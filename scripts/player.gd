extends CharacterBody3D

const SPEED := 7.0
const ATTACK_DAMAGE := 25.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var sprite: AnimatedSprite3D = $Sprite
@onready var attack_area: Area3D = $AttackArea
@onready var attack_shape: CollisionShape3D = $AttackArea/AttackShape

var _moving := false
var _attacking := false


func _ready() -> void:
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5
	nav_agent.navigation_finished.connect(_on_navigation_finished)
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("idle")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not _attacking:
				_handle_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_attack(event.position)


func _handle_click(screen_pos: Vector2) -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return

	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * 1000.0

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1

	var result := space_state.intersect_ray(query)
	if result:
		nav_agent.target_position = result.position
		_moving = true
		sprite.play("walk")


func _handle_attack(screen_pos: Vector2) -> void:
	if _attacking:
		return

	# Face toward the click position
	var camera := get_viewport().get_camera_3d()
	if camera:
		var from := camera.project_ray_origin(screen_pos)
		var to := from + camera.project_ray_normal(screen_pos) * 1000.0
		var space_state := get_world_3d().direct_space_state
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = 1
		var result := space_state.intersect_ray(query)
		if result:
			var dir: Vector3 = (result.position - global_position).normalized()
			sprite.flip_h = dir.x < 0

	# Stop movement and play attack
	_moving = false
	_attacking = true
	velocity = Vector3.ZERO
	sprite.play("attack")

	# Enable hitbox during the swing
	attack_shape.disabled = false
	attack_area.monitoring = true
	_deal_damage()

	# Disable hitbox after a short delay
	await get_tree().create_timer(0.3).timeout
	attack_shape.disabled = true
	attack_area.monitoring = false


func _deal_damage() -> void:
	# Small delay so the hitbox overlaps on the swing frame
	await get_tree().create_timer(0.1).timeout
	var targets := attack_area.get_overlapping_bodies()
	for target in targets:
		if target.is_in_group("enemies") and target.has_method("take_damage"):
			target.take_damage(ATTACK_DAMAGE)


func _physics_process(_delta: float) -> void:
	if _attacking or not _moving:
		return

	if nav_agent.is_navigation_finished():
		_moving = false
		velocity = Vector3.ZERO
		sprite.play("idle")
		return

	var next_pos := nav_agent.get_next_path_position()
	var direction := (next_pos - global_position).normalized()
	direction.y = 0

	if direction.length() > 0.01:
		sprite.flip_h = direction.x < 0

	velocity = direction * SPEED
	move_and_slide()


func _on_animation_finished() -> void:
	if sprite.animation == &"attack":
		_attacking = false
		if _moving:
			sprite.play("walk")
		else:
			sprite.play("idle")


func _on_navigation_finished() -> void:
	_moving = false
	velocity = Vector3.ZERO
	if not _attacking:
		sprite.play("idle")
