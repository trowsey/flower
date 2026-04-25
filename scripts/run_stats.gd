# RunStats — tracks per-run statistics, displayed in the death recap.
# Instanced as a child of main scene (not autoload — owned by the run).
extends Node
class_name RunStats

var waves_cleared: int = 0
var kills: int = 0
var elite_kills: int = 0
var gold_collected: int = 0
var time_alive: float = 0.0
var peak_level: int = 1


func _process(delta: float) -> void:
	time_alive += delta


func record_kill(is_elite: bool = false) -> void:
	kills += 1
	if is_elite:
		elite_kills += 1


func record_gold(amount: int) -> void:
	gold_collected += amount


func record_level(lvl: int) -> void:
	peak_level = max(peak_level, lvl)


func record_wave_cleared() -> void:
	waves_cleared += 1


func format_time() -> String:
	var t: int = int(time_alive)
	return "%02d:%02d" % [t / 60, t % 60]


func summary() -> String:
	return "Wave reached: %d\nKills:        %d (%d elite)\nGold:         %d\nTime:         %s\nPeak level:   %d" % [
		waves_cleared + 1, kills, elite_kills, gold_collected, format_time(), peak_level,
	]
