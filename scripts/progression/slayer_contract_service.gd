extends Node
class_name SlayerContractService

## Owns current contract progress. Rewards are emitted for ProgressionDirector
## and InventoryService to consume; this service does not own player XP/items.

signal progress_changed(current_kills: int, required_kills: int)
signal contract_completed(rewards: Dictionary)

@export var contract_data: SlayerContractData

var current_kills: int = 0
var completed: bool = false


func _ready() -> void:
	if contract_data == null:
		push_error("SlayerContractService requires a SlayerContractData resource.")


func register_kill(monster_id: StringName) -> int:
	if contract_data == null or completed or monster_id != contract_data.target_monster_id:
		return 0

	current_kills = mini(contract_data.target_count, current_kills + 1)
	var xp_awarded := contract_data.xp_per_kill
	progress_changed.emit(current_kills, contract_data.target_count)

	if current_kills >= contract_data.target_count:
		completed = true
		xp_awarded += contract_data.completion_bonus_xp
		contract_completed.emit(contract_data.completion_rewards.duplicate(true))

	return xp_awarded


func get_status_text() -> String:
	if contract_data == null:
		return "NO CONTRACT"
	if completed:
		return "%s  COMPLETE" % contract_data.display_name.to_upper()
	return "%s  %d/%d" % [
		contract_data.display_name.to_upper(),
		current_kills,
		contract_data.target_count
	]
