class_name DecoyHud
extends Control

@onready var count_label: Label = %CountLabel

var controller: PlayerDecoyController
var remaining_charges: int = 0
var maximum_charges: int = 2


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func bind(decoy_controller: PlayerDecoyController) -> void:
	if controller != null and controller.charges_changed.is_connected(_on_charges_changed):
		controller.charges_changed.disconnect(_on_charges_changed)
	controller = decoy_controller
	if controller == null:
		remaining_charges = 0
		_refresh()
		return
	controller.charges_changed.connect(_on_charges_changed)
	remaining_charges = controller.remaining_charges
	maximum_charges = controller.maximum_charges
	_refresh()


func _on_charges_changed(remaining: int, maximum: int) -> void:
	remaining_charges = remaining
	maximum_charges = maximum
	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	count_label.text = "CHARGES %d/%d" % [remaining_charges, maximum_charges]
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.008, 0.025, 0.04, 0.9), true)
	for index in range(maximum_charges):
		var center := Vector2(24.0 + index * 30.0, 52.0)
		var color := Color(0.94, 0.72, 0.24, 1.0) if index < remaining_charges else Color(0.38, 0.33, 0.24, 0.65)
		var diamond := PackedVector2Array([
			center + Vector2(0.0, -8.0),
			center + Vector2(8.0, 0.0),
			center + Vector2(0.0, 8.0),
			center + Vector2(-8.0, 0.0),
		])
		if index < remaining_charges:
			draw_colored_polygon(diamond, Color(color, 0.4))
		draw_polyline(diamond + PackedVector2Array([diamond[0]]), color, 2.0)
