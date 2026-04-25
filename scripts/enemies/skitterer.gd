# Skitterer: small, fast melee swarm enemy
extends EnemyBase
class_name Skitterer

var _attack_timer: float = 0.0


func _ready() -> void:
	max_health = 12.0
	move_speed = 5.0
	damage = 5.0
	enemy_type = "skitterer"
	xp_reward = 10.0
	super._ready()


func _physics_process(delta: float) -> void:
	if not alive or not player:
		return
	if _attack_timer > 0.0:
		_attack_timer -= delta
	var dist := distance_to_player()
	if dist > attack_range:
		var dir: Vector3 = (player.global_position - global_position)
		dir.y = 0.0
		velocity = dir.normalized() * move_speed
		move_and_slide()
	else:
		velocity = Vector3.ZERO
		if _attack_timer <= 0.0 and player.has_method("take_damage"):
			player.take_damage(damage)
			_attack_timer = 0.8
