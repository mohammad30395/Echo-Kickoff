extends Node

enum ScreenState {
	BOOT,
	MAIN_MENU,
	GAME_WORLD,
	GAME_OVER,
	VICTORY,
}

enum RoundState {
	PLAYING,
	PAUSED,
	PLAYER_CAUGHT,
	RESTARTING,
	VICTORY,
	TRANSITIONING,
}

const MAIN_MENU_SCENE := preload("res://scenes/ui/main_menu.tscn")
const GAME_WORLD_SCENE := preload("res://scenes/game_world.tscn")
const PAUSE_MENU_SCENE := preload("res://scenes/ui/pause_menu.tscn")
const GAME_OVER_SCENE := preload("res://scenes/ui/game_over.tscn")
const VICTORY_SCENE := preload("res://scenes/ui/victory.tscn")
const ROUND_TRANSITION_OVERLAY_SCENE := preload("res://scenes/ui/round_transition_overlay.tscn")

@export_range(0.05, 0.5, 0.01) var fade_out_duration: float = 0.16
@export_range(0.05, 0.5, 0.01) var fade_in_duration: float = 0.18
@export_range(0.2, 1.5, 0.05) var death_feedback_duration: float = 0.55

var current_screen: ScreenState = ScreenState.BOOT
var current_round_state: RoundState = RoundState.TRANSITIONING
var current_round_id: int = 0

var _pause_overlay: Control
var _transition_layer: CanvasLayer
var _transition_visual: RoundTransitionVisual
var _transition_in_progress: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_install_transition_overlay()
	EventBus.boot_completed.connect(_on_boot_completed)
	EventBus.new_game_requested.connect(_on_new_game_requested)
	EventBus.pause_requested.connect(_on_pause_requested)
	EventBus.resume_requested.connect(_on_resume_requested)
	EventBus.main_menu_requested.connect(_on_main_menu_requested)
	EventBus.restart_requested.connect(_on_restart_requested)
	EventBus.game_over_requested.connect(_on_game_over_requested)
	EventBus.victory_requested.connect(_on_victory_requested)


func get_state_name() -> StringName:
	if current_round_state == RoundState.PAUSED and current_screen == ScreenState.GAME_WORLD:
		return &"paused"
	match current_screen:
		ScreenState.BOOT:
			return &"boot"
		ScreenState.MAIN_MENU:
			return &"main_menu"
		ScreenState.GAME_WORLD:
			return &"game_world"
		ScreenState.GAME_OVER:
			return &"game_over"
		ScreenState.VICTORY:
			return &"victory"
	return &"unknown"


func get_round_state_name() -> StringName:
	match current_round_state:
		RoundState.PLAYING:
			return &"playing"
		RoundState.PAUSED:
			return &"paused"
		RoundState.PLAYER_CAUGHT:
			return &"player_caught"
		RoundState.RESTARTING:
			return &"restarting"
		RoundState.VICTORY:
			return &"victory"
		RoundState.TRANSITIONING:
			return &"transitioning"
	return &"unknown"


func get_pause_overlay() -> Control:
	return _pause_overlay


func get_transition_overlay() -> RoundTransitionVisual:
	return _transition_visual


func get_session_progress() -> Dictionary:
	# Objective, decoy, pulse, and enemy state deliberately remain scene-local.
	return {&"round_id": current_round_id}


func get_round_state_names() -> Array[StringName]:
	var state_names: Array[StringName] = []
	for state_name: String in RoundState.keys():
		state_names.append(StringName(state_name.to_lower()))
	return state_names


func is_transitioning() -> bool:
	return _transition_in_progress


func _on_boot_completed() -> void:
	if current_screen == ScreenState.BOOT and not _transition_in_progress:
		_transition_from_boot()


func _on_new_game_requested() -> void:
	if current_screen == ScreenState.MAIN_MENU and not _transition_in_progress:
		_start_new_round(false)


func _on_pause_requested() -> void:
	if (
		current_screen != ScreenState.GAME_WORLD
		or current_round_state != RoundState.PLAYING
		or _transition_in_progress
		or is_instance_valid(_pause_overlay)
	):
		return
	var previous_app_state := get_state_name()
	_pause_overlay = PAUSE_MENU_SCENE.instantiate() as Control
	_transition_layer.add_child(_pause_overlay)
	# Keep pause controls above gameplay CanvasLayers while leaving the transition
	# visual last so fades can still cover the complete frame.
	_transition_layer.move_child(_pause_overlay, 0)
	get_tree().paused = true
	_set_round_state(RoundState.PAUSED)
	EventBus.app_state_changed.emit(previous_app_state, get_state_name())


func _on_resume_requested() -> void:
	if current_screen != ScreenState.GAME_WORLD or current_round_state != RoundState.PAUSED:
		return
	var previous_app_state := get_state_name()
	get_tree().paused = false
	_clear_pause_overlay()
	_set_round_state(RoundState.PLAYING)
	EventBus.app_state_changed.emit(previous_app_state, get_state_name())


func _on_main_menu_requested() -> void:
	var can_leave_round := (
		current_screen == ScreenState.GAME_WORLD
		and current_round_state == RoundState.PAUSED
	)
	var can_leave_terminal := (
		current_screen == ScreenState.GAME_OVER
		and current_round_state == RoundState.PLAYER_CAUGHT
	) or (
		current_screen == ScreenState.VICTORY
		and current_round_state == RoundState.VICTORY
	)
	if (can_leave_round or can_leave_terminal) and not _transition_in_progress:
		_transition_to_main_menu()


