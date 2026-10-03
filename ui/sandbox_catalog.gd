extends RefCounted

# Structures the sandbox can place. Each is unlocked by completing its
# "unlock_chapter" (GameProgress.is_completed), so chapter rewards feed the
# sandbox. Art is placeholder: swap "texture" / "width" here to change how a
# structure looks. Used through `preload("res://ui/sandbox_catalog.gd")`
# rather than class_name so it doesn't depend on the editor's class cache.

const BUILDINGS := "res://Isometric City - Starter Set/Buildings/"
const PROPS := "res://Isometric City - Starter Set/Props/"

const ROADS := "res://Isometric City - Starter Set/Roads and Grounds/"

const CATEGORIES := ["Telecom", "Homes", "Services", "Work", "Roads"]

# Neighbour offsets on the isometric grid (screen direction of each edge).
const DIRS := {"NE": Vector2i(0, -1), "SE": Vector2i(1, 0), "SW": Vector2i(0, 1), "NW": Vector2i(-1, 0)}

# Which road piece to show for a set of connected directions (keys are the open
# directions sorted alphabetically). Read from the art: a piece is open on the
# edges without a sidewalk.
const ROAD_PIECES := {
	"SW": "deadend_NE", "NW": "deadend_SE", "NE": "deadend_SW", "SE": "deadend_NW",
	"NW,SE": "straight_SE", "NE,SW": "straight_SW",
	"SE,SW": "corner_N", "NW,SW": "corner_E", "NE,NW": "corner_S", "NE,SE": "corner_W",
	"NW,SE,SW": "intersect_NE", "NE,SE,SW": "intersect_NW", "NE,NW,SW": "intersect_SE", "NE,NW,SE": "intersect_SW",
	"NE,NW,SE,SW": "xing",
}


