class_name EchoFacility
extends Node2D

signal onboarding_stage_changed(stage: int, message: String)
signal listener_alerted(listener: Listener)
signal tutorial_step_completed(step_id: StringName)

const LEVEL_BOUNDS := Rect2(-3400.0, -1700.0, 6600.0, 3400.0)
const START_POSITION := Vector2(-3150.0, 0.0)
const MOVE_TRIGGER_RADIUS := 48.0
const LOCAL_VISIBILITY_TRIGGER_RADIUS := 132.0
const DANGER_CONFIRMATION_DURATION := 1.35
const TUTORIAL_STAGE_COUNT := 7
const SHAKE_OFFSETS: Array[Vector2] = [
	Vector2(4.0, -2.0),
	Vector2(-3.0, 3.0),
	Vector2(2.0, 2.0),
	Vector2.ZERO,
]

const TUTORIAL_MOVE: StringName = &"move"
const TUTORIAL_LOCAL: StringName = &"local_visibility"
const TUTORIAL_PULSE: StringName = &"pulse"
const TUTORIAL_DANGER: StringName = &"danger"
const TUTORIAL_INTERACT: StringName = &"interact"
const TUTORIAL_DECOY: StringName = &"decoy"
const TUTORIAL_EXTRACTION: StringName = &"extraction"

@onready var orientation_sector: OrientationSector = %OrientationSector
@onready var laboratory_sector: LaboratorySector = %LaboratorySector
@onready var extraction_sector: ExtractionSector = %ExtractionSector
@onready var player: TopDownPlayer = %Player
@onready var mission_controller: MissionObjectiveController = %MissionController
@onready var relay_a: ReactorRelay = %RelayA
@onready var relay_b: ReactorRelay = %RelayB
@onready var relay_c: ReactorRelay = %RelayC
@onready var extraction_terminal: ExtractionTerminal = %ExtractionTerminal
@onready var listener: Listener = %Listener
@onready var listener_south: Listener = %ListenerSouth
@onready var pulse_hud: PulseCooldownHud = %PulseCooldownHud
@onready var objective_hud: ObjectiveHud = %ObjectiveHud
@onready var interaction_prompt_hud: InteractionPromptHud = %InteractionPromptHud
@onready var onboarding_hud: OnboardingHud = %OnboardingHud
@onready var decoy_hud: DecoyHud = %DecoyHud
@onready var threat_status_hud: ThreatStatusHud = %ThreatStatusHud
@onready var movement_aid: MovementAid = %MovementAid

var onboarding_stage: int = 0
var listener_was_alerted: bool = false
var elapsed_run_time: float = 0.0
var current_tutorial_step: StringName = &""
var _tutorial_completed: Dictionary[StringName, bool] = {}
var _shake_tween: Tween
var _pulse_controller: PlayerPulseController
var _decoy_controller: PlayerDecoyController
var _interaction_controller: PlayerInteractionController
var _accessibility_manager: Node
var _listener_reaction_observed: bool = false
var _danger_confirmation_pending: bool = false
var _interaction_completed_before_lesson: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_configure_player_camera()
	_pulse_controller = player.get_node(^"%PulseController") as PlayerPulseController
	_decoy_controller = player.get_node(^"%DecoyController") as PlayerDecoyController
	_pulse_controller.allow_debug_input = false
	_pulse_controller.set_debug_visuals(false)
	for active_listener: Listener in get_listeners():
		active_listener.allow_debug_input = false
		active_listener.set_debug_enabled(false)
	_interaction_controller = player.get_node(^"%InteractionController") as PlayerInteractionController
	pulse_hud.bind(_pulse_controller)
	objective_hud.bind(mission_controller)
	interaction_prompt_hud.bind(_interaction_controller)
	decoy_hud.bind(_decoy_controller)
	threat_status_hud.bind(get_listeners())
	movement_aid.bind(player)
	_accessibility_manager = get_node_or_null("/root/AccessibilityManager")
	if _accessibility_manager != null:
		_accessibility_manager.connect(&"movement_aid_changed", _on_movement_aid_changed)
	_pulse_controller.pulse_started.connect(_on_pulse_started)
	_decoy_controller.decoy_thrown.connect(_on_decoy_thrown)
	_interaction_controller.focus_changed.connect(_on_interaction_focus_changed)
	_interaction_controller.interaction_completed.connect(_on_interaction_completed)
	for active_listener: Listener in get_listeners():
		active_listener.noise_target_changed.connect(
			_on_listener_noise_target_changed.bind(active_listener),
		)
	mission_controller.objective_changed.connect(_on_objective_changed)
	mission_controller.extraction_state_changed.connect(_on_extraction_state_changed)
	_show_tutorial_step(TUTORIAL_MOVE, 0, _get_move_tutorial_message())


