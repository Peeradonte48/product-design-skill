# `figma-design-to-working-prototype` composes sibling suite skills

**Status:** accepted

`figma-design-to-working-prototype` (P1) fuses pixel-perfect Figma transcription with a
walkable, narrative-driven flow. Rather than reimplementing either half, it is a **thin
orchestrator** that sequences two existing suite skills — `use-case-narrative-to-prototype`
(builds the walkable skeleton) and `implement-figma-design` (re-skins each screen
pixel-perfect) — and adds only the fusion and verification glue. We chose to make this a
**hard dependency on those two sibling skills** rather than carrying a standalone copy of
their workflows.

## Why this is worth recording

The suite's standing convention is that each skill is self-contained and depends only on
Figma **MCP tools**, never on another **skill**. ADR 0001 records the first deliberate break
of that rule: `page-to-figma` depending on the **external** official Figma plugin. P1 is a
**second, different-flavor** break — it depends on **same-suite siblings**. A future
maintainer reading the "self-contained, MCP-only" convention will reasonably wonder why P1
also breaks it and may try to "fix" it back toward self-containment by inlining the two
sub-skills' logic. This ADR records that the coupling is deliberate.

## Considered options

- **Thin orchestrator, hard dependency on siblings (chosen)** — P1 runs each sub-skill in its
  natural mode (behavior-first: skeleton, then re-skin) and owns only the glue the sub-skills
  can't: the frame↔step mapping, the in-place re-skin contract, and the two-phase
  verification gate. Keeps the two sub-skills single-source-of-truth; P1 stays short.
- **Standalone re-implementation** — P1 carries its own full fused workflow, duplicating the
  Figma-extract and UCN-parse steps. Rejected: it creates two more perpetually-drifting copies
  of logic the suite already owns, the exact duplication trap the suite avoids.

## Consequences

- P1's `SKILL.md` must name `use-case-narrative-to-prototype` and `implement-figma-design` as
  prerequisites, and stop (rather than half-run) if either is absent.
- The "build order is behavior-first" decision is load-bearing: it is what lets each sub-skill
  run in its natural mode, which is what keeps the orchestrator genuinely thin. Reversing to
  pixels-first would force P1 to own a fusion step the sub-skills don't provide — re-opening
  the standalone-vs-orchestrator trade-off.
- When delegating the re-skin, P1 must explicitly state the "presentation-only, wiring
  untouchable" contract to `implement-figma-design`; the post-skin behavioral walk is the
  backstop that catches a violation.
