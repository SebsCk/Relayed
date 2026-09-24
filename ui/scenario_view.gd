extends Control

# Small visual for chapter 1's scenario: the Relay Clinic and City Hospital
# cut off by the blackout, then linked, then online. Used by the chapter hub
# (progress strip) and the first_call / follow_message activities (where a
# message packet travels the link). Textures are the constants below, so
# swapping in new clinic/hospital art means changing a path here.

signal message_arrived

const BUILDINGS := "res://Isometric City - Starter Set/Buildings/"
const CLINIC_NORMAL := BUILDINGS + "bld_clinic_mint_SW_normal.png"
const CLINIC_DAMAGED := BUILDINGS + "bld_clinic_mint_SW_damaged.png"
const HOSPITAL_NORMAL := BUILDINGS + "bld_hospital_white_SE_normal.png"
const HOSPITAL_DAMAGED := BUILDINGS + "bld_hospital_white_SE_damaged.png"
const TOWER := BUILDINGS + "bld_watertower_blue_SW_normal.png"

enum State { BLACKOUT, LINKED, ONLINE }

const CABLE_COLOR := Color(0.95, 0.75, 0.3)
const RADIO_COLOR := Color(0.15, 0.85, 1.0)
const DAMAGED_TINT := Color(0.55, 0.55, 0.65)

var state: int = State.BLACKOUT
var link_color := RADIO_COLOR

@onready var sky: ColorRect = $Sky
@onready var link: ColorRect = $Link
@onready var clinic_sprite: TextureRect = $ClinicSprite
@onready var hospital_sprite: TextureRect = $HospitalSprite
@onready var tower_sprite: TextureRect = $TowerSprite
@onready var packet: TextureRect = $Packet
@onready var status_label: Label = $StatusLabel
@onready var clinic_tag: Label = $ClinicTag
@onready var link_tag: Label = $LinkTag
@onready var hospital_tag: Label = $HospitalTag

func _ready() -> void:
	tower_sprite.texture = _texture(TOWER, TOWER)
	set_state(State.BLACKOUT)

func _texture(path: String, fallback: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	if ResourceLoader.exists(fallback):
		return load(fallback) as Texture2D
	return null

func set_state(new_state: int) -> void:
	state = new_state
	var powered := state != State.BLACKOUT
	clinic_sprite.texture = _texture(CLINIC_NORMAL if powered else CLINIC_DAMAGED, CLINIC_NORMAL)
	hospital_sprite.texture = _texture(HOSPITAL_NORMAL if powered else HOSPITAL_DAMAGED, HOSPITAL_NORMAL)
	clinic_sprite.modulate = Color.WHITE if powered else DAMAGED_TINT
	hospital_sprite.modulate = Color.WHITE if powered else DAMAGED_TINT
	link.visible = powered
	link.color = link_color if state == State.ONLINE else link_color.darkened(0.45)
	tower_sprite.visible = state == State.ONLINE
	match state:
		State.BLACKOUT:
			sky.color = Color(0.07, 0.08, 0.13)
			status_label.text = "Blackout"
		State.LINKED:
			sky.color = Color(0.12, 0.17, 0.27)
			status_label.text = "Link built"
		State.ONLINE:
			sky.color = Color(0.2, 0.32, 0.5)
			status_label.text = "Block online"

# "cable" or "radio"
func set_link_kind(kind: String) -> void:
	link_color = CABLE_COLOR if kind == "cable" else RADIO_COLOR
	set_state(state)

# part is "clinic", "link" or "hospital"; empty text clears the tag.
func set_tag(part: String, text: String) -> void:
	var tag: Label = clinic_tag
	if part == "link":
		tag = link_tag
	elif part == "hospital":
		tag = hospital_tag
	tag.text = text
	tag.visible = not text.is_empty()

func clear_tags() -> void:
	for part in ["clinic", "link", "hospital"]:
		set_tag(part, "")

func send_message(seconds: float) -> void:
	packet.modulate = link_color.lightened(0.3)
	packet.position = Vector2(link.position.x, link.position.y + link.size.y / 2.0 - packet.size.y / 2.0)
	packet.visible = true
	var end_x := link.position.x + link.size.x - packet.size.x
	var tween := create_tween()
	tween.tween_property(packet, "position:x", end_x, seconds)
	tween.tween_callback(_on_message_arrived)

func _on_message_arrived() -> void:
	packet.visible = false
	message_arrived.emit()
