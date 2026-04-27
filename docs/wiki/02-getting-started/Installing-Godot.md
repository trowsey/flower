# Installing Godot

Flower targets **Godot 4.6 stable, GDScript only**. No GDExtension, no native build step, no extra editor plugins to install — the only addon (GUT) is already vendored under `addons/gut/`.

## Get the engine

Download Godot 4.6 from the official site or via package manager:

- **Direct downloads:** https://godotengine.org/download/archive/4.6-stable/
- **Linux (apt-based, manual):** download the 64-bit Linux .zip, extract `Godot_v4.6-stable_linux.x86_64`, optionally symlink to `/usr/local/bin/godot`.
- **macOS:** `brew install --cask godot` (verify it pulls 4.6) or use the official .app from the archive page.
- **WSL2:** install the Linux binary inside WSL. Headless test runs work natively; the editor needs an X server / WSLg if you want to open the project visually.

Verify:

```bash
godot --version
# expected: 4.6.stable.<commit hash> (or 4.6 release variant)
```

> **Why this matters:** Tests, parse checks, and the autobot all invoke `godot` on the command line. If it isn't in `PATH`, every CI-style command in [`Running-Tests.md`](Running-Tests.md) will fail. Make `godot` resolve before doing anything else.

## Open the project

From the repo root:

```bash
# Launch the editor against this project directly (no project picker)
godot --editor --path .

# Or launch the project picker in the usual way
godot
# then click "Import" and pick /path/to/flower/project.godot
```

First import takes ~30 seconds while Godot compiles `.import/` and `.godot/` artifacts. These directories are gitignored — re-importing on a fresh clone is normal and idempotent.

## Required addons

The repo ships everything it needs:

- **GUT** (Godot Unit Test) lives at `addons/gut/`. It is enabled in `project.godot` (`enabled=PackedStringArray("res://addons/gut/plugin.cfg")`).
- A one-time patch for Godot 4.6 was applied: `Logger` was renamed to `GutLogger` in `addons/gut/utils.gd` to avoid a class-name collision (see ADR-004 in [`docs/architecture.md`](../../architecture.md)). Don't revert this if you upgrade GUT.

No other addons are required, expected, or supported by the test suite.

## Platform notes

- **Linux / macOS / WSL:** all first-class. Headless `godot --headless ...` commands work identically.
- **Windows native:** the editor runs fine. Adapt the test commands in [`Running-Tests.md`](Running-Tests.md) to use `godot.exe` and Windows path separators if needed; the underlying GUT/autobot scripts are platform-agnostic.

There is **no native compile step**, no `cargo build`, no `npm install`, no `make`. If you find yourself running one of those, you're in the wrong tree.

## Next

- [Running The Game](Running-The-Game.md) — keybindings, F5 to launch.
- [Running Tests](Running-Tests.md) — parse / unit / E2E commands.
- [Repo Layout](Repo-Layout.md) — directory tour.
