class_name UIKit
extends RefCounted

# Shared control factory for the storyboard screens (login, register, settings,
# chapter select, etc). Keeps each screen script focused on layout/logic
# instead of repeating StyleBox and font boilerplate.

const BG_COLOR := Color(0.16, 0.16, 0.18)
const PANEL_COLOR := Color(0.29, 0.29, 0.31, 0.95)
const FIELD_COLOR := Color(0.95, 0.95, 0.95)
const ACCENT_COLOR := Color(0.2, 0.55, 0.95)
const DANGER_COLOR := Color(0.85, 0.3, 0.3)
const TEXT_LIGHT := Color(0.95, 0.95, 0.95)
const TEXT_DARK := Color(0.12, 0.12, 0.12)

static func go_to_scene(path: String) -> void:
	# The building-info side panel is an autoloaded CanvasLayer that draws on
	# top of every scene, so it stays visible across a scene change unless
	# explicitly hidden — previously only main_menu.gd and back_to_mm.gd did
	# this, so any other exit from gameplay (e.g. "Next District" after the
	# final round) left it stuck on screen over the next scene. Hiding it
	# here, at the single chokepoint every scene transition already goes
	# through, covers every path instead of one call site at a time.
	BuildingInfoPanel.hide_panel()
	# Deferred so the click that triggered navigation finishes being
	# dispatched to the OLD scene before the new one loads — changing scenes
	# synchronously inside a Button's `pressed` handler can otherwise leak
	# that same input event into whatever control ends up at the same
	# screen position in the new scene, firing a phantom click there.
	(Engine.get_main_loop() as SceneTree).change_scene_to_file.call_deferred(path)

static func full_rect_bg(color: Color = BG_COLOR) -> ColorRect:
	var bg := ColorRect.new()
	bg.color = color
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bg

static func panel(size: Vector2, color: Color = PANEL_COLOR, radius: int = 18) -> PanelContainer:
	var panel_container := PanelContainer.new()
	panel_container.custom_minimum_size = size
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(20)
	panel_container.add_theme_stylebox_override("panel", style)
	return panel_container

static func title_label(text: String, size: int = 30) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", TEXT_LIGHT)
	return label

static func body_label(text: String, size: int = 15, color: Color = TEXT_LIGHT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

static func text_field(placeholder: String, secret: bool = false) -> LineEdit:
	var field := LineEdit.new()
	field.placeholder_text = placeholder
	field.secret = secret
	field.custom_minimum_size = Vector2(0, 42)
	var style := StyleBoxFlat.new()
	style.bg_color = FIELD_COLOR
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	field.add_theme_stylebox_override("normal", style)
	field.add_theme_stylebox_override("focus", style)
	field.add_theme_color_override("font_color", TEXT_DARK)
	field.add_theme_color_override("font_placeholder_color", Color(0.35, 0.35, 0.35))
	return field

static func styled_button(text: String, color: Color = ACCENT_COLOR, text_color: Color = TEXT_LIGHT) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 46)
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.set_corner_radius_all(10)
	var hover := StyleBoxFlat.new()
	hover.bg_color = color.lightened(0.12)
	hover.set_corner_radius_all(10)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = color.darkened(0.12)
	pressed.set_corner_radius_all(10)
	var disabled := StyleBoxFlat.new()
	disabled.bg_color = color.darkened(0.3)
	disabled.set_corner_radius_all(10)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_disabled_color", text_color.darkened(0.4))
	return button

static func link_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.add_theme_color_override("font_color", Color(0.55, 0.75, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.7, 0.85, 1.0))
	button.add_theme_font_size_override("font_size", 13)
	return button

static func back_button() -> Button:
	var button := Button.new()
	button.text = "◀"
	button.flat = true
	button.custom_minimum_size = Vector2(44, 44)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", TEXT_LIGHT)
	return button

static func icon(path: String, size: Vector2 = Vector2(28, 28), tint: Color = TEXT_LIGHT) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = load(path)
	rect.custom_minimum_size = size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.modulate = tint
	return rect

static func vbox(separation: int = 10) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	# Containers default to MOUSE_FILTER_PASS, which still wins a hit-test
	# over an unrelated sibling positioned behind/around it (e.g. a corner
	# back button) even though it has nothing to actually do with the
	# click. These are pure layout wrappers; IGNORE lets clicks fall
	# through to whatever's really there. Buttons/fields added as children
	# still receive their own clicks regardless of the parent's filter.
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return box

static func hbox(separation: int = 10) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return box

