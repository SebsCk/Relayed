extends Node2D

var speed_value: Label

func _ready() -> void:
	var control := $Control
	var title := Label.new()
	title.text = "Settings"
	title.position = Vector2(435, 130)
	title.add_theme_font_size_override("font_size", 32)
	control.add_child(title)
	var description := Label.new()
	description.text = "Camera movement speed"
	description.position = Vector2(400, 205)
	description.add_theme_font_size_override("font_size", 18)
	control.add_child(description)
	var slider := HSlider.new()
	slider.position = Vector2(400, 245)
	slider.size = Vector2(330, 28)
	slider.min_value = 0.5
	slider.max_value = 2.0
	slider.step = 0.25
	slider.value = GameSettings.camera_speed_multiplier
	slider.value_changed.connect(_on_speed_changed)
	control.add_child(slider)
	speed_value = Label.new()
	speed_value.position = Vector2(740, 245)
	control.add_child(speed_value)
	_on_speed_changed(slider.value)
	var hint := Label.new()
	hint.text = "This setting applies immediately in the map."
	hint.position = Vector2(400, 295)
	control.add_child(hint)

	_build_extra_settings(control)

func _on_speed_changed(value: float) -> void:
	GameSettings.camera_speed_multiplier = value
	speed_value.text = "%.2fx" % value

func _build_extra_settings(control: Node) -> void:
	var audio_title := Label.new()
	audio_title.text = "Audio"
	audio_title.position = Vector2(400, 345)
	audio_title.add_theme_font_size_override("font_size", 18)
	control.add_child(audio_title)
	var audio_slider := HSlider.new()
	audio_slider.position = Vector2(400, 375)
	audio_slider.size = Vector2(330, 28)
	audio_slider.min_value = 0.0
	audio_slider.max_value = 1.0
	audio_slider.step = 0.05
	audio_slider.value = GameSettings.audio_volume
	audio_slider.value_changed.connect(GameSettings.set_audio_volume)
	control.add_child(audio_slider)

	var notif_title := Label.new()
	notif_title.text = "Notifications"
	notif_title.position = Vector2(400, 420)
	notif_title.add_theme_font_size_override("font_size", 18)
	control.add_child(notif_title)
	var notif_toggle := CheckButton.new()
	notif_toggle.position = Vector2(650, 415)
	notif_toggle.button_pressed = GameSettings.notifications_enabled
	notif_toggle.toggled.connect(func(pressed): GameSettings.notifications_enabled = pressed)
	control.add_child(notif_toggle)

	var sign_out_button := UIKit.styled_button("SIGN OUT", Color(0.3, 0.3, 0.32))
	sign_out_button.position = Vector2(400, 470)
	sign_out_button.size = Vector2(160, 46)
	sign_out_button.pressed.connect(_on_sign_out_pressed)
	control.add_child(sign_out_button)

	var quit_button := UIKit.styled_button("QUIT GAME", UIKit.DANGER_COLOR)
	quit_button.position = Vector2(570, 470)
	quit_button.size = Vector2(160, 46)
	quit_button.pressed.connect(_on_quit_pressed)
	control.add_child(quit_button)

func _on_sign_out_pressed() -> void:
	AuthState.logout()
	UIKit.go_to_scene("res://scenes/login.tscn")

func _on_quit_pressed() -> void:
	UIKit.show_confirm_dialog(self, "ARE YOU SURE?", "Any unsaved progress in this session will be lost.", func(): get_tree().quit())
