extends Node

signal boot_completed
signal new_game_requested
signal pause_requested
signal resume_requested
signal main_menu_requested
signal restart_requested
signal game_over_requested
signal victory_requested
signal app_state_changed(previous_state: StringName, current_state: StringName)
signal round_state_changed(previous_state: StringName, current_state: StringName)
signal round_started(round_id: int)
signal noise_emitted(noise_event: NoiseEvent)


func publish_noise(
	position: Vector2,
	loudness: float,
	category: StringName,
) -> NoiseEvent:
	var noise_event := NoiseEvent.new(position, loudness, category)
	noise_emitted.emit(noise_event)
	return noise_event
