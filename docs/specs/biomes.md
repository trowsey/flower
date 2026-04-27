# Spec: Biomes / Area Progression

## Goal
Visual + thematic variety across runs. Each biome defines floor/wall colors
and an enemy pool. The current biome advances every 5 cleared waves, with
the wave-counter HUD also displaying biome name.

## Biome data (Resource: `BiomeDef`)
```gdscript
class_name BiomeDef extends Resource

@export var biome_id: String         # "crypt", "cavern", "forge", "garden"
@export var display_name: String     # "The Crypt"
@export var floor_color: Color
@export var wall_color: Color
@export var ambient_color: Color     # WorldEnvironment ambient
@export var enemy_scenes: Array[String]  # PackedScene paths
```

## Biomes (initial 4)
1. **Crypt** — floor `#3a2e2a`, wall `#5a4d44`, ambient `#1a1820`.
   Enemies: skitterer, brute, archer.
2. **Cavern** — floor `#2a3a2e`, wall `#445a4d`, ambient `#181a18`.
   Enemies: skitterer, charger, bomber.
3. **Forge** — floor `#4a2e2a`, wall `#5a3a2a`, ambient `#2a1810`.
   Enemies: brute, charger, imp_caster, healer.
4. **Garden** — floor `#2a4a3a`, wall `#3a5a4a`, ambient `#102a18`.
   Enemies: skitterer, archer, bomber, healer.

## Progression
- Run starts in Crypt (wave 1-5).
- After every 5 cleared waves, advance to next biome (Crypt → Cavern → Forge
  → Garden → loops to Crypt with +1 difficulty tier).
- On biome change: show big banner "ENTERING: <Name>" for 2s.
- Floor/wall MeshInstance3D `albedo_color` is overridden via material clone.

## BiomeManager (Node, child of main scene)
```gdscript
func current_biome() -> BiomeDef
func advance_biome() -> void  # rotates + applies visuals + emits signal
signal biome_changed(biome: BiomeDef)
```

## Tests
- Biome rotates after 5 clears.
- Enemy pool used by `_spawn_wave` matches `current_biome().enemy_scenes`.
- Banner displays on biome_changed signal.
