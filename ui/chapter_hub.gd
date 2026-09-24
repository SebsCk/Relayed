extends Control

# Chapter hub for story chapters (see ChapterContent.HUB_CHAPTERS): lists the
# main objectives (played in order), the optional side quests, and the Field
# Notes. Stars come from how much the player explored, never from speed.
# The layout is real nodes in scenes/chapter_hub.tscn (3 main cards, 4 side
# cards, 7 note rows, both overlays); this script only fills in text and
# button states from ChapterContent / QuestTracker.

const MUTED := Color(0.72, 0.72, 0.76)
const DONE_COLOR := Color(0.45, 0.85, 0.5)
const PUZZLE_SCENE := "res://scenes/relayed.tscn"
const ACTIVITY_SCENE := "res://scenes/chapter_activity.tscn"

var chapter: int
var content: Dictionary

@onready var title_label: Label = $Scroll/Margin/Body/TitleLabel
@onready var topic_label: Label = $Scroll/Margin/Body/TopicLabel
@onready var stars_label: Label = $Scroll/Margin/Body/StarsLabel
@onready var scenario: Control = $Scroll/Margin/Body/Scenario
@onready var main_cards: Array[Node] = [
	$Scroll/Margin/Body/MainCard1,
	$Scroll/Margin/Body/MainCard2,
	$Scroll/Margin/Body/MainCard3,
]
@onready var side_cards: Array[Node] = [
	$Scroll/Margin/Body/SideCard1,
	$Scroll/Margin/Body/SideCard2,
	$Scroll/Margin/Body/SideCard3,
	$Scroll/Margin/Body/SideCard4,
]
@onready var notes_card: Node = $Scroll/Margin/Body/NotesCard
@onready var finish_button: Button = $Scroll/Margin/Body/FinishButton
@onready var finish_hint: Label = $Scroll/Margin/Body/FinishHint
@onready var notes_layer: CanvasLayer = $FieldNotesLayer
@onready var note_rows: Array[Node] = [
	$FieldNotesLayer/Margin/Panel/Column/NotesScroll/NoteList/NoteRow1,
	$FieldNotesLayer/Margin/Panel/Column/NotesScroll/NoteList/NoteRow2,
	$FieldNotesLayer/Margin/Panel/Column/NotesScroll/NoteList/NoteRow3,
	$FieldNotesLayer/Margin/Panel/Column/NotesScroll/NoteList/NoteRow4,
	$FieldNotesLayer/Margin/Panel/Column/NotesScroll/NoteList/NoteRow5,
	$FieldNotesLayer/Margin/Panel/Column/NotesScroll/NoteList/NoteRow6,
	$FieldNotesLayer/Margin/Panel/Column/NotesScroll/NoteList/NoteRow7,
]
@onready var result_layer: CanvasLayer = $ResultLayer
@onready var result_stars_label: Label = $ResultLayer/Center/ResultPanel/Box/ResultStars

func _ready() -> void:
	chapter = GameProgress.selected_chapter
	content = ChapterContent.get_chapter(chapter)

	$BackButton.pressed.connect(func(): UIKit.go_to_scene("res://scenes/chapter_select.tscn"))
	finish_button.pressed.connect(_finish_chapter)
	$FieldNotesLayer/Margin/Panel/Column/CloseNotesButton.pressed.connect(func(): notes_layer.visible = false)
	$ResultLayer/Center/ResultPanel/Box/ToChaptersButton.pressed.connect(func(): UIKit.go_to_scene("res://scenes/chapter_select.tscn"))
	$ResultLayer/Center/ResultPanel/Box/KeepExploringButton.pressed.connect(func():
		result_layer.visible = false
		_refresh()
	)

	# Buttons are wired once by card position; _refresh() only changes text
	# and enabled state.
	var mains: Array = ChapterContent.main_quests(chapter)
	for i in range(main_cards.size()):
		if i < mains.size():
			_card_button(main_cards[i]).pressed.connect(_launch_main.bind(String(mains[i]["id"])))
	var sides: Array = ChapterContent.side_quests(chapter)
	for i in range(side_cards.size()):
		if i < sides.size():
			_card_button(side_cards[i]).pressed.connect(_launch_side.bind(String(sides[i]["id"]), bool(sides[i]["needs_puzzle"])))
	_card_button(notes_card).pressed.connect(_show_field_notes)

	_refresh()
	if not QuestTracker.seen(chapter, "intro"):
		_play_intro()

