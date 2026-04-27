# Current Feature Matrix

Status as of commit `3fea189` and after. **190 unit tests + 10 E2E checks passing baseline.**

Legend: ✅ shipped · 🚧 in progress · 📋 specced · ❌ not planned

## Combat

| Feature | Status | Tests | Spec |
|---|---|---|---|
| Click-to-move + WASD/stick movement | ✅ | `test_player_movement.gd` | [player-movement](../../specs/player-movement.md) |
| Mouse + controller attack | ✅ | `test_player_attack.gd` | [player-attack](../../specs/player-attack.md) |
| 3-stage combo (`[1.0, 1.25, 1.75]× damage`, 0.5s window) | ✅ | `test_player_combat_polish.gd` | [combo-attacks](../../specs/combo-attacks.md) |
| Crit chance/damage (10% base, 2.0×) | ✅ | `test_xp_and_crit_stats.gd` | — |
| Dash (Shift / R1, 5u over 0.18s, 1.2s cd) | ✅ | `test_player_extras.gd` | — |
| Hit feedback (shake + hit-stop + numbers + flash) | ✅ | — | [hit-feedback](../../specs/hit-feedback.md) |
| Blood particles | ✅ | — | [blood-particles](../../specs/blood-particles.md) |
| Death explosions (bombers, "explosive" elites) | ✅ | `test_new_enemies.gd` | [death-explosions](../../specs/death-explosions.md) |
| Soul-drain mechanic (15s, demon latch) | ✅ | `test_soul_drain.gd` | [soul-system](../../specs/soul-system.md) |
| Soul wisp VFX | 📋 | — | [soul-wisp-vfx](../../specs/soul-wisp-vfx.md) |
| I-frames after hit (0.4s) | ✅ | `test_player_combat_polish.gd` | — |

## Loot & items

| Feature | Status | Tests | Spec |
|---|---|---|---|
| 5-tier rarity, weighted rolls (60/25/10/4/1) | ✅ | `test_item_factory.gd` | [item-drops](../../specs/item-drops.md) |
| Item-level scaling on drops | ✅ | `test_item_levels.gd` | [item-levels](../../specs/item-levels.md) |
| Procedural names (prefix + base + suffix) | ✅ | `test_item_factory.gd` | [item-drops](../../specs/item-drops.md) |
| Rarity tint + emission, beam on Rare+ | ✅ | — | [item-drops](../../specs/item-drops.md) |
| 5 equipment slots (weapon/armor/helmet/ring/amulet) | ✅ | `test_inventory.gd` | [equipment-slots](../../specs/equipment-slots.md) |
| 30-slot inventory | ✅ | `test_inventory.gd` | [inventory-screen](../../specs/inventory-screen.md) |
| 7 stat modifier types stacking via `EquipmentManager` | ✅ | `test_inventory.gd` | [equipment-slots](../../specs/equipment-slots.md) |
| 3 named item sets w/ 2/4/5-piece bonuses | ✅ | `test_set_items.gd` | [set-items](../../specs/set-items.md) |
| Set drops (3% baseline, 25% from bosses) | ✅ | `test_set_items.gd` | [set-items](../../specs/set-items.md) |
| Loot magnet (3u radius, 6u/s pull) | ✅ | — | — |
| Consumables (health potion, soul tonic) | ✅ | — | — |
| Sell items (rarity- and iLvl-scaled gold) | ✅ | `test_economy.gd` | [gold-economy](../../specs/gold-economy.md) |
| Vendor NPC | 📋 | — | [gold-economy](../../specs/gold-economy.md) |

## Progression

| Feature | Status | Tests | Spec |
|---|---|---|---|
| XP curve (1.12^n, max level 50) | ✅ | `test_progression.gd`, `test_player_stats.gd` | [xp-leveling](../../specs/xp-leveling.md) |
| 4-stat allocation (STR/VIT/SPI/AGI, 3pt/level) | ✅ | `test_player_stats.gd` | [level-up](../../specs/level-up.md) |
| Level-up toast + stat panel (`C` key) | ✅ | — | [level-up](../../specs/level-up.md) |
| Wave counter, +10% difficulty/wave | ✅ | — | [wave-counter](../../specs/wave-counter.md) |
| Forced elite every 5 waves | ✅ | — | [wave-counter](../../specs/wave-counter.md) |
| Boss every 10 waves (5× HP, 5× XP) | ✅ | — | — |
| 4 biomes rotating every 5 waves | ✅ | `test_biomes.gd` | [biomes](../../specs/biomes.md) |
| Biome-loop difficulty tier (+20%/loop) | ✅ | `test_biomes.gd` | [biomes](../../specs/biomes.md) |
| Shrines (every 3 waves from wave 3, 4 buff types, 20s) | ✅ | `test_shrine.gd` | — |