func _exit_tree() -> void:
	if (
		_accessibility_manager != null
		and _accessibility_manager.is_connected(&"movement_aid_changed", _on_movement_aid_changed)
	):
		_accessibility_manager.disconnect(&"movement_aid_changed", _on_movement_aid_changed)


func _process(delta: float) -> void:
	elapsed_run_time += maxf(delta, 0.0)
	_update_orientation_tutorial_zones()


func _update_orientation_tutorial_zones() -> void:
	var distance_from_start := player.global_position.distance_to(START_POSITION)
	if not is_tutorial_completed(TUTORIAL_MOVE) and distance_from_start >= MOVE_TRIGGER_RADIUS:
		_complete_tutorial_step(TUTORIAL_MOVE)
		_show_tutorial_step(
			TUTORIAL_LOCAL,
			1,
			"LOCAL // YOU CAN ALWAYS SEE A LITTLE AROUND YOU",
		)
	elif (
		is_tutorial_completed(TUTORIAL_MOVE)
		and not is_tutorial_completed(TUTORIAL_LOCAL)
		and distance_from_start >= LOCAL_VISIBILITY_TRIGGER_RADIUS
	):
		_complete_tutorial_step(TUTORIAL_LOCAL)
		_show_tutorial_step(
			TUTORIAL_PULSE,
			2,
			"PULSE // REVEAL FARTHER: [SPACE] / LEFT MOUSE",
		)


func get_sectors() -> Array[FacilitySector]:
	return [orientation_sector, laboratory_sector, extraction_sector]


func get_listeners() -> Array[Listener]:
	return [listener, listener_south]


func get_authored_wall_count() -> int:
	var count := 0
	for sector: FacilitySector in get_sectors():
		count += sector.get_authored_collision_count()
	return count


func get_authored_revealable_count() -> int:
	var count := 0
	for sector: FacilitySector in get_sectors():
		count += sector.get_revealable_count()
	return count + 3 + 1 + get_listeners().size()


func get_all_room_centers() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for sector: FacilitySector in get_sectors():
		points.append_array(sector.get_global_room_centers())
	return points


func get_all_safe_observation_pockets() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for sector: FacilitySector in get_sectors():
		points.append_array(sector.get_global_safe_observation_pockets())
	return points


func get_level_bounds() -> Rect2:
	return LEVEL_BOUNDS


func get_sector_at(global_point: Vector2) -> FacilitySector:
	# Orientation owns the shared start/extraction threshold while its onboarding
	# is active; afterward the lower component is reported as Extraction.
	for sector: FacilitySector in get_sectors():
		if sector.sector_rect.has_point(sector.to_local(global_point)):
			return sector
	return null


func _configure_player_camera() -> void:
	player.global_position = START_POSITION
	var camera := player.get_node(^"%Camera2D") as Camera2D
	camera.limit_left = int(LEVEL_BOUNDS.position.x)
	camera.limit_top = int(LEVEL_BOUNDS.position.y)
	camera.limit_right = int(LEVEL_BOUNDS.end.x)
	camera.limit_bottom = int(LEVEL_BOUNDS.end.y)


