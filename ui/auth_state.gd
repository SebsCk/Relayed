extends Node

# Real Firebase Authentication (email/password + Google Sign-In) once
# FirebaseConfig.is_configured() is true. Until then, every call here falls
# back to the old in-memory local-only stub so the game still runs without a
# Firebase project — matching AGENTS.md's "core gameplay must work fully
# offline" rule, just extended to cover "no Firebase project configured yet"
# too.
#
# Google Sign-In uses the OAuth 2.0 "installed app" loopback flow: it opens
# the system browser to Google's consent screen, then listens briefly on
# 127.0.0.1 for the redirect carrying the authorization code (see
# login_with_google()). This needs its own Desktop OAuth client from Google
# Cloud Console — see the comment block in ui/firebase_config.gd.

const USERS_COLLECTION := "users"

const GOOGLE_AUTH_ENDPOINT := "https://accounts.google.com/o/oauth2/v2/auth"
const GOOGLE_TOKEN_ENDPOINT := "https://oauth2.googleapis.com/token"
const LOOPBACK_PORT_START := 8000
const LOOPBACK_PORT_TRIES := 20
const LOOPBACK_TIMEOUT_SECONDS := 180.0

var is_logged_in: bool = false
var username: String = ""
var email: String = ""
var uid: String = ""
var last_error: String = ""

func _ready() -> void:
	if FirebaseConfig.is_configured():
		FirebaseLite.initialize(FirebaseConfig.firebase_config())

func is_firebase_ready() -> bool:
	return FirebaseConfig.is_configured()

# ---- Email / password -----------------------------------------------------

# Returns "" on success, or a message to show the player.
func login(login_email: String, password: String) -> String:
	if not is_firebase_ready():
		_apply_local_session(login_email)
		return ""
	var result = await FirebaseLite.Authentication.initializeAuth(3, login_email, password)
	var error := _handle_auth_result(result)
	if not error.is_empty():
		return error
	await _load_profile_after_sign_in(login_email, "")
	return ""

func register(display_name: String, register_email: String, password: String) -> String:
	if not is_firebase_ready():
		_apply_local_session(display_name)
		return ""
	var result = await FirebaseLite.Authentication.initializeAuth(2, register_email, password)
	var error := _handle_auth_result(result)
	if not error.is_empty():
		return error
	await FirebaseLite.Authentication.updateDisplayName(display_name)
	username = display_name
	email = register_email
	_create_user_document(display_name, register_email, "email")
	return ""

# Always returns "" (see the note in login.gd on why errors aren't surfaced
# here — showing a different message for "no such account" would leak which
# emails are registered).
func send_password_reset(reset_email: String) -> String:
	if is_firebase_ready():
		var http := HTTPRequest.new()
		add_child(http)
		http.request(
			"https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=%s" % FirebaseConfig.API_KEY,
			["Content-Type: application/json"], HTTPClient.METHOD_POST,
			JSON.stringify({"requestType": "PASSWORD_RESET", "email": reset_email}))
		await http.request_completed
		http.queue_free()
	return ""

func update_display_name(new_name: String) -> void:
	username = new_name
	if is_firebase_ready() and is_logged_in and not uid.is_empty():
		FirebaseLite.Authentication.updateDisplayName(new_name)
		FirebaseLite.Firestore.update("%s/%s" % [USERS_COLLECTION, uid], {"display_name": new_name})

func logout() -> void:
	is_logged_in = false
	username = ""
	email = ""
	uid = ""
	last_error = ""
	if is_firebase_ready():
		FirebaseLite.authToken = null

# ---- Google Sign-In (OAuth loopback flow) ----------------------------------

