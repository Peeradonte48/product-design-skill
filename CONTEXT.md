# Product Design Skill Suite

A scaffold of portable, stack-agnostic Claude Code skills forming a FigJam → narrative →
prototype pipeline plus standalone Figma read/build/verify paths. This glossary pins the terms
whose meaning is load-bearing across skills, so roles don't blur as the suite evolves.

## Language

**Report**:
A formal, shareable design-parity artifact — a styled PDF and/or a machine-readable findings
document — produced **exclusively** by `verify-design-match`. No other suite skill emits a Report,
even when it holds the data to.
_Avoid_: audit output, parity doc, verification report (when you mean the inline check below)

**Inline verification summary**:
The per-property ✓/Δ check a build skill (e.g. `implement-figma-design`) states **in its own
response** while iterating a build to match a design. It is never a shareable Report; for that the
user runs `verify-design-match`.
_Avoid_: report, verification report

**Design spec**:
The structured transcription of a Figma node — per-element geometry, color, typography, asset
flags, resolved tokens, and a gaps list — that `implement-figma-design` extracts up front and
builds from. Build guidance, not the verification oracle (the Figma screenshot is).
_Avoid_: extract, design doc, spec (bare)

**Product brief**:
A **stakeholder buy-in / sign-off** document — problem, demand evidence, goals & metrics, scope —
written in the stakeholder's language to make the case for a feature. Produced **exclusively** by
`spec-to-brief`. Its audience is a decision-maker, not a builder.
_Avoid_: PRD (bare), dev doc

**Developer-facing PRD**:
The `PRD.md` produced by `figma-to-dev-docs` — lean **build context** for an AI developer (problem,
target user, scope in/out, success signal, screen inventory), telling the builder *why/who/what
scope* so they build the right thing. It is **not** a buy-in pitch (that is the Product brief
above); the two differ by audience and purpose, not just format.
_Avoid_: product brief, buy-in doc

**Product spec**:
The markdown `figjam-sitemap-to-spec` writes from a **FigJam sitemap** — a sitemap tree plus a
per-page spec for each node. Its source is a site-structure diagram, and it describes *what pages
exist and what each holds*.
_Avoid_: spec (bare), spec-driven spec

**Spec-driven spec**:
The `spec.md` `figma-to-dev-docs` writes from a **finished Figma frame/section** — three sections:
EARS requirements (with IDs), a design section, and an ordered task list. Its source is a visual
design, and it describes *what an AI developer must build and in what order*. Distinct from the
Product spec above by source (frame vs sitemap) and shape (requirements/design/tasks vs page specs).
_Avoid_: spec (bare), product spec
