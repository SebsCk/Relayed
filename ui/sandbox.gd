extends Node2D

# Sandbox city builder. Structures come from sandbox_catalog.gd and are
# unlocked by completing chapters. TheoTown-style controls: the Build button
# (bottom-left) expands / collapses the build menu only when clicked, pick a
# structure, then tap a free tile to place it. Dragging pans the map. The
# layout is real nodes in scenes/sandbox.tscn; the map itself is drawn as an
# isometric grid here (no tileset), and the city autosaves to user://.

const Catalog := preload("res://ui/sandbox_catalog.gd")
const ITEM_SCENE := preload("res://scenes/sandbox_item.tscn")

const SAVE_PATH := "user://sandbox_city.json"
const BACK_SCENE := "res://scenes/chapter_select.tscn"
const GRID_SIZE := 24
const TILE_W := 128.0
const TILE_H := 64.0
const DRAG_THRESHOLD := 12.0
const MIN_ZOOM := 0.35
const MAX_ZOOM := 1.5
const BULLDOZE := "bulldoze"
const ACTIVE_COLOR := Color(0.55, 0.85, 1.0)
const LOCKED_COLOR := Color(0.55, 0.55, 0.6)

var occupied: Dictionary = {}
var history: Array[Dictionary] = []
var selected_id := ""
var category := "Telecom"
var _press_pos := Vector2.ZERO
var _pressing := false
var _panning := false
var _painting := false

@onready var grid: Node2D = $Grid
@onready var buildings: Node2D = $Buildings
@onready var roads_layer: Node2D = $Roads
@onready var ghost: Node2D = $Ghost
@onready var ghost_sprite: Sprite2D = $Ghost/GhostSprite
@onready var camera: Camera2D = $Camera2D
@onready var menu_panel: PanelContainer = $Ui/Hud/MenuPanel
@onready var build_toggle: Button = $Ui/Hud/BuildToggle
@onready var status_label: Label = $Ui/Hud/StatusLabel
@onready var undo_button: Button = $Ui/Hud/UndoButton
@onready var item_row: HBoxContainer = $Ui/Hud/MenuPanel/MenuBox/ItemScroll/ItemRow
@onready var info_label: Label = $Ui/Hud/MenuPanel/MenuBox/InfoLabel
@onready var bulldoze_button: Button = $Ui/Hud/BulldozeButton
@onready var tab_buttons: Array[Button] = [
	$Ui/Hud/MenuPanel/MenuBox/TabRow/Tab1,
	$Ui/Hud/MenuPanel/MenuBox/TabRow/Tab2,
	$Ui/Hud/MenuPanel/MenuBox/TabRow/Tab3,
	$Ui/Hud/MenuPanel/MenuBox/TabRow/Tab4,
	$Ui/Hud/MenuPanel/MenuBox/TabRow/Tab5,
]

func _ready() -> void:
	grid.draw.connect(_draw_grid)
	grid.queue_redraw()
	camera.position = cell_to_world(Vector2i(GRID_SIZE / 2, GRID_SIZE / 2))
	camera.zoom = Vector2(0.8, 0.8)

	$Ui/Hud/BackButton.pressed.connect(func(): UIKit.go_to_scene(BACK_SCENE))
	$Ui/Hud/ZoomInButton.pressed.connect(_zoom.bind(1.2))
	$Ui/Hud/ZoomOutButton.pressed.connect(_zoom.bind(1.0 / 1.2))
	undo_button.pressed.connect(_undo)
	build_toggle.pressed.connect(_toggle_menu)
	bulldoze_button.pressed.connect(_toggle_bulldoze)
	for i in range(tab_buttons.size()):
		tab_buttons[i].text = Catalog.CATEGORIES[i]
		tab_buttons[i].pressed.connect(_set_category.bind(Catalog.CATEGORIES[i]))

	menu_panel.visible = false
	ghost.visible = false
	_populate_items()
	_load_city()
	_refresh_ui()

