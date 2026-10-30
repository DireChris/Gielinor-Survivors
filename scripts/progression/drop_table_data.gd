extends Resource
class_name DropTableData

## Data-driven drop table. Each entry rolls independently.

@export var entries: Array[Resource] = []


func roll_drops() -> Dictionary:
	var results: Dictionary = {}
	for resource_entry in entries:
		var entry := resource_entry as DropEntryData
		if entry == null:
			continue
		var quantity := entry.roll_quantity()
		if quantity <= 0:
			continue
		results[entry.item_id] = int(results.get(entry.item_id, 0)) + quantity
	return results
