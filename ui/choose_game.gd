extends Control

# Figure 29 — New Game / Continue Game chooser. UI is authored directly in
# scenes/choose_game.tscn; this script only wires up references and
# behavior. Continue Game's enabled state and the "no session" label are
# genuinely dynamic (depend on GameProgress.has_save() at load time), so
# they're set here each time rather than baked as a fixed snapshot.

@onready var continue_button: Button = $Center/RootBox/ChoicePanel/PanelBox/ContinueButton
@onready var no_session_label: Label = $Center/RootBox/ChoicePanel/PanelBox/NoSessionLabel

func _ready() -> void:
	$BackButton.pressed.connect(_on_back_pressed)
	$Center/RootBox/ChoicePanel/PanelBox/NewGameButton.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)

	var has_save := GameProgress.has_save()
	continue_button.disabled = not has_save
	no_session_label.visible = not has_save

func _on_new_game_pressed() -> void:
	GameProgress.start_new_game()
	UIKit.go_to_scene("res://scenes/chapter_select.tscn")

func _on_continue_pressed() -> void:
	GameProgress.load_progress()
	UIKit.go_to_scene("res://scenes/chapter_select.tscn")

func _on_back_pressed() -> void:
	AuthState.logout()
	UIKit.go_to_scene("res://scenes/login.tscn")
