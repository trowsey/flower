# Brute: slow, tanky, heavy melee
extends EnemyBase
class_name Brute

var _attack_timer: float = 0.0


func _ready() -> void:
	max_health = 80.0
	move_speed = 1.8
	damage = 18.0
	attack_range = 1.6
	enemy_type = "brute"
	xp_reward = 50.0
	gold_drop_min = 3
	gold_drop_max = 12
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
			_attack_timer = 1.5
