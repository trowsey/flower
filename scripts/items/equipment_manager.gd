## EquipmentManager — manages the 5 equipment slots and applies stat modifiers.
extends Resource
class_name EquipmentManager

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
	for item in slots.values():
		if item == null:
			continue
		for key in item.stat_modifiers.keys():
			totals[key] = totals.get(key, 0.0) + float(item.stat_modifiers[key])
	return totals
