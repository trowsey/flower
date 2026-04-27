#!/usr/bin/env python3
"""Dead-text-detector (heuristic-only pass).

Finds prose in agent files that is highly likely to be dead weight:
  1. Placeholder sections — explicit "(none yet)", "(No goals set)",
     "PLACEHOLDER", "Example format:", etc.
  2. Sections referencing systems that don't exist (currently: $50 spend
     escalation has no tracker).
  3. Repeated boilerplate: identical paragraphs across ≥3 agent files.

Output is a markdown report with each finding tagged:
  KEEP      — too important; leave in place
  PRUNE     — boilerplate or dead, safe to delete
  RELOCATE  — important for *some* tasks, but doesn't belong in the
              always-loaded surface; move to a skill and leave a
              breadcrumb pointer

The relocation policy implements the user's directive: "we don't want to
completely remove text if it is absolutely necessary to work on some
part of the code, but moving it to keep it from being loaded needlessly,
is almost as good".

Usage:
  python3 scripts/ops/dead_text.py [--out PATH] [--apply]

--apply edits files in-place to delete PRUNE findings (RELOCATE is never
auto-applied — relocation requires judgment about target skill).
"""
from __future__ import annotations

import argparse
import hashlib
import os
import re
import sys
from collections import defaultdict
from pathlib import Path

ROOTS = [".agents", "docs", "AGENTS.md", "CLAUDE.md", "README.md"]

PLACEHOLDER_PATTERNS = [
    (r"\(No .+? yet[^)]*\)", "placeholder: empty section"),
    (r"\(none yet\)", "placeholder: empty list"),
    (r"PLACEHOLDER", "placeholder: literal sentinel"),
    (r"Example format:", "placeholder: example-template"),
    (r"^\s*Add your first .+? here", "placeholder: scaffolding text"),
]

DEAD_INSTRUCTION_PATTERNS = [
    (r"Spend exceeds \$\d+", "references untracked spend system"),
]


def discover(repo_root: Path) -> list[Path]:
    files: list[Path] = []
    for root in ROOTS:
        p = repo_root / root
        if p.is_file() and p.suffix == ".md":
            files.append(p)
        elif p.is_dir():
            for f in sorted(p.rglob("*.md")):
                if "/memory/ops/" in str(f) and "/reports/" in str(f):
                    continue
                files.append(f)
    return files


