class_name EchoRevealable
extends Node2D

signal reveal_changed(strength: float)

@export_category("Reveal Timing")
@export_range(0.0, 5.0, 0.05) var reveal_duration: float = 0.8
@export_range(0.05, 4.0, 0.05) var fade_speed: float = 0.4

@export_category("Darkness")
@export_range(0.0, 0.1, 0.001) var darkness_visibility: float = 0.012
@export_range(0.0, 1.0, 0.01) var revealed_fill_alpha: float = 0.24
@export var luminous_color: Color = Color(0.28, 0.95, 1.0, 1.0)

var reveal_strength: float = 0.0:
	set(value):
		var next_strength := clampf(value, 0.0, 1.0)
		if is_equal_approx(reveal_strength, next_strength):
			return
		reveal_strength = next_strength
		reveal_changed.emit(reveal_strength)
		queue_redraw()

var _hold_remaining: float = 0.0


func _ready() -> void:
	add_to_group(&"echo_revealable")
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	var remaining_delta := maxf(delta, 0.0)
	if _hold_remaining > 0.0:
		var held_time := minf(_hold_remaining, remaining_delta)
		_hold_remaining -= held_time
		remaining_delta -= held_time

	if remaining_delta > 0.0:
		reveal_strength = move_toward(reveal_strength, 0.0, fade_speed * remaining_delta)

	if reveal_strength <= 0.0001 and _hold_remaining <= 0.0:
		reveal_strength = 0.0
		set_process(false)


func receive_reveal(strength: float = 1.0, duration_override: float = -1.0) -> void:
	var incoming_strength := clampf(strength, 0.0, 1.0)
	if incoming_strength <= 0.0:
		return
	reveal_strength = maxf(reveal_strength, incoming_strength)
	_hold_remaining = maxf(
		_hold_remaining,
		reveal_duration if duration_override < 0.0 else duration_override,
	)
	set_process(true)


func clear_reveal() -> void:
	_hold_remaining = 0.0
	reveal_strength = 0.0
	set_process(false)


func get_reveal_strength() -> float:
	return reveal_strength


func get_fill_color(base_color: Color) -> Color:
	var result := base_color
	result.a *= lerpf(darkness_visibility * 0.5, revealed_fill_alpha, reveal_strength)
	return result


func get_outline_color(alpha_scale: float = 1.0) -> Color:
	var result := luminous_color
	var visible_strength := pow(reveal_strength, 0.7)
	result.a *= lerpf(darkness_visibility, 1.0, visible_strength) * alpha_scale
	return result


func get_outline_width() -> float:
	return lerpf(1.0, 3.0, reveal_strength)
