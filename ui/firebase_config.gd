extends Node

# Autoload (FirebaseConfig). Fill in the placeholder values below with your
# own Firebase project's values, then the game will use real Firebase
# Authentication + Firestore. Until you do, is_configured() returns false and
# AuthState falls back to the old local-only login stub, so the game still
# runs without a Firebase project.
#
# Where to get these values:
#
# 1. Create a Firebase project: https://console.firebase.google.com/
#    -> "Add project" -> name it (e.g. "relayed-game") -> finish the wizard.
# 2. Add a Web app to it: Project settings (gear icon) -> "Your apps" ->
#    the </> (Web) icon -> register an app (no Firebase Hosting needed).
#    Firebase shows you a firebaseConfig object — copy "apiKey" and
#    "projectId" from it into API_KEY / PROJECT_ID below.
# 3. Enable Authentication: Build -> Authentication -> Get started ->
#    Sign-in method -> enable "Email/Password", and separately enable
#    "Google".
# 4. Enable Firestore: Build -> Firestore Database -> Create database ->
#    start in test mode for development (lock it down with real security
#    rules before shipping — test mode allows anyone to read/write).
# 5. For Google Sign-In specifically, Firebase's own "Google" provider
#    auto-creates a Web OAuth client, but this game signs in from a desktop
#    build, which needs its own "Desktop app" OAuth client (the flow opens
#    the user's system browser, then listens on 127.0.0.1 for the reply —
#    a Web client's redirect URIs don't allow that):
#      Google Cloud Console (console.cloud.google.com), same project as
#      Firebase -> APIs & Services -> Credentials -> Create Credentials ->
#      OAuth client ID -> Application type: Desktop app.
#      Copy its Client ID and Client secret into GOOGLE_OAUTH_CLIENT_ID /
#      GOOGLE_OAUTH_CLIENT_SECRET below. (Yes, Google's own docs say a
#      desktop app's "secret" isn't kept confidential — this is expected,
#      not a mistake: https://developers.google.com/identity/protocols/oauth2/native-app)

const API_KEY := "YOUR_FIREBASE_WEB_API_KEY"
const PROJECT_ID := "YOUR_FIREBASE_PROJECT_ID"
const GOOGLE_OAUTH_CLIENT_ID := "YOUR_GOOGLE_OAUTH_DESKTOP_CLIENT_ID"
const GOOGLE_OAUTH_CLIENT_SECRET := "YOUR_GOOGLE_OAUTH_DESKTOP_CLIENT_SECRET"

func is_configured() -> bool:
	return not (API_KEY.begins_with("YOUR_") or PROJECT_ID.begins_with("YOUR_"))

func google_sign_in_configured() -> bool:
	return is_configured() and not (GOOGLE_OAUTH_CLIENT_ID.begins_with("YOUR_") or GOOGLE_OAUTH_CLIENT_SECRET.begins_with("YOUR_"))

func firebase_config() -> Dictionary:
	return {"apiKey": API_KEY, "projectId": PROJECT_ID}