## Enemies

| Feature | Status | Tests | Spec |
|---|---|---|---|
| `EnemyBase` w/ HP, knockback, hit-flash, drops | ✅ | `test_enemy_base.gd` | — |
| Skitterer (fast melee swarmer) | ✅ | `test_enemy_base.gd` | [enemy-variety](../../specs/enemy-variety.md) |
| Brute (slow tank) | ✅ | `test_enemy_base.gd` | [enemy-variety](../../specs/enemy-variety.md) |
| Imp Caster (lobbed projectile) | ✅ | — | [enemy-variety](../../specs/enemy-variety.md) |
| Skeleton Archer (ranged kiter) | ✅ | `test_new_enemies.gd` | [enemy-variety-v2](../../specs/enemy-variety-v2.md) |
| Bomber (chase + fuse + explode) | ✅ | `test_new_enemies.gd` | [enemy-variety-v2](../../specs/enemy-variety-v2.md) |
| Charger (telegraph + dash) | ✅ | `test_new_enemies.gd` | [enemy-variety-v2](../../specs/enemy-variety-v2.md) |
| Cult Healer (keeps distance, heals allies) | ✅ | `test_new_enemies.gd` | [enemy-variety-v2](../../specs/enemy-variety-v2.md) |
| Soul-draining `DemonBase` (latch FSM) | ✅ | `test_soul_drain.gd` | [demon-behavior](../../specs/demon-behavior.md) |
| Elite affixes (fast/tough/explosive/venomous/armored) | ✅ | — | [elite-enemies](../../specs/elite-enemies.md) |
| Floating health bars | 📋 | — | [enemy-health-bars](../../specs/enemy-health-bars.md) |
| Demon assets (real sprites) | ❌ | — | [demon-assets](../../specs/demon-assets.md) |

## UI / HUD

| Feature | Status | Tests | Spec |
|---|---|---|---|
| Main menu | ✅ | — | [main-menu](../../specs/main-menu.md) |
| Player count screen | ✅ | — | — |
| Character select (per-player class + device) | ✅ | `test_character_class.gd`, `test_party_config.gd` | — |
| Game HUD (per-player panel) | ✅ | — | — |
| Wave label / banner | ✅ | — | [wave-counter](../../specs/wave-counter.md) |
| Health/mana orbs | ✅ | — | [health-mana-orbs](../../specs/health-mana-orbs.md) |
| Skill hotbar (4 slots, cooldown overlay) | ✅ | — | [skill-hotbar](../../specs/skill-hotbar.md) |
| XP bar | ✅ | — | [xp-bar](../../specs/xp-bar.md) |
| Inventory screen (5 equip slots + 30-grid bag) | ✅ | — | [inventory-screen](../../specs/inventory-screen.md), [inventory-ui](../../specs/inventory-ui.md) |
| Tutorial overlay (first-run, dismissable) | ✅ | — | [tutorial-overlay](../../specs/tutorial-overlay.md) |
| Pause menu (audio + fullscreen) | ✅ | `test_settings.gd` | — |
| Settings menu (full) | ✅ | `test_settings.gd` | — |
| Game-over screen + death recap | ✅ | `test_run_stats.gd` | [death-recap](../../specs/death-recap.md) |
| Damage indicator (red vignette on hit) | ✅ | — | — |
| Minimap (fog-revealed tiles) | ✅ | `test_world.gd` | [minimap](../../specs/minimap.md) |

## World

