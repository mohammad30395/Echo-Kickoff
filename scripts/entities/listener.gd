class_name Listener
extends CharacterBody2D

signal state_changed(previous_state: ListenerState, current_state: ListenerState)
signal noise_target_changed(position: Vector2, category: StringName)
signal player_caught

enum ListenerState {
	IDLE,
	PATROL,
	INVESTIGATE,
	SEARCH,
	CHASE,
	RETURN,
}

const SEARCH_DIRECTIONS := [
	Vector2.RIGHT,
	Vector2.DOWN,
	Vector2.LEFT,
	Vector2.UP,
]

@export_category("Patrol")
@export var patrol_points: Array[Vector2] = []
@export_range(0.0, 4.0, 0.05) var initial_idle_duration: float = 0.35
@export_range(0.0, 4.0, 0.05) var patrol_wait_duration: float = 0.45

@export_category("Movement")
@export_range(10.0, 500.0, 1.0) var patrol_speed: float = 78.0
@export_range(10.0, 500.0, 1.0) var investigate_speed: float = 110.0
@export_range(10.0, 600.0, 1.0) var chase_speed: float = 150.0
@export_range(10.0, 500.0, 1.0) var return_speed: float = 94.0
@export_range(10.0, 4000.0, 10.0) var acceleration: float = 900.0
@export_range(2.0, 64.0, 1.0) var arrival_distance: float = 12.0

@export_category("Hearing")
@export_range(0.1, 3.0, 0.05) var hearing_sensitivity: float = 1.0
@export_range(0.0, 300.0, 1.0) var minimum_heard_loudness: float = 30.0
@export_range(0.1, 1.0, 0.05) var newer_noise_replacement_ratio: float = 0.7
@export_range(0.0, 300.0, 1.0) var stimulus_decay_per_second: float = 24.0

@export_category("Search and Detection")
@export_range(16.0, 240.0, 1.0) var search_radius: float = 72.0
@export_range(0.2, 10.0, 0.1) var search_duration: float = 3.2
@export_range(16.0, 300.0, 1.0) var detection_range: float = 105.0
@export_range(8.0, 80.0, 1.0) var contact_range: float = 34.0
@export_range(0.05, 1.0, 0.05) var detection_check_interval: float = 0.15
@export_range(0.05, 1.0, 0.05) var chase_retarget_interval: float = 0.18
@export_range(0.1, 5.0, 0.1) var chase_memory_duration: float = 1.2
@export_flags_2d_physics var detection_collision_mask: int = 1
@export var trigger_game_over_on_contact: bool = true

@export_category("Stuck Recovery")
@export_range(0.1, 3.0, 0.1) var stuck_check_duration: float = 0.65
@export_range(0.0, 10.0, 0.1) var stuck_minimum_movement: float = 0.4
@export_range(0.1, 2.0, 0.05) var recovery_duration: float = 0.45
@export_range(1, 8, 1) var maximum_recovery_attempts: int = 3
@export_range(0.5, 6.0, 0.1) var route_progress_timeout: float = 1.8
@export_range(1.0, 32.0, 1.0) var meaningful_route_progress: float = 6.0
@export_range(0.5, 6.0, 0.1) var maximum_wall_follow_duration: float = 2.5

@export_category("Debug")
@export var debug_enabled: bool = false
@export var allow_debug_input: bool = true
@export_range(32.0, 1000.0, 1.0) var debug_reference_loudness: float = 480.0

@onready var listener_visual: ListenerVisual = %Visual
@onready var debug_label: Label = %DebugLabel

var current_state: ListenerState = ListenerState.IDLE
var last_heard_position: Vector2 = Vector2.ZERO
var last_heard_category: StringName = &"none"
var last_heard_timestamp: float = -1.0
var current_stimulus_priority: float = 0.0
var target_update_count: int = 0
var is_disabled: bool = false

