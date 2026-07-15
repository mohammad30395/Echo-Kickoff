class_name PlayerInteractionController
extends Area2D

signal focus_changed(interactable: FacilityInteractable)
signal prompt_changed(text: String, progress: float, available: bool)
signal interaction_cancelled(interactable: FacilityInteractable)
signal interaction_completed(interactable: FacilityInteractable)

@export_flags_2d_physics var line_of_sight_collision_mask: int = 1

var focused_interactable: FacilityInteractable
var interaction_progress: float = 0.0

var _actor: Node2D
var _candidates: Array[FacilityInteractable] = []
var _active_interactable: FacilityInteractable
var _last_prompt: String = ""
var _last_progress: float = -1.0
var _last_available: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_actor = get_parent() as Node2D
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _physics_process(delta: float) -> void:
	_refresh_focus()
	_update_interaction(maxf(delta, 0.0))
	_publish_prompt()


func get_focused_interactable() -> FacilityInteractable:
	return focused_interactable


func get_interaction_progress() -> float:
	return interaction_progress


func refresh_prompt() -> void:
	_last_prompt = "__force_prompt_refresh__"
	_last_progress = -1.0
	_publish_prompt()


func has_clear_line_to(interactable: FacilityInteractable) -> bool:
	if interactable == null or not is_instance_valid(interactable) or _actor == null:
		return false
	var exclusions: Array[RID] = []
	if _actor is CollisionObject2D:
		exclusions.append((_actor as CollisionObject2D).get_rid())
	exclusions.append_array(interactable.get_line_of_sight_exclusions())
	var query := PhysicsRayQueryParameters2D.create(
		_actor.global_position,
		interactable.get_interaction_position(),
		line_of_sight_collision_mask,
		exclusions,
	)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func cancel_interaction() -> void:
	if _active_interactable != null and is_instance_valid(_active_interactable):
		interaction_cancelled.emit(_active_interactable)
	_active_interactable = null
	interaction_progress = 0.0


func _refresh_focus() -> void:
	var nearest: FacilityInteractable
	var nearest_distance := INF
	for index in range(_candidates.size() - 1, -1, -1):
		var candidate := _candidates[index]
		if candidate == null or not is_instance_valid(candidate):
			_candidates.remove_at(index)
			continue
		if not has_clear_line_to(candidate):
			continue
		var distance := _actor.global_position.distance_squared_to(
			candidate.get_interaction_position(),
		)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = candidate
	if focused_interactable == nearest:
		return
	cancel_interaction()
	focused_interactable = nearest
	focus_changed.emit(focused_interactable)


func _update_interaction(delta: float) -> void:
	if focused_interactable == null or not is_instance_valid(focused_interactable):
		cancel_interaction()
		return
	if not focused_interactable.is_interaction_available(_actor):
		cancel_interaction()
		return
	if not Input.is_action_pressed(&"interact"):
		cancel_interaction()
		return
	if _active_interactable != focused_interactable:
		_active_interactable = focused_interactable
		interaction_progress = 0.0
	var duration := maxf(focused_interactable.get_interaction_duration(), 0.05)
	interaction_progress = minf(interaction_progress + delta / duration, 1.0)
	if interaction_progress < 1.0:
		return
	var completed_interactable := focused_interactable
	_active_interactable = null
	interaction_progress = 0.0
	if completed_interactable.try_activate(_actor):
		interaction_completed.emit(completed_interactable)


func _publish_prompt() -> void:
	var prompt := ""
	var available := false
	if focused_interactable != null and is_instance_valid(focused_interactable):
		prompt = focused_interactable.get_interaction_prompt(_actor)
		available = focused_interactable.is_interaction_available(_actor)
	if (
		prompt == _last_prompt
		and is_equal_approx(interaction_progress, _last_progress)
		and available == _last_available
	):
		return
	_last_prompt = prompt
	_last_progress = interaction_progress
	_last_available = available
	prompt_changed.emit(prompt, interaction_progress, available)


func _on_area_entered(area: Area2D) -> void:
	if area is FacilityInteractable and not _candidates.has(area as FacilityInteractable):
		_candidates.append(area as FacilityInteractable)


func _on_area_exited(area: Area2D) -> void:
	if not area is FacilityInteractable:
		return
	_candidates.erase(area as FacilityInteractable)
	if focused_interactable == area:
		cancel_interaction()
		focused_interactable = null
		focus_changed.emit(null)
