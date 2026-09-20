extends Control

# Screen 1 (Login) + its Forgot Password panel from the storyboard.
# Auth is stubbed via AuthState until Firebase Authentication is wired up.

var username_field: LineEdit
var password_field: LineEdit
var status_label: Label
var forgot_overlay: Control
var forgot_email_field: LineEdit
var forgot_status_label: Label

func _ready() -> void:
	add_child(UIKit.full_rect_bg())
	_build_login_layout()
	_build_forgot_password_overlay()

func _build_login_layout() -> void:
	var root_box := UIKit.vbox(18)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	center.add_child(root_box)

	root_box.add_child(UIKit.title_label("RELAYED", 40))

	var panel := UIKit.panel(Vector2(320, 0))
	root_box.add_child(panel)
	var box := UIKit.vbox(12)
	panel.add_child(box)

	box.add_child(UIKit.title_label("LOGIN", 22))

	username_field = UIKit.text_field("Username")
	box.add_child(username_field)

	password_field = UIKit.text_field("Password", true)
	box.add_child(password_field)

	var forgot_row := HBoxContainer.new()
	forgot_row.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(forgot_row)
	var forgot_link := UIKit.link_button("Forgot Password?")
	forgot_link.pressed.connect(_show_forgot_password)
	forgot_row.add_child(forgot_link)

	var enter_button := UIKit.styled_button("ENTER")
	enter_button.pressed.connect(_on_enter_pressed)
	box.add_child(enter_button)

	var create_link := UIKit.link_button("CREATE ACCOUNT")
	create_link.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	create_link.pressed.connect(_on_create_account_pressed)
	box.add_child(UIKit.centered(create_link))

	var google_button := UIKit.styled_button("Sign in with Google", Color(0.25, 0.25, 0.27))
	google_button.custom_minimum_size = Vector2(320, 46)
	google_button.pressed.connect(_on_google_pressed)
	root_box.add_child(google_button)

	status_label = UIKit.body_label("", 13, Color(1.0, 0.6, 0.4))
	status_label.custom_minimum_size = Vector2(320, 0)
	root_box.add_child(status_label)

func _build_forgot_password_overlay() -> void:
	forgot_overlay = Control.new()
	forgot_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	forgot_overlay.visible = false
	add_child(forgot_overlay)
	forgot_overlay.add_child(UIKit.full_rect_bg(Color(0, 0, 0, 0.55)))

	var panel := UIKit.panel(Vector2(320, 0))
	forgot_overlay.add_child(UIKit.centered(panel))
	var box := UIKit.vbox(12)
	panel.add_child(box)

	var header := UIKit.hbox(8)
	box.add_child(header)
	var back := UIKit.back_button()
	back.pressed.connect(_hide_forgot_password)
	header.add_child(back)
	header.add_child(UIKit.title_label("Forgot Password", 20))

	box.add_child(UIKit.body_label("Please enter your email address"))
	forgot_email_field = UIKit.text_field("Email")
	box.add_child(forgot_email_field)

	var submit := UIKit.styled_button("SUBMIT")
	submit.pressed.connect(_on_forgot_submit)
	box.add_child(UIKit.centered(submit))

	forgot_status_label = UIKit.body_label("", 12, Color(0.7, 0.9, 0.7))
	box.add_child(forgot_status_label)

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
	get_tree().change_scene_to_file("res://scenes/choose_game.tscn")

func _on_create_account_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/register.tscn")

func _on_google_pressed() -> void:
	status_label.text = "Google Sign-In needs Firebase setup — not connected yet."

func _looks_like_email(value: String) -> bool:
	return value.contains("@") and value.contains(".") and not value.begins_with("@")
