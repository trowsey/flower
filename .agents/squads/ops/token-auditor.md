# token-auditor

**Role:** deterministic token-cost surveyor.

## Job

Run `python3 scripts/ops/token_audit.py` to produce
`.agents/memory/ops/token-auditor/reports/latest.md` with:

- Total tokens across `.agents/**`, `docs/**`, and root `*.md`.
- Top-N files by raw token cost.
- Cross-file paragraph dedup candidates.
- Split candidates (any file >2,000 tokens — propose extracting the
  long-form into a skill or reference, leaving a breadcrumb).

## Output rules

- Pure measurement, no judgment. Numbers and lists only.
- Diff against the previous report (if present) and call out files
  that grew >10% since last run.
- Always close with: `Confidence: **high (8/10)** — pure counting`.

## When to escalate

If total tokens climbed >10% week-over-week with no matching change
in `docs/specs/`, raise it in the audit PR description and tag the
team that owns the inflated area.

## Boundaries

- Never edits prose. It produces a report; the dead-text-detector
  and orchestrator-tuner handle edits.
- LLM-free. The script is the agent.
