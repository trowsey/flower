## EquipmentManager — manages the 5 equipment slots and applies stat modifiers.
extends Resource
class_name EquipmentManager

const ItemSetScript = preload("res://scripts/items/item_set.gd")

signal equipment_changed(slot_type: int, new_item: ItemResource, old_item: ItemResource)

var slots: Dictionary = {
	ItemResource.ItemType.WEAPON: null,
	ItemResource.ItemType.ARMOR: null,
	ItemResource.ItemType.HELMET: null,
	ItemResource.ItemType.RING: null,
	ItemResource.ItemType.AMULET: null,
}


func get_equipped(slot_type: int) -> ItemResource:
	return slots.get(slot_type, null)


func set_equipped(slot_type: int, item: ItemResource) -> ItemResource:
	if not slots.has(slot_type):
		return null
	if item != null and item.item_type != slot_type:
		return null
	var old: ItemResource = slots[slot_type]
	slots[slot_type] = item
	equipment_changed.emit(slot_type, item, old)
	return old


func get_total_modifiers() -> Dictionary:
	var totals: Dictionary = {}
	var set_counts: Dictionary = {}
	for item in slots.values():
		if item == null:
			continue
		for key in item.stat_modifiers.keys():
			totals[key] = totals.get(key, 0.0) + float(item.stat_modifiers[key])
		if item.set_id != "":
			set_counts[item.set_id] = int(set_counts.get(item.set_id, 0)) + 1
	# Apply set bonuses for each active set
	for set_id in set_counts.keys():
		var count: int = set_counts[set_id]
		var set_def = ItemSetScript.by_id(set_id)
		if set_def == null:
			continue
		for threshold in set_def.bonuses.keys():
			if count >= int(threshold):
				var bonus: Dictionary = set_def.bonuses[threshold]
				for key in bonus.keys():
					totals[key] = totals.get(key, 0.0) + float(bonus[key])
	return totals


# Returns dict { set_id: piece_count } for currently equipped sets.
func get_active_sets() -> Dictionary:
	var counts: Dictionary = {}
	for item in slots.values():
		if item == null or item.set_id == "":
			continue
		counts[item.set_id] = int(counts.get(item.set_id, 0)) + 1
	return counts
