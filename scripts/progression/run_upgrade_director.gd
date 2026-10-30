extends Node
class_name RunUpgradeDirector

## Converts skill level-ups into queued, pause-and-pick run upgrade choices.
## Upgrade ranks are deliberately run-only and are reset when a new scene starts.

signal choices_available(upgrades: Array[RunUpgradeData], context_text: String)
signal choices_closed
signal upgrade_applied(upgrade_id: StringName, new_rank: int)

@export_category("References")
@export var progression_path: NodePath
@export var player_path: NodePath
@export var combat_path: NodePath

@export_category("Upgrade Catalogue")
@export var upgrade_catalog: Array[RunUpgradeData] = [
	preload("res://data/upgrades/keen_edge.tres"),
	preload("res://data/upgrades/swift_strikes.tres"),
	preload("res://data/upgrades/fleetfoot.tres"),
	preload("res://data/upgrades/vitality.tres"),
	preload("res://data/upgrades/focused_spirit.tres"),
	preload("res://data/upgrades/long_reach.tres")
]

var upgrade_ranks: Dictionary = {}
var _progression: ProgressionDirector
var _player: PlayerController
var _combat: AutoCombat
var _pending_level_ups: Array[Dictionary] = []
var _current_choices: Array[RunUpgradeData] = []
var _choice_active: bool = false


func _ready() -> void:
	_progression = get_node_or_null(progression_path) as ProgressionDirector
	_player = get_node_or_null(player_path) as PlayerController
	_combat = get_node_or_null(combat_path) as AutoCombat

	if _progression == null or _player == null or _combat == null:
		push_error("RunUpgradeDirector requires valid progression, player and combat references.")
		set_process(false)
		return

	for upgrade in upgrade_catalog:
		if upgrade != null and not upgrade.upgrade_id.is_empty():
			upgrade_ranks[upgrade.upgrade_id] = 0

	_progression.level_up.connect(_on_level_up)
	_player.player_died.connect(_on_player_died)


func _on_level_up(skill_name: String, new_level: int) -> void:
	_pending_level_ups.append({
		"skill_name": skill_name,
		"new_level": new_level
	})
	_show_next_choice()


func _show_next_choice() -> void:
	if _choice_active:
		return

	while not _pending_level_ups.is_empty():
		var level_event: Dictionary = _pending_level_ups.pop_front()
		var available := _get_available_upgrades()
		if available.is_empty():
			continue

		available.shuffle()
		while available.size() > 3:
			available.pop_back()

		_current_choices = available
		_choice_active = true
		get_tree().paused = true
		var context := "%s reached level %d" % [
			String(level_event.get("skill_name", "Skill")).to_upper(),
			int(level_event.get("new_level", 1))
		]
		choices_available.emit(_current_choices, context)
		return

	_choice_active = false
	get_tree().paused = false
	choices_closed.emit()


func choose_upgrade(upgrade_id: StringName) -> void:
	if not _choice_active:
		return

	var selected: RunUpgradeData
	for upgrade in _current_choices:
		if upgrade.upgrade_id == upgrade_id:
			selected = upgrade
			break

	if selected == null:
		return

	var new_rank := int(upgrade_ranks.get(selected.upgrade_id, 0)) + 1
	if new_rank > selected.max_rank:
		return

	_apply_upgrade(selected)
	upgrade_ranks[selected.upgrade_id] = new_rank
	upgrade_applied.emit(selected.upgrade_id, new_rank)

	_choice_active = false
	_current_choices.clear()
	_show_next_choice()


func _get_available_upgrades() -> Array[RunUpgradeData]:
	var available: Array[RunUpgradeData] = []
	for upgrade in upgrade_catalog:
		if upgrade == null or upgrade.upgrade_id.is_empty():
			continue
		if int(upgrade_ranks.get(upgrade.upgrade_id, 0)) < upgrade.max_rank:
			available.append(upgrade)
	return available


func _apply_upgrade(upgrade: RunUpgradeData) -> void:
	match upgrade.effect_type:
		&"damage":
			_combat.run_damage_bonus += maxi(1, roundi(upgrade.effect_per_rank))
		&"attack_speed":
			_combat.attack_speed_multiplier += upgrade.effect_per_rank
		&"move_speed":
			_player.run_speed_multiplier += upgrade.effect_per_rank
		&"max_health":
			var health_bonus := maxi(1, roundi(upgrade.effect_per_rank))
			_player.max_health += health_bonus
			_player.restore_health(health_bonus)
		&"special_gain":
			_combat.special_energy_gain_multiplier += upgrade.effect_per_rank
		&"attack_range":
			_combat.attack_range_bonus += upgrade.effect_per_rank
		_:
			push_warning("Unknown run upgrade effect type: %s" % String(upgrade.effect_type))


func get_upgrade_summary_text() -> String:
	var owned: Array[String] = []
	for upgrade in upgrade_catalog:
		if upgrade == null:
			continue
		var rank := int(upgrade_ranks.get(upgrade.upgrade_id, 0))
		if rank > 0:
			owned.append("%s %d" % [upgrade.display_name, rank])

	if owned.is_empty():
		return "UPGRADES  NONE YET"
	return "UPGRADES  " + "  |  ".join(owned)


func _on_player_died() -> void:
	_pending_level_ups.clear()
	_current_choices.clear()
	_choice_active = false
	if get_tree() != null:
		get_tree().paused = false
	choices_closed.emit()
