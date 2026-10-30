extends Node
class_name InventoryService

## Run-scoped item storage. Mutations are validated and announced centrally.

signal inventory_changed(items: Dictionary)

var items: Dictionary = {}


func add_item(item_id: StringName, quantity: int = 1) -> void:
	if item_id.is_empty() or quantity <= 0:
		return
	items[item_id] = int(items.get(item_id, 0)) + quantity
	inventory_changed.emit(items.duplicate(true))


func get_item_count(item_id: StringName) -> int:
	return maxi(0, int(items.get(item_id, 0)))


func has_items(costs: Dictionary) -> bool:
	for item_id in costs:
		var cost := int(costs[item_id])
		if cost < 0 or get_item_count(StringName(item_id)) < cost:
			return false
	return true


func remove_items(costs: Dictionary) -> bool:
	# Check every cost first so crafting cannot partially consume materials.
	if not has_items(costs):
		return false

	for item_id in costs:
		var key := StringName(item_id)
		var remaining := get_item_count(key) - int(costs[item_id])
		if remaining <= 0:
			items.erase(key)
		else:
			items[key] = remaining

	inventory_changed.emit(items.duplicate(true))
	return true


func get_items_snapshot() -> Dictionary:
	return items.duplicate(true)
