class_name ExtractionGate
extends Node2D

signal gate_opened
signal extraction_crossed(actor: TopDownPlayer)
signal entrance_sealed

enum GateState { LOCKED, POWERING, OPEN, EXITED }

@onready var visual: ExtractionGateVisual = %Visual
@onready var blocker_shape: CollisionShape2D = %BlockerShape
@onready var exit_area: Area2D = %ExitArea

var state: GateState = GateState.LOCKED
var _panel_tween: Tween


func _ready() -> void:
	add_to_group(&"extraction_gate")
	exit_area.body_entered.connect(_on_body_entered)
	visual.set_gate_state(state)
	visual.open_progress = 1.0
	call_deferred(&"_play_entry_seal_animation")


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
	_kill_panel_tween()
	_panel_tween = create_tween()
	_panel_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_panel_tween.tween_property(visual, ^"open_progress", 1.0, 0.72)
	var opening_tween := _panel_tween
	await opening_tween.finished
	blocker_shape.set_deferred(&"disabled", true)
	await get_tree().physics_frame
	state = GateState.OPEN
	visual.set_gate_state(state)
	gate_opened.emit()


func is_open() -> bool:
	return state in [GateState.OPEN, GateState.EXITED]


func open_gate_immediately() -> void:
	if state in [GateState.OPEN, GateState.EXITED]:
		return
	_kill_panel_tween()
	state = GateState.OPEN
	visual.open_progress = 1.0
	blocker_shape.set_deferred(&"disabled", true)
	visual.set_gate_state(state)
	gate_opened.emit()


func is_entrance_sealed() -> bool:
	return state == GateState.LOCKED and visual.open_progress <= 0.001 and not blocker_shape.disabled


func _play_entry_seal_animation() -> void:
	if state != GateState.LOCKED:
		return
	# The operative has just entered when the scene begins. The compact panels
	# close behind them while collision remains active for the entire sequence.
	await get_tree().create_timer(0.16, false).timeout
	if state != GateState.LOCKED:
		return
	_kill_panel_tween()
	_panel_tween = create_tween()
	_panel_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_panel_tween.tween_property(visual, ^"open_progress", 0.0, 0.58)
	var closing_tween := _panel_tween
	await closing_tween.finished
	if state == GateState.LOCKED:
		entrance_sealed.emit()


func _kill_panel_tween() -> void:
	if _panel_tween != null and _panel_tween.is_valid():
		_panel_tween.kill()
	_panel_tween = null


func _on_body_entered(body: Node2D) -> void:
	if state != GateState.OPEN or not body is TopDownPlayer:
		return
	state = GateState.EXITED
	visual.set_gate_state(state)
	extraction_crossed.emit(body as TopDownPlayer)
