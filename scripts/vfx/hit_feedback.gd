## HitFeedback — singleton coordinating shake/hit-stop/damage numbers.
## Registered as autoload "HitFeedback".
extends Node

signal request_camera_shake(intensity: float, duration: float)
signal request_hit_stop(real_seconds: float)
signal request_damage_number(world_position: Vector3, amount: float, color: Color)
signal request_sprite_flash(node: Node3D, color: Color, duration: float)


func enemy_hit(world_position: Vector3, amount: float, sprite_node: Node3D = null, is_critical: bool = false) -> void:
	request_camera_shake.emit(0.15, 0.2)
	request_hit_stop.emit(0.05)
	var color := Color(1, 0.95, 0.2) if is_critical else Color.WHITE
	request_damage_number.emit(world_position, amount, color)
	if sprite_node:
		request_sprite_flash.emit(sprite_node, Color.WHITE, 0.1)


func player_hit(world_position: Vector3, amount: float, sprite_node: Node3D = null) -> void:
	request_camera_shake.emit(0.25, 0.3)
	request_damage_number.emit(world_position, amount, Color(1, 0.2, 0.2))
	if sprite_node:
		request_sprite_flash.emit(sprite_node, Color(1, 0.3, 0.3), 0.15)


func heal(world_position: Vector3, amount: float) -> void:
	request_damage_number.emit(world_position, amount, Color(0.3, 1, 0.3))


func finisher_hit(world_position: Vector3, amount: float, sprite_node: Node3D = null) -> void:
	request_camera_shake.emit(0.3, 0.25)
	request_hit_stop.emit(0.1)
	request_damage_number.emit(world_position, amount, Color(1, 0.7, 0.1))
	if sprite_node:
		request_sprite_flash.emit(sprite_node, Color.WHITE, 0.15)
