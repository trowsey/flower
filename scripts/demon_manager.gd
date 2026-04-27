## DemonManager — singleton coordinating the global one-at-a-time latch lock.
## Registered as autoload "DemonManager".
extends Node

signal latched(demon: Node3D)
signal released(demon: Node3D)

var _latched_demon: Node3D = null
var _latched_target: Node = null


func request_latch(demon: Node3D, target: Node = null) -> bool:
	# Defensive: if the previous latched demon was freed without releasing
	# (shouldn't happen, but a wave wipe / queue_free chain could do it),
	# clear the stale reference so a fresh demon can latch.
	if _latched_demon != null and not is_instance_valid(_latched_demon):
		_latched_demon = null
		_latched_target = null
	if _latched_demon != null:
		return false
	_latched_demon = demon
	_latched_target = target
	if target and target.has_method("begin_soul_drain"):
		if not target.begin_soul_drain(demon):
			_latched_demon = null
			_latched_target = null
			return false
	latched.emit(demon)
	return true


func release_latch(demon: Node3D) -> void:
	if _latched_demon == demon:
		var t := _latched_target
		_latched_demon = null
		_latched_target = null
		if t and t.has_method("end_soul_drain"):
			t.end_soul_drain()
		released.emit(demon)


func force_release() -> void:
	if _latched_demon != null:
		release_latch(_latched_demon)


func is_latch_available() -> bool:
	return _latched_demon == null


func get_latched_demon() -> Node3D:
	return _latched_demon
