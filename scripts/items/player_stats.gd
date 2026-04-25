## PlayerStats — derived stats including base values and equipment modifiers.
extends Resource
class_name PlayerStats

signal stats_changed
signal level_changed(new_level: int)

const MAX_LEVEL := 50

@export var base_attack_damage: float = 25.0
@export var base_attack_speed: float = 1.0
@export var base_max_health: float = 100.0
@export var base_max_soul: float = 100.0
@export var base_move_speed: float = 7.0
@export var base_defense: float = 0.0
@export var base_soul_drain_resist: float = 0.0

var modifiers: Dictionary = {}

var level: int = 1
var xp: float = 0.0
var stat_points: int = 0

var strength: int = 0
var vitality: int = 0
var spirit: int = 0
var agility: int = 0


func attack_damage() -> float:
	return base_attack_damage + (strength * 2.0) + modifiers.get("attack_damage_flat", 0.0)


func attack_speed() -> float:
	var s: float = base_attack_speed + (agility * 0.1) + modifiers.get("attack_speed_bonus", 0.0)
	return clamp(s, 0.5, 3.0)


func max_health() -> float:
	return base_max_health + (vitality * 10.0) + modifiers.get("max_health_flat", 0.0)


func max_soul() -> float:
	return base_max_soul + (spirit * 10.0) + modifiers.get("max_soul_flat", 0.0)


func move_speed() -> float:
	return base_move_speed + (agility * 0.3) + modifiers.get("move_speed_bonus", 0.0)


func defense() -> float:
	return base_defense + modifiers.get("defense_flat", 0.0)


func soul_drain_resist() -> float:
	return base_soul_drain_resist + modifiers.get("soul_drain_resist", 0.0)


func notify_changed() -> void:
	stats_changed.emit()


func xp_to_next_level() -> float:
	return xp_required_for_level(level + 1)


func set_modifiers(new_mods: Dictionary) -> void:
	modifiers = new_mods.duplicate()
	stats_changed.emit()


func xp_required_for_level(target_level: int) -> float:
	if target_level <= 1:
		return 0.0
	return 100.0 * float(target_level - 1) * pow(1.2, target_level - 1)


func add_xp(amount: float) -> Array:
	var levels_gained: Array = []
	if level >= MAX_LEVEL:
		return levels_gained
	xp += amount
	while level < MAX_LEVEL and xp >= xp_required_for_level(level + 1):
		xp -= xp_required_for_level(level + 1)
		level += 1
		stat_points += 3
		levels_gained.append(level)
		level_changed.emit(level)
	stats_changed.emit()
	return levels_gained


func spend_stat_point(stat: String) -> bool:
	if stat_points <= 0:
		return false
	match stat:
		"strength": strength += 1
		"vitality": vitality += 1
		"spirit": spirit += 1
		"agility": agility += 1
		_: return false
	stat_points -= 1
	stats_changed.emit()
	return true
