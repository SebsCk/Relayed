extends Node
class_name Authentication

func initializeAuth(type : int, email : String = "", password : String = ""):
	match type:
		1: return await processRequest("signUp", {'returnSecureToken':true})
		2: return await processRequest("signUp", {'email':email,'password':password,'returnSecureToken':true})
		3: return await processRequest("signInWithPassword", {'email':email,'password':password,'returnSecureToken':true})

func getUserData():
	return await processRequest("lookup", {'idToken':FirebaseLite.authToken})

func changeEmail(email : String):
	return await processRequest("update", {'idToken':FirebaseLite.authToken,'email':email,'returnSecureToken':true})

func changePassword(password : String):
	return await processRequest("update", {'idToken':FirebaseLite.authToken,'password':password,'returnSecureToken':true})

func updateDisplayName(displayName : String):
	return await processRequest("update", {'idToken':FirebaseLite.authToken,'displayName':displayName,'returnSecureToken':true})

func updatePhoto(photoUrl : String):
	return await processRequest("update", {'idToken':FirebaseLite.authToken,'photoUrl':photoUrl,'returnSecureToken':true})

func linkWithEmail(email : String, password : String):
	return await processRequest("update", {'idToken':FirebaseLite.authToken,'email':email,'password':password,'returnSecureToken':true})

func sendEmailVerification():
	return await processRequest("sendOobCode", {'requestType':'VERIFY_EMAIL','idToken':FirebaseLite.authToken})

func deleteAccount():
	return await processRequest("delete", {'idToken':FirebaseLite.authToken})

func unlinkProvider(providers : Array):
	return await processRequest("update", {'idToken':FirebaseLite.authToken,'deleteProvider':providers,'returnSecureToken':true})

func processRequest(event, datats):
	# Vendored fix: signInWithIdp (Google/federated sign-in) is a sign-IN
	# event like signUp/signInWithPassword, not an update to an already
	# logged-in user — it was missing from this list, so the "else" branch
	# below required authToken != null and every Google sign-in attempt
	# failed immediately with "User not logged in", before any request went out.
	if event == "signUp" or event == "signInWithPassword" or event == "signInWithIdp":
		if FirebaseLite.authToken != null: 
			printerr("User already logged in")
			return ERR_CANT_CONNECT
	else:
		if FirebaseLite.authToken == null:  
			printerr("Firebase (Authentication): User not logged in")
			return ERR_CANT_CONNECT
	var authHttp = HTTPRequest.new()
	add_child(authHttp)
	authHttp.request("https://identitytoolkit.googleapis.com/v1/accounts:"+event+"?key="+FirebaseLite.firebaseConfig["apiKey"], ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(datats))
	var data = await authHttp.request_completed
	var decodedData = JSON.parse_string(data[3].get_string_from_utf8())
	authHttp.queue_free()
	if data[1] == 400: #Response code: 400 | There was an error
		printerr("Firebase (Authentication): There was an error, received data: %s" % decodedData)
		# Vendored fix: return the decoded error body (has an "error" key with
		# a real message like EMAIL_EXISTS/INVALID_PASSWORD) instead of a bare
		# int, so callers can show the player something more useful than
		# "something went wrong".
		return decodedData
	elif data[1] == 200: #Response code: 200 | Request was succesful and data was received
		# Vendored fix: the original check only matched signUp's response
		# "kind", so a successful signInWithPassword or signInWithIdp never
		# stored the token — every later authenticated call (Firestore
		# writes, updateDisplayName, ...) silently went out unauthenticated.
		# signUp/signInWithPassword/signInWithIdp all return "idToken" on
		# success, so key off that instead of one specific response kind.
		if typeof(decodedData) == TYPE_DICTIONARY and decodedData.has("idToken"):
			FirebaseLite.authToken = decodedData["idToken"]
		return decodedData
