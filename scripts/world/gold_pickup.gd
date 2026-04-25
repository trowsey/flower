extends "res://scripts/world/pickup_base.gd"
class_name GoldPickup

var amount: int = 1


func set_amount(a: int) -> void:
	amount = a


func collect(player: Node3D) -> void:
	if player and player.has_method("add_gold"):
		player.add_gold(amount)
	collected.emit(player)
	queue_free()
