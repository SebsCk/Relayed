extends Node

# Autoload (DialogueBox). Tap-to-advance story dialogue drawn over whatever
# scene calls play(), plus a small fading toast for quest/note notifications.
# Built in code so any scene can use it without a shared .tscn. It's an
# autoload rather than a class_name script so it doesn't depend on the
# editor's script-class cache picking up a new file.
#
#   var box := DialogueBox.play(self, lines, can_skip)
#   await box.finished
#
# `lines` is an Array of {"speaker": String, "text": String}.

class Overlay extends CanvasLayer:
	signal finished

	var _lines: Array = []
	var _index := 0
	var _done := false
	var _speaker_label: Label
	var _text_label: Label
	var _next_button: Button

	func setup(lines: Array, can_skip: bool) -> void:
		_lines = lines
		var dim := UIKit.full_rect_bg(Color(0, 0, 0, 0.55))
		dim.mouse_filter = Control.MOUSE_FILTER_STOP
		dim.gui_input.connect(_on_dim_input)
		add_child(dim)

		var root := MarginContainer.new()
		root.set_anchors_preset(Control.PRESET_FULL_RECT)
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_theme_constant_override("margin_left", 12)
		root.add_theme_constant_override("margin_right", 12)
		root.add_theme_constant_override("margin_bottom", 12)
		add_child(root)
		var column := UIKit.vbox(0)
		root.add_child(column)
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(spacer)

		var panel := UIKit.panel(Vector2.ZERO, UIKit.PANEL_COLOR, 16)
		column.add_child(panel)
		var box := UIKit.vbox(8)
		panel.add_child(box)
		_speaker_label = Label.new()
		_speaker_label.add_theme_font_size_override("font_size", 16)
		_speaker_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.4))
		box.add_child(_speaker_label)
		_text_label = UIKit.body_label("", 16)
		_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		box.add_child(_text_label)

		var buttons := UIKit.hbox(8)
		box.add_child(buttons)
		if can_skip:
			var skip_button := UIKit.styled_button("Skip", Color(0.38, 0.38, 0.42))
			skip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			skip_button.pressed.connect(_finish)
			buttons.add_child(skip_button)
		_next_button = UIKit.styled_button("Next")
		_next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_next_button.pressed.connect(_advance)
		buttons.add_child(_next_button)
		_show_line()

	func _on_dim_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_advance()

	func _show_line() -> void:
		var line: Dictionary = _lines[_index]
		_speaker_label.text = String(line.get("speaker", ""))
		_text_label.text = String(line.get("text", ""))
		_next_button.text = "Done" if _index == _lines.size() - 1 else "Next"

	func _advance() -> void:
		_index += 1
		if _index >= _lines.size():
			_finish()
		else:
			_show_line()

	func _finish() -> void:
		if _done:
			return
		_done = true
		finished.emit()
		queue_free()

func play(host: Node, lines: Array, can_skip: bool = false) -> Overlay:
	var overlay := Overlay.new()
	overlay.layer = 30
	host.add_child(overlay)
	overlay.setup(lines, can_skip)
	return overlay

func toast(host: Node, message: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 40
	host.add_child(layer)
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_constant_override("margin_top", 70)
	root.add_theme_constant_override("margin_left", 16)
	root.add_theme_constant_override("margin_right", 16)
	layer.add_child(root)
	var column := UIKit.vbox(0)
	root.add_child(column)
	var panel := UIKit.panel(Vector2.ZERO, Color(0.16, 0.42, 0.25, 0.96), 12)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(panel)
	var label := UIKit.body_label(message, 15)
	label.custom_minimum_size = Vector2(260, 0)
	panel.add_child(label)
	var tween := layer.create_tween()
	tween.tween_interval(2.8)
	tween.tween_property(root, "modulate:a", 0.0, 0.5)
	tween.tween_callback(layer.queue_free)
