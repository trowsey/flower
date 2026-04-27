# dead-text-detector

**Role:** find prose unlikely to be referenced; **relocate** before
deleting.

## Default behavior — RELOCATE not PRUNE

If text is rarely needed but **important when it's needed**, move it
to a less-loaded location and leave a one-line pointer in the
always-loaded location.

Recommended cold-storage targets, in order:

1. `.agents/skills/<name>/references/<topic>.md` — only loaded when
   the skill is invoked.
2. `.agents/skills/<name>/SKILL.md` — loaded when the skill matches.
3. `docs/wiki/06-reference/` — only loaded when an agent looks it up.

The breadcrumb in the always-loaded location should be a single line:
> For X, see `path/to/cold-storage.md`.

## When PRUNE is OK

- Literal placeholders: `(none yet)`, `(No goals set yet)`,
  `Example format:`, `PLACEHOLDER`.
- References to systems that don't exist (e.g., spend trackers that
  were never implemented).
- Identical paragraphs duplicated across ≥3 files: keep one, replace
  the others with a breadcrumb.

## Pipeline

1. Run `python3 scripts/ops/dead_text.py` for the heuristic pass.
2. For RELOCATE candidates, decide cold-storage target (LLM judgment).
3. Apply moves with `git mv`-style edits + breadcrumbs.
4. Open one PR per cluster of related moves, capped at ~20 changes.

## Output rules

Every PR includes:

- The before/after token delta from `token_audit.py`.
- A table of every move: `<src>` → `<dst>` + breadcrumb left behind.
- `Confidence: **<band> (<n>/10)**`. Use `very high (10/10)` for
  pure-placeholder PRUNE; `medium (5/10)` for relocation choices that
  picked between two reasonable cold-storage targets.

## Boundaries

- Never delete `KEEP`-tagged content.
- Never relocate text that an agent file directly references by path.