func _play_intro() -> void:
	var box := DialogueBox.play(self, content["intro"], false)
	await box.finished
	QuestTracker.mark_seen(chapter, "intro")

func _card_button(card: Node) -> Button:
	return card.get_node("Box/ActionButton") as Button

func _set_card(card: Node, title: String, desc: String, status: String, done: bool, button_text: String, enabled: bool) -> void:
	(card.get_node("Box/Head/NameLabel") as Label).text = title
	var status_label := card.get_node("Box/Head/StatusLabel") as Label
	status_label.text = status
	status_label.add_theme_color_override("font_color", DONE_COLOR if done else MUTED)
	(card.get_node("Box/DescLabel") as Label).text = desc
	var button := _card_button(card)
	button.text = button_text
	button.disabled = not enabled

func _refresh() -> void:
	# 0 = blackout, 1 = link built, 2 = block online (ScenarioView.State).
	if QuestTracker.is_done(chapter, "bring_online"):
		scenario.set_state(2)
	elif QuestTracker.is_done(chapter, "first_call"):
		scenario.set_state(1)
	else:
		scenario.set_state(0)
	title_label.text = "Chapter %d: %s" % [chapter, String(content["title"])]
	topic_label.text = "Topic: %s" % String(content["topic"])
	stars_label.text = "Stars this run: %d / 3\n1 star: finish all main objectives.\n2 stars: also finish %d side quests.\n3 stars: finish every side quest.\nSpeed never counts. Take your time." % [
		QuestTracker.stars_earned(chapter), ChapterContent.STAR2_SIDE_QUESTS]

	var mains: Array = ChapterContent.main_quests(chapter)
	var previous_done := true
	for i in range(main_cards.size()):
		main_cards[i].visible = i < mains.size()
		if i >= mains.size():
			continue
		var quest: Dictionary = mains[i]
		var done := QuestTracker.is_done(chapter, String(quest["id"]))
		var unlocked := previous_done
		var status := "Done" if done else ("Ready" if unlocked else "Locked")
		_set_card(main_cards[i], "%d. %s" % [i + 1, String(quest["title"])], String(quest["desc"]), status, done, "Replay" if done else "Start", unlocked)
		previous_done = done

	var puzzle_unlocked := QuestTracker.is_done(chapter, "follow_message")
	var sides: Array = ChapterContent.side_quests(chapter)
	for i in range(side_cards.size()):
		side_cards[i].visible = i < sides.size()
		if i >= sides.size():
			continue
		var side_quest: Dictionary = sides[i]
		var quest_id := String(side_quest["id"])
		var done := QuestTracker.is_done(chapter, quest_id)
		var needs_puzzle: bool = side_quest["needs_puzzle"]
		var desc := String(side_quest["desc"])
		if quest_id == "budget":
			desc += " Target: %d towers or fewer." % ChapterContent.BUDGET_MAX_SITES
		if quest_id == "ask_around":
			desc += " (%d / %d read)" % [_building_notes_read(), ChapterContent.notes(chapter).size()]
		var status := "Done" if done else "Optional"
		var button_text := "Replay" if done else "Play"
		if needs_puzzle:
			button_text = "Go to the block"
			if not puzzle_unlocked:
				status = "Locked"
				desc += " Unlocks after Follow the message."
		_set_card(side_cards[i], String(side_quest["title"]), desc, status, done, button_text, puzzle_unlocked or not needs_puzzle)

	var note_count := QuestTracker.notes(chapter).size()
	var total_notes := ChapterContent.total_notes(chapter)
	_set_card(notes_card, "Field Notes", "Things you have learned and heard around the city.", "%d / %d" % [note_count, total_notes], note_count >= total_notes, "Open Field Notes", true)

	finish_button.disabled = not QuestTracker.main_all_done(chapter)
	finish_hint.visible = finish_button.disabled

