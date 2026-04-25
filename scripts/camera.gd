extends Camera3D

@export var offset := Vector3(5, 13, 5)
@export var smooth_speed := 5.0

var _target: Node3D
var _shake: CameraShake = null
var _hit_stop_remaining: float = 0.0


func _ready() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_target = players[0]
	if _target:
		global_position = _target.global_position + offset
		look_at(_target.global_position)
	_shake = CameraShake.new()
	if has_node("/root/HitFeedback"):
		var hf := get_node("/root/HitFeedback")
		hf.request_camera_shake.connect(_on_request_shake)
		hf.request_hit_stop.connect(_on_request_hit_stop)


func _on_request_shake(strength: float, duration: float) -> void:
	if _shake:
		_shake.start(strength, duration)


func _on_request_hit_stop(duration: float) -> void:
	_hit_stop_remaining = max(_hit_stop_remaining, duration)
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	_hit_stop_remaining = 0.0
	Engine.time_scale = 1.0


func _physics_process(delta: float) -> void:
	if not _target:
		return
	var desired := _target.global_position + offset
	if _shake:
		desired += _shake.get_offset(delta)
	global_position = global_position.lerp(desired, smooth_speed * delta)
	look_at(_target.global_position)
