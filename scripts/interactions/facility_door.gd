class_name FacilityDoor
extends FacilityInteractable

signal door_opened(door: FacilityDoor, actor: Node2D)

@export var is_unlocked: bool = false

@onready var door_visual: FacilityDoorVisual = %Visual
@onready var blocker: StaticBody2D = %Blocker
@onready var blocker_shape: CollisionShape2D = %BlockerShape


func _ready() -> void:
	interaction_name = "FACILITY DOOR"
	super._ready()
	add_to_group(&"facility_door")
	door_visual.set_door_state(is_unlocked, is_activated)


func set_unlocked(unlocked: bool) -> void:
	if is_unlocked == unlocked:
		return
	is_unlocked = unlocked
	door_visual.set_door_state(is_unlocked, is_activated)
	interaction_state_changed.emit()


func is_interaction_available(actor: Node2D) -> bool:
	return is_unlocked and super.is_interaction_available(actor)


func get_interaction_prompt(actor: Node2D) -> String:
	if is_activated:
		return "FACILITY DOOR // OPEN"
	if not is_unlocked:
		return "FACILITY DOOR // LOCKED"
	return super.get_interaction_prompt(actor)


func get_line_of_sight_exclusions() -> Array[RID]:
	return [blocker.get_rid()] if is_instance_valid(blocker) else []


func _perform_activation(actor: Node2D) -> void:
	door_visual.set_door_state(true, true)
	blocker_shape.set_deferred(&"disabled", true)
	door_opened.emit(self, actor)