var _spawn_position: Vector2
var _move_target: Vector2
var _current_patrol_index: int = 0
var _state_elapsed: float = 0.0
var _idle_duration: float = 0.0
var _search_center: Vector2
var _search_point_index: int = 0
var _target_player: TopDownPlayer
var _player_visible: bool = false
var _last_seen_position: Vector2
var _time_since_player_seen: float = 0.0
var _detection_timer: float = 0.0
var _chase_retarget_timer: float = 0.0
var _stuck_timer: float = 0.0
var _recovery_remaining: float = 0.0
var _recovery_direction: Vector2 = Vector2.ZERO
var _recovery_attempts: int = 0
var _wall_following: bool = false
var _wall_follow_direction: Vector2 = Vector2.ZERO
var _wall_follow_elapsed: float = 0.0
var _best_target_distance: float = INF
var _no_progress_timer: float = 0.0
var _has_caught_player: bool = false
var _event_bus: Node
var _ray_query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.new()
var _ray_exclusions: Array[RID] = []


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group(&"listener")
	add_to_group(&"listener_ai")
	_spawn_position = global_position
	_move_target = global_position
	_ray_exclusions = [get_rid()]
	_ray_query.exclude = _ray_exclusions
	_ray_query.collide_with_areas = false
	_ray_query.collide_with_bodies = true
	_find_player()
	_event_bus = get_node_or_null("/root/EventBus")
	if _event_bus != null:
		_event_bus.connect(&"noise_emitted", _on_noise_emitted)
	_idle_duration = initial_idle_duration
	_update_visual_state()
	set_debug_enabled(debug_enabled)


func _exit_tree() -> void:
	if _event_bus != null and _event_bus.is_connected(&"noise_emitted", _on_noise_emitted):
		_event_bus.disconnect(&"noise_emitted", _on_noise_emitted)


func _physics_process(delta: float) -> void:
	if is_disabled or _has_caught_player:
		velocity = Vector2.ZERO
		return
	_state_elapsed += maxf(delta, 0.0)
	current_stimulus_priority = move_toward(
		current_stimulus_priority,
		0.0,
		stimulus_decay_per_second * maxf(delta, 0.0),
	)
	_update_detection(delta)
	match current_state:
		ListenerState.IDLE:
			_update_idle(delta)
		ListenerState.PATROL:
			_update_patrol(delta)
		ListenerState.INVESTIGATE:
			_update_investigate(delta)
		ListenerState.SEARCH:
			_update_search(delta)
		ListenerState.CHASE:
			_update_chase(delta)
		ListenerState.RETURN:
			_update_return(delta)
	_update_visual_rotation(delta)
	listener_visual.advance_animation(delta)


func get_state_name() -> StringName:
	return ListenerState.keys()[current_state]


func get_move_target() -> Vector2:
	return _move_target


func get_last_seen_position() -> Vector2:
	return _last_seen_position


func is_player_currently_visible() -> bool:
	return _player_visible


func has_caught_player() -> bool:
	return _has_caught_player


func get_debug_hearing_radius() -> float:
	return debug_reference_loudness * hearing_sensitivity


func set_target_player(player: TopDownPlayer) -> void:
	_target_player = player


func apply_tuning(profile: EnemyTuningProfile) -> void:
	if profile == null:
		return
	patrol_speed = profile.patrol_speed
	investigate_speed = profile.investigate_speed
	chase_speed = profile.chase_speed
	acceleration = profile.acceleration
	hearing_sensitivity = profile.hearing_sensitivity
	detection_range = profile.detection_range
	detection_check_interval = profile.detection_check_interval
	chase_retarget_interval = profile.chase_retarget_interval
	chase_memory_duration = profile.chase_memory_duration
	search_duration = profile.search_duration


func set_debug_enabled(enabled: bool) -> void:
	debug_enabled = enabled
	if is_node_ready():
		debug_label.visible = debug_enabled
		_update_debug_label()
	queue_redraw()


func set_disabled(disabled: bool) -> void:
	is_disabled = disabled
	velocity = Vector2.ZERO
	if is_node_ready():
		listener_visual.set_movement_state(Vector2.ZERO, chase_speed)
	set_physics_process(not is_disabled and not _has_caught_player)
	if is_node_ready():
		_update_debug_label()


