# Glossary

> Audience: agents and contributors meeting Flower's vocabulary for the first
> time. One-line definitions; follow the link for the full picture.

| Term | Definition |
|---|---|
| **Affix** | A randomly-rolled stat modifier on an item (e.g. "of Fury", "Cruel"). Names live in `scripts/items/item_factory.gd`. |
| **Autoload** | A Godot global singleton declared in `project.godot` `[autoload]`. Flower's: `DemonManager`, `HitFeedback`, `TransitionManager`, `PartyConfig`. See [Architecture Guide](../04-architecture/Architecture-Guide.md). |
| **Biome** | A themed dungeon palette (floor, walls, lighting, enemy mix). Defined as `BiomeDef` resources, rotated by `BiomeManager`. See [Biomes](../03-systems/Biomes.md). |
| **Boss wave** | Special wave gated by floor depth that spawns a unique high-HP enemy plus minions. Tracked in `RunStats.boss_kills`. |
| **Crit** | Critical hit. Roll vs `player_stats.crit_chance()`; multiplies damage by `crit_damage()`. Surfaced via the gold damage number. |
| **Difficulty mult** | Multiplier applied to enemy HP/damage based on selected difficulty (Normal/Hard/Hell). Lives in spawn manager / enemy base. |
| **Drop chance** | Probability that a slain enemy drops an item or gold; biased by enemy tier and elite affix. See [Loot & Economy](../03-systems/Loot-And-Economy.md). |
| **Elite** | Stronger variant of a base enemy with one or more **affixes** (Fast, Tanky, Vampiric, etc.). See `scripts/enemies/elite_affixes.gd`. |
| **Equipment** | Items currently worn by the player; their `stat_modifiers` are summed into `player_stats.modifiers`. Managed by `EquipmentManager`. |
| **Equipment slot** | One of 5 fixed slots: weapon, armor, helmet, ring, amulet. Slot accepts only items of matching `item_type`. |
| **Fog of War** | Map-coverage overlay revealed as the player explores. See `scripts/world/fog_of_war.gd`. |
| **Hit feedback** | Combined screen-shake + hit-stop + damage number + sprite flash on impact. Routed through the `HitFeedback` autoload. |
| **HUD** | The in-game heads-up display (orbs, hotbar, XP bar, wave counter, minimap). See `scenes/ui/game_hud.tscn`. |
| **Iframe** | "Invulnerability frame". Brief window after dodging during which the player ignores incoming damage. |
| **Item level (iLvl)** | The internal level rolled onto an item; gates affix tiers and base stat ranges. See [item-levels spec](../../specs/item-levels.md). |
| **Knockback** | Positional impulse applied to enemies on hit. Implemented as a decaying offset in `enemy_base._process` (see [Tech Debt](../07-roadmap/Tech-Debt.md)). |
| **Legendary** | Top-tier rarity. Always rolls max affixes plus a unique flavor name. Counted in `RunStats.legendaries_found`. |
| **Loot beam** | Vertical light beam rendered above dropped items, color-coded by rarity. |
| **Loot magnet** | Auto-pull radius that draws nearby pickups toward the player. Lives in `pickup_base.gd`. |
| **Modifier dict** | The `Dictionary` on `PlayerStats.modifiers` accumulating equipment/buff stat additions, keyed by stat name (e.g. `"attack_damage_flat"`). |
| **Pickup** | Any world entity the player walks over to collect (gold, items, soul wisps). Base class: `scripts/world/pickup_base.gd`. |
| **Rarity** | Item quality tier: Common → Magic → Rare → Legendary (and **Set**). Drives affix count and visual color. |
| **Resource (Godot)** | A data-only Godot class extending `Resource`; serializable to `.tres`. Flower uses these for items, skills, biomes, sets. |
| **RunStats** | Per-run counters (waves, kills, gold, time). Owned by `main` scene, *not* an autoload. See `scripts/run_stats.gd`. |
| **Set bonus** | Extra stats granted when wearing N pieces of the same set (2-piece, 4-piece, etc.). See `scripts/items/item_set.gd`. |
| **Set item** | An item belonging to a named set; contributes to set bonuses when other set pieces are equipped. |
| **Shrine** | One-shot interactable that grants a temporary buff to the first player who steps into it. See `scripts/world/shrine.gd`. |
| **Signature skill** | Class-defining skill auto-equipped to skill slot 1 on character spawn. Built by `CharacterClass.make_signature_skill()`. |
| **Soul** | Secondary resource (the blue orb). Spent on skills and consumed by demons during **Soul Drain**. |
| **Soul drain** | An enemy attack channel that bleeds the player's soul; resisted by `soul_drain_resist`. See [Soul System](../03-systems/Soul-System.md). |
| **Soul wisp** | Pickup that restores soul on contact. Drops from certain enemies. |
| **Spawn wave** | A scripted batch of enemies released by `SpawnManager`; clearing it advances `RunStats.waves_cleared`. |
| **Static-script pattern** | Calling functions via `preload(...)` rather than `class_name`; used to dodge Godot 4.6 self-reference issues (see `item_set.gd`, `biome_def.gd`). |
| **Temp buff** | Time-limited modifier applied via `PlayerStats` (e.g. shrine boon); decays automatically. |
| **Wave** | See **Spawn wave**. |
| **XP curve** | Function mapping level → required XP. Implemented in `player_stats.gd` (`xp_for_level`). |

## See also

- [Spec Index](Spec-Index.md) · [Test Index](Test-Index.md) · [Keybindings](Keybindings.md)
