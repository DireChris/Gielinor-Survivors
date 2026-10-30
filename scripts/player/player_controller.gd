extends CharacterBody3D
class_name PlayerController

## Camera-relative third-person movement plus the player's run health.
## Input actions are registered in code so a fresh project works without
## manual Input Map configuration in the editor.

signal health_changed(current_health: int, maximum_health: int)
signal player_died

@export_category("Movement")
@export_range(1.0, 12.0, 0.1) var walk_speed: float = 5.5
@export_range(1.0, 18.0, 0.1) var sprint_speed: float = 8.0
@export_range(1.0, 60.0, 0.5) var acceleration: float = 25.0
@export_range(1.0, 80.0, 0.5) var deceleration: float = 32.0
@export_range(1.0, 60.0, 0.5) var turn_rate: float = 14.0
@export_range(1.0, 100.0, 1.0) var gravity_strength: float = 24.0
@export_range(5.0, 100.0, 1.0) var terminal_fall_speed: float = 45.0

const MAX_PHYSICS_STEP: float = 0.05
const INPUT_DEADZONE_SQUARED: float = 0.001

@export_category("Survival")
@export_range(1, 500, 1) var max_health: int = 100

@export_category("References")
@export var camera_path: NodePath

var current_health: int = 100
var is_dead: bool = false
var run_speed_multiplier: float = 1.0

var _combat_facing_lock_remaining: float = 0.0
var _combat_facing_yaw: float = 0.0

var _camera: Camera3D


func _ready() -> void:
	# CharacterBody3D.velocity is persistent state. Never inherit a stale or
	# editor/runtime-modified velocity when a new scene instance is created.
	velocity = Vector3.ZERO
	_register_default_inputs()
	_camera = get_node_or_null(camera_path) as Camera3D
	current_health = max_health
	health_changed.emit(current_health, max_health)

	if _camera == null:
		push_warning("PlayerController: Camera not found. Movement will use world-relative directions.")


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector3.ZERO
		return

	# Physics normally supplies a fixed delta. Capping a rare hitch prevents a
	# single oversized integration step from producing a large movement jump.
	var physics_delta := clampf(delta, 0.0, MAX_PHYSICS_STEP)
	var input_vector := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)

	var move_direction := _get_camera_relative_direction(input_vector)
	var target_speed := (sprint_speed if Input.is_action_pressed("sprint") else walk_speed) * run_speed_multiplier
	var max_horizontal_speed := maxf(walk_speed, sprint_speed) * run_speed_multiplier
	var target_horizontal_velocity := move_direction * target_speed
	var has_movement_input := move_direction.length_squared() > INPUT_DEADZONE_SQUARED
	var rate := acceleration if has_movement_input else deceleration

	# Accelerate towards input, or decelerate each axis towards exactly zero
	# when no movement key is held. Then enforce the speed ceiling even if
	# velocity was externally modified or corrupted before this tick.
	velocity.x = move_toward(velocity.x, target_horizontal_velocity.x, rate * physics_delta)
	velocity.z = move_toward(velocity.z, target_horizontal_velocity.z, rate * physics_delta)
	var horizontal_velocity := Vector2(velocity.x, velocity.z)
	if horizontal_velocity.length_squared() > max_horizontal_speed * max_horizontal_speed:
		horizontal_velocity = horizontal_velocity.normalized() * max_horizontal_speed
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.y

	if is_on_floor():
		# Zero vertical drift while grounded; a small negative bias is not
		# needed for CharacterBody3D floor detection here.
		velocity.y = 0.0
	else:
		velocity.y = maxf(
			velocity.y - gravity_strength * physics_delta,
			-terminal_fall_speed
		)

	if _combat_facing_lock_remaining > 0.0:
		_combat_facing_lock_remaining = maxf(0.0, _combat_facing_lock_remaining - physics_delta)
		rotation.y = lerp_angle(rotation.y, _combat_facing_yaw, minf(turn_rate * physics_delta, 1.0))
	elif has_movement_input:
		var target_yaw := atan2(-move_direction.x, -move_direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, minf(turn_rate * physics_delta, 1.0))

	# Godot 4 consumes the CharacterBody3D.velocity property directly.
	# Do not multiply velocity by delta here.
	move_and_slide()


func face_direction(direction: Vector3, lock_duration: float = 0.35) -> void:
	var flat_direction := Vector3(direction.x, 0.0, direction.z)
	if flat_direction.length_squared() < INPUT_DEADZONE_SQUARED:
		return
	flat_direction = flat_direction.normalized()
	_combat_facing_yaw = atan2(-flat_direction.x, -flat_direction.z)
	_combat_facing_lock_remaining = maxf(_combat_facing_lock_remaining, lock_duration)


func take_damage(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		is_dead = true
		velocity = Vector3.ZERO
		player_died.emit()


func restore_health(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	current_health = mini(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)


func _get_camera_relative_direction(input_vector: Vector2) -> Vector3:
	if input_vector.length_squared() < INPUT_DEADZONE_SQUARED:
		return Vector3.ZERO

	if _camera == null:
		return Vector3(input_vector.x, 0.0, input_vector.y).normalized()

	var camera_right := _camera.global_basis.x
	var camera_forward := -_camera.global_basis.z
	camera_right.y = 0.0
	camera_forward.y = 0.0

	if camera_right.length_squared() > INPUT_DEADZONE_SQUARED:
		camera_right = camera_right.normalized()
	if camera_forward.length_squared() > INPUT_DEADZONE_SQUARED:
		camera_forward = camera_forward.normalized()

	# Input.get_vector returns a negative Y value for the forward action.
	return (camera_right * input_vector.x + camera_forward * -input_vector.y).normalized()


func _register_default_inputs() -> void:
	_bind_keys("move_forward", [KEY_W, KEY_UP])
	_bind_keys("move_back", [KEY_S, KEY_DOWN])
	_bind_keys("move_left", [KEY_A, KEY_LEFT])
	_bind_keys("move_right", [KEY_D, KEY_RIGHT])
	_bind_keys("sprint", [KEY_SHIFT])


func _bind_keys(action_name: StringName, keycodes: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for keycode in keycodes:
		var already_bound := false
		for existing_event in InputMap.action_get_events(action_name):
			if existing_event is InputEventKey and existing_event.physical_keycode == keycode:
				already_bound = true
				break
		if already_bound:
			continue

		var key_event := InputEventKey.new()
		key_event.physical_keycode = keycode
		InputMap.action_add_event(action_name, key_event)
