extends Button

func _ready():
	pressed.connect(_on_back_pressed)

func _on_back_pressed():
	BuildingInfoPanel.hide_panel()
	get_tree().change_scene_to_file("res://scenes/chapter_select.tscn")
