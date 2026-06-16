---
name: figma-design-to-working-prototype
description: >-
  Fuse a finished Figma design (pixels) with its use-case-narrative / flow (behavior) into
  ONE prototype that is both pixel-perfect AND clickable end to end (design + flow → working
  prototype). Use this skill ONLY when the user has BOTH a finished Figma design AND a
  flow/UCN for the same screens and wants a single artifact that looks exact and walks the
  flow. Triggers: "I have the Figma and the use-case narrative — give me one prototype that
  looks right and clicks through", "make this Figma design walkable against this flow", "fuse
  this design and this flow into a working prototype". If you have ONLY a Figma design (no
  flow) → use implement-figma-design. If you have ONLY a flow/UCN (no design) → use
  use-case-narrative-to-prototype. To push running code INTO Figma → use page-to-figma.
---

# Figma Design → Working Prototype (pixels + behavior)

Turn a designer's **finished Figma design** and its **use-case-narrative (UCN)** into a
single prototype that is **both** pixel-perfect **and** walkable end to end — the artifact a
designer most wants to test and hand off. The designer already drew the screens (pixels) and
wrote the flow (behavior); this skill fuses those two halves into one working thing.

This skill is a **thin orchestrator**. It does not transcribe Figma or parse the UCN itself —
it sequences two sibling skills and adds only the fusion and verification glue:

- `use-case-narrative-to-prototype` builds the walkable **skeleton** (behavior).
- `implement-figma-design` **re-skins** each screen pixel-perfect (pixels).

Both siblings are a **hard dependency** — if either is unavailable, stop and say so rather
than half-running. Why this skill composes siblings instead of standing alone is recorded in
`docs/adr/0002-p1-composes-sibling-suite-skills.md`.

**Vocabulary used below:**
- **skeleton** — the walkable, default-UI prototype produced by step 1 (behavior, not pixels).
- **re-skin** — replace a screen's presentation to match its Figma frame while leaving all
  wiring (handlers, routes, state, conditions) untouched.
- **behavior-only state** — a UCN state with no mapped Figma frame: walk-verified, not
  pixel-verified.
- **(screen × state)** — the unit of pixel verification; one screen may have several states
  (e.g. a default and an Extension error state), each with its own frame.

## Before you proceed — ask until clear

While this skill is active, **never silently guess.** A fused prototype that quietly invents
a screen-to-flow mapping, a missing state, or an interaction is misleading. If the
frame↔step mapping is ambiguous, a UCN state has no obvious frame (or vice versa), an
Extension's condition is underspecified, or you can't tell which stack to target — **stop and
ask the user, and keep asking until everything is clear.** Batch related questions, but do
not build past an unresolved gap.

## When this applies — and when it doesn't

Use this skill **only** when the user has **both** inputs for the same screens:

1. a finished Figma design (link/node, usually several frames), **and**
2. a flow for those screens — a UCN doc (what `figjam-to-use-case-narrative` produces) or a
   looser flow description.

If only one input is present, **route away rather than half-running**:

- Only a Figma design, no flow → `implement-figma-design`.
- Only a flow/UCN, no design → `use-case-narrative-to-prototype`.
- Pushing running code *into* Figma → `page-to-figma`.

A looser flow description is acceptable (you lean on `use-case-narrative-to-prototype`'s
tolerance), but a finished Figma with **no** described flow at all is the single-input case —
route to `implement-figma-design`. If the user invoked this skill with only one input, ask
for the other or offer to route, rather than proceeding.

## Workflow

The order is **behavior-first**: build the walkable skeleton, then re-skin it to the pixels.
This is load-bearing — it lets each sibling run in its natural mode, which is what keeps this
skill genuinely thin. Do not reverse it.

### 1. Gather inputs and propose the frame↔step mapping

Pull the Figma frame list/metadata (frame names) and read the UCN's screen-steps. **Auto-
propose a mapping table** from Figma frames to UCN screen-steps (including Extension states
like `4a`), then **present it to the user and get confirmation before building anything.**
Surface gaps both ways:

- a UCN screen-step or Extension with **no** matching frame → it will be **behavior-only**;
- a Figma frame with **no** matching step → flag it (unused, or a missing flow step).

Build nothing until the user confirms or corrects the mapping.

### 2. Build the skeleton (delegate to use-case-narrative-to-prototype)

Hand the UCN to `use-case-narrative-to-prototype` and let it run in its normal mode: derive
routes, navigation, mock state, Extensions, and Business Rules, and produce a walkable
prototype with its own default UI. This step also **establishes the host** — if there is no
target repo, that skill scaffolds a fresh standalone app (React by default, confirmed with
the user). Do not add a separate scaffold step here; the host comes from this delegation.

### 3. Behavioral walk #1 (gate the flow before skinning)

Verify the skeleton against the UCN **before** spending effort on pixels: every Main Success
Scenario step reachable in order to a Postcondition, key Extensions triggerable, Business
Rules enforced. Fix flow gaps now, while the UI is still cheap to change.

### 4. Re-skin each screen in place (delegate to implement-figma-design)

For each confirmed **(screen × state)** in the mapping, hand the mapped Figma frame to
`implement-figma-design` to match it pixel-for-pixel. State the contract explicitly when you
delegate: **edit presentation only — markup and styles change to match the frame; every
onClick handler, route target, state binding, and conditional branch the skeleton established
stays untouched.** Multi-state screens get each state skinned to its own frame and left bound
to the skeleton's condition (e.g. the login error state still renders only when
`authFailed === true`).

Run `implement-figma-design`'s screenshot diff here, but per **(screen × state)**: drive the
prototype into each mapped state first (set the flag / click the path), then diff the rendered
screen against its frame. A state that is **behavior-only** (no frame) is not pixel-diffed —
note it. A frame with no reachable path is a mapping gap — surface it.

### 5. Behavioral walk #2 (regression after skinning)

Re-run the walk from step 3 to prove the re-skin broke no wiring — the backstop for the
"wiring untouchable" contract. If a handler, route, or conditional state was lost during
skinning, fix it and re-diff the affected screen.

### 6. Report coverage

Report explicitly so the user sees exactly how faithful the prototype is:

- **Per screen:** pixel-verified (which states) vs behavior-only.
- **Per UCN step / Extension / Business Rule:** covered, stubbed, or gap.
- **Any assumption** you made (a mapping you inferred, a state you couldn't reach, a visual
  you guessed).

## When to stop and ask

This restates the clarify-until-clear rule for the moments it bites hardest: an ambiguous
frame↔step match, a UCN state with no frame (or a frame with no step), an Extension whose
condition you can't pin down, or a delegation that would force `implement-figma-design` to
alter wiring. **Ask the user** rather than improvising, and keep asking until it's
unambiguous.

## Dependencies

- **Sibling skills (hard dependency):** `use-case-narrative-to-prototype`,
  `implement-figma-design`. Stop if either is absent.
- **Figma MCP read tools** (used transitively via the siblings): `get_design_context`,
  `get_screenshot`, `get_metadata`, `get_variable_defs`.
- Browser/screenshot tooling for the per-state pixel diff (whatever the project has; the
  siblings set this up).
