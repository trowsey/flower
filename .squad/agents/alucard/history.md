# Alucard — History

## Core Context
- Project: flower — Godot 4.6 dungeon crawler (GDScript)
- User: Tim
- Key files: scripts/player.gd, scripts/camera.gd, scenes/main.tscn, scenes/player.tscn
- Player uses NavigationAgent3D for movement, AnimatedSprite3D for visuals
- Combat: left-click move, right-click attack with Area3D hitbox

## Learnings

### Enemy System Architecture (2025-07-14)
- Soul system: 15s drain timer (100→0 at ~6.67/sec), separate from health (100 HP). Player frozen during latch but can attack.
- One-at-a-time latch lock via DemonManager autoload singleton.
- 3 demon types first pass: Pure Drainer (soul only, low HP), Fighter Drainer (melee + soul, medium HP), Boss (enhanced fighter drainer, 200 HP, ground slam, enrage).
- Collision layers: 1=world, 2=player, 4=enemies. Player AttackArea masks layer 4. Demons mask layer 1 (ground) + detect layer 2 (player).
- demon_base.gd shared state machine: IDLE/PATROL/CHASE/LATCH_APPROACH/LATCHING/DRAINING/ATTACK/STAGGERED/DYING/DEAD/EMERGING.
- Spawning: pre-placed + dynamic via SpawnManager/SpawnPoint. Emerge animation ~1.7s invulnerability window (collision_layer=0 during emerge).
- Soul wisp: visual-only node (AnimatedSprite3D + OmniLight3D), managed by SoulWispManager listening to player signals.
- Specs written to docs/specs/: soul-system.md, demon-behavior.md, demon-spawning.md, demon-assets.md, soul-wisp-vfx.md.
- Player sprite: pixel_size=0.015, billboard=1, texture_filter=0 (nearest neighbor). Demons must match.
- Player.gd needs extension: PlayerState enum, soul/health vars, begin_soul_drain()/end_soul_drain()/take_damage()/recover_soul() methods, signals.
- Recommended split: Trevor handles gameplay (soul system, demon AI, spawning), Sypha handles visuals (assets, wisp VFX).
