# `figma-design-to-working-prototype` — design spec

**Date:** 2026-06-17
**Status:** approved (pending implementation)
**Roadmap item:** P1 (+ partial ROADMAP fix #1)
**Branch:** `feat/figma-design-to-working-prototype`

---

## 1. Problem

The suite has two prototype halves that don't meet:

- `implement-figma-design` produces **pixels** — a static, 1:1 pixel-perfect transcription
  of a finished Figma frame, verified by screenshot diff.
- `use-case-narrative-to-prototype` produces **behavior** — a walkable, clickable flow from
  a UCN, with generic default visuals.

No single path turns a **finished Figma design + its flow** into a prototype that is *both*
pixel-faithful *and* behaviorally real — the artifact a designer most wants to test and hand
off. P1 closes that gap.

It honors the suite's guiding principle: **the designer owns the Figma design itself.** P1
never generates or critiques design; it fuses the designer's own finished frames with their
documented flow into one working artifact.

---

## 2. Locked decisions

Each was resolved by grilling; rationale included so a future reader sees the trade-off.

1. **Thin orchestrator, not standalone.** P1 sequences the two existing build skills and
   adds only the fusion + verification glue. The two source skills stay single-source-of-
   truth; P1 does not duplicate their Figma-extract or UCN-parse logic.

2. **Behavior-first build order (skeleton → re-skin).** P1 runs each sub-skill in its
   *natural* mode:
   1. `use-case-narrative-to-prototype` builds the walkable **skeleton** (routes, nav, mock
      state, Extensions, Business Rules) with its own default UI.
   2. `implement-figma-design` then **re-skins** each screen pixel-perfect against its mapped
      Figma frame.
   This is what makes the thin-orchestrator claim *honest*: neither skill is asked to operate
   outside its built-in workflow. (Pixels-first was considered and rejected because
   `use-case-narrative-to-prototype` has no "wire flow onto pre-built screens" mode — it would
   force P1 to own a fusion step the orchestrator framing denies.)

3. **In-place re-skin; wiring is untouchable.** Re-skinning edits a screen's *presentation
   only* — markup/styles change to match Figma; every onClick handler, route target, state
   binding, and conditional branch the skeleton established is **preserved**. Multi-state
   screens (a UCN Extension with its own frame) get each state skinned to its corresponding
   frame and left bound to the skeleton's condition. (Generate-then-port was rejected: the
   port step is where wiring silently gets dropped.)

4. **Two-phase verification gate.**
   1. After the skeleton: run the **behavioral walk** (flow reachable in order to a
      Postcondition; key Extensions triggerable; Business Rules enforced) — catches flow bugs
      *before* pixel effort is spent.
   2. During re-skin: **per-(screen × state) pixel diff** — for each frame in the confirmed
      mapping, drive the prototype into that state, then screenshot-diff against the frame.
   3. After re-skin: **re-run the behavioral walk** as a regression check that the in-place
      contract held.
   A UCN state with an Extension but **no frame** is **behavior-only** — walk-verified, not
   pixel-verified — and reported as such. A frame with no reachable path is flagged as a
   mapping gap.

5. **Frame↔step mapping is proposed, then user-confirmed.** P1 auto-matches Figma frames to
   UCN screen-steps by name/content, presents the proposed table, surfaces gaps both ways
   (step with no frame; frame with no step), and **builds nothing until the user confirms**.
   Honors the suite's clarify-until-clear rule.

6. **No own scaffold step; host comes from step 1.** Under behavior-first,
   `use-case-narrative-to-prototype` runs first and already has the no-codebase behavior
   ("no project → default to React, confirm before scaffolding"). P1 inherits the host from
   it. `implement-figma-design` therefore **always runs on an existing host** in P1's flow
   and never hits the no-codebase case here.