func receive_noise(noise_event: NoiseEvent) -> bool:
	if is_disabled or _has_caught_player or noise_event.loudness < minimum_heard_loudness:
		return false
	var distance := global_position.distance_to(noise_event.position)
	var effective_radius := noise_event.loudness * hearing_sensitivity
	if distance > effective_radius:
		return false
	if current_state == ListenerState.CHASE and _player_visible:
		return false
	var candidate_priority := _noise_priority(noise_event, distance, effective_radius)
	var is_newer := noise_event.timestamp > last_heard_timestamp
	var can_replace := (
		current_state in [ListenerState.IDLE, ListenerState.PATROL, ListenerState.RETURN]
		or candidate_priority > current_stimulus_priority
		or (is_newer and candidate_priority >= current_stimulus_priority * newer_noise_replacement_ratio)
	)
	if not can_replace:
		return false
	last_heard_position = noise_event.position
	last_heard_category = noise_event.category
	last_heard_timestamp = noise_event.timestamp
	current_stimulus_priority = candidate_priority
	_set_move_target(last_heard_position)
	_change_state(ListenerState.INVESTIGATE)
	noise_target_changed.emit(last_heard_position, last_heard_category)
	return true


func _on_noise_emitted(noise_event: NoiseEvent) -> void:
	receive_noise(noise_event)


func _noise_priority(noise_event: NoiseEvent, distance: float, effective_radius: float) -> float:
	var category_weight := 1.0
	if noise_event.category == NoiseEvent.CATEGORY_ECHO_PULSE:
		category_weight = 1.35
	elif noise_event.category == NoiseEvent.CATEGORY_SOUND_DECOY:
		# Precision is the decoy's advantage: a nearby impact can redirect a
		# Listener from a distant event, while louder events still win at equal range.
		category_weight = 1.3
	elif noise_event.category == NoiseEvent.CATEGORY_REACTOR_RELAY:
		category_weight = 1.5
	elif noise_event.category == NoiseEvent.CATEGORY_FOOTSTEP:
		category_weight = 0.65
	var remaining_reach := maxf(effective_radius - distance, 0.0)
	return (noise_event.loudness * 0.7 + remaining_reach * 0.3) * category_weight


func _update_idle(delta: float) -> void:
	_slow_to_stop(delta)
	if _state_elapsed >= _idle_duration and not patrol_points.is_empty():
		_set_move_target(_patrol_position(_current_patrol_index))
		_change_state(ListenerState.PATROL)


func _update_patrol(delta: float) -> void:
	if _move_to_target(delta, patrol_speed):
		_current_patrol_index = (_current_patrol_index + 1) % patrol_points.size()
		_idle_duration = patrol_wait_duration
		_change_state(ListenerState.IDLE)


func _update_investigate(delta: float) -> void:
	if _move_to_target(delta, investigate_speed):
		_begin_search(last_heard_position)


func _update_search(delta: float) -> void:
	if _state_elapsed >= search_duration:
		_begin_return()
		return
	if _move_to_target(delta, investigate_speed * 0.82):
		_search_point_index = (_search_point_index + 1) % SEARCH_DIRECTIONS.size()
		_set_move_target(
			_search_center + SEARCH_DIRECTIONS[_search_point_index] * search_radius,
		)


func _update_chase(delta: float) -> void:
	if _target_player == null or not is_instance_valid(_target_player):
		_begin_search(_last_seen_position)
		return
	if global_position.distance_to(_target_player.global_position) <= contact_range:
		_catch_player()
		return
	if _player_visible:
		_time_since_player_seen = 0.0
		_chase_retarget_timer -= maxf(delta, 0.0)
		if _chase_retarget_timer <= 0.0:
			_set_move_target(_last_seen_position)
			_chase_retarget_timer = chase_retarget_interval
	else:
		_time_since_player_seen += maxf(delta, 0.0)
	_move_to_target(delta, chase_speed)
	if not _player_visible and _time_since_player_seen >= chase_memory_duration:
		_begin_search(_last_seen_position)


func _update_return(delta: float) -> void:
	if _move_to_target(delta, return_speed):
		_idle_duration = patrol_wait_duration
		_change_state(ListenerState.IDLE)


func _update_detection(delta: float) -> void:
	_detection_timer -= maxf(delta, 0.0)
	if _detection_timer > 0.0:
		return
	_detection_timer = detection_check_interval
	if _target_player == null or not is_instance_valid(_target_player):
		_find_player()
	_player_visible = _can_detect_player()
	if _player_visible:
		_last_seen_position = _target_player.global_position
	if _player_visible and current_state != ListenerState.CHASE:
		_time_since_player_seen = 0.0
		_set_move_target(_last_seen_position)
		_change_state(ListenerState.CHASE)


