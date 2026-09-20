extends Control

# Figure 31 — Player Account. UI is authored directly in
# scenes/player_profile.tscn; this script wires up references/signals and
# shows real GameProgress data. "View Stats" reflects real progress;
# Achievements/Reputation read real badges/reputation, honest empty states
# when none are earned yet.

@onready var info_panel: Control = $InfoPanel
@onready var info_title: Label = $InfoPanel/InfoCenter/InfoInnerPanel/InfoBox/InfoTitle
@onready var info_body: Label = $InfoPanel/InfoCenter/InfoInnerPanel/InfoBox/InfoBody
@onready var edit_panel: Control = $EditPanel
@onready var edit_field: LineEdit = $EditPanel/EditCenter/EditInnerPanel/EditBox/EditField
@onready var name_label: Label = $Center/ProfilePanel/ProfileBox/NameLabel

func _ready() -> void:
	$BackButton.pressed.connect(func(): UIKit.go_to_scene("res://scenes/chapter_select.tscn"))
	$Center/ProfilePanel/ProfileBox/EditButton.pressed.connect(_show_edit_account)
	$Center/ProfilePanel/ProfileBox/StatsButton.pressed.connect(_show_stats)
	$Center/ProfilePanel/ProfileBox/AchievementsButton.pressed.connect(_show_achievements)
	$Center/ProfilePanel/ProfileBox/ReputationButton.pressed.connect(_show_reputation)

	$InfoPanel/DismissButton.pressed.connect(func(): info_panel.visible = false)
	$EditPanel/EditCenter/EditInnerPanel/EditBox/EditRow/CancelButton.pressed.connect(func(): edit_panel.visible = false)
	$EditPanel/EditCenter/EditInnerPanel/EditBox/EditRow/SaveButton.pressed.connect(_on_save_account)

	name_label.text = AuthState.username if not AuthState.username.is_empty() else "Player"

func _show_edit_account() -> void:
	edit_field.text = AuthState.username
	edit_panel.visible = true

func _on_save_account() -> void:
	var new_name := edit_field.text.strip_edges()
	if not new_name.is_empty():
		AuthState.username = new_name
		name_label.text = new_name
	edit_panel.visible = false

const BADGE_NAMES := {
	"first_contact": "First Contact — completed your first district",
	"city_restored": "City Restored — completed every district",
}

func _show_stats() -> void:
	var completed := 0
	var total_stars := 0
	for chapter in GameProgress.stars.keys():
		total_stars += int(GameProgress.stars[chapter])
		if int(GameProgress.stars[chapter]) > 0:
			completed += 1
	_show_info("Stats", "Rank: %s\nXP: %d\nInfrastructure Fund: %d\nChapters completed: %d / %d\nTotal stars: %d" % [
		GameProgress.administration_rank(), GameProgress.xp, GameProgress.infrastructure_fund,
		completed, GameProgress.TOTAL_CHAPTERS, total_stars,
	])

func _show_achievements() -> void:
	if GameProgress.badges.is_empty():
		_show_info("Achievements", "No badges earned yet — complete a district to earn your first.")
		return
	var lines := PackedStringArray()
	for badge_id in GameProgress.badges:
		lines.append("• " + String(BADGE_NAMES.get(badge_id, badge_id)))
	_show_info("Achievements", "\n".join(lines))

func _show_reputation() -> void:
	_show_info("Reputation", "City Reputation: %d\nRelay City's overall telecom satisfaction, earned by completing districts." % GameProgress.city_reputation)

func _show_info(title: String, body: String) -> void:
	info_title.text = title
	info_body.text = body
	info_panel.visible = true
