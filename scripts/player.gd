# Player character with full Flower combat suite:
# - Click-to-move + WASD/controller direct movement
# - Soul/health system with demon latch support
# - Combo attacks (3-stage chain)
# - Stats from equipment/leveling
# - Inventory and gold
# - Skill hotbar integration
# - Multi-player: device_id selects controller; player_index 0 owns mouse/keyboard
extends CharacterBody3D

const CharacterClassScript := preload("res://scripts/items/character_class.gd")
const SettingsScript = preload("res://scripts/settings.gd")

const STICK_DEADZONE := 0.2
const SOUL_DRAIN_DURATION := 15.0
const COMBO_WINDOW := 0.5
const COMBO_STAGES := 3
const COMBO_DAMAGE_MULT := [1.0, 1.25, 1.75]
const ATTACK_BASE_WINDOW_DELAY := 0.1
const ATTACK_BASE_ACTIVE := 0.3

# Dash configuration
const DASH_DISTANCE := 5.0
const DASH_DURATION := 0.18
const DASH_COOLDOWN := 1.2

# Revive: another player must be within REVIVE_RADIUS for REVIVE_TIME seconds
const REVIVE_RADIUS := 2.5
const REVIVE_TIME := 2.0
const HIT_IFRAME_DURATION := 0.4
const POTION_COOLDOWN := 1.0
const CRIT_CHANCE := 0.10
const CRIT_MULTIPLIER := 2.0

# Loot magnet: gold/items within MAGNET_RADIUS get pulled toward player
const MAGNET_RADIUS := 3.0
const MAGNET_SPEED := 6.0

enum PlayerState { NORMAL, BEING_DRAINED, SOUL_DEAD, HEALTH_DEAD, DOWNED, DASHING }

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
signal player_downed
signal player_revived
signal dashed
signal damage_dealt(amount: float, crit: bool)
signal damage_taken(amount: float)

# Multiplayer config — set before _ready (or via setup()).
# player_index: 0 for P1 (mouse + first controller), 1 for P2 (controller only), etc.
# device_id: -1 = listen to all devices (default for solo/P1); otherwise filter joypad input.
@export var player_index: int = 0
@export var device_id: int = -1
@export var character_class_id: int = -1  # -1 = no class chosen yet

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
var _hit_iframe_timer: float = 0.0
var _potion_cooldown_timer: float = 0.0
var _temp_buffs: Dictionary = {}  # id -> {timer: float, mods: Dictionary}

var _combo_stage: int = 0
var _combo_window_remaining: float = 0.0
var _combo_window_open: bool = false

# Dash state
var _dash_cooldown: float = 0.0
var _dash_remaining: float = 0.0
var _dash_dir: Vector3 = Vector3.ZERO

# Revive state — when DOWNED, accumulates while a teammate is in range
var _revive_progress: float = 0.0


func _ready() -> void:
	add_to_group("player")
	# Each player also joins a per-index group for targeted lookups (HUD, autobot)
	add_to_group("player_%d" % player_index)
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

	# Equip starter weapon
	equipment.set_equipped(ItemResource.ItemType.WEAPON, ItemFactory.make_starter_weapon())

	if pickup_area:
		pickup_area.area_entered.connect(_on_pickup_area_entered)

	# Apply class if one was chosen before _ready ran. main.gd may also call
	# apply_character_class() after spawning to (re)apply.
	if character_class_id >= 0:
		apply_character_class(character_class_id)
	else:
		# No class yet — fill defaults from base PlayerStats.
		health = stats.max_health()
		soul = stats.max_soul()
		max_health_changed.emit(stats.max_health())
		max_soul_changed.emit(stats.max_soul())
		health_changed.emit(health)
		soul_changed.emit(soul)


# Apply (or re-apply) a character class. Safe to call after _ready.
func apply_character_class(class_id: int) -> void:
	character_class_id = class_id
	var cls = CharacterClassScript.by_id(class_id)
	if cls == null:
		return
	cls.apply_to_stats(stats)
	skills[0] = cls.make_signature_skill()
	if sprite:
		sprite.modulate = cls.primary_color
	health = stats.max_health()
	soul = stats.max_soul()
	max_health_changed.emit(stats.max_health())
	max_soul_changed.emit(stats.max_soul())
	health_changed.emit(health)
	soul_changed.emit(soul)


