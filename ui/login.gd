extends Control

# Screen 1 (Login) + its Forgot Password panel from the storyboard.
# Real Firebase Authentication through AuthState when a Firebase project is
# configured (see ui/firebase_config.gd); otherwise AuthState's local-only
# fallback keeps this screen working without one.
# UI is authored directly in scenes/login.tscn (editable in the 2D editor);
# this script only wires up references and behavior.

@onready var email_field: LineEdit = $Center/RootBox/LoginPanel/LoginBox/UsernameField
@onready var password_field: LineEdit = $Center/RootBox/LoginPanel/LoginBox/PasswordField
@onready var status_label: Label = $Center/RootBox/StatusLabel
@onready var enter_button: Button = $Center/RootBox/LoginPanel/LoginBox/EnterButton
@onready var google_button: Button = $Center/RootBox/GoogleButton
@onready var forgot_overlay: Control = $ForgotOverlay
@onready var forgot_email_field: LineEdit = $ForgotOverlay/ForgotCenter/ForgotPanel/ForgotBox/ForgotEmailField
@onready var forgot_status_label: Label = $ForgotOverlay/ForgotCenter/ForgotPanel/ForgotBox/ForgotStatusLabel

func _ready() -> void:
	$Center/RootBox/LoginPanel/LoginBox/ForgotRow/ForgotPasswordLink.pressed.connect(_show_forgot_password)
	enter_button.pressed.connect(_on_enter_pressed)
	$Center/RootBox/LoginPanel/LoginBox/CreateAccountCenter/CreateAccountLink.pressed.connect(_on_create_account_pressed)
	google_button.pressed.connect(_on_google_pressed)
	$ForgotOverlay/ForgotCenter/ForgotPanel/ForgotBox/ForgotHeader/BackButton.pressed.connect(_hide_forgot_password)
	$ForgotOverlay/ForgotCenter/ForgotPanel/ForgotBox/SubmitCenter/SubmitButton.pressed.connect(_on_forgot_submit)

func _show_forgot_password() -> void:
	forgot_status_label.text = ""
	forgot_email_field.text = ""
	forgot_overlay.visible = true

func _hide_forgot_password() -> void:
	forgot_overlay.visible = false

func _on_forgot_submit() -> void:
	var forgot_email := forgot_email_field.text.strip_edges()
	if not _looks_like_email(forgot_email):
		forgot_status_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.4))
		forgot_status_label.text = "Enter a valid email address."
		return
	# Fire-and-forget: always show the same neutral message regardless of
	# whether the account exists, so this screen can't be used to check
	# which emails are registered.
	AuthState.send_password_reset(forgot_email)
	forgot_status_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	forgot_status_label.text = "If an account exists for that email, a reset link has been sent."

func _on_enter_pressed() -> void:
	var login_email := email_field.text.strip_edges()
	var password := password_field.text
	if login_email.is_empty() or password.is_empty():
		status_label.text = "Enter your email and password."
		return
	status_label.remove_theme_color_override("font_color")
	status_label.text = "Signing in..."
	enter_button.disabled = true
	var error := await AuthState.login(login_email, password)
	enter_button.disabled = false
	if not error.is_empty():
		status_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.4))
		status_label.text = error
		return
	UIKit.go_to_scene("res://scenes/choose_game.tscn")

func _on_create_account_pressed() -> void:
	UIKit.go_to_scene("res://scenes/register.tscn")

func _on_google_pressed() -> void:
	status_label.remove_theme_color_override("font_color")
	status_label.text = "Continue in your browser..."
	google_button.disabled = true
	var error := await AuthState.login_with_google()
	google_button.disabled = false
	if not error.is_empty():
		status_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.4))
		status_label.text = error
		return
	UIKit.go_to_scene("res://scenes/choose_game.tscn")

func _looks_like_email(value: String) -> bool:
	return value.contains("@") and value.contains(".") and not value.begins_with("@")
