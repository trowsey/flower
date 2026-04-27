extends Camera3D

@export var offset := Vector3(5, 13, 5)
@export var smooth_speed := 5.0
# Multiplayer: when 2+ players exist, zoom out to keep both in frame
@export var multi_zoom_per_unit_distance: float = 0.5
@export var multi_max_extra_zoom: float = 8.0

var _target: Node3D
var _shake: CameraShake = null
var _hit_stop_end_ms: int = 0
# Cached per-frame so we don't call get_nodes_in_group three times per
# physics tick (was: _get_focus_point + _get_player_spread + size-check).
var _players_cache: Array = []
var _players_cache_frame: int = -1


func _refresh_players_cache() -> void:
	var f := Engine.get_physics_frames()
	if f == _players_cache_frame:
		return
	_players_cache_frame = f
	_players_cache = get_tree().get_nodes_in_group("player")


func _ready() -> void:
	_refresh_players_cache()
	if _players_cache.size() > 0:
		_target = _players_cache[0]
	if _target:
		global_position = _get_focus_point() + offset
		look_at(_get_focus_point())
	_shake = CameraShake.new()
	if not HitFeedback.request_camera_shake.is_connected(_on_request_shake):
		HitFeedback.request_camera_shake.connect(_on_request_shake)
	if not HitFeedback.request_hit_stop.is_connected(_on_request_hit_stop):
		HitFeedback.request_hit_stop.connect(_on_request_hit_stop)


func _get_focus_point() -> Vector3:
	if _players_cache.size() == 0:
		return _target.global_position if _target else Vector3.ZERO
	var sum := Vector3.ZERO
	var n: int = 0
	for p in _players_cache:
		if not is_instance_valid(p):
			continue
		sum += p.global_position
		n += 1
	if n == 0:
		return Vector3.ZERO
	return sum / float(n)


func _get_player_spread() -> float:
	if _players_cache.size() < 2:
		return 0.0
	var center := _get_focus_point()
	var max_d: float = 0.0
	for p in _players_cache:
		if is_instance_valid(p):
			max_d = max(max_d, p.global_position.distance_to(center))
	return max_d


func _on_request_shake(strength: float, duration: float) -> void:
	if _shake:
		_shake.start(strength, duration)


func _on_request_hit_stop(duration: float) -> void:
	# Track end time across overlapping requests. If a longer hit-stop is
	# scheduled while a shorter one is still pending, the earlier timer used
	# to expire and reset Engine.time_scale to 1.0 prematurely.
	var now_ms: int = Time.get_ticks_msec()
	var requested_end: int = now_ms + int(duration * 1000.0)
	if requested_end > _hit_stop_end_ms:
		_hit_stop_end_ms = requested_end
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	if not is_instance_valid(self):
		return
	# Only restore time_scale if no later overlapping request extended the stop.
	if Time.get_ticks_msec() >= _hit_stop_end_ms:
		Engine.time_scale = 1.0


func _physics_process(delta: float) -> void:
	_refresh_players_cache()
	if _players_cache.size() == 0 and not _target:
		return
	var focus: Vector3 = _get_focus_point()
	var zoom_extra: float = clamp(
		_get_player_spread() * multi_zoom_per_unit_distance,
		0.0,
		multi_max_extra_zoom
	)
	var desired: Vector3 = focus + offset + offset.normalized() * zoom_extra
	if _shake:
		desired += _shake.get_offset(delta)
	global_position = global_position.lerp(desired, smooth_speed * delta)
	look_at(focus)