func _building_notes_read() -> int:
	var count := 0
	for key in ChapterContent.notes(chapter).keys():
		if QuestTracker.notes(chapter).has("note_" + String(key)):
			count += 1
	return count

func _launch_main(quest_id: String) -> void:
	if quest_id == "bring_online":
		UIKit.go_to_scene(PUZZLE_SCENE)
	else:
		QuestTracker.active_activity = quest_id
		UIKit.go_to_scene(ACTIVITY_SCENE)

func _launch_side(quest_id: String, needs_puzzle: bool) -> void:
	if needs_puzzle:
		UIKit.go_to_scene(PUZZLE_SCENE)
	else:
		QuestTracker.active_activity = quest_id
		UIKit.go_to_scene(ACTIVITY_SCENE)

func _show_field_notes() -> void:
	var collected := QuestTracker.notes(chapter)
	var entries: Array = []
	var terms := ChapterContent.terms(chapter)
	for key in terms.keys():
		var term: Dictionary = terms[key]
		entries.append({"unlocked": collected.has("term_" + String(key)), "title": String(term["title"]), "text": String(term["text"])})
	var notes := ChapterContent.notes(chapter)
	for key in notes.keys():
		var note: Dictionary = notes[key]
		entries.append({"unlocked": collected.has("note_" + String(key)), "title": String(note["title"]), "text": String(note["text"])})

	for i in range(note_rows.size()):
		note_rows[i].visible = i < entries.size()
		if i >= entries.size():
			continue
		var entry: Dictionary = entries[i]
		var unlocked: bool = entry["unlocked"]
		var title := note_rows[i].get_node("TitleLabel") as Label
		var text := note_rows[i].get_node("TextLabel") as Label
		title.text = String(entry["title"]) if unlocked else "???"
		title.add_theme_color_override("font_color", Color(0.95, 0.8, 0.4) if unlocked else MUTED)
		text.text = String(entry["text"]) if unlocked else "Not discovered yet."
		text.add_theme_color_override("font_color", UIKit.TEXT_LIGHT if unlocked else MUTED)
	notes_layer.visible = true

func _finish_chapter() -> void:
	var stars := QuestTracker.stars_earned(chapter)
	var lines: Array = (content["outro"] as Array).duplicate()
	var by_stars: Dictionary = content["outro_by_stars"]
	lines.append({"speaker": "Mayor Santos", "text": String(by_stars[stars])})
	var box := DialogueBox.play(self, lines, QuestTracker.seen(chapter, "outro"))
	await box.finished
	QuestTracker.mark_seen(chapter, "outro")

	var totals := QuestTracker.consume_totals(chapter)
	var successes: int = totals["successes"]
	var wrong: int = totals["wrong"]
	var accuracy := 1.0 if successes + wrong == 0 else successes / float(successes + wrong)
	HintBot.log_chapter_performance(chapter, accuracy, wrong, totals["seconds"], totals["hints"], totals["hint_reason"])
	if int(totals["hints"]) == 0:
		GameProgress.award_badge("solo_signal")
	GameProgress.set_chapter_stars(chapter, stars)
	# unlock_next_chapter() advances unconditionally, so only call it the
	# first time this chapter is the furthest one reached.
	if GameProgress.unlocked_chapters <= chapter:
		GameProgress.unlock_next_chapter()
	result_stars_label.text = "Stars earned: %d / 3" % stars
	result_layer.visible = true
