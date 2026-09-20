extends Node2D

func _ready() -> void:
	BuildingInfoPanel.hide_panel()

func _on_start_pressed() -> void:
	UIKit.go_to_scene("res://scenes/relayed.tscn")


func _on_settings_pressed() -> void:
	GameProgress.settings_return_path = "res://scenes/main_menu.tscn"
	UIKit.go_to_scene("res://scenes/settings.tscn")


func _on_quit_pressed() -> void:
	UIKit.show_confirm_dialog(self, "ARE YOU SURE?", "Any unsaved progress in this session will be lost.", func(): get_tree().quit())
