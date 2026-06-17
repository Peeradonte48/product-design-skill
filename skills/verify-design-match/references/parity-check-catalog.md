# Parity check catalog — verify-design-match

Single-owner reference (only `verify-design-match` uses it). Defines the five comparison
categories, how each property is read from both sides, default tolerances, the element-matching
algorithm, severity defaults, and the report template. Every finding cites its source; nothing
here licenses an aesthetic-taste judgment — this is an objective conformance audit.

## Categories & properties

Each comparison runs five categories. For each property: read the **live** value from the DOM
(`getComputedStyle` / bounding box via the browser tool) and the **Figma** value from the node
(`get_metadata` geometry/props + `get_variable_defs` for token-resolved values), then diff.

| Category | Properties compared | Live source | Figma source |
|---|---|---|---|
| Color | text color, background, border/stroke color, fill | `getComputedStyle` color / background-color / border-color | node fills / strokes, resolved to hex (via variables) |
| Typography | font-family, font-size, font-weight, line-height, letter-spacing, text-align | `getComputedStyle` font-* | text node style props |
| Spacing | padding, gap between paired siblings, margin | `getComputedStyle` padding/margin + measured inter-element gaps | auto-layout padding / itemSpacing, else measured from geometry |
| Layout / position | x/y offset within the frame, alignment, sibling order | element bounding box relative to frame origin | `absoluteBoundingBox` relative to frame |
| Sizing | width, height | element bounding box w/h | node w/h |

## Tolerances

Conform to the **target project's documented rules first** (token system, any documented
allowed deviation); else use these defaults. **State which tolerance/source each finding used.**

- **Sub-pixel:** differences ≤1px are ignored (anti-aliasing / rounding).
- **Color:** compare by hex; treat ΔE ≤ 2 (near-identical rendered color) as a match.
- **Typography:** font-family, font-size, font-weight compared **exact**; line-height /
  letter-spacing use the ≤1px / ≤0.5px sub-pixel rule.
- **Spacing / layout / sizing:** px against the paired node, ≤1px ignored.
- Note fluid/`%`/`auto` live values explicitly rather than forcing a px comparison.

## Matching algorithm (geometry-first, text-anchored)

Goal: pair each live element with its Figma node without guessing.

1. **Normalize.** Render the live page at the frame's exact width so both share one coordinate
   space (scale factor 1). All boxes are expressed relative to the frame origin.
2. **Candidate pairs by geometry.** For each significant Figma node (leaf or labeled
   container), find live elements whose bounding box overlaps it; score overlap by IoU
   (intersection-over-union).
3. **Disambiguate by text.** If the node carries text, prefer the candidate whose visible text
   matches (exact, then closest). Text match breaks geometry ties.
4. **Confidence.** `confidence = f(IoU, text match, type compatibility)`. Pair only when
   confidence ≥ the bar (default **0.6**). Below the bar → **couldn't-align** (emit NO property
   findings for it).
5. **Leftovers.** A Figma node with no live counterpart, or a live element with no Figma
   counterpart, goes to **couldn't-align**, tagged which side is missing (a missing/extra
   element is itself a Must-fix finding, distinct from a low-confidence pairing).

## Severity defaults

Severity = category × magnitude × role (body text / primary CTA outrank decorative chrome).

| Severity | Examples |
|---|---|
| **✗ Must-fix** | element present in Figma but absent live (or extra live element); wrong font-family; large color delta (ΔE > 5) on text/primary surface; size off > 10% or > 24px; wrong sibling order |
| **⚠ Should-fix** | spacing/position off 2–8px; font-size off 1–2px; minor color delta (ΔE 2–5); line-height / letter-spacing drift |
| **✓ within tolerance** | all properties inside the tolerances above |

## Per-category verdict

For each frame, each of the five categories gets one mark:
- **✓** — every paired property in that category is within tolerance.
- **⚠** — only Should-fix drift in that category.
- **✗** — at least one Must-fix in that category.

## Report template

```
# Design-match report — <page/route> ↔ <figma file>
Roll-up: <N> frames · Must-fix <m> · Should-fix <s> · couldn't-align <c>   (no overall score)

## Frame: <frame name> @ <width>px
Color ✓ · Typography ✗ · Spacing ⚠ · Layout ✓ · Sizing ⚠

### Must-fix
- [typography] 'Hero heading' font-family: live `Inter` vs Figma `Söhne` (Δ family) —
  live `.hero h1` / node 12:3 · tol: exact
### Should-fix
- [spacing] 'CTA' padding-top: live `12px` vs Figma `16px` (Δ4px) —
  live `.cta` / node 9:7 · tol: ≤1px default
### Couldn't align
- Figma node 'Badge/new' (14:2) — no live match (confidence 0.31 < 0.6 bar)
- live `.cookie-banner` — no Figma node (present live, absent in design)
```

A clean category says so (`✓`). A frame where no pairs cleared the confidence bar reports that
explicitly (all in couldn't-align) — never a silent pass.
