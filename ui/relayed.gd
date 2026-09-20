extends Node2D

const TOWER_SCENE := preload("res://scenes/cell_tower.tscn")
const BUILDING_SCENE := preload("res://scenes/building.tscn")
const HOUSE_TEXTURE := preload("res://Isometric Suburban Pack/Buildings/house 02a.png")
const APARTMENT_TEXTURE := preload("res://Isometric Suburban Pack/Buildings/apartment complex 01a.png")
const PLACEABLE_BUILDING_TEXTURE := preload("res://Isometric Suburban Pack/Buildings/house 01a.png")
const TOWER_TEXTURE := preload("res://Isometric City - Starter Set/Buildings/bld_watertower_blue_SW_normal.png")

const TOWER_COST := 200
const BUILDING_COST := 100
const MAX_ROUNDS := 3
const TOWER_CAPACITY := {"5G": 150, "Ethernet": 120}

var credits := 600
var score := 0
var current_round := 1
var placement_kind := ""
var placement_network := ""
var placing_network := ""
var round_complete := false
var deployed_towers: Array[CellTower] = []
var extra_buildings: Array[Building] = []
var occupied_cells: Dictionary = {}
var placement_history: Array[Dictionary] = []
var placed_building_count := 0
var round_demand_count := 0
var placement_preview: Node2D
var building_drag_active := false
var wire_layer: WireLayer

var credits_label: Label
var coverage_label: Label
var round_label: Label
var status_label: Label
var five_g_button: Button
var fiber_button: Button
var building_button: Button
var undo_button: Button
var reset_button: Button
var next_button: Button
var overlay: PanelContainer

func _ready() -> void:
	wire_layer = WireLayer.new()
	wire_layer.name = "WireLayer"
	wire_layer.z_index = 5
	add_child(wire_layer)
	register_existing_buildings()
	build_hud()
	apply_round_demands()
	refresh_network()

func is_placing() -> bool:
	return not placement_kind.is_empty()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.ctrl_pressed and event.keycode == KEY_Z:
		undo_last_placement()
		get_viewport().set_input_as_handled()
		return
	if not is_placing():
		return
	if placement_kind == "building" or placement_kind == "tower":
		handle_placement_drag(event)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		place_current_item(get_global_mouse_position())
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel_placement()

func place_current_item(world_position: Vector2) -> void:
	if placement_kind == "tower":
		place_tower(world_position)
	elif placement_kind == "building":
		place_building(world_position)

func begin_placement(network_type: String) -> void:
	if credits < TOWER_COST:
		set_status("Not enough credits. A site costs %d credits." % TOWER_COST)
		return
	placing_network = network_type
	placement_kind = "tower"
	placement_network = network_type
	building_drag_active = false
	remove_building_preview()
	show_building_preview(get_global_mouse_position())
	set_status("Placing %s site — click the map. Press Esc to cancel." % network_type)
	update_hud()

func cancel_placement() -> void:
	remove_building_preview()
	building_drag_active = false
	placing_network = ""
	placement_kind = ""
	placement_network = ""
	set_status("Placement cancelled.")
	update_hud()

func place_tower(world_position: Vector2) -> void:
	if credits < TOWER_COST:
		cancel_placement()
		return
	var cell := world_to_cell(world_position)
	if not is_buildable_cell(cell):
		set_status("Choose a visible, unoccupied grid tile.")
		return
	var tower := TOWER_SCENE.instantiate() as CellTower
	tower.position = cell_to_world(cell)
	tower.network_type = placing_network
	tower.capacity = TOWER_CAPACITY.get(placing_network, 150)
	prepare_placed_tower(tower)
	add_child(tower)
	deployed_towers.append(tower)
	occupied_cells[cell] = tower
	placement_history.append({"node": tower, "cell": cell, "cost": TOWER_COST, "kind": "tower"})
	credits -= TOWER_COST
	set_status("%s coverage site deployed." % placing_network)
	placing_network = ""
	placement_kind = ""
	placement_network = ""
	remove_building_preview()
	refresh_network()

func begin_building_placement() -> void:
	if credits < BUILDING_COST:
		set_status("Not enough credits. A building costs %d credits." % BUILDING_COST)
		return
	placement_kind = "building"
	placement_network = "5G"
	placing_network = ""
	building_drag_active = false
	remove_building_preview()
	show_building_preview(get_global_mouse_position())
	set_status("Hold, drag, and release the building on a free grid tile. Press Esc to cancel.")
	update_hud()