static func centered_icon(path: String, size: Vector2 = Vector2(28, 28), tint: Color = TEXT_LIGHT) -> CenterContainer:
	return centered(icon(path, size, tint))

static func show_confirm_dialog(parent: Node, title: String, body: String, on_confirm: Callable) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	parent.add_child(layer)
	layer.add_child(full_rect_bg(Color(0, 0, 0, 0.6)))

	var dialog_panel := panel(Vector2(260, 0))
	layer.add_child(centered(dialog_panel))
	var box := vbox(14)
	dialog_panel.add_child(box)
	box.add_child(title_label(title, 20))
	box.add_child(body_label(body))

	var row := hbox(10)
	box.add_child(row)
	var yes_button := styled_button("YES", DANGER_COLOR)
	yes_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes_button.pressed.connect(func():
		layer.queue_free()
		on_confirm.call()
	)
	row.add_child(yes_button)
	var no_button := styled_button("NO", Color(0.3, 0.3, 0.32))
	no_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no_button.pressed.connect(func(): layer.queue_free())
	row.add_child(no_button)

# Shared in-game settings overlay for any gameplay screen whose progress
# lives only in an unsaved script instance (the puzzle, the quiz, ...) —
# an overlay rather than a navigation to scenes/settings.tscn so opening
# settings never silently discards what the player is in the middle of.
# `sign_out_warning` names what's at stake on this specific screen.
static func show_in_game_settings(parent: Node, sign_out_warning: String) -> void:
	var settings_layer := CanvasLayer.new()
	settings_layer.layer = 20
	parent.add_child(settings_layer)
	settings_layer.add_child(full_rect_bg(Color(0, 0, 0, 0.6)))

	var settings_panel := panel(Vector2(280, 0))
	settings_layer.add_child(centered(settings_panel))
	var box := vbox(10)
	settings_panel.add_child(box)
	box.add_child(title_label("Settings", 22))

	box.add_child(body_label("Camera Speed", 12, Color(0.75, 0.75, 0.75)))
	var speed_slider := HSlider.new()
	speed_slider.custom_minimum_size = Vector2(220, 24)
	speed_slider.min_value = 0.5
	speed_slider.max_value = 2.0
	speed_slider.step = 0.25
	speed_slider.value = GameSettings.camera_speed_multiplier
	speed_slider.value_changed.connect(func(v): GameSettings.camera_speed_multiplier = v)
	box.add_child(speed_slider)

	box.add_child(body_label("Audio", 12, Color(0.75, 0.75, 0.75)))
	var audio_slider := HSlider.new()
	audio_slider.custom_minimum_size = Vector2(220, 24)
	audio_slider.min_value = 0.0
	audio_slider.max_value = 1.0
	audio_slider.step = 0.05
	audio_slider.value = GameSettings.audio_volume
	audio_slider.value_changed.connect(GameSettings.set_audio_volume)
	box.add_child(audio_slider)

	var notif_row := hbox(8)
	box.add_child(notif_row)
	var notif_label := body_label("Notifications", 13)
	notif_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	notif_row.add_child(notif_label)
	var notif_toggle := CheckButton.new()
	notif_toggle.button_pressed = GameSettings.notifications_enabled
	notif_toggle.toggled.connect(func(pressed): GameSettings.notifications_enabled = pressed)
	notif_row.add_child(notif_toggle)

	var close_button := styled_button("Close")
	close_button.pressed.connect(func(): settings_layer.queue_free())
	box.add_child(close_button)

	var sign_out_button := styled_button("Sign Out", Color(0.3, 0.3, 0.32))
	sign_out_button.pressed.connect(func():
		show_confirm_dialog(parent, "SIGN OUT?", sign_out_warning, func():
			settings_layer.queue_free()
			AuthState.logout()
			go_to_scene("res://scenes/login.tscn")
		)
	)
	box.add_child(sign_out_button)

	var quit_button := styled_button("Quit Game", DANGER_COLOR)
	quit_button.pressed.connect(func():
		show_confirm_dialog(parent, "ARE YOU SURE?", "Any unsaved progress in this session will be lost.", func(): (Engine.get_main_loop() as SceneTree).quit())
	)
	box.add_child(quit_button)

static func centered(child: Control) -> CenterContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	# A pure layout wrapper shouldn't itself consume clicks over its empty
	# area — that silently blocks sibling controls (e.g. a corner back
	# button) positioned behind/around it. Its child still receives input
	# normally; a modal's own background layer is what should block clicks,
	# not this.
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(child)
	return center
