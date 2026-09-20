extends Control

# Figure 32 — Story Event / Objectives. UI is authored directly in
# scenes/story_event.tscn; this script wires up references/signals and
# fills in per-chapter dynamic text. The storyboard's hand-drawn character
# portrait needs dedicated 2D character art we don't have (the project's only
# character sprites are isometric walk-cycles, a different art style) — this
# uses a generic silhouette placeholder instead. Objective text is pulled
# from the actual win condition in ui/relayed.gd rather than invented copy,
# since no per-chapter level design exists yet beyond that one puzzle map.

# District 2 is a TelCom quiz instead of the tower-placement puzzle (see
# ui/quiz.gd). This is a direct special case, not a general "district type"
# system — worth generalizing if more non-puzzle districts get added later.
const QUIZ_CHAPTER := 2

@onready var intro_view: Control = $IntroView
@onready var objectives_view: Control = $ObjectivesView
@onready var welcome_label: Label = $IntroView/Center/Row/Bubble/BubbleBox/WelcomeLabel
@onready var objective_line_1: Label = $ObjectivesView/Center/ObjectivesPanel/ObjectivesBox/ObjectivesList/ObjectiveLine1
@onready var objective_line_2: Label = $ObjectivesView/Center/ObjectivesPanel/ObjectivesBox/ObjectivesList/ObjectiveLine2

func _ready() -> void:
	$BackButton.pressed.connect(func(): UIKit.go_to_scene("res://scenes/chapter_select.tscn"))
	$IntroView/Center/Row/Bubble/BubbleBox/ContinueButton.pressed.connect(_show_objectives)
	$ObjectivesView/Center/ObjectivesPanel/ObjectivesBox/BeginButton.pressed.connect(_on_begin_pressed)

	objectives_view.visible = false

	welcome_label.text = "Welcome to Chapter %d" % GameProgress.selected_chapter
	var is_quiz := GameProgress.selected_chapter == QUIZ_CHAPTER
	if is_quiz:
		objective_line_1.text = "• Answer every TelCom question correctly"
		objective_line_2.visible = false
	else:
		objective_line_1.text = "• Connect every building to its preferred network"
		objective_line_2.text = "• Resolve any tower congestion"
		objective_line_2.visible = true

func _show_objectives() -> void:
	intro_view.visible = false
	objectives_view.visible = true

func _on_begin_pressed() -> void:
	if GameProgress.selected_chapter == QUIZ_CHAPTER:
		UIKit.go_to_scene("res://scenes/quiz.tscn")
	else:
		UIKit.go_to_scene("res://scenes/relayed.tscn")
