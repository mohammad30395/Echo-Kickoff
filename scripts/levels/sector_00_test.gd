class_name Sector00Test
extends Node2D

signal onboarding_stage_changed(stage: int, message: String)
signal listener_alerted

const LEVEL_BOUNDS := Rect2(-1120.0, -640.0, 2240.0, 1280.0)
const START_POSITION := Vector2(-1010.0, 0.0)
const MOVEMENT_LEARN_DISTANCE := 68.0
const MESSAGE_DURATION := 3.8

const WALL_RECTS: Array[Rect2] = [
	Rect2(-1120.0, -640.0, 2240.0, 32.0),
	Rect2(-1120.0, 608.0, 2240.0, 32.0),
	Rect2(-1120.0, -608.0, 32.0, 1216.0),
	Rect2(1088.0, -608.0, 32.0, 1216.0),
	Rect2(-1050.0, -125.0, 300.0, 24.0),
	Rect2(-1050.0, 101.0, 300.0, 24.0),
	Rect2(-210.0, -150.0, 420.0, 300.0),
	Rect2(-690.0, -250.0, 280.0, 28.0),
	Rect2(400.0, -250.0, 350.0, 28.0),
	Rect2(-720.0, 210.0, 310.0, 28.0),
	Rect2(380.0, 210.0, 350.0, 28.0),
	Rect2(-500.0, -520.0, 28.0, 270.0),
	Rect2(472.0, -520.0, 28.0, 270.0),
	Rect2(-590.0, 238.0, 28.0, 220.0),
	Rect2(558.0, 238.0, 28.0, 230.0),
]

const PROP_RECTS: Array[Rect2] = [
	Rect2(-330.0, -500.0, 96.0, 74.0),
	Rect2(245.0, -500.0, 96.0, 74.0),
	Rect2(-390.0, 350.0, 92.0, 100.0),
	Rect2(265.0, 350.0, 104.0, 82.0),
]

const HAZARD_RECTS: Array[Rect2] = [
	Rect2(-870.0, -310.0, 150.0, 40.0),
	Rect2(700.0, -300.0, 150.0, 40.0),
	Rect2(730.0, 285.0, 150.0, 40.0),
]

@onready var player: TopDownPlayer = %Player
@onready var mission_controller: MissionObjectiveController = %MissionController
@onready var listener: Listener = %Listener
@onready var pulse_hud: PulseCooldownHud = %PulseCooldownHud
@onready var objective_hud: ObjectiveHud = %ObjectiveHud
@onready var interaction_prompt_hud: InteractionPromptHud = %InteractionPromptHud
@onready var onboarding_hud: OnboardingHud = %OnboardingHud
@onready var decoy_hud: DecoyHud = %DecoyHud
@onready var revealables: Node2D = %Revealables
@onready var collision_geometry: Node2D = %CollisionGeometry

var onboarding_stage: int = 0
var listener_was_alerted: bool = false
var elapsed_run_time: float = 0.0
var _message_remaining: float = 0.0
var _pulse_controller: PlayerPulseController
var _decoy_controller: PlayerDecoyController


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_authored_geometry()
	_configure_player_camera()
	_pulse_controller = player.get_node(^"%PulseController") as PlayerPulseController
	_decoy_controller = player.get_node(^"%DecoyController") as PlayerDecoyController
	_pulse_controller.allow_debug_input = false
	_pulse_controller.set_debug_visuals(false)
	listener.allow_debug_input = false
	listener.set_debug_enabled(false)
	var interaction_controller := player.get_node(^"%InteractionController") as PlayerInteractionController
	pulse_hud.bind(_pulse_controller)
	objective_hud.bind(mission_controller)
	interaction_prompt_hud.bind(interaction_controller)
	decoy_hud.bind(_decoy_controller)
	_pulse_controller.pulse_started.connect(_on_pulse_started)
	listener.noise_target_changed.connect(_on_listener_noise_target_changed)
	mission_controller.objective_changed.connect(_on_objective_changed)
	_set_onboarding_message(0, "MOVE // WASD OR ARROW KEYS", 0.0)


