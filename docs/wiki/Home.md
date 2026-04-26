# Flower — Wiki

> A small-scope Diablo-like 3D action RPG built in Godot 4.6 with GDScript.
> Killing demons, picking up loot, levelling up, repeat.

This wiki is the front door for everyone working on Flower — humans and
agents alike. If you can't find what you need in three clicks from here,
that's a bug. [Open an issue](../../issues/new) or fix it.

---

## Quick links

- **Just want to play?** → [Running The Game](02-getting-started/Running-The-Game.md)
- **Just want to contribute?** → [Workflow](05-contributing/Workflow.md) → [Repo Layout](02-getting-started/Repo-Layout.md)
- **Architecting a change?** → [Architecture Guide](04-architecture/Architecture-Guide.md) → [Principles](04-architecture/Principles-In-Practice.md)
- **Asking "where does X live?"** → [Spec Index](06-reference/Spec-Index.md) · [Test Index](06-reference/Test-Index.md)
- **Wondering what's next?** → [Roadmap](07-roadmap/Future-Work.md)

---

## By audience

### 🎮 Players & designers
1. [What Is Flower](01-overview/What-Is-Flower.md)
2. [Game Design Pillars](01-overview/Game-Design-Pillars.md)
3. [Current Feature Matrix](01-overview/Current-Feature-Matrix.md)
4. [Keybindings](06-reference/Keybindings.md)
5. [Glossary](06-reference/Glossary.md)

### 🛠 Contributors
1. [Installing Godot](02-getting-started/Installing-Godot.md)
2. [Running The Game](02-getting-started/Running-The-Game.md)
3. [Running Tests](02-getting-started/Running-Tests.md)
4. [Repo Layout](02-getting-started/Repo-Layout.md)
5. [Workflow](05-contributing/Workflow.md)
6. [Coding Standards](05-contributing/Coding-Standards.md)
7. [Writing Tests](05-contributing/Writing-Tests.md)
8. [Writing Specs](05-contributing/Writing-Specs.md)
9. [Commit & PR Conventions](05-contributing/Commit-And-PR-Conventions.md)

### 🏗 Architects & reviewers
1. [Architecture Guide](04-architecture/Architecture-Guide.md)
2. [Principles In Practice](04-architecture/Principles-In-Practice.md)
3. [Autoloads](04-architecture/Autoloads.md)
4. [Signals Catalog](04-architecture/Signals-Catalog.md)
5. [Resource Patterns](04-architecture/Resource-Patterns.md)
6. [Scene Composition](04-architecture/Scene-Composition.md)
7. [ADR Index](04-architecture/ADR-Index.md)

### 🤖 Agents
1. [Squad & Agents](05-contributing/Squad-And-Agents.md) — who does what in the engineering pipeline
2. [Workflow](05-contributing/Workflow.md) — the TDD loop you must follow
3. [Writing Specs](05-contributing/Writing-Specs.md) — sypha's template
4. [Writing Tests](05-contributing/Writing-Tests.md) — trevor's patterns
5. [Coding Standards](05-contributing/Coding-Standards.md) — shanoa's style
6. [Architecture Guide](04-architecture/Architecture-Guide.md) — grant's compass

---

## By system

| System | Page | Source |
|---|---|---|
| Player character | [Player](03-systems/Player.md) | `scripts/player.gd` |
| Enemies | [Enemies](03-systems/Enemies.md) | `scripts/enemies/` |
| Combat | [Combat](03-systems/Combat.md) | `player.gd`, `enemy_base.gd` |
| Items & loot | [Items & Loot](03-systems/Items-And-Loot.md) | `scripts/items/`, `world/item_pickup.gd` |
| Inventory & equipment | [Inventory & Equipment](03-systems/Inventory-And-Equipment.md) | `items/inventory.gd`, `items/equipment_manager.gd` |
| Skills & hotbar | [Skills & Hotbar](03-systems/Skills-And-Hotbar.md) | `items/skill_resource.gd`, `ui/skill_hotbar.gd` |
| Progression | [Progression](03-systems/Progression.md) | `items/player_stats.gd`, `run_stats.gd` |
| Biomes & waves | [Biomes & Waves](03-systems/Biomes-And-Waves.md) | `world/biome_manager.gd`, `main.gd` |
| World objects | [World Objects](03-systems/World-Objects.md) | `world/` |
| UI & HUD | [UI & HUD](03-systems/UI-And-HUD.md) | `ui/` |
| Menus & flow | [Menus & Flow](03-systems/Menus-And-Flow.md) | `ui/main_menu.gd`, `ui/character_select.gd` |
| Multiplayer & input | [Multiplayer & Input](03-systems/Multiplayer-And-Input.md) | `party_config.gd` |
| Audio | [Audio](03-systems/Audio.md) | `audio/` |
| VFX & feedback | [VFX & Feedback](03-systems/VFX-And-Feedback.md) | `vfx/` |
| Settings & persistence | [Settings & Persistence](03-systems/Settings-And-Persistence.md) | `settings.gd` |

---

## Per-page template

Every system page follows this shape so readers always know what to expect:

```
# <System Name>

## Purpose            — one paragraph, what & why
## Key files          — bullet list with one-line summary each
## Data flow          — short prose or ASCII diagram
## Public API         — methods, signals, exported props
## Tests              — which test files cover this
## Extending          — "to add a new X, do Y"
## Known gaps         — open issues, TODOs, not-yet-implemented
```

If a system page deviates from this template, that's a smell — call it out
in review.

---

## Status & meta

- **Engine:** Godot 4.6 stable
- **Language:** GDScript
- **Tests:** [GUT](https://github.com/bitwes/Gut) (unit) + custom autobot
  (E2E) — 190 unit + 10 E2E currently green
- **Autoloads:** 4 (DemonManager, HitFeedback, TransitionManager, PartyConfig)
- **Scripts:** 58 across 7 subsystems
- **Specs:** 40+ in `docs/specs/` — see [Spec Index](06-reference/Spec-Index.md)

The wiki itself lives in `docs/wiki/` and is the source of truth. If GitHub
Wiki is enabled, it mirrors this directory.
