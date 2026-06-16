# `critique-figma-design` — design spec

**Date:** 2026-06-17
**Status:** approved (pending implementation)
**Roadmap item:** P2
**Branch:** `feat/critique-figma-design`

---

## 1. Problem

The suite can build, document, and reason about a design, but nothing gives the designer a
**second pair of eyes** on a Figma frame they drew. P2 fills that — a self-check that flags
what is *checkable*, so the designer catches accessibility failures, design-system drift,
structural slips, and usability-heuristic gaps before handoff.

It honors the suite's guiding principle: **the designer owns the aesthetic.** This skill is a
**self-check, not a taste-maker** — it never dictates aesthetic preference. It reports two
kinds of findings, kept visibly distinct so the designer always knows which is which:

- **Measured** — cites a *value vs a threshold or concrete rule* (objective).
- **Heuristic (judgment-based)** — cites a *named Nielsen heuristic + a specific observable
  element/state* in the frame (evidence-anchored, never pure preference).

---

## 2. Locked decisions

1. **Command-only.** Frontmatter carries `disable-model-invocation: true`. It fires only on
   explicit `/critique-figma-design`. Rationale: critique borders the designer's craft and
   should never fire uninvited; and `implement-figma-design` already owns the "user shares a
   Figma link" trigger space — a model-invocable critique would collide with it. Consistent
   with the suite's other review skills (`harden-doc`, `biz-review`), which are command-only
   for the same "unsolicited review is obnoxious" reason.

2. **Read-only.** Uses only Figma MCP **read** tools: `get_design_context`, `get_screenshot`,
   `get_metadata`, `get_variable_defs`. No `figma-use`, no writes, ever.

3. **Five check categories.** Four measured + one judgment:
   - **Accessibility** *(measured)* — contrast ratios, touch-target sizes, min text sizes.
   - **Design-system consistency** *(measured)* — values not bound to a Figma variable / not
     in the token set; detached or overridden styles.
   - **Structure & hierarchy** *(measured, checkable only)* — spacing-scale breaks,
     misalignment, near-duplicate text styles, heading-size inversions. Excludes
     subjective "balance/feel."
   - **Layer & naming hygiene** *(measured, lowest value)* — unnamed layers, ungrouped
     stacks, detached component instances.
   - **Heuristic evaluation — Nielsen's 10** *(judgment)* — each finding anchored to a
     specific observable element/state. Interaction-dependent heuristics (e.g. User control /
     undo, Help users recover from errors) are evaluated only as far as the static frame +
     any shown states allow, then marked **⚠ needs live flow — partial** and the rest
     deferred to the prototype/flow path.

4. **The taste guardrail (binding on every finding).**
   - A measured finding MUST cite **location (layer name + node id) · measured value ·
     threshold · source**.
   - A heuristic finding MUST cite **the named heuristic (H1–H10) · the specific observable
     element/state · why it signals that heuristic**.
   - No finding may be a bare aesthetic preference ("make it bolder", "this color is ugly").
     If the only thing to say about something is taste, the skill stays silent — that is the
     designer's call.

5. **Thresholds & sources — conform to target.** A11y thresholds use the target project's
   documented rules first (e.g. CLAUDE.md touch-target / body-font minimums, a contrast
   standard); else fall back to **WCAG AA** (4.5:1 normal text, 3:1 large) + platform
   touch-target defaults (44×44 iOS / 48 Android). The token set is the Figma file's own
   variables (`get_variable_defs`); if a target project token system exists, cross-check
   against it too. **Each finding states which source it used.**

6. **Report shape — severity-first measured, separate heuristic section, no score.**
   - Header counts: `Must-fix (n) · Should-fix (n) · Consider (n)` for measured findings,
     plus `Heuristic: n findings (m partial)`.
   - **Measured findings** grouped severity-first, each category-tagged. Severity defaults:
     **Must-fix** = hard a11y failures (contrast / touch-target / text-size); **Should-fix** =
     off-token + structure breaks; **Consider** = layer/naming hygiene.
   - **Heuristic findings** in their own section, each tagged by heuristic (H1–H10) and
     severity, with ⚠-partial markers for interaction-dependent ones.
   - **No 0–100 quality score** — a numeric grade implies judging the design's goodness,
     which is taste-making. Report counts of objective violations instead.
   - A clean category says so explicitly. A check that cannot be evaluated from the reads
     (e.g. contrast needs a resolved background the reads can't supply) is reported as
     **unable-to-check**, never as a pass.

7. **Clarify-until-clear.** Opens with the suite's standard rule: if the target frame,
   selection, or which project's conventions apply is ambiguous, stop and ask rather than
   guessing.

---

## 3. When NOT to use (routing)

- Building a Figma design into code → `implement-figma-design`.
- Pushing running code into Figma → `page-to-figma`.
- Challenging product premise / value / scope → `biz-review`.
- **Pure aesthetic preference** ("which color looks better?", "is this beautiful?") — out of
  scope; the skill declines, because that is the designer's craft.

---

## 4. Workflow (as it will appear in SKILL.md)

1. **Resolve the target & conventions.** Parse the Figma frame/node (or selection). Read the
   target project's documented a11y/ergonomics rules if any (else note defaults will apply).
   Ask if the target is ambiguous.
2. **Pull the reads.** `get_design_context`, `get_metadata`, `get_variable_defs`,
   `get_screenshot` — the ground truth for measurements and the token set.
3. **Run the four measured categories.** For each finding, record location · value ·
   threshold · source. Mark un-evaluable checks as unable-to-check.
4. **Run the heuristic pass (Nielsen-10).** For each heuristic, look for the observable
   signals listed in `references/check-catalog.md`; anchor each finding to a specific
   element/state; mark interaction-dependent gaps ⚠-partial.
5. **Assemble the report** in the shape of decision 6. State sources, keep measured and
   heuristic findings in separate sections, no score.

---

## 5. Scope of this branch

**Ships:**
- `skills/critique-figma-design/SKILL.md` — the skill (command-only frontmatter).
- `skills/critique-figma-design/references/check-catalog.md` — single combined reference:
  the measured per-check thresholds + default values + how to measure each from the MCP
  reads, AND the Nielsen-10 list with "what observable signals each heuristic on a static
  frame." Single-owner reference (like `figjam-sitemap-to-spec`'s guide); not part of any
  shared contract.
- `CLAUDE.md` — 9 → 10 skills: suite entry; update the doc-lens note to reflect a fourth
  review-type skill (three doc-review + one read-only Figma self-check); note it is read-only
  and command-only.
- `ROADMAP.md` — mark P2 ✅ SHIPPED.

**Out of scope:**
- Any aesthetic / taste judgment.
- Any Figma write (`figma-use`, `use_figma`).
- Any auto-trigger (it is command-only).
- A numeric quality score.
- Full evaluation of interaction-only heuristics — deferred to the prototype/flow path with
  a ⚠-partial marker.

---

## 6. Vocabulary (canonical terms — defined in SKILL.md)

- **measured finding** — a violation citing a value vs a threshold/rule; objective.
- **heuristic finding** — a usability observation citing a named Nielsen heuristic + a
  specific observable; judgment-based, evidence-anchored.
- **unable-to-check** — a check that cannot be evaluated from the available reads; reported
  as such, never as a pass.
- **⚠ partial** — an interaction-dependent heuristic evaluated only as far as a static frame
  allows; the rest defers to the live flow.

---

## 7. Open questions

None blocking. The implementation-plan stage will fix the exact wording of each measured
threshold and the per-heuristic observable-signal list in `references/check-catalog.md`.
