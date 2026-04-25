## Inventory — fixed-size grid storage for items collected by the player.
extends Resource
class_name Inventory

const CAPACITY := 30

signal items_changed
signal item_added(item: ItemResource, slot: int)
signal item_removed(item: ItemResource, slot: int)

var slots: Array = []


func _init() -> void:
	slots.resize(CAPACITY)
	for i in CAPACITY:
		slots[i] = null


func is_full() -> bool:
	for slot in slots:
		if slot == null:
			return false
	return true


func first_empty_slot() -> int:
	for i in CAPACITY:
		if slots[i] == null:
			return i
	return -1


func add(item: ItemResource) -> int:
	var slot := first_empty_slot()
	if slot < 0:
		return -1
	slots[slot] = item
	item_added.emit(item, slot)
	items_changed.emit()
	return slot


func remove(slot: int) -> ItemResource:
	if slot < 0 or slot >= CAPACITY:
		return null
	var item: ItemResource = slots[slot]
	if item == null:
		return null
	slots[slot] = null
	item_removed.emit(item, slot)
	items_changed.emit()
	return item


func get_item(slot: int) -> ItemResource:
	if slot < 0 or slot >= CAPACITY:
		return null
	return slots[slot]
