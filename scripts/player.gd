# Xbox controller support uses Godot's built-in GameInput v3 backend (Windows)
# for joypad handling. No native code or GDExtension needed — Godot abstracts
# controller input through its Input Map and InputEvent system.
#
# Supports both mouse/keyboard (click-to-move) and controller (direct stick movement).

extends CharacterBody3D

const SPEED := 7.0
const ATTACK_DAMAGE := 25.0
const STICK_DEADZONE := 0.2

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var sprite: AnimatedSprite3D = $Sprite
@onready var attack_area: Area3D = $AttackArea
@onready var attack_shape: CollisionShape3D = $AttackArea/AttackShape

var _moving := false
var _attacking := false
# Direct movement from controller/WASD — overrides nav-agent pathfinding
var _direct_move := false
var _facing_dir := Vector3.FORWARD


func _ready() -> void:
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5
	nav_agent.navigation_finished.connect(_on_navigation_finished)
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("idle")


func _unhandled_input(event: InputEvent) -> void:
	# Mouse click-to-move and right-click attack
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not _attacking:
				_direct_move = false
				_handle_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_mouse_attack(event.position)

	# Controller / keyboard attack (X button on Xbox, mapped to "attack" action)
	if event.is_action_pressed("attack"):
		_handle_controller_attack()


# --- Mouse input ---

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


func _handle_mouse_attack(screen_pos: Vector2) -> void:
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
			_facing_dir = dir
			sprite.flip_h = dir.x < 0

	_start_attack()


# --- Controller / WASD input ---

func _get_stick_input() -> Vector3:
	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if input_dir.length() < STICK_DEADZONE:
		return Vector3.ZERO
	return Vector3(input_dir.x, 0.0, input_dir.y).normalized()


func _handle_controller_attack() -> void:
	if _attacking:
		return
	# Attack in the stick direction if tilted, otherwise use last facing direction
	var stick := _get_stick_input()
	if stick.length() > 0.1:
		_facing_dir = stick
	sprite.flip_h = _facing_dir.x < 0
	_start_attack()


# --- Shared attack logic ---

func _start_attack() -> void:
	_moving = false
	_direct_move = false
	_attacking = true
	velocity = Vector3.ZERO
	sprite.play("attack")

	attack_shape.disabled = false
	attack_area.monitoring = true
	_deal_damage()

	await get_tree().create_timer(0.3).timeout
	attack_shape.disabled = true
	attack_area.monitoring = false


func _deal_damage() -> void:
	await get_tree().create_timer(0.1).timeout
	var targets := attack_area.get_overlapping_bodies()
	for target in targets:
		if target.is_in_group("enemies") and target.has_method("take_damage"):
			target.take_damage(ATTACK_DAMAGE)


# --- Movement (runs every physics frame) ---

func _physics_process(_delta: float) -> void:
	if _attacking:
		return

	# Controller / WASD direct movement takes priority when stick is active
	var stick_dir := _get_stick_input()
	if stick_dir.length() > 0.1:
		_direct_move = true
		_moving = false
		_facing_dir = stick_dir
		sprite.flip_h = stick_dir.x < 0
		velocity = stick_dir * SPEED
		if sprite.animation != &"walk":
			sprite.play("walk")
		move_and_slide()
		return

	# If we were doing direct movement and stick was released, stop
	if _direct_move:
		_direct_move = false
		velocity = Vector3.ZERO
		sprite.play("idle")
		return

	# Nav-agent click-to-move path following
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
		_facing_dir = direction
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
