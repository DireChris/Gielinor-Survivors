extends Node3D
class_name OrbitCamera

## RuneLite-inspired orbit camera.
## Hold middle mouse and drag to orbit; use the wheel to zoom.

@export_category("Target")
@export var target_path: NodePath
@export var target_offset: Vector3 = Vector3(0.0, 1.15, 0.0)
@export_range(1.0, 30.0, 0.5) var follow_speed: float = 16.0

@export_category("Orbit")
@export_range(0.05, 1.0, 0.01) var mouse_sensitivity: float = 0.22
@export_range(-85.0, 5.0, 1.0) var min_pitch_degrees: float = -78.0
@export_range(-85.0, 5.0, 1.0) var max_pitch_degrees: float = 5.0
@export_range(2.0, 35.0, 0.5) var min_zoom: float = 3.0
@export_range(4.0, 60.0, 0.5) var max_zoom: float = 22.0
@export_range(0.25, 3.0, 0.05) var zoom_step: float = 1.0
@export_range(0.0, 360.0, 1.0) var starting_yaw_degrees: float = 35.0
@export_range(-85.0, 5.0, 1.0) var starting_pitch_degrees: float = -32.0
@export var starting_zoom: float = 8.5

@onready var yaw_pivot: Node3D = $YawPivot
@onready var pitch_pivot: Node3D = $YawPivot/PitchPivot
@onready var spring_arm: SpringArm3D = $YawPivot/PitchPivot/SpringArm3D
@onready var camera: Camera3D = $YawPivot/PitchPivot/SpringArm3D/Camera3D

var _target: Node3D
var _yaw: float
var _pitch: float
var _zoom: float
var _is_orbiting: bool = false


func _ready() -> void:
	_target = get_node_or_null(target_path) as Node3D
	if _target == null:
		push_error("OrbitCamera: target_path does not point to a Node3D.")
		set_process(false)
		set_process_input(false)
		return

	_yaw = deg_to_rad(starting_yaw_degrees)
	_pitch = deg_to_rad(starting_pitch_degrees)
	_zoom = clampf(starting_zoom, min_zoom, max_zoom)
	spring_arm.spring_length = _zoom
	camera.current = true

	if _target is CollisionObject3D:
		spring_arm.add_excluded_object((_target as CollisionObject3D).get_rid())

	yaw_pivot.rotation.y = _yaw
	pitch_pivot.rotation.x = _pitch
	global_position = _target.global_position + target_offset


func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		return

	var desired_position := _target.global_position + target_offset
	global_position = global_position.lerp(desired_position, minf(follow_speed * delta, 1.0))
	yaw_pivot.rotation.y = lerp_angle(yaw_pivot.rotation.y, _yaw, minf(20.0 * delta, 1.0))
	pitch_pivot.rotation.x = lerp_angle(pitch_pivot.rotation.x, _pitch, minf(20.0 * delta, 1.0))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_MIDDLE:
			_is_orbiting = mouse_button.pressed
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _is_orbiting else Input.MOUSE_MODE_VISIBLE
			get_viewport().set_input_as_handled()
			return

		if mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(_zoom - zoom_step)
			get_viewport().set_input_as_handled()
			return

		if mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(_zoom + zoom_step)
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion and _is_orbiting:
		var motion := event as InputEventMouseMotion
		_yaw -= deg_to_rad(motion.screen_relative.x * mouse_sensitivity)
		_pitch -= deg_to_rad(motion.screen_relative.y * mouse_sensitivity)
		_pitch = clampf(_pitch, deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and _is_orbiting:
			_is_orbiting = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and _is_orbiting:
		_is_orbiting = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _set_zoom(value: float) -> void:
	_zoom = clampf(value, min_zoom, max_zoom)
	spring_arm.spring_length = _zoom
