# Signals Catalog

Every cross-system signal in the codebase. **Internal-to-one-script**
signals (e.g. UI button `pressed`, `tween_finished`) are excluded.

If you're wiring a new feature, scan this first — chances are the data
you need is already broadcast somewhere.

> Format: each row lists the **emitter**, the **signature**, the
> **listeners** found by `grep '<signal>.connect('`, and the **purpose**.
> A signal with no listeners is flagged ⚠.

---

## `HitFeedback` (autoload — `scripts/vfx/hit_feedback.gd`)

| Signal | Listeners | Purpose |
|--------|-----------|---------|
| `request_camera_shake(intensity: float, duration: float)` | `scripts/camera.gd:24` | Camera applies shake scaled by Settings |
| `request_hit_stop(real_seconds: float)` | `scripts/camera.gd:25` | Camera freezes time briefly on impact |
| `request_damage_number(world_position: Vector3, amount: float, color: Color)` | ⚠ no `.connect()` — likely consumed by an auto-spawned `damage_number.tscn` instance | Pop floating damage text |
| `request_sprite_flash(node: Node3D, color: Color, duration: float)` | ⚠ no `.connect()` listener found | Flash an enemy/player sprite |

> **Note:** producers call methods on `HitFeedback` (`enemy_hit`,
> `player_hit`, `heal`, `finisher_hit`); the autoload re-emits the
> appropriate `request_*` signals. See [Autoloads](Autoloads.md).

---

## `DemonManager` (autoload — `scripts/demon_manager.gd`)

| Signal | Listeners | Purpose |
|--------|-----------|---------|
| `latched(demon: Node3D)` | (none direct — gates via return value) | Notify when a demon acquires the global latch lock |
| `released(demon: Node3D)` | (none direct) | Notify when the lock is released |

---

## `TransitionManager` (autoload — `scripts/transition_manager.gd`)

| Signal | Listeners | Purpose |
|--------|-----------|---------|
| `transition_started` | (callers `await` instead) | Fade-out begins |
| `transition_finished` | (callers `await` instead) | Player has been moved + fade-in done |

---

## `Player` (`scripts/player.gd`, instance per player)

| Signal | Listeners | Purpose |
|--------|-----------|---------|
| `health_changed(new_value: float)` | `scripts/ui/health_mana_orbs.gd:23`, `scripts/ui/game_hud.gd:197`, `scripts/ui/damage_indicator.gd:23` | Refresh orbs, HUD, red-vignette on damage |
| `max_health_changed(new_max: float)` | `scripts/ui/health_mana_orbs.gd:25`, `scripts/ui/game_hud.gd:203` | Resize health bar after stats change |
| `soul_changed(new_value: float)` | `scripts/ui/health_mana_orbs.gd:24`, `scripts/ui/game_hud.gd:199` | Refresh soul orb |
| `max_soul_changed(new_max: float)` | `scripts/ui/health_mana_orbs.gd:26`, `scripts/ui/game_hud.gd:205` | Resize soul orb |
| `gold_changed(new_amount: int)` | `scripts/ui/game_hud.gd:201`, `scripts/main.gd:114` | HUD update + run-stats accumulator |
| `xp_gained(amount: float)` | `scripts/ui/game_hud.gd:207` | XP bar refresh |
| `level_up(new_level: int)` | `scripts/ui/game_hud.gd:209`, `scripts/ui/level_up_panel.gd:36`, `scripts/main.gd:111` | Open stat-point panel; record in run stats |
| `stats_recalculated` | `scripts/ui/inventory_screen.gd:47` | Inventory tooltip totals refresh |
| `item_picked_up(item: ItemResource)` | `scripts/main.gd:120` | Run-stats records the pickup |
| `player_died(reason: String)` | `scripts/ui/game_over_screen.gd:23` | Show game-over screen (`reason` is `"health"` or `"soul"`) |
| `latch_started(demon: Node3D)` / `latch_broken(demon: Node3D)` | (no cross-system listeners; player-internal flow uses them) | Demon-drain UI hooks (currently unused) |
| `player_state_changed(new_state: int)` / `combo_advanced(stage: int)` / `dashed` / `player_downed` / `player_revived` | (no cross-system listeners yet) | Reserved for future UI/SFX |

