extends Control

# Figure 29 — New Game / Continue Game chooser.

func _ready() -> void:
	add_child(UIKit.full_rect_bg())

	var back := UIKit.back_button()
	back.position = Vector2(12, 12)
	back.pressed.connect(_on_back_pressed)
	add_child(back)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var box := UIKit.vbox(16)
	center.add_child(box)
	box.add_child(UIKit.title_label("RELAYED", 34))

	var panel := UIKit.panel(Vector2(300, 0))
	box.add_child(panel)
	var panel_box := UIKit.vbox(14)
	panel.add_child(panel_box)

	var new_game_button := UIKit.styled_button("NEW GAME")
	new_game_button.pressed.connect(_on_new_game_pressed)
	panel_box.add_child(new_game_button)

	var continue_button := UIKit.styled_button("CONTINUE GAME", Color(0.3, 0.3, 0.32))
	continue_button.disabled = not GameProgress.has_save()
	continue_button.pressed.connect(_on_continue_pressed)
	panel_box.add_child(continue_button)
	if continue_button.disabled:
		panel_box.add_child(UIKit.body_label("No previous session found.", 12, Color(0.7, 0.7, 0.7)))

func _on_new_game_pressed() -> void:
	GameProgress.start_new_game()
	UIKit.go_to_scene("res://scenes/chapter_select.tscn")

func _on_continue_pressed() -> void:
	GameProgress.load_progress()
	UIKit.go_to_scene("res://scenes/chapter_select.tscn")

func _on_back_pressed() -> void:
	AuthState.logout()
	UIKit.go_to_scene("res://scenes/login.tscn")
