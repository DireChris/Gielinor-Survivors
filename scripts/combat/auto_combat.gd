extends Node
class_name AutoCombat

## Automatic weapon combat with target selection, special energy and visual feedback.

signal attack_landed(target_name: String, damage: int)
signal special_activated(special_name: String, targets_hit: int)

@export_category("References")
@export var player_path: NodePath
@export var enemy_container_path: NodePath
@export var weapon_data: WeaponData
@export_category("Special Energy")
@export_range(0.0, 10.0, 0.1) var passive_energy_regen: float = 1.25
@export_range(0.0, 50.0, 1.0) var energy_per_kill: float = 18.0

var special_energy: float = 0.0
var damage_bonus: int = 0
var run_damage_bonus: int = 0
var attack_speed_multiplier: float = 1.0
var special_energy_gain_multiplier: float = 1.0
var attack_range_bonus: float = 0.0
var _player: PlayerController
var _enemy_container: Node3D
var _attack_cooldown: float = 0.0


func _ready() -> void:
	_player = get_node_or_null(player_path) as PlayerController
	_enemy_container = get_node_or_null(enemy_container_path) as Node3D
	if _player == null or _enemy_container == null or weapon_data == null:
		push_error("AutoCombat requires player, enemy container and WeaponData references.")
		set_process(false)
		return
	_register_special_input()
	_enemy_container.child_entered_tree.connect(_on_enemy_child_entered)
	for child in _enemy_container.get_children():
		_connect_enemy(child)


func _process(delta: float) -> void:
	if not is_instance_valid(_player) or _player.is_dead:
		return
	special_energy = minf(100.0, special_energy + passive_energy_regen * special_energy_gain_multiplier * delta)
	if Input.is_action_just_pressed("special_attack"):
		_activate_special()
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	if _attack_cooldown > 0.0:
		return
	var target := _select_target(weapon_data.attack_range + attack_range_bonus)
	if target == null:
		return
	var attack_direction := _face_target(target, weapon_data.attack_interval)
	var damage := weapon_data.damage + damage_bonus + run_damage_bonus
	_spawn_directional_slash(attack_direction, 1.65, 115.0, false)
	target.take_damage(damage)
	_attack_cooldown = weapon_data.attack_interval / maxf(0.25, attack_speed_multiplier)
	attack_landed.emit(String(target.name), damage)


func _select_target(search_radius: float) -> EnemyController:
	var radius_squared := search_radius * search_radius
	var selected: EnemyController
	var best_distance := INF
	var lowest_health_ratio := INF
	for child in _enemy_container.get_children():
		if not child is EnemyController:
			continue
		var enemy := child as EnemyController
		if not enemy.alive:
			continue
		var distance_squared := _player.global_position.distance_squared_to(enemy.global_position)
		if distance_squared > radius_squared:
			continue
		if weapon_data.target_policy == WeaponData.TargetPolicy.LOWEST_HEALTH:
			var ratio := float(enemy.current_health) / maxf(1.0, float(enemy.max_health))
			if ratio < lowest_health_ratio or (is_equal_approx(ratio, lowest_health_ratio) and distance_squared < best_distance):
				selected = enemy
				lowest_health_ratio = ratio
				best_distance = distance_squared
		elif distance_squared < best_distance:
			selected = enemy
			best_distance = distance_squared
	return selected


func _activate_special() -> void:
	if special_energy < weapon_data.special_cost:
		return

	# Lock the player onto the nearest valid target before building the sweep.
	var lead_target := _select_target(weapon_data.special_radius)
	if lead_target == null:
		return
	var special_direction := _face_target(lead_target, 0.55)
	var radius_squared := weapon_data.special_radius * weapon_data.special_radius
	var minimum_forward_dot := cos(deg_to_rad(weapon_data.special_arc_degrees * 0.5))
	var targets: Array[EnemyController] = []

	for child in _enemy_container.get_children():
		if not child is EnemyController:
			continue
		var enemy := child as EnemyController
		if not enemy.alive:
			continue
		var offset := enemy.global_position - _player.global_position
		offset.y = 0.0
		var distance_squared := offset.length_squared()
		if distance_squared > radius_squared or distance_squared < 0.0001:
			continue
		var direction_to_enemy := offset.normalized()
		if direction_to_enemy.dot(special_direction) >= minimum_forward_dot:
			targets.append(enemy)

	if targets.is_empty():
		return

	special_energy -= weapon_data.special_cost
	var damage := maxi(1, roundi(float(weapon_data.damage + damage_bonus + run_damage_bonus) * weapon_data.special_damage_multiplier))
	_spawn_directional_slash(special_direction, minf(weapon_data.special_radius, 2.2), weapon_data.special_arc_degrees, true)
	for enemy in targets:
		if is_instance_valid(enemy) and enemy.alive:
			enemy.take_damage(damage)
	special_activated.emit(weapon_data.special_name, targets.size())


