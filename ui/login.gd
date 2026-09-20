extends Control

# Screen 1 (Login) + its Forgot Password panel from the storyboard.
# Auth is stubbed via AuthState until Firebase Authentication is wired up.
# UI is authored directly in scenes/login.tscn (editable in the 2D editor);
# this script only wires up references and behavior.

@onready var username_field: LineEdit = $Center/RootBox/LoginPanel/LoginBox/UsernameField
@onready var password_field: LineEdit = $Center/RootBox/LoginPanel/LoginBox/PasswordField
@onready var status_label: Label = $Center/RootBox/StatusLabel
@onready var forgot_overlay: Control = $ForgotOverlay
@onready var forgot_email_field: LineEdit = $ForgotOverlay/ForgotCenter/ForgotPanel/ForgotBox/ForgotEmailField
@onready var forgot_status_label: Label = $ForgotOverlay/ForgotCenter/ForgotPanel/ForgotBox/ForgotStatusLabel

func _ready() -> void:
	$Center/RootBox/LoginPanel/LoginBox/ForgotRow/ForgotPasswordLink.pressed.connect(_show_forgot_password)
	$Center/RootBox/LoginPanel/LoginBox/EnterButton.pressed.connect(_on_enter_pressed)
	$Center/RootBox/LoginPanel/LoginBox/CreateAccountCenter/CreateAccountLink.pressed.connect(_on_create_account_pressed)
	$Center/RootBox/GoogleButton.pressed.connect(_on_google_pressed)
	$ForgotOverlay/ForgotCenter/ForgotPanel/ForgotBox/ForgotHeader/BackButton.pressed.connect(_hide_forgot_password)
	$ForgotOverlay/ForgotCenter/ForgotPanel/ForgotBox/SubmitCenter/SubmitButton.pressed.connect(_on_forgot_submit)

func _show_forgot_password() -> void:
	forgot_status_label.text = ""
	forgot_email_field.text = ""
	forgot_overlay.visible = true

func _hide_forgot_password() -> void:
	forgot_overlay.visible = false

func _on_forgot_submit() -> void:
	var email := forgot_email_field.text.strip_edges()
	if not _looks_like_email(email):
		forgot_status_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.4))
		forgot_status_label.text = "Enter a valid email address."
		return
	forgot_status_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	forgot_status_label.text = "If an account exists for that email, a reset link has been sent."

func _on_enter_pressed() -> void:
	var username := username_field.text.strip_edges()
	var password := password_field.text
	if username.is_empty() or password.is_empty():
		status_label.text = "Enter a username and password."
		return
	AuthState.login(username)
	UIKit.go_to_scene("res://scenes/choose_game.tscn")

func _on_create_account_pressed() -> void:
	UIKit.go_to_scene("res://scenes/register.tscn")

func _on_google_pressed() -> void:
	status_label.text = "Google Sign-In needs Firebase setup — not connected yet."

func _looks_like_email(value: String) -> bool:
	return value.contains("@") and value.contains(".") and not value.begins_with("@")