7. **Model-invocable, both-inputs-required trigger.** P1 is model-invocable (a generative
   build skill, like its siblings and `spec-to-brief`; *not* a review command — no
   `disable-model-invocation`). It fires only on the **conjunction**: a finished Figma design
   **and** a flow/UCN for the same screens, wanting one artifact that is both pixel-faithful
   and walkable. Single-input prompts route away — Figma only → `implement-figma-design`;
   flow/UCN only → `use-case-narrative-to-prototype`; code → Figma → `page-to-figma`. Invoked
   with only one input, P1 stops and asks for the other (or offers to route). A looser flow
   description is accepted (leaning on `use-case-narrative-to-prototype`'s tolerance), but a
   finished Figma with *no* described flow is the single-input case and routes away.

---

## 3. Workflow (as it will appear in SKILL.md)

1. **Gather + map.** Pull Figma frame metadata; parse the UCN's screen-steps. Auto-propose a
   frame↔step mapping table, surface both-way gaps, and **get user confirmation before any
   build** (decision 5).
2. **Build the skeleton.** Delegate to `use-case-narrative-to-prototype` to produce the
   walkable prototype with default UI — establishing the host (decision 6), routes, mock
   state, Extensions, and Business Rules.
3. **Behavioral walk #1.** Verify the flow against the UCN before skinning (decision 4.1).
4. **Re-skin each screen in place.** For each confirmed (screen × state), delegate to
   `implement-figma-design` to match the Figma frame pixel-for-pixel, **presentation only**,
   wiring untouchable (decisions 3, 4.2). Run the per-state pixel diff here.
5. **Behavioral walk #2.** Re-run the walk to confirm re-skinning broke no wiring
   (decision 4.3).
6. **Report coverage.** Per screen: pixel-verified vs behavior-only; per UCN
   step/Extension/Rule: covered, stubbed, or gap; plus any assumption made.

---

## 4. Scope of this branch

**Ships:**
- `skills/figma-design-to-working-prototype/SKILL.md` — the orchestrator skill, referencing
  the two source skills by name (not duplicating their reference files).
- A **hardened no-codebase mode** in `skills/use-case-narrative-to-prototype/SKILL.md` —
  make the React default + confirm explicit and robust (the one that actually fires in P1).
- `docs/adr/0002-p1-composes-sibling-suite-skills.md` — records the architecture decision.
- `CLAUDE.md` — 8 → 9 skills: suite description, the "don't confuse direction" note, and a
  one-line nod to the new vocabulary; note P1 as the second skill with a hard dependency on
  sibling suite skills (after `page-to-figma`).
- `ROADMAP.md` — mark P1 shipped; note ROADMAP fix #1 partially done (UCN-to-prototype only).

**Out of scope (deferred):**
- `implement-figma-design`'s standalone no-codebase fix — out of P1's path; its own
  ROADMAP-fix branch.
- Design generation (designer owns Figma) and critique (that's P2).
- Any Figma *write* path.

---

## 5. Vocabulary (canonical terms — live in SKILL.md, not a CONTEXT.md)

This repo uses CLAUDE.md + `docs/adr/` as its context surface and has no `CONTEXT.md`; these
terms are defined in the skill itself to honor that convention.

- **skeleton** — the walkable, default-UI prototype produced by step 1 (behavior, not pixels).
- **re-skin** — replace a screen's presentation to match its Figma frame while leaving all
  wiring (handlers, routes, state, conditions) untouched.
- **behavior-only state** — a UCN state with no mapped Figma frame: walk-verified, not
  pixel-verified.
- **(screen × state)** — the unit of pixel verification; one screen may have several states
  (e.g. a default and an Extension error state), each with its own frame.

---

## 6. Dependencies & risks

- **Hard dependency on two sibling skills** (`implement-figma-design`,
  `use-case-narrative-to-prototype`). Recorded in ADR 0002. If either is absent, P1 stops and
  says so rather than half-running.
- **In-place re-skin relies on `implement-figma-design` respecting a "don't touch logic"
  boundary.** P1 must state this contract explicitly when delegating; behavioral walk #2 is
  the backstop that catches a violation.
- **Per-state screenshotting requires driving the prototype into each state** before the
  diff — more than `implement-figma-design` does alone, so P1 owns that navigation step.

---

## 7. Open questions

None blocking. Implementation-plan stage will decide the exact prose of the delegation
instructions (how P1 phrases the "presentation-only, wiring untouchable" contract to
`implement-figma-design`).
