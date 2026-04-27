## TransitionManager — singleton for screen fades and player repositioning.
## Registered as autoload "TransitionManager".
extends Node

signal transition_started
signal transition_finished

var _transitioning := false
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect


func _ready() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)


func is_transitioning() -> bool:
	return _transitioning


func fade_to_room(player: Node3D, target_position: Vector3, fade_duration: float = 0.3) -> void:
	if _transitioning:
		return
	_transitioning = true
	transition_started.emit()
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, fade_duration)
	await tween.finished
	if is_instance_valid(player):
		player.global_position = target_position
	var tween2 := create_tween()
	tween2.tween_property(_fade_rect, "color:a", 0.0, fade_duration)
	await tween2.finished
	_transitioning = false
	transition_finished.emit()


func fade_to_floor(player: Node3D, target_position: Vector3, fade_duration: float = 0.8) -> void:
	if _transitioning:
		return
	_transitioning = true
	transition_started.emit()
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, fade_duration)
	await tween.finished
	if is_instance_valid(player):
		player.global_position = target_position
	var tween2 := create_tween()
	tween2.tween_property(_fade_rect, "color:a", 0.0, fade_duration)
	await tween2.finished
	_transitioning = false
	transition_finished.emit()