func setup(p_index: int, p_device: int, p_class_id: int = -1) -> void:
	player_index = p_index
	device_id = p_device
	character_class_id = p_class_id


# --- Input device helpers ---

func _owns_event(event: InputEvent) -> bool:
	# When device_id == -1, this player accepts anything (single-player mode).
	# Otherwise, joypad events must match our device_id.
	if device_id < 0:
		return true
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return event.device == device_id
	# Keyboard/mouse only owned by player_index 0
	return player_index == 0


func _is_primary_player() -> bool:
	return player_index == 0


# --- State helpers ---

func is_alive() -> bool:
	# DOWNED is "incapacitated but revivable" — not dead, not playable
	return state != PlayerState.SOUL_DEAD and state != PlayerState.HEALTH_DEAD


func is_active() -> bool:
	# Can the player accept input / move on their own?
	return is_alive() and state != PlayerState.DOWNED and state != PlayerState.BEING_DRAINED


func _set_state(new_state: int) -> void:
	if state == new_state:
		return
	state = new_state
	player_state_changed.emit(state)


# --- Input ---

func _unhandled_input(event: InputEvent) -> void:
	if not is_alive():
		return
	if not _owns_event(event):
		return
	if state == PlayerState.BEING_DRAINED:
		# Only attack input is allowed while latched
		if event.is_action_pressed("attack"):
			_handle_controller_attack()
		return

	# Mouse only available to primary player (device_id < 0 or player_index 0)
	if _is_primary_player() and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not _attacking:
				_direct_move = false
				_handle_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_mouse_attack(event.position)

	if event.is_action_pressed("attack"):
		_handle_controller_attack()

	# Dash: Shift on keyboard, RB / R1 on controller
	if _is_dash_event(event):
		_try_dash()

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
	var input_dir: Vector2
	if device_id < 0:
		# Single-player / primary mode: use action map (kbd + any joy)
		input_dir = Vector2(
			Input.get_axis("move_left", "move_right"),
			Input.get_axis("move_up", "move_down")
		)
	else:
		# Multi-player: read this player's joypad axes directly
		var x: float = Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X)
		var y: float = Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)
		# Also accept keyboard for player_index 0
		if player_index == 0:
			x += Input.get_axis("move_left", "move_right")
			y += Input.get_axis("move_up", "move_down")
			x = clamp(x, -1.0, 1.0)
			y = clamp(y, -1.0, 1.0)
		input_dir = Vector2(x, y)
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
				var crit: bool = randf() < (CRIT_CHANCE + stats.crit_chance_bonus())
				var crit_mult: float = CRIT_MULTIPLIER + stats.crit_damage_bonus()
				var final_dmg: float = dmg * (crit_mult if crit else 1.0)
				target.take_damage(final_dmg)
				if is_finisher:
					HitFeedback.finisher_hit(target.global_position, final_dmg, target)
				else:
					HitFeedback.enemy_hit(target.global_position, final_dmg, target, crit)
				damage_dealt.emit(final_dmg, crit)


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
	# Dashing = invuln frames
	if state == PlayerState.DASHING:
		return
	# Hit-iframes after a recent hit
	if _hit_iframe_timer > 0.0:
		return
	# Downed players can't take more damage
	if state == PlayerState.DOWNED:
		return
	var actual: float = max(amount - stats.defense(), 1.0)
	health -= actual
	_hit_iframe_timer = HIT_IFRAME_DURATION
	health_changed.emit(health)
	damage_taken.emit(actual)
	HitFeedback.player_hit(global_position, actual, sprite)
	# Combo resets when hit
	_combo_stage = 0
	_combo_window_open = false
	if health <= 0.0:
		health = 0.0
		# In 2P, go to DOWNED if a teammate is still up
		if _has_living_teammate():
			down_player("health")
		else:
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


func sell_item(slot_index: int) -> int:
	var item := inventory.get_item(slot_index)
	if item == null:
		return 0
	var value: int = item.sell_value()
	gold += value
	inventory.remove(slot_index)
	gold_changed.emit(gold)
	return value