const ITEMS := [
	{"id": "cell_tower", "name": "Cell Tower", "category": "Telecom", "texture": BUILDINGS + "bld_watertower_blue_SW_normal.png", "width": 100.0, "unlock_chapter": 1,
		"desc": "Sends a wireless signal to the buildings around it."},
	{"id": "telephone_pole", "name": "Telephone Pole", "category": "Telecom", "texture": PROPS + "prop_lightpole_standard_SW_normal.png", "width": 40.0, "unlock_chapter": 1,
		"desc": "Carries cables along the street from place to place."},
	{"id": "cable_hub", "name": "Cable Hub", "category": "Telecom", "texture": BUILDINGS + "bld_warehouse_orange_SW_normal.png", "width": 130.0, "unlock_chapter": 2,
		"desc": "Gathers cables so many buildings can share a connection."},
	{"id": "wifi_station", "name": "WiFi Station", "category": "Telecom", "texture": BUILDINGS + "bld_cafe_pink_SW_normal.png", "width": 110.0, "unlock_chapter": 2,
		"desc": "Gives phones and laptops nearby a Wi-Fi connection."},
	{"id": "fiber_hub", "name": "Fiber Hub", "category": "Telecom", "texture": BUILDINGS + "bld_office2_blue_SW_normal.png", "width": 130.0, "unlock_chapter": 3,
		"desc": "Moves lots of data very fast over glass fibers."},
	{"id": "data_center", "name": "Data Center", "category": "Telecom", "texture": BUILDINGS + "bld_office_gray_SW_normal.png", "width": 130.0, "unlock_chapter": 4,
		"desc": "Stores and sends large amounts of data."},

	{"id": "house_blue", "name": "Blue House", "category": "Homes", "texture": BUILDINGS + "bld_house_blue_SW_normal.png", "width": 90.0, "unlock_chapter": 1,
		"desc": "A small home that needs a connection."},
	{"id": "house_red", "name": "Red House", "category": "Homes", "texture": BUILDINGS + "bld_house_red_SW_normal.png", "width": 90.0, "unlock_chapter": 1,
		"desc": "A small home that needs a connection."},
	{"id": "house_yellow", "name": "Yellow House", "category": "Homes", "texture": BUILDINGS + "bld_house_yellow_SW_normal.png", "width": 90.0, "unlock_chapter": 2,
		"desc": "A small home that needs a connection."},
	{"id": "house_brown", "name": "Brown House", "category": "Homes", "texture": BUILDINGS + "bld_house2_brown_SW_normal.png", "width": 100.0, "unlock_chapter": 3,
		"desc": "A bigger family home."},
	{"id": "house_green", "name": "Green House", "category": "Homes", "texture": BUILDINGS + "bld_house3_green_SW_normal.png", "width": 100.0, "unlock_chapter": 5,
		"desc": "A bigger family home."},
	{"id": "apartments", "name": "Apartments", "category": "Homes", "texture": "res://Isometric Suburban Pack/Buildings/apartment complex 01a.png", "width": 170.0, "unlock_chapter": 2,
		"desc": "Many families share one building and one connection."},

	{"id": "clinic", "name": "Clinic", "category": "Services", "texture": BUILDINGS + "bld_clinic_mint_SW_normal.png", "width": 120.0, "unlock_chapter": 1,
		"desc": "Nurses and doctors who need a steady connection."},
	{"id": "hospital", "name": "Hospital", "category": "Services", "texture": BUILDINGS + "bld_hospital_white_SW_normal.png", "width": 140.0, "unlock_chapter": 1,
		"desc": "A big building where connection can save lives."},
	{"id": "fire_station", "name": "Fire Station", "category": "Services", "texture": BUILDINGS + "bld_firestation_red_SW_normal.png", "width": 130.0, "unlock_chapter": 3,
		"desc": "Emergency calls must always get through."},
	{"id": "police_station", "name": "Police Station", "category": "Services", "texture": BUILDINGS + "bld_policestation_blue_SW_normal.png", "width": 130.0, "unlock_chapter": 4,
		"desc": "Keeps the city safe and needs a reliable link."},
	{"id": "church", "name": "Church", "category": "Services", "texture": BUILDINGS + "bld_church_neutral_SW_normal.png", "width": 120.0, "unlock_chapter": 5,
		"desc": "A place where the neighborhood gathers."},

	{"id": "shop", "name": "Auto Shop", "category": "Work", "texture": BUILDINGS + "bld_autoshop_yellow_SW_normal.png", "width": 120.0, "unlock_chapter": 2,
		"desc": "A small business that takes orders online."},
	{"id": "barbershop", "name": "Barbershop", "category": "Work", "texture": BUILDINGS + "bld_barbershop_purple_SW_normal.png", "width": 110.0, "unlock_chapter": 3,
		"desc": "A small business that books customers by phone."},
	{"id": "fruit_stand", "name": "Fruit Stand", "category": "Work", "texture": BUILDINGS + "bld_fruitstand_neutral_SW_normal.png", "width": 100.0, "unlock_chapter": 4,
		"desc": "A market stall that takes mobile payments."},
	{"id": "office_brown", "name": "Office", "category": "Work", "texture": BUILDINGS + "bld_office_brown_SW_normal.png", "width": 130.0, "unlock_chapter": 5,
		"desc": "Many people work here and share one network."},
	{"id": "office_white", "name": "Tall Office", "category": "Work", "texture": BUILDINGS + "bld_office2_white_SW_normal.png", "width": 130.0, "unlock_chapter": 6,
		"desc": "A big office that needs lots of bandwidth."},
	{"id": "gas_station", "name": "Gas Station", "category": "Work", "texture": BUILDINGS + "bld_gasstation_green_SW_normal.png", "width": 120.0, "unlock_chapter": 6,
		"desc": "Travelers stop here and use their phones."},

	{"id": "road", "name": "Road", "category": "Roads", "kind": "road", "family": "asphalt", "texture": ROADS + "tile_road_straight_SE_normal.png", "unlock_chapter": 1,
		"desc": "Roads join up with nearby roads on their own. Drag to draw a long road."},
	{"id": "dirt_road", "name": "Dirt Road", "category": "Roads", "kind": "road", "family": "dirt", "texture": ROADS + "tile_dirtroad_straight_SE.png", "unlock_chapter": 2,
		"desc": "A simple country road that joins up on its own."},
	{"id": "crosswalk", "name": "Crosswalk", "category": "Roads", "kind": "road", "family": "asphalt", "crosswalk": true, "texture": ROADS + "tile_road_pelican_NW_normal.png", "unlock_chapter": 3,
		"desc": "A road with a crossing. It shows on straight roads."},
	{"id": "concrete", "name": "Concrete", "category": "Roads", "kind": "ground", "texture": ROADS + "tile_ground_concrete_normal.png", "unlock_chapter": 4,
		"desc": "A flat paved area for plazas and yards."},
	{"id": "asphalt_lot", "name": "Parking Lot", "category": "Roads", "kind": "ground", "texture": ROADS + "tile_ground_asphalt_normal.png", "unlock_chapter": 5,
		"desc": "A wide paved space with no sidewalks."},
	{"id": "dirt_ground", "name": "Dirt", "category": "Roads", "kind": "ground", "texture": ROADS + "tile_ground_dirt_normal.png", "unlock_chapter": 6,
		"desc": "Bare ground for building sites and paths."},
	{"id": "pond", "name": "Pond", "category": "Roads", "kind": "ground", "texture": ROADS + "tile_ground_water.png", "unlock_chapter": 7,
		"desc": "A patch of water to decorate the city."},
]

static func kind_of(item: Dictionary) -> String:
	return String(item.get("kind", "building"))

static func is_tile(item: Dictionary) -> bool:
	return not item.is_empty() and kind_of(item) != "building"

static func find(id: String) -> Dictionary:
	for item in ITEMS:
		if String(item["id"]) == id:
			return item
	return {}

static func in_category(category: String) -> Array:
	var result: Array = []
	for item in ITEMS:
		if String(item["category"]) == category:
			result.append(item)
	return result

static func texture_of(item: Dictionary) -> Texture2D:
	var path := String(item["texture"])
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

# Texture for a road tile given which directions have a connecting road.
static func road_texture(family: String, open_dirs: Array, crosswalk: bool) -> Texture2D:
	var names := PackedStringArray()
	for dir_name in open_dirs:
		names.append(String(dir_name))
	names.sort()
	var piece := "straight_SE" if names.is_empty() else String(ROAD_PIECES.get(",".join(names), "xing"))
	if crosswalk and piece.begins_with("straight"):
		piece = "pelican_NW" if piece == "straight_SE" else "pelican_NE"
	var path := ROADS + "tile_dirtroad_%s.png" % piece
	if family != "dirt":
		path = ROADS + ("tile_road_deadned_NW_normal.png" if piece == "deadend_NW" else "tile_road_%s_normal.png" % piece)
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null
