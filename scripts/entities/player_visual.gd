class_name PlayerVisual
extends Node2D

const EFFECTIVE_DIMENSIONS := Vector2(60.0, 54.0)
const SCANNER_LOCAL_POSITION := Vector2(24.0, 12.0)
const BODY_PARTS: Array[StringName] = [
	&"helmet",
	&"torso",
	&"left_arm",
	&"right_arm",
	&"left_leg",
	&"right_leg",
	&"rescue_pack",
	&"echo_scanner",
]

@export_category("Rescue Operative Palette")
@export var suit_color: Color = Color(0.7, 0.82, 0.84, 1.0)
@export var suit_highlight_color: Color = Color(0.88, 0.95, 0.95, 1.0)
@export var protective_color: Color = Color(0.055, 0.15, 0.22, 1.0)
@export var protective_mid_color: Color = Color(0.11, 0.28, 0.36, 1.0)
@export var human_outline_color: Color = Color(0.008, 0.035, 0.055, 1.0)
@export var visor_color: Color = Color(0.055, 0.32, 0.42, 1.0)
@export var scanner_color: Color = Color(0.28, 0.94, 1.0, 1.0)
@export var safety_color: Color = Color(1.0, 0.42, 0.12, 1.0)
@export var threat_color: Color = Color(1.0, 0.25, 0.12, 1.0)
@export var captured_color: Color = Color(0.92, 0.16, 0.18, 1.0)

# Retain the original visibility-system contract while the rendered character
# now uses the more specific rescue-operative palette.
var core_color: Color:
	get:
		return suit_highlight_color
	set(value):
		suit_highlight_color = value

@export_category("Procedural Animation")
@export_range(2.0, 16.0, 0.1) var walk_cycle_speed: float = 8.4
@export_range(0.0, 6.0, 0.1) var leg_stride: float = 4.2
@export_range(0.0, 4.0, 0.1) var arm_swing_amount: float = 2.4
@export_range(0.0, 3.0, 0.1) var walk_bob_amount: float = 1.0
@export_range(0.0, 0.08, 0.005) var breathing_amount: float = 0.025
@export_range(0.1, 1.0, 0.05) var scanner_flash_duration: float = 0.32

var facing_direction: Vector2 = Vector2.RIGHT

var _movement_strength: float = 0.0
var _animation_time: float = 0.0
var _walk_phase: float = 0.0
var _pulse_readiness: float = 1.0
var _scanner_flash_remaining: float = 0.0
var _threat_nearby: bool = false
var _captured: bool = false
var _animation_frozen: bool = false
var _capture_progress: float = 0.0
var _pulse_controller: PlayerPulseController
var _event_bus: Node
var _torso_polygon := PackedVector2Array()
var _torso_outline := PackedVector2Array()
var _visor_polygon := PackedVector2Array()
var _visor_outline := PackedVector2Array()
var _scanner_polygon := PackedVector2Array()
var _scanner_outline := PackedVector2Array()

@onready var scanner_origin: Marker2D = %ScannerOrigin


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_initialize_geometry_buffers()
	_event_bus = get_node_or_null("/root/EventBus")
	if _event_bus != null:
		_event_bus.connect(&"round_state_changed", _on_round_state_changed)
	set_process(true)
	queue_redraw()


func _exit_tree() -> void:
	_unbind_pulse_controller()
	if (
		_event_bus != null
		and _event_bus.is_connected(&"round_state_changed", _on_round_state_changed)
	):
		_event_bus.disconnect(&"round_state_changed", _on_round_state_changed)


func _process(delta: float) -> void:
	if _animation_frozen:
		return
	var safe_delta := maxf(delta, 0.0)
	_animation_time += safe_delta
	if _movement_strength > 0.02 and not _captured:
		_walk_phase = fposmod(
			_walk_phase + safe_delta * walk_cycle_speed * lerpf(0.55, 1.0, _movement_strength),
			TAU,
		)
	if _scanner_flash_remaining > 0.0:
		_scanner_flash_remaining = maxf(_scanner_flash_remaining - safe_delta, 0.0)
	if _captured:
		_capture_progress = minf(_capture_progress + safe_delta * 3.5, 1.0)
	queue_redraw()


