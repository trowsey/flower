# Skeleton Archer: ranged kiter that shoots from distance
extends EnemyBase
class_name SkeletonArcher

@export var fire_range: float = 9.0
@export var min_player_distance: float = 4.0
@export var fire_cooldown: float = 1.4
@export var projectile_damage: float = 8.0

var _fire_timer: float = 0.0


func _ready() -> void:
	max_health = 18.0
	move_speed = 2.5
	damage = 8.0
	attack_range = fire_range
	enemy_type = "archer"
	xp_reward = 30.0
	gold_drop_min = 2
	gold_drop_max = 8
	super._ready()


func _physics_process(delta: float) -> void:
	if not alive or not player:
		return
	if _fire_timer > 0.0:
		_fire_timer -= delta
	var dist := distance_to_player()
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	if dist < min_player_distance:
		# Kite away
		velocity = -to_player.normalized() * move_speed
		move_and_slide()
	elif dist > fire_range:
		# Close in
		velocity = to_player.normalized() * move_speed
		move_and_slide()
	else:
		velocity = Vector3.ZERO
		if _fire_timer <= 0.0:
			_fire(player)
			_fire_timer = fire_cooldown


func _fire(target: Node3D) -> void:
	if target == null or not target.has_method("take_damage"):
		return
	# Hitscan with line-of-sight check
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.5,
		target.global_position + Vector3.UP * 0.5
	)
	query.collision_mask = 1 | 2  # walls + players
	query.exclude = [self]
	var hit := space.intersect_ray(query)
	if hit and hit.collider == target:
		target.take_damage(projectile_damage)
