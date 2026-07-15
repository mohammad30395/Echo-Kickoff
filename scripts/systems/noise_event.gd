class_name NoiseEvent
extends RefCounted

const CATEGORY_ECHO_PULSE: StringName = &"echo_pulse"
const CATEGORY_FOOTSTEP: StringName = &"footstep"
const CATEGORY_SOUND_DECOY: StringName = &"sound_decoy"
const CATEGORY_REACTOR_RELAY: StringName = &"reactor_relay"

var position: Vector2
var loudness: float
var category: StringName
var timestamp: float


func _init(
	event_position: Vector2 = Vector2.ZERO,
	event_loudness: float = 0.0,
	event_category: StringName = &"unknown",
	event_timestamp: float = -1.0,
) -> void:
	position = event_position
	loudness = maxf(event_loudness, 0.0)
	category = event_category
	timestamp = (
		Time.get_ticks_msec() / 1000.0
		if event_timestamp < 0.0
		else event_timestamp
	)


func reaches(point: Vector2) -> bool:
	return position.distance_squared_to(point) <= loudness * loudness


func strength_at(point: Vector2) -> float:
	if loudness <= 0.0:
		return 0.0
	return clampf(1.0 - position.distance_to(point) / loudness, 0.0, 1.0)
