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
	var damage := weapon_data.damage + damage_bonus + run_damage_bonus
	target.take_damage(damage)
	_attack_cooldown = weapon_data.attack_interval / maxf(0.25, attack_speed_multiplier)
	_player.rotation.y = atan2(
		_player.global_position.x - target.global_position.x,
		_player.global_position.z - target.global_position.z
	)
	_spawn_impact(target.global_position, 0.72)
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
	var radius_squared := weapon_data.special_radius * weapon_data.special_radius
	var targets: Array[EnemyController] = []
	for child in _enemy_container.get_children():
		if child is EnemyController:
			var enemy := child as EnemyController
			if enemy.alive and _player.global_position.distance_squared_to(enemy.global_position) <= radius_squared:
				targets.append(enemy)
	if targets.is_empty():
		return
	special_energy -= weapon_data.special_cost
	var damage := maxi(1, roundi(float(weapon_data.damage + damage_bonus + run_damage_bonus) * weapon_data.special_damage_multiplier))
	for enemy in targets:
		if is_instance_valid(enemy) and enemy.alive:
			enemy.take_damage(damage)
	_spawn_impact(_player.global_position, weapon_data.special_radius)
	special_activated.emit(weapon_data.special_name, targets.size())


func _spawn_impact(world_position: Vector3, radius: float) -> void:
	var effect := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = radius * 0.72
	ring.outer_radius = radius
	effect.mesh = ring
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.72, 0.25, 0.9)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(1.0, 0.48, 0.12)
	effect.material_override = material
	get_tree().current_scene.add_child(effect)
	effect.global_position = world_position + Vector3.UP * 0.12
	effect.rotation.x = PI / 2.0
	effect.scale = Vector3.ONE * 0.35
	var tween := effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "scale", Vector3.ONE, 0.22)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.35)
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
