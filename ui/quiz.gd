extends Control

# District 2's content type: a TelCom/networking trivia quiz instead of the
# tower-placement puzzle. Every district currently shares the single map in
# scenes/relayed.tscn (see PROGRESS.md) — this gives district 2 distinct
# content of its own rather than just replaying district 1's map again.
# Questions cover the TelCom concepts AGENTS.md lists as what the game
# should teach (QoS, congestion, latency, packet loss, bandwidth, routing).

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

var question_label: Label
var option_buttons: Array[Button] = []
var feedback_label: Label
var continue_button: Button
var progress_label: Label
var overlay: Control

func _ready() -> void:
	add_child(UIKit.full_rect_bg())
	_build_top_bar()
	_build_quiz_panel()
	_build_completion_overlay()
	_show_question()

func _build_top_bar() -> void:
	var back := UIKit.back_button()
	back.position = Vector2(12, 12)
	back.pressed.connect(func(): UIKit.go_to_scene("res://scenes/chapter_select.tscn"))
	add_child(back)

	var settings_button := Button.new()
	settings_button.flat = true
	settings_button.custom_minimum_size = Vector2(44, 44)
	settings_button.anchor_left = 1.0
	settings_button.anchor_right = 1.0
	settings_button.position = Vector2(-56, 12)
	settings_button.add_child(UIKit.icon("res://ui/icons/gear.svg", Vector2(26, 26)))
	settings_button.pressed.connect(func(): UIKit.show_in_game_settings(self, "Quiz progress will be lost."))
	add_child(settings_button)

func _build_quiz_panel() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := UIKit.panel(Vector2(320, 0))
	center.add_child(panel)
	var box := UIKit.vbox(10)
	panel.add_child(box)

	progress_label = UIKit.body_label("", 12, Color(0.75, 0.75, 0.75))
	box.add_child(progress_label)

	question_label = UIKit.title_label("", 17)
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(question_label)

	for i in range(4):
		var option_button := UIKit.styled_button("", Color(0.3, 0.3, 0.32))
		option_button.custom_minimum_size = Vector2(0, 40)
		option_button.add_theme_font_size_override("font_size", 14)
		option_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		option_button.pressed.connect(_on_option_pressed.bind(i))
		box.add_child(option_button)
		option_buttons.append(option_button)

	feedback_label = UIKit.body_label("", 13)
	feedback_label.visible = false
	box.add_child(feedback_label)

	continue_button = UIKit.styled_button("Continue")
	continue_button.visible = false
	continue_button.pressed.connect(_on_continue_pressed)
	box.add_child(continue_button)

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

func _build_completion_overlay() -> void:
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	add_child(overlay)
	overlay.add_child(UIKit.full_rect_bg(Color(0, 0, 0, 0.6)))

	var panel := UIKit.panel(Vector2(280, 0))
	overlay.add_child(UIKit.centered(panel))
	var box := UIKit.vbox(12)
	panel.add_child(box)

	box.add_child(UIKit.title_label("District Complete!", 22))
	var summary := UIKit.body_label("")
	summary.name = "Summary"
	box.add_child(summary)

	var next_button := UIKit.styled_button("")
	next_button.name = "NextButton"
	next_button.pressed.connect(_on_next_pressed)
	box.add_child(next_button)

func _show_completion() -> void:
	overlay.visible = true
	var summary := overlay.find_child("Summary") as Label
	summary.text = "You answered every question correctly. Final score: %d / %d" % [score, QUESTIONS.size()]
	# Flat 3-star award until a real per-district scoring rubric exists,
	# matching the puzzle's own current placeholder rubric.
	GameProgress.set_chapter_stars(GameProgress.selected_chapter, 3)
	GameProgress.unlock_next_chapter()
	var next_button := overlay.find_child("NextButton") as Button
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
