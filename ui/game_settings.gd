extends Node

# A small persistent-in-session settings store.  More options can be added here
# without coupling the menu to a particular gameplay scene.
var camera_speed_multiplier: float = 1.0
var audio_volume: float = 1.0
var notifications_enabled: bool = true

func set_audio_volume(value: float) -> void:
	audio_volume = value
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(max(value, 0.0001)))
	AudioServer.set_bus_mute(bus, value <= 0.0)

