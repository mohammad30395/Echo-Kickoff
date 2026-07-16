class_name PlayerLocalAwareness
extends Node2D

@export_category("Awareness Zone")
@export_range(96.0, 220.0, 4.0) var visibility_radius: float = 148.0:
	set(value):
		visibility_radius = maxf(value, 1.0)
		inner_radius = minf(inner_radius, visibility_radius)
		queue_redraw()
@export_range(24.0, 96.0, 4.0) var inner_radius: float = 52.0:
	set(value):
		inner_radius = clampf(value, 1.0, visibility_radius)
		queue_redraw()
@export var awareness_color: Color = Color(0.15, 0.68, 0.78, 1.0)
@export_range(0.0, 0.12, 0.005) var floor_tint_alpha: float = 0.025
@export_range(0.0, 0.3, 0.01) var horizon_alpha: float = 0.11

var _accessibility_manager: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_accessibility_manager = get_node_or_null("/root/AccessibilityManager")
	if _accessibility_manager != null:
		_accessibility_manager.connect(&"settings_changed", _on_accessibility_changed)
	queue_redraw()


func _exit_tree() -> void:
	if (
		_accessibility_manager != null
		and _accessibility_manager.is_connected(&"settings_changed", _on_accessibility_changed)
	):
		_accessibility_manager.disconnect(&"settings_changed", _on_accessibility_changed)


func configure(radius: float, full_strength_radius: float) -> void:
	visibility_radius = radius
	inner_radius = full_strength_radius


func get_center_tint_alpha() -> float:
	return floor_tint_alpha * 4.0


func _draw() -> void:
	var visible_color := awareness_color
	if _accessibility_manager != null:
		visible_color = _accessibility_manager.call(&"get_echo_color", awareness_color) as Color

	# Four overlapping bounded discs approximate a soft floor-light falloff without
	# a viewport texture or per-pixel shader. The draw is static while the node
	# follows its Player parent through the normal CanvasItem transform.
	for step in range(4):
		var ratio := float(step) / 3.0
		var radius := lerpf(visibility_radius, inner_radius, ratio)
		var tint := visible_color
		tint.a = floor_tint_alpha
		draw_circle(Vector2.ZERO, radius, tint)

	var horizon := visible_color
	for segment in range(8):
		var start_angle := float(segment) * TAU / 8.0 + 0.08
		horizon.a = horizon_alpha * (0.78 if segment % 2 == 0 else 0.52)
		draw_arc(
			Vector2.ZERO,
			visibility_radius,
			start_angle,
			start_angle + 0.22,
			5,
			horizon,
			1.25,
		)

	var inner_trace := visible_color
	inner_trace.a = horizon_alpha * 0.34
	draw_arc(Vector2.ZERO, inner_radius, 0.0, TAU, 32, inner_trace, 1.0)


func _on_accessibility_changed(
	_high_contrast_enabled: bool,
	_reduced_flash_enabled: bool,
	_screen_shake_enabled: bool,
) -> void:
	queue_redraw()
