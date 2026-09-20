extends Node2D
class_name CellTower

@export var coverage_radius: float = 300.0
@export var network_type: String = "5G"

func _ready():
	queue_redraw()

func provides_coverage(building: Building) -> bool:
	return global_position.distance_to(building.global_position) <= coverage_radius and building.preferred_network == network_type

func _draw():
	var color := Color(0.15, 0.85, 1.0, 0.65) if network_type == "5G" else Color(0.35, 1.0, 0.45, 0.65)
	var fill_color := color
	fill_color.a = 0.12
	draw_circle(Vector2.ZERO, coverage_radius, fill_color)
	draw_arc(Vector2.ZERO, coverage_radius, 0, TAU, 64, color, 2.0)
