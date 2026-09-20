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
	if not building.connected_to_network:
		network_label.text = "Prefers: %s (no coverage)" % building.preferred_network
	elif building.congested and building.wire_crossing:
		network_label.text = "Prefers: %s (congested, wire crossing)" % building.preferred_network
	elif building.congested:
		network_label.text = "Prefers: %s (congested)" % building.preferred_network
	elif building.wire_crossing:
		network_label.text = "Prefers: %s (wire crossing)" % building.preferred_network
	else:
		network_label.text = "Prefers: " + building.preferred_network
	panel.visible = true

func _on_close_pressed():
	panel.visible = false