func bind_pulse_controller(controller: PlayerPulseController) -> void:
	if _pulse_controller == controller:
		return
	_unbind_pulse_controller()
	_pulse_controller = controller
	if _pulse_controller == null:
		return
	_pulse_controller.cooldown_changed.connect(_on_pulse_cooldown_changed)
	_pulse_controller.pulse_started.connect(_on_pulse_started)
	set_pulse_readiness(_pulse_controller.get_cooldown_readiness())


func _unbind_pulse_controller() -> void:
	if not is_instance_valid(_pulse_controller):
		_pulse_controller = null
		return
	if _pulse_controller.cooldown_changed.is_connected(_on_pulse_cooldown_changed):
		_pulse_controller.cooldown_changed.disconnect(_on_pulse_cooldown_changed)
	if _pulse_controller.pulse_started.is_connected(_on_pulse_started):
		_pulse_controller.pulse_started.disconnect(_on_pulse_started)
	_pulse_controller = null


func set_facing_direction(direction: Vector2) -> void:
	if direction.length_squared() <= 0.0001:
		return
	facing_direction = direction.normalized()
	rotation = facing_direction.angle()
	queue_redraw()


func set_movement_state(current_velocity: Vector2, maximum_speed: float) -> void:
	var safe_maximum := maxf(maximum_speed, 0.001)
	_movement_strength = clampf(current_velocity.length() / safe_maximum, 0.0, 1.0)
	queue_redraw()


func set_pulse_readiness(readiness: float) -> void:
	_pulse_readiness = clampf(readiness, 0.0, 1.0)
	queue_redraw()


func trigger_scanner_flash() -> void:
	_scanner_flash_remaining = scanner_flash_duration
	queue_redraw()


func set_threat_nearby(active: bool) -> void:
	if _threat_nearby == active:
		return
	_threat_nearby = active
	queue_redraw()


func set_captured(active: bool) -> void:
	if _captured == active:
		return
	_captured = active
	_capture_progress = 0.0
	if _captured:
		_movement_strength = 0.0
	queue_redraw()


func get_effective_dimensions() -> Vector2:
	return EFFECTIVE_DIMENSIONS


func get_body_part_names() -> Array[StringName]:
	return BODY_PARTS.duplicate()


func get_scanner_global_position() -> Vector2:
	if is_instance_valid(scanner_origin):
		return scanner_origin.global_position
	return to_global(SCANNER_LOCAL_POSITION)


func get_motion_state_name() -> StringName:
	if _captured:
		return &"captured"
	return &"moving" if _movement_strength > 0.02 else &"idle"


func get_scanner_state_name() -> StringName:
	if _captured:
		return &"disabled"
	if _scanner_flash_remaining > 0.0:
		return &"pulse_flash"
	return &"ready" if _pulse_readiness >= 0.999 else &"cooldown"


func get_facing_octant() -> StringName:
	var octant := wrapi(int(round(facing_direction.angle() / (PI / 4.0))), -4, 4)
	match octant:
		-4, 4:
			return &"left"
		-3:
			return &"up_left"
		-2:
			return &"up"
		-1:
			return &"up_right"
		0:
			return &"right"
		1:
			return &"down_right"
		2:
			return &"down"
		3:
			return &"down_left"
	return &"right"


func is_threat_nearby() -> bool:
	return _threat_nearby


func is_captured() -> bool:
	return _captured


func get_scanner_flash_strength() -> float:
	if scanner_flash_duration <= 0.0:
		return 0.0
	return clampf(_scanner_flash_remaining / scanner_flash_duration, 0.0, 1.0)


func get_movement_strength() -> float:
	return _movement_strength


