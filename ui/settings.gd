extends Node2D

# The settings UI is authored directly in scenes/settings.tscn (under
# $Control) so it's visible and editable in the editor; this script only
# loads current values from GameSettings and wires up the signals.
@onready var speed_value: Label = $Control/SpeedValue

func _ready() -> void:
	var speed_slider: HSlider = $Control/SpeedSlider
	speed_slider.value = GameSettings.camera_speed_multiplier
	speed_slider.value_changed.connect(_on_speed_changed)
	_on_speed_changed(speed_slider.value)

	var audio_slider: HSlider = $Control/AudioSlider
	audio_slider.value = GameSettings.audio_volume
	audio_slider.value_changed.connect(GameSettings.set_audio_volume)

	var notif_toggle: CheckButton = $Control/NotificationsToggle
	notif_toggle.button_pressed = GameSettings.notifications_enabled
	notif_toggle.toggled.connect(func(pressed): GameSettings.notifications_enabled = pressed)

	$Control/SignOutButton.pressed.connect(_on_sign_out_pressed)
	$Control/QuitButton.pressed.connect(_on_quit_pressed)

func _on_speed_changed(value: float) -> void:
	GameSettings.camera_speed_multiplier = value
	speed_value.text = "%.2fx" % value

func _on_sign_out_pressed() -> void:
	AuthState.logout()
	UIKit.go_to_scene("res://scenes/login.tscn")

func _on_quit_pressed() -> void:
	UIKit.show_confirm_dialog(self, "ARE YOU SURE?", "Any unsaved progress in this session will be lost.", func(): get_tree().quit())
