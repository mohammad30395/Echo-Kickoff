class_name AudioSettingsPanel
extends PanelContainer

@onready var master_slider: HSlider = %MasterSlider
@onready var effects_slider: HSlider = %EffectsSlider
@onready var ambience_slider: HSlider = %AmbienceSlider
@onready var master_value: Label = %MasterValue
@onready var effects_value: Label = %EffectsValue
@onready var ambience_value: Label = %AmbienceValue

var _is_syncing: bool = false
var _audio_manager: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_audio_manager = get_node_or_null("/root/AudioManager")
	if _audio_manager == null:
		push_error("AudioSettingsPanel requires the AudioManager autoload.")
		return
	master_slider.value_changed.connect(_on_master_changed)
	effects_slider.value_changed.connect(_on_effects_changed)
	ambience_slider.value_changed.connect(_on_ambience_changed)
	_audio_manager.connect(&"volumes_changed", _on_volumes_changed)
	_sync_from_manager()


func _exit_tree() -> void:
	if _audio_manager != null and _audio_manager.is_connected(&"volumes_changed", _on_volumes_changed):
		_audio_manager.disconnect(&"volumes_changed", _on_volumes_changed)


func _on_master_changed(value: float) -> void:
	if not _is_syncing:
		_audio_manager.call(&"set_master_volume", value)


func _on_effects_changed(value: float) -> void:
	if not _is_syncing:
		_audio_manager.call(&"set_effects_volume", value)


func _on_ambience_changed(value: float) -> void:
	if not _is_syncing:
		_audio_manager.call(&"set_ambience_volume", value)


func _on_volumes_changed(_master: float, _effects: float, _ambience: float) -> void:
	_sync_from_manager()


func _sync_from_manager() -> void:
	_is_syncing = true
	var master := float(_audio_manager.get("master_volume_linear"))
	var effects := float(_audio_manager.get("effects_volume_linear"))
	var ambience := float(_audio_manager.get("ambience_volume_linear"))
	master_slider.value = master
	effects_slider.value = effects
	ambience_slider.value = ambience
	master_value.text = "%d%%" % roundi(master * 100.0)
	effects_value.text = "%d%%" % roundi(effects * 100.0)
	ambience_value.text = "%d%%" % roundi(ambience * 100.0)
	_is_syncing = false
