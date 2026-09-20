extends Node2D
class_name CellTower

@export var coverage_radius: float = 300.0
@export var network_type: String = "5G"
@export var capacity: int = 150

var current_load: int = 0
var is_congested: bool = false

func _ready():
	queue_redraw()

func provides_coverage(building: Building) -> bool:
	return global_position.distance_to(building.global_position) <= coverage_radius and building.preferred_network == network_type

func reset_load() -> void:
	current_load = 0
	is_congested = false

func add_load(bandwidth: int) -> void:
	current_load += bandwidth
	is_congested = current_load > capacity
	queue_redraw()

func _draw():
	var color := Color(0.15, 0.85, 1.0, 0.65) if network_type == "5G" else Color(0.35, 1.0, 0.45, 0.65)
	if is_congested:
		color = Color(1.0, 0.55, 0.1, 0.85)
	var fill_color := color
	fill_color.a = 0.12
	draw_circle(Vector2.ZERO, coverage_radius, fill_color)
	draw_arc(Vector2.ZERO, coverage_radius, 0, TAU, 64, color, 2.0)