func add_item(item: ItemResource) -> bool:
	var slot := inventory.add(item)
	if slot < 0:
		return false
	item_picked_up.emit(item)
	# Auto-equip if slot is empty and item is equippable (better-than-nothing rule)
	if item.item_type != ItemResource.ItemType.CONSUMABLE:
		var equipped: ItemResource = equipment.get_equipped(item.item_type)
		if equipped == null:
			equip_item(slot)
	return true


func apply_temp_buff(id: String, mods: Dictionary, duration: float) -> void:
	# If reapplied, refresh
	_temp_buffs[id] = {"timer": duration, "mods": mods.duplicate()}
	_recompute_modifiers()


func _tick_temp_buffs(delta: float) -> void:
	var expired: Array = []
	for id in _temp_buffs.keys():
		_temp_buffs[id].timer -= delta
		if _temp_buffs[id].timer <= 0.0:
			expired.append(id)
	if expired.size() > 0:
		for id in expired:
			_temp_buffs.erase(id)
		_recompute_modifiers()


func _recompute_modifiers() -> void:
	var totals: Dictionary = equipment.get_total_modifiers()
	for id in _temp_buffs.keys():
		var mods: Dictionary = _temp_buffs[id].mods
		for k in mods.keys():
			totals[k] = totals.get(k, 0.0) + float(mods[k])
	stats.set_modifiers(totals)


func use_consumable(slot_index: int) -> bool:
	var item := inventory.get_item(slot_index)
	if item == null or item.item_type != ItemResource.ItemType.CONSUMABLE:
		return false
	if _potion_cooldown_timer > 0.0:
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
	_potion_cooldown_timer = POTION_COOLDOWN
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


func unequip_item(slot_type: int) -> bool:
	var equipped := equipment.get_equipped(slot_type)
	if equipped == null:
		return false
	if inventory.is_full():
		return false
	equipment.set_equipped(slot_type, null)
	inventory.add(equipped)
	return true


func add_xp(amount: float) -> void:
	xp_gained.emit(amount)
	var levels := stats.add_xp(amount)
	for lv in levels:
		level_up.emit(lv)


func _on_equipment_changed(_slot_type: int, _new_item: ItemResource, _old_item: ItemResource) -> void:
	_recompute_modifiers()


func _on_stats_changed() -> void:
	# Clamp current health/soul to new maxes
	health = min(health, stats.max_health())
	soul = min(soul, stats.max_soul())
	max_health_changed.emit(stats.max_health())
	max_soul_changed.emit(stats.max_soul())
	health_changed.emit(health)
	soul_changed.emit(soul)
	stats_recalculated.emit()


func _on_level_changed(_new_level: int) -> void:
	# On level-up restore some health/soul. The level_up signal itself is
	# emitted from add_xp() so listeners aren't notified twice per level.
	health = min(health + 30.0, stats.max_health())
	soul = min(soul + 30.0, stats.max_soul())
	health_changed.emit(health)
	soul_changed.emit(soul)


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

	# Dash cooldown ticks regardless of state
	if _dash_cooldown > 0.0:
		_dash_cooldown = max(0.0, _dash_cooldown - delta)

	# Damage iframes & potion cooldown
	if _hit_iframe_timer > 0.0:
		_hit_iframe_timer = max(0.0, _hit_iframe_timer - delta)
	if _potion_cooldown_timer > 0.0:
		_potion_cooldown_timer = max(0.0, _potion_cooldown_timer - delta)
	# Tick temp buffs
	if not _temp_buffs.is_empty():
		_tick_temp_buffs(delta)

	# Revive progress ticks while DOWNED
	_process_revive(delta)

	# Loot magnet — only active players magnetize pickups
	if is_active():
		_process_magnet(delta)

	# Active dash overrides movement
	if state == PlayerState.DASHING:
		_dash_remaining -= delta
		velocity = _dash_dir * (DASH_DISTANCE / DASH_DURATION)
		move_and_slide()
		if _dash_remaining <= 0.0:
			_set_state(PlayerState.NORMAL)
		return

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


# --- Dash / dodge ---

