extends Control

@onready var new_game_button: Button = %NewGameButton
@onready var how_to_play_button: Button = %HowToPlayButton
@onready var credits_button: Button = %CreditsButton
@onready var close_info_button: Button = %CloseInfoButton
@onready var info_panel: PanelContainer = %InfoPanel
@onready var info_title: Label = %InfoTitle
@onready var info_body: Label = %InfoBody


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	how_to_play_button.pressed.connect(_on_how_to_play_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	close_info_button.pressed.connect(_on_close_info_pressed)
	info_panel.visible = false
	new_game_button.grab_focus()


func _on_new_game_pressed() -> void:
	AudioManager.confirm_user_gesture()
	EventBus.new_game_requested.emit()


func _on_how_to_play_pressed() -> void:
	info_title.text = "HOW TO PLAY"
	info_body.text = "Move: WASD or arrows; optional Move Pad is in Accessibility.\nPulse when you need sight: Space or Left Mouse.\nEvery pulse also calls Listeners.\nHold E at relays and extraction.\nAfter danger appears, Q or Right Mouse throws a decoy."
	_show_info_panel()


func _on_credits_pressed() -> void:
	info_title.text = "CREDITS"
	info_body.text = "Echo Kickoff\nOriginal jam code, visuals, UI, and audio.\nBuilt with Godot 4.7 for IUT 12th ICT FEST 2026.\nNo third-party game assets."
	_show_info_panel()


func _on_close_info_pressed() -> void:
	info_panel.visible = false
	how_to_play_button.grab_focus()


func _show_info_panel() -> void:
	info_panel.visible = true
	close_info_button.grab_focus()
