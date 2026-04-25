# Soul-draining demon. Rushes player, latches on, drains soul over time.
extends EnemyBase
class_name DemonBase

@export var latch_distance: float = 1.0
@export var detach_break_distance: float = 4.0
@export var demon_max_health: float = 50.0

enum DemonState { ROAMING, CHASING, LATCHED, DEAD }

var demon_state: int = DemonState.ROAMING
var _roam_target: Vector3 = Vector3.ZERO
var _roam_timer: float = 0.0


func _ready() -> void:
	max_health = demon_max_health
	enemy_type = "demon_drainer"
	super._ready()
	_pick_roam_target()


func _physics_process(delta: float) -> void:
	if not alive:
		return
	if _hit_flash_remaining > 0.0:
		_hit_flash_remaining -= delta
	if not player:
		return

	match demon_state:
		DemonState.ROAMING:
			_process_roaming(delta)
		DemonState.CHASING:
			_process_chasing(delta)
		DemonState.LATCHED:
			_process_latched(delta)


func _process_roaming(delta: float) -> void:
	_roam_timer -= delta
	if _roam_timer <= 0.0:
		_pick_roam_target()
	if distance_to_player() < 8.0:
		demon_state = DemonState.CHASING
		return
	var dir: Vector3 = (_roam_target - global_position)
	dir.y = 0.0
	if dir.length() < 0.5:
		_pick_roam_target()
		return
	velocity = dir.normalized() * (move_speed * 0.4)
	move_and_slide()


func _process_chasing(_delta: float) -> void:
	if distance_to_player() > 12.0:
		demon_state = DemonState.ROAMING
		return
	var dir: Vector3 = player.global_position - global_position
	dir.y = 0.0
	if dir.length() <= latch_distance:
		_try_latch()
		return
	velocity = dir.normalized() * move_speed
	move_and_slide()


func _process_latched(_delta: float) -> void:
	if not player or not is_instance_valid(player):
		_release_latch()
		return
	# Stick to player
	global_position = player.global_position + Vector3(0.6, 0.3, 0.0)
	velocity = Vector3.ZERO
	if distance_to_player() > detach_break_distance:
		_release_latch()


func _try_latch() -> void:
	if not has_node("/root/DemonManager"):
		return
	var dm := get_node("/root/DemonManager")
	if dm.request_latch(self, player):
		demon_state = DemonState.LATCHED


func _release_latch() -> void:
	if has_node("/root/DemonManager"):
		get_node("/root/DemonManager").release_latch(self)
	demon_state = DemonState.CHASING


func take_damage(amount: float) -> void:
	super.take_damage(amount)
	if demon_state == DemonState.LATCHED and alive:
		_release_latch()


func _pick_roam_target() -> void:
	_roam_target = global_position + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0))
	_roam_timer = randf_range(2.0, 4.0)
