extends Control

# Figure 30 — Chapter Selection. Districts are approximated as a grid of
# isometric ground tiles rather than the storyboard's hand-placed diamond
# map; the interaction (locked/unlocked, stars, Play/Replay/locked popup) is
# real, the exact map arrangement is a later visual pass.

const GROUND_TILE := preload("res://Isometric City - Starter Set/Roads and Grounds/tile_ground_grass.png")
const DISTRICT_ICON := preload("res://Isometric City - Starter Set/Buildings/bld_watertower_blue_SW_normal.png")

var popup: Control
var popup_title: Label
var popup_body: Label
var popup_stars: HBoxContainer
var popup_action: Button
var selected_chapter: int = 1

func _ready() -> void:
	add_child(UIKit.full_rect_bg())
	_build_top_bar()
	_build_grid()
	_build_popup()

func _build_top_bar() -> void:
	var back := UIKit.back_button()
	back.position = Vector2(12, 12)
	back.pressed.connect(func(): UIKit.go_to_scene("res://scenes/choose_game.tscn"))
	add_child(back)

	var profile_button := Button.new()
	profile_button.flat = true
	profile_button.custom_minimum_size = Vector2(44, 44)
	profile_button.anchor_left = 1.0
	profile_button.anchor_right = 1.0
	profile_button.position = Vector2(-96, 12)
	profile_button.add_child(UIKit.icon("res://ui/icons/person.svg", Vector2(28, 28)))
	profile_button.pressed.connect(func(): UIKit.go_to_scene("res://scenes/player_profile.tscn"))
	add_child(profile_button)

	var settings_button := Button.new()
	settings_button.flat = true
	settings_button.custom_minimum_size = Vector2(44, 44)
	settings_button.anchor_left = 1.0
	settings_button.anchor_right = 1.0
	settings_button.position = Vector2(-48, 12)
	settings_button.add_child(UIKit.icon("res://ui/icons/gear.svg", Vector2(24, 24)))
	settings_button.pressed.connect(func():
		GameProgress.settings_return_path = "res://scenes/chapter_select.tscn"
		UIKit.go_to_scene("res://scenes/settings.tscn")
	)
	add_child(settings_button)

func _build_grid() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := UIKit.vbox(16)
	center.add_child(box)
	box.add_child(UIKit.title_label("Select a District", 24))

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)

	for chapter in range(1, GameProgress.TOTAL_CHAPTERS + 1):
		grid.add_child(_build_chapter_tile(chapter))

func _build_chapter_tile(chapter: int) -> Control:
	var unlocked := GameProgress.is_unlocked(chapter)
	var tile := Button.new()
	tile.custom_minimum_size = Vector2(100, 100)
	tile.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tile.clip_contents = true
	tile.flat = true
	tile.modulate = Color(1, 1, 1) if unlocked else Color(0.55, 0.55, 0.55)
	tile.pressed.connect(_on_tile_pressed.bind(chapter))

	var background := TextureRect.new()
	background.texture = GROUND_TILE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(background)

	if unlocked:
		var icon := TextureRect.new()
		icon.texture = DISTRICT_ICON
		icon.custom_minimum_size = Vector2(28, 28)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.position = Vector2(36, 14)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(icon)
	else:
		var lock := UIKit.icon("res://ui/icons/lock.svg", Vector2(24, 24))
		lock.set_anchors_preset(Control.PRESET_CENTER)
		lock.position = Vector2(38, 20)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(lock)

	var label := UIKit.body_label("Chapter %d" % chapter, 13)
	label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	label.position = Vector2(0, 74)
	label.size = Vector2(100, 20)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(label)

	return tile

func _build_popup() -> void:
	popup = Control.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.visible = false
	add_child(popup)
	var dismiss := UIKit.full_rect_bg(Color(0, 0, 0, 0.55))
	dismiss.mouse_filter = Control.MOUSE_FILTER_STOP
	popup.add_child(dismiss)
	var dismiss_button := Button.new()
	dismiss_button.flat = true
	dismiss_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	dismiss_button.pressed.connect(func(): popup.visible = false)
	popup.add_child(dismiss_button)

	var panel := UIKit.panel(Vector2(280, 0))
	popup.add_child(UIKit.centered(panel))
	var box := UIKit.vbox(12)
	panel.add_child(box)

	popup_title = UIKit.title_label("", 22)
	box.add_child(popup_title)

	popup_stars = UIKit.hbox(4)
	popup_stars.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(popup_stars)

	popup_body = UIKit.body_label("")
	box.add_child(popup_body)

	popup_action = UIKit.styled_button("")
	popup_action.pressed.connect(_on_popup_action_pressed)
	box.add_child(popup_action)

func _on_tile_pressed(chapter: int) -> void:
	selected_chapter = chapter
	for star_icon in popup_stars.get_children():
		star_icon.queue_free()

	if not GameProgress.is_unlocked(chapter):
		popup_title.text = "LOCKED DISTRICT!"
		popup_body.text = "Complete previous chapters to unlock this district."
		popup_action.visible = false
		popup.visible = true
		return

	popup_title.text = "CHAPTER %d" % chapter
	var earned := GameProgress.stars_for(chapter)
	for i in range(3):
		var tint := Color(1.0, 0.85, 0.2) if i < earned else Color(0.4, 0.4, 0.4)
		popup_stars.add_child(UIKit.icon("res://ui/icons/star.svg", Vector2(22, 22), tint))
	popup_body.text = "Chapter progress: %d / 3 stars" % earned
	popup_action.text = "REPLAY" if earned > 0 else "PLAY"
	popup_action.visible = true
	popup.visible = true

func _on_popup_action_pressed() -> void:
	GameProgress.selected_chapter = selected_chapter
	UIKit.go_to_scene("res://scenes/story_event.tscn")
