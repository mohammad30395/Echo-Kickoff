class_name ListenerAudio
extends Node

@export_range(0.2, 2.0, 0.05) var movement_interval: float = 0.62
@export_range(1.0, 100.0, 1.0) var minimum_movement_speed: float = 18.0
@export_range(100.0, 2000.0, 50.0) var audible_distance: float = 950.0

var _listener: Listener
var _movement_remaining: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_listener = get_parent() as Listener
	if _listener == null:
		push_error("ListenerAudio must be a child of Listener.")
		set_physics_process(false)
		return
	_listener.state_changed.connect(_on_listener_state_changed)
	_movement_remaining = movement_interval * 0.5


func _physics_process(delta: float) -> void:
	if _listener.is_disabled or _listener.has_caught_player():
		return
	_movement_remaining -= maxf(delta, 0.0)
	if _movement_remaining > 0.0 or _listener.velocity.length() < minimum_movement_speed:
		return
	_movement_remaining = movement_interval
	var volume_offset := _distance_volume_offset()
	if volume_offset > -50.0:
		AudioManager.play_cue(AudioManager.CUE_LISTENER_MOVEMENT, volume_offset)


func _on_listener_state_changed(
	previous_state: Listener.ListenerState,
	current_state: Listener.ListenerState,
) -> void:
	var became_alerted := (
		current_state == Listener.ListenerState.CHASE
		or (
			current_state == Listener.ListenerState.INVESTIGATE
			and previous_state in [
				Listener.ListenerState.IDLE,
				Listener.ListenerState.PATROL,
				Listener.ListenerState.RETURN,
			]
		)
	)
	if not became_alerted:
		return
	var volume_offset := _distance_volume_offset()
	if volume_offset > -50.0:
		AudioManager.play_cue(AudioManager.CUE_LISTENER_ALERT, volume_offset)


func _distance_volume_offset() -> float:
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return -12.0
	var distance := _listener.global_position.distance_to(player.global_position)
	if distance >= audible_distance:
		return -80.0
	return lerpf(0.0, -18.0, clampf(distance / audible_distance, 0.0, 1.0))
