extends Control

func _on_back_pressed() -> void:
	UIKit.go_to_scene(GameProgress.settings_return_path)
