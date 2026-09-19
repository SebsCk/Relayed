extends Node2D
class_name Building

@export var building_name: String = "House"
@export var bandwidth_level: int = 0
@export var district_id: String = "A"
@export var preferred_network: String = "5G"

@export var hitbox_size: Vector2 = Vector2(64, 64)
@export var hitbox_offset: Vector2 = Vector2(0, 0)

var connected_to_network: bool = false

func _ready():
	add_to_group("buildings")

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos = get_global_mouse_position()
		var rect = get_rect_global()
		print(building_name, " | Mouse: ", local_pos, " | Hitbox: ", rect, " | Hit: ", rect.has_point(local_pos))
		if rect.has_point(local_pos):
			BuildingInfoPanel.show_building(self)

func get_rect_global() -> Rect2:
	var camera = get_viewport().get_camera_2d()
	var zoom_factor = camera.zoom if camera else Vector2(1, 1)
	
	var size = hitbox_size / zoom_factor
	var top_left = global_position + hitbox_offset - size / 2
	return Rect2(top_left, size)

func set_connected(state: bool):
	connected_to_network = state
	modulate = Color(1, 1, 1) if state else Color(1, 0.4, 0.4)

func _draw():
	if Engine.is_editor_hint():
		var rect = Rect2(hitbox_offset - hitbox_size / 2, hitbox_size)
		draw_rect(rect, Color(1, 0, 0, 0.3))
