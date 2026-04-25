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
const SPAWN_RING_RADIUS := 12.0
const BASE_ENEMIES := 6  # solo baseline
const PER_PLAYER_BONUS := 4  # + per extra player
const WAVE_RESPAWN_DELAY := 8.0

const SPAWN_OFFSETS := [
	Vector3(0, 0.5, 0),
	Vector3(2, 0.5, 0),
	Vector3(-2, 0.5, 0),
	Vector3(0, 0.5, 2),
]

var _wave_timer: float = 0.0
var _player_count: int = 1


func _ready() -> void:
	# Apply persisted settings
	SettingsScript.load_and_apply()

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

	# Spawn first wave after a short delay so HUD/scene settle
	await get_tree().create_timer(0.5).timeout
	_spawn_wave()


func _process(delta: float) -> void:
	# Respawn a wave when no enemies remain
	if get_tree().get_nodes_in_group("enemies").size() == 0:
		_wave_timer += delta
		if _wave_timer >= WAVE_RESPAWN_DELAY:
			_wave_timer = 0.0
			_spawn_wave()
	else:
		_wave_timer = 0.0


func _spawn_wave() -> void:
	var count: int = BASE_ENEMIES + (_player_count - 1) * PER_PLAYER_BONUS
	var avg_level: float = _avg_player_level()
	for i in count:
		var scene_path: String = ENEMY_SCENES[i % ENEMY_SCENES.size()]
		var scene := load(scene_path)
		if scene == null:
			continue
		var enemy: Node3D = scene.instantiate()
		_scale_enemy_for_difficulty(enemy, avg_level)
		var angle: float = (TAU / float(count)) * i + randf() * 0.3
		var pos := Vector3(cos(angle), 0, sin(angle)) * SPAWN_RING_RADIUS
		add_child(enemy)
		enemy.global_position = pos + Vector3(0, 0.5, 0)


func _avg_player_level() -> float:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return 1.0
	var total: float = 0.0
	for p in players:
		total += float(p.stats.level if p.stats else 1)
	return total / float(players.size())


func _scale_enemy_for_difficulty(e: Node, avg_level: float) -> void:
	# +15% HP and +10% damage per player level above 1, +25% HP per extra player
	var lvl_mult: float = 1.0 + max(0.0, avg_level - 1.0) * 0.15
	var coop_mult: float = 1.0 + (_player_count - 1) * 0.25
	if "max_health" in e:
		e.max_health *= lvl_mult * coop_mult
	if "damage" in e:
		e.damage *= 1.0 + max(0.0, avg_level - 1.0) * 0.10
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
