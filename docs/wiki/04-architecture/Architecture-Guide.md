# Architecture Guide

> **Source of truth:** [`docs/architecture.md`](../../architecture.md). This page is a stub; do not duplicate the constitution.

When in doubt about *why* the codebase is shaped the way it is, read the
full document. Open an [ADR](ADR-Index.md) before deviating.

## Quick orientation — the 5 rules that matter most

- **Boring code over clever code.** Plain loops, named locals, early returns. No metaprogramming. (`architecture.md` §2.1)
- **Rule of Three for abstractions.** Two copies is fine; extract on the third concrete use case, never sooner. (§2.2)
- **Data over machinery.** Items, skills, modifiers are `Resource`s and `Dictionary`s — not class hierarchies. (§2.3)
- **Signals at the seams, direct calls within a system.** Cross-system calls go through a signal or autoload hub. (§2.4) → see [Signals Catalog](Signals-Catalog.md).
- **Tests are the first contract.** TDD is non-negotiable; a failing test always wins over a refactor. (§2.5)

For day-to-day choices ("Resource or Node?", "Where do I put this code?"),
read [Principles In Practice](Principles-In-Practice.md) first.

## Related pages

- [Autoloads](Autoloads.md) · [Signals Catalog](Signals-Catalog.md) · [Resource Patterns](Resource-Patterns.md) · [Scene Composition](Scene-Composition.md) · [ADR Index](ADR-Index.md)