# --- Isometric math ------------------------------------------------------------

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2((cell.x - cell.y) * TILE_W / 2.0, (cell.x + cell.y) * TILE_H / 2.0)

func world_to_cell(pos: Vector2) -> Vector2i:
	var x := pos.x / (TILE_W / 2.0)
	var y := pos.y / (TILE_H / 2.0)
	return Vector2i(floori((x + y) / 2.0 + 0.5), floori((y - x) / 2.0 + 0.5))

func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_SIZE and cell.y < GRID_SIZE

func _draw_grid() -> void:
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			var center := cell_to_world(Vector2i(x, y))
			var points := PackedVector2Array([
				center + Vector2(0, -TILE_H / 2.0),
				center + Vector2(TILE_W / 2.0, 0),
				center + Vector2(0, TILE_H / 2.0),
				center + Vector2(-TILE_W / 2.0, 0),
			])
			var shade := 0.0 if (x + y) % 2 == 0 else 0.035
			grid.draw_colored_polygon(points, Color(0.22 + shade, 0.42 + shade, 0.24 + shade))
			points.append(points[0])
			grid.draw_polyline(points, Color(0, 0, 0, 0.14), 1.0)

# --- Input -----------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.ctrl_pressed and event.keycode == KEY_Z:
			_undo()
		elif event.keycode == KEY_ESCAPE and not selected_id.is_empty():
			_select("")
		return
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if button_event.button_index == MOUSE_BUTTON_LEFT:
			if button_event.pressed:
				_pressing = true
				_panning = false
				_painting = _is_paint_tool()
				_press_pos = button_event.position
				if _painting:
					_paint(get_global_mouse_position())
			else:
				if _pressing and not _panning and not _painting:
					_tap(get_global_mouse_position())
				_pressing = false
				_panning = false
				_painting = false
		elif button_event.pressed and button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(1.1)
		elif button_event.pressed and button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(1.0 / 1.1)
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		# The release can land on a UI control and never reach us.
		if _pressing and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_pressing = false
			_panning = false
			_painting = false
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			camera.position -= motion.relative / camera.zoom.x
			_clamp_camera()
		elif _pressing and _painting:
			_paint(get_global_mouse_position())
		elif _pressing:
			if not _panning and motion.position.distance_to(_press_pos) > DRAG_THRESHOLD:
				_panning = true
			if _panning:
				camera.position -= motion.relative / camera.zoom.x
				_clamp_camera()
		_update_ghost(get_global_mouse_position())

func _clamp_camera() -> void:
	var half_w := GRID_SIZE * TILE_W / 2.0
	camera.position = Vector2(clampf(camera.position.x, -half_w, half_w), clampf(camera.position.y, 0.0, GRID_SIZE * TILE_H))

func _zoom(factor: float) -> void:
	var value := clampf(camera.zoom.x * factor, MIN_ZOOM, MAX_ZOOM)
	camera.zoom = Vector2(value, value)

func _tap(world_position: Vector2) -> void:
	var cell := world_to_cell(world_position)
	if not in_bounds(cell):
		return
	if selected_id.is_empty():
		if occupied.has(cell):
			var node: Node2D = occupied[cell]
			DialogueBox.toast(self, String(Catalog.find(String(node.get_meta("item_id")))["name"]))
	else:
		if not _place(selected_id, cell, true):
			DialogueBox.toast(self, "That tile is taken.")

# --- Placing and removing --------------------------------------------------------

# Roads, ground tiles and the bulldozer paint while the mouse is held; buildings
# are placed with a tap so a drag can pan the map.
func _is_paint_tool() -> bool:
	return selected_id == BULLDOZE or Catalog.is_tile(Catalog.find(selected_id))

func _paint(world_position: Vector2) -> void:
	var cell := world_to_cell(world_position)
	if not in_bounds(cell):
		return
	if selected_id == BULLDOZE:
		_remove_at(cell, true)
	elif not occupied.has(cell):
		_place(selected_id, cell, true)

