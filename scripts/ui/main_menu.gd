extends Control

@onready var new_game_button: Button = %NewGameButton
@onready var how_to_play_button: Button = %HowToPlayButton
@onready var credits_button: Button = %CreditsButton
@onready var close_info_button: Button = %CloseInfoButton
@onready var info_panel: PanelContainer = %InfoPanel
@onready var info_title: Label = %InfoTitle
@onready var info_body: Label = %InfoBody
@onready var settings_row: HBoxContainer = $Center/Content/SettingsRow


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
	info_title.text = "HOW TO PLAY // CONTROLS"
	info_body.text = "WASD / Arrow Keys — Move\nReal Virtual Joystick — Drag the bottom-right control to move\nVisibility — You can always see nearby\nEcho Pulse — Space or left click outside the joystick; scans farther and calls Listeners\nDecoy — Q or right mouse to throw a sound decoy\nInteract — Hold E to restore relays and use extraction\nPause — Escape\nRestart — R after capture"
	_show_info_panel()


func _on_credits_pressed() -> void:
	info_title.text = "CREDITS"
	info_body.text = "Echo Kickoff\nOriginal jam code, visuals, UI, and audio.\nBuilt with Godot 4.7 for IUT 12th ICT FEST 2026.\nNo third-party game assets."
	_show_info_panel()


func _on_close_info_pressed() -> void:
	info_panel.visible = false
	settings_row.visible = true
	how_to_play_button.grab_focus()


func _show_info_panel() -> void:
	settings_row.visible = false
	info_panel.visible = true
	close_info_button.grab_focus()