func _can_detect_player() -> bool:
	if _target_player == null or not is_instance_valid(_target_player):
		return false
	var distance := global_position.distance_to(_target_player.global_position)
	if distance <= contact_range:
		return true
	if distance > detection_range:
		return false
	_ray_query.from = global_position
	_ray_query.to = _target_player.global_position
	_ray_query.collision_mask = detection_collision_mask
	var hit := get_world_2d().direct_space_state.intersect_ray(_ray_query)
	return not hit.is_empty() and hit.get("collider") == _target_player


func _move_to_target(delta: float, speed: float) -> bool:
	var to_target := _move_target - global_position
	if to_target.length() <= arrival_distance:
		_slow_to_stop(delta)
		_stuck_timer = 0.0
		_recovery_attempts = 0
		_no_progress_timer = 0.0
		return true
	var desired_direction := to_target.normalized()
	if _wall_following:
		_wall_follow_elapsed += maxf(delta, 0.0)
		if (
			(_wall_follow_elapsed >= 0.12 and _has_clear_route_to_target())
			or _wall_follow_elapsed >= maximum_wall_follow_duration
		):
			_wall_following = false
			_wall_follow_elapsed = 0.0
		else:
			desired_direction = _wall_follow_direction
	elif _recovery_remaining > 0.0:
		_recovery_remaining = move_toward(_recovery_remaining, 0.0, maxf(delta, 0.0))
		desired_direction = _recovery_direction
	velocity = velocity.move_toward(
		desired_direction * speed,
		acceleration * maxf(delta, 0.0),
	)
	var position_before_move := global_position
	move_and_slide()
	var moved_distance := global_position.distance_to(position_before_move)
	var remaining_distance := global_position.distance_to(_move_target)
	if remaining_distance <= _best_target_distance - meaningful_route_progress:
		_best_target_distance = remaining_distance
		_no_progress_timer = 0.0
		_recovery_attempts = 0
	else:
		_no_progress_timer += maxf(delta, 0.0)
	if get_slide_collision_count() > 0 and not _wall_following and _recovery_remaining <= 0.0:
		var collision := get_slide_collision(0)
		var tangent := collision.get_normal().orthogonal().normalized()
		if tangent.dot(desired_direction) < (-tangent).dot(desired_direction):
			tangent = -tangent
		_wall_following = true
		_wall_follow_direction = tangent
		_wall_follow_elapsed = 0.0
	if moved_distance < stuck_minimum_movement:
		_stuck_timer += maxf(delta, 0.0)
	else:
		_stuck_timer = 0.0
	if _stuck_timer >= stuck_check_duration or _no_progress_timer >= route_progress_timeout:
		_begin_stuck_recovery(desired_direction)
	return false


func _begin_stuck_recovery(desired_direction: Vector2) -> void:
	_stuck_timer = 0.0
	_no_progress_timer = 0.0
	_wall_following = false
	_wall_follow_elapsed = 0.0
	_recovery_attempts += 1
	if _recovery_attempts > maximum_recovery_attempts:
		_fail_current_route()
		return
	var side := -1.0 if _recovery_attempts % 2 == 0 else 1.0
	_recovery_direction = desired_direction.orthogonal() * side
	_recovery_remaining = recovery_duration


func _fail_current_route() -> void:
	_recovery_attempts = 0
	_recovery_remaining = 0.0
	_wall_following = false
	_wall_follow_elapsed = 0.0
	match current_state:
		ListenerState.PATROL:
			_current_patrol_index = (_current_patrol_index + 1) % patrol_points.size()
			_idle_duration = patrol_wait_duration
			_change_state(ListenerState.IDLE)
		ListenerState.INVESTIGATE, ListenerState.CHASE:
			_begin_search(_move_target)
		ListenerState.SEARCH:
			_begin_return()
		ListenerState.RETURN:
			_idle_duration = patrol_wait_duration
			_change_state(ListenerState.IDLE)


