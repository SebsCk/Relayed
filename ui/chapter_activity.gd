extends Control

# Short story activities for hub chapters, chosen by QuestTracker.active_activity:
#   first_call       - pick a medium that can carry a message
#   follow_message   - watch a message travel, then name sender / medium / receiver
#   any key of ChapterContent's "quiz_sets" - a short multiple-choice side quest
# Wrong answers are never punished; the Hint Bot offers a hint after repeated
# misses or a long pause. The layout is real nodes in
# scenes/chapter_activity.tscn (everything starts hidden); this script shows
# the pieces each activity needs and fills in their text.

const HUB_SCENE := "res://scenes/chapter_hub.tscn"
const SEND_SECONDS := 1.8
# Mirrors ScenarioView.State (BLACKOUT, LINKED, ONLINE).
const SCENARIO_BLACKOUT := 0
const SCENARIO_LINKED := 1
const SCENARIO_ONLINE := 2
const CORRECT_COLOR := Color(0.5, 1.0, 0.55)
const WRONG_COLOR := Color(1.0, 0.55, 0.55)

var chapter: int
var activity: String
var content: Dictionary
var spec: Dictionary

var _current_hint := ""
var _start_msec := 0
var _wrong := 0
var _successes := 0
var _quiz_index := 0
var _role_done: Array = []

@onready var stage: VBoxContainer = $Scroll/Margin/Stage
@onready var title_label: Label = $Scroll/Margin/Stage/TitleLabel
@onready var scenario: Control = $Scroll/Margin/Stage/Scenario
@onready var progress_label: Label = $Scroll/Margin/Stage/ProgressLabel
@onready var prompt_label: Label = $Scroll/Margin/Stage/PromptLabel
@onready var options_box: VBoxContainer = $Scroll/Margin/Stage/OptionsBox
@onready var option_buttons: Array[Button] = [
	$Scroll/Margin/Stage/OptionsBox/Option1,
	$Scroll/Margin/Stage/OptionsBox/Option2,
	$Scroll/Margin/Stage/OptionsBox/Option3,
	$Scroll/Margin/Stage/OptionsBox/Option4,
]
@onready var send_button: Button = $Scroll/Margin/Stage/SendButton
@onready var watch_label: Label = $Scroll/Margin/Stage/WatchLabel
@onready var roles_box: VBoxContainer = $Scroll/Margin/Stage/RolesBox
@onready var role_labels: Array[Label] = [
	$Scroll/Margin/Stage/RolesBox/Role1Label,
	$Scroll/Margin/Stage/RolesBox/Role2Label,
	$Scroll/Margin/Stage/RolesBox/Role3Label,
]
@onready var role_buttons: Array = [
	[$Scroll/Margin/Stage/RolesBox/Role1Row/Role1Button1, $Scroll/Margin/Stage/RolesBox/Role1Row/Role1Button2, $Scroll/Margin/Stage/RolesBox/Role1Row/Role1Button3],
	[$Scroll/Margin/Stage/RolesBox/Role2Row/Role2Button1, $Scroll/Margin/Stage/RolesBox/Role2Row/Role2Button2, $Scroll/Margin/Stage/RolesBox/Role2Row/Role2Button3],
	[$Scroll/Margin/Stage/RolesBox/Role3Row/Role3Button1, $Scroll/Margin/Stage/RolesBox/Role3Row/Role3Button2, $Scroll/Margin/Stage/RolesBox/Role3Row/Role3Button3],
]
@onready var feedback_label: Label = $Scroll/Margin/Stage/FeedbackLabel
@onready var hint_label: Label = $Scroll/Margin/Stage/HintLabel
@onready var next_button: Button = $Scroll/Margin/Stage/NextButton
@onready var complete_box: VBoxContainer = $Scroll/Margin/Stage/CompleteBox
@onready var complete_message: Label = $Scroll/Margin/Stage/CompleteBox/CompleteMessage
@onready var reward_label: Label = $Scroll/Margin/Stage/CompleteBox/RewardLabel
@onready var hint_timer: Timer = $HintTimer

