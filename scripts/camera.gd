extends Camera3D

@export var offset := Vector3(5, 13, 5)
@export var smooth_speed := 5.0

var _target: Node3D


func _ready() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_target = players[0]
	if _target:
		global_position = _target.global_position + offset
		look_at(_target.global_position)


func _physics_process(delta: float) -> void:
	if not _target:
		return
	var desired := _target.global_position + offset
	global_position = global_position.lerp(desired, smooth_speed * delta)
	look_at(_target.global_position)
