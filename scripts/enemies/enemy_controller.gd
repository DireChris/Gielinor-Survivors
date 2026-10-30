extends CharacterBody3D
class_name EnemyController

## Simple melee enemy with wave scaling, contact attacks and floating
## damage numbers. This is the reusable base for future monster variants.

signal died(enemy: EnemyController)
signal health_changed(current_health: int, maximum_health: int)

@export_category("Identity")
@export var monster_id: StringName = &"goblin"
@export var drop_table: DropTableData

@export_category("Base Stats")
@export_range(1, 500, 1) var base_max_health: int = 18
@export_range(0.5, 10.0, 0.1) var base_move_speed: float = 2.0
@export_range(1, 50, 1) var base_contact_damage: int = 5
@export_range(0.5, 5.0, 0.1) var attack_interval: float = 1.25
@export_range(0.5, 4.0, 0.1) var attack_range: float = 1.55
@export_range(1.0, 60.0, 1.0) var gravity_strength: float = 24.0

var max_health: int = 18
var current_health: int = 18
var move_speed: float = 2.0
var contact_damage: int = 5
var alive: bool = true

var _target: Node3D
var _attack_cooldown: float = 0.65
var _visual_rig: Node


func _ready() -> void:
	max_health = base_max_health
	current_health = max_health
	move_speed = base_move_speed
	contact_damage = base_contact_damage
	_visual_rig = get_node_or_null("VisualRig")


func initialize(target: Node3D, wave_number: int) -> void:
	_target = target
	var wave_bonus := maxi(0, wave_number - 1)

	max_health = roundi(float(base_max_health) * (1.0 + float(wave_bonus) * 0.14))
	current_health = max_health
	move_speed = base_move_speed + minf(float(wave_bonus) * 0.05, 0.7)
	contact_damage = base_contact_damage + floori(float(wave_bonus) / 3.0)
	health_changed.emit(current_health, max_health)


func _physics_process(delta: float) -> void:
	if not alive:
		return

	var move_direction := Vector3.ZERO
	var distance_to_target := INF

	if is_instance_valid(_target):
		var offset := _target.global_position - global_position
		offset.y = 0.0
		distance_to_target = offset.length()
		if distance_to_target > 0.001:
			move_direction = offset / distance_to_target

	if distance_to_target > attack_range:
		var desired_velocity := move_direction * move_speed
		velocity.x = move_toward(velocity.x, desired_velocity.x, 12.0 * delta)
		velocity.z = move_toward(velocity.z, desired_velocity.z, 12.0 * delta)
		if move_direction.length_squared() > 0.001:
			var target_yaw := atan2(-move_direction.x, -move_direction.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, minf(10.0 * delta, 1.0))
	else:
		velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
		_attack_cooldown -= delta
		if _attack_cooldown <= 0.0:
			if is_instance_valid(_target) and _target.has_method("take_damage"):
				if is_instance_valid(_visual_rig) and _visual_rig.has_method("play_action"):
					_visual_rig.call("play_action", &"attack")
				_target.take_damage(contact_damage)
			_attack_cooldown = attack_interval

	if is_on_floor():
		if velocity.y < 0.0:
			velocity.y = -0.1
	else:
		velocity.y -= gravity_strength * delta

	move_and_slide()


func take_damage(amount: int) -> void:
	if not alive or amount <= 0:
		return

	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	_spawn_damage_number(amount)

	if current_health <= 0:
		alive = false
		collision_layer = 0
		collision_mask = 0
		set_physics_process(false)
		if is_instance_valid(_visual_rig) and _visual_rig.has_method("play_action"):
			_visual_rig.call("play_action", &"death")
		died.emit(self)
		# Keep the defeated mesh visible briefly so its death animation can play.
		get_tree().create_timer(0.78).timeout.connect(queue_free)


func _spawn_damage_number(amount: int) -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return

	var label := Label3D.new()
	label.text = str(amount)
	label.font_size = 28
	label.outline_size = 8
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 0.34, 0.20, 1.0)
	scene_root.add_child(label)
	label.global_position = global_position + Vector3(0.0, 2.0, 0.0)

	var tween := scene_root.create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		label,
		"global_position",
		label.global_position + Vector3(0.0, 0.75, 0.0),
		0.55
	)
	tween.tween_property(label, "modulate:a", 0.0, 0.55)
	tween.chain().tween_callback(label.queue_free)
