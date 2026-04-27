## CameraShake — shared screen shake helper used by Camera3D scripts.
extends RefCounted
class_name CameraShake

var time_left: float = 0.0
var intensity: float = 0.0
var max_duration: float = 0.0


func start(intensity_units: float, duration: float) -> void:
	intensity = clamp(intensity + intensity_units, 0.0, 0.4)
	time_left = max(time_left, duration)
	max_duration = max(max_duration, duration)


func get_offset(delta: float) -> Vector3:
	if time_left <= 0.0:
		intensity = 0.0
		max_duration = 0.0
		return Vector3.ZERO
	time_left -= delta
	var ratio: float = time_left / max_duration if max_duration > 0.0 else 0.0
	var current := intensity * ratio
	return Vector3(
		randf_range(-current, current),
		randf_range(-current, current),
		randf_range(-current, current)
	)


func is_active() -> bool:
	return time_left > 0.0