func _face_target(target: EnemyController, lock_duration: float) -> Vector3:
	var direction := target.global_position - _player.global_position
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		return -_player.global_basis.z.normalized()

	direction = direction.normalized()
	_player.face_direction(direction, lock_duration)
	return direction


func _spawn_directional_slash(
	direction: Vector3,
	radius: float,
	sweep_degrees: float,
	is_special: bool
) -> void:
	if direction.length_squared() < 0.0001:
		return
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return

	var segments := 24
	var half_angle := deg_to_rad(clampf(sweep_degrees, 20.0, 300.0) * 0.5)
	var inner_radius := radius * (0.70 if is_special else 0.72)
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	# The crescent is authored in local XY, then its plane is aimed down the
	# attack direction. This keeps the slash visually aligned with combat.
	for segment in range(segments + 1):
		var angle := lerpf(-half_angle, half_angle, float(segment) / float(segments))
		var direction_2d := Vector2(sin(angle), cos(angle))
		vertices.append(Vector3(direction_2d.x * inner_radius, direction_2d.y * inner_radius, 0.0))
		vertices.append(Vector3(direction_2d.x * radius, direction_2d.y * radius, 0.0))
		uvs.append(Vector2(float(segment) / float(segments), 0.0))
		uvs.append(Vector2(float(segment) / float(segments), 1.0))
		if segment < segments:
			var index := segment * 2
			indices.append_array(PackedInt32Array([
				index, index + 1, index + 2,
				index + 1, index + 3, index + 2
			]))

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var slash_mesh := ArrayMesh.new()
	slash_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.emission_enabled = true
	if is_special:
		material.albedo_color = Color(1.0, 0.68, 0.22, 0.88)
		material.emission = Color(1.0, 0.42, 0.08)
	else:
		material.albedo_color = Color(0.98, 0.85, 0.48, 0.92)
		material.emission = Color(1.0, 0.62, 0.18)
	slash_mesh.surface_set_material(0, material)

	var effect := MeshInstance3D.new()
	effect.mesh = slash_mesh
	effect.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scene_root.add_child(effect)
	effect.global_position = _player.global_position + direction * (0.55 if not is_special else 0.85) + Vector3.UP * 1.0
	effect.look_at(effect.global_position + direction, Vector3.UP)
	effect.scale = Vector3(0.78, 0.78, 0.78) if is_special else Vector3(0.58, 0.58, 0.58)

	var tween := effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "scale", Vector3.ONE, 0.14 if not is_special else 0.24)
	tween.tween_property(material, "albedo_color", Color(
		material.albedo_color.r,
		material.albedo_color.g,
		material.albedo_color.b,
		0.0
	), 0.20 if not is_special else 0.32)
	tween.chain().tween_callback(effect.queue_free)


func _on_enemy_child_entered(child: Node) -> void:
	_connect_enemy(child)


func _connect_enemy(child: Node) -> void:
	if child is EnemyController:
		var enemy := child as EnemyController
		if not enemy.died.is_connected(_on_enemy_died):
			enemy.died.connect(_on_enemy_died)


func _on_enemy_died(_enemy: EnemyController) -> void:
	special_energy = minf(100.0, special_energy + energy_per_kill * special_energy_gain_multiplier)


func _register_special_input() -> void:
	if not InputMap.has_action(&"special_attack"):
		InputMap.add_action(&"special_attack")
	for existing in InputMap.action_get_events(&"special_attack"):
		if existing is InputEventKey and existing.physical_keycode == KEY_Q:
			return
	var key := InputEventKey.new()
	key.physical_keycode = KEY_Q
	InputMap.action_add_event(&"special_attack", key)