func get_walk_phase() -> float:
	return _walk_phase


func get_animation_time() -> float:
	return _animation_time


func get_idle_breathing_offset() -> float:
	if _movement_strength > 0.02 or _captured:
		return 0.0
	return sin(_animation_time * 2.1) * breathing_amount


func get_pulse_readiness() -> float:
	return _pulse_readiness


func _on_pulse_cooldown_changed(readiness: float, _remaining: float) -> void:
	set_pulse_readiness(readiness)


func _on_pulse_started(_pulse: EchoPulse, _noise_event: NoiseEvent) -> void:
	trigger_scanner_flash()


func _on_round_state_changed(_previous_state: StringName, current_state: StringName) -> void:
	set_captured(current_state == &"player_caught")
	_animation_frozen = current_state in [&"paused", &"victory", &"restarting", &"transitioning"]
	if current_state == &"playing":
		_animation_frozen = false
		if _captured:
			set_captured(false)


func _draw() -> void:
	var walk_wave := sin(_walk_phase) * _movement_strength
	var stride := walk_wave * leg_stride
	var arm_swing := -walk_wave * arm_swing_amount
	var walk_bob := absf(sin(_walk_phase * 2.0)) * walk_bob_amount * _movement_strength
	var breathing := sin(_animation_time * 2.1) * breathing_amount if _movement_strength <= 0.02 else 0.0
	var body_shift := Vector2(walk_bob, 0.0)
	if _captured:
		body_shift = Vector2(-2.5 * _capture_progress, 0.0)

	_draw_ground_shadow(walk_bob)
	_draw_legs(stride, body_shift)
	_draw_rescue_pack(body_shift)
	_draw_arms(arm_swing, body_shift)
	_draw_torso(body_shift, breathing)
	_draw_helmet(body_shift)
	_draw_echo_scanner(body_shift)
	_draw_state_feedback()