func handle_placement_drag(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		show_building_preview(get_global_mouse_position())
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			building_drag_active = true
			show_building_preview(get_global_mouse_position())
		elif building_drag_active:
			building_drag_active = false
			place_current_item(get_global_mouse_position())
	elif event is InputEventScreenDrag:
		show_building_preview(viewport_to_world(event.position))
	elif event is InputEventScreenTouch:
		var touch_world := viewport_to_world(event.position)
		if event.pressed:
			building_drag_active = true
			show_building_preview(touch_world)
		elif building_drag_active:
			building_drag_active = false
			place_current_item(touch_world)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel_placement()

func show_building_preview(world_position: Vector2) -> void:
	if not placement_preview:
		placement_preview = Node2D.new()
		placement_preview.name = "PlacementPreview"
		placement_preview.z_index = 2
		var sprite := Sprite2D.new()
		var preview_texture: Texture2D = PLACEABLE_BUILDING_TEXTURE if placement_kind == "building" else TOWER_TEXTURE
		sprite.texture = preview_texture
		sprite.position = Vector2(0, -preview_texture.get_height() / 2.0)
		sprite.modulate = Color(0.55, 0.9, 1.0, 0.65)
		placement_preview.add_child(sprite)
		add_child(placement_preview)
	var cell := world_to_cell(world_position)
	placement_preview.global_position = cell_to_world(cell)
	placement_preview.modulate = Color.WHITE if is_buildable_cell(cell) else Color(1.0, 0.35, 0.35, 0.7)

func remove_building_preview() -> void:
	if is_instance_valid(placement_preview):
		placement_preview.queue_free()
	placement_preview = null

func viewport_to_world(viewport_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * viewport_position

func place_building(world_position: Vector2) -> void:
	if credits < BUILDING_COST:
		cancel_placement()
		return
	var cell := world_to_cell(world_position)
	if not is_buildable_cell(cell):
		set_status("Choose a visible, unoccupied grid tile.")
		return
	placed_building_count += 1
	var building := BUILDING_SCENE.instantiate() as Building
	building.name = "PlayerBuilding%d" % placed_building_count
	building.position = cell_to_world(cell)
	prepare_placed_building(building)
	building.building_name = "Network Demand %d" % placed_building_count
	building.bandwidth_level = 25
	building.district_id = "Player"
	building.preferred_network = placement_network
	$Buildings.add_child(building)
	extra_buildings.append(building)
	occupied_cells[cell] = building
	placement_history.append({"node": building, "cell": cell, "cost": BUILDING_COST, "kind": "building"})
	credits -= BUILDING_COST
	placing_network = ""
	placement_kind = ""
	placement_network = ""
	remove_building_preview()
	set_status("Building placed. Connect it with 5G coverage.")
	refresh_network()

func prepare_placed_building(building: Building) -> void:
	building.z_index = 1
	var sprite := building.get_node("Sprite2D") as Sprite2D
	if sprite.texture:
		sprite.position = Vector2(0, -sprite.texture.get_height() / 2.0)

func prepare_placed_tower(tower: CellTower) -> void:
	tower.z_index = 1
	var sprite := tower.get_node("Sprite2D") as Sprite2D
	if sprite.texture:
		sprite.position = Vector2(0, -sprite.texture.get_height() / 2.0)

func undo_last_placement() -> void:
	if placement_history.is_empty():
		set_status("Nothing to undo.")
		return
	var action: Dictionary = placement_history.pop_back()
	var node := action["node"] as Node
	var cell: Vector2i = action["cell"]
	if is_instance_valid(node):
		node.get_parent().remove_child(node)
		node.queue_free()
	occupied_cells.erase(cell)
	credits += int(action["cost"])
	if action["kind"] == "tower":
		deployed_towers.erase(node as CellTower)
	else:
		extra_buildings.erase(node as Building)
	set_status("Last placement removed and credits refunded.")
	refresh_network()

func reset_player_placements() -> void:
	while not placement_history.is_empty():
		undo_last_placement()
	cancel_placement()
	set_status("Player placements reset; credits refunded.")

func world_to_cell(world_position: Vector2) -> Vector2i:
	return $Ground.local_to_map($Ground.to_local(world_position))

func cell_to_world(cell: Vector2i) -> Vector2:
	return $Ground.to_global($Ground.map_to_local(cell))

# Road (44) and the decorative downtown building tiles (45-59) painted onto
# the Ground layer aren't valid placement targets; every other ground source
# (grass, concrete, puddles, ...) stays buildable as before.
const NON_BUILDABLE_GROUND_SOURCES := [44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59]

func is_buildable_cell(cell: Vector2i) -> bool:
	var source_id: int = $Ground.get_cell_source_id(cell)
	return source_id != -1 and not NON_BUILDABLE_GROUND_SOURCES.has(source_id) and not occupied_cells.has(cell)

func register_existing_buildings() -> void:
	for node in get_tree().get_nodes_in_group("buildings"):
		if node is Building:
			occupied_cells[world_to_cell(node.global_position)] = node

func apply_round_demands() -> void:
	# The first map starts with three structures.  Each later round adds a new
	# demand point, so the player must extend the network instead of reusing one solve.
	if current_round == 2 and round_demand_count == 0:
		spawn_building("Corner House", 75, "D", "5G", Vector2(1250, 85), HOUSE_TEXTURE)
	if current_round == 3 and round_demand_count == 1:
		spawn_building("Riverside Apartments", 90, "E", "Ethernet", Vector2(620, -120), APARTMENT_TEXTURE)
	set_status("Round %d: connect every active building with its preferred network." % current_round)
	update_hud()

func spawn_building(title: String, bandwidth: int, district: String, network: String, world_position: Vector2, texture: Texture2D) -> void:
	var building := BUILDING_SCENE.instantiate() as Building
	building.name = title.replace(" ", "")
	var cell := world_to_cell(world_position)
	building.position = cell_to_world(cell)
	building.building_name = title
	building.bandwidth_level = bandwidth
	building.district_id = district
	building.preferred_network = network
	building.hitbox_size = Vector2(110, 110)
	(building.get_node("Sprite2D") as Sprite2D).texture = texture
	prepare_placed_building(building)
	$Buildings.add_child(building)
	extra_buildings.append(building)
	occupied_cells[cell] = building
	round_demand_count += 1

func refresh_network() -> void:
	for tower in deployed_towers:
		tower.reset_load()
	_rebuild_astar_grid()

	var buildings := get_tree().get_nodes_in_group("buildings")
	# Among towers already in Euclidean range (the existing coverage rule),
	# prefer the one with the shortest actual routed path rather than raw
	# distance — this is what makes the AStarGrid2D routing load-bearing
	# rather than cosmetic, without changing which towers are eligible.
	var serving_tower: Dictionary = {}
	var serving_path: Dictionary = {}
	for node in buildings:
		var building := node as Building
		var building_cell := world_to_cell(building.global_position)
		var best_tower: CellTower = null
		var best_path: Array = []
		var best_length := INF
		for tower in deployed_towers:
			if not tower.provides_coverage(building):
				continue
			var path := _path_between(world_to_cell(tower.global_position), building_cell)
			if path.is_empty():
				continue
			if path.size() < best_length:
				best_length = path.size()
				best_tower = tower
				best_path = path
		if best_tower:
			best_tower.add_load(building.bandwidth_level)
			serving_tower[building] = best_tower
			serving_path[building] = best_path

	# Group wires by tower and flag crossings only between DIFFERENT towers'
	# paths — wires converging on the same tower's hub are expected trunk
	# cabling, not interference. Crossings are flagged, not blocked: with no
	# way to interactively verify every layout stays solvable, round
	# completion still only requires coverage + no capacity congestion.
	var wires: Array[Dictionary] = []
	var building_crossing: Dictionary = {}
	var reserved_cells: Dictionary = {}
	for tower in deployed_towers:
		var color := Color(0.15, 0.85, 1.0) if tower.network_type == "5G" else Color(0.35, 1.0, 0.45)
		if tower.is_congested:
			color = Color(1.0, 0.55, 0.1)
		var this_tower_cells: Dictionary = {}
		for building in serving_tower.keys():
			if serving_tower[building] != tower:
				continue
			var path: Array = serving_path[building]
			var crossing := false
			for i in range(1, path.size() - 1):
				if reserved_cells.has(path[i]):
					crossing = true
				this_tower_cells[path[i]] = true
			building_crossing[building] = crossing
			var points := PackedVector2Array()
			for cell in path:
				points.append(cell_to_world(cell) - wire_layer.global_position)
			wires.append({"points": points, "color": color, "crossing": crossing})
		for cell in this_tower_cells.keys():
			reserved_cells[cell] = true
	wire_layer.set_wires(wires)

	var connected := 0
	var congested_count := 0
	var crossing_count := 0
	for node in buildings:
		var building := node as Building
		var tower: CellTower = serving_tower.get(building)
		var crossing: bool = building_crossing.get(building, false)
		building.set_network_state(tower != null, tower != null and tower.is_congested, crossing)
		if tower and not tower.is_congested:
			connected += 1
		if tower and tower.is_congested:
			congested_count += 1
		if crossing:
			crossing_count += 1
	if not buildings.is_empty() and connected == buildings.size() and not round_complete:
		round_complete = true
		var bonus := 250 + current_round * 100
		score += bonus
		credits += bonus
		set_status("District network online! +%d credits and points." % bonus)
		show_round_result()
	elif congested_count > 0:
		set_status("%d building(s) congested — add coverage to relieve overloaded towers." % congested_count)
	elif crossing_count > 0:
		set_status("%d wire(s) cross another tower's path — relocating a tower can clear this." % crossing_count)
	update_hud(congested_count)

# Decorative downtown buildings block wire routing like any obstacle; roads
# stay routable (wires can run alongside streets). Player-placed towers,
# buildings, and the original demand buildings all occupy cells and block
# routing through them except at their own two path endpoints.
const ROUTING_BLOCKED_GROUND_SOURCES := [45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59]

var astar_grid: AStarGrid2D

func _routing_region() -> Rect2i:
	var min_cell := Vector2i.ZERO
	var max_cell := Vector2i.ZERO
	var first := true
	for cell in occupied_cells.keys():
		if first:
			min_cell = cell
			max_cell = cell
			first = false
		else:
			min_cell.x = min(min_cell.x, cell.x)
			min_cell.y = min(min_cell.y, cell.y)
			max_cell.x = max(max_cell.x, cell.x)
			max_cell.y = max(max_cell.y, cell.y)
	if first:
		return Rect2i(Vector2i(-3, -3), Vector2i(6, 6))
	const MARGIN := 3
	min_cell -= Vector2i(MARGIN, MARGIN)
	max_cell += Vector2i(MARGIN, MARGIN)
	return Rect2i(min_cell, max_cell - min_cell + Vector2i.ONE)

func _rebuild_astar_grid() -> void:
	astar_grid = AStarGrid2D.new()
	var region := _routing_region()
	astar_grid.region = region
	astar_grid.cell_size = Vector2.ONE
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar_grid.update()
	for x in range(region.position.x, region.position.x + region.size.x):
		for y in range(region.position.y, region.position.y + region.size.y):
			var cell := Vector2i(x, y)
			astar_grid.set_point_solid(cell, not _is_routable_cell(cell))

func _is_routable_cell(cell: Vector2i) -> bool:
	var source_id: int = $Ground.get_cell_source_id(cell)
	if source_id == -1 or ROUTING_BLOCKED_GROUND_SOURCES.has(source_id):
		return false
	return not occupied_cells.has(cell)

func _path_between(from_cell: Vector2i, to_cell: Vector2i) -> Array:
	if not astar_grid.is_in_boundsv(from_cell) or not astar_grid.is_in_boundsv(to_cell):
		return []
	astar_grid.set_point_solid(from_cell, false)
	astar_grid.set_point_solid(to_cell, false)
	var path: Array[Vector2i] = astar_grid.get_id_path(from_cell, to_cell)
	astar_grid.set_point_solid(from_cell, true)
	astar_grid.set_point_solid(to_cell, true)
	return path

func show_round_result() -> void:
	overlay.visible = true
	var title := overlay.get_node("Margin/Box/Title") as Label
	var body := overlay.get_node("Margin/Box/Body") as Label
	if current_round >= MAX_ROUNDS:
		title.text = "Network Complete"
		body.text = "All districts are online. Final score: %d" % score
		next_button.text = "Play Again"
		# Flat 3-star award until a real per-chapter scoring rubric exists
		# (e.g. based on score or leftover credits).
		GameProgress.set_chapter_stars(GameProgress.selected_chapter, 3)
		GameProgress.unlock_next_chapter()
	else:
		title.text = "Round %d Complete" % current_round
		body.text = "Every building has compatible coverage. Prepare for the next district."
		next_button.text = "Next Round"

func advance_round() -> void:
	if current_round >= MAX_ROUNDS:
		get_tree().reload_current_scene()
		return
	current_round += 1
	round_complete = false
	overlay.visible = false
	apply_round_demands()
	refresh_network()

func set_status(message: String) -> void:
	if status_label:
		status_label.text = message

func update_hud(congested_count: int = -1) -> void:
	if not credits_label:
		return
	var total := get_tree().get_nodes_in_group("buildings").size()
	var online := 0
	var congested := congested_count
	if congested < 0:
		congested = 0
		for node in get_tree().get_nodes_in_group("buildings"):
			if (node as Building).congested:
				congested += 1
	for node in get_tree().get_nodes_in_group("buildings"):
		if (node as Building).connected_to_network and not (node as Building).congested:
			online += 1
	credits_label.text = "Credits: %d    Score: %d" % [credits, score]
	if congested > 0:
		coverage_label.text = "Coverage: %d / %d online (%d congested)" % [online, total, congested]
	else:
		coverage_label.text = "Coverage: %d / %d buildings online" % [online, total]
	round_label.text = "District %d of %d" % [current_round, MAX_ROUNDS]
	five_g_button.disabled = credits < TOWER_COST or round_complete
	fiber_button.disabled = credits < TOWER_COST or round_complete
	building_button.disabled = credits < BUILDING_COST or round_complete
	undo_button.disabled = placement_history.is_empty()
	reset_button.disabled = placement_history.is_empty()

func build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var hud := PanelContainer.new()
	hud.position = Vector2(16, 76)
	hud.size = Vector2(390, 250)
	layer.add_child(hud)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	hud.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	margin.add_child(box)
	var title := Label.new()
	title.text = "RELAYED  |  Network Operations"
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	round_label = Label.new()
	box.add_child(round_label)
	credits_label = Label.new()
	box.add_child(credits_label)
	coverage_label = Label.new()
	box.add_child(coverage_label)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	box.add_child(buttons)
	five_g_button = Button.new()
	five_g_button.text = "Place 5G ($%d)" % TOWER_COST
	five_g_button.pressed.connect(begin_placement.bind("5G"))
	buttons.add_child(five_g_button)
	fiber_button = Button.new()
	fiber_button.text = "Place Fiber ($%d)" % TOWER_COST
	fiber_button.pressed.connect(begin_placement.bind("Ethernet"))
	buttons.add_child(fiber_button)
	var placement_tools := HBoxContainer.new()
	placement_tools.add_theme_constant_override("separation", 8)
	box.add_child(placement_tools)
	building_button = Button.new()
	building_button.text = "Place Building ($%d)" % BUILDING_COST
	building_button.pressed.connect(begin_building_placement)
	placement_tools.add_child(building_button)
	undo_button = Button.new()
	undo_button.text = "Undo"
	undo_button.pressed.connect(undo_last_placement)
	placement_tools.add_child(undo_button)
	reset_button = Button.new()
	reset_button.text = "Reset"
	reset_button.pressed.connect(reset_player_placements)
	placement_tools.add_child(reset_button)
	status_label = Label.new()
	status_label.position = Vector2(18, 670)
	status_label.size = Vector2(900, 30)
	status_label.add_theme_font_size_override("font_size", 16)
	layer.add_child(status_label)

	overlay = PanelContainer.new()
	overlay.position = Vector2(390, 220)
	overlay.size = Vector2(430, 220)
	overlay.visible = false
	layer.add_child(overlay)
	var result_margin := MarginContainer.new()
	result_margin.name = "Margin"
	result_margin.add_theme_constant_override("margin_left", 24)
	result_margin.add_theme_constant_override("margin_right", 24)
	result_margin.add_theme_constant_override("margin_top", 20)
	result_margin.add_theme_constant_override("margin_bottom", 20)
	overlay.add_child(result_margin)
	var result_box := VBoxContainer.new()
	result_box.name = "Box"
	result_box.add_theme_constant_override("separation", 14)
	result_margin.add_child(result_box)
	var result_title := Label.new()
	result_title.name = "Title"
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.add_theme_font_size_override("font_size", 24)
	result_box.add_child(result_title)
	var result_body := Label.new()
	result_body.name = "Body"
	result_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_box.add_child(result_body)
	next_button = Button.new()
	next_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next_button.pressed.connect(advance_round)
	result_box.add_child(next_button)
