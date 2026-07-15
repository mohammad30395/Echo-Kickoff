class_name FacilityInteractable
extends Area2D

signal interaction_state_changed
signal activated(interactable: FacilityInteractable, actor: Node2D)

@export_category("Interaction")
@export var interaction_name: String = "FACILITY CONTROL"
@export_range(0.05, 4.0, 0.05) var hold_duration: float = 1.5
@export var interaction_enabled: bool = true

var is_activated: bool = false


func _ready() -> void:
	monitoring = false
	monitorable = true
	add_to_group(&"facility_interactable")


func get_interaction_position() -> Vector2:
	return global_position


func get_interaction_duration() -> float:
	return hold_duration


func is_interaction_available(_actor: Node2D) -> bool:
	return interaction_enabled and not is_activated


func get_interaction_prompt(actor: Node2D) -> String:
	if is_activated:
		return "%s // COMPLETE" % interaction_name
	if not is_interaction_available(actor):
		return "%s // UNAVAILABLE" % interaction_name
	return "HOLD [E] // %s" % interaction_name


func try_activate(actor: Node2D) -> bool:
	if not is_interaction_available(actor):
		return false
	is_activated = true
	_perform_activation(actor)
	interaction_state_changed.emit()
	activated.emit(self, actor)
	return true


func set_interaction_enabled(enabled: bool) -> void:
	if interaction_enabled == enabled:
		return
	interaction_enabled = enabled
	interaction_state_changed.emit()


func get_line_of_sight_exclusions() -> Array[RID]:
	return []


func _perform_activation(_actor: Node2D) -> void:
	pass
