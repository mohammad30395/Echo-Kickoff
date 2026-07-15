class_name RoundTransitionVisual
extends Control

enum VisualMode {
	NONE,
	FADE,
	PLAYER_CAUGHT,
}

@onready var status_label: Label = %StatusLabel

var visual_mode: VisualMode = VisualMode.NONE
var fade_alpha: float = 0.0
var death_progress: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clear()


func begin_fade(alpha: float) -> void:
	visual_mode = VisualMode.FADE
	death_progress = 0.0
	status_label.visible = false
	set_fade_alpha(alpha)


func set_fade_alpha(alpha: float) -> void:
	fade_alpha = clampf(alpha, 0.0, 1.0)
	visible = fade_alpha > 0.001
	mouse_filter = Control.MOUSE_FILTER_STOP if visible else Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func begin_death_feedback() -> void:
	visual_mode = VisualMode.PLAYER_CAUGHT
	fade_alpha = 0.0
	death_progress = 0.0
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	status_label.visible = true
	status_label.modulate.a = 0.0
	queue_redraw()


func set_death_progress(progress: float) -> void:
	death_progress = clampf(progress, 0.0, 1.0)
	status_label.modulate.a = clampf(death_progress * 2.4, 0.0, 1.0)
	queue_redraw()


func clear() -> void:
	visual_mode = VisualMode.NONE
	fade_alpha = 0.0
	death_progress = 0.0
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_node_ready():
		status_label.visible = false
	queue_redraw()


func get_mode_name() -> StringName:
	return VisualMode.keys()[visual_mode].to_lower()


func _draw() -> void:
	match visual_mode:
		VisualMode.FADE:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.002, 0.006, 0.012, fade_alpha), true)
		VisualMode.PLAYER_CAUGHT:
			_draw_player_caught()


func _draw_player_caught() -> void:
	var accessibility := get_node_or_null("/root/AccessibilityManager")
	var flash_multiplier := 1.0
	var cut_color := Color(1.0, 0.25, 0.28, 0.82)
	if accessibility != null:
		flash_multiplier = float(accessibility.call(&"get_flash_multiplier"))
		cut_color = accessibility.call(&"get_warning_color", cut_color) as Color
	var center := size * 0.5
	var flash := (0.18 + death_progress * 0.32) * flash_multiplier
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.005, 0.015, flash), true)
	for index in range(3):
		var ring_progress := fposmod(death_progress + float(index) * 0.24, 1.0)
		var radius := lerpf(36.0, maxf(size.x, size.y) * 0.58, ring_progress)
		var ring_color := cut_color
		ring_color.a = (1.0 - ring_progress) * 0.58 * flash_multiplier
		draw_arc(center, radius, 0.0, TAU, 80, ring_color, 3.0)
	var cut_half_width := minf(size.x * 0.28, 330.0)
	var spread := lerpf(8.0, 44.0, death_progress)
	draw_line(center + Vector2(-cut_half_width, -spread), center + Vector2(cut_half_width, spread), cut_color, 4.0)
	draw_line(center + Vector2(-cut_half_width, spread), center + Vector2(cut_half_width, -spread), cut_color, 2.0)
	for band_index in range(5):
		var band_y := center.y - 120.0 + float(band_index) * 54.0
		var band_alpha := 0.08 + 0.08 * float((band_index + int(death_progress * 12.0)) % 2)
		draw_rect(Rect2(0.0, band_y, size.x, 3.0), Color(1.0, 0.1, 0.16, band_alpha), true)
