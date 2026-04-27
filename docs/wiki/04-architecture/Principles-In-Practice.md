# Principles In Practice

> **Source of truth:** [`docs/principles.md`](../../principles.md). This page is a stub.

> **The five rules that catch 90% of bad code**
>
> 1. If you can't test it without a SceneTree, the logic is in the wrong file.
> 2. Two copies is fine. Three triggers an extraction.
> 3. One signal per cross-system concern.
> 4. No new autoload without an ADR. (We have four — see [Autoloads](Autoloads.md).)
> 5. Tests fail first, pass after.

Read the full doc for the day-to-day decision tables ("Where do I put this
code?", "Resource or Node?", "How big is too big?") and the canonical
patterns (static-module, procedural-UI, signal-into-autoload).

## When in doubt

- Architectural questions → [Architecture Guide](Architecture-Guide.md) (`docs/architecture.md`).
- Style and naming → [Coding Standards](../05-contributing/Coding-Standards.md).
- "Where does this signal go?" → [Signals Catalog](Signals-Catalog.md).
- "Should this be a new autoload?" → No, unless you write an ADR. See [ADR Index](ADR-Index.md).
