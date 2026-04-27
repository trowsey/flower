---
scope: "all-squads"
authority: "ops"
---

# Shared Squad Goals — template

Each squad's `memory/<squad>/goals.md` should contain only its
**actual** goals — no placeholder scaffolding. If a squad has no
goals yet, the file should be near-empty with a pointer here.

## Goal entry format

```
1. **<Goal name>** — metric: <what_to_measure> | baseline: <n> | target: <n> | deadline: YYYY-MM-DD | status: <not-started|in-progress|done>
```

## Confidence

Every new goal entry should declare a confidence band per
`.agents/config/CONFIDENCE.md`. A goal with confidence below
`medium` should not yet be set — sharpen the spec first.
