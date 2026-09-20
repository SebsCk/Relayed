extends Camera2D

# Mobile-first navigation: click/touch-and-drag to pan, replacing the
# previous WASD scheme. Skips panning entirely while the gameplay scene is
# in placement mode, so dragging to draw a tower/building preview doesn't
# also drag the camera underneath it.

@export var zoom_speed: float = 1.0
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0

var dragging := false
var drag_start_pointer: Vector2
var drag_start_camera: Vector2

func _unhandled_input(event: InputEvent) -> void:
	if _is_placing():
		dragging = false
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_begin_drag(event.position)
			else:
				dragging = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_apply_zoom(zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_apply_zoom(-zoom_speed)
	elif event is InputEventMouseMotion:
		_update_drag(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_drag(event.position)
		else:
			dragging = false
	elif event is InputEventScreenDrag:
		_update_drag(event.position)

func _is_placing() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.has_method("is_placing") and scene.is_placing()

func _begin_drag(pointer_position: Vector2) -> void:
	dragging = true
	drag_start_pointer = pointer_position
	drag_start_camera = position

func _update_drag(pointer_position: Vector2) -> void:
	if not dragging:
		return
	var delta := (pointer_position - drag_start_pointer) / zoom
	position = drag_start_camera - delta * GameSettings.camera_speed_multiplier

func _apply_zoom(amount: float) -> void:
	zoom = clamp(
		zoom + Vector2(amount, amount),
		Vector2(min_zoom, min_zoom),
		Vector2(max_zoom, max_zoom)
	)
