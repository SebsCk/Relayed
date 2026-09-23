extends Node

# Local save for campaign progress. Local-only — matches AGENTS.md's Save
# System section (user://save_data.json via FileAccess), no Firebase yet
# (see the capstone manuscript's Player Profile / Save Data collections for
# the eventual cloud schema this is standing in for).

const SAVE_PATH := "user://save_data.json"
const TOTAL_CHAPTERS := 10
const STARTING_INFRASTRUCTURE_FUND := 600

# Districts group a range of chapters (manuscript: DISTRICTS.chapter_range),
# and each District is split into Zones, each spanning its own sub-range of
# chapters — the chapter select map draws one diamond per Zone with its
# chapters fanned out beneath it. Layout follows the user's District 1
# sketch (Zone 1: 1-4, Zone 2: 5-7, Zone 3: 8-10). The later districts have
# no chapters yet (empty range, no zones) — they're shown as locked
# "coming soon" sections until their chapters are designed.
const DISTRICTS := [
	{"name": "District 1", "start": 1, "end": 10, "zones": [
		{"name": "Zone 1", "start": 1, "end": 4},
		{"name": "Zone 2", "start": 5, "end": 7},
		{"name": "Zone 3", "start": 8, "end": 10},
	]},
	{"name": "Downtown District", "start": 0, "end": -1, "zones": []},
	{"name": "Suburban District", "start": 0, "end": -1, "zones": []},
	{"name": "Industrial District", "start": 0, "end": -1, "zones": []},
]

# Administration Rank is a title derived from XP (manuscript: Player
# Profile.administration_rank, default "Trainee").
const RANK_THRESHOLDS := [
	{"xp": 0, "rank": "Trainee"},
	{"xp": 200, "rank": "Technician"},
	{"xp": 500, "rank": "Administrator"},
	{"xp": 1000, "rank": "Senior Administrator"},
	{"xp": 2000, "rank": "Chief Administrator"},
]

const XP_PER_CHAPTER := 100
const REPUTATION_PER_CHAPTER := 10

var unlocked_chapters: int = 1
var stars: Dictionary = {}
var selected_chapter: int = 1
var settings_return_path: String = "res://scenes/chapter_select.tscn"

var infrastructure_fund: int = STARTING_INFRASTRUCTURE_FUND
var xp: int = 0
var city_reputation: int = 0
var badges: Array = []

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func start_new_game() -> void:
	unlocked_chapters = 1
	stars.clear()
	infrastructure_fund = STARTING_INFRASTRUCTURE_FUND
	xp = 0
	city_reputation = 0
	badges.clear()
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
	infrastructure_fund = int(parsed.get("infrastructure_fund", STARTING_INFRASTRUCTURE_FUND))
	xp = int(parsed.get("xp", 0))
	city_reputation = int(parsed.get("city_reputation", 0))
	badges.clear()
	var raw_badges = parsed.get("badges", [])
	if typeof(raw_badges) == TYPE_ARRAY:
		for b in raw_badges:
			badges.append(String(b))

func save_progress() -> void:
	var data := {
		"unlocked_chapters": unlocked_chapters,
		"stars": stars,
		"infrastructure_fund": infrastructure_fund,
		"xp": xp,
		"city_reputation": city_reputation,
		"badges": badges,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func unlock_next_chapter() -> void:
	if unlocked_chapters < TOTAL_CHAPTERS:
		unlocked_chapters += 1
		save_progress()

func set_chapter_stars(chapter: int, count: int) -> void:
	var first_completion := int(stars.get(chapter, 0)) == 0 and count > 0
	stars[chapter] = max(int(stars.get(chapter, 0)), count)
	if first_completion:
		add_xp(XP_PER_CHAPTER)
		add_city_reputation(REPUTATION_PER_CHAPTER)
		_check_badges(chapter)
	save_progress()

func add_xp(amount: int) -> void:
	xp = max(0, xp + amount)
	save_progress()

func add_infrastructure_fund(amount: int) -> void:
	infrastructure_fund = max(0, infrastructure_fund + amount)
	save_progress()

func add_city_reputation(amount: int) -> void:
	city_reputation = max(0, city_reputation + amount)
	save_progress()

func award_badge(badge_id: String) -> void:
	if not badges.has(badge_id):
		badges.append(badge_id)
		save_progress()

# Placeholder badge content (only two milestones) pending a real badge list —
# the manuscript defines the schema (milestone_type/milestone_value) but not
# specific badges.
func _check_badges(chapter: int) -> void:
	if chapter == 1:
		award_badge("first_contact")
	if stars.size() >= TOTAL_CHAPTERS:
		award_badge("city_restored")

func administration_rank() -> String:
	var rank := "Trainee"
	for tier in RANK_THRESHOLDS:
		if xp >= int(tier["xp"]):
			rank = String(tier["rank"])
	return rank

func district_for_chapter(chapter: int) -> Dictionary:
	for district in DISTRICTS:
		if chapter >= int(district["start"]) and chapter <= int(district["end"]):
			return district
	return {"name": "Unknown District", "start": chapter, "end": chapter}

func zone_for_chapter(chapter: int) -> Dictionary:
	for zone in district_for_chapter(chapter).get("zones", []):
		if chapter >= int(zone["start"]) and chapter <= int(zone["end"]):
			return zone
	return {"name": "Unknown Zone", "start": chapter, "end": chapter}

# A chapter's objectives count as completed once it has earned any stars —
# set_chapter_stars() is only called from a finished chapter.
func is_completed(chapter: int) -> bool:
	return stars_for(chapter) > 0

func stars_for(chapter: int) -> int:
	return int(stars.get(chapter, 0))

func is_unlocked(chapter: int) -> bool:
	return chapter <= unlocked_chapters