func _on_pulse_started(_pulse: EchoPulse, _noise_event: NoiseEvent) -> void:
	_request_screen_shake(1.0, 0.14)
	if is_tutorial_completed(TUTORIAL_LOCAL) and not is_tutorial_completed(TUTORIAL_PULSE):
		_complete_tutorial_step(TUTORIAL_PULSE)
		_show_tutorial_step(
			TUTORIAL_DANGER,
			3,
			"DANGER // PULSE REVEALS, BUT CALLS LISTENERS",
		)
		if _listener_reaction_observed:
			_schedule_danger_confirmation()


func _on_listener_noise_target_changed(
	_position: Vector2,
	category: StringName,
	active_listener: Listener,
) -> void:
	if category == NoiseEvent.CATEGORY_SOUND_DECOY:
		listener_was_alerted = true
		if is_tutorial_completed(TUTORIAL_INTERACT) and not is_tutorial_completed(TUTORIAL_DECOY):
			_complete_decoy_tutorial()
		listener_alerted.emit(active_listener)
		return
	if category not in [
		NoiseEvent.CATEGORY_ECHO_PULSE,
		NoiseEvent.CATEGORY_REACTOR_RELAY,
	]:
		return
	_listener_reaction_observed = true
	if listener_was_alerted:
		return
	listener_was_alerted = true
	if is_tutorial_completed(TUTORIAL_PULSE) and not is_tutorial_completed(TUTORIAL_DANGER):
		_schedule_danger_confirmation()
	listener_alerted.emit(active_listener)


func _on_objective_changed(active_relays: int, required_relays: int) -> void:
	if active_relays <= 0:
		return
	if active_relays >= required_relays:
		_show_tutorial_step(TUTORIAL_EXTRACTION, 6, "EXTRACTION // POWERED: RETURN TO ENTRY")
		return
	if current_tutorial_step == TUTORIAL_EXTRACTION:
		_show_tutorial_step(
			TUTORIAL_EXTRACTION,
			6,
			"MISSION // RELAYS %d/%d: EXTRACTION STAYS LOCKED" % [active_relays, required_relays],
		)


func _on_extraction_state_changed(unlocked: bool) -> void:
	if unlocked:
		_show_tutorial_step(TUTORIAL_EXTRACTION, 6, "EXTRACTION // POWERED: RETURN TO ENTRY")


func is_tutorial_completed(step_id: StringName) -> bool:
	return _tutorial_completed.has(step_id)


func get_completed_tutorial_steps() -> Array[StringName]:
	var steps: Array[StringName] = []
	for step_id: StringName in _tutorial_completed:
		steps.append(step_id)
	return steps


func _on_decoy_thrown(_decoy: SoundDecoy, _landing_position: Vector2) -> void:
	if is_tutorial_completed(TUTORIAL_INTERACT) and not is_tutorial_completed(TUTORIAL_DECOY):
		_complete_decoy_tutorial()


func _on_interaction_focus_changed(interactable: FacilityInteractable) -> void:
	if (
		interactable != null
		and not is_tutorial_completed(TUTORIAL_INTERACT)
		and is_tutorial_completed(TUTORIAL_DANGER)
		and interactable.is_interaction_available(player)
	):
		_show_tutorial_step(
			TUTORIAL_INTERACT,
			4,
			"INTERACT // HOLD [E] AT RELAYS / EXTRACTION",
		)


func _on_interaction_completed(interactable: FacilityInteractable) -> void:
	if interactable is ExtractionTerminal:
		if not is_tutorial_completed(TUTORIAL_EXTRACTION):
			_complete_tutorial_step(TUTORIAL_EXTRACTION)
		return
	if is_tutorial_completed(TUTORIAL_DANGER) and not is_tutorial_completed(TUTORIAL_INTERACT):
		_complete_interaction_tutorial()
	elif not is_tutorial_completed(TUTORIAL_INTERACT):
		_interaction_completed_before_lesson = true


