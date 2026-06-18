# `implement-figma-design` emits no report — report output is `verify-design-match`'s alone

**Status:** accepted

`implement-figma-design` extracts a Figma node into a persisted **design spec** and verifies its
build with a screenshot diff. It therefore *holds* everything needed to emit a formal parity
**report** — yet it deliberately does **not**. Report output (styled PDF + machine-readable
findings) is the **exclusive** responsibility of `verify-design-match`. `implement-figma-design`
instead states an **inline verification summary** (per-property ✓/Δ in its response) and points the
user to `verify-design-match` when a shareable report is wanted.

## Why this is worth recording

The suite's identity is **non-overlapping skill roles** (see the routing/"When NOT to use"
sections across skills). A future maintainer will look at `implement-figma-design` sitting on a
design spec *and* a pixel diff and reasonably think "why doesn't it just print the report like its
siblings?" — and try to add one. That re-opens the exact overlap this boundary closes: two skills
emitting parity reports, with the model unsure which to invoke. This ADR records that the absence
is deliberate, not an oversight.

## Considered options

- **Builder emits no report; report is `verify-design-match`'s alone (chosen)** — keeps the build
  skill focused on *building + converging to a match*, and keeps exactly one source of parity
  reports. The builder hands off to the auditor for the shareable artifact.
- **Builder emits its own report too (rejected)** — convenient (one-stop build-and-report) but
  duplicates `verify-design-match`'s output, drifts from it over time, and blurs which skill to
  run. The suite avoids duplicated, perpetually-drifting copies on principle.

## Consequences

- `implement-figma-design` writes **no report file and no PDF**, and carries **no report
  template**. Its verification is the inline summary plus the screenshot diff.
- The **Figma screenshot stays the verification oracle**; the design spec is build guidance only,
  so an extraction error surfaces as a spec↔screenshot disagreement rather than being laundered.
- `implement-figma-design`'s `SKILL.md` points to `verify-design-match` for a formal report, and
  `verify-design-match` remains the only skill that produces one.
