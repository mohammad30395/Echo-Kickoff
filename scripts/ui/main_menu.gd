extends Control

const EXTRACTION_DOOR_ICON := preload("res://assets/ui/icons/extraction-door.svg")
const LOCKED_LEVEL_ICON := preload("res://assets/ui/icons/locked-level.svg")
const WARDEN_ICON := preload("res://assets/ui/icons/warden.svg")

@onready var new_game_button: Button = %NewGameButton
@onready var how_to_play_button: Button = %HowToPlayButton
@onready var credits_button: Button = %CreditsButton
@onready var level_select_button: Button = %LevelSelectButton
@onready var reset_progress_button: Button = %ResetProgressButton
@onready var close_info_button: Button = %CloseInfoButton
@onready var info_panel: PanelContainer = %InfoPanel
@onready var level_select_panel: PanelContainer = %LevelSelectPanel
@onready var info_title: Label = %InfoTitle
@onready var info_body: Label = %InfoBody
@onready var settings_row: HBoxContainer = $Center/Content/SettingsRow
@onready var easy_level_button: Button = %EasyLevelButton
@onready var medium_level_button: Button = %MediumLevelButton
@onready var hard_level_button: Button = %HardLevelButton
@onready var close_level_select_button: Button = %CloseLevelSelectButton

var _reset_confirmation_pending: bool = false


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	how_to_play_button.pressed.connect(_on_how_to_play_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	level_select_button.pressed.connect(_on_level_select_pressed)
	reset_progress_button.pressed.connect(_on_reset_progress_pressed)
	easy_level_button.pressed.connect(_on_level_pressed.bind(&"easy"))
	medium_level_button.pressed.connect(_on_level_pressed.bind(&"medium"))
	hard_level_button.pressed.connect(_on_level_pressed.bind(&"hard"))
	close_level_select_button.pressed.connect(_on_close_level_select_pressed)
	close_info_button.pressed.connect(_on_close_info_pressed)
	info_panel.visible = false
	level_select_panel.visible = false
	CampaignManager.progress_changed.connect(_refresh_campaign_ui)
	_refresh_campaign_ui()
	if CampaignManager.consume_level_select_request():
		_on_level_select_pressed()
	else:
		new_game_button.grab_focus()


func _on_new_game_pressed() -> void:
	AudioManager.confirm_user_gesture()
	var test_level := _get_test_level_override()
	if not test_level.is_empty():
		var test_index := CampaignManager.LEVEL_ORDER.find(test_level)
		CampaignManager.highest_unlocked_index = maxi(CampaignManager.highest_unlocked_index, test_index)
		EventBus.level_requested.emit(test_level)
		return
	var level_id := CampaignManager.start_continue_level()
	EventBus.level_requested.emit(level_id)


func _get_test_level_override() -> StringName:
	var requested := ""
	if OS.has_feature("web"):
		var browser_window: JavaScriptObject = JavaScriptBridge.get_interface("window")
		if browser_window != null:
			var query := String(browser_window.location.search)
			for part in query.trim_prefix("?").split("&"):
				if part.begins_with("test_level="):
					requested = part.trim_prefix("test_level=").to_lower()
	else:
		for argument in OS.get_cmdline_user_args():
			if argument.begins_with("--test-level="):
				requested = argument.trim_prefix("--test-level=").to_lower()
	var level_id := StringName(requested)
	return level_id if level_id in [&"easy", &"medium", &"hard"] else &""


func _on_level_select_pressed() -> void:
	_reset_confirmation_pending = false
	reset_progress_button.text = "RESET PROGRESS"
	settings_row.visible = false
	info_panel.visible = false
	level_select_panel.visible = true
	easy_level_button.grab_focus()


func _on_level_pressed(level_id: StringName) -> void:
	if not CampaignManager.is_level_unlocked(level_id):
		return
	AudioManager.confirm_user_gesture()
	EventBus.level_requested.emit(level_id)


func _on_reset_progress_pressed() -> void:
	if not _reset_confirmation_pending:
		_reset_confirmation_pending = true
		reset_progress_button.text = "CONFIRM RESET"
		return
	CampaignManager.reset_progress()
	_reset_confirmation_pending = false
	reset_progress_button.text = "RESET PROGRESS"


func _on_close_level_select_pressed() -> void:
	level_select_panel.visible = false
	settings_row.visible = true
	level_select_button.grab_focus()


func _on_how_to_play_pressed() -> void:
	info_title.text = "HOW TO PLAY // CONTROLS"
	info_body.text = "WASD / Arrow Keys — Move\nReal Virtual Joystick — Drag the bottom-right control to move\nVisibility — You can always see nearby\nEcho Pulse — Space or left click outside the joystick; scans farther and calls Listeners\nDecoy — Q or right mouse to throw a sound decoy\nInteract — Hold E to restore reactors; extraction opens automatically\nPause — Escape\nRestart — R after capture"
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
	level_select_panel.visible = false
	info_panel.visible = true
	close_info_button.grab_focus()


func _refresh_campaign_ui() -> void:
	var continue_definition := CampaignManager.get_definition(
		CampaignManager.LEVEL_ORDER[CampaignManager.highest_unlocked_index],
	)
	if CampaignManager.highest_unlocked_index == 0 and CampaignManager.get_best_rank(&"easy").is_empty():
		new_game_button.text = "START // CAMPAIGN"
	else:
		new_game_button.text = "CONTINUE // %s" % continue_definition.difficulty_name
	_refresh_level_button(easy_level_button, &"easy")
	_refresh_level_button(medium_level_button, &"medium")
	_refresh_level_button(hard_level_button, &"hard")


func _refresh_level_button(button: Button, level_id: StringName) -> void:
	var definition := CampaignManager.get_definition(level_id)
	var unlocked := CampaignManager.is_level_unlocked(level_id)
	button.disabled = not unlocked
	if not unlocked:
		button.icon = LOCKED_LEVEL_ICON
		var level_index := CampaignManager.LEVEL_ORDER.find(level_id)
		var prerequisite := CampaignManager.get_definition(CampaignManager.LEVEL_ORDER[level_index - 1])
		button.text = "%s // LOCKED\nCOMPLETE %s TO UNLOCK" % [
			definition.difficulty_name,
			prerequisite.difficulty_name,
		]
		return
	button.icon = EXTRACTION_DOOR_ICON if level_id == &"easy" else WARDEN_ICON
	var best_rank := CampaignManager.get_best_rank(level_id)
	var best_time := CampaignManager.get_best_time(level_id)
	var record := "UNPLAYED"
	if not best_rank.is_empty():
		record = "RANK %s // %s" % [best_rank, _format_time(best_time)]
	button.text = "%s // %s // %d REACTORS\n%s" % [
		definition.difficulty_name,
		definition.display_name,
		definition.required_reactors,
		record,
	]


func _format_time(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]
