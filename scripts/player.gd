extends CharacterBody3D

const SPEED := 7.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var sprite: AnimatedSprite3D = $Sprite

var _moving := false


func _ready() -> void:
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5
	nav_agent.navigation_finished.connect(_on_navigation_finished)
	sprite.play("idle")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_click(event.position)


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


func _physics_process(_delta: float) -> void:
	if not _moving:
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
		# Flip sprite based on horizontal movement direction
		sprite.flip_h = direction.x < 0

	velocity = direction * SPEED
	move_and_slide()


func _on_navigation_finished() -> void:
	_moving = false
	velocity = Vector3.ZERO
	sprite.play("idle")
