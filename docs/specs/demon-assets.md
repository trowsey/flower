# Demon Art Requirements & Asset Sourcing Spec

## Overview

All demon visuals use `AnimatedSprite3D` (2D sprites in 3D world), matching the existing player character style. This spec defines required sprite sheets, animation lists, art guidelines, and sourcing strategy for free/CC0 assets.

## Requirements

1. All demon sprites must work with `AnimatedSprite3D` using `SpriteFrames` resources
2. Sprite style must match existing player sprites (pixel art, ~64×64 or 128×128 per frame, nearest-neighbor filtering)
3. Each demon type needs a complete animation set (listed below)
4. Sprites face right by default — `flip_h` handles left-facing (matching player convention)
5. All assets must be **CC0** (public domain) or **CC-BY** (attribution required, must credit in-game or README)
6. No CC-BY-NC or CC-BY-SA unless explicitly approved by Tim
7. Soul wisp needs its own sprite/particle assets (see also `soul-wisp-vfx.md`)

## Reference: Existing Player Sprite Setup

From `player.tscn`:
- `pixel_size = 0.015`
- `texture_filter = 0` (nearest neighbor)
- `billboard = 1` (Y-axis billboard — always faces camera)
- Walk animation: 4 frames at 8 FPS
- Attack animation: 5 frames at 12 FPS
- Idle animation: 1 frame

Demon sprites should use the same `pixel_size`, `texture_filter`, and `billboard` settings for visual consistency.

## Animation Requirements Per Demon Type

### Pure Drainer

| Animation | Frames | FPS | Loop | Notes |
|-----------|--------|-----|------|-------|
| idle | 2–4 | 4 | yes | Subtle breathing/floating |
| walk | 4–6 | 8 | yes | Crawling/floating approach |
| latch | 3–4 | 10 | no | Grab/attach to player |
| drain | 2–4 | 4 | yes | Pulsing while draining soul |
| stagger | 2–3 | 8 | no | Knocked back from latch break |
| death | 4–6 | 10 | no | Dissolves/explodes |
| emerge | 4–6 | 8 | no | Claws emerging from ground, pulling body up |

### Fighter Drainer

| Animation | Frames | FPS | Loop | Notes |
|-----------|--------|-----|------|-------|
| idle | 2–4 | 4 | yes | Battle stance |
| walk | 4–6 | 8 | yes | Aggressive stride |
| attack | 4–5 | 12 | no | Melee swing/slash |
| latch | 3–4 | 10 | no | Grab/attach to player |
| drain | 2–4 | 4 | yes | Pulsing while draining |
| stagger | 2–3 | 8 | no | Hit reaction |
| death | 4–6 | 10 | no | Dissolves/explodes |
| emerge | 4–6 | 8 | no | Emerging from ground |

### Boss/Elite Demon

| Animation | Frames | FPS | Loop | Notes |
|-----------|--------|-----|------|-------|
| idle | 2–4 | 4 | yes | Imposing stance |
| walk | 4–6 | 6 | yes | Heavy, slower stride |
| attack | 5–6 | 10 | no | Powerful melee |
| slam | 6–8 | 10 | no | Ground slam AoE wind-up and impact |
| latch | 4–5 | 10 | no | Grab — more dramatic than regular demons |
| drain | 3–4 | 4 | yes | Intense draining |
| stagger | 2–3 | 6 | no | Barely flinches |
| death | 6–8 | 8 | no | Dramatic death — larger explosion |
| emerge | 6–8 | 6 | no | Bigger, slower emerge |
| enrage | 3–4 | 10 | no | One-shot transition to enraged state |

### Soul Wisp

| Animation | Frames | FPS | Loop | Notes |
|-----------|--------|-----|------|-------|
| idle | 2–4 | 6 | yes | Gentle float inside player |
| drain_travel | 4–6 | 10 | no | Moving from player to demon |
| captured | 2–3 | 4 | yes | Trapped in/near demon |
| return | 4–6 | 10 | no | Flying back to player |
| absorbed | 3–4 | 8 | no | Fully absorbed by demon (death) |

## Sprite Sheet Specifications

