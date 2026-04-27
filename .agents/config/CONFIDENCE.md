# Confidence Rubric

Every spec, PR, and proposal must declare a confidence level using the
1–10 scale below, followed by the named band in parentheses.

| Score | Band         | Meaning                                                |
|------:|--------------|--------------------------------------------------------|
| 1     | very low     | Speculative; likely wrong; needs human design.         |
| 2–3   | low          | Plausible direction, weak evidence; expect rewrite.    |
| 4     | medium-low   | Some validation; significant unknowns remain.          |
| 5     | medium       | Reasonable; tests pass but design choices are guesses. |
| 6–7   | medium-high  | Well-tested; minor unknowns; reviewer should sanity-check. |
| 8–9   | high         | Strong evidence; tests + lints green; deterministic findings. |
| 10    | very high    | Mechanical, deterministic, or trivially verifiable.    |

Format: `Confidence: **<band> (<score>/10)** — <one-sentence rationale>`

Eventually high/very-high PRs may auto-merge. Until then, all bands
require review. Regardless of band, every PR adds **@trowsey** as
reviewer.