func login_with_google() -> String:
	if not FirebaseConfig.google_sign_in_configured():
		last_error = "Google Sign-In isn't set up yet — see the comment at the top of ui/firebase_config.gd."
		return last_error

	var server := TCPServer.new()
	var port := -1
	for candidate in range(LOOPBACK_PORT_START, LOOPBACK_PORT_START + LOOPBACK_PORT_TRIES):
		if server.listen(candidate, "127.0.0.1") == OK:
			port = candidate
			break
	if port < 0:
		last_error = "Couldn't open a local port for sign-in. Close other apps and try again."
		return last_error
	var redirect_uri := "http://127.0.0.1:%d/" % port

	var crypto := Crypto.new()
	var verifier := _base64url(crypto.generate_random_bytes(32))
	var challenge_ctx := HashingContext.new()
	challenge_ctx.start(HashingContext.HASH_SHA256)
	challenge_ctx.update(verifier.to_utf8_buffer())
	var challenge := _base64url(challenge_ctx.finish())
	var state := _base64url(crypto.generate_random_bytes(16))

	var auth_url := "%s?client_id=%s&redirect_uri=%s&response_type=code&scope=%s&code_challenge=%s&code_challenge_method=S256&state=%s&access_type=online&prompt=select_account" % [
		GOOGLE_AUTH_ENDPOINT,
		FirebaseConfig.GOOGLE_OAUTH_CLIENT_ID.uri_encode(),
		redirect_uri.uri_encode(),
		"openid email profile".uri_encode(),
		challenge.uri_encode(),
		state.uri_encode(),
	]
	OS.shell_open(auth_url)

	var code := await _await_loopback_code(server, state)
	server.stop()
	if code.is_empty():
		last_error = "Sign-in was cancelled or timed out."
		return last_error

	var token_result = await _exchange_google_code(code, verifier, redirect_uri)
	if typeof(token_result) != TYPE_DICTIONARY or not token_result.has("id_token"):
		last_error = "Google didn't return a valid sign-in. Please try again."
		return last_error

	var idp_result = await FirebaseLite.Authentication.processRequest("signInWithIdp", {
		"postBody": "id_token=%s&providerId=google.com" % String(token_result["id_token"]),
		"requestUri": redirect_uri,
		"returnIdpCredential": true,
		"returnSecureToken": true,
	})
	var error := _handle_auth_result(idp_result)
	if not error.is_empty():
		return error
	var display_name := String(idp_result.get("displayName", ""))
	await _load_profile_after_sign_in(String(idp_result.get("email", "")), display_name)
	_create_user_document(username, email, "google")
	return ""

# Polls the loopback server for the browser's redirect and returns the
# authorization code, or "" if it timed out, was cancelled, or the state
# (CSRF) value didn't match what we sent.
func _await_loopback_code(server: TCPServer, expected_state: String) -> String:
	var elapsed := 0.0
	while elapsed < LOOPBACK_TIMEOUT_SECONDS:
		if server.is_connection_available():
			var conn: StreamPeerTCP = server.take_connection()
			var request_line := await _read_http_request_line(conn)
			var params := _parse_query_params(request_line)
			_respond_and_close(conn, params.has("code"))
			if params.has("state") and String(params["state"]) != expected_state:
				return ""
			return String(params.get("code", ""))
		await get_tree().create_timer(0.25).timeout
		elapsed += 0.25
	return ""

func _read_http_request_line(conn: StreamPeerTCP) -> String:
	var waited := 0.0
	while conn.get_available_bytes() <= 0 and waited < 5.0:
		conn.poll()
		await get_tree().create_timer(0.05).timeout
		waited += 0.05
	conn.poll()
	var available := conn.get_available_bytes()
	if available <= 0:
		return ""
	var chunk = conn.get_partial_data(available)
	var text: String = (chunk[1] as PackedByteArray).get_string_from_utf8()
	var line_end := text.find("\r\n")
	return text.substr(0, line_end) if line_end >= 0 else text

func _parse_query_params(request_line: String) -> Dictionary:
	var params := {}
	var parts := request_line.split(" ")
	if parts.size() < 2:
		return params
	var target := parts[1]
	var q := target.find("?")
	if q < 0:
		return params
	for pair in target.substr(q + 1).split("&"):
		var kv := pair.split("=")
		if kv.size() == 2:
			params[kv[0]] = kv[1].uri_decode()
	return params