func _is_dash_event(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode == KEY_SHIFT
	if event is InputEventJoypadButton and event.pressed:
		return event.button_index == JOY_BUTTON_RIGHT_SHOULDER
	return false


func _try_dash() -> bool:
	if not is_active():
		return false
	if _dash_cooldown > 0.0:
		return false
	var dir: Vector3 = _get_stick_input()
	if dir.length() < 0.1:
		dir = _facing_dir
	if dir.length() < 0.1:
		return false
	_dash_dir = dir.normalized()
	_dash_remaining = DASH_DURATION
	_dash_cooldown = DASH_COOLDOWN
	_set_state(PlayerState.DASHING)
	dashed.emit()
	return true


# --- Revive ---

func down_player(_reason: String = "health") -> void:
	# Convert what would be a death into the DOWNED state when there's a
	# living teammate who can revive. Returns true if the player was downed
	# (deferring death). Solo players or last-survivor get full death.
	if _has_living_teammate():
		health = 1.0
		health_changed.emit(health)
		velocity = Vector3.ZERO
		_revive_progress = 0.0
		_set_state(PlayerState.DOWNED)
		player_downed.emit()


func revive() -> void:
	if state != PlayerState.DOWNED:
		return
	health = max(stats.max_health() * 0.5, 1.0)
	soul = max(stats.max_soul() * 0.5, soul)
	health_changed.emit(health)
	soul_changed.emit(soul)
	_revive_progress = 0.0
	_set_state(PlayerState.NORMAL)
	player_revived.emit()


func _has_living_teammate() -> bool:
	for p in get_tree().get_nodes_in_group("player"):
		if p == self:
			continue
		if p.has_method("is_active") and p.is_active():
			return true
	return false


func _process_revive(delta: float) -> void:
	if state != PlayerState.DOWNED:
		return
	var reviver_in_range := false
	for p in get_tree().get_nodes_in_group("player"):
		if p == self:
			continue
		if not (p.has_method("is_active") and p.is_active()):
			continue
		if p.global_position.distance_to(global_position) <= REVIVE_RADIUS:
			reviver_in_range = true
			break
	if reviver_in_range:
		_revive_progress += delta
		if _revive_progress >= REVIVE_TIME:
			revive()
	else:
		_revive_progress = max(0.0, _revive_progress - delta * 0.5)


# --- Loot magnet ---

func _process_magnet(_delta: float) -> void:
	var radius: float = SettingsScript.get_loot_magnet_radius() if SettingsScript else MAGNET_RADIUS
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if not is_instance_valid(pickup):
			continue
		var dist: float = pickup.global_position.distance_to(global_position)
		if dist <= radius and dist > 0.4:
			var dir: Vector3 = (global_position - pickup.global_position).normalized()
			pickup.global_position += dir * MAGNET_SPEED * _delta

# --- Signature skill implementations ---

func _skill_whirling_blade(skill: SkillResource) -> void:
	# Sarah: spin attack hitting all nearby enemies
	if attack_area == null:
		return
	attack_shape.disabled = false
	attack_area.monitoring = true
	var dmg: float = stats.attack_damage() * skill.damage_multiplier
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(dmg)
	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(self) and attack_shape:
		attack_shape.disabled = true
		attack_area.monitoring = false


func _skill_ground_pound(skill: SkillResource) -> void:
	# Maddie: AoE shockwave
	var radius: float = skill.radius
	var dmg: float = stats.attack_damage() * skill.damage_multiplier
	for body in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(body):
			continue
		if body.global_position.distance_to(global_position) <= radius and body.has_method("take_damage"):
			body.take_damage(dmg)
	HitFeedback.explosion(global_position, radius)


func _skill_soul_bolt(skill: SkillResource) -> void:
	# Chan Xaic: hit nearest enemy within radius
	var nearest: Node3D = null
	var best_dist: float = skill.radius
	for body in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(body):
			continue
		var d: float = body.global_position.distance_to(global_position)
		if d < best_dist:
			nearest = body
			best_dist = d
	if nearest and nearest.has_method("take_damage"):
		nearest.take_damage(stats.attack_damage() * skill.damage_multiplier)


func _skill_ward_pulse(skill: SkillResource) -> void:
	# Aiyana: heal all players in range
	var radius: float = skill.radius
	var heal: float = skill.heal_amount
	for p in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(p):
			continue
		if p.global_position.distance_to(global_position) <= radius:
			p.health = min(p.health + heal, p.stats.max_health())
			if p.has_signal("health_changed"):
				p.health_changed.emit(p.health)
