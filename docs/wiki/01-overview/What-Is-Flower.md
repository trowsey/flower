# What Is Flower

Flower is a **Diablo-like 3D action RPG** built in **Godot 4.6** with **GDScript**. Top-down isometric camera, click-or-WASD movement, mouse-or-stick aim, click-to-loot, kill-stuff-take-loot-level-up loop.

## The pitch

Pick one of four hand-rolled characters, drop into a procedurally-themed dungeon, fight escalating waves of demons and monsters, hoover up gold and rarity-tinted gear, level up and dump points into 4 stats, and chase a 5-piece set bonus until something kills you. Then do it again. Couch co-op for two with controllers. A run is short — the wave loop is built for sub-30-minute sessions.

## Scope

- **One programmer + an AI workforce.** See [`AGENTS.md`](../../../AGENTS.md) and `.agents/squads/engineering/` for the TDD agent pipeline (Spec-writer → Architect → Test-writer → Implementer → Code-reviewer → Test-runner).
- **Small game, deliberately.** Architectural decisions live in [`docs/architecture.md`](../../architecture.md) and exist to serve a one-person-plus-AI team, not an enterprise project.
- **No artists yet.** All character sprites are color-tinted placeholders; demons and props are CSG/MeshInstance primitives. The art layer is mockable behind real game logic.

## Status: alpha

What's playable today (commit `3fea189` and after):

- 4 character classes — Sarah (Bladedancer), Maddie (Bruiser), Chan Xaic (Soulcaster), Aiyana (Wardweaver). Each has unique base stats and a signature skill on slot 1. See [`scripts/items/character_class.gd`](../../../scripts/items/character_class.gd).
- 7 enemy types (skitterer, brute, archer, bomber, charger, healer, imp_caster) plus elite affixes and boss-every-10-waves scaling.
- Wave-based survival loop with 4 rotating biomes (Crypt → Cavern → Forge → Garden, then loops with +20% difficulty per loop).
- 5-slot equipment, 30-slot inventory, 5 rarity tiers with item-level scaling, 3 named item sets with 2/4/5-piece bonuses.
- Per-class signature skill + 3 free skill slots, 4-stat allocation (STR/VIT/SPI/AGI), XP curve to level 50.
- Hit feedback (camera shake, hit-stop, damage numbers, sprite flash, blood particles), dash, loot magnet, revive system for co-op, soul-drain mechanic, shrines.
- Local 2-player couch co-op with per-device input filtering.
- Tutorial overlay, pause menu, settings (audio buses, fullscreen, vsync, camera shake, damage numbers toggle), death recap, main-menu → player-count → character-select flow.

## Not in scope

- **No MMO, no online multiplayer.** Local couch co-op only. No netcode planned.
- **No PvP.**
- **No story mode, no scripted bosses, no NPCs/vendors yet.** The vendor concept is specced ([`docs/specs/gold-economy.md`](../../specs/gold-economy.md)) but not implemented.
- **No save system.** Runs are ephemeral. Settings persist via `user://settings.cfg`; party config persists via the `PartyConfig` autoload only across scene changes within a session.
- **No skill tree.** Stat allocation only.
- **No GDExtension / native code.** GDScript only — see ADR-001 in [`docs/architecture.md`](../../architecture.md).

## Where to read next

- [Game Design Pillars](Game-Design-Pillars.md) — what we optimize for.
- [Current Feature Matrix](Current-Feature-Matrix.md) — shipped vs specced vs planned.
- [`docs/architecture.md`](../../architecture.md) — system map, layering rules, ADRs.
- [`docs/principles.md`](../../principles.md) — daily-driver coding rules.
