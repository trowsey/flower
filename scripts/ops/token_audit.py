#!/usr/bin/env python3
"""Token-auditor: measure cost of every doc that ends up in agent context.

Counts tokens (cl100k_base) for every file in:
  - .agents/   (squad/agent/memory/skills)
  - docs/      (architecture, principles, specs, wiki)
  - AGENTS.md, CLAUDE.md, README.md (repo-root context)

Outputs a sorted markdown report with bloat hotspots and a dedup hint
(identical-paragraph clusters across files).

Usage:
  python3 scripts/ops/token_audit.py [--out PATH]
"""
from __future__ import annotations

import argparse
import hashlib
import os
import re
import sys
from collections import defaultdict
from pathlib import Path

import tiktoken

ROOTS = [".agents", "docs", "AGENTS.md", "CLAUDE.md", "README.md"]
ENC = tiktoken.get_encoding("cl100k_base")


def discover(repo_root: Path) -> list[Path]:
    files: list[Path] = []
    for root in ROOTS:
        p = repo_root / root
        if p.is_file() and p.suffix == ".md":
            files.append(p)
        elif p.is_dir():
            for f in sorted(p.rglob("*.md")):
                # Skip generated audit reports
                if "/memory/ops/" in str(f) and "/reports/" in str(f):
                    continue
                files.append(f)
    return files


def count_tokens(text: str) -> int:
    return len(ENC.encode(text))


def paragraphs(text: str) -> list[str]:
    # Split on blank lines; strip; ignore short fragments (<40 chars)
    parts = re.split(r"\n\s*\n", text)
    return [p.strip() for p in parts if len(p.strip()) >= 40]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=".agents/memory/ops/token-auditor/reports/latest.md")
    ap.add_argument("--top", type=int, default=20)
    args = ap.parse_args()

    repo_root = Path(__file__).resolve().parents[2]
    os.chdir(repo_root)
    files = discover(repo_root)
    if not files:
        print("no files found", file=sys.stderr)
        return 1

    rows: list[tuple[str, int, int]] = []  # (path, tokens, lines)
    para_index: dict[str, list[str]] = defaultdict(list)  # hash -> [paths]
    para_text: dict[str, str] = {}

    total_tokens = 0
    for f in files:
        try:
            text = f.read_text(encoding="utf-8")
        except Exception:
            continue
        tk = count_tokens(text)
        ln = text.count("\n") + 1
        rel = str(f.relative_to(repo_root))
        rows.append((rel, tk, ln))
        total_tokens += tk
        for p in paragraphs(text):
            h = hashlib.sha1(p.encode("utf-8")).hexdigest()
            para_index[h].append(rel)
            para_text[h] = p

    rows.sort(key=lambda r: -r[1])

    # Bucket by area
    bucket = defaultdict(int)
    for path, tk, _ in rows:
        if path.startswith(".agents/squads/"):
            bucket["squads"] += tk
        elif path.startswith(".agents/memory/"):
            bucket["memory"] += tk
        elif path.startswith(".agents/skills/"):
            bucket["skills"] += tk
        elif path.startswith(".agents/config/"):
            bucket["config"] += tk
        elif path.startswith("docs/"):
            bucket["docs"] += tk
        else:
            bucket["root"] += tk

    # Dedup candidates: paragraphs hashed to ≥3 different files
    dups: list[tuple[int, list[str], str]] = []
    for h, paths in para_index.items():
        unique = sorted(set(paths))
        if len(unique) >= 3:
            tk = count_tokens(para_text[h])
            dups.append((tk * (len(unique) - 1), unique, para_text[h][:120].replace("\n", " ")))
    dups.sort(reverse=True)

    out_path = repo_root / args.out
    out_path.parent.mkdir(parents=True, exist_ok=True)

    lines: list[str] = []
    lines.append("# Token Audit Report")
    lines.append("")
    lines.append(f"Total files scanned: **{len(rows)}**  ")
    lines.append(f"Total tokens: **{total_tokens:,}** (cl100k_base)")
    lines.append("")
    lines.append("## By area")
    lines.append("")
    lines.append("| Area | Tokens | % |")
    lines.append("|------|--------|---|")
    for area, tk in sorted(bucket.items(), key=lambda x: -x[1]):
        lines.append(f"| {area} | {tk:,} | {tk * 100 // max(total_tokens, 1)}% |")
    lines.append("")
    lines.append(f"## Top {args.top} files by token cost")
    lines.append("")
    lines.append("| File | Tokens | Lines | tokens/line |")
    lines.append("|------|-------:|------:|------------:|")
    for path, tk, ln in rows[: args.top]:
        lines.append(f"| `{path}` | {tk:,} | {ln} | {tk // max(ln, 1)} |")
    lines.append("")
    if dups:
        lines.append("## Duplicated paragraphs (≥3 files) — dedup candidates")
        lines.append("")
        lines.append("Sorted by token-savings-if-deduped (tokens × (file_count − 1)):")
        lines.append("")
        lines.append("| Savings | Files | Preview |")
        lines.append("|--------:|-------|---------|")
        for savings, paths, preview in dups[:10]:
            file_list = "<br>".join(f"`{p}`" for p in paths)
            preview_clean = preview.replace("|", "\\|")
            lines.append(f"| {savings} | {file_list} | {preview_clean}… |")
        lines.append("")
    lines.append("## Splitting hints")
    lines.append("")
    lines.append("Files >2,000 tokens are candidates for splitting into a SKILL")
    lines.append("(loaded on-demand) with a one-line breadcrumb in the always-loaded")
    lines.append("location.")
    lines.append("")
    big = [r for r in rows if r[1] > 2000]
    if big:
        for path, tk, _ in big:
            lines.append(f"- `{path}` — {tk:,} tokens")
    else:
        lines.append("- (none currently exceed 2,000 tokens)")
    lines.append("")
    lines.append("---")
    lines.append("")
    lines.append("Generated by `scripts/ops/token_audit.py`. ")
    lines.append("Confidence: **high (8/10)** — pure token counting + heuristic dedup; no judgment calls.")

    out_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"wrote {out_path}")
    print(f"total tokens: {total_tokens:,}  files: {len(rows)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
