# Cult Healer: stays back and heals nearest other enemy on cooldown
extends EnemyBase
class_name CultHealer

@export var heal_amount: float = 10.0
@export var heal_cooldown: float = 2.5
@export var heal_radius: float = 8.0
@export var keep_distance_min: float = 5.0
@export var keep_distance_max: float = 7.0
@export var flee_distance: float = 3.0

var _heal_timer: float = 0.0


func _ready() -> void:
	max_health = 25.0
	move_speed = 3.0
	damage = 0.0
	enemy_type = "healer"
	xp_reward = 40.0
	gold_drop_min = 4
	gold_drop_max = 10
	super._ready()


func _physics_process(delta: float) -> void:
	if not alive or not player:
		return
	if _heal_timer > 0.0:
		_heal_timer -= delta
	var dist := distance_to_player()
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	if dist < flee_distance:
		velocity = -to_player.normalized() * move_speed
		move_and_slide()
	elif dist < keep_distance_min:
		velocity = -to_player.normalized() * move_speed * 0.5
		move_and_slide()
	elif dist > keep_distance_max:
		velocity = to_player.normalized() * move_speed * 0.5
		move_and_slide()
	else:
		velocity = Vector3.ZERO

	if _heal_timer <= 0.0:
		if _try_heal():
			_heal_timer = heal_cooldown


func _try_heal() -> bool:
	var target: EnemyBase = _find_heal_target()
	if target == null:
		return false
	target.health = min(target.max_health, target.health + heal_amount)
	target.health_changed.emit(target.health)
	return true


func _find_heal_target() -> EnemyBase:
	var best: EnemyBase = null
	var best_score: float = -1.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or not is_instance_valid(e) or not (e is EnemyBase):
			continue
		var enemy_base: EnemyBase = e
		if not enemy_base.alive:
			continue
		if enemy_base.health >= enemy_base.max_health:
			continue
		var d: float = global_position.distance_to(enemy_base.global_position)
		if d > heal_radius:
			continue
		# Prefer most-wounded then closest
		var missing: float = enemy_base.max_health - enemy_base.health
		var score: float = missing - d
		if score > best_score:
			best_score = score
			best = enemy_base
	return best