func _begin_search(center: Vector2) -> void:
	_search_center = center
	_search_point_index = 0
	_set_move_target(_search_center + SEARCH_DIRECTIONS[0] * search_radius)
	_change_state(ListenerState.SEARCH)


func _begin_return() -> void:
	if patrol_points.is_empty():
		_set_move_target(_spawn_position)
	else:
		_current_patrol_index = _nearest_patrol_index()
		_set_move_target(_patrol_position(_current_patrol_index))
	_change_state(ListenerState.RETURN)


func _change_state(next_state: ListenerState) -> void:
	if current_state == next_state:
		_update_debug_label()
		return
	var previous_state := current_state
	current_state = next_state
	_state_elapsed = 0.0
	_stuck_timer = 0.0
	_recovery_attempts = 0
	_update_visual_state()
	_update_debug_label()
	queue_redraw()
	state_changed.emit(previous_state, current_state)


func _set_move_target(target: Vector2) -> void:
	if _move_target.is_equal_approx(target):
		return
	_move_target = target
	_wall_following = false
	_wall_follow_elapsed = 0.0
	_best_target_distance = global_position.distance_to(_move_target)
	_no_progress_timer = 0.0
	target_update_count += 1
	queue_redraw()


func _patrol_position(index: int) -> Vector2:
	return _spawn_position + patrol_points[index]


func _nearest_patrol_index() -> int:
	var nearest_index := 0
	var nearest_distance := INF
	for index in range(patrol_points.size()):
		var distance := global_position.distance_squared_to(_patrol_position(index))
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = index
	return nearest_index


func _find_player() -> void:
	var player_node := get_tree().get_first_node_in_group(&"player")
	_target_player = player_node as TopDownPlayer


func _has_clear_route_to_target() -> bool:
	_ray_query.from = global_position
	_ray_query.to = _move_target
	_ray_query.collision_mask = collision_mask
	var hit := get_world_2d().direct_space_state.intersect_ray(_ray_query)
	if hit.is_empty():
		return true
	return _target_player != null and hit.get("collider") == _target_player


func _slow_to_stop(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, acceleration * maxf(delta, 0.0))
	move_and_slide()


func _update_visual_rotation(delta: float) -> void:
	listener_visual.set_movement_state(velocity, chase_speed)
	if velocity.length_squared() <= 4.0:
		return
	var target_rotation := velocity.angle() + PI * 0.5
	listener_visual.rotation = lerp_angle(
		listener_visual.rotation,
		target_rotation,
		clampf(10.0 * maxf(delta, 0.0), 0.0, 1.0),
	)


func _update_visual_state() -> void:
	var alert_level := 0
	match current_state:
		ListenerState.INVESTIGATE:
			alert_level = 1
		ListenerState.SEARCH:
			alert_level = 2
		ListenerState.CHASE:
			alert_level = 3
	listener_visual.set_state(get_state_name(), alert_level)


func _update_debug_label() -> void:
	if not is_node_ready():
		return
	debug_label.text = (
		"DISABLED"
		if is_disabled
		else "%s\nheard: %s" % [get_state_name(), last_heard_category]
	)


func _catch_player() -> void:
	if _has_caught_player:
		return
	_has_caught_player = true
	velocity = Vector2.ZERO
	listener_visual.set_movement_state(Vector2.ZERO, chase_speed)
	listener_visual.trigger_attack_lunge()
	set_physics_process(false)
	player_caught.emit()
	if trigger_game_over_on_contact and _event_bus != null:
		_event_bus.emit_signal(&"game_over_requested")


func _unhandled_input(event: InputEvent) -> void:
	if allow_debug_input and event.is_action_pressed(&"debug_listener_ai"):
		set_debug_enabled(not debug_enabled)


func _draw() -> void:
	if not debug_enabled:
		return
	var hearing_color := Color(1.0, 0.45, 0.16, 0.34)
	draw_arc(
		Vector2.ZERO,
		debug_reference_loudness * hearing_sensitivity,
		0.0,
		TAU,
		96,
		hearing_color,
		1.25,
	)
	var target_color := Color(1.0, 0.75, 0.22, 0.8)
	draw_line(Vector2.ZERO, to_local(_move_target), target_color, 1.25)
	draw_circle(to_local(_move_target), 4.0, target_color)
