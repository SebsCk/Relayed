extends Control

# District 2's content type: a TelCom/networking trivia quiz instead of the
# tower-placement puzzle. Every district currently shares the single map in
# scenes/relayed.tscn (see PROGRESS.md) — this gives district 2 distinct
# content of its own rather than just replaying district 1's map again.
# Questions cover the TelCom concepts AGENTS.md lists as what the game
# should teach (QoS, congestion, latency, packet loss, bandwidth, routing).
# UI is authored directly in scenes/quiz.tscn; this script wires up
# references/signals and drives the fixed 4-option-button layout per question.

const QUESTIONS := [
	{
		"question": "What does QoS stand for?",
		"options": ["Quality of Service", "Queue over Server", "Quick Online Signal", "Quantum of Speed"],
		"correct": 0,
		"explanation": "QoS lets a network prioritize certain traffic types over others on the same link.",
	},
	{
		"question": "What happens when a link carries more traffic than it can handle?",
		"options": ["Congestion", "Encryption", "Compression", "Amplification"],
		"correct": 0,
		"explanation": "Congestion is what slows or drops traffic once a link exceeds its capacity.",
	},
	{
		"question": "What is \"latency\"?",
		"options": ["Delay before data arrives", "Total bandwidth", "Number of devices", "Signal strength"],
		"correct": 0,
		"explanation": "Latency is the time it takes a signal to travel from source to destination.",
	},
	{
		"question": "What typically causes packet loss?",
		"options": ["Unresolved congestion", "Too much bandwidth", "A strong signal", "Fast routing"],
		"correct": 0,
		"explanation": "When congestion isn't relieved, the network starts dropping packets instead of delivering them.",
	},
	{
		"question": "What does \"bandwidth allocation\" control?",
		"options": ["Routing capacity per connection", "Signal travel distance", "Number of towers", "Construction speed"],
		"correct": 0,
		"explanation": "Bandwidth allocation is how much data-carrying capacity gets assigned between nodes.",
	},
	{
		"question": "What is the goal of network routing?",
		"options": ["Finding a path to the destination", "Increasing total bandwidth", "Reducing tower cost", "Encrypting traffic"],
		"correct": 0,
		"explanation": "Routing finds — and keeps finding — a valid path for signals to travel across the network.",
	},
]

var current_index := 0
var score := 0

@onready var progress_label: Label = $Center/QuizPanel/QuizBox/ProgressLabel
@onready var question_label: Label = $Center/QuizPanel/QuizBox/QuestionLabel
@onready var option_buttons: Array[Button] = [
	$Center/QuizPanel/QuizBox/OptionButton0,
	$Center/QuizPanel/QuizBox/OptionButton1,
	$Center/QuizPanel/QuizBox/OptionButton2,
	$Center/QuizPanel/QuizBox/OptionButton3,
]
@onready var feedback_label: Label = $Center/QuizPanel/QuizBox/FeedbackLabel
@onready var continue_button: Button = $Center/QuizPanel/QuizBox/ContinueButton
@onready var overlay: Control = $CompletionOverlay
@onready var summary_label: Label = $CompletionOverlay/CompletionCenter/CompletionPanel/CompletionBox/Summary
@onready var next_button: Button = $CompletionOverlay/CompletionCenter/CompletionPanel/CompletionBox/NextButton

func _ready() -> void:
	$BackButton.pressed.connect(func(): UIKit.go_to_scene("res://scenes/chapter_select.tscn"))
	$SettingsButton.pressed.connect(func(): UIKit.show_in_game_settings(self, "Quiz progress will be lost."))

	for i in range(option_buttons.size()):
		option_buttons[i].pressed.connect(_on_option_pressed.bind(i))
	continue_button.pressed.connect(_on_continue_pressed)
	next_button.pressed.connect(_on_next_pressed)

	_show_question()

func _show_question() -> void:
	var data: Dictionary = QUESTIONS[current_index]
	progress_label.text = "Question %d of %d" % [current_index + 1, QUESTIONS.size()]
	question_label.text = data["question"]
	feedback_label.visible = false
	continue_button.visible = false
	for i in range(option_buttons.size()):
		var option_button := option_buttons[i]
		option_button.text = data["options"][i]
		option_button.disabled = false
		option_button.modulate = Color.WHITE

func _on_option_pressed(index: int) -> void:
	var data: Dictionary = QUESTIONS[current_index]
	var correct_index: int = data["correct"]
	if index == correct_index:
		for option_button in option_buttons:
			option_button.disabled = true
		option_buttons[index].modulate = Color(0.5, 1.0, 0.55)
		feedback_label.text = "Correct! " + String(data["explanation"])
		feedback_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
		feedback_label.visible = true
		continue_button.visible = true
		score += 1
	else:
		option_buttons[index].modulate = Color(1.0, 0.55, 0.55)
		feedback_label.text = "Not quite — try again."
		feedback_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.6))
		feedback_label.visible = true

func _on_continue_pressed() -> void:
	current_index += 1
	if current_index >= QUESTIONS.size():
		_show_completion()
	else:
		_show_question()

func _show_completion() -> void:
	overlay.visible = true
	summary_label.text = "You answered every question correctly. Final score: %d / %d" % [score, QUESTIONS.size()]
	# Flat 3-star award until a real per-district scoring rubric exists,
	# matching the puzzle's own current placeholder rubric.
	GameProgress.set_chapter_stars(GameProgress.selected_chapter, 3)
	GameProgress.unlock_next_chapter()
	if GameProgress.selected_chapter < GameProgress.TOTAL_CHAPTERS:
		next_button.text = "Next District"
	else:
		next_button.text = "Back to Districts"

func _on_next_pressed() -> void:
	if GameProgress.selected_chapter < GameProgress.TOTAL_CHAPTERS:
		GameProgress.selected_chapter += 1
		UIKit.go_to_scene("res://scenes/story_event.tscn")
	else:
		UIKit.go_to_scene("res://scenes/chapter_select.tscn")
