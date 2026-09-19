extends Node2D
class_name CellTower

@export var coverage_radius: float = 300.0
@export var network_type: String = "5G"

func _ready():
	queue_redraw()

func _process(delta):
	check_buildings_in_range()

func check_buildings_in_range():
	var buildings = get_tree().get_nodes_in_group("buildings")
	for b in buildings:
		var dist = global_position.distance_to(b.global_position)
		if dist <= coverage_radius and b.preferred_network == network_type:
			b.set_connected(true)
		elif dist <= coverage_radius:
			b.set_connected(false)  # in range, wrong network type
		# if out of range, leave as-is (another tower might cover it)

func _draw():
	draw_circle(Vector2.ZERO, coverage_radius, Color(0, 1, 1, 0.15))
	draw_arc(Vector2.ZERO, coverage_radius, 0, TAU, 64, Color(0, 1, 1, 0.6), 2.0)
