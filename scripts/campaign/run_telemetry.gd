class_name RunTelemetry
extends Node

var elapsed_time: float = 0.0
var pulse_count: int = 0
var decoy_count: int = 0
var chase_count: int = 0
var _listeners: Array[Listener] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func _process(delta: float) -> void:
	elapsed_time += maxf(delta, 0.0)


func bind(player: TopDownPlayer, listeners: Array[Listener]) -> void:
	var pulse_controller := player.get_node(^"%PulseController") as PlayerPulseController
	var decoy_controller := player.get_node(^"%DecoyController") as PlayerDecoyController
	pulse_controller.pulse_started.connect(_on_pulse_started)
	decoy_controller.decoy_thrown.connect(_on_decoy_thrown)
	_listeners = listeners
	for listener: Listener in _listeners:
		listener.state_changed.connect(_on_listener_state_changed)


func create_result(definition: CampaignLevelDefinition) -> RunResult:
	return RunResult.create(
		definition.level_id,
		elapsed_time,
		pulse_count,
		decoy_count,
		chase_count,
		definition.par_time_seconds,
	)


func _on_pulse_started(_pulse: EchoPulse, _event: NoiseEvent) -> void:
	pulse_count += 1


func _on_decoy_thrown(_decoy: SoundDecoy, _position: Vector2) -> void:
	decoy_count += 1


func _on_listener_state_changed(_previous: Listener.ListenerState, current: Listener.ListenerState) -> void:
	if current == Listener.ListenerState.CHASE:
		chase_count += 1
