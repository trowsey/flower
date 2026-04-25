# Main scene controller — configures players from PartyConfig.
# - Slot 0: configures existing $Player node (kept in scene for backward compat)
# - Slot 1+: instantiates additional players spaced around the spawn point
extends Node3D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const CharacterClassScript := preload("res://scripts/items/character_class.gd")
const SPAWN_OFFSETS := [
	Vector3(0, 0.5, 0),
	Vector3(2, 0.5, 0),
	Vector3(-2, 0.5, 0),
	Vector3(0, 0.5, 2),
]


func _ready() -> void:
	# Defaults if PartyConfig wasn't set (e.g. running main.tscn directly)
	var slots: Array = PartyConfig.slots
	if slots.size() == 0:
		PartyConfig.set_solo(CharacterClassScript.Id.SARAH)
		slots = PartyConfig.slots

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
