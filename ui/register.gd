extends Control

# Screens matching Figures "Register" and "Create Account" — a two-step
# account creation form. Account creation is stubbed via AuthState until
# Firebase Authentication is wired up.

const MIN_PASSWORD_LENGTH := 6

var username_field: LineEdit
var email_field: LineEdit
var password_field: LineEdit
var confirm_field: LineEdit
var status_label: Label
var step_one: Control
var step_two: Control

func _ready() -> void:
	add_child(UIKit.full_rect_bg())
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var root_box := UIKit.vbox(16)
	center.add_child(root_box)
	root_box.add_child(UIKit.title_label("REGISTER", 28))

	var panel := UIKit.panel(Vector2(320, 0))
	root_box.add_child(panel)
	var panel_box := UIKit.vbox(12)
	panel.add_child(panel_box)

	step_one = _build_step_one()
	step_two = _build_step_two()
	panel_box.add_child(step_one)
	panel_box.add_child(step_two)
	step_two.visible = false

	status_label = UIKit.body_label("", 13, Color(1.0, 0.6, 0.4))
	status_label.custom_minimum_size = Vector2(320, 0)
	root_box.add_child(status_label)

func _build_step_one() -> Control:
	var box := UIKit.vbox(12)
	username_field = UIKit.text_field("Username")
	box.add_child(username_field)
	email_field = UIKit.text_field("Email")
	box.add_child(email_field)
	var next_row := HBoxContainer.new()
	next_row.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(next_row)
	var next_button := UIKit.styled_button("▶")
	next_button.custom_minimum_size = Vector2(46, 46)
	next_button.pressed.connect(_on_next_pressed)
	next_row.add_child(next_button)
	return box

func _build_step_two() -> Control:
	var box := UIKit.vbox(12)
	password_field = UIKit.text_field("Password", true)
	box.add_child(password_field)
	confirm_field = UIKit.text_field("Confirm Password", true)
	box.add_child(confirm_field)
	var row := UIKit.hbox(12)
	box.add_child(row)
	var back_button := UIKit.back_button()
	back_button.pressed.connect(_on_back_pressed)
	row.add_child(back_button)
	var create_button := UIKit.styled_button("CREATE ACCOUNT")
	create_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create_button.pressed.connect(_on_create_pressed)
	row.add_child(create_button)
	return box

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