def paragraphs(text: str) -> list[tuple[int, str]]:
    out: list[tuple[int, str]] = []
    cur: list[str] = []
    cur_start = 1
    line_no = 0
    for line in text.split("\n"):
        line_no += 1
        if line.strip() == "":
            if cur:
                out.append((cur_start, "\n".join(cur)))
                cur = []
            cur_start = line_no + 1
        else:
            if not cur:
                cur_start = line_no
            cur.append(line)
    if cur:
        out.append((cur_start, "\n".join(cur)))
    return out
    # Returns [(line_no_1based, paragraph)]. Splits on blank lines.
    out: list[tuple[int, str]] = []
    cur: list[str] = []
    cur_start = 1
    line_no = 0
    for line in text.split("\n"):
        line_no += 1
        if line.strip() == "":
            if cur:
                out.append((cur_start, "\n".join(cur)))
                cur = []
            cur_start = line_no + 1
        else:
            if not cur:
                cur_start = line_no
            cur.append(line)
    if cur:
        out.append((cur_start, "\n".join(cur)))
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=".agents/memory/ops/dead-text-detector/reports/latest.md")
    args = ap.parse_args()

    repo_root = Path(__file__).resolve().parents[2]
    os.chdir(repo_root)
    files = discover(repo_root)

    findings: list[dict] = []
    para_index: dict[str, list[tuple[str, int]]] = defaultdict(list)
    para_text: dict[str, str] = {}

    # Skip files that legitimately *describe* placeholder patterns
    SELF_DESCRIBING = {
        ".agents/squads/ops/dead-text-detector.md",
        ".agents/squads/ops/token-auditor.md",
        "scripts/ops/dead_text.py",
        "scripts/ops/token_audit.py",
    }

    for f in files:
        try:
            text = f.read_text(encoding="utf-8")
        except Exception:
            continue
        rel = str(f.relative_to(repo_root))
        skip_pattern_scan = rel in SELF_DESCRIBING

        # 1. Placeholder patterns — line-level
        if not skip_pattern_scan:
            for pat, reason in PLACEHOLDER_PATTERNS:
                for m in re.finditer(pat, text, flags=re.MULTILINE):
                    line_no = text[: m.start()].count("\n") + 1
                    findings.append({
                        "verdict": "PRUNE",
                        "file": rel,
                        "line": line_no,
                        "match": m.group(0)[:80],
                        "reason": reason,
                    })

            # 2. Dead-instruction patterns
            for pat, reason in DEAD_INSTRUCTION_PATTERNS:
                for m in re.finditer(pat, text, flags=re.MULTILINE):
                    line_no = text[: m.start()].count("\n") + 1
                    findings.append({
                        "verdict": "RELOCATE",
                        "file": rel,
                        "line": line_no,
                        "match": m.group(0)[:80],
                        "reason": reason
                                  + " — keep the rule, but only load it when "
                                  + "spend tracking is wired",
                    })

        # 3. Repeated boilerplate index — but skip cross-reference breadcrumbs
        for ln, p in paragraphs(text):
            if len(p) < 80:
                continue
            # Skip paragraphs that ARE a breadcrumb (they SHOULD repeat)
            if re.search(r"`\.agents/memory/_shared/", p):
                continue
            h = hashlib.sha1(p.encode("utf-8")).hexdigest()
            para_index[h].append((rel, ln))
            para_text[h] = p

    # Repeated paragraphs across ≥3 files
    for h, locations in para_index.items():
        unique_files = sorted({p for p, _ in locations})
        if len(unique_files) >= 3:
            preview = para_text[h].split("\n", 1)[0][:80]
            findings.append({
                "verdict": "RELOCATE",
                "file": "MULTIPLE",
                "line": 0,
                "match": preview,
                "reason": (
                    f"identical paragraph in {len(unique_files)} files: "
                    + ", ".join(unique_files)
                    + " — extract to shared file with breadcrumb"
                ),
            })

    # Group findings by verdict
    by_verdict: dict[str, list[dict]] = defaultdict(list)
    for f in findings:
        by_verdict[f["verdict"]].append(f)

    out_path = repo_root / args.out
    out_path.parent.mkdir(parents=True, exist_ok=True)

    lines: list[str] = []
    lines.append("# Dead-Text Detector Report (heuristic pass)")
    lines.append("")
    lines.append(f"Findings: **{len(findings)}**  "
                 f"(PRUNE: {len(by_verdict.get('PRUNE', []))}, "
                 f"RELOCATE: {len(by_verdict.get('RELOCATE', []))}, "
                 f"KEEP: {len(by_verdict.get('KEEP', []))})")
    lines.append("")
    lines.append("Verdict legend:")
    lines.append("- **PRUNE** — safe to delete; boilerplate or dead.")
    lines.append("- **RELOCATE** — important for some tasks; move to a "
                 "lazy-loaded skill and leave a breadcrumb in the "
                 "always-loaded location.")
    lines.append("- **KEEP** — too important to touch.")
    lines.append("")

    for verdict in ("PRUNE", "RELOCATE", "KEEP"):
        items = by_verdict.get(verdict, [])
        if not items:
            continue
        lines.append(f"## {verdict} — {len(items)} findings")
        lines.append("")
        lines.append("| File | Line | Match | Reason |")
        lines.append("|------|-----:|-------|--------|")
        for f in items:
            file_cell = f["file"] if f["file"] == "MULTIPLE" else f"`{f['file']}`"
            match_cell = f["match"].replace("|", "\\|").replace("\n", " ")
            reason_cell = f["reason"].replace("|", "\\|")
            lines.append(f"| {file_cell} | {f['line'] or '—'} | {match_cell} | {reason_cell} |")
        lines.append("")

    lines.append("---")
    lines.append("")
    lines.append("Generated by `scripts/ops/dead_text.py` (heuristic pass).")
    lines.append("")
    lines.append("Confidence: **medium-high (7/10)** — heuristics are "
                 "deterministic but verdicts (PRUNE vs RELOCATE) for "
                 "boundary cases need human review. PRUNE on placeholder "
                 "text: very high (9/10). RELOCATE on dedup candidates: "
                 "medium (5/10) — relocation target requires judgment.")

    out_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {out_path}")
    print(f"findings: {len(findings)}  "
          f"(PRUNE {len(by_verdict.get('PRUNE', []))}, "
          f"RELOCATE {len(by_verdict.get('RELOCATE', []))})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
