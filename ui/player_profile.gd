extends Control

# Figure 31 — Player Account. "View Stats" reflects real GameProgress data;
# Achievements/Reputation are honest stubs since no such systems exist yet.

var info_panel: Control
var info_title: Label
var info_body: Label
var edit_panel: Control
var edit_field: LineEdit
var name_label: Label

func _ready() -> void:
	add_child(UIKit.full_rect_bg())

	var back := UIKit.back_button()
	back.position = Vector2(12, 12)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/chapter_select.tscn"))
	add_child(back)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := UIKit.panel(Vector2(300, 0))
	center.add_child(panel)
	var box := UIKit.vbox(14)
	panel.add_child(box)

	box.add_child(UIKit.centered_icon("res://ui/icons/person.svg", Vector2(56, 56)))
	name_label = UIKit.title_label(AuthState.username if not AuthState.username.is_empty() else "Player", 20)
	box.add_child(name_label)

	var edit_button := UIKit.styled_button("Edit Account", Color(0.3, 0.3, 0.32))
	edit_button.pressed.connect(_show_edit_account)
	box.add_child(edit_button)

	var stats_button := UIKit.styled_button("View Stats")
	stats_button.pressed.connect(_show_stats)
	box.add_child(stats_button)

	var achievements_button := UIKit.styled_button("View Achievements")
	achievements_button.pressed.connect(_show_achievements)
	box.add_child(achievements_button)

	var reputation_button := UIKit.styled_button("View Reputation")
	reputation_button.pressed.connect(_show_reputation)
	box.add_child(reputation_button)

	_build_info_panel()
	_build_edit_panel()

func _build_info_panel() -> void:
	info_panel = Control.new()
	info_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	info_panel.visible = false
	add_child(info_panel)
	info_panel.add_child(UIKit.full_rect_bg(Color(0, 0, 0, 0.55)))
	var dismiss := Button.new()
	dismiss.flat = true
	dismiss.set_anchors_preset(Control.PRESET_FULL_RECT)
	dismiss.pressed.connect(func(): info_panel.visible = false)
	info_panel.add_child(dismiss)

	var panel := UIKit.panel(Vector2(260, 0))
	info_panel.add_child(UIKit.centered(panel))
	var box := UIKit.vbox(10)
	panel.add_child(box)
	info_title = UIKit.title_label("", 18)
	box.add_child(info_title)
	info_body = UIKit.body_label("")
	box.add_child(info_body)

func _build_edit_panel() -> void:
	edit_panel = Control.new()
	edit_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	edit_panel.visible = false
	add_child(edit_panel)
	edit_panel.add_child(UIKit.full_rect_bg(Color(0, 0, 0, 0.55)))

	var panel := UIKit.panel(Vector2(260, 0))
	edit_panel.add_child(UIKit.centered(panel))
	var box := UIKit.vbox(10)
	panel.add_child(box)
	box.add_child(UIKit.title_label("Edit Account", 18))
	edit_field = UIKit.text_field("Username")
	box.add_child(edit_field)
	var row := UIKit.hbox(8)
	box.add_child(row)
	var cancel_button := UIKit.styled_button("Cancel", Color(0.3, 0.3, 0.32))
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_button.pressed.connect(func(): edit_panel.visible = false)
	row.add_child(cancel_button)
	var save_button := UIKit.styled_button("Save")
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_button.pressed.connect(_on_save_account)
	row.add_child(save_button)

func _show_edit_account() -> void:
	edit_field.text = AuthState.username
	edit_panel.visible = true

func _on_save_account() -> void:
	var new_name := edit_field.text.strip_edges()
	if not new_name.is_empty():
		AuthState.username = new_name
		name_label.text = new_name
	edit_panel.visible = false

func _show_stats() -> void:
	var completed := 0
	var total_stars := 0
	for chapter in GameProgress.stars.keys():
		total_stars += int(GameProgress.stars[chapter])
		if int(GameProgress.stars[chapter]) > 0:
			completed += 1
	_show_info("Stats", "Chapters completed: %d / %d\nTotal stars: %d" % [completed, GameProgress.TOTAL_CHAPTERS, total_stars])

func _show_achievements() -> void:
	_show_info("Achievements", "Achievements are coming in a future update.")

func _show_reputation() -> void:
	_show_info("Reputation", "Reputation tracking is coming in a future update.")

func _show_info(title: String, body: String) -> void:
	info_title.text = title
	info_body.text = body
	info_panel.visible = true
