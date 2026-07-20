class_name ListenerVisual
extends EchoRevealable

const BODY_PARTS: Array[StringName] = [
	&"head",
	&"torso",
	&"left_arm",
	&"right_arm",
	&"left_leg",
	&"right_leg",
	&"hearing_spines",
]

@export var silhouette_size: Vector2 = Vector2(38.0, 58.0)
@export var idle_color: Color = Color(0.86, 0.25, 0.12, 1.0)
@export var alert_color: Color = Color(1.0, 0.48, 0.12, 1.0)
@export var chase_color: Color = Color(1.0, 0.14, 0.08, 1.0)

@export_category("Procedural Animation")
@export_range(2.0, 18.0, 0.1) var gait_cycle_speed: float = 7.2
@export_range(0.0, 8.0, 0.1) var stride_amount: float = 4.8
@export_range(0.0, 5.0, 0.1) var limb_swing_amount: float = 3.2
@export_range(0.0, 3.0, 0.1) var movement_bob_amount: float = 1.2
@export_range(0.0, 0.12, 0.005) var breathing_amount: float = 0.045
@export_range(0.1, 0.8, 0.05) var attack_lunge_duration: float = 0.28

var state_name: StringName = &"IDLE"
var alert_level: int = 0

var _movement_strength: float = 0.0
var _animation_time: float = 0.0
var _gait_phase: float = 0.0
var _attack_remaining: float = 0.0
var _torso_polygon := PackedVector2Array()
var _torso_outline := PackedVector2Array()


func _ready() -> void:
	super._ready()
	_torso_polygon.resize(8)
	_torso_outline.resize(9)


func advance_animation(delta: float) -> void:
	var safe_delta := maxf(delta, 0.0)
	_animation_time += safe_delta
	if _movement_strength > 0.02:
		var alert_speed := 1.28 if alert_level >= 3 else (1.12 if alert_level > 0 else 1.0)
		_gait_phase = fposmod(
			_gait_phase + safe_delta * gait_cycle_speed * alert_speed * lerpf(0.55, 1.0, _movement_strength),
			TAU,
		)
	_attack_remaining = maxf(_attack_remaining - safe_delta, 0.0)
	if get_effective_visibility_strength() > 0.001:
		queue_redraw()


func set_state(next_state_name: StringName, next_alert_level: int) -> void:
	state_name = next_state_name
	alert_level = clampi(next_alert_level, 0, 3)
	match alert_level:
		0:
			luminous_color = idle_color
		1, 2:
			luminous_color = alert_color
		3:
			luminous_color = chase_color
	queue_redraw()


func set_movement_state(current_velocity: Vector2, maximum_speed: float) -> void:
	var safe_maximum := maxf(maximum_speed, 0.001)
	_movement_strength = clampf(current_velocity.length() / safe_maximum, 0.0, 1.0)
	queue_redraw()


func trigger_attack_lunge() -> void:
	# Capture freezes AI immediately, so start at the visual peak of the lunge.
	_attack_remaining = attack_lunge_duration * 0.5
	queue_redraw()


func get_body_part_names() -> Array[StringName]:
	return BODY_PARTS.duplicate()


func get_motion_state_name() -> StringName:
	if _attack_remaining > 0.0:
		return &"attack"
	return &"moving" if _movement_strength > 0.02 else &"idle"


func get_movement_strength() -> float:
	return _movement_strength


func get_gait_phase() -> float:
	return _gait_phase


func get_animation_time() -> float:
	return _animation_time


func get_idle_breathing_offset() -> float:
	if _movement_strength > 0.02:
		return 0.0
	return sin(_animation_time * 2.25) * breathing_amount


