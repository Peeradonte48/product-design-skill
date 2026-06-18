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
