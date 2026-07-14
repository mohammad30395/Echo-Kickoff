extends Node

enum AppState {
	BOOT,
	MAIN_MENU,
	GAME_WORLD,
	PAUSED,
	GAME_OVER,
	VICTORY,
}

const MAIN_MENU_SCENE := preload("res://scenes/ui/main_menu.tscn")
const GAME_WORLD_SCENE := preload("res://scenes/game_world.tscn")
const PAUSE_MENU_SCENE := preload("res://scenes/ui/pause_menu.tscn")
const GAME_OVER_SCENE := preload("res://scenes/ui/game_over.tscn")
const VICTORY_SCENE := preload("res://scenes/ui/victory.tscn")

var current_state: AppState = AppState.BOOT
var _pause_overlay: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.boot_completed.connect(_on_boot_completed)
	EventBus.new_game_requested.connect(_on_new_game_requested)
	EventBus.pause_requested.connect(_on_pause_requested)
	EventBus.resume_requested.connect(_on_resume_requested)
	EventBus.main_menu_requested.connect(_on_main_menu_requested)
	EventBus.restart_requested.connect(_on_restart_requested)
	EventBus.game_over_requested.connect(_on_game_over_requested)
	EventBus.victory_requested.connect(_on_victory_requested)


func get_state_name() -> StringName:
	match current_state:
		AppState.BOOT:
			return &"boot"
		AppState.MAIN_MENU:
			return &"main_menu"
		AppState.GAME_WORLD:
			return &"game_world"
		AppState.PAUSED:
			return &"paused"
		AppState.GAME_OVER:
			return &"game_over"
		AppState.VICTORY:
			return &"victory"
	return &"unknown"


func get_pause_overlay() -> Control:
	return _pause_overlay


func _on_boot_completed() -> void:
	if current_state == AppState.BOOT:
		_change_scene(MAIN_MENU_SCENE, AppState.MAIN_MENU)


func _on_new_game_requested() -> void:
	if current_state == AppState.MAIN_MENU:
		_change_scene(GAME_WORLD_SCENE, AppState.GAME_WORLD)


func _on_pause_requested() -> void:
	if current_state != AppState.GAME_WORLD or is_instance_valid(_pause_overlay):
		return
	_pause_overlay = PAUSE_MENU_SCENE.instantiate() as Control
	get_tree().root.add_child(_pause_overlay)
	get_tree().paused = true
	_set_state(AppState.PAUSED)


func _on_resume_requested() -> void:
	if current_state != AppState.PAUSED:
		return
	get_tree().paused = false
	_clear_pause_overlay()
	_set_state(AppState.GAME_WORLD)


func _on_main_menu_requested() -> void:
	if current_state in [AppState.PAUSED, AppState.GAME_OVER, AppState.VICTORY]:
		_change_scene(MAIN_MENU_SCENE, AppState.MAIN_MENU)


func _on_restart_requested() -> void:
	if current_state == AppState.GAME_OVER:
		_change_scene(GAME_WORLD_SCENE, AppState.GAME_WORLD)


func _on_game_over_requested() -> void:
	if current_state == AppState.GAME_WORLD:
		_change_scene(GAME_OVER_SCENE, AppState.GAME_OVER)


func _on_victory_requested() -> void:
	if current_state == AppState.GAME_WORLD:
		_change_scene(VICTORY_SCENE, AppState.VICTORY)


func _change_scene(scene: PackedScene, next_state: AppState) -> void:
	get_tree().paused = false
	_clear_pause_overlay()
	var change_error := get_tree().change_scene_to_packed(scene)
	if change_error != OK:
		push_error("Scene change failed with error %d." % change_error)
		return
	_set_state(next_state)


func _clear_pause_overlay() -> void:
	if is_instance_valid(_pause_overlay):
		_pause_overlay.queue_free()
	_pause_overlay = null


func _set_state(next_state: AppState) -> void:
	var previous_state := get_state_name()
	current_state = next_state
	EventBus.app_state_changed.emit(previous_state, get_state_name())
