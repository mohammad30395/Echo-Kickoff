extends Control

@onready var main_menu_button: Button = %MainMenuButton
@onready var next_level_button: Button = %NextLevelButton
@onready var retry_button: Button = %RetryButton
@onready var level_select_button: Button = %LevelSelectButton
@onready var title_label: Label = %Title
@onready var rank_label: Label = %RankLabel
@onready var rank_badge: TextureRect = %RankBadge
@onready var stats_label: Label = %StatsLabel


func _ready() -> void:
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	next_level_button.pressed.connect(_on_next_level_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	level_select_button.pressed.connect(_on_level_select_pressed)
	_refresh_result()
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.call(&"play_cue", &"level_complete")
	(next_level_button if next_level_button.visible else retry_button).grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		EventBus.main_menu_requested.emit()


func _on_main_menu_pressed() -> void:
	EventBus.main_menu_requested.emit()


func _on_next_level_pressed() -> void:
	EventBus.next_level_requested.emit()


func _on_retry_pressed() -> void:
	EventBus.retry_level_requested.emit()


func _on_level_select_pressed() -> void:
	CampaignManager.request_level_select_on_menu()
	EventBus.main_menu_requested.emit()


func _refresh_result() -> void:
	var result := CampaignManager.last_result
	var definition := CampaignManager.get_definition()
	if result == null or definition == null:
		title_label.text = "EXTRACTION COMPLETE"
		rank_label.text = "MISSION COMPLETE"
		stats_label.text = "The signal found its way out."
		next_level_button.visible = false
		rank_badge.visible = false
		return
	rank_badge.visible = true
	title_label.text = "%s // COMPLETE" % definition.display_name
	rank_label.text = "RANK %s" % result.rank
	rank_badge.texture = load("res://assets/ui/icons/rank-%s.svg" % String(result.rank).to_lower()) as Texture2D
	stats_label.text = (
		"TIME  %s     ECHOES  %d     DECOYS  %d     CHASES  %d"
		% [_format_time(result.completion_time), result.pulse_count, result.decoy_count, result.chase_count]
	)
	var next_level_id := definition.next_level_id
	next_level_button.visible = not next_level_id.is_empty()
	if next_level_button.visible:
		var next_definition := CampaignManager.get_definition(next_level_id)
		next_level_button.text = "NEXT // %s" % next_definition.difficulty_name
	else:
		rank_label.text = "CAMPAIGN COMPLETE // RANK %s" % result.rank


func _format_time(seconds: float) -> String:
	return "%02d:%02d.%02d" % [
		int(seconds) / 60,
		int(seconds) % 60,
		int(fmod(seconds, 1.0) * 100.0),
	]
