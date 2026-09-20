extends Button

func _ready():
	pressed.connect(_on_back_pressed)

func _on_back_pressed():
	BuildingInfoPanel.hide_panel()
	UIKit.go_to_scene("res://scenes/chapter_select.tscn")
