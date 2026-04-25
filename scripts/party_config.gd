# PartyConfig — persists character selection and party state across scenes.
# Registered as autoload "PartyConfig". See ADR-008 in docs/architecture.md.
extends Node

const CharacterClassScript = preload("res://scripts/items/character_class.gd")

# Each entry: { "character_class_id": int, "device_id": int }
# By default, P1 is mouse+keyboard+device 0, no P2.
var slots: Array = [
	{"character_class_id": CharacterClassScript.Id.SARAH, "device_id": -1},
]


func clear() -> void:
	slots = []


func add_slot(class_id: int, device_id: int) -> void:
	slots.append({"character_class_id": class_id, "device_id": device_id})


func set_solo(class_id: int) -> void:
	slots = [{"character_class_id": class_id, "device_id": -1}]


func set_two_player(p1_class: int, p2_class: int, p1_device: int = -1, p2_device: int = 0) -> void:
	# When 2P: P1 uses kbd+joy0, P2 uses joy1 (or whichever device_id is supplied)
	slots = [
		{"character_class_id": p1_class, "device_id": p1_device},
		{"character_class_id": p2_class, "device_id": p2_device},
	]


func player_count() -> int:
	return slots.size()


func get_slot(index: int) -> Dictionary:
	if index < 0 or index >= slots.size():
		return {}
	return slots[index]
