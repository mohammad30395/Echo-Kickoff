class_name MissionObjectiveController
extends Node

signal objective_changed(active_relays: int, required_relays: int)
signal extraction_state_changed(unlocked: bool)
signal mission_completed

@export_range(1, 8, 1) var required_relay_count: int = 3
@export var trigger_victory_on_completion: bool = true

var active_relay_count: int = 0
var extraction_unlocked: bool = false
var is_completed: bool = false
var relays: Array[ReactorRelay] = []
var extraction_terminal: ExtractionTerminal


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	call_deferred(&"discover_mission_nodes")


func discover_mission_nodes() -> void:
	relays.clear()
	for node: Node in get_tree().get_nodes_in_group(&"reactor_relay"):
		if node is ReactorRelay and node.get_viewport() == get_viewport():
			relays.append(node as ReactorRelay)
	relays.sort_custom(_sort_relays)
	for relay: ReactorRelay in relays:
		if not relay.relay_activated.is_connected(_on_relay_activated):
			relay.relay_activated.connect(_on_relay_activated)
	extraction_terminal = null
	for node: Node in get_tree().get_nodes_in_group(&"extraction_terminal"):
		if node is ExtractionTerminal and node.get_viewport() == get_viewport():
			extraction_terminal = node as ExtractionTerminal
			break
	if (
		extraction_terminal != null
		and not extraction_terminal.extraction_completed.is_connected(_on_extraction_completed)
	):
		extraction_terminal.extraction_completed.connect(_on_extraction_completed)
	_refresh_objective_state()


func get_objective_text() -> String:
	if is_completed:
		return "MISSION COMPLETE // EXTRACTION CONFIRMED"
	if extraction_unlocked:
		return "RELAYS %d/%d // EXTRACTION READY" % [active_relay_count, required_relay_count]
	return "RESTORE REACTOR RELAYS // %d/%d" % [active_relay_count, required_relay_count]


func _refresh_objective_state() -> void:
	var next_count := 0
	for relay: ReactorRelay in relays:
		if relay.is_activated:
			next_count += 1
	active_relay_count = mini(next_count, required_relay_count)
	var next_unlocked := active_relay_count >= required_relay_count
	if extraction_terminal != null:
		extraction_terminal.set_relay_progress(active_relay_count, required_relay_count)
	objective_changed.emit(active_relay_count, required_relay_count)
	if extraction_unlocked != next_unlocked:
		extraction_unlocked = next_unlocked
		extraction_state_changed.emit(extraction_unlocked)


func _on_relay_activated(_relay: ReactorRelay, _actor: Node2D) -> void:
	_refresh_objective_state()


func _on_extraction_completed(_terminal: ExtractionTerminal, _actor: Node2D) -> void:
	if is_completed or not extraction_unlocked:
		return
	is_completed = true
	objective_changed.emit(active_relay_count, required_relay_count)
	mission_completed.emit()
	if trigger_victory_on_completion:
		var event_bus := get_node_or_null("/root/EventBus")
		if event_bus != null:
			event_bus.emit_signal(&"victory_requested")


func _sort_relays(a: ReactorRelay, b: ReactorRelay) -> bool:
	return String(a.relay_id) < String(b.relay_id)
