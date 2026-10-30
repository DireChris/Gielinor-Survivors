extends Resource
class_name DropEntryData

## One independently rolled entry in a monster's drop table.

@export var item_id: StringName = &""
@export_range(0.0, 1.0, 0.01) var drop_chance: float = 1.0
@export_range(1, 999, 1) var minimum_quantity: int = 1
@export_range(1, 999, 1) var maximum_quantity: int = 1


func roll_quantity() -> int:
	if item_id.is_empty() or randf() > drop_chance:
		return 0
	return randi_range(minimum_quantity, maxi(minimum_quantity, maximum_quantity))
