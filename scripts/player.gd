# Player character with full Flower combat suite:
# - Click-to-move + WASD/controller direct movement
# - Soul/health system with demon latch support
# - Combo attacks (3-stage chain)
# - Stats from equipment/leveling
# - Inventory and gold
# - Skill hotbar integration
extends CharacterBody3D

const STICK_DEADZONE := 0.2
const SOUL_DRAIN_DURATION := 15.0
const COMBO_WINDOW := 0.5
const COMBO_STAGES := 3
const COMBO_DAMAGE_MULT := [1.0, 1.25, 1.75]
const ATTACK_BASE_WINDOW_DELAY := 0.1
const ATTACK_BASE_ACTIVE := 0.3

enum PlayerState { NORMAL, BEING_DRAINED, SOUL_DEAD, HEALTH_DEAD }

signal soul_changed(new_value: float)
signal health_changed(new_value: float)
signal max_soul_changed(new_max: float)
signal max_health_changed(new_max: float)
signal player_state_changed(new_state: int)
signal latch_started(demon: Node3D)
signal latch_broken(demon: Node3D)
signal gold_changed(new_amount: int)
signal xp_gained(amount: float)
signal level_up(new_level: int)
signal stats_recalculated
signal combo_advanced(stage: int)
signal item_picked_up(item: ItemResource)
signal player_died(reason: String)

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var sprite: AnimatedSprite3D = $Sprite
@onready var attack_area: Area3D = $AttackArea
@onready var attack_shape: CollisionShape3D = $AttackArea/AttackShape
@onready var pickup_area: Area3D = $PickupArea if has_node("PickupArea") else null
@onready var player_light: OmniLight3D = $PlayerLight if has_node("PlayerLight") else null

var stats: PlayerStats = PlayerStats.new()
var equipment: EquipmentManager = EquipmentManager.new()
var inventory: Inventory = Inventory.new()
var skills: Array = [null, null, null, null]
var skill_cooldowns: Array = [0.0, 0.0, 0.0, 0.0]

var soul: float = 100.0
var health: float = 100.0
var gold: int = 0
var state: int = PlayerState.NORMAL

var _moving := false
var _attacking := false
var _direct_move := false
var _facing_dir := Vector3.FORWARD
var _latched_demon: Node3D = null
var _soul_at_latch_start := 100.0

var _combo_stage: int = 0
var _combo_window_remaining: float = 0.0
var _combo_window_open: bool = false


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1

	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5
	nav_agent.navigation_finished.connect(_on_navigation_finished)
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("idle")

	# Equip starter weapon
	equipment.equipment_changed.connect(_on_equipment_changed)
	stats.stats_changed.connect(_on_stats_changed)
	stats.level_changed.connect(_on_level_changed)
	var starter := ItemFactory.make_starter_weapon()
	equipment.set_equipped(ItemResource.ItemType.WEAPON, starter)

	health = stats.max_health()
	soul = stats.max_soul()

	if pickup_area:
		pickup_area.area_entered.connect(_on_pickup_area_entered)

	max_health_changed.emit(stats.max_health())
	max_soul_changed.emit(stats.max_soul())
	health_changed.emit(health)
	soul_changed.emit(soul)


# --- State helpers ---

func is_alive() -> bool:
	return state != PlayerState.SOUL_DEAD and state != PlayerState.HEALTH_DEAD


func _set_state(new_state: int) -> void:
	if state == new_state:
		return
	state = new_state
	player_state_changed.emit(state)


# --- Input ---

func _unhandled_input(event: InputEvent) -> void:
	if not is_alive():
		return
	if state == PlayerState.BEING_DRAINED:
		# Only attack input is allowed while latched
		if event.is_action_pressed("attack"):
			_handle_controller_attack()
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not _attacking:
				_direct_move = false
				_handle_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_mouse_attack(event.position)

	if event.is_action_pressed("attack"):
		_handle_controller_attack()

	# Skill hotbar 1-4
	for i in range(4):
		var action := "skill_%d" % (i + 1)
		if InputMap.has_action(action) and event.is_action_pressed(action):
			_try_use_skill(i)


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


# --- Controller input ---

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
	var stick := _get_stick_input()
	if stick.length() > 0.1:
		_facing_dir = stick
	sprite.flip_h = _facing_dir.x < 0
	_start_attack()


# --- Attack and combo ---