| Feature | Status | Tests | Spec |
|---|---|---|---|
| Single-room main scene + wave spawn ring | ✅ | — | [scene-layout](../../specs/scene-layout.md) |
| Camera follow (orthographic, smoothed) | ✅ | `test_camera_follow.gd` | [camera-follow](../../specs/camera-follow.md) |
| Camera shake | ✅ | — | [hit-feedback](../../specs/hit-feedback.md) |
| Fog of war (grid-based reveal) | ✅ | `test_world.gd` | [fog-of-war](../../specs/fog-of-war.md) |
| Destructible objects | ✅ | `test_world.gd` | [destructibles](../../specs/destructibles.md) |
| Gold pickups (hovering, magnetized) | ✅ | `test_economy.gd` | [gold-economy](../../specs/gold-economy.md) |
| Item pickups | ✅ | — | [item-drops](../../specs/item-drops.md) |
| Shrines (random temp buff) | ✅ | `test_shrine.gd` | — |
| Procedural rooms (3×3 grid, doors) | 🚧 | — | [procedural-rooms](../../specs/procedural-rooms.md) |
| Room transitions (fade, repositioning) | 🚧 | — | [room-transitions](../../specs/room-transitions.md) |

## Multiplayer (couch co-op)

| Feature | Status | Tests | Spec |
|---|---|---|---|
| `PartyConfig` autoload | ✅ | `test_party_config.gd` | — |
| Per-device input filtering on `Player` | ✅ | — | — |
| Auto-spawn extra players from slots | ✅ | — | — |
| Per-player HUD panel | ✅ | — | — |
| Co-op enemy scaling (+25% HP per extra player) | ✅ | — | — |
| Revive system (2.5u radius, 2.0s channel) | ✅ | `test_player_extras.gd` | — |
| Online multiplayer | ❌ | — | — |

## Audio

| Feature | Status | Tests | Spec |
|---|---|---|---|
| Audio bus layout (master/music/sfx) | ✅ | `test_settings.gd` | — |
| Settings persistence (`user://settings.cfg`) | ✅ | `test_settings.gd` | — |
| `AmbientAudio` ambient/combat track switch | ✅ | — | [ambient-sound](../../specs/ambient-sound.md) |
| Real audio assets (loops, hit sounds) | ❌ | — | [ambient-sound](../../specs/ambient-sound.md) |

## Tooling / infra

| Feature | Status | Tests | Spec |
|---|---|---|---|
| GUT vendored (`addons/gut/`, patched for 4.6) | ✅ | — | — |
| Headless E2E autobot (10 checks) | ✅ | — | — |
| Engineering squad agent definitions | ✅ | — | — |
| Save/load runs | ❌ | — | — |
| Skill tree | ❌ | — | — |
| Story mode / NPCs | ❌ | — | — |
| PvP / online | ❌ | — | — |

## Spec/code mismatches noted

While building this matrix:

- **`docs/specs/inventory-screen.md` REQ-1** says opening the inventory pauses the game (`get_tree().paused = true`). Implementation in `scripts/ui/inventory_screen.gd::toggle()` only flips `visible`; combat continues while the bag is open.
- **`docs/specs/death-recap.md`** specifies `RunStats` as `RefCounted`. Actual implementation in `scripts/run_stats.gd` is `extends Node` (so it can `_process` for `time_alive`).
- **`docs/specs/biomes.md`** requires a "ENTERING: <Name>" banner for 2s on biome change. `BiomeManager` emits the signal and `main.gd` updates the floor/wall/ambient colors, but no banner UI is currently implemented.
- **`docs/specs/player-attack.md` REQ-6/REQ-10** still claim a fixed `ATTACK_DAMAGE = 25.0` constant. Damage now flows through `stats.attack_damage() * COMBO_DAMAGE_MULT[stage]` with crit roll. The combo-attacks spec supersedes; player-attack should be marked obsolete.
- **`docs/specs/level-up.md`** specifies `C` *or* `Tab` opens the panel. Only `C` is wired in `level_up_panel.gd`; the `character` input action is referenced but not declared in `project.godot`.
- **`docs/specs/input-config.md`** Out of Scope claims "Multiple controller support" — but couch co-op with multiple controllers is implemented. Spec is outdated.
- **`docs/specs/input-config.md` REQ-8** describes a `dodge` action on the B button. The action exists in `project.godot` but the implemented dash uses `Shift` / right-shoulder (R1) via `_is_dash_event`, not `dodge`.
