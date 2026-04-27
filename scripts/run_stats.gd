# RunStats — tracks per-run statistics, displayed in the death recap.
# Instanced as a child of main scene (not autoload — owned by the run).
extends Node
class_name RunStats

var waves_cleared: int = 0
var kills: int = 0
var elite_kills: int = 0
var boss_kills: int = 0
var gold_collected: int = 0
var time_alive: float = 0.0
var peak_level: int = 1
var crit_hits: int = 0
var damage_dealt: float = 0.0
var damage_taken: float = 0.0
var items_picked: int = 0
var legendaries_found: int = 0
var sets_found: int = 0


func _process(delta: float) -> void:
	time_alive += delta


func record_kill(is_elite: bool = false, is_boss: bool = false) -> void:
	kills += 1
	if is_elite:
		elite_kills += 1
	if is_boss:
		boss_kills += 1


func record_gold(amount: int) -> void:
	gold_collected += amount


func record_level(lvl: int) -> void:
	peak_level = max(peak_level, lvl)


func record_wave_cleared() -> void:
	waves_cleared += 1


func record_damage_dealt(amount: float, was_crit: bool = false) -> void:
	damage_dealt += amount
	if was_crit:
		crit_hits += 1


func record_damage_taken(amount: float) -> void:
	damage_taken += amount


func record_item_picked(item: ItemResource) -> void:
	items_picked += 1
	if item == null:
		return
	if item.rarity == ItemResource.Rarity.LEGENDARY:
		legendaries_found += 1
	if item.set_id != "":
		sets_found += 1


func format_time() -> String:
	var t: int = int(time_alive)
	return "%02d:%02d" % [t / 60, t % 60]


func summary() -> String:
	return "Wave reached: %d\nKills:        %d (%d elite, %d boss)\nDamage dealt: %d (%d crits)\nDamage taken: %d\nGold:         %d\nItems:        %d (%d legendary, %d set)\nTime:         %s\nPeak level:   %d" % [
		waves_cleared + 1, kills, elite_kills, boss_kills,
		int(damage_dealt), crit_hits, int(damage_taken),
		gold_collected, items_picked, legendaries_found, sets_found,
		format_time(), peak_level,
	]
