extends Node

# Per-chapter quest progress for hub chapters (see ChapterContent): which main
# objectives / side quests are done, which Field Notes are collected, and the
# hint/attempt/time totals gathered across the chapter's separate scenes so
# they can be logged once when the chapter is finished. Local-only save,
# same pattern as GameProgress.

const SAVE_PATH := "user://quest_data.json"
const SIDE_QUEST_XP := 20
const SIDE_QUEST_REPUTATION := 2

# Which activity scene (scenes/chapter_activity.tscn) to run next.
var active_activity: String = ""

var _data: Dictionary = {}

func _ready() -> void:
	_load()

func _entry(chapter: int) -> Dictionary:
	var key := str(chapter)
	if not _data.has(key):
		_data[key] = {
			"done": {}, "notes": [], "seen": {},
			"wrong": 0, "seconds": 0.0, "hints": 0, "successes": 0, "hint_reason": "",
		}
	return _data[key]

func is_done(chapter: int, quest_id: String) -> bool:
	var done: Dictionary = _entry(chapter)["done"]
	return done.has(quest_id)

# Returns true only the first time a quest is completed.
func complete(chapter: int, quest_id: String) -> bool:
	var done: Dictionary = _entry(chapter)["done"]
	if done.has(quest_id):
		return false
	done[quest_id] = true
	if ChapterContent.is_side_quest(chapter, quest_id):
		GameProgress.add_xp(SIDE_QUEST_XP)
		GameProgress.add_city_reputation(SIDE_QUEST_REPUTATION)
	if ChapterContent.terms(chapter).has(quest_id):
		add_note(chapter, "term_" + quest_id)
	_save()
	return true

func main_all_done(chapter: int) -> bool:
	for quest in ChapterContent.main_quests(chapter):
		if not is_done(chapter, String(quest["id"])):
			return false
	return true

func side_done_count(chapter: int) -> int:
	var count := 0
	for quest in ChapterContent.side_quests(chapter):
		if is_done(chapter, String(quest["id"])):
			count += 1
	return count

func stars_earned(chapter: int) -> int:
	if not main_all_done(chapter):
		return 0
	var side := side_done_count(chapter)
	if side >= ChapterContent.side_quests(chapter).size():
		return 3
	if side >= ChapterContent.STAR2_SIDE_QUESTS:
		return 2
	return 1

func notes(chapter: int) -> Array:
	return _entry(chapter)["notes"]

func add_note(chapter: int, note_id: String) -> bool:
	var collected: Array = _entry(chapter)["notes"]
	if collected.has(note_id):
		return false
	collected.append(note_id)
	if collected.size() >= ChapterContent.total_notes(chapter):
		GameProgress.award_badge("field_researcher")
	_save()
	return true

# Called when the player taps a building. Returns {} for buildings with no
# note (or already-read ones), else {"note": Dictionary, "quest_done": bool}.
func inspect_building(chapter: int, node_name: String) -> Dictionary:
	var chapter_notes := ChapterContent.notes(chapter)
	if not chapter_notes.has(node_name):
		return {}
	if not add_note(chapter, "note_" + node_name):
		return {}
	var all_read := true
	for key in chapter_notes.keys():
		if not notes(chapter).has("note_" + String(key)):
			all_read = false
	var quest_done := all_read and complete(chapter, "ask_around")
	return {"note": chapter_notes[node_name], "quest_done": quest_done}

func seen(chapter: int, key: String) -> bool:
	var seen_flags: Dictionary = _entry(chapter)["seen"]
	return seen_flags.has(key)

func mark_seen(chapter: int, key: String) -> void:
	var seen_flags: Dictionary = _entry(chapter)["seen"]
	seen_flags[key] = true
	_save()

func add_stats(chapter: int, wrong: int, seconds: float, hints: int, successes: int, hint_reason: String) -> void:
	var entry := _entry(chapter)
	entry["wrong"] = int(entry["wrong"]) + wrong
	entry["seconds"] = float(entry["seconds"]) + seconds
	entry["hints"] = int(entry["hints"]) + hints
	entry["successes"] = int(entry["successes"]) + successes
	if not hint_reason.is_empty():
		entry["hint_reason"] = hint_reason
	_save()

# Returns the accumulated totals and starts a fresh tally, so replaying a
# chapter doesn't double-count earlier runs in the performance log.
func consume_totals(chapter: int) -> Dictionary:
	var entry := _entry(chapter)
	var totals := {
		"wrong": int(entry["wrong"]),
		"seconds": float(entry["seconds"]),
		"hints": int(entry["hints"]),
		"successes": int(entry["successes"]),
		"hint_reason": String(entry["hint_reason"]),
	}
	entry["wrong"] = 0
	entry["seconds"] = 0.0
	entry["hints"] = 0
	entry["successes"] = 0
	entry["hint_reason"] = ""
	_save()
	return totals

func reset_all() -> void:
	_data.clear()
	_save()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_data = parsed

func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(_data))
	file.close()
