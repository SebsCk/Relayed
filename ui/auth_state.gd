extends Node

# In-memory session stub. AGENTS.md specifies Firebase Authentication for the
# real backend; this just tracks "logged in" state for the UI flow until that
# integration exists, matching how GameSettings stands in for real settings
# persistence.

var is_logged_in: bool = false
var username: String = ""

func login(name: String) -> void:
	is_logged_in = true
	username = name

func logout() -> void:
	is_logged_in = false
	username = ""
