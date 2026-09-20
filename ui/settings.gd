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

func _on_speed_changed(value: float) -> void:
	GameSettings.camera_speed_multiplier = value
	speed_value.text = "%.2fx" % value