func _on_restart_requested() -> void:
	if (
		current_screen == ScreenState.GAME_OVER
		and current_round_state == RoundState.PLAYER_CAUGHT
		and not _transition_in_progress
	):
		_start_new_round(true)


func _on_game_over_requested() -> void:
	if (
		current_screen == ScreenState.GAME_WORLD
		and current_round_state == RoundState.PLAYING
		and not _transition_in_progress
	):
		_run_player_caught_flow()


func _on_victory_requested() -> void:
	if (
		current_screen == ScreenState.GAME_WORLD
		and current_round_state == RoundState.PLAYING
		and not _transition_in_progress
	):
		_run_victory_flow()


func _transition_from_boot() -> void:
	_transition_in_progress = true
	_transition_visual.begin_fade(1.0)
	AudioManager.stop_round_audio()
	if not await _load_scene(MAIN_MENU_SCENE, ScreenState.MAIN_MENU):
		_recover_transition_failure()
		return
	await _fade_in()
	_set_round_state(RoundState.TRANSITIONING)
	_transition_in_progress = false


func _start_new_round(is_restart: bool) -> void:
	_transition_in_progress = true
	_set_round_state(RoundState.RESTARTING if is_restart else RoundState.TRANSITIONING)
	AudioManager.stop_round_audio()
	await _fade_out()
	if not await _load_scene(GAME_WORLD_SCENE, ScreenState.GAME_WORLD):
		_recover_transition_failure()
		return
	current_round_id += 1
	_set_round_state(RoundState.TRANSITIONING)
	await _fade_in()
	_set_round_state(RoundState.PLAYING)
	_transition_in_progress = false
	EventBus.round_started.emit(current_round_id)


func _run_player_caught_flow() -> void:
	_transition_in_progress = true
	_set_round_state(RoundState.PLAYER_CAUGHT)
	get_tree().paused = true
	await _play_death_feedback()
	await _fade_out(0.42)
	AudioManager.stop_round_audio()
	if not await _load_scene(GAME_OVER_SCENE, ScreenState.GAME_OVER):
		_recover_transition_failure()
		return
	_set_round_state(RoundState.TRANSITIONING)
	await _fade_in()
	_set_round_state(RoundState.PLAYER_CAUGHT)
	_transition_in_progress = false


func _run_victory_flow() -> void:
	_transition_in_progress = true
	_set_round_state(RoundState.VICTORY)
	get_tree().paused = true
	await _fade_out()
	AudioManager.stop_round_audio()
	if not await _load_scene(VICTORY_SCENE, ScreenState.VICTORY):
		_recover_transition_failure()
		return
	_set_round_state(RoundState.TRANSITIONING)
	await _fade_in()
	_set_round_state(RoundState.VICTORY)
	_transition_in_progress = false


func _transition_to_main_menu() -> void:
	_transition_in_progress = true
	_set_round_state(RoundState.TRANSITIONING)
	AudioManager.stop_round_audio()
	await _fade_out()
	if not await _load_scene(MAIN_MENU_SCENE, ScreenState.MAIN_MENU):
		_recover_transition_failure()
		return
	await _fade_in()
	_set_round_state(RoundState.TRANSITIONING)
	_transition_in_progress = false


func _load_scene(scene: PackedScene, next_screen: ScreenState) -> bool:
	get_tree().paused = false
	_clear_pause_overlay()
	var change_error := get_tree().change_scene_to_packed(scene)
	if change_error != OK:
		push_error("Scene change failed with error %d." % change_error)
		return false
	await get_tree().process_frame
	_set_screen_state(next_screen)
	return true


func _play_death_feedback() -> void:
	_transition_visual.begin_death_feedback()
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(
		_transition_visual.set_death_progress,
		0.0,
		1.0,
		death_feedback_duration,
	)
	await tween.finished


func _fade_out(start_alpha: float = 0.0) -> void:
	_transition_visual.begin_fade(start_alpha)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(
		_transition_visual.set_fade_alpha,
		start_alpha,
		1.0,
		fade_out_duration,
	)
	await tween.finished


func _fade_in() -> void:
	_transition_visual.begin_fade(1.0)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(
		_transition_visual.set_fade_alpha,
		1.0,
		0.0,
		fade_in_duration,
	)
	await tween.finished
	_transition_visual.clear()


func _install_transition_overlay() -> void:
	_transition_layer = ROUND_TRANSITION_OVERLAY_SCENE.instantiate() as CanvasLayer
	add_child(_transition_layer)
	_transition_visual = _transition_layer.get_node(^"%Visual") as RoundTransitionVisual
	_transition_visual.begin_fade(1.0)


func _clear_pause_overlay() -> void:
	if is_instance_valid(_pause_overlay):
		_pause_overlay.queue_free()
	_pause_overlay = null


func _set_screen_state(next_screen: ScreenState) -> void:
	var previous_state := get_state_name()
	current_screen = next_screen
	EventBus.app_state_changed.emit(previous_state, get_state_name())


func _set_round_state(next_state: RoundState) -> void:
	if current_round_state == next_state:
		return
	var previous_state := get_round_state_name()
	current_round_state = next_state
	EventBus.round_state_changed.emit(previous_state, get_round_state_name())


func _recover_transition_failure() -> void:
	get_tree().paused = false
	_transition_visual.clear()
	_transition_in_progress = false
	if current_screen == ScreenState.GAME_WORLD:
		_set_round_state(RoundState.PLAYING)
	else:
		_set_round_state(RoundState.TRANSITIONING)
