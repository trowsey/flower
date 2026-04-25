# BiomeManager — tracks current biome, advances every N waves.
# Instanced as a child of main; reads main.current_wave; emits biome_changed
# when it rotates so visuals + spawn pool can update.
extends Node
class_name BiomeManager

const BiomeDefScript = preload("res://scripts/world/biome_def.gd")
const WAVES_PER_BIOME := 5

signal biome_changed(biome: Resource)

var _biomes: Array = []
var _index: int = 0
var difficulty_loop: int = 0  # +1 each full rotation


func _ready() -> void:
	_biomes = BiomeDefScript.ALL()


func current() -> Resource:
	if _biomes.size() == 0:
		_biomes = BiomeDefScript.ALL()
	return _biomes[_index]


func enemy_pool() -> Array:
	return current().enemy_scenes


func notify_wave_cleared(wave_just_cleared: int) -> void:
	# Rotate after every WAVES_PER_BIOME cleared waves
	if wave_just_cleared % WAVES_PER_BIOME == 0:
		_index = (_index + 1) % _biomes.size()
		if _index == 0:
			difficulty_loop += 1
		biome_changed.emit(current())
