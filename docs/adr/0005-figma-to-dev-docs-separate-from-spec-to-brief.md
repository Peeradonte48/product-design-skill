# `figma-to-dev-docs` is a separate skill from `spec-to-brief`, and is command-only

**Status:** accepted

`figma-to-dev-docs` turns a finished Figma frame/section into a developer doc bundle (`PRD.md`,
`spec.md`, `test-cases.md`). Its `PRD.md` overlaps, on the surface, with `spec-to-brief`'s output —
both are "a PRD." This ADR records why it is nonetheless a **separate skill**, why its PRD is a
**developer-facing build-context** doc rather than a stakeholder buy-in brief, and why it is
**command-only**.

## Why this is worth recording

A future maintainer will see two skills producing "a PRD" and reasonably ask "why two? — fold
`figma-to-dev-docs`'s PRD into `spec-to-brief`." That is the same duplicated-output question ADR
0004 answers for the parity report. This ADR records that the two PRDs are **different artifacts**,
not drifting copies.

## Considered options

- **Separate skill; PRD = developer build context; command-only (chosen).** The input (a Figma
  frame), the output set (an SDD spec + Gherkin tests alongside the PRD), and the PRD's audience (an
  AI developer, not a sign-off stakeholder) are all distinct from `spec-to-brief`. Command-only
  invocation keeps it from colliding with `implement-figma-design`, which also fires on a figma.com
  link but to build code.
- **Extend `spec-to-brief` (rejected).** `spec-to-brief` is a pure synthesizer that never reads
  Figma and produces a buy-in brief; adding Figma reading, an SDD spec, and test cases would blur
  its single role and break its "composes after biz-review/harden-doc" framing.
- **Thin orchestrator delegating the PRD to `spec-to-brief` (rejected).** Would create a hard
  sibling dependency (against the suite convention that skills depend only on Figma MCP tools) for a
  PRD that is a *different artifact* anyway.

## Consequences

- Two skills produce a "PRD," distinguished by audience and purpose. The glossary (`CONTEXT.md`)
  pins **Product brief** (buy-in, `spec-to-brief`) vs **Developer-facing PRD** (build context,
  `figma-to-dev-docs`).
- `figma-to-dev-docs` is **command-only** (`disable-model-invocation: true`), like
  `critique-figma-design` and the doc-review commands — it never auto-fires on a figma link.
- It has **no hard dependency** on any sibling skill; it reads Figma (and, in a repo, the codebase)
  read-only and writes only its three markdown files. For a buy-in brief it *points* to
  `spec-to-brief`; for the build it *points* to `implement-figma-design`.
