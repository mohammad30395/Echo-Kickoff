extends Node

var master_volume_linear: float = 1.0
var is_muted: bool = false


func set_master_volume(value: float) -> void:
	master_volume_linear = clampf(value, 0.0, 1.0)
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		var volume_db := linear_to_db(master_volume_linear) if master_volume_linear > 0.0 else -80.0
		AudioServer.set_bus_volume_db(master_bus, volume_db)


func set_muted(muted: bool) -> void:
	is_muted = muted
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_mute(master_bus, is_muted)