func _process(delta: float) -> void:
	elapsed_run_time += maxf(delta, 0.0)
	if onboarding_stage == 0 and player.global_position.distance_to(START_POSITION) >= MOVEMENT_LEARN_DISTANCE:
		_set_onboarding_message(1, "ECHO // SPACE OR LEFT MOUSE", 0.0)
	if _message_remaining > 0.0:
		_message_remaining = move_toward(_message_remaining, 0.0, maxf(delta, 0.0))
		if is_zero_approx(_message_remaining):
			onboarding_hud.clear_message()


func get_authored_wall_count() -> int:
	return WALL_RECTS.size() + PROP_RECTS.size()


func get_level_bounds() -> Rect2:
	return LEVEL_BOUNDS


func _build_authored_geometry() -> void:
	var index := 0
	for wall_rect: Rect2 in WALL_RECTS:
		_add_revealable_block(wall_rect, EchoRevealPrimitive.PrimitiveKind.WALL, "Wall%02d" % index, true)
		index += 1
	for prop_index in range(PROP_RECTS.size()):
		_add_revealable_block(
			PROP_RECTS[prop_index],
			EchoRevealPrimitive.PrimitiveKind.PROP,
			"Prop%02d" % prop_index,
			true,
		)
	for hazard_index in range(HAZARD_RECTS.size()):
		_add_revealable_block(
			HAZARD_RECTS[hazard_index],
			EchoRevealPrimitive.PrimitiveKind.HAZARD,
			"Hazard%02d" % hazard_index,
			false,
		)
	var boundary := EchoRevealPrimitive.new()
	boundary.name = "FloorBoundary"
	boundary.primitive_kind = EchoRevealPrimitive.PrimitiveKind.FLOOR_BOUNDARY
	boundary.primitive_size = LEVEL_BOUNDS.size - Vector2(32.0, 32.0)
	boundary.reveal_duration = 1.0
	boundary.fade_speed = 0.34
	revealables.add_child(boundary)


func _add_revealable_block(
	block_rect: Rect2,
	primitive_kind: int,
	node_name: String,
	with_collision: bool,
) -> void:
	var visual := EchoRevealPrimitive.new()
	visual.name = "%sVisual" % node_name
	visual.position = block_rect.get_center()
	visual.primitive_kind = primitive_kind
	visual.primitive_size = block_rect.size
	visual.reveal_duration = 1.0
	visual.fade_speed = 0.34
	visual.darkness_visibility = 0.01
	revealables.add_child(visual)
	if not with_collision:
		return
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = block_rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 1
	var collision_shape := CollisionShape2D.new()
	var rectangle_shape := RectangleShape2D.new()
	rectangle_shape.size = block_rect.size
	collision_shape.shape = rectangle_shape
	body.add_child(collision_shape)
	collision_geometry.add_child(body)


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


func _on_listener_noise_target_changed(_position: Vector2, category: StringName) -> void:
	if category == NoiseEvent.CATEGORY_SOUND_DECOY:
		listener_was_alerted = true
		_set_onboarding_message(
			3,
			"LISTENER DIVERTED // MOVE WHILE IT INVESTIGATES",
			MESSAGE_DURATION,
		)
		listener_alerted.emit()
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
	listener_alerted.emit()


func _on_objective_changed(active_relays: int, _required_relays: int) -> void:
	if active_relays <= 0 or listener_was_alerted:
		return
	# A relay is guaranteed to make enough noise to teach the danger relationship,
	# even when a cautious player reaches one without pulsing near the Listener.
	_set_onboarding_message(3, "THE RELAY WAS LOUD // MOVE", MESSAGE_DURATION)


func _set_onboarding_message(stage: int, message: String, duration: float) -> void:
	onboarding_stage = stage
	_message_remaining = maxf(duration, 0.0)
	onboarding_hud.show_message(message)
	onboarding_stage_changed.emit(onboarding_stage, message)
