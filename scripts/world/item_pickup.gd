extends "res://scripts/world/pickup_base.gd"
class_name ItemPickup

var item: ItemResource = null


func set_item(i: ItemResource) -> void:
	item = i


func collect(player: Node3D) -> void:
	if player and player.has_method("add_item") and item:
		if player.add_item(item):
			collected.emit(player)
			queue_free()
