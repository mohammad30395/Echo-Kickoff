class_name HudFrame
extends Control

enum FrameStyle { STANDARD, BLACKOUT_CORE }

@export var accent_color: Color = Color(0.32, 0.86, 0.94, 0.9)
@export var panel_color: Color = Color(0.006, 0.022, 0.036, 0.94)
@export_range(4.0, 24.0, 1.0) var corner_length: float = 12.0
@export_range(0.0, 1.0, 0.01) var accent_strength: float = 1.0
@export var use_warning_palette: bool = false
@export var frame_style: FrameStyle = FrameStyle.STANDARD

var _accessibility_manager: Node


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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


func set_accent_color(color: Color) -> void:
	accent_color = color
	queue_redraw()


func set_warning_palette(enabled: bool) -> void:
	use_warning_palette = enabled
	queue_redraw()


func set_frame_style(style: FrameStyle) -> void:
	frame_style = style
	queue_redraw()


func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var visible_panel := panel_color
	var visible_accent := accent_color
	if _accessibility_manager != null:
		visible_panel = _accessibility_manager.call(&"get_panel_color", panel_color) as Color
		visible_accent = (
			_accessibility_manager.call(&"get_warning_color", accent_color) as Color
			if use_warning_palette
			else _accessibility_manager.call(&"get_echo_color", accent_color) as Color
		)
	visible_accent.a *= accent_strength
	if frame_style == FrameStyle.BLACKOUT_CORE:
		_draw_blackout_frame(visible_panel, visible_accent)
		return
	draw_rect(Rect2(Vector2.ZERO, size), visible_panel, true)
	var border := visible_accent
	border.a *= 0.34
	draw_rect(Rect2(Vector2(0.5, 0.5), size - Vector2.ONE), border, false, 1.0)
	var top_line := visible_accent
	top_line.a *= 0.72
	draw_line(Vector2(12.0, 1.5), Vector2(size.x - 12.0, 1.5), top_line, 1.5)
	var scan_line := visible_accent
	scan_line.a *= 0.08
	draw_line(Vector2(8.0, size.y - 9.0), Vector2(size.x - 8.0, size.y - 9.0), scan_line, 1.0)
	_draw_corner(Vector2(1.5, 1.5), Vector2.RIGHT, Vector2.DOWN, visible_accent)
	_draw_corner(Vector2(size.x - 1.5, 1.5), Vector2.LEFT, Vector2.DOWN, visible_accent)
	_draw_corner(Vector2(1.5, size.y - 1.5), Vector2.RIGHT, Vector2.UP, visible_accent)
	_draw_corner(Vector2(size.x - 1.5, size.y - 1.5), Vector2.LEFT, Vector2.UP, visible_accent)


func _draw_blackout_frame(visible_panel: Color, visible_accent: Color) -> void:
	var cut := minf(14.0, minf(size.x, size.y) * 0.18)
	var shape := PackedVector2Array([
		Vector2(cut, 0.5), Vector2(size.x - cut, 0.5),
		Vector2(size.x - 0.5, cut), Vector2(size.x - 0.5, size.y - cut),
		Vector2(size.x - cut, size.y - 0.5), Vector2(cut, size.y - 0.5),
		Vector2(0.5, size.y - cut), Vector2(0.5, cut),
	])
	draw_colored_polygon(shape, visible_panel)
	var outline := shape.duplicate()
	outline.append(shape[0])
	draw_polyline(outline, Color(visible_accent, visible_accent.a * 0.58), 2.0, true)
	var rail := Color(visible_accent, visible_accent.a * 0.8)
	draw_line(Vector2(cut + 10.0, 3.5), Vector2(size.x * 0.42, 3.5), rail, 2.0)
	draw_line(Vector2(size.x * 0.58, 3.5), Vector2(size.x - cut - 10.0, 3.5), rail, 2.0)
	var warning := Color(1.0, 0.3, 0.14, 0.66)
	for side: float in [-1.0, 1.0]:
		var x := 7.0 if side < 0.0 else size.x - 7.0
		var direction := 1.0 if side < 0.0 else -1.0
		draw_line(Vector2(x, size.y * 0.34), Vector2(x + direction * 8.0, size.y * 0.42), warning, 2.0)
		draw_line(Vector2(x + direction * 8.0, size.y * 0.42), Vector2(x, size.y * 0.5), warning, 2.0)
	var scan_line := Color(visible_accent, visible_accent.a * 0.13)
	draw_line(Vector2(cut, size.y - 9.0), Vector2(size.x - cut, size.y - 9.0), scan_line, 1.0)


func _draw_corner(origin: Vector2, horizontal: Vector2, vertical: Vector2, color: Color) -> void:
	var corner := color
	corner.a *= 0.82
	draw_line(origin, origin + horizontal * corner_length, corner, 2.0)
	draw_line(origin, origin + vertical * corner_length, corner, 2.0)


func _on_accessibility_changed(
	_high_contrast_enabled: bool,
	_reduced_flash_enabled: bool,
	_screen_shake_enabled: bool,
) -> void:
	queue_redraw()
