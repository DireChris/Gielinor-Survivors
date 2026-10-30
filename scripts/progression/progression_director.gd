extends Node
class_name ProgressionDirector

## Run progression, Slayer contracts, drops, crafting and persistent profile.
## Run XP is banked into the local profile when the player is defeated.

signal progression_changed
signal level_up(skill_name: String, new_level: int)
signal profile_saved

const PROFILE_PATH := "user://gielinor_survivors_profile.json"
const SKILLS := ["Attack", "Strength", "Defence", "Hitpoints", "Slayer"]

@export var player_path: NodePath
@export var enemy_container_path: NodePath
@export var combat_path: NodePath
@export var inventory_service_path: NodePath
@export var slayer_service_path: NodePath

var run_skill_xp: Dictionary = {}
var profile_skill_xp: Dictionary = {}
var lifetime_kills: int = 0
var bronze_edge_unlocked: bool = false
var weapon_damage_bonus: int = 0

var _player: PlayerController
var _enemy_container: Node3D
var _combat: AutoCombat
var _inventory: InventoryService
var _slayer_contract: SlayerContractService


func _ready() -> void:
	for skill in SKILLS:
		run_skill_xp[skill] = 0
	_load_profile()
	_player = get_node_or_null(player_path) as PlayerController
	_enemy_container = get_node_or_null(enemy_container_path) as Node3D
	_combat = get_node_or_null(combat_path) as AutoCombat
	_inventory = get_node_or_null(inventory_service_path) as InventoryService
	_slayer_contract = get_node_or_null(slayer_service_path) as SlayerContractService

	if _player == null or _enemy_container == null or _inventory == null or _slayer_contract == null:
		push_error("ProgressionDirector requires player, enemy container, InventoryService and SlayerContractService references.")
		set_process(false)
		return

	_player.player_died.connect(_on_player_died)
	_slayer_contract.contract_completed.connect(_on_slayer_contract_completed)
	_enemy_container.child_entered_tree.connect(_on_enemy_child_entered)
	for child in _enemy_container.get_children():
		_connect_enemy(child)
	progression_changed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_C:
			craft_bronze_edge()


func _on_enemy_child_entered(child: Node) -> void:
	_connect_enemy(child)


func _connect_enemy(child: Node) -> void:
	if child is EnemyController:
		var enemy := child as EnemyController
		if not enemy.died.is_connected(_on_enemy_died):
			enemy.died.connect(_on_enemy_died)


func _on_enemy_died(enemy: EnemyController) -> void:
	lifetime_kills += 1
	_award_xp("Attack", 4.0)
	_award_xp("Strength", 4.0)
	_award_xp("Defence", 2.0)
	_award_xp("Hitpoints", 1.33)

	var slayer_xp := _slayer_contract.register_kill(enemy.monster_id)
	if slayer_xp > 0:
		_award_xp("Slayer", float(slayer_xp))

	_roll_drops(enemy)
	progression_changed.emit()


func _roll_drops(enemy: EnemyController) -> void:
	if enemy.drop_table == null:
		return
	var drops := enemy.drop_table.roll_drops()
	for item_id in drops:
		_inventory.add_item(StringName(item_id), int(drops[item_id]))


func _on_slayer_contract_completed(rewards: Dictionary) -> void:
	for item_id in rewards:
		_inventory.add_item(StringName(item_id), int(rewards[item_id]))


func _award_xp(skill: String, amount: float) -> void:
	if not run_skill_xp.has(skill):
		return
	var old_level := get_skill_level(skill)
	run_skill_xp[skill] = float(run_skill_xp[skill]) + amount
	var new_level := get_skill_level(skill)
	if new_level > old_level:
		# A large XP award can cross more than one threshold. Emit each level so
		# the run-upgrade director can queue one deliberate choice per level.
		for reached_level in range(old_level + 1, new_level + 1):
			level_up.emit(skill, reached_level)
		if skill == "Hitpoints" and is_instance_valid(_player):
			var health_increase := 2 * (new_level - old_level)
			_player.max_health += health_increase
			_player.restore_health(health_increase)
		if skill == "Attack":
			weapon_damage_bonus = maxi(0, new_level - 1) / 10
	progression_changed.emit()


