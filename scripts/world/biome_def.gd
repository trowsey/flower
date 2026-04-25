# BiomeDef — data Resource defining a biome's visuals + enemy pool.
extends Resource
class_name BiomeDef

@export var biome_id: String = ""
@export var display_name: String = ""
@export var floor_color: Color = Color(0.4, 0.4, 0.4)
@export var wall_color: Color = Color(0.5, 0.5, 0.5)
@export var ambient_color: Color = Color(0.15, 0.15, 0.15)
@export var enemy_scenes: Array[String] = []


static func _make(id: String, dname: String, floor_c: Color, wall_c: Color, amb: Color, enemies: Array) -> Resource:
	var Script: GDScript = load("res://scripts/world/biome_def.gd")
	var b: Resource = Script.new()
	b.biome_id = id
	b.display_name = dname
	b.floor_color = floor_c
	b.wall_color = wall_c
	b.ambient_color = amb
	var typed: Array[String] = []
	for s in enemies:
		typed.append(s)
	b.enemy_scenes = typed
	return b


static func ALL() -> Array:
	return [
		_make("crypt", "The Crypt",
			Color(0.227, 0.180, 0.165), Color(0.353, 0.302, 0.267), Color(0.10, 0.094, 0.125),
			[
				"res://scenes/enemies/skitterer.tscn",
				"res://scenes/enemies/brute.tscn",
				"res://scenes/enemies/archer.tscn",
			]),
		_make("cavern", "Sunken Cavern",
			Color(0.165, 0.227, 0.180), Color(0.267, 0.353, 0.302), Color(0.094, 0.10, 0.094),
			[
				"res://scenes/enemies/skitterer.tscn",
				"res://scenes/enemies/charger.tscn",
				"res://scenes/enemies/bomber.tscn",
			]),
		_make("forge", "Demonic Forge",
			Color(0.290, 0.180, 0.165), Color(0.353, 0.227, 0.165), Color(0.165, 0.094, 0.063),
			[
				"res://scenes/enemies/brute.tscn",
				"res://scenes/enemies/charger.tscn",
				"res://scenes/enemies/healer.tscn",
			]),
		_make("garden", "Blighted Garden",
			Color(0.165, 0.290, 0.227), Color(0.227, 0.353, 0.290), Color(0.063, 0.165, 0.094),
			[
				"res://scenes/enemies/skitterer.tscn",
				"res://scenes/enemies/archer.tscn",
				"res://scenes/enemies/bomber.tscn",
				"res://scenes/enemies/healer.tscn",
			]),
	]
