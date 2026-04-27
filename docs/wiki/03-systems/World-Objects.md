# World Objects

## Purpose
Non-enemy entities that populate the play area: destructible props (urns, crates) that drop loot when broken; shrines that grant temporary buffs; pickups that hover and collect on contact. Player-facing behavior: shoot a barrel, get gold/items; touch a glowing pillar, get 20s of "Swift / Wrath / Fortune / Iron"; walk near a dropped item to suck it in.

## Key files
- `scripts/world/destructible.gd` — `Destructible extends StaticBody3D`, `take_damage` chain, gold/item drops.
- `scripts/world/shrine.gd` — `Shrine extends Area3D`, single-use buff dispenser.
- `scripts/world/pickup_base.gd` — `PickupBase extends Area3D`, hover sine, "pickups" group.
- `scripts/world/item_pickup.gd` — extends `pickup_base.gd`; sets rarity tint + light beam.
- `scripts/world/gold_pickup.gd` — extends `pickup_base.gd`; calls `player.add_gold`.

## Data flow
```
Destructible
  joins "destructibles" group, collision_layer=1
  AttackArea (mask=4) overlaps it via the player's combo
    → player._deal_damage finds it via is_in_group("destructibles")
    → take_damage(amount) → break_apart() at 0 HP
       randi_range(gold_min, gold_max) → spawn gold_pickup
       randf() < item_drop_chance → spawn item_pickup with ItemFactory.make_random()
       queue_free

Shrine
  added by main._spawn_shrine on (wave>=3 and wave%3==0)
  group "shrines", collision_layer=0, mask=2 (player layer)
  body_entered → if player and not used:
      used = true
      player.apply_temp_buff(buff.id, buff.mods, 20.0)
      emit activated(player, buff.id)
      fade _mesh modulate to grey, _light energy → 0

Pickup (base)
  layer 0 / mask 2; monitoring=true; group "pickups"
  _process: y oscillates ±hover_height around base_y
  player magnet (Player._process_magnet) pulls toward player when within radius
  collect(player) called from player._on_pickup_area_entered
```

## Public API
**`Destructible`** (`class_name Destructible extends StaticBody3D`):
```gdscript
signal destroyed(node: Node3D)
@export var max_health: float = 1.0
@export var gold_min: int = 0
@export var gold_max: int = 3
@export var item_drop_chance: float = 0.05
func take_damage(amount: float) -> void
```
Joins `"destructibles"` group on `_ready`. Player damage routes via the combo's "is_in_group" check.

**`Shrine`** (`class_name Shrine extends Area3D`):
```gdscript
signal activated(player: Node3D, buff_id: String)
const BUFF_DURATION := 20.0
const BUFFS := [
    {"id":"swift",  "mods":{"move_speed_bonus":2.0}},
    {"id":"wrath",  "mods":{"attack_damage_flat":15.0}},
    {"id":"fortune","mods":{"crit_chance_bonus":0.25}},
    {"id":"iron",   "mods":{"defense_flat":5.0}},
]
var buff: Dictionary       # picked at _ready via BUFFS.pick_random()
var used: bool             # one-shot
```
Builds its own `CollisionShape3D` (sphere r=1.5), `MeshInstance3D` (cylinder, emissive gold), and `OmniLight3D` procedurally — no `.tscn` required.

**`PickupBase`** (`class_name PickupBase extends Area3D`):
```gdscript
signal collected(player: Node3D)
@export var hover_speed := 2.0
@export var hover_height := 0.15
func collect(_player) -> void   # override
```
Joins `"pickups"` group; that's how `Player._process_magnet` finds them.

**`GoldPickup`** / **`ItemPickup`** — see [Items-And-Loot](Items-And-Loot.md). Both override `collect`.

## Tests
- `tests/unit/test_shrine.gd` — single-use, applies buff to player via `apply_temp_buff`, mods composition.
- `tests/unit/test_world.gd` — destructible damage path (and `DungeonGenerator`).
- `tests/unit/test_economy.gd` — pickups and magnet integration.
- Gap: no test that a Destructible's drop chance is wired (counts on `test_world.gd`'s smoke coverage).

## Extending
**Add a new shrine buff:** append to `Shrine.BUFFS` with a unique `id` (the id is also the buff key in `Player._temp_buffs`, so unique ids prevent stacking-by-refresh from a different buff).

**Add a new world object (e.g. cursed pillar that summons enemies):** new script extending `Area3D` or `StaticBody3D`. Join an appropriate group (`"interactables"` is a common addition); use `body_entered` for triggers. Spawn from `main.gd` (or a new `WorldObjectManager`) using the same pattern as `_spawn_shrine`.

**Make pickups single-collector in 2P:** currently any player overlapping an item collects it. Mark the pickup as "claimed" on first overlap to avoid double-collect races.

## Known gaps
- Shrine has no UI feedback beyond the visual fade — no popup naming the buff.
- `Destructible.collision_layer = 1` (world layer) means it blocks movement and the player attack hits via overlap — fine, but means destructibles can soak combo damage you intended for enemies behind them.
- No prop "cluster" spawner — destructibles must be hand-placed in the scene.
- Shrine spawn placement is unconstrained (`main._spawn_shrine` uses `cos/sin * (6..10)`), can land inside walls.

## Spec/code mismatches
- `docs/specs/destructibles.md` lists drop scaling that may differ from `Destructible`'s flat 5% chance — code is canonical.
- The shrine system is **NEW** and likely not yet in `docs/specs/`. Drop a `docs/specs/shrines.md` if formal spec coverage is desired.
