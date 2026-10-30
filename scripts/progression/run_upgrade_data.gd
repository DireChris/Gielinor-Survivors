extends Resource
class_name RunUpgradeData

## Static definition for one selectable run upgrade.
@export var upgrade_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var effect_type: StringName = &""
@export_range(1, 10, 1) var max_rank: int = 5
@export var effect_per_rank: float = 1.0
