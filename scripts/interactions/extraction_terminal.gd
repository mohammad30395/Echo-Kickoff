class_name ExtractionTerminal
extends FacilityInteractable

signal extraction_completed(terminal: ExtractionTerminal, actor: Node2D)

@onready var terminal_visual: ExtractionTerminalVisual = %Visual

var active_relay_count: int = 0
var required_relay_count: int = 3
var is_unlocked: bool = false


func _ready() -> void:
	interaction_name = "EXTRACTION"
	super._ready()
	add_to_group(&"extraction_terminal")
	terminal_visual.set_terminal_state(is_unlocked, is_activated)


func set_relay_progress(active_count: int, required_count: int) -> void:
	active_relay_count = maxi(active_count, 0)
	required_relay_count = maxi(required_count, 1)
	var next_unlocked := active_relay_count >= required_relay_count
	if is_unlocked == next_unlocked:
		interaction_state_changed.emit()
		return
	is_unlocked = next_unlocked
	terminal_visual.set_terminal_state(is_unlocked, is_activated)
	interaction_state_changed.emit()


func is_interaction_available(actor: Node2D) -> bool:
	return is_unlocked and super.is_interaction_available(actor)


func get_interaction_prompt(actor: Node2D) -> String:
	if is_activated:
		return "EXTRACTION // COMPLETE"
	if not is_unlocked:
		return "EXTRACTION LOCKED // RELAYS %d/%d" % [
			active_relay_count,
			required_relay_count,
		]
	return super.get_interaction_prompt(actor)


func _perform_activation(actor: Node2D) -> void:
	terminal_visual.set_terminal_state(true, true)
	extraction_completed.emit(self, actor)
