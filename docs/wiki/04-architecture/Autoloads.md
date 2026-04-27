# Autoloads

The project has **four** autoloads, registered in `project.godot` under
`[autoload]`. Every other "global" lives in a Resource, a static module
(see [Resource Patterns](Resource-Patterns.md)), or a regular node owned by
`scenes/main.tscn`.

| Name | Script | Purpose |
|------|--------|---------|
| `DemonManager` | `scripts/demon_manager.gd` | Global one-at-a-time latch lock for soul-drain |
| `HitFeedback` | `scripts/vfx/hit_feedback.gd` | Combat reactions: shake, hit-stop, damage numbers, sprite flash |
| `TransitionManager` | `scripts/transition_manager.gd` | Screen fades + player repositioning across rooms/floors |
| `PartyConfig` | `scripts/party_config.gd` | Character + device selections that survive scene changes |

> **Rule:** Adding a 5th autoload requires an ADR. See [ADR Index](ADR-Index.md) and `architecture.md` §2.4.

---

## `DemonManager`

**Why an autoload:** soul-drain must enforce *exactly one* demon latched to
*one* target across the entire scene. A scene-tree node would either
duplicate the lock per-room or require painful lookups; a static module
can't hold mutable state cleanly.

**Key API** (`scripts/demon_manager.gd`):

```gdscript
func request_latch(demon: Node3D, target: Node = null) -> bool
func release_latch(demon: Node3D) -> void
func force_release() -> void
func is_latch_available() -> bool
func get_latched_demon() -> Node3D

signal latched(demon: Node3D)
signal released(demon: Node3D)
```

`request_latch` returns `false` if another demon already holds the lock and
also calls `target.begin_soul_drain(demon)` if available.

---

## `HitFeedback`

**Why an autoload:** "many producers → one router → many consumers" for
combat reactions. Producers (player, enemies) call methods; the camera and
VFX subscribe to the `request_*` signals. Decouples sources from sinks.

**Key API** (`scripts/vfx/hit_feedback.gd`):

```gdscript
# producer-facing methods
func enemy_hit(world_position: Vector3, amount: float, sprite_node: Node3D = null, is_critical: bool = false)
func player_hit(world_position: Vector3, amount: float, sprite_node: Node3D = null)
func heal(world_position: Vector3, amount: float)
func finisher_hit(world_position: Vector3, amount: float, sprite_node: Node3D = null)

# consumer-facing signals
signal request_camera_shake(intensity: float, duration: float)
signal request_hit_stop(real_seconds: float)
signal request_damage_number(world_position: Vector3, amount: float, color: Color)
signal request_sprite_flash(node: Node3D, color: Color, duration: float)
```

> ⚠ **Spec/code mismatch:** `enemy_hit(...)` is a **method**, not a signal
> (some docs and prompts describe it as a signal). The signals are the four
> `request_*` ones. ⚠ **Spec/code mismatch:** `enemy_base.gd:189` calls
> `HitFeedback.explosion(...)` and `player.gd:884` references the same
> object — neither method exists in `hit_feedback.gd`. Either add the
> method or remove the calls; this currently raises at runtime when an
> enemy with `death_explosion_radius > 0` dies.

---

## `TransitionManager`

**Why an autoload:** owns a top-layer (`CanvasLayer.layer = 100`) fade
overlay that must persist across room loads. A scene-local fade would be
torn down mid-transition.

**Key API** (`scripts/transition_manager.gd`):

```gdscript
func fade_to_room(player: Node3D, target_position: Vector3, fade_duration: float = 0.3)
func fade_to_floor(player: Node3D, target_position: Vector3, fade_duration: float = 0.8)
func is_transitioning() -> bool

signal transition_started
signal transition_finished
```

Both `fade_*` methods are `await`-able via `transition_finished` and no-op
if a transition is already in flight.

---

## `PartyConfig`

**Why an autoload:** player choices in `character_select.tscn` must survive
the load of `main.tscn`. The alternative (passing a Resource via
`set_meta` on the SceneTree root) was deemed more fragile. See ADR-008.

**Key API** (`scripts/party_config.gd`):

```gdscript
var slots: Array  # [{character_class_id: int, device_id: int}, ...]

func clear()
func add_slot(class_id: int, device_id: int)
func set_solo(class_id: int)
func set_two_player(p1_class: int, p2_class: int, p1_device := -1, p2_device := 0)
func player_count() -> int
func get_slot(index: int) -> Dictionary
```

Cross-scene state lives on the autoload itself (`slots` array). One thing
*does* use `set_meta` — `scripts/main.gd:148` reads
`PartyConfig.get_meta("difficulty_mult", 1.0)`, set by the main menu.
That's an informal extension point; if it grows, promote it to a typed
field with a setter.

---

## Adding a 5th autoload

Don't. If you must:

1. Write an ADR in `docs/adr/` (template TODO — see [ADR Index](ADR-Index.md)).
2. Justify why a static module + scene-owned node combination won't work.
3. Get architecture approval before merging the `project.godot` change.

> ⚠ **Spec/code mismatch:** `architecture.md` §2.4 still says "Resist
> adding a *fourth* singleton" and ADR-005 is titled "Three autoloads".
> Both predate ADR-008 (PartyConfig). The current bar is **fifth**.