func _draw() -> void:
	var half_width := silhouette_size.x * 0.5
	var half_height := silhouette_size.y * 0.5
	var gait_wave := sin(_gait_phase) * _movement_strength
	var stride := gait_wave * stride_amount
	var limb_swing := -gait_wave * limb_swing_amount
	var movement_bob := absf(sin(_gait_phase * 2.0)) * movement_bob_amount * _movement_strength
	var breathing := get_idle_breathing_offset()
	var attack_strength := (
		clampf(_attack_remaining / attack_lunge_duration, 0.0, 1.0)
		if attack_lunge_duration > 0.0
		else 0.0
	)
	var body_shift := Vector2(0.0, -movement_bob - sin(attack_strength * PI) * 7.0)

	_draw_ground_shadow(half_width, movement_bob)
	_draw_legs(half_width, half_height, stride, body_shift)
	_draw_arms(half_width, limb_swing, attack_strength, body_shift)
	_draw_torso(half_width, half_height, breathing, body_shift)
	_draw_head(half_width, half_height, body_shift)
	_draw_state_indicator(half_width, half_height, body_shift)


func _draw_ground_shadow(half_width: float, movement_bob: float) -> void:
	var alpha := lerpf(0.2, 0.13, clampf(movement_bob, 0.0, 1.0))
	draw_set_transform(Vector2(0.0, 7.0), 0.0, Vector2(1.0, 0.48))
	draw_circle(Vector2.ZERO, half_width + 4.0, Color(0.0, 0.004, 0.008, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_legs(
	half_width: float,
	half_height: float,
	stride: float,
	body_shift: Vector2,
) -> void:
	var limb_color := get_fill_color(Color(0.34, 0.045, 0.025, 1.0))
	var left_hip := body_shift + Vector2(-half_width * 0.36, half_height * 0.24)
	var right_hip := body_shift + Vector2(half_width * 0.36, half_height * 0.24)
	var left_foot := Vector2(-half_width * 0.48, half_height * 0.92 + stride)
	var right_foot := Vector2(half_width * 0.48, half_height * 0.92 - stride)
	_draw_limb(left_hip, left_foot, limb_color, 6.0)
	_draw_limb(right_hip, right_foot, limb_color, 6.0)
	draw_line(left_foot + Vector2(-4.0, 1.0), left_foot + Vector2(4.0, -2.0), get_outline_color(), 2.0, true)
	draw_line(right_foot + Vector2(-4.0, -2.0), right_foot + Vector2(4.0, 1.0), get_outline_color(), 2.0, true)


func _draw_arms(
	half_width: float,
	limb_swing: float,
	attack_strength: float,
	body_shift: Vector2,
) -> void:
	var limb_color := get_fill_color(Color(0.38, 0.05, 0.025, 1.0))
	var reach := sin(attack_strength * PI) * 8.0
	var left_shoulder := body_shift + Vector2(-half_width * 0.58, -5.0)
	var right_shoulder := body_shift + Vector2(half_width * 0.58, -5.0)
	var left_claw := body_shift + Vector2(-half_width - 4.0 - reach, 7.0 + limb_swing)
	var right_claw := body_shift + Vector2(half_width + 4.0 + reach, 7.0 - limb_swing)
	_draw_limb(left_shoulder, left_claw, limb_color, 5.0)
	_draw_limb(right_shoulder, right_claw, limb_color, 5.0)
	for side: float in [-1.0, 1.0]:
		var claw := left_claw if side < 0.0 else right_claw
		draw_line(claw, claw + Vector2(side * 5.0, -4.0), get_outline_color(), 1.8, true)
		draw_line(claw, claw + Vector2(side * 5.5, 3.0), get_outline_color(), 1.8, true)


func _draw_torso(
	half_width: float,
	half_height: float,
	breathing: float,
	body_shift: Vector2,
) -> void:
	var breathing_scale := 1.0 + breathing
	_torso_polygon[0] = body_shift + Vector2(-half_width * 0.34, -half_height * 0.58)
	_torso_polygon[1] = body_shift + Vector2(half_width * 0.34, -half_height * 0.58)
	_torso_polygon[2] = body_shift + Vector2(half_width * 0.7 * breathing_scale, -half_height * 0.14)
	_torso_polygon[3] = body_shift + Vector2(half_width * 0.48, half_height * 0.42)
	_torso_polygon[4] = body_shift + Vector2(half_width * 0.2, half_height * 0.66)
	_torso_polygon[5] = body_shift + Vector2(-half_width * 0.2, half_height * 0.66)
	_torso_polygon[6] = body_shift + Vector2(-half_width * 0.48, half_height * 0.42)
	_torso_polygon[7] = body_shift + Vector2(-half_width * 0.7 * breathing_scale, -half_height * 0.14)
	for index in range(_torso_polygon.size()):
		_torso_outline[index] = _torso_polygon[index]
	_torso_outline[-1] = _torso_polygon[0]
	draw_colored_polygon(_torso_polygon, get_fill_color(Color(0.45, 0.07, 0.032, 1.0)))
	draw_polyline(_torso_outline, get_outline_color(0.15), 8.0, true)
	draw_polyline(_torso_outline, get_outline_color(), get_outline_width(), true)
	draw_line(
		body_shift + Vector2(-half_width * 0.36, -2.0),
		body_shift + Vector2(half_width * 0.36, 5.0),
		get_outline_color(0.72),
		get_outline_width(),
		true,
	)


func _draw_head(half_width: float, half_height: float, body_shift: Vector2) -> void:
	var head_center := body_shift + Vector2(0.0, -half_height * 0.68)
	var head_radius := maxf(half_width * 0.42, 6.0)
	draw_circle(head_center, head_radius + 2.5, get_outline_color(0.22))
	draw_circle(head_center, head_radius, get_fill_color(Color(0.5, 0.075, 0.035, 1.0)))
	draw_arc(head_center, head_radius, 0.0, TAU, 24, get_outline_color(), get_outline_width())
	var eye_color := get_outline_color(0.95)
	draw_circle(head_center + Vector2(-3.2, -1.0), 1.8, eye_color)
	draw_circle(head_center + Vector2(3.2, -1.0), 1.8, eye_color)
	# Paired hearing spines make the sound-sensitive silhouette readable without color.
	for side: float in [-1.0, 1.0]:
		var root := head_center + Vector2(side * head_radius * 0.68, -head_radius * 0.55)
		draw_line(root, root + Vector2(side * 7.0, -8.0), get_outline_color(0.84), 3.0, true)
		draw_line(root + Vector2(side * 2.0, -1.0), root + Vector2(side * 10.0, -2.0), get_outline_color(0.52), 2.0, true)


func _draw_limb(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	draw_line(from, to, get_outline_color(0.18), width + 4.0, true)
	draw_line(from, to, color, width, true)
	draw_circle(from, width * 0.48, color)
	draw_circle(to, width * 0.42, color)


func _draw_state_indicator(
	half_width: float,
	half_height: float,
	body_shift: Vector2,
) -> void:
	var pulse := 0.78 + sin(_animation_time * (8.0 if alert_level >= 3 else 5.0)) * 0.16
	match alert_level:
		1:
			for radius: float in [half_width + 7.0, half_width + 13.0]:
				draw_arc(body_shift, radius, -2.4, -0.74, 18, get_outline_color(pulse), 2.0)
		2:
			var search_radius := half_width + 12.0
			for direction: Vector2 in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
				draw_circle(body_shift + direction * search_radius, 2.5, get_outline_color(pulse))
		3:
			for side: float in [-1.0, 1.0]:
				draw_line(
					body_shift + Vector2(side * (half_width + 16.0), -half_height * 0.56),
					body_shift + Vector2(side * (half_width + 5.0), 0.0),
					get_outline_color(pulse),
					3.0,
					true,
				)
				draw_line(
					body_shift + Vector2(side * (half_width + 5.0), 0.0),
					body_shift + Vector2(side * (half_width + 16.0), half_height * 0.56),
					get_outline_color(pulse),
					3.0,
					true,
				)
