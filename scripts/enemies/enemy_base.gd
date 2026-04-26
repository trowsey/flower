# Base class for all enemies. Handles health, damage, death, blood vfx, drops.
extends CharacterBody3D
class_name EnemyBase

signal enemy_died(enemy: Node3D)
signal health_changed(new_value: float)

@export var max_health: float = 30.0
@export var damage: float = 10.0
@export var move_speed: float = 3.0
@export var attack_range: float = 1.2
@export var xp_reward: float = 25.0
@export var gold_drop_min: int = 0
@export var gold_drop_max: int = 5
@export var item_drop_chance: float = 0.10
@export var death_explosion_radius: float = 0.0
@export var death_explosion_damage: float = 0.0
@export var enemy_type: String = "generic"
@export var elite: bool = false
@export var affixes: Array[String] = []
# Item level for loot drops. Set by spawner at spawn time.
@export var item_level: int = 1

var health: float = 30.0
var alive: bool = true
var player: Node3D = null
var _hit_flash_remaining: float = 0.0
var _knockback: Vector3 = Vector3.ZERO


func _process(delta: float) -> void:
	if _hit_flash_remaining > 0.0:
		_hit_flash_remaining = max(0.0, _hit_flash_remaining - delta)
		_apply_hit_flash_modulate(_hit_flash_remaining > 0.0)
	if _knockback.length_squared() > 0.001:
		# Apply directly as position offset so subclass AI velocity isn't fought
		global_position += _knockback * delta
		_knockback = _knockback.move_toward(Vector3.ZERO, delta * 12.0)


func _apply_hit_flash_modulate(active: bool) -> void:
	# Use a sentinel meta key to detect "we have stashed a value" — including
	# when that value is null. A plain get_meta(..., null) check can't tell
	# "absent" from "present-but-null", which previously left material_override
	# stuck on the duplicated red material after a flash ended.
	for child in get_children():
		if child is MeshInstance3D:
			var mesh: MeshInstance3D = child
			if active:
				if not mesh.has_meta("_orig_mod"):
					mesh.set_meta("_orig_mod", mesh.material_override)
				if mesh.material_override == null and mesh.mesh and mesh.mesh.surface_get_material(0):
					var dup: StandardMaterial3D = mesh.mesh.surface_get_material(0).duplicate()
					mesh.material_override = dup
				if mesh.material_override is StandardMaterial3D:
					(mesh.material_override as StandardMaterial3D).albedo_color = Color(2.0, 0.6, 0.6)
			else:
				if mesh.has_meta("_orig_mod"):
					mesh.material_override = mesh.get_meta("_orig_mod")
					mesh.remove_meta("_orig_mod")


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	health = max_health
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]


func take_damage(amount: float) -> void:
	if not alive:
		return
	health -= amount
	health_changed.emit(health)
	_hit_flash_remaining = 0.1
	# Knockback away from player
	if player:
		var away: Vector3 = (global_position - player.global_position)
		away.y = 0.0
		if away.length_squared() > 0.001:
			_knockback = away.normalized() * 3.0
	_spawn_blood_particles()
	if health <= 0.0:
		die()


func die() -> void:
	if not alive:
		return
	alive = false
	enemy_died.emit(self)
	if player and player.has_method("add_xp"):
		var xp_amount: float = xp_reward * (2.0 if elite else 1.0)
		player.add_xp(xp_amount)
	_drop_loot()
	if death_explosion_radius > 0.0:
		_explode()
	_spawn_death_particles()
	queue_free()


func _drop_loot() -> void:
	var is_boss: bool = has_meta("is_boss") and bool(get_meta("is_boss"))
	var gold_amount := randi_range(gold_drop_min, gold_drop_max) * (4 if is_boss else 1)
	if gold_amount > 0:
		_spawn_gold(gold_amount)
	var roll := randf()
	var chance: float = item_drop_chance * (3.0 if elite else 1.0)
	if is_boss or roll < chance:
		_spawn_item_drop()


func _spawn_gold(amount: int) -> void:
	var pickup_scene := load("res://scenes/items/gold_pickup.tscn")
	if pickup_scene == null:
		return
	var pickup: Node = pickup_scene.instantiate()
	get_tree().current_scene.add_child(pickup)
	pickup.global_position = global_position + Vector3(0, 0.3, 0)
	if pickup.has_method("set_amount"):
		pickup.set_amount(amount)


func _spawn_item_drop() -> void:
	var pickup_scene := load("res://scenes/items/item_pickup.tscn")
	if pickup_scene == null:
		return
	var pickup: Node = pickup_scene.instantiate()
	get_tree().current_scene.add_child(pickup)
	pickup.global_position = global_position + Vector3(0, 0.3, 0)
	var is_boss: bool = has_meta("is_boss") and bool(get_meta("is_boss"))
	# Try set drop first (rare); bosses get higher set chance
	var item: ItemResource = ItemFactory.maybe_make_set_item(
		item_level, 0.25 if is_boss else 0.03)
	if item == null:
		var rarity_floor: int = (
			ItemResource.Rarity.LEGENDARY if is_boss
			else (ItemResource.Rarity.RARE if elite else 0))
		var rolled: int = ItemFactory.roll_rarity(1 if elite else 0)
		var rarity: int = max(rolled, rarity_floor)
		item = ItemFactory.make_random(-1, rarity, item_level)
	if pickup.has_method("set_item"):
		pickup.set_item(item)


func _current_item_level() -> int:
	# Backwards-compat shim. Prefer the `item_level` property set by spawners.
	return item_level


func _spawn_blood_particles() -> void:
	var scene := load("res://scenes/effects/blood_particles.tscn")
	if scene == null:
		return
	var p: Node = scene.instantiate()
	get_tree().current_scene.add_child(p)
	p.global_position = global_position + Vector3(0, 0.5, 0)


func _spawn_death_particles() -> void:
	var scene := load("res://scenes/effects/death_particles.tscn")
	if scene == null:
		return
	var p: Node = scene.instantiate()
	get_tree().current_scene.add_child(p)
	p.global_position = global_position + Vector3(0, 0.5, 0)


func _explode() -> void:
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := SphereShape3D.new()
	shape.radius = death_explosion_radius
	query.shape = shape
	query.transform = Transform3D(Basis(), global_position)
	query.collision_mask = 2 | 4
	var results := space_state.intersect_shape(query, 32)
	for r in results:
		var node = r.collider
		if not is_instance_valid(node) or node == self:
			continue
		if node.has_method("take_damage"):
			node.take_damage(death_explosion_damage)
	HitFeedback.explosion(global_position, death_explosion_radius)


func distance_to_player() -> float:
	if not player:
		return INF
	return global_position.distance_to(player.global_position)
