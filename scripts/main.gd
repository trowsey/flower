# Main scene controller — configures players from PartyConfig.
# - Slot 0: configures existing $Player node (kept in scene for backward compat)
# - Slot 1+: instantiates additional players spaced around the spawn point
extends Node3D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const CharacterClassScript := preload("res://scripts/items/character_class.gd")
const SettingsScript := preload("res://scripts/settings.gd")

const ENEMY_SCENES := [
	"res://scenes/enemies/skitterer.tscn",
	"res://scenes/enemies/brute.tscn",
]
const BiomeManagerScript := preload("res://scripts/world/biome_manager.gd")
const SPAWN_RING_RADIUS := 12.0
const BASE_ENEMIES := 6  # solo baseline
const PER_PLAYER_BONUS := 4  # + per extra player
const WAVE_RESPAWN_DELAY := 8.0
const RunStatsScript := preload("res://scripts/run_stats.gd")
const TutorialScript := preload("res://scripts/ui/tutorial_overlay.gd")
const InventoryScreenScript := preload("res://scripts/ui/inventory_screen.gd")
const LevelUpPanelScript := preload("res://scripts/ui/level_up_panel.gd")
const DamageIndicatorScript := preload("res://scripts/ui/damage_indicator.gd")
const ShrineScript := preload("res://scripts/world/shrine.gd")

const SPAWN_OFFSETS := [
	Vector3(0, 0.5, 0),
	Vector3(2, 0.5, 0),
	Vector3(-2, 0.5, 0),
	Vector3(0, 0.5, 2),
]

var _wave_timer: float = 0.0
var _player_count: int = 1
var current_wave: int = 1
var run_stats: RunStats = null
var biome_manager: BiomeManager = null
signal wave_started(wave: int)
signal wave_cleared(wave: int)
signal biome_changed(biome: Resource)


func _ready() -> void:
	# Apply persisted settings
	SettingsScript.load_and_apply()

	# Run stats tracker
	run_stats = RunStatsScript.new()
	run_stats.name = "RunStats"
	add_child(run_stats)

	# Biome rotation
	biome_manager = BiomeManagerScript.new()
	biome_manager.name = "BiomeManager"
	add_child(biome_manager)
	biome_manager.biome_changed.connect(_on_biome_changed)
	_apply_biome_visuals(biome_manager.current())

	# Tutorial overlay (auto-hides if seen before)
	var tut: CanvasLayer = TutorialScript.new()
	tut.name = "TutorialOverlay"
	add_child(tut)

	# Inventory & level-up overlays
	var inv: CanvasLayer = InventoryScreenScript.new()
	inv.name = "InventoryScreen"
	add_child(inv)
	var lvl: CanvasLayer = LevelUpPanelScript.new()
	lvl.name = "LevelUpPanel"
	add_child(lvl)

	# Damage indicator (red vignette on hit)
	var dmg_ind: CanvasLayer = DamageIndicatorScript.new()
	dmg_ind.name = "DamageIndicator"
	add_child.call_deferred(dmg_ind)

	# Defaults if PartyConfig wasn't set (e.g. running main.tscn directly)
	var slots: Array = PartyConfig.slots
	if slots.size() == 0:
		PartyConfig.set_solo(CharacterClassScript.Id.SARAH)
		slots = PartyConfig.slots
	_player_count = slots.size()

	# Configure the pre-placed Player node (slot 0)
	var existing: Node = get_node_or_null("Player")
	if existing and slots.size() > 0:
		var s0: Dictionary = slots[0]
		existing.player_index = 0
		existing.device_id = s0.get("device_id", -1)
		existing.character_class_id = s0.get("character_class_id", CharacterClassScript.Id.SARAH)
		existing.global_position = SPAWN_OFFSETS[0]
		# Player._ready already ran (children before parent), so re-apply
		# the class explicitly and refill resources to full.
		_apply_class(existing)

	# Spawn additional players for slot 1+
	for i in range(1, slots.size()):
		var s: Dictionary = slots[i]
		var p: Node = PLAYER_SCENE.instantiate()
		p.name = "Player%d" % (i + 1)
		p.player_index = i
		p.device_id = s.get("device_id", i)
		p.character_class_id = s.get("character_class_id", CharacterClassScript.Id.MADDIE)
		add_child(p)
		p.global_position = SPAWN_OFFSETS[i % SPAWN_OFFSETS.size()]
		_apply_class(p)

	# Wire run-stats signal connections
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_signal("level_up"):
			p.level_up.connect(func(lv): run_stats.record_level(lv))
		if p.has_signal("gold_changed"):
			var prev: int = p.gold
			p.gold_changed.connect(func(v):
				if v > prev:
					run_stats.record_gold(v - prev)
				prev = v
			)
		if p.has_signal("item_picked_up"):
			p.item_picked_up.connect(func(it): run_stats.record_item_picked(it))

	# Spawn first wave after a short delay so HUD/scene settle
	await get_tree().create_timer(0.5).timeout
	_spawn_wave()


func _process(delta: float) -> void:
	# Respawn a wave when no enemies remain
	if get_tree().get_nodes_in_group("enemies").size() == 0:
		_wave_timer += delta
		if _wave_timer >= WAVE_RESPAWN_DELAY:
			_wave_timer = 0.0
			if run_stats:
				run_stats.record_wave_cleared()
			emit_signal("wave_cleared", current_wave)
			if biome_manager:
				biome_manager.notify_wave_cleared(current_wave)
			current_wave += 1
			_spawn_wave()
	else:
		_wave_timer = 0.0