func _ready() -> void:
	chapter = GameProgress.selected_chapter
	activity = QuestTracker.active_activity
	content = ChapterContent.get_chapter(chapter)
	_start_msec = Time.get_ticks_msec()
	HintBot.begin_session()

	$BackButton.pressed.connect(func(): UIKit.go_to_scene(HUB_SCENE))
	$Scroll/Margin/Stage/CompleteBox/BackToHubButton.pressed.connect(func(): UIKit.go_to_scene(HUB_SCENE))
	hint_timer.timeout.connect(_on_hint_timer_timeout)
	for i in range(option_buttons.size()):
		option_buttons[i].pressed.connect(_on_option_pressed.bind(i))
	for r in range(role_buttons.size()):
		for c in range(role_buttons[r].size()):
			role_buttons[r][c].pressed.connect(_on_role_chosen.bind(r, c))
	send_button.pressed.connect(_on_send_pressed)
	next_button.pressed.connect(_on_quiz_next)

	var quiz_sets: Dictionary = content.get("quiz_sets", {})
	if activity == "first_call":
		_run_first_call()
	elif activity == "follow_message":
		_run_follow_message()
	elif quiz_sets.has(activity):
		_run_quiz()
	else:
		UIKit.go_to_scene(HUB_SCENE)

func _play_dialogue(lines: Array, skip_key: String) -> void:
	var box := DialogueBox.play(self, lines, QuestTracker.seen(chapter, skip_key))
	await box.finished
	QuestTracker.mark_seen(chapter, skip_key)

func _begin_task(task_suffix: String, hint: String) -> void:
	HintBot.start_task("chapter_%d_%s_%s" % [chapter, activity, task_suffix])
	_current_hint = hint
	hint_label.visible = false

func _show_hint() -> void:
	hint_label.text = "Hint: " + _current_hint
	hint_label.visible = true

func _on_hint_timer_timeout() -> void:
	if _current_hint.is_empty() or hint_label.visible:
		return
	if HintBot.poll_time():
		_show_hint()

func _wrong_answer(message: String) -> void:
	_wrong += 1
	feedback_label.text = message
	feedback_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.6))
	feedback_label.visible = true
	if HintBot.record_wrong_attempt():
		_show_hint()

func _right_answer(message: String) -> void:
	_successes += 1
	feedback_label.text = message
	feedback_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	feedback_label.visible = true

func _send_message(on_arrived: Callable) -> void:
	scenario.message_arrived.connect(on_arrived, CONNECT_ONE_SHOT)
	scenario.send_message(SEND_SECONDS)

# --- Objective 1: first call ---------------------------------------------

func _run_first_call() -> void:
	spec = content["first_call"]
	title_label.text = "First call"
	scenario.visible = true
	scenario.set_state(SCENARIO_BLACKOUT)
	prompt_label.text = String(spec["prompt"])
	prompt_label.visible = true
	var options: Array = spec["options"]
	options_box.visible = true
	for i in range(option_buttons.size()):
		option_buttons[i].visible = i < options.size()
		if i < options.size():
			option_buttons[i].text = String(options[i])
	_begin_task("medium", String(spec["hint"]))
	_play_dialogue(spec["intro"], "first_call_intro")

func _on_option_pressed(index: int) -> void:
	if activity == "first_call":
		_on_first_call_choice(index)
	else:
		_on_quiz_choice(index)

func _on_first_call_choice(index: int) -> void:
	var correct: Array = spec["correct"]
	var button := option_buttons[index]
	if not correct.has(index):
		button.modulate = WRONG_COLOR
		_wrong_answer(String(spec["wrong_feedback"]))
		return
	for other in option_buttons:
		other.disabled = true
	button.modulate = CORRECT_COLOR
	scenario.set_link_kind("cable" if index == 1 else "radio")
	scenario.set_state(SCENARIO_LINKED)
	_right_answer("Sending the message...")
	_send_message(_on_first_call_arrived)

func _on_first_call_arrived() -> void:
	scenario.set_state(SCENARIO_ONLINE)
	await _play_dialogue(spec["done"], "first_call_done")
	_finish("first_call", "First call complete. You picked a medium to carry the message.")

# --- Objective 2: follow the message ---------------------------------------

func _run_follow_message() -> void:
	spec = content["follow_message"]
	title_label.text = "Follow the message"
	scenario.visible = true
	scenario.set_link_kind("radio")
	scenario.set_state(SCENARIO_LINKED)
	send_button.text = "Send message"
	send_button.visible = true
	watch_label.visible = true
	roles_box.visible = true
	_begin_task("roles", String(spec["hint"]))

	var roles: Array = spec["roles"]
	var rows: Array = spec["rows"]
	_role_done.clear()
	for r in range(role_buttons.size()):
		_role_done.append(false)
		var row_spec: Dictionary = rows[r]
		role_labels[r].text = "%s is the..." % String(row_spec["part"])
		for c in range(role_buttons[r].size()):
			var button: Button = role_buttons[r][c]
			button.text = String(roles[c])
			button.disabled = true
	_play_dialogue(spec["intro"], "follow_message_intro")

