class_name PowerRestorationOverlay
extends Control

@onready var message_label: Label = %MessageLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	modulate.a = 0.0


func play_sequence() -> void:
	visible = true
	message_label.text = "GRID ONLINE // EXTRACTION OPEN"
	var accessibility := get_node_or_null("/root/AccessibilityManager")
	var peak_alpha := 0.36
	if accessibility != null:
		peak_alpha *= float(accessibility.call(&"get_flash_multiplier"))
	var tween := create_tween()
	tween.tween_property(self, ^"modulate:a", peak_alpha, 0.24)
	tween.tween_interval(0.78)
	tween.tween_property(self, ^"modulate:a", 0.0, 0.42)
	await tween.finished
	visible = false
