extends Node

signal progress_changed
signal level_selected(level_id: StringName)
signal level_completed(result: RunResult)

const SAVE_PATH := "user://echo_kickoff_progress.cfg"
const SAVE_SCHEMA_VERSION := 1
const LEVEL_ORDER: Array[StringName] = [&"easy", &"medium", &"hard"]

var progress_path: String = SAVE_PATH
var current_level_id: StringName = &"easy"
var highest_unlocked_index: int = 0
var last_result: RunResult
var open_level_select_on_next_menu: bool = false
var _definitions: Dictionary[StringName, CampaignLevelDefinition] = {}
var _best_ranks: Dictionary[StringName, StringName] = {}
var _best_times: Dictionary[StringName, float] = {}


func _ready() -> void:
	_build_catalog()
	_load_progress()


func get_definition(level_id: StringName = current_level_id) -> CampaignLevelDefinition:
	return _definitions.get(level_id) as CampaignLevelDefinition


func get_all_definitions() -> Array[CampaignLevelDefinition]:
	var definitions: Array[CampaignLevelDefinition] = []
	for level_id: StringName in LEVEL_ORDER:
		definitions.append(get_definition(level_id))
	return definitions


func start_level(level_id: StringName) -> bool:
	if not _definitions.has(level_id) or not is_level_unlocked(level_id):
		return false
	current_level_id = level_id
	level_selected.emit(current_level_id)
	return true


func start_continue_level() -> StringName:
	var level_id := LEVEL_ORDER[clampi(highest_unlocked_index, 0, LEVEL_ORDER.size() - 1)]
	start_level(level_id)
	return level_id


func retry_current_level() -> StringName:
	return current_level_id


func complete_current_level(result: RunResult) -> void:
	if result == null or result.level_id != current_level_id:
		return
	last_result = result
	var level_index := LEVEL_ORDER.find(current_level_id)
	if level_index >= 0 and level_index < LEVEL_ORDER.size() - 1:
		highest_unlocked_index = maxi(highest_unlocked_index, level_index + 1)
	var previous_rank: StringName = _best_ranks.get(current_level_id, &"")
	var previous_time: float = _best_times.get(current_level_id, 0.0)
	if RunResult.is_better(result, previous_rank, previous_time):
		_best_ranks[current_level_id] = result.rank
		_best_times[current_level_id] = result.completion_time
	_save_progress()
	level_completed.emit(result)
	progress_changed.emit()


func is_level_unlocked(level_id: StringName) -> bool:
	var index := LEVEL_ORDER.find(level_id)
	return index >= 0 and index <= highest_unlocked_index


func get_best_rank(level_id: StringName) -> StringName:
	return _best_ranks.get(level_id, &"")


func get_best_time(level_id: StringName) -> float:
	return _best_times.get(level_id, 0.0)


func get_next_level_id() -> StringName:
	var definition := get_definition()
	return definition.next_level_id if definition != null else &""


func reset_progress() -> void:
	highest_unlocked_index = 0
	current_level_id = &"easy"
	last_result = null
	_best_ranks.clear()
	_best_times.clear()
	_save_progress()
	progress_changed.emit()


func request_level_select_on_menu() -> void:
	open_level_select_on_next_menu = true


func consume_level_select_request() -> bool:
	var requested := open_level_select_on_next_menu
	open_level_select_on_next_menu = false
	return requested


func _build_catalog() -> void:
	_definitions.clear()
	_register_definition(
		&"easy", "ORIENTATION DECK", "EASY",
		"res://scenes/levels/echo_facility.tscn", 3, 2, 0, 720.0, &"medium",
		[74.0, 110.0, 150.0, 900.0, 1.0, 110.0, 0.15, 0.18, 1.2, 3.2],
	)
	_register_definition(
		&"medium", "RESONANCE LABS", "MEDIUM",
		"res://scenes/levels/resonance_labs.tscn", 5, 3, 1, 1080.0, &"hard",
		[84.0, 126.0, 168.0, 1050.0, 1.15, 125.0, 0.12, 0.14, 1.5, 3.8],
	)
	_register_definition(
		&"hard", "BLACKOUT CORE", "HARD",
		"res://scenes/levels/blackout_core.tscn", 7, 4, 2, 1500.0, &"",
		[94.0, 142.0, 188.0, 1250.0, 1.3, 142.0, 0.1, 0.1, 1.9, 4.6],
	)


func _register_definition(
	level_id: StringName,
	display_name: String,
	difficulty_name: String,
	scene_path: String,
	reactors: int,
	listeners: int,
	wardens: int,
	par_time: float,
	next_level: StringName,
	values: Array,
) -> void:
	var tuning := EnemyTuningProfile.new()
	tuning.patrol_speed = values[0]
	tuning.investigate_speed = values[1]
	tuning.chase_speed = values[2]
	tuning.acceleration = values[3]
	tuning.hearing_sensitivity = values[4]
	tuning.detection_range = values[5]
	tuning.detection_check_interval = values[6]
	tuning.chase_retarget_interval = values[7]
	tuning.chase_memory_duration = values[8]
	tuning.search_duration = values[9]
	var definition := CampaignLevelDefinition.new()
	definition.level_id = level_id
	definition.display_name = display_name
	definition.difficulty_name = difficulty_name
	definition.scene_path = scene_path
	definition.required_reactors = reactors
	definition.listener_count = listeners
	definition.warden_count = wardens
	definition.par_time_seconds = par_time
	definition.next_level_id = next_level
	definition.tuning = tuning
	_definitions[level_id] = definition


func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(progress_path) != OK:
		return
	if int(config.get_value("meta", "schema_version", 0)) != SAVE_SCHEMA_VERSION:
		return
	highest_unlocked_index = clampi(
		int(config.get_value("progress", "highest_unlocked_index", 0)),
		0,
		LEVEL_ORDER.size() - 1,
	)
	for level_id: StringName in LEVEL_ORDER:
		var rank := StringName(config.get_value("results", "%s_rank" % level_id, ""))
		var time := float(config.get_value("results", "%s_time" % level_id, 0.0))
		if RunResult.RANK_ORDER.has(rank) and time > 0.0:
			_best_ranks[level_id] = rank
			_best_times[level_id] = time


func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "schema_version", SAVE_SCHEMA_VERSION)
	config.set_value("progress", "highest_unlocked_index", highest_unlocked_index)
	for level_id: StringName in LEVEL_ORDER:
		if _best_ranks.has(level_id):
			config.set_value("results", "%s_rank" % level_id, String(_best_ranks[level_id]))
			config.set_value("results", "%s_time" % level_id, _best_times[level_id])
	var error := config.save(progress_path)
	if error != OK:
		push_warning("Campaign progress could not be saved: %d" % error)
