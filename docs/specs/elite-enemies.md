# Feature: Elite / Champion Enemies

## Overview
Rare, stronger versions of normal enemies that spawn with random affixes — modifier properties that change their behavior and appearance. Elites drop better loot and create memorable combat encounters.

## Requirements

### REQ-1: Elite spawn chance
**Given** the spawn system creates a demon
**When** the demon is instantiated
**Then** there is a 10% chance it becomes an Elite (configurable via SpawnManager.elite_chance)

### REQ-2: Elite visual indicator
**Given** an enemy is promoted to Elite
**Then** the enemy has a glowing colored aura (OmniLight3D, color based on primary affix), its name is prefixed with the affix names (e.g., "Fire Enchanted Fast Pure Drainer"), and its sprite has a subtle pulsing modulate effect

### REQ-3: Elite stat scaling
**Given** an enemy becomes Elite
**Then** its stats are scaled: max_health × 2.5, attack_damage × 1.5, and it grants 3× XP on death

### REQ-4: Affix system — 1-2 random affixes
**Given** an Elite spawns
**Then** it receives 1-2 random affixes from the affix pool (no duplicates)

### REQ-5: Affix — Fire Enchanted
**Given** an Elite has the Fire Enchanted affix
**Then** on death, it explodes dealing 20 damage in a 3.0 unit radius to the player. During life, it has an orange glow aura.

### REQ-6: Affix — Extra Fast
**Given** an Elite has the Extra Fast affix
**Then** its move_speed is multiplied by 1.6. It has a blue-white glow aura.

### REQ-7: Affix — Teleporter
**Given** an Elite has the Teleporter affix
**When** the player is more than 8 units away and the teleport cooldown (4.0s) is ready
**Then** the Elite teleports to a random position within 3.0 units of the player. It has a purple glow aura and plays a brief fade-out / fade-in effect.

### REQ-8: Affix — Vampiric
**Given** an Elite has the Vampiric affix
**When** the Elite deals damage to the player (melee or drain)
**Then** it heals for 30% of the damage dealt. It has a red glow aura.

### REQ-9: Affix — Shielded
**Given** an Elite has the Shielded affix
**Then** it has a damage shield equal to 50% of its max_health. The shield absorbs damage before health. While the shield is active, a translucent barrier sprite overlays the enemy. When the shield breaks, there is a shatter visual effect.

### REQ-10: Elite loot bonus
**Given** an Elite enemy dies
**When** loot is generated
**Then** the loot table is upgraded: guaranteed item drop, rarity roll boosted by +1 tier (e.g., common becomes uncommon minimum)

## Edge Cases
- Fire Enchanted death explosion during soul drain — should still deal damage to player
- Teleporter teleporting into a wall — validate destination is on the NavigationMesh
- Vampiric healing past max_health — clamp to max_health
- Shielded + Vampiric combo — vampiric healing applies to health, not shield
- Elite with can_latch attempting soul drain — affixes still apply during drain

## Out of Scope
- Champion packs (groups of elites that share an affix) — future enhancement
- Boss-specific affixes
- Player affixes or enchantments
- Affix immunity (all affixes can stack with any enemy type)