func _show_tutorial_step(step_id: StringName, stage: int, message: String) -> void:
	if is_tutorial_completed(step_id):
		return
	current_tutorial_step = step_id
	onboarding_stage = maxi(onboarding_stage, stage)
	onboarding_hud.show_message(message, stage, TUTORIAL_STAGE_COUNT)
	onboarding_stage_changed.emit(onboarding_stage, message)


func _complete_tutorial_step(step_id: StringName) -> void:
	if is_tutorial_completed(step_id):
		return
	_tutorial_completed[step_id] = true
	tutorial_step_completed.emit(step_id)
	if current_tutorial_step == step_id:
		current_tutorial_step = &""
		onboarding_hud.clear_message()


func _complete_danger_tutorial() -> void:
	_danger_confirmation_pending = false
	if is_tutorial_completed(TUTORIAL_DANGER):
		return
	_complete_tutorial_step(TUTORIAL_DANGER)
	if _interaction_completed_before_lesson:
		_complete_interaction_tutorial()
	else:
		_show_tutorial_step(
			TUTORIAL_INTERACT,
			4,
			"INTERACT // HOLD [E] AT RELAYS / EXTRACTION",
		)


func _complete_interaction_tutorial() -> void:
	if not is_tutorial_completed(TUTORIAL_INTERACT):
		_complete_tutorial_step(TUTORIAL_INTERACT)
	_show_tutorial_step(
		TUTORIAL_DECOY,
		5,
		"DECOY // [Q] / RIGHT MOUSE MISDIRECTS LISTENERS",
	)


func _complete_decoy_tutorial() -> void:
	_complete_tutorial_step(TUTORIAL_DECOY)
	_show_tutorial_step(
		TUTORIAL_EXTRACTION,
		6,
		"MISSION // RESTORE 3 RELAYS, THEN EXTRACT",
	)


func _schedule_danger_confirmation() -> void:
	if _danger_confirmation_pending or is_tutorial_completed(TUTORIAL_DANGER):
		return
	_danger_confirmation_pending = true
	var timer := get_tree().create_timer(DANGER_CONFIRMATION_DURATION, false)
	timer.timeout.connect(_complete_danger_tutorial, CONNECT_ONE_SHOT)


func _get_move_tutorial_message() -> String:
	var movement_aid_enabled := false
	if _accessibility_manager != null:
		movement_aid_enabled = bool(_accessibility_manager.get("movement_aid_enabled"))
	return (
		"MOVE // WASD / ARROWS OR BOTTOM-RIGHT JOYSTICK"
		if movement_aid_enabled
		else "MOVE // WASD / ARROWS"
	)


func _on_movement_aid_changed(_enabled: bool) -> void:
	if current_tutorial_step == TUTORIAL_MOVE and not is_tutorial_completed(TUTORIAL_MOVE):
		_show_tutorial_step(TUTORIAL_MOVE, 0, _get_move_tutorial_message())


func _request_screen_shake(strength: float, duration: float) -> void:
	var accessibility := get_node_or_null("/root/AccessibilityManager")
	var shake_multiplier := 1.0
	if accessibility != null:
		shake_multiplier = float(accessibility.call(&"get_shake_multiplier"))
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	if shake_multiplier <= 0.0:
		_reset_camera_offset()
		return
	var camera := player.get_node(^"%Camera2D") as Camera2D
	_shake_tween = create_tween()
	_shake_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var step_duration := maxf(duration, 0.01) / float(SHAKE_OFFSETS.size())
	for offset: Vector2 in SHAKE_OFFSETS:
		_shake_tween.tween_property(
			camera,
			"offset",
			offset * strength * shake_multiplier,
			step_duration,
		)
	_shake_tween.finished.connect(_reset_camera_offset, CONNECT_ONE_SHOT)


func _reset_camera_offset() -> void:
	if is_instance_valid(player):
		var camera := player.get_node(^"%Camera2D") as Camera2D
		camera.offset = Vector2.ZERO
