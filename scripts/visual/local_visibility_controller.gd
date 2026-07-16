class_name LocalVisibilityController
extends Node

@export_range(96.0, 220.0, 4.0) var visibility_radius: float = 148.0
@export_range(24.0, 96.0, 4.0) var inner_radius: float = 52.0
@export_range(0.04, 0.2, 0.01) var refresh_interval: float = 0.08

var _player: TopDownPlayer
var _targets: Array[EchoRevealable] = []
var _refresh_remaining: float = 0.0
var _awareness_visual: PlayerLocalAwareness


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	set_process(false)
	call_deferred(&"_bind_parent_player")


func bind(player: TopDownPlayer) -> void:
	_player = player
	_awareness_visual = get_node_or_null(^"../LocalAwareness") as PlayerLocalAwareness
	if _awareness_visual != null:
		_awareness_visual.configure(visibility_radius, inner_radius)
	_cache_targets()
	_update_visibility()
	_refresh_remaining = refresh_interval
	set_process(_player != null)


func get_cached_target_count() -> int:
	return _targets.size()


func is_bound() -> bool:
	return is_instance_valid(_player)


func refresh_targets() -> void:
	_cache_targets()
	_update_visibility()


func _bind_parent_player() -> void:
	var parent_player := get_parent() as TopDownPlayer
	if parent_player == null:
		push_error("LocalVisibilityController must be a child of TopDownPlayer.")
		return
	bind(parent_player)


func _process(delta: float) -> void:
	_refresh_remaining -= maxf(delta, 0.0)
	if _refresh_remaining > 0.0:
		return
	_refresh_remaining = refresh_interval
	_update_visibility()


func _cache_targets() -> void:
	_targets.clear()
	for node: Node in get_tree().get_nodes_in_group(&"echo_revealable"):
		var revealable := node as EchoRevealable
		if revealable != null and revealable.receives_local_visibility:
			_targets.append(revealable)


func _update_visibility() -> void:
	if not is_instance_valid(_player):
		set_process(false)
		return
	var player_position := _player.global_position
	var fade_distance := maxf(visibility_radius - inner_radius, 1.0)
	for target: EchoRevealable in _targets:
		if not is_instance_valid(target):
			continue
		var distance := target.get_reveal_distance_from(player_position)
		var strength := 1.0 - clampf((distance - inner_radius) / fade_distance, 0.0, 1.0)
		target.set_local_visibility(strength)
