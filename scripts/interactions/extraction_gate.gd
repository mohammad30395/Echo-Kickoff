class_name ExtractionGate
extends Node2D

signal gate_opened
signal extraction_crossed(actor: TopDownPlayer)

enum GateState { LOCKED, POWERING, OPEN, EXITED }

@onready var visual: ExtractionGateVisual = %Visual
@onready var blocker_shape: CollisionShape2D = %BlockerShape
@onready var exit_area: Area2D = %ExitArea

var state: GateState = GateState.LOCKED


func _ready() -> void:
	add_to_group(&"extraction_gate")
	exit_area.body_entered.connect(_on_body_entered)
	visual.set_gate_state(state)


func begin_powering() -> void:
	if state != GateState.LOCKED:
		return
	state = GateState.POWERING
	visual.set_gate_state(state)


func open_gate() -> void:
	if state in [GateState.OPEN, GateState.EXITED]:
		return
	if state == GateState.LOCKED:
		begin_powering()
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.call(&"play_cue", &"gate_unlock")
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(visual, ^"open_progress", 1.0, 0.9)
	await get_tree().create_timer(0.72, false).timeout
	blocker_shape.set_deferred(&"disabled", true)
	await tween.finished
	state = GateState.OPEN
	visual.set_gate_state(state)
	gate_opened.emit()


func is_open() -> bool:
	return state in [GateState.OPEN, GateState.EXITED]


func open_gate_immediately() -> void:
	if state in [GateState.OPEN, GateState.EXITED]:
		return
	state = GateState.OPEN
	visual.open_progress = 1.0
	blocker_shape.set_deferred(&"disabled", true)
	visual.set_gate_state(state)
	gate_opened.emit()


func _on_body_entered(body: Node2D) -> void:
	if state != GateState.OPEN or not body is TopDownPlayer:
		return
	state = GateState.EXITED
	visual.set_gate_state(state)
	extraction_crossed.emit(body as TopDownPlayer)
