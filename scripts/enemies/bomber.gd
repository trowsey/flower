# Bomber: chases close, then fuses and explodes
extends EnemyBase
class_name Bomber

enum State { CHASE, FUSING, EXPLODED }

@export var fuse_time: float = 1.0
@export var explode_trigger_range: float = 1.5

var state: int = State.CHASE
var _fuse_timer: float = 0.0


func _ready() -> void:
	max_health = 14.0
	move_speed = 4.0
	damage = 30.0
	attack_range = 1.5
	enemy_type = "bomber"
	xp_reward = 25.0
	gold_drop_min = 0
	gold_drop_max = 4
	death_explosion_radius = 2.5
	death_explosion_damage = 30.0
	super._ready()


func _physics_process(delta: float) -> void:
	if not alive or not player:
		return
	match state:
		State.CHASE:
			var dist := distance_to_player()
			if dist <= explode_trigger_range:
				state = State.FUSING
				_fuse_timer = fuse_time
			else:
				var dir: Vector3 = (player.global_position - global_position)
				dir.y = 0.0
				velocity = dir.normalized() * move_speed
				move_and_slide()
		State.FUSING:
			velocity = Vector3.ZERO
			_fuse_timer -= delta
			if _fuse_timer <= 0.0:
				state = State.EXPLODED
				die()
		State.EXPLODED:
			pass
