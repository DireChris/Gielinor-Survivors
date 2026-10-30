extends Node
class_name AutoCombat

## Automatically attacks the nearest eligible enemy using the equipped
## WeaponData resource. Q spends special energy on a small area attack.

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

var _player: PlayerController
var _enemy_container: Node3D
var _attack_cooldown: float = 0.0


func _ready() -> void:
	_player = get_node_or_null(player_path) as PlayerController
	_enemy_container = get_node_or_null(enemy_container_path) as Node3D

	if _player == null:
		push_error("AutoCombat: player_path must point to a PlayerController.")
		set_process(false)
		return

	if _enemy_container == null:
		push_error("AutoCombat: enemy_container_path must point to a Node3D.")
		set_process(false)
		return

	if weapon_data == null:
		push_error("AutoCombat: weapon_data has not been assigned.")
		set_process(false)
		return

	_register_special_input()
	_enemy_container.child_entered_tree.connect(_on_enemy_child_entered)

	for child in _enemy_container.get_children():
		_connect_enemy(child)


func _process(delta: float) -> void:
	if not is_instance_valid(_player) or _player.is_dead:
		return

	special_energy = minf(100.0, special_energy + passive_energy_regen * delta)

	if Input.is_action_just_pressed("special_attack"):
		_activate_special()

	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	if _attack_cooldown > 0.0:
		return

	var target := _select_target(weapon_data.attack_range)
	if target == null:
		return

	target.take_damage(weapon_data.damage)
	_attack_cooldown = weapon_data.attack_interval
	attack_landed.emit(String(target.name), weapon_data.damage)


func _select_target(search_radius: float) -> EnemyController:
	var search_radius_squared := search_radius * search_radius
	var selected: EnemyController
	var shortest_distance_squared := INF
	var lowest_health_ratio := INF

	for child in _enemy_container.get_children():
		if not child is EnemyController:
			continue

		var enemy := child as EnemyController
		if not enemy.alive:
			continue

		var distance_squared := _player.global_position.distance_squared_to(enemy.global_position)
		if distance_squared > search_radius_squared:
			continue

		if weapon_data.target_policy == WeaponData.TargetPolicy.LOWEST_HEALTH:
			var health_ratio := float(enemy.current_health) / maxf(1.0, float(enemy.max_health))
			if health_ratio < lowest_health_ratio or (
				is_equal_approx(health_ratio, lowest_health_ratio)
				and distance_squared < shortest_distance_squared
			):
				selected = enemy
				lowest_health_ratio = health_ratio
				shortest_distance_squared = distance_squared
		elif distance_squared < shortest_distance_squared:
			selected = enemy
			shortest_distance_squared = distance_squared

	return selected


func _activate_special() -> void:
	if special_energy < weapon_data.special_cost:
		return

	var radius_squared := weapon_data.special_radius * weapon_data.special_radius
	var targets: Array[EnemyController] = []

	for child in _enemy_container.get_children():
		if not child is EnemyController:
			continue

		var enemy := child as EnemyController
		if not enemy.alive:
			continue

		if _player.global_position.distance_squared_to(enemy.global_position) <= radius_squared:
			targets.append(enemy)

	if targets.is_empty():
		return

	special_energy -= weapon_data.special_cost
	var special_damage := maxi(
		1,
		roundi(float(weapon_data.damage) * weapon_data.special_damage_multiplier)
	)

	for enemy in targets:
		if is_instance_valid(enemy) and enemy.alive:
			enemy.take_damage(special_damage)

	special_activated.emit(weapon_data.special_name, targets.size())


func _on_enemy_child_entered(child: Node) -> void:
	_connect_enemy(child)


func _connect_enemy(child: Node) -> void:
	if not child is EnemyController:
		return

	var enemy := child as EnemyController
	if not enemy.died.is_connected(_on_enemy_died):
		enemy.died.connect(_on_enemy_died)


func _on_enemy_died(_enemy: EnemyController) -> void:
	special_energy = minf(100.0, special_energy + energy_per_kill)


func _register_special_input() -> void:
	var action_name: StringName = &"special_attack"
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for existing_event in InputMap.action_get_events(action_name):
		if existing_event is InputEventKey and existing_event.physical_keycode == KEY_Q:
			return

	var key_event := InputEventKey.new()
	key_event.physical_keycode = KEY_Q
	InputMap.action_add_event(action_name, key_event)
