class_name TopDownPlayer
extends CharacterBody2D

@export_category("Movement")
@export_range(1.0, 1000.0, 1.0) var max_speed: float = 230.0
@export_range(1.0, 6000.0, 1.0) var acceleration: float = 1800.0
@export_range(1.0, 6000.0, 1.0) var deceleration: float = 2200.0

@export_category("Facing")
@export var face_mouse: bool = true
@export var default_facing_direction: Vector2 = Vector2.RIGHT
@export_range(0.0, 64.0, 1.0) var mouse_dead_zone: float = 8.0

@export_category("Camera")
@export_range(1.0, 20.0, 0.1) var camera_smoothing_speed: float = 6.0

@onready var visuals: PlayerVisual = %Visuals
@onready var player_camera: Camera2D = %Camera2D

var facing_direction: Vector2 = Vector2.RIGHT
var movement_aid_vector: Vector2 = Vector2.ZERO


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group(&"player")
	facing_direction = _safe_normalized(default_facing_direction, Vector2.RIGHT)
	player_camera.position_smoothing_enabled = true
	player_camera.position_smoothing_speed = camera_smoothing_speed
	visuals.set_facing_direction(facing_direction)


func _physics_process(delta: float) -> void:
	var keyboard_direction := Input.get_vector(
		&"move_left",
		&"move_right",
		&"move_up",
		&"move_down",
	)
	var input_direction := select_strongest_movement_input(keyboard_direction, movement_aid_vector)
	velocity = calculate_next_velocity(velocity, input_direction, delta)
	move_and_slide()
	_update_facing_direction()


func calculate_next_velocity(
	current_velocity: Vector2,
	input_direction: Vector2,
	delta: float,
) -> Vector2:
	var clamped_input := input_direction.limit_length(1.0)
	var target_velocity := clamped_input * max_speed
	var response_rate := deceleration if clamped_input.length_squared() <= 0.0001 else acceleration
	return current_velocity.move_toward(target_velocity, response_rate * maxf(delta, 0.0))


func set_movement_aid_vector(direction: Vector2) -> void:
	movement_aid_vector = direction.limit_length(1.0)


func clear_movement_aid_vector() -> void:
	movement_aid_vector = Vector2.ZERO


func set_virtual_joystick_vector(direction: Vector2) -> void:
	set_movement_aid_vector(direction)


func clear_virtual_joystick_vector() -> void:
	clear_movement_aid_vector()


func select_strongest_movement_input(
	keyboard_direction: Vector2,
	joystick_direction: Vector2,
) -> Vector2:
	var keyboard := keyboard_direction.limit_length(1.0)
	var joystick := joystick_direction.limit_length(1.0)
	return joystick if joystick.length_squared() > keyboard.length_squared() else keyboard


func _update_facing_direction() -> void:
	var next_facing := facing_direction
	if face_mouse:
		var mouse_offset := get_global_mouse_position() - global_position
		if mouse_offset.length() > mouse_dead_zone:
			next_facing = mouse_offset.normalized()
	elif velocity.length_squared() > 1.0:
		next_facing = velocity.normalized()

	facing_direction = _safe_normalized(next_facing, facing_direction)
	visuals.set_facing_direction(facing_direction)


func _safe_normalized(value: Vector2, fallback: Vector2) -> Vector2:
	return fallback if value.length_squared() <= 0.0001 else value.normalized()