func _spawn_wave() -> void:
	var count: int = BASE_ENEMIES + (_player_count - 1) * PER_PLAYER_BONUS + (current_wave - 1) * 2
	var avg_level: float = _avg_player_level()
	var wave_mult: float = 1.0 + (current_wave - 1) * 0.10
	wave_mult *= float(PartyConfig.get_meta("difficulty_mult", 1.0))
	if biome_manager:
		wave_mult *= 1.0 + 0.20 * float(biome_manager.difficulty_loop)
	var force_elite_index: int = -1
	if current_wave % 5 == 0:
		force_elite_index = randi() % count
	var is_boss_wave: bool = current_wave % 10 == 0
	var pool: Array = ENEMY_SCENES
	if biome_manager:
		var biome_pool: Array = biome_manager.enemy_pool()
		if biome_pool.size() > 0:
			pool = biome_pool
	for i in count:
		var scene_path: String = pool[i % pool.size()]
		var scene := load(scene_path)
		if scene == null:
			continue
		var enemy: Node3D = scene.instantiate()
		_scale_enemy_for_difficulty(enemy, avg_level, wave_mult)
		if i == force_elite_index and "elite" in enemy:
			enemy.elite = true
		# Boss every 10 waves: index 0 gets massive HP/dmg + scale
		if is_boss_wave and i == 0:
			if "elite" in enemy:
				enemy.elite = true
			if "max_health" in enemy:
				enemy.max_health *= 5.0
				enemy.health = enemy.max_health
			if "damage" in enemy:
				enemy.damage *= 1.8
			if "xp_reward" in enemy:
				enemy.xp_reward *= 5.0
			enemy.scale = Vector3(1.6, 1.6, 1.6)
			enemy.set_meta("is_boss", true)
		var angle: float = (TAU / float(count)) * i + randf() * 0.3
		var pos := Vector3(cos(angle), 0, sin(angle)) * SPAWN_RING_RADIUS
		add_child(enemy)
		enemy.global_position = pos + Vector3(0, 0.5, 0)
		# Hook tree_exiting once for kill stats
		enemy.tree_exiting.connect(func(): _on_enemy_removed(enemy))
	emit_signal("wave_started", current_wave)
	# Shrine every 3 waves (skip first wave)
	if current_wave >= 3 and current_wave % 3 == 0:
		_spawn_shrine()


func _spawn_shrine() -> void:
	var shrine: Node3D = ShrineScript.new()
	shrine.name = "Shrine"
	add_child(shrine)
	var angle: float = randf() * TAU
	var dist: float = 6.0 + randf() * 4.0
	shrine.global_position = Vector3(cos(angle) * dist, 0.5, sin(angle) * dist)


func _on_enemy_removed(e: Node) -> void:
	if not is_instance_valid(e) or run_stats == null:
		return
	var is_elite: bool = e.get("elite") if "elite" in e else false
	var is_boss: bool = bool(e.get_meta("is_boss", false))
	run_stats.record_kill(is_elite, is_boss)


func _avg_player_level() -> float:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return 1.0
	var total: float = 0.0
	for p in players:
		total += float(p.stats.level if p.stats else 1)
	return total / float(players.size())


func _scale_enemy_for_difficulty(e: Node, avg_level: float, wave_mult: float = 1.0) -> void:
	# +15% HP and +10% damage per player level above 1, +25% HP per extra player,
	# +10% per wave past 1.
	var lvl_mult: float = 1.0 + max(0.0, avg_level - 1.0) * 0.15
	var coop_mult: float = 1.0 + (_player_count - 1) * 0.25
	if "max_health" in e:
		e.max_health *= lvl_mult * coop_mult * wave_mult
	if "damage" in e:
		e.damage *= (1.0 + max(0.0, avg_level - 1.0) * 0.10) * wave_mult
	if "health" in e and "max_health" in e:
		e.health = e.max_health


func _apply_class(p: Node) -> void:
	if p.character_class_id < 0:
		return
	var cls: Resource = CharacterClassScript.by_id(p.character_class_id)
	if cls == null or p.stats == null:
		return
	cls.apply_to_stats(p.stats)
	p.health = p.stats.max_health()
	p.soul = p.stats.max_soul()
	if p.has_signal("max_health_changed"):
		p.max_health_changed.emit(p.stats.max_health())
		p.max_soul_changed.emit(p.stats.max_soul())
		p.health_changed.emit(p.health)
		p.soul_changed.emit(p.soul)


func _on_biome_changed(biome: Resource) -> void:
	_apply_biome_visuals(biome)
	emit_signal("biome_changed", biome)


func _apply_biome_visuals(biome: Resource) -> void:
	if biome == null:
		return
	var floor_node := get_node_or_null("Floor/Mesh") as MeshInstance3D
	if floor_node == null:
		floor_node = get_node_or_null("Floor") as MeshInstance3D
	if floor_node:
		var fmat := StandardMaterial3D.new()
		fmat.albedo_color = biome.floor_color
		floor_node.material_override = fmat
	for wall_name in ["WallNorth", "WallSouth", "WallEast", "WallWest"]:
		var wall := get_node_or_null("%s/Mesh" % wall_name) as MeshInstance3D
		if wall == null:
			wall = get_node_or_null(wall_name) as MeshInstance3D
		if wall:
			var wmat := StandardMaterial3D.new()
			wmat.albedo_color = biome.wall_color
			wall.material_override = wmat
	var env := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if env and env.environment:
		env.environment.ambient_light_color = biome.ambient_color


func current_biome() -> Resource:
	if biome_manager:
		return biome_manager.current()
	return null
