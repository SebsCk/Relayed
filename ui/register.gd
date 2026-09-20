extends Control

# Screens matching Figures "Register" and "Create Account" — a two-step
# account creation form. Account creation is stubbed via AuthState until
# Firebase Authentication is wired up.
# UI is authored directly in scenes/register.tscn; this script only wires
# up references and behavior.

const MIN_PASSWORD_LENGTH := 6

@onready var username_field: LineEdit = $Center/RootBox/RegisterPanel/PanelBox/StepOne/UsernameField
@onready var email_field: LineEdit = $Center/RootBox/RegisterPanel/PanelBox/StepOne/EmailField
@onready var password_field: LineEdit = $Center/RootBox/RegisterPanel/PanelBox/StepTwo/PasswordField
@onready var confirm_field: LineEdit = $Center/RootBox/RegisterPanel/PanelBox/StepTwo/ConfirmField
@onready var status_label: Label = $Center/RootBox/StatusLabel
@onready var step_one: Control = $Center/RootBox/RegisterPanel/PanelBox/StepOne
@onready var step_two: Control = $Center/RootBox/RegisterPanel/PanelBox/StepTwo

func _ready() -> void:
	$Center/RootBox/RegisterPanel/PanelBox/StepOne/NextRow/NextButton.pressed.connect(_on_next_pressed)
	$Center/RootBox/RegisterPanel/PanelBox/StepTwo/Row/BackButton.pressed.connect(_on_back_pressed)
	$Center/RootBox/RegisterPanel/PanelBox/StepTwo/Row/CreateButton.pressed.connect(_on_create_pressed)

func _on_next_pressed() -> void:
	var username := username_field.text.strip_edges()
	var email := email_field.text.strip_edges()
	if username.is_empty():
		status_label.text = "Enter a username."
		return
	if not (email.contains("@") and email.contains(".") and not email.begins_with("@")):
		status_label.text = "Enter a valid email address."
		return
	status_label.text = ""
	step_one.visible = false
	step_two.visible = true

func _on_back_pressed() -> void:
	status_label.text = ""
	step_two.visible = false
	step_one.visible = true

func _on_create_pressed() -> void:
	var password := password_field.text
	var confirm := confirm_field.text
	if password.length() < MIN_PASSWORD_LENGTH:
		status_label.text = "Password must be at least %d characters." % MIN_PASSWORD_LENGTH
		return
	if password != confirm:
		status_label.text = "Passwords do not match."
		return
	AuthState.login(username_field.text.strip_edges())
	UIKit.go_to_scene("res://scenes/choose_game.tscn")
