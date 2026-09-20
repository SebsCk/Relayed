extends Camera2D

@export var move_speed: float = 300.0
@export var zoom_speed: float = 1.0
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0

func _process(delta):
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("right"):
		direction.x += 1
	if Input.is_action_pressed("left"):
		direction.x -= 1
	if Input.is_action_pressed("down"):
		direction.y += 1
	if Input.is_action_pressed("up"):
		direction.y -= 1
	
	position += direction * move_speed * GameSettings.camera_speed_multiplier * delta

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clamp(
				zoom + Vector2(zoom_speed, zoom_speed),
				Vector2(min_zoom, min_zoom),
				Vector2(max_zoom, max_zoom)
			)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clamp(
				zoom - Vector2(zoom_speed, zoom_speed),
				Vector2(min_zoom, min_zoom),
				Vector2(max_zoom, max_zoom)
			)