func _draw_ground_shadow(walk_bob: float) -> void:
	var shadow_alpha := lerpf(0.28, 0.2, clampf(walk_bob, 0.0, 1.0))
	draw_set_transform(Vector2(-2.0, 3.0), 0.0, Vector2(1.0, 0.62))
	draw_circle(Vector2.ZERO, 24.0, Color(0.0, 0.008, 0.014, shadow_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_legs(stride: float, body_shift: Vector2) -> void:
	var captured_spread := 7.0 * _capture_progress if _captured else 0.0
	var left_hip := body_shift + Vector2(-7.0, -5.0)
	var right_hip := body_shift + Vector2(-7.0, 5.0)
	var left_boot := Vector2(-20.0 + stride, -7.0 - captured_spread)
	var right_boot := Vector2(-20.0 - stride, 7.0 + captured_spread)
	var active_suit := suit_color.lerp(captured_color, 0.32 if _captured else 0.0)
	_draw_limb(left_hip, left_boot, active_suit, 6.0)
	_draw_limb(right_hip, right_boot, active_suit, 6.0)
	_draw_boot(left_boot, -1.0)
	_draw_boot(right_boot, 1.0)


func _draw_boot(position: Vector2, side: float) -> void:
	var heel := position + Vector2(-2.0, side * 0.5)
	draw_line(position + Vector2(3.0, 0.0), heel - Vector2(4.0, 0.0), human_outline_color, 8.0, true)
	draw_line(position + Vector2(3.0, 0.0), heel - Vector2(4.0, 0.0), protective_color, 5.0, true)


func _draw_rescue_pack(body_shift: Vector2) -> void:
	var pack := Rect2(body_shift + Vector2(-15.0, -9.0), Vector2(11.0, 18.0))
	draw_rect(pack.grow(2.0), human_outline_color, true)
	draw_rect(pack, protective_color, true)
	draw_rect(pack.grow(-2.0), protective_mid_color, true)
	draw_line(pack.position + Vector2(3.0, 2.0), pack.position + Vector2(3.0, 16.0), safety_color, 2.0)
	draw_circle(pack.position + Vector2(7.5, 4.0), 1.8, scanner_color)


func _draw_arms(arm_swing: float, body_shift: Vector2) -> void:
	var active_suit := suit_color.lerp(captured_color, 0.34 if _captured else 0.0)
	var splay := 7.0 * _capture_progress if _captured else 0.0
	var free_shoulder := body_shift + Vector2(3.0, -8.0)
	var free_elbow := body_shift + Vector2(2.0 + arm_swing, -14.0 - splay)
	var free_hand := body_shift + Vector2(9.0 + arm_swing, -15.0 - splay)
	_draw_limb(free_shoulder, free_elbow, active_suit, 5.5)
	_draw_limb(free_elbow, free_hand, active_suit, 5.0)

	var scanner_shoulder := body_shift + Vector2(4.0, 8.0)
	var scanner_elbow := body_shift + Vector2(7.0 - arm_swing * 0.4, 14.0 + splay)
	var scanner_hand := body_shift + Vector2(17.0, 12.0 + splay * 0.35)
	_draw_limb(scanner_shoulder, scanner_elbow, active_suit, 5.5)
	_draw_limb(scanner_elbow, scanner_hand, active_suit, 5.0)
	draw_circle(scanner_hand, 3.0, human_outline_color)
	draw_circle(scanner_hand, 1.8, suit_highlight_color)


func _draw_limb(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	draw_line(from, to, human_outline_color, width + 3.0, true)
	draw_line(from, to, color, width, true)
	draw_circle(from, width * 0.48, color)
	draw_circle(to, width * 0.48, color)


func _draw_torso(body_shift: Vector2, breathing: float) -> void:
	var half_width := 9.5 * (1.0 + breathing)
	var active_suit := suit_color.lerp(captured_color, 0.28 if _captured else 0.0)
	_torso_polygon[0] = body_shift + Vector2(-10.0, -half_width * 0.72)
	_torso_polygon[1] = body_shift + Vector2(-6.0, -half_width)
	_torso_polygon[2] = body_shift + Vector2(6.5, -half_width * 0.92)
	_torso_polygon[3] = body_shift + Vector2(9.0, -half_width * 0.56)
	_torso_polygon[4] = body_shift + Vector2(9.0, half_width * 0.56)
	_torso_polygon[5] = body_shift + Vector2(6.5, half_width * 0.92)
	_torso_polygon[6] = body_shift + Vector2(-6.0, half_width)
	_torso_polygon[7] = body_shift + Vector2(-10.0, half_width * 0.72)
	_copy_closed_polygon(_torso_polygon, _torso_outline)
	draw_colored_polygon(_torso_polygon, active_suit)
	draw_polyline(_torso_outline, human_outline_color, 3.0, true)
	var chest_panel := Rect2(body_shift + Vector2(-2.0, -6.5), Vector2(9.0, 13.0))
	draw_rect(chest_panel, protective_color, true)
	draw_line(
		body_shift + Vector2(1.0, -5.0),
		body_shift + Vector2(1.0, 5.0),
		protective_mid_color,
		2.0,
	)
	draw_rect(Rect2(body_shift + Vector2(4.0, -6.0), Vector2(2.5, 4.0)), safety_color, true)


func _draw_helmet(body_shift: Vector2) -> void:
	var helmet_center := body_shift + Vector2(13.0, 0.0)
	var active_suit := suit_highlight_color.lerp(captured_color, 0.3 if _captured else 0.0)
	draw_circle(helmet_center, 9.5, human_outline_color)
	draw_circle(helmet_center, 7.5, active_suit)
	draw_arc(helmet_center, 6.2, -1.9, 1.9, 20, protective_mid_color, 2.0)
	_visor_polygon[0] = body_shift + Vector2(14.5, -5.4)
	_visor_polygon[1] = body_shift + Vector2(20.5, -3.8)
	_visor_polygon[2] = body_shift + Vector2(21.5, 0.0)
	_visor_polygon[3] = body_shift + Vector2(20.5, 3.8)
	_visor_polygon[4] = body_shift + Vector2(14.5, 5.4)
	_copy_closed_polygon(_visor_polygon, _visor_outline)
	draw_colored_polygon(_visor_polygon, visor_color)
	draw_polyline(_visor_outline, scanner_color.darkened(0.22), 1.5, true)
	draw_line(body_shift + Vector2(17.0, -2.6), body_shift + Vector2(19.5, -1.7), Color(0.5, 0.9, 0.94, 0.72), 1.2)


func _draw_echo_scanner(body_shift: Vector2) -> void:
	var scanner_center := body_shift + SCANNER_LOCAL_POSITION
	_scanner_polygon[0] = scanner_center + Vector2(-6.0, -5.0)
	_scanner_polygon[1] = scanner_center + Vector2(5.5, -4.0)
	_scanner_polygon[2] = scanner_center + Vector2(7.0, 0.0)
	_scanner_polygon[3] = scanner_center + Vector2(5.5, 4.0)
	_scanner_polygon[4] = scanner_center + Vector2(-6.0, 5.0)
	_copy_closed_polygon(_scanner_polygon, _scanner_outline)
	draw_colored_polygon(_scanner_polygon, protective_color)
	draw_polyline(_scanner_outline, human_outline_color, 2.5, true)
	var flash_strength := get_scanner_flash_strength()
	var ready_wave := 0.72 + sin(_animation_time * 4.8) * 0.18 if _pulse_readiness >= 0.999 else 0.45
	var equipment_strength := clampf(
		maxf(_pulse_readiness * ready_wave, flash_strength),
		0.18,
		1.0,
	)
	if _captured:
		equipment_strength = 0.08
	var glow := scanner_color
	glow.a = 0.13 + equipment_strength * 0.2
	draw_circle(scanner_center, 8.0 + flash_strength * 5.0, glow)
	var core := scanner_color.lerp(Color.WHITE, flash_strength * 0.75)
	core.a = 0.38 + equipment_strength * 0.62
	draw_circle(scanner_center + Vector2(1.0, 0.0), 3.2, core)
	draw_line(scanner_center + Vector2(-3.0, 0.0), scanner_center + Vector2(5.0, 0.0), core, 1.6)
	if flash_strength > 0.0:
		var ring := core
		ring.a = flash_strength * 0.82
		draw_arc(scanner_center, lerpf(6.0, 15.0, 1.0 - flash_strength), 0.0, TAU, 24, ring, 2.0)


func _draw_state_feedback() -> void:
	if _threat_nearby and not _captured:
		var threat_pulse := 0.62 + sin(_animation_time * 8.0) * 0.25
		var warning := threat_color
		warning.a = threat_pulse
		draw_circle(Vector2(3.0, -10.5), 2.6, warning)
		draw_circle(Vector2(3.0, 10.5), 2.6, warning)
		draw_arc(Vector2.ZERO, 27.0, -0.62, 0.62, 14, warning, 2.0)
	if _captured:
		var distress := captured_color
		distress.a = 0.55 + _capture_progress * 0.4
		draw_arc(Vector2.ZERO, 28.0, -2.8, -1.7, 12, distress, 2.5)
		draw_arc(Vector2.ZERO, 28.0, 0.35, 1.45, 12, distress, 2.5)
		draw_line(Vector2(-11.0, -16.0), Vector2(17.0, 16.0), distress, 3.0, true)


func _initialize_geometry_buffers() -> void:
	_torso_polygon.resize(8)
	_torso_outline.resize(9)
	_visor_polygon.resize(5)
	_visor_outline.resize(6)
	_scanner_polygon.resize(5)
	_scanner_outline.resize(6)


func _copy_closed_polygon(source: PackedVector2Array, target: PackedVector2Array) -> void:
	for index in range(source.size()):
		target[index] = source[index]
	target[source.size()] = source[0]