func _start_attack() -> void:
	# Advance combo if window is open, otherwise start at stage 1
	if _combo_window_open and _combo_stage < COMBO_STAGES:
		_combo_stage += 1
	else:
		_combo_stage = 1
	_combo_window_open = false
	_combo_window_remaining = 0.0
	combo_advanced.emit(_combo_stage)

	_moving = false
	_direct_move = false
	_attacking = true
	velocity = Vector3.ZERO

	var anim_name := "attack"
	# Play stage-specific animation if it exists, else fallback to "attack"
	var stage_anim := "attack_%d" % _combo_stage
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(stage_anim):
		anim_name = stage_anim
	sprite.speed_scale = stats.attack_speed()
	sprite.play(anim_name)

	attack_shape.disabled = false
	attack_area.monitoring = true
	_deal_damage()

	var atk_speed: float = stats.attack_speed()
	var active_time: float = ATTACK_BASE_ACTIVE / atk_speed
	await get_tree().create_timer(active_time).timeout
	if is_instance_valid(self):
		attack_shape.disabled = true
		attack_area.monitoring = false


func _deal_damage() -> void:
	var atk_speed: float = stats.attack_speed()
	var window_delay: float = ATTACK_BASE_WINDOW_DELAY / atk_speed
	await get_tree().create_timer(window_delay).timeout
	if not is_instance_valid(self) or not attack_area.monitoring:
		return
	var targets := attack_area.get_overlapping_bodies()
	var dmg: float = stats.attack_damage() * COMBO_DAMAGE_MULT[_combo_stage - 1]
	var is_finisher: bool = _combo_stage >= COMBO_STAGES
	for target in targets:
		if not is_instance_valid(target):
			continue
		if target.is_in_group("enemies") or target.is_in_group("destructibles"):
			if target.has_method("take_damage"):
				target.take_damage(dmg)
				if has_node("/root/HitFeedback"):
					var hf := get_node("/root/HitFeedback")
					if is_finisher:
						hf.finisher_hit(target.global_position, dmg, target)
					else:
						hf.enemy_hit(target.global_position, dmg, target)


# --- Soul drain API (called by demons) ---

func begin_soul_drain(demon: Node3D) -> bool:
	if state != PlayerState.NORMAL:
		return false
	_latched_demon = demon
	_soul_at_latch_start = soul
	_set_state(PlayerState.BEING_DRAINED)
	latch_started.emit(demon)
	return true


func end_soul_drain() -> void:
	if state != PlayerState.BEING_DRAINED:
		return
	var demon := _latched_demon
	_latched_demon = null
	_set_state(PlayerState.NORMAL)
	latch_broken.emit(demon)


func get_soul_drain_rate() -> float:
	var max_soul: float = stats.max_soul()
	var rate: float = max_soul / SOUL_DRAIN_DURATION
	# Drain resist reduces effective rate (1.0 resist = 100% reduction)
	rate *= max(0.0, 1.0 - stats.soul_drain_resist())
	return rate


func recover_soul(amount: float) -> void:
	soul = min(soul + amount, stats.max_soul())
	soul_changed.emit(soul)


func recover_to_pre_latch() -> void:
	soul = min(_soul_at_latch_start, stats.max_soul())
	soul_changed.emit(soul)


# --- Damage ---

func take_damage(amount: float) -> void:
	if not is_alive():
		return
	var actual: float = max(amount - stats.defense(), 1.0)
	health -= actual
	health_changed.emit(health)
	if has_node("/root/HitFeedback"):
		get_node("/root/HitFeedback").player_hit(global_position, actual, sprite)
	# Combo resets when hit
	_combo_stage = 0
	_combo_window_open = false
	if health <= 0.0:
		health = 0.0
		_die_health()


func _die_health() -> void:
	_set_state(PlayerState.HEALTH_DEAD)
	velocity = Vector3.ZERO
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
	player_died.emit("health")


func _die_soul() -> void:
	_set_state(PlayerState.SOUL_DEAD)
	velocity = Vector3.ZERO
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
	player_died.emit("soul")


# --- Inventory / gold / XP ---

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true


func add_item(item: ItemResource) -> bool:
	var slot := inventory.add(item)
	if slot < 0:
		return false
	item_picked_up.emit(item)
	return true


func use_consumable(slot_index: int) -> bool:
	var item := inventory.get_item(slot_index)
	if item == null or item.item_type != ItemResource.ItemType.CONSUMABLE:
		return false
	match item.consumable_effect:
		"heal_health":
			health = min(health + item.consumable_amount, stats.max_health())
			health_changed.emit(health)
		"heal_soul":
			soul = min(soul + item.consumable_amount, stats.max_soul())
			soul_changed.emit(soul)
		_:
			return false
	inventory.remove(slot_index)
	return true