> ⚠ **Spec/code mismatch:** these signals carry only `(new_value)` —
> *not* `(current, max)` as some prompts describe. Consumers that need the
> max read it via `player.stats.max_health()` or by listening to
> `max_health_changed`. There is **no `Player.equipment_changed` signal**;
> equipment changes are broadcast by `player.equipment.equipment_changed`
> (see EquipmentManager below). There is **no `Player.died`** — the actual
> name is `player_died`.

---

## `EnemyBase` (`scripts/enemies/enemy_base.gd`, instance per enemy)

| Signal | Listeners | Purpose |
|--------|-----------|---------|
| `enemy_died(enemy: Node3D)` | (no `.connect()` — main listens to `tree_exiting` instead at `main.gd:187`) | Death broadcast for systems that want it |
| `health_changed(new_value: float)` | `scripts/ui/enemy_health_bar.gd:26` | Health-bar refresh above the enemy |

> ⚠ **Spec/code mismatch:** `enemy_died` carries the **enemy node**, not a
> score value. Score / kill stats are accumulated in `main.gd::_on_enemy_removed`
> via `tree_exiting`, not via this signal.

---

## `Main` (`scripts/main.gd`, root of `scenes/main.tscn`)

| Signal | Listeners | Purpose |
|--------|-----------|---------|
| `wave_started(wave: int)` | `scripts/ui/game_hud.gd:150` | HUD wave counter |
| `wave_cleared(wave: int)` | (none — `_process` handles transition internally) | Hook for future "wave complete" SFX/VFX |
| `biome_changed(biome: Resource)` | `scripts/ui/game_hud.gd:152` | HUD biome label/icon |

---

## `BiomeManager` (`scripts/world/biome_manager.gd`, child of Main)

| Signal | Listeners | Purpose |
|--------|-----------|---------|
| `biome_changed(biome: Resource)` | `scripts/main.gd:56` (then re-emitted by Main) | Biome rotated; main applies visuals |

---

## `EquipmentManager` (`scripts/items/equipment_manager.gd`, owned by Player as `player.equipment`)

| Signal | Listeners | Purpose |
|--------|-----------|---------|
| `equipment_changed(slot_type: int, new_item: ItemResource, old_item: ItemResource)` | `scripts/player.gd:120`, `scripts/ui/inventory_screen.gd:48` | Player recalculates stats; inventory UI refreshes |

---

## `Inventory` (`scripts/items/inventory.gd`, owned by Player as `player.inventory`)

| Signal | Listeners | Purpose |
|--------|-----------|---------|
| `items_changed` | `scripts/ui/inventory_screen.gd:46` | Bag UI refresh |
| `item_added(item, slot)` / `item_removed(item, slot)` | (no cross-system listeners) | Granular hooks; UI uses `items_changed` instead |

---

## `PlayerStats` (`scripts/items/player_stats.gd`, owned by Player as `player.stats`)

| Signal | Listeners | Purpose |
|--------|-----------|---------|
| `stats_changed` | `scripts/player.gd:121` | Player re-derives derived values, emits its own signals |
| `level_changed(new_level: int)` | `scripts/player.gd:122` | Player notifies UI via `level_up` |

---

## World pickups & destructibles

| Emitter | Signal | Listeners | Purpose |
|---------|--------|-----------|---------|
| `PickupBase` (`scripts/world/pickup_base.gd`) | `collected(player: Node3D)` | (subclass-internal) | Item / gold pickup hook |
| `Shrine` (`scripts/world/shrine.gd`) | `activated(player: Node3D, buff_id: String)` | (no cross-system listeners) | Reserved for HUD/SFX |
| `Destructible` (`scripts/world/destructible.gd`) | `destroyed(node: Node3D)` | (no cross-system listeners) | Reserved |

---

## Autobot

| Emitter | Signal | Listeners | Purpose |
|---------|--------|-----------|---------|
| `Autobot` (`scripts/e2e/autobot.gd`) | `autobot_finished(passed: bool, results: Array)` | `autobot_runner.gd` | Headless E2E test completion |

---

## Quick rule of thumb for adding signals

1. If only **one** script will ever listen → call its method directly.
2. If consumers **don't know about producers** (or vice-versa) → signal.
3. If many producers feed many consumers → route through an autoload like
   `HitFeedback` (see [Autoloads](Autoloads.md)).
4. Past tense names (`died`, `equipment_changed`) — see [Coding Standards](../05-contributing/Coding-Standards.md).