| Property | Value |
|----------|-------|
| Frame size | 64×64 px (regular demons) or 128×128 px (boss) |
| Format | PNG with transparency |
| Color depth | 32-bit RGBA |
| Arrangement | Horizontal strip (one row per animation) OR individual frame files |
| Naming convention | `{demon_type}_{animation}_{frame}.png` |

**Example file names:**
```
assets/enemies/pure_drainer/pure_drainer_idle_0.png
assets/enemies/pure_drainer/pure_drainer_idle_1.png
assets/enemies/pure_drainer/pure_drainer_walk_0.png
...
assets/enemies/boss/boss_slam_0.png
assets/enemies/boss/boss_slam_1.png
...
assets/effects/soul_wisp_idle_0.png
```

## Art Style Guidelines

### Match Existing Style
- **Pixel art** at 64×64 (match Sarah's proportions)
- Nearest-neighbor scaling (no smoothing/anti-aliasing)
- Dark, demonic color palette: deep reds, purples, blacks, with glowing accents (orange/green eyes)
- Clear silhouette readable at the camera's orthographic zoom (size=12)

### Demon Visual Identity
- **Pure Drainer**: Wispy/ghostly — semi-transparent, floating, tendril-like appendages. Visually reads as "soul creature." Smaller than player.
- **Fighter Drainer**: Solid, muscular, armored or bony. Clearly physical and dangerous. Similar size to player.
- **Boss/Elite**: 1.5–2× player size. Imposing horns/wings/armor. Visually distinct from regular demons.

### Consistency Rules
- All sprites face RIGHT by default
- Feet/base should be at the bottom-center of the frame (anchor point)
- Attack hitbox frames should have clear visual "impact" moment
- Death animations should end with the sprite mostly transparent/gone (since the node is freed)

## Suggested Asset Sources

### itch.io (primary)
Search terms:
- `demon sprite pixel art`
- `monster sprite sheet 2d`
- `dungeon enemy sprites`
- `dark fantasy pixel art enemies`
- `ghost wisp sprite pixel`
- `soul spirit sprite sheet`

Recommended creators/packs:
- **0x72** — Dungeon Tileset II (has some demon-like enemies)
- **Szadi art** — various fantasy enemy packs
- **Sanctum Pixel** — dark themed sprite collections
- **Admurin** — character sprite collections

### OpenGameArt.org
Search terms:
- `demon sprite`
- `dungeon monster`
- `dark creature pixel`
- `ghost wisp particle`

### Licensing Checklist
For each asset pack used:
- [ ] License is CC0 or CC-BY (no NC/SA unless Tim approves)
- [ ] Attribution text saved to `assets/CREDITS.md`
- [ ] Original source URL recorded
- [ ] Sprite dimensions compatible (64×64 or resizable)
- [ ] Animation frame count meets minimum requirements
- [ ] Color palette doesn't clash with existing player sprites

## Asset Directory Structure

```
assets/
  enemies/
    pure_drainer/
      pure_drainer_idle_0.png
      pure_drainer_idle_1.png
      pure_drainer_walk_0.png
      ...
    fighter_drainer/
      fighter_drainer_idle_0.png
      ...
    boss/
      boss_idle_0.png
      ...
  effects/
    soul_wisp_idle_0.png
    soul_wisp_drain_travel_0.png
    ...
  CREDITS.md               # Attribution for all sourced assets
```

## Open Questions

1. **Frame size**: 64×64 for all, or 128×128 for boss only? Need to check Sarah's actual frame size for reference.
2. **Placeholder art**: Should Trevor use colored rectangles as placeholders during development, or do we source assets first? (Recommend: Trevor implements with placeholders, Sypha sources real art in parallel)
3. **Custom art**: If free assets don't match the vibe, is Tim open to commissioning pixel art? Budget?
4. **Sprite sheet vs individual files**: Godot's `SpriteFrames` supports both. Individual files (like player.tscn uses) are simpler for iteration. Recommend individual files.
5. **Emerge animation**: Can this be shared across demon types (same claws-from-ground), or does each need a unique emerge?

## Dependencies

- **Depends on**: art style established by existing player sprites in `assets/player/`
- **Depended on by**: `demon-behavior.md` (needs sprites for AnimatedSprite3D), `soul-wisp-vfx.md` (wisp sprites), all demon `.tscn` scene files
