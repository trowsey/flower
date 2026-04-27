# Ops Squad

Meta-quality squad. Audits and improves the agent infrastructure
itself with the goal of **reducing token consumption** while
preserving (or improving) output quality.

## Mission

Make every agent run cheaper. Find dead text, duplicated prose,
unused instructions, oversized files, and recurring patterns that
should be promoted from memory to static context (or vice versa).

## Goals

1. Reduce total agent token surface (`.agents/**` + `docs/**` +
   root context files) measured by `scripts/ops/token_audit.py`.
2. Increase **effective tokens** — fraction of loaded context that
   actually gets referenced in output.
3. Shorten sessions by extracting repeated bootstrap into AGENTS.md
   or skills.

## Agents (operational names)

- **token-auditor** — deterministic count of every doc; flags bloat,
  dedup candidates, and split opportunities.
- **dead-text-detector** — finds prose unlikely to influence output.
  Default verdict is **RELOCATE** (move to skill + breadcrumb), not
  PRUNE — total deletion is reserved for placeholders and dead
  references.
- **gotcha-promoter** — scans repo memories for facts repeated across
  ≥3 sessions and promotes them to AGENTS.md / skills.
- **orchestrator-tuner** — narrowly critiques lead/orchestrator agent
  files for prose duplicated in SQUAD.md / SYSTEM.md.
- **session-summarizer** — condenses session transcripts while
  preserving commands run, key decisions, and thought processes.
  Improves over time at "what to keep vs. compress".

## Output format

Every PR or proposal from this squad ends with:

```
Confidence: **<band> (<n>/10)** — <rationale>
```

See `.agents/config/CONFIDENCE.md` for the band map. All PRs auto-add
@trowsey as reviewer regardless of confidence.

## Cadence

Every 3 days via `.github/workflows/ops-audit.yml` plus on-demand
via `workflow_dispatch`.
