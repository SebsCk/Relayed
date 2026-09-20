extends Control

# Figure 30 — Chapter Selection. UI (top bar, district grid, popup) is
# authored directly in scenes/chapter_select.tscn; this script wires up
# references/signals and refreshes tile/star state from GameProgress.
# Districts are approximated as a grid of isometric ground tiles rather
# than the storyboard's hand-placed diamond map — the interaction
# (locked/unlocked, stars, Play/Replay/locked popup) is real, the exact
# map arrangement is a later visual pass.

var popup: Control
var popup_title: Label
var popup_body: Label
var popup_stars: HBoxContainer
var popup_action: Button
var selected_chapter: int = 1
var chapter_tiles: Dictionary = {}

func _ready() -> void:
	$BackButton.pressed.connect(func(): UIKit.go_to_scene("res://scenes/choose_game.tscn"))
	$ProfileButton.pressed.connect(func(): UIKit.go_to_scene("res://scenes/player_profile.tscn"))
	$SettingsButton.pressed.connect(func():
		GameProgress.settings_return_path = "res://scenes/chapter_select.tscn"
		UIKit.go_to_scene("res://scenes/settings.tscn")
	)

	popup = $Popup
	popup_title = $Popup/PopupCenter/PopupPanel/PopupBox/PopupTitle
	popup_stars = $Popup/PopupCenter/PopupPanel/PopupBox/PopupStars
	popup_body = $Popup/PopupCenter/PopupPanel/PopupBox/PopupBody
	popup_action = $Popup/PopupCenter/PopupPanel/PopupBox/PopupAction
	$Popup/DismissButton.pressed.connect(func(): popup.visible = false)
	popup_action.pressed.connect(_on_popup_action_pressed)

	for district in GameProgress.DISTRICTS:
		var section_name := "District_%s" % String(district["name"]).replace(" ", "")
		var section: Node = $Scroll/Outer/DistrictBox.get_node(section_name)
		for chapter in range(int(district["start"]), int(district["end"]) + 1):
			var tile: Button = section.get_node("Grid/Tile%d" % chapter)
			tile.pressed.connect(_on_tile_pressed.bind(chapter))
			chapter_tiles[chapter] = tile

	_refresh_tiles()

func _refresh_tiles() -> void:
	for district in GameProgress.DISTRICTS:
		var start: int = district["start"]
		var end: int = district["end"]
		var stars_earned := 0
		for chapter in range(start, end + 1):
			stars_earned += GameProgress.stars_for(chapter)
		var section: Node = $Scroll/Outer/DistrictBox.get_node("District_%s" % String(district["name"]).replace(" ", ""))
		var header := section.get_node("HeaderLabel") as Label
		header.text = "%s  (%d/%d ★)" % [district["name"], stars_earned, (end - start + 1) * 3]

	for chapter in chapter_tiles.keys():
		var unlocked := GameProgress.is_unlocked(chapter)
		var tile: Button = chapter_tiles[chapter]
		tile.modulate = Color(1, 1, 1) if unlocked else Color(0.55, 0.55, 0.55)
		tile.get_node("UnlockedIcon").visible = unlocked
		tile.get_node("LockIcon").visible = not unlocked

func _on_tile_pressed(chapter: int) -> void:
	selected_chapter = chapter

	if not GameProgress.is_unlocked(chapter):
		popup_title.text = "LOCKED DISTRICT!"
		popup_body.text = "Complete previous chapters to unlock this district."
		popup_action.visible = false
		popup_stars.visible = false
		popup.visible = true
		return

	popup_title.text = "CHAPTER %d" % chapter
	var earned := GameProgress.stars_for(chapter)
	for i in range(3):
		var star := popup_stars.get_node("Star%d" % i)
		star.modulate = Color(1.0, 0.85, 0.2) if i < earned else Color(0.4, 0.4, 0.4)
	popup_stars.visible = true
	var district: Dictionary = GameProgress.district_for_chapter(chapter)
	popup_body.text = "%s\nChapter progress: %d / 3 stars" % [district["name"], earned]
	popup_action.text = "REPLAY" if earned > 0 else "PLAY"
	popup_action.visible = true
	popup.visible = true

func _on_popup_action_pressed() -> void:
	GameProgress.selected_chapter = selected_chapter
	UIKit.go_to_scene("res://scenes/story_event.tscn")
