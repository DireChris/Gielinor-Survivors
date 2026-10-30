extends CharacterBody3D
class_name PlayerController

## Camera-relative third-person movement for the first playable slice.
## Input actions are registered in code so the project works immediately
## without requiring manual Input Map setup in the editor.

@export_category("Movement")
@export_range(1.0, 12.0, 0.1) var walk_speed: float = 5.5
@export_range(1.0, 18.0, 0.1) var sprint_speed: float = 8.0
@export_range(1.0, 60.0, 0.5) var acceleration: float = 25.0
@export_range(1.0, 80.0, 0.5) var deceleration: float = 32.0
@export_range(1.0, 60.0, 0.5) var turn_rate: float = 14.0
@export var gravity_strength: float = 24.0

@export_category("References")
@export var camera_path: NodePath

var _camera: Camera3D


func _ready() -> void:
	_register_default_inputs()
	_camera = get_node_or_null(camera_path) as Camera3D
	if _camera == null:
		push_warning("PlayerController: Camera not found. Movement will use world-relative directions.")


func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)

	var move_direction := _get_camera_relative_direction(input_vector)
	var target_speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var target_horizontal_velocity := move_direction * target_speed
	var rate := acceleration if move_direction.length_squared() > 0.001 else deceleration

	velocity.x = move_toward(velocity.x, target_horizontal_velocity.x, rate * delta)
	velocity.z = move_toward(velocity.z, target_horizontal_velocity.z, rate * delta)

	if is_on_floor():
		if velocity.y < 0.0:
			velocity.y = -0.1
	else:
		velocity.y -= gravity_strength * delta

	if move_direction.length_squared() > 0.001:
		var target_yaw := atan2(-move_direction.x, -move_direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, minf(turn_rate * delta, 1.0))

	move_and_slide()


func _get_camera_relative_direction(input_vector: Vector2) -> Vector3:
	if input_vector.length_squared() < 0.001:
		return Vector3.ZERO

	if _camera == null:
		return Vector3(input_vector.x, 0.0, input_vector.y).normalized()

	var camera_right := _camera.global_basis.x
	var camera_forward := -_camera.global_basis.z
	camera_right.y = 0.0
	camera_forward.y = 0.0

	if camera_right.length_squared() > 0.001:
		camera_right = camera_right.normalized()
	if camera_forward.length_squared() > 0.001:
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
