class_name EchoFacility
extends Node2D

signal onboarding_stage_changed(stage: int, message: String)
signal listener_alerted(listener: Listener)

const LEVEL_BOUNDS := Rect2(-3400.0, -1700.0, 6600.0, 3400.0)
const START_POSITION := Vector2(-3150.0, 0.0)
const MOVEMENT_LEARN_DISTANCE := 76.0
const MESSAGE_DURATION := 4.2

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

var onboarding_stage: int = 0
var listener_was_alerted: bool = false
var elapsed_run_time: float = 0.0
var _message_remaining: float = 0.0
var _pulse_controller: PlayerPulseController
var _decoy_controller: PlayerDecoyController


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
	var interaction_controller := player.get_node(^"%InteractionController") as PlayerInteractionController
	pulse_hud.bind(_pulse_controller)
	objective_hud.bind(mission_controller)
	interaction_prompt_hud.bind(interaction_controller)
	decoy_hud.bind(_decoy_controller)
	_pulse_controller.pulse_started.connect(_on_pulse_started)
	for active_listener: Listener in get_listeners():
		active_listener.noise_target_changed.connect(
			_on_listener_noise_target_changed.bind(active_listener),
		)
	mission_controller.objective_changed.connect(_on_objective_changed)
	mission_controller.extraction_state_changed.connect(_on_extraction_state_changed)
	_set_onboarding_message(0, "MOVE // WASD OR ARROW KEYS", 0.0)


func _process(delta: float) -> void:
	elapsed_run_time += maxf(delta, 0.0)
	if onboarding_stage == 0 and player.global_position.distance_to(START_POSITION) >= MOVEMENT_LEARN_DISTANCE:
		_set_onboarding_message(1, "ECHO // SPACE OR LEFT MOUSE", 0.0)
	if _message_remaining > 0.0:
		_message_remaining = move_toward(_message_remaining, 0.0, maxf(delta, 0.0))
		if is_zero_approx(_message_remaining):
			onboarding_hud.clear_message()


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
	if onboarding_stage <= 1:
		_set_onboarding_message(
			2,
			"ECHO REVEALS THE FACILITY // ECHO ALSO TRAVELS",
			MESSAGE_DURATION,
		)


func _on_listener_noise_target_changed(
	_position: Vector2,
	category: StringName,
	active_listener: Listener,
) -> void:
	if category == NoiseEvent.CATEGORY_SOUND_DECOY:
		listener_was_alerted = true
		_set_onboarding_message(
			3,
			"LISTENER DIVERTED // MOVE WHILE IT INVESTIGATES",
			MESSAGE_DURATION,
		)
		listener_alerted.emit(active_listener)
		return
	if listener_was_alerted or category not in [
		NoiseEvent.CATEGORY_ECHO_PULSE,
		NoiseEvent.CATEGORY_REACTOR_RELAY,
	]:
		return
	listener_was_alerted = true
	_set_onboarding_message(
		3,
		"LISTENER ALERTED // BREAK LINE OF SIGHT",
		MESSAGE_DURATION,
	)
	listener_alerted.emit(active_listener)


func _on_objective_changed(active_relays: int, required_relays: int) -> void:
	if active_relays <= 0:
		return
	if active_relays >= required_relays:
		_set_onboarding_message(5, "EXTRACTION POWERED // RETURN TO ENTRY", MESSAGE_DURATION)
		return
	if active_relays == 1:
		_set_onboarding_message(4, "RELAY ONLINE // SIDE ROUTES CREATE DISTANCE", MESSAGE_DURATION)
	else:
		_set_onboarding_message(4, "ONE RELAY REMAINS // SAVE A DECOY FOR WITHDRAWAL", MESSAGE_DURATION)


func _on_extraction_state_changed(unlocked: bool) -> void:
	if unlocked:
		_set_onboarding_message(5, "EXTRACTION POWERED // RETURN TO ENTRY", MESSAGE_DURATION)


func _set_onboarding_message(stage: int, message: String, duration: float) -> void:
	onboarding_stage = maxi(onboarding_stage, stage)
	_message_remaining = maxf(duration, 0.0)
	onboarding_hud.show_message(message)
	onboarding_stage_changed.emit(onboarding_stage, message)
