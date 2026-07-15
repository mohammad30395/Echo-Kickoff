class_name ReactorRelay
extends FacilityInteractable

signal relay_activated(relay: ReactorRelay, actor: Node2D)

@export var relay_id: StringName = &"A"
@export_range(100.0, 1000.0, 10.0) var activation_loudness: float = 620.0

@onready var relay_visual: ReactorRelayVisual = %Visual


func _ready() -> void:
	interaction_name = "REACTOR RELAY %s" % relay_id
	super._ready()
	add_to_group(&"reactor_relay")
	relay_visual.set_active(is_activated)


func get_interaction_prompt(actor: Node2D) -> String:
	if is_activated:
		return "RELAY %s // ONLINE" % relay_id
	return super.get_interaction_prompt(actor)


func _perform_activation(actor: Node2D) -> void:
	relay_visual.set_active(true)
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null:
		event_bus.call(
			&"publish_noise",
			global_position,
			activation_loudness,
			NoiseEvent.CATEGORY_REACTOR_RELAY,
		)
	relay_activated.emit(self, actor)
