extends CanvasLayer

@onready var panel = $Panel
@onready var name_label = $Panel/Name
@onready var bandwidth_label = $Panel/Bandwidth
@onready var district_label = $Panel/District
@onready var network_label = $Panel/Network
@onready var close_button = $Panel/CloseButton

func _ready():
	panel.visible = false
	close_button.pressed.connect(_on_close_pressed)

func show_building(building: Building):
	name_label.text = building.building_name
	bandwidth_label.text = "Bandwidth: %d%%" % building.bandwidth_level
	district_label.text = "District: " + building.district_id
	network_label.text = "Prefers: " + building.preferred_network
	panel.visible = true

func hide_panel() -> void:
	panel.visible = false

func _on_close_pressed():
	hide_panel()