func _on_send_pressed() -> void:
	send_button.disabled = true
	_send_message(_on_message_arrived)

func _on_message_arrived() -> void:
	send_button.text = "Send again"
	send_button.disabled = false
	for r in range(role_buttons.size()):
		if _role_done[r]:
			continue
		for button in role_buttons[r]:
			(button as Button).disabled = false

func _on_role_chosen(row_index: int, choice: int) -> void:
	var rows: Array = spec["rows"]
	var row_spec: Dictionary = rows[row_index]
	var button: Button = role_buttons[row_index][choice]
	if int(row_spec["role"]) != choice:
		button.modulate = WRONG_COLOR
		_wrong_answer(String(spec["wrong_feedback"]))
		return
	for other in role_buttons[row_index]:
		other.disabled = true
	button.modulate = CORRECT_COLOR
	_role_done[row_index] = true
	var roles: Array = spec["roles"]
	scenario.set_tag(["clinic", "link", "hospital"][row_index], String(roles[choice]))
	_right_answer("Correct.")
	if not _role_done.has(false):
		send_button.disabled = true
		scenario.set_state(SCENARIO_ONLINE)
		await _play_dialogue(spec["done"], "follow_message_done")
		_finish("follow_message", "Follow the message complete. You named the sender, medium and receiver.")

# --- Side quests: multiple-choice sets -------------------------------------

func _run_quiz() -> void:
	var quiz_sets: Dictionary = content["quiz_sets"]
	spec = quiz_sets[activity]
	title_label.text = String(spec["title"])
	progress_label.visible = true
	prompt_label.visible = true
	options_box.visible = true
	_quiz_index = 0
	_show_quiz_question()
	if spec.has("intro"):
		_play_dialogue(spec["intro"], activity + "_intro")

func _show_quiz_question() -> void:
	var questions: Array = spec["questions"]
	var data: Dictionary = questions[_quiz_index]
	progress_label.text = "Question %d of %d" % [_quiz_index + 1, questions.size()]
	prompt_label.text = String(data["question"])
	var options: Array = data["options"]
	for i in range(option_buttons.size()):
		option_buttons[i].visible = i < options.size()
		option_buttons[i].disabled = false
		option_buttons[i].modulate = Color.WHITE
		if i < options.size():
			option_buttons[i].text = String(options[i])
	feedback_label.visible = false
	next_button.visible = false
	_begin_task("q%d" % _quiz_index, String(data["hint"]))

func _on_quiz_choice(index: int) -> void:
	var questions: Array = spec["questions"]
	var data: Dictionary = questions[_quiz_index]
	var button := option_buttons[index]
	if index != int(data["correct"]):
		button.modulate = WRONG_COLOR
		_wrong_answer("Not quite. Try another answer.")
		return
	for other in option_buttons:
		other.disabled = true
	button.modulate = CORRECT_COLOR
	_right_answer("Correct! " + String(data["explanation"]))
	if data.has("note") and QuestTracker.add_note(chapter, "note_" + String(data["note"])):
		var note: Dictionary = ChapterContent.notes(chapter)[String(data["note"])]
		DialogueBox.toast(self, "Field note added: %s" % String(note["title"]))
	next_button.text = "Finish" if _quiz_index == questions.size() - 1 else "Next"
	next_button.visible = true

func _on_quiz_next() -> void:
	var questions: Array = spec["questions"]
	_quiz_index += 1
	if _quiz_index >= questions.size():
		_finish(activity, String(spec["done"]))
	else:
		_show_quiz_question()

# --- Completion ---------------------------------------------------------------

func _finish(quest_id: String, message: String) -> void:
	var newly_done := QuestTracker.complete(chapter, quest_id)
	var seconds := (Time.get_ticks_msec() - _start_msec) / 1000.0
	QuestTracker.add_stats(chapter, _wrong, seconds, HintBot.hints_used(), _successes, HintBot.last_hint_reason())
	hint_timer.stop()

	for child in stage.get_children():
		child.visible = false
	title_label.text = "Complete!"
	title_label.visible = true
	complete_box.visible = true
	complete_message.text = message
	reward_label.visible = newly_done and ChapterContent.is_side_quest(chapter, quest_id)
	reward_label.text = "Side quest reward: +%d XP" % QuestTracker.SIDE_QUEST_XP
