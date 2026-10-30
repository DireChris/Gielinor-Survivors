extends Resource
class_name SlayerContractData

## Static definition for a Slayer contract.

@export var contract_id: StringName = &""
@export var display_name: String = ""
@export var target_monster_id: StringName = &""
@export_range(1, 10000, 1) var target_count: int = 15
@export_range(0, 100000, 1) var xp_per_kill: int = 5
@export_range(0, 100000, 1) var completion_bonus_xp: int = 100
@export var completion_rewards: Dictionary = {"coins": 75}
