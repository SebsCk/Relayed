extends Node

# Rule-based "Hint bot" (see the capstone manuscript's Adaptive Decision
# Layer). Watches wrong attempts and time-on-task per question to decide
# when a player is struggling, and logs chapter performance locally —
# no Firebase yet, mirrors GameProgress's user://save_data.json pattern
# until a real Firestore schema is wired up.

const LOG_PATH := "user://hint_bot_log.json"

const WRONG_ATTEMPT_THRESHOLD := 2
const TIME_STRUGGLE_SECONDS := 20.0

var _task_id: String = ""
var _wrong_attempts: int = 0
var _start_msec: int = 0
var _hint_already_shown: bool = false

func start_task(task_id: String) -> void:
	_task_id = task_id
	_wrong_attempts = 0
	_start_msec = Time.get_ticks_msec()
	_hint_already_shown = false

func time_on_task() -> float:
	return (Time.get_ticks_msec() - _start_msec) / 1000.0

# Call after a wrong attempt on the current task. Returns true the moment
# a hint should be shown (attempt threshold crossed).
func record_wrong_attempt() -> bool:
	_wrong_attempts += 1
	return _should_trigger()

# Call periodically (e.g. from a 1s Timer) to catch the time-based trigger
# even if the player hasn't attempted anything wrong yet.
func poll_time() -> bool:
	return _should_trigger()

func _should_trigger() -> bool:
	if _hint_already_shown:
		return false
	if _wrong_attempts >= WRONG_ATTEMPT_THRESHOLD or time_on_task() >= TIME_STRUGGLE_SECONDS:
		_hint_already_shown = true
		return true
	return false

# Logs one chapter's outcome: accuracy (0-1), total wrong attempts, and
# completion time in seconds.
func log_chapter_performance(chapter: int, accuracy: float, wrong_attempts: int, time_seconds: float) -> void:
	var entries := _read_log()
	entries.append({
		"chapter": chapter,
		"accuracy": accuracy,
		"wrong_attempts": wrong_attempts,
		"time_seconds": time_seconds,
		"timestamp": Time.get_datetime_string_from_system(),
	})
	var file := FileAccess.open(LOG_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(entries))
	file.close()

func _read_log() -> Array:
	if not FileAccess.file_exists(LOG_PATH):
		return []
	var file := FileAccess.open(LOG_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_ARRAY:
		return parsed
	return []