func get_total_xp(skill: String) -> float:
	return float(profile_skill_xp.get(skill, 0.0)) + float(run_skill_xp.get(skill, 0.0))


func get_skill_level(skill: String) -> int:
	var xp := get_total_xp(skill)
	var level := 1
	for candidate in range(2, 100):
		if xp < _xp_for_level(candidate):
			break
		level = candidate
	return level


func _xp_for_level(level: int) -> int:
	var points := 0
	for current in range(1, level):
		points += floori(float(current) + 300.0 * pow(2.0, float(current) / 7.0))
	return floori(float(points) / 4.0)


func craft_bronze_edge() -> void:
	if bronze_edge_unlocked:
		return
	var material_costs := {
		&"copper_ore": 5,
		&"bones": 3,
		&"coins": 30
	}
	if not _inventory.remove_items(material_costs):
		return

	bronze_edge_unlocked = true
	weapon_damage_bonus += 3
	progression_changed.emit()


func get_progression_text() -> String:
	var attack_level := get_skill_level("Attack")
	var strength_level := get_skill_level("Strength")
	var defence_level := get_skill_level("Defence")
	var hp_level := get_skill_level("Hitpoints")
	var slayer_text := _slayer_contract.get_status_text()
	return "SKILLS  ATK %d  STR %d  DEF %d  HP %d\nSLAYER  %s\nLOOT  COINS %d  ORE %d  BONES %d\nBRONZE EDGE  %s  (C TO CRAFT)" % [
		attack_level, strength_level, defence_level, hp_level,
		slayer_text,
		_inventory.get_item_count(&"coins"),
		_inventory.get_item_count(&"copper_ore"),
		_inventory.get_item_count(&"bones"),
		"OWNED" if bronze_edge_unlocked else "5 ORE + 3 BONES + 30 COINS"
	]


func _on_player_died() -> void:
	for skill in SKILLS:
		profile_skill_xp[skill] = float(profile_skill_xp.get(skill, 0.0)) + float(run_skill_xp.get(skill, 0.0))
		run_skill_xp[skill] = 0.0
	_save_profile()
	progression_changed.emit()


func _load_profile() -> void:
	for skill in SKILLS:
		profile_skill_xp[skill] = 0.0
	if not FileAccess.file_exists(PROFILE_PATH):
		return

	var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not open the saved profile.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_warning("Saved profile was invalid; starting with a fresh profile.")
		return
	var data: Dictionary = parsed
	if int(data.get("schema_version", 0)) != 1:
		push_warning("Saved profile version is unsupported; starting with a fresh profile.")
		return
	var saved_xp: Variant = data.get("permanent_skill_xp", {})
	if saved_xp is Dictionary:
		for skill in SKILLS:
			profile_skill_xp[skill] = maxf(0.0, float(saved_xp.get(skill, 0.0)))
	lifetime_kills = maxi(0, int(data.get("lifetime_kills", 0)))
	bronze_edge_unlocked = bool(data.get("bronze_edge_unlocked", false))


func _save_profile() -> void:
	var data := {
		"schema_version": 1,
		"permanent_skill_xp": profile_skill_xp,
		"lifetime_kills": lifetime_kills,
		"bronze_edge_unlocked": bronze_edge_unlocked
	}
	var temporary_path := PROFILE_PATH + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write the profile save file.")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	file = null
	if FileAccess.file_exists(PROFILE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE_PATH))
	var error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporary_path),
		ProjectSettings.globalize_path(PROFILE_PATH)
	)
	if error != OK:
		push_error("Could not finalize the profile save (error %d)." % error)
		return
	profile_saved.emit()
