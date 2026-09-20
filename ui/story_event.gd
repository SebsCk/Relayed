extends Control

# Figure 32 — Story Event / Objectives. The storyboard's hand-drawn character
# portrait needs dedicated 2D character art we don't have (the project's only
# character sprites are isometric walk-cycles, a different art style) — this
# uses a generic silhouette placeholder instead. Objective text is pulled
# from the actual win condition in ui/relayed.gd rather than invented copy,
# since no per-chapter level design exists yet beyond that one puzzle map.

const REWARD_COLORS := [Color(0.15, 0.85, 1.0), Color(0.35, 1.0, 0.45)]
const REWARD_LABELS := ["5G Bonus", "Fiber Bonus"]

# District 2 is a TelCom quiz instead of the tower-placement puzzle (see
# ui/quiz.gd). This is a direct special case, not a general "district type"
# system — worth generalizing if more non-puzzle districts get added later.
const QUIZ_CHAPTER := 2

var intro_view: Control
var objectives_view: Control

func _ready() -> void:
	add_child(UIKit.full_rect_bg())

	var back := UIKit.back_button()
	back.position = Vector2(12, 12)
	back.pressed.connect(func(): UIKit.go_to_scene("res://scenes/chapter_select.tscn"))
	add_child(back)

	intro_view = _build_intro()
	objectives_view = _build_objectives()
	add_child(intro_view)
	add_child(objectives_view)
	objectives_view.visible = false

func _build_intro() -> Control:
	var view := Control.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(center)

	var row := UIKit.hbox(16)
	center.add_child(row)

	var portrait := UIKit.icon("res://ui/icons/person.svg", Vector2(90, 120), Color(0.6, 0.6, 0.65))
	row.add_child(portrait)

	var bubble := UIKit.panel(Vector2(200, 0), Color(0.95, 0.95, 0.95, 0.95), 14)
	row.add_child(bubble)
	var bubble_box := UIKit.vbox(6)
	bubble.add_child(bubble_box)
	bubble_box.add_child(UIKit.body_label("Welcome to Chapter %d" % GameProgress.selected_chapter, 15, UIKit.TEXT_DARK))
	var continue_button := UIKit.link_button("Tap to continue ▶")
	continue_button.add_theme_color_override("font_color", Color(0.2, 0.45, 0.8))
	continue_button.pressed.connect(_show_objectives)
	bubble_box.add_child(continue_button)

	return view

func _build_objectives() -> Control:
	var view := Control.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(center)

	var panel := UIKit.panel(Vector2(300, 0))
	center.add_child(panel)
	var box := UIKit.vbox(12)
	panel.add_child(box)

	box.add_child(UIKit.title_label("OBJECTIVES", 22))

	var objectives_list := UIKit.vbox(4)
	box.add_child(objectives_list)
	var objective_lines := ["Answer every TelCom question correctly"] if GameProgress.selected_chapter == QUIZ_CHAPTER else ["Connect every building to its preferred network", "Resolve any tower congestion"]
	for line in objective_lines:
		objectives_list.add_child(UIKit.body_label("• " + line, 13))

	box.add_child(UIKit.body_label("Progress", 12, Color(0.75, 0.75, 0.75)))
	var progress := ProgressBar.new()
	progress.value = 0
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 10)
	box.add_child(progress)

	box.add_child(UIKit.body_label("Rewards:", 12, Color(0.75, 0.75, 0.75)))
	var reward_row := UIKit.hbox(10)
	reward_row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(reward_row)
	for i in range(REWARD_COLORS.size()):
		var swatch_box := UIKit.vbox(2)
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(28, 28)
		swatch.color = REWARD_COLORS[i]
		swatch_box.add_child(UIKit.centered(swatch))
		swatch_box.add_child(UIKit.body_label(REWARD_LABELS[i], 10))
		reward_row.add_child(swatch_box)

	var start_button := UIKit.styled_button("BEGIN")
	start_button.pressed.connect(_on_begin_pressed)
	box.add_child(start_button)

	return view

func _show_objectives() -> void:
	intro_view.visible = false
	objectives_view.visible = true

func _on_begin_pressed() -> void:
	if GameProgress.selected_chapter == QUIZ_CHAPTER:
		UIKit.go_to_scene("res://scenes/quiz.tscn")
	else:
		UIKit.go_to_scene("res://scenes/relayed.tscn")
