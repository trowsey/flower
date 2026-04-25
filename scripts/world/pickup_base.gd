# Pickup base — common for gold and items
extends Area3D
class_name PickupBase

signal collected(player: Node3D)

@export var hover_speed: float = 2.0
@export var hover_height: float = 0.15

var _t: float = 0.0
var _base_y: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	_base_y = global_position.y


func _process(delta: float) -> void:
	_t += delta
	global_position.y = _base_y + sin(_t * hover_speed) * hover_height


func collect(_player: Node3D) -> void:
	# Override in subclasses
	collected.emit(_player)
	queue_free()
