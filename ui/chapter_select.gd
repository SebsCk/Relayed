extends Control

# Figure 30 — Chapter Selection. UI (top bar, District map, popup) is
# authored directly in scenes/chapter_select.tscn; this script wires up
# references/signals and refreshes chapter/zone state from GameProgress.
# The District map follows the user's sketch: one diamond per Zone, each
# with its chapters' boxed numbers in a row beneath it. A box is lit once
# that chapter's objectives are completed, dim if not, and the next chapter
# to play is outlined and pulses, so players can see where they left off.
# Districts after the first have no chapters yet and show as locked
# LockedDistrictN sections below the map.

const COMPLETED_FILL := Color(0.95, 0.75, 0.2)
const COMPLETED_TEXT := Color(0.15, 0.12, 0.05)
const DIM_FILL := Color(0.24, 0.24, 0.27)
const DIM_TEXT := Color(0.5, 0.5, 0.53)
const CURRENT_FILL := Color(0.16, 0.25, 0.4)
const ZONE_LIT := Color(0.2, 0.72, 0.3)
const ZONE_DIM := Color(0.2, 0.72, 0.3, 0.35)

var popup: Control
var popup_title: Label
var popup_body: Label
var popup_stars: HBoxContainer
var popup_action: Button
var selected_chapter: int = 1
var chapter_boxes: Dictionary = {}
var current_pulse: Tween

# The map is authored at 390-wide portrait size (Canvas's own rect) and
# scaled up a little on wider/landscape screens — DistrictMap reserves the
# scaled size in the scroll layout, Canvas carries the actual scale.
const MAP_MAX_SCALE := 1.3
const MAP_SIDE_GUTTER := 16.0

@onready var district_map: Control = $Scroll/Outer/DistrictBox/DistrictMap
@onready var map_canvas: Control = $Scroll/Outer/DistrictBox/DistrictMap/Canvas

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

	var zones: Array = GameProgress.DISTRICTS[0]["zones"]
	for i in zones.size():
		var zone_node := map_canvas.get_node("Zone%d" % (i + 1))
		for chapter in range(int(zones[i]["start"]), int(zones[i]["end"]) + 1):
			var box: Button = zone_node.get_node("Chapter%d" % chapter)
			box.pressed.connect(_on_tile_pressed.bind(chapter))
			chapter_boxes[chapter] = box

	for i in range(1, GameProgress.DISTRICTS.size()):
		var section := $Scroll/Outer/DistrictBox.get_node_or_null("LockedDistrict%d" % (i + 1))
		if section:
			section.get_node("Box/NameLabel").text = GameProgress.DISTRICTS[i]["name"]

	get_viewport().size_changed.connect(_fit_map)
	_fit_map()
	_refresh_map()

func _fit_map() -> void:
	var base := map_canvas.size
	var view := get_viewport_rect().size
	var fit := (view.x - MAP_SIDE_GUTTER * 2.0) / base.x
	var map_scale := clampf(fit, 1.0, MAP_MAX_SCALE)
	map_canvas.scale = Vector2(map_scale, map_scale)
	district_map.custom_minimum_size = base * map_scale

# The first unlocked chapter that isn't completed yet — where the player
# left off. 0 once every chapter is done.
func _current_chapter() -> int:
	for chapter in range(1, GameProgress.TOTAL_CHAPTERS + 1):
		if GameProgress.is_unlocked(chapter) and not GameProgress.is_completed(chapter):
			return chapter
	return 0

func _refresh_map() -> void:
	var district: Dictionary = GameProgress.DISTRICTS[0]
	var district_done := 0
	for chapter in range(int(district["start"]), int(district["end"]) + 1):
		if GameProgress.is_completed(chapter):
			district_done += 1
	map_canvas.get_node("DistrictTitle").text = "%s  (%d/%d)" % [district["name"], district_done, int(district["end"]) - int(district["start"]) + 1]

	var zones: Array = district["zones"]
	for i in zones.size():
		var zone: Dictionary = zones[i]
		var total := int(zone["end"]) - int(zone["start"]) + 1
		var done := 0
		for chapter in range(int(zone["start"]), int(zone["end"]) + 1):
			if GameProgress.is_completed(chapter):
				done += 1
		var zone_node := map_canvas.get_node("Zone%d" % (i + 1))
		var lit := done == total
		zone_node.get_node("Outline").default_color = ZONE_LIT if done > 0 else ZONE_DIM
		zone_node.get_node("Diamond").color = Color(0.2, 0.55, 0.26) if lit else Color(0.13, 0.3, 0.16)
		zone_node.get_node("Progress").text = "%d/%d" % [done, total]

	var current := _current_chapter()
	for chapter in chapter_boxes.keys():
		var box: Button = chapter_boxes[chapter]
		var completed := GameProgress.is_completed(chapter)
		var is_current: bool = chapter == current
		var fill := COMPLETED_FILL if completed else (CURRENT_FILL if is_current else DIM_FILL)
		var text_color := COMPLETED_TEXT if completed else (UIKit.TEXT_LIGHT if is_current else DIM_TEXT)
		_style_box(box, fill, text_color, UIKit.ACCENT_COLOR if is_current else Color(0, 0, 0, 0))

	if current_pulse:
		current_pulse.kill()
	if current > 0:
		var box: Button = chapter_boxes[current]
		current_pulse = create_tween().set_loops()
		current_pulse.tween_property(box, "scale", Vector2(1.08, 1.08), 0.6).set_trans(Tween.TRANS_SINE)
		current_pulse.tween_property(box, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)

func _style_box(box: Button, fill: Color, text_color: Color, border: Color) -> void:
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = fill.lightened(0.12) if state == "hover" else fill
		style.set_corner_radius_all(5)
		style.set_border_width_all(2 if border.a > 0 else 0)
		style.border_color = border
		if state == "focus":
			style.draw_center = false
		box.add_theme_stylebox_override(state, style)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		box.add_theme_color_override(color_name, text_color)

func _on_tile_pressed(chapter: int) -> void:
	selected_chapter = chapter

	if not GameProgress.is_unlocked(chapter):
		popup_title.text = "LOCKED CHAPTER!"
		popup_body.text = "Complete previous chapters to unlock this chapter."
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
	var zone: Dictionary = GameProgress.zone_for_chapter(chapter)
	popup_body.text = "%s · %s\nChapter progress: %d / 3 stars" % [district["name"], zone["name"], earned]
	popup_action.text = "REPLAY" if earned > 0 else "PLAY"
	popup_action.visible = true
	popup.visible = true

func _on_popup_action_pressed() -> void:
	GameProgress.selected_chapter = selected_chapter
	UIKit.go_to_scene("res://scenes/story_event.tscn")
