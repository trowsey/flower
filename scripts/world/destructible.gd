# Destructible object: takes hits, drops loot on break
extends StaticBody3D
class_name Destructible

signal destroyed(node: Node3D)

@export var max_health: float = 1.0
@export var gold_min: int = 0
@export var gold_max: int = 3
@export var item_drop_chance: float = 0.05

var health: float = 1.0
var alive: bool = true


func _ready() -> void:
	add_to_group("destructibles")
	collision_layer = 1
	health = max_health


func take_damage(amount: float) -> void:
	if not alive:
		return
	health -= amount
	if health <= 0.0:
		break_apart()


func break_apart() -> void:
	if not alive:
		return
	alive = false
	destroyed.emit(self)
	var gold := randi_range(gold_min, gold_max)
	if gold > 0:
		var pickup_scene := load("res://scenes/items/gold_pickup.tscn")
		if pickup_scene:
			var p: Node = pickup_scene.instantiate()
			get_tree().current_scene.add_child(p)
			p.global_position = global_position
			if p.has_method("set_amount"):
				p.set_amount(gold)
	if randf() < item_drop_chance:
		var item_scene := load("res://scenes/items/item_pickup.tscn")
		if item_scene:
			var p: Node = item_scene.instantiate()
			get_tree().current_scene.add_child(p)
			p.global_position = global_position
			if p.has_method("set_item"):
				p.set_item(ItemFactory.make_random())
	queue_free()
