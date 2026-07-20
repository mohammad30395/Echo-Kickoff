class_name PowerGridController
extends Node

signal power_level_changed(ratio: float)
signal restoration_completed

@export var unpowered_modulate: Color = Color(0.72, 0.78, 0.9, 1.0)
@export var powered_modulate: Color = Color.WHITE
@export_range(0.1, 2.0, 0.05) var step_duration: float = 0.45
@export_range(0.5, 3.0, 0.1) var final_sequence_duration: float = 1.6

var power_ratio: float = 0.0
var _mission: MissionObjectiveController
var _gate: ExtractionGate
var _player: TopDownPlayer
var _sectors: Array[FacilitySector] = []
var _world_modulate: CanvasModulate
var _overlay: PowerRestorationOverlay
var _final_sequence_started: bool = false
var _world_tween: Tween


func bind(
	mission: MissionObjectiveController,
	gate: ExtractionGate,
	player: TopDownPlayer,
	sectors: Array[FacilitySector],
	world_modulate: CanvasModulate,
	overlay: PowerRestorationOverlay,
) -> void:
	_mission = mission
	_gate = gate
	_player = player
	_sectors = sectors
	_world_modulate = world_modulate
	_overlay = overlay
	if _world_modulate != null:
		_world_modulate.color = unpowered_modulate
	_mission.power_progress_changed.connect(_on_power_progress_changed)
	_apply_power_ratio(0.0)


func _on_power_progress_changed(active: int, required: int, ratio: float) -> void:
	var next_ratio := clampf(ratio, power_ratio, 1.0)
	_apply_power_ratio(next_ratio)
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and active > 0:
		audio_manager.call(&"play_cue", &"power_surge", -2.0 if active < required else 0.0)
	if active >= required and not _final_sequence_started:
		_run_final_sequence()


func _apply_power_ratio(next_ratio: float) -> void:
	power_ratio = clampf(next_ratio, 0.0, 1.0)
	for sector: FacilitySector in _sectors:
		sector.set_power_ratio(power_ratio)
	if _world_modulate != null:
		var target := unpowered_modulate.lerp(powered_modulate, power_ratio)
		if _world_tween != null and _world_tween.is_valid():
			_world_tween.kill()
		_world_tween = create_tween()
		_world_tween.tween_property(_world_modulate, ^"color", target, step_duration)
	power_level_changed.emit(power_ratio)


func _run_final_sequence() -> void:
	_final_sequence_started = true
	_gate.begin_powering()
	_player.set_controls_enabled(false)
	if _overlay != null:
		_overlay.play_sequence()
	var timer := get_tree().create_timer(0.38, false)
	await timer.timeout
	await _gate.open_gate()
	var remaining := maxf(final_sequence_duration - 1.38, 0.1)
	await get_tree().create_timer(remaining, false).timeout
	_player.set_controls_enabled(true)
	restoration_completed.emit()