func equip_item(slot_index: int) -> bool:
	var item := inventory.get_item(slot_index)
	if item == null or item.item_type == ItemResource.ItemType.CONSUMABLE:
		return false
	var old_equipped := equipment.set_equipped(item.item_type, item)
	inventory.remove(slot_index)
	if old_equipped != null:
		inventory.slots[slot_index] = old_equipped
		inventory.items_changed.emit()
	return true


func add_xp(amount: float) -> void:
	xp_gained.emit(amount)
	var levels := stats.add_xp(amount)
	for lv in levels:
		level_up.emit(lv)


func _on_equipment_changed(_slot_type: int, _new_item: ItemResource, _old_item: ItemResource) -> void:
	stats.set_modifiers(equipment.get_total_modifiers())


func _on_stats_changed() -> void:
	# Clamp current health/soul to new maxes
	health = min(health, stats.max_health())
	soul = min(soul, stats.max_soul())
	max_health_changed.emit(stats.max_health())
	max_soul_changed.emit(stats.max_soul())
	health_changed.emit(health)
	soul_changed.emit(soul)
	stats_recalculated.emit()


func _on_level_changed(new_level: int) -> void:
	# On level-up restore some health/soul
	health = min(health + 30.0, stats.max_health())
	soul = min(soul + 30.0, stats.max_soul())
	health_changed.emit(health)
	soul_changed.emit(soul)
	level_up.emit(new_level)


# --- Skills ---

func equip_skill(slot: int, skill: SkillResource) -> void:
	if slot < 0 or slot >= 4:
		return
	skills[slot] = skill
	skill_cooldowns[slot] = 0.0


func _try_use_skill(slot: int) -> bool:
	if not is_alive() or state == PlayerState.BEING_DRAINED:
		return false
	if slot < 0 or slot >= skills.size():
		return false
	var skill: SkillResource = skills[slot]
	if skill == null:
		return false
	if skill_cooldowns[slot] > 0.0:
		return false
	if soul < skill.soul_cost:
		return false
	soul -= skill.soul_cost
	soul_changed.emit(soul)
	skill_cooldowns[slot] = skill.cooldown
	if skill.execute_method != "" and has_method(skill.execute_method):
		call(skill.execute_method, skill)
	return true


# --- Movement / drain processing ---

func _physics_process(delta: float) -> void:
	# Tick skill cooldowns
	for i in skill_cooldowns.size():
		if skill_cooldowns[i] > 0.0:
			skill_cooldowns[i] = max(0.0, skill_cooldowns[i] - delta)

	# Combo window decay
	if _combo_window_open:
		_combo_window_remaining -= delta
		if _combo_window_remaining <= 0.0:
			_combo_stage = 0
			_combo_window_open = false

	# Soul drain
	if state == PlayerState.BEING_DRAINED:
		soul -= get_soul_drain_rate() * delta
		soul_changed.emit(soul)
		if soul <= 0.0:
			soul = 0.0
			_die_soul()
			return

	if not is_alive():
		return

	if _attacking:
		return

	if state == PlayerState.BEING_DRAINED:
		velocity = Vector3.ZERO
		return

	var stick_dir := _get_stick_input()
	if stick_dir.length() > 0.1:
		# Direct move resets combo
		if _combo_window_open:
			_combo_stage = 0
			_combo_window_open = false
		_direct_move = true
		_moving = false
		_facing_dir = stick_dir
		sprite.flip_h = stick_dir.x < 0
		velocity = stick_dir * stats.move_speed()
		if sprite.animation != &"walk":
			sprite.play("walk")
		move_and_slide()
		return

	if _direct_move:
		_direct_move = false
		velocity = Vector3.ZERO
		sprite.play("idle")
		return

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
	velocity = direction * stats.move_speed()
	move_and_slide()


func _on_animation_finished() -> void:
	var anim := str(sprite.animation)
	if anim == "attack" or anim.begins_with("attack_"):
		_attacking = false
		# Open combo window if not at final stage
		if _combo_stage < COMBO_STAGES:
			_combo_window_open = true
			_combo_window_remaining = COMBO_WINDOW
		else:
			_combo_stage = 0
			_combo_window_open = false
		sprite.speed_scale = 1.0
		if _moving:
			sprite.play("walk")
		else:
			sprite.play("idle")


func _on_navigation_finished() -> void:
	_moving = false
	velocity = Vector3.ZERO
	if not _attacking and is_alive():
		sprite.play("idle")


func _on_pickup_area_entered(area: Area3D) -> void:
	if area.is_in_group("gold_pickup") and area.has_method("collect"):
		area.collect(self)
	elif area.is_in_group("item_pickup") and area.has_method("collect"):
		area.collect(self)