func _respond_and_close(conn: StreamPeerTCP, success: bool) -> void:
	var message := "Signed in! You can close this tab and go back to RELAYED." if success \
		else "Sign-in didn't go through. You can close this tab and try again in RELAYED."
	var html := "<html><body style=\"font-family:sans-serif;text-align:center;padding-top:4em;\">%s</body></html>" % message
	var body := html.to_utf8_buffer()
	var header := "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: %d\r\nConnection: close\r\n\r\n" % body.size()
	conn.put_data(header.to_utf8_buffer() + body)
	conn.disconnect_from_host()

func _exchange_google_code(code: String, verifier: String, redirect_uri: String):
	var http := HTTPRequest.new()
	add_child(http)
	var body := "code=%s&client_id=%s&client_secret=%s&redirect_uri=%s&grant_type=authorization_code&code_verifier=%s" % [
		code.uri_encode(), FirebaseConfig.GOOGLE_OAUTH_CLIENT_ID.uri_encode(),
		FirebaseConfig.GOOGLE_OAUTH_CLIENT_SECRET.uri_encode(), redirect_uri.uri_encode(), verifier.uri_encode(),
	]
	http.request(GOOGLE_TOKEN_ENDPOINT, ["Content-Type: application/x-www-form-urlencoded"], HTTPClient.METHOD_POST, body)
	var data = await http.request_completed
	http.queue_free()
	if int(data[1]) != 200:
		return ERR_CANT_CONNECT
	return JSON.parse_string(data[3].get_string_from_utf8())

func _base64url(bytes: PackedByteArray) -> String:
	return Marshalls.raw_to_base64(bytes).replace("+", "-").replace("/", "_").replace("=", "")

# ---- Shared helpers ---------------------------------------------------------

func _handle_auth_result(result) -> String:
	if typeof(result) != TYPE_DICTIONARY:
		last_error = "Couldn't reach Firebase. Check your connection and try again."
		return last_error
	if result.has("error"):
		last_error = _friendly_auth_error(String(result["error"].get("message", "")))
		return last_error
	is_logged_in = true
	uid = String(result.get("localId", ""))
	if result.has("email"):
		email = String(result["email"])
	return ""

func _friendly_auth_error(code: String) -> String:
	match code:
		"EMAIL_EXISTS":
			return "An account with that email already exists."
		"EMAIL_NOT_FOUND":
			return "No account found for that email."
		"INVALID_PASSWORD", "INVALID_LOGIN_CREDENTIALS":
			return "Incorrect email or password."
		"INVALID_EMAIL":
			return "That doesn't look like a valid email address."
		"USER_DISABLED":
			return "This account has been disabled."
		"TOO_MANY_ATTEMPTS_TRY_LATER":
			return "Too many attempts. Please try again later."
		_:
			if code.begins_with("WEAK_PASSWORD"):
				return "Password must be at least 6 characters."
			return "Something went wrong. Please try again." if code.is_empty() else "Something went wrong (%s)." % code

func _load_profile_after_sign_in(signed_in_email: String, fallback_display_name: String) -> void:
	email = signed_in_email
	var doc = await FirebaseLite.Firestore.read("%s/%s" % [USERS_COLLECTION, uid])
	if typeof(doc) == TYPE_DICTIONARY and doc.has("display_name"):
		username = String(doc["display_name"])
	elif not fallback_display_name.is_empty():
		username = fallback_display_name
	elif username.is_empty() and not signed_in_email.is_empty():
		username = signed_in_email.split("@")[0]

func _create_user_document(display_name: String, user_email: String, provider: String) -> void:
	if uid.is_empty():
		return
	FirebaseLite.Firestore.update("%s/%s" % [USERS_COLLECTION, uid], {
		"email": user_email,
		"display_name": display_name,
		"auth_provider": provider,
	})

func _apply_local_session(display_name: String) -> void:
	is_logged_in = true
	username = display_name
	email = ""
	uid = ""
