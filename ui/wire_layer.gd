extends Node2D
class_name WireLayer

# Draws the routed wire paths computed in relayed.gd. Kept as its own node
# (immediate-mode _draw(), same pattern as CellTower's coverage circle) so
# relayed.gd only has to hand it path data, not manage per-wire node
# lifecycles.

var wires: Array[Dictionary] = []

func set_wires(new_wires: Array[Dictionary]) -> void:
	wires = new_wires
	queue_redraw()

func _draw() -> void:
	for wire in wires:
		var points: PackedVector2Array = wire["points"]
		if points.size() < 2:
			continue
		var color: Color = wire["color"]
		var crossing: bool = wire.get("crossing", false)
		var width := 4.0 if crossing else 3.0
		# soft glow pass, then a bright core — reads as a "lit" connection
		var glow := color
		glow.a = 0.25
		draw_polyline(points, glow, width + 5.0, true)
		draw_polyline(points, color, width, true)
		if crossing:
			draw_polyline(points, Color(1.0, 0.15, 0.15, 0.85), 1.5, true)