func _apply_sprite(sprite: Sprite2D, item: Dictionary) -> void:
	var texture := Catalog.texture_of(item)
	sprite.texture = texture
	if texture == null:
		return
	if Catalog.is_tile(item):
		sprite.scale = Vector2.ONE
		sprite.position = Vector2.ZERO
		return
	var factor := float(item["width"]) / texture.get_width()
	sprite.scale = Vector2(factor, factor)
	# Bottom of the art sits on the tile's bottom point.
	sprite.position = Vector2(0, TILE_H / 2.0 - texture.get_height() * factor / 2.0)

func _place(id: String, cell: Vector2i, record: bool) -> bool:
	var item := Catalog.find(id)
	if item.is_empty() or not in_bounds(cell) or occupied.has(cell):
		return false
	var node := Node2D.new()
	node.position = cell_to_world(cell)
	node.set_meta("item_id", id)
	var sprite := Sprite2D.new()
	_apply_sprite(sprite, item)
	node.add_child(sprite)
	if Catalog.kind_of(item) == "road":
		node.set_meta("family", String(item["family"]))
		node.set_meta("crosswalk", bool(item.get("crosswalk", false)))
	(roads_layer if Catalog.is_tile(item) else buildings).add_child(node)
	occupied[cell] = node
	if node.has_meta("family"):
		_refresh_roads_around(cell)
	if record:
		if not Catalog.is_tile(item):
			node.scale = Vector2(0.7, 0.7)
			create_tween().tween_property(node, "scale", Vector2.ONE, 0.12)
		history.append({"action": "place", "id": id, "cell": cell})
		_save_city()
		_refresh_ui()
	return true

func _remove_at(cell: Vector2i, record: bool) -> void:
	if not occupied.has(cell):
		return
	var node: Node2D = occupied[cell]
	var id := String(node.get_meta("item_id"))
	occupied.erase(cell)
	node.get_parent().remove_child(node)
	node.queue_free()
	if node.has_meta("family"):
		_refresh_roads_around(cell)
	if record:
		history.append({"action": "remove", "id": id, "cell": cell})
		_save_city()
		_refresh_ui()

# Roads pick their piece from which neighbours are roads of the same family.
func _refresh_roads_around(cell: Vector2i) -> void:
	_refresh_road(cell)
	for dir_name in Catalog.DIRS:
		_refresh_road(cell + Catalog.DIRS[dir_name])

func _refresh_road(cell: Vector2i) -> void:
	if not occupied.has(cell):
		return
	var node: Node2D = occupied[cell]
	if not node.has_meta("family"):
		return
	var family := String(node.get_meta("family"))
	var open_dirs: Array = []
	for dir_name in Catalog.DIRS:
		var neighbour: Vector2i = cell + Catalog.DIRS[dir_name]
		if occupied.has(neighbour):
			var other: Node2D = occupied[neighbour]
			if other.has_meta("family") and String(other.get_meta("family")) == family:
				open_dirs.append(dir_name)
	(node.get_child(0) as Sprite2D).texture = Catalog.road_texture(family, open_dirs, bool(node.get_meta("crosswalk")))

func _undo() -> void:
	if history.is_empty():
		DialogueBox.toast(self, "Nothing to undo.")
		return
	var action: Dictionary = history.pop_back()
	var cell: Vector2i = action["cell"]
	if String(action["action"]) == "place":
		_remove_at(cell, false)
	else:
		_place(String(action["id"]), cell, false)
	_save_city()
	_refresh_ui()

# --- Ghost preview ---------------------------------------------------------------

func _update_ghost(world_position: Vector2) -> void:
	var item := Catalog.find(selected_id)
	if item.is_empty():
		ghost.visible = false
		return
	var cell := world_to_cell(world_position)
	ghost.visible = in_bounds(cell)
	ghost.position = cell_to_world(cell)
	ghost.modulate = Color(1, 1, 1, 0.75) if not occupied.has(cell) else Color(1.0, 0.35, 0.35, 0.75)

