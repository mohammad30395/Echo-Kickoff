extends Control

@onready var diagnostics_label: Label = %DiagnosticsLabel


func _ready() -> void:
	_refresh_diagnostics()
	get_viewport().size_changed.connect(_refresh_diagnostics)
	print(_diagnostic_log_line())
	await get_tree().process_frame
	if is_inside_tree() and get_tree().current_scene == self:
		EventBus.boot_completed.emit()


func _refresh_diagnostics() -> void:
	var viewport_size := get_viewport_rect().size
	diagnostics_label.text = "Renderer: %s\nViewport: %d × %d\nPlatform: %s" % [
		RenderingServer.get_current_rendering_method(),
		int(viewport_size.x),
		int(viewport_size.y),
		OS.get_name(),
	]

func _diagnostic_log_line() -> String:
	var viewport_size := get_viewport_rect().size
	return "ECHO_KICKOFF_BOOT_OK | renderer=%s | viewport=%dx%d | platform=%s" % [
		RenderingServer.get_current_rendering_method(),
		int(viewport_size.x),
		int(viewport_size.y),
		OS.get_name(),
	]
