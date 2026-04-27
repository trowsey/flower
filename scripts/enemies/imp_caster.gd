# Imp Caster: ranged enemy that lobs simple projectiles
extends EnemyBase
class_name ImpCaster

@export var cast_range: float = 6.0
@export var cast_cooldown: float = 2.5
@export var projectile_damage: float = 8.0

var _cast_timer: float = 0.0


func _ready() -> void:
	max_health = 20.0
	move_speed = 2.0
	enemy_type = "imp_caster"
	super._ready()


func _physics_process(delta: float) -> void:
	if not alive or not player:
		return
	if _cast_timer > 0.0:
		_cast_timer -= delta
	var dist := distance_to_player()
	if dist > cast_range + 1.0:
		# Move toward player
		var dir: Vector3 = (player.global_position - global_position)
		dir.y = 0.0
		velocity = dir.normalized() * move_speed
		move_and_slide()
	elif dist < cast_range - 2.0:
		# Kite away
		var dir: Vector3 = (global_position - player.global_position)
		dir.y = 0.0
		velocity = dir.normalized() * move_speed
		move_and_slide()
	else:
		velocity = Vector3.ZERO
		if _cast_timer <= 0.0:
			_cast()
			_cast_timer = cast_cooldown


func _cast() -> void:
	if not player or not player.has_method("take_damage"):
		return
	# Simple "hitscan" — actual projectile would spawn a scene
	if distance_to_player() <= cast_range:
		player.take_damage(projectile_damage)