# --- Build menu ------------------------------------------------------------------

func _toggle_menu() -> void:
	menu_panel.visible = not menu_panel.visible
	build_toggle.text = "Close" if menu_panel.visible else "Build"

func _is_unlocked(item: Dictionary) -> bool:
	return GameProgress.is_completed(int(item["unlock_chapter"]))

func _set_category(new_category: String) -> void:
	category = new_category
	_populate_items()
	_refresh_ui()

func _toggle_bulldoze() -> void:
	_select("" if selected_id == BULLDOZE else BULLDOZE)

func _select(id: String) -> void:
	selected_id = id
	var item := Catalog.find(id)
	if not item.is_empty():
		_apply_sprite(ghost_sprite, item)
	ghost.visible = false
	_populate_items()
	_refresh_ui()

func _on_item_pressed(id: String) -> void:
	var item := Catalog.find(id)
	if not _is_unlocked(item):
		DialogueBox.toast(self, "Complete Chapter %d to unlock the %s." % [int(item["unlock_chapter"]), String(item["name"])])
		return
	_select("" if selected_id == id else id)

func _populate_items() -> void:
	for child in item_row.get_children():
		item_row.remove_child(child)
		child.queue_free()
	for item in Catalog.in_category(category):
		var unlocked := _is_unlocked(item)
		var button := ITEM_SCENE.instantiate() as Button
		item_row.add_child(button)
		(button.get_node("Box/Icon") as TextureRect).texture = Catalog.texture_of(item)
		(button.get_node("Box/NameLabel") as Label).text = String(item["name"])
		var reward_label := button.get_node("Box/LockLabel") as Label
		reward_label.text = ("Ch. %d reward" if unlocked else "Unlocks Ch. %d") % int(item["unlock_chapter"])
		reward_label.add_theme_color_override("font_color", Color(0.55, 0.9, 0.6) if unlocked else Color(0.72, 0.72, 0.76))
		if String(item["id"]) == selected_id:
			button.modulate = ACTIVE_COLOR
		elif not unlocked:
			button.modulate = LOCKED_COLOR
		button.pressed.connect(_on_item_pressed.bind(String(item["id"])))

func _refresh_ui() -> void:
	for i in range(tab_buttons.size()):
		tab_buttons[i].modulate = ACTIVE_COLOR if Catalog.CATEGORIES[i] == category else Color.WHITE
	bulldoze_button.modulate = Color(1.0, 0.6, 0.55) if selected_id == BULLDOZE else Color.WHITE
	undo_button.disabled = history.is_empty()

	var item := Catalog.find(selected_id)
	if selected_id == BULLDOZE:
		status_label.text = "Bulldozer: tap or drag over things to remove them."
		info_label.text = "Tap Bulldoze again to stop."
	elif not item.is_empty():
		status_label.text = ("Drawing %s: drag over free tiles. Tap the item again to stop." if Catalog.is_tile(item) else "Placing %s: tap a free tile. Tap the item again to stop.") % String(item["name"])
		info_label.text = String(item["desc"])
	else:
		status_label.text = "Open Build, pick a structure, then tap the map. Drag to move around."
		var unlocked := 0
		for entry in Catalog.ITEMS:
			if _is_unlocked(entry):
				unlocked += 1
		info_label.text = "%d of %d structures unlocked. Finish chapters to unlock more." % [unlocked, Catalog.ITEMS.size()]

# --- Saving ----------------------------------------------------------------------

func _save_city() -> void:
	var placed: Array = []
	for cell in occupied.keys():
		var node: Node2D = occupied[cell]
		placed.append({"id": String(node.get_meta("item_id")), "x": cell.x, "y": cell.y})
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"placed": placed}))
	file.close()

func _load_city() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for entry in parsed.get("placed", []):
		_place(String(entry["id"]), Vector2i(int(entry["x"]), int(entry["y"])), false)
