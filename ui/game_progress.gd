extends Node

# Local save for campaign progress, matching AGENTS.md's Save System section
# ("Local save: user://save_data.json via Godot's FileAccess"). This is
# intentionally minimal: chapter unlock state and per-chapter stars. It does
# not yet cover in-round puzzle state (credits/score/placements) — that still
# lives only in ui/relayed.gd for the current session.

const SAVE_PATH := "user://save_data.json"
const TOTAL_CHAPTERS := 6

var unlocked_chapters: int = 1
var stars: Dictionary = {}
var selected_chapter: int = 1
var settings_return_path: String = "res://scenes/chapter_select.tscn"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func start_new_game() -> void:
	unlocked_chapters = 1
	stars.clear()
	save_progress()

func load_progress() -> void:
	if not has_save():
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	unlocked_chapters = int(parsed.get("unlocked_chapters", 1))
	stars.clear()
	var raw_stars = parsed.get("stars", {})
	if typeof(raw_stars) == TYPE_DICTIONARY:
		for key in raw_stars.keys():
			stars[int(key)] = int(raw_stars[key])

func save_progress() -> void:
	var data := {"unlocked_chapters": unlocked_chapters, "stars": stars}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func unlock_next_chapter() -> void:
	if unlocked_chapters < TOTAL_CHAPTERS:
		unlocked_chapters += 1
		save_progress()

func set_chapter_stars(chapter: int, count: int) -> void:
	stars[chapter] = max(int(stars.get(chapter, 0)), count)
	save_progress()

func stars_for(chapter: int) -> int:
	return int(stars.get(chapter, 0))

func is_unlocked(chapter: int) -> bool:
	return chapter <= unlocked_chapters
