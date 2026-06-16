# figma-design-to-working-prototype Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the P1 skill `figma-design-to-working-prototype` — a thin orchestrator that fuses a finished Figma design (pixels) with its use-case-narrative (behavior) into one pixel-perfect, walkable prototype — plus the supporting doc updates.

**Architecture:** Behavior-first thin orchestrator. Step 1 delegates to `use-case-narrative-to-prototype` to build a walkable skeleton; step 2 delegates to `implement-figma-design` to re-skin each screen in place (presentation only, wiring untouchable); a two-phase verification gate (walk → per-(screen×state) pixel diff → walk again) proves both halves. No own scaffold step — the host comes from step 1.

**Tech Stack:** Markdown skill files only. This repo is a skill-only scaffold — no package.json, no build/test runner. "Tests" in this plan are deterministic `grep`/read checks with expected output.

## Global Constraints

- **Stay stack-agnostic.** No hardcoded framework/design-system/domain assumptions in skill prose (CLAUDE.md convention).
- **Clarify until clear.** Every suite skill opens with an "ask until clear" rule; this one must too.
- **Thin orchestrator.** The SKILL.md references `implement-figma-design` and `use-case-narrative-to-prototype` by name; it does NOT duplicate their reference files or re-implement their extract/parse logic.
- **Model-invocable.** No `disable-model-invocation` in the frontmatter (unlike the two review commands).
- **Behavior-first order is load-bearing.** Skeleton → re-skin, never the reverse (per ADR 0002).
- **Both-inputs trigger.** The skill fires only when a finished Figma design AND a flow/UCN are both present; single-input cases route to the named sibling.
- **Canonical vocabulary** defined in SKILL.md (not a new CONTEXT.md): *skeleton*, *re-skin*, *behavior-only state*, *(screen × state)*.
- Source of truth for every decision: `docs/superpowers/specs/2026-06-17-figma-design-to-working-prototype-design.md` and `docs/adr/0002-p1-composes-sibling-suite-skills.md` (both already committed).

---

### Task 1: Write the orchestrator skill

**Files:**
- Create: `skills/figma-design-to-working-prototype/SKILL.md`

**Interfaces:**
- Consumes: nothing (first task). Reads the two sibling skills by name at runtime.
- Produces: the skill file. Later tasks reference its exact skill name `figma-design-to-working-prototype` and its dependency on `use-case-narrative-to-prototype` + `implement-figma-design`.

- [ ] **Step 1: Write the skill file**

Create `skills/figma-design-to-working-prototype/SKILL.md` with EXACTLY this content:

````markdown
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
````

- [ ] **Step 2: Verify the frontmatter and required sections exist**

Run:
```bash
F=skills/figma-design-to-working-prototype/SKILL.md
head -1 "$F"                                            # expect: ---
grep -q '^name: figma-design-to-working-prototype$' "$F" && echo NAME_OK
grep -q 'disable-model-invocation' "$F" && echo HAS_DISABLE || echo MODEL_INVOCABLE_OK
grep -qi 'ask until clear' "$F" && echo CLARIFY_OK
for h in 'When this applies' 'Workflow' 'Dependencies' 'Vocabulary'; do grep -q "$h" "$F" && echo "SECTION_OK: $h"; done
```
Expected output includes: `---`, `NAME_OK`, `MODEL_INVOCABLE_OK`, `CLARIFY_OK`, and `SECTION_OK:` for each of the four headings. Must NOT print `HAS_DISABLE`.

- [ ] **Step 3: Verify the thin-orchestrator contract and behavior-first order**

Run:
```bash
F=skills/figma-design-to-working-prototype/SKILL.md
grep -q 'use-case-narrative-to-prototype' "$F" && echo SIBLING1_OK
grep -q 'implement-figma-design' "$F" && echo SIBLING2_OK
grep -q 'page-to-figma' "$F" && echo ROUTE_OK
grep -qi 'behavior-first' "$F" && echo ORDER_OK
grep -qi 'presentation only' "$F" && echo RESKIN_CONTRACT_OK
grep -qi 'behavior-only' "$F" && echo STATE_TERM_OK
grep -q '0002-p1-composes-sibling-suite-skills' "$F" && echo ADR_LINK_OK
```
Expected: all seven `*_OK` lines print.

- [ ] **Step 4: Read the file once for house-style fidelity**

Read the file top to bottom and confirm, by eye: (a) no hardcoded framework/design-system/
domain is baked in as a requirement (React appears only as the *confirmed default* inherited
from the sibling, not a mandate); (b) the single-input routing names all three siblings;
(c) the workflow is the six steps in spec §3, in order. Fix any drift inline. No code change
if all three hold.

- [ ] **Step 5: Commit**

```bash
git add skills/figma-design-to-working-prototype/SKILL.md
git commit -m "feat: add figma-design-to-working-prototype skill (P1)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Harden the no-codebase mode in use-case-narrative-to-prototype

**Files:**
- Modify: `skills/use-case-narrative-to-prototype/SKILL.md` (the "### 3. Detect the stack and build" section)

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: a robust, explicit no-codebase scaffold path that Task 1's step 2 relies on ("the host comes from this delegation").

- [ ] **Step 1: Verify the current text before editing**

Run:
```bash
grep -n 'default to \*\*React\*\*' skills/use-case-narrative-to-prototype/SKILL.md
```
Expected: one match inside section "### 3. Detect the stack and build". This confirms the anchor you are about to replace.

- [ ] **Step 2: Replace the no-codebase sentence with an explicit mode**

In `skills/use-case-narrative-to-prototype/SKILL.md`, find this exact paragraph in section
"### 3. Detect the stack and build":

```markdown
Detect the target project's stack and conventions (framework, routing, styling, component
patterns) and build within them. If there is no existing project to host the prototype,
default to **React**, and confirm that default with the user before scaffolding.
```

Replace it with:

```markdown
Detect the target project's stack and conventions (framework, routing, styling, component
patterns) and build within them.

**No codebase yet?** A pure designer often has no target repo — that is expected, not a
blocker. Do not hunt for a stack to conform to. Instead, scaffold a fresh standalone app
to host the prototype:

- Default to **React**, and **confirm that default with the user** before scaffolding (offer
  their stack if they have a preference).
- Scaffold the minimum that runs and is walkable — a single app with client-side routing,
  local mock state/data (no backend), and a dev server the user can open. Use the framework's
  standard starter rather than hand-rolling configuration.
- Tell the user how to run it, and keep it self-contained so it can be zipped or handed off.

Once a host exists (detected or scaffolded), build within it as below.
```

- [ ] **Step 3: Verify the edit landed and the section still parses**

Run:
```bash
F=skills/use-case-narrative-to-prototype/SKILL.md
grep -q 'No codebase yet?' "$F" && echo MODE_OK
grep -q 'confirm that default with the user' "$F" && echo CONFIRM_OK
grep -c 'default to \*\*React\*\*' "$F"   # expect: 1 (no duplicate paragraph left behind)
```
Expected: `MODE_OK`, `CONFIRM_OK`, and `1`.

- [ ] **Step 4: Commit**

```bash
git add skills/use-case-narrative-to-prototype/SKILL.md
git commit -m "feat: harden no-codebase scaffold mode in use-case-narrative-to-prototype

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Update suite docs (CLAUDE.md + ROADMAP.md)

**Files:**
- Modify: `CLAUDE.md` (intro count, suite list, conventions)
- Modify: `ROADMAP.md` (mark P1 shipped; ROADMAP fix #1 partial)

**Interfaces:**
- Consumes: the skill name and behavior from Tasks 1–2.
- Produces: nothing downstream (terminal documentation task).

- [ ] **Step 1: Update the skill count and add the suite entry in CLAUDE.md**

In `CLAUDE.md`, change the count from eight to nine. Find:

```markdown
It contains eight portable, stack-agnostic Claude Code skills under [skills/](skills/)
```

Replace `eight` with `nine`.

Then, in the "## The skill suite" list, add this entry immediately after the
`use-case-narrative-to-prototype` entry (keeping the pipeline grouping intact):

```markdown
- **[figma-design-to-working-prototype](skills/figma-design-to-working-prototype/SKILL.md)** — *fusion, finished design + flow → working prototype.* A **thin orchestrator** that fuses a finished Figma design (pixels) with its use-case-narrative (behavior) into one prototype that is **both** pixel-perfect **and** walkable. Behavior-first: it delegates the walkable **skeleton** to `use-case-narrative-to-prototype`, then **re-skins** each screen in place (presentation only, wiring untouchable) via `implement-figma-design`, gated by a two-phase check (behavioral walk → per-(screen × state) pixel diff → behavioral walk again). Fires **only when both a finished Figma design and a flow/UCN are present** for the same screens; single-input cases route to the relevant sibling. **This is the second skill with a hard dependency on sibling suite skills** (after `page-to-figma`) — see `docs/adr/0002-p1-composes-sibling-suite-skills.md`. Model-invocable. Needs the Figma MCP read tools transitively via its siblings.
```

- [ ] **Step 2: Add a conventions note in CLAUDE.md**

In the "## Conventions when editing these skills" section, append this bullet to the "Don't
confuse direction." bullet group (as its own bullet):

```markdown
- **Keep the fusion skill thin and behavior-first.** `figma-design-to-working-prototype` must stay a thin orchestrator of `use-case-narrative-to-prototype` (skeleton) + `implement-figma-design` (re-skin), in that order — don't reverse to pixels-first and don't inline either sibling's logic. Its re-skin contract is **presentation only, wiring untouchable**; preserve it. See `docs/adr/0002-p1-composes-sibling-suite-skills.md`.
```

- [ ] **Step 3: Verify the CLAUDE.md edits**

Run:
```bash
grep -q 'nine portable' CLAUDE.md && echo COUNT_OK
grep -q 'figma-design-to-working-prototype](skills/figma-design-to-working-prototype/SKILL.md)' CLAUDE.md && echo ENTRY_OK
grep -q 'Keep the fusion skill thin and behavior-first' CLAUDE.md && echo CONVENTION_OK
```
Expected: `COUNT_OK`, `ENTRY_OK`, `CONVENTION_OK`.

- [ ] **Step 4: Mark P1 shipped in ROADMAP.md**

In `ROADMAP.md`, change the P1 heading from:

```markdown
### P1 — `figma-design-to-working-prototype`
```

to:

```markdown
### P1 — `figma-design-to-working-prototype` — ✅ SHIPPED
```

Then add this status line immediately under that heading, before the existing
`**Input → output:**` line:

```markdown
**Status:** shipped. Thin orchestrator, **behavior-first** (skeleton via
`use-case-narrative-to-prototype` → in-place **re-skin** via `implement-figma-design`),
two-phase verification gate, proposed-then-confirmed frame↔step mapping, model-invocable with
a both-inputs-required trigger. Decisions in
`docs/superpowers/specs/2026-06-17-figma-design-to-working-prototype-design.md`; cross-skill
dependency in `docs/adr/0002-p1-composes-sibling-suite-skills.md`.
```

- [ ] **Step 5: Note ROADMAP fix #1 as partially done**

In `ROADMAP.md` section "## 5. Fixes to existing skills", change fix #1 from:

```markdown
1. **Add a "no codebase yet" mode.** The prototype/code skills should scaffold a fresh
   standalone app gracefully when there's no target repo (a pure designer usually has none)
   instead of hunting for a stack to conform to.
```

to:

```markdown
1. **Add a "no codebase yet" mode.** *(Partially done — `use-case-narrative-to-prototype`
   hardened alongside P1; `implement-figma-design`'s standalone case still open.)* The
   prototype/code skills should scaffold a fresh standalone app gracefully when there's no
   target repo (a pure designer usually has none) instead of hunting for a stack to conform
   to.
```

- [ ] **Step 6: Verify the ROADMAP.md edits**

Run:
```bash
grep -q 'P1 — `figma-design-to-working-prototype` — ✅ SHIPPED' ROADMAP.md && echo P1_SHIPPED_OK
grep -q 'Partially done — `use-case-narrative-to-prototype` ' ROADMAP.md && echo FIX1_OK
```
Expected: `P1_SHIPPED_OK`, `FIX1_OK`.

- [ ] **Step 7: Commit**

```bash
git add CLAUDE.md ROADMAP.md
git commit -m "docs: document P1 fusion skill in CLAUDE.md and ROADMAP.md

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Self-Review

**1. Spec coverage** (spec §2 decisions → task):
- Thin orchestrator (1) → Task 1 body + Step 3 check + CLAUDE.md convention (Task 3.2). ✓
- Behavior-first (2) → Task 1 Workflow §1–6 + Step 3 `ORDER_OK`. ✓
- In-place re-skin (3) → Task 1 Workflow §4 + Step 3 `RESKIN_CONTRACT_OK`. ✓
- Two-phase gate (4) → Task 1 Workflow §3/§4/§5. ✓
- Proposed-then-confirmed mapping (5) → Task 1 Workflow §1. ✓
- No own scaffold; harden UCN-to-prototype (6) → Task 1 §2 (no scaffold step) + Task 2. ✓
- Model-invocable, both-inputs trigger (7) → Task 1 frontmatter + "When this applies" + Step 2 `MODEL_INVOCABLE_OK`. ✓
- Vocabulary in SKILL.md (spec §5) → Task 1 "Vocabulary used below". ✓
- Scope/ship list (spec §4) → Tasks 1–3 cover SKILL.md, UCN harden, CLAUDE.md, ROADMAP.md; ADR 0002 + spec already committed. ✓
- Deferred items (implement-figma-design no-codebase) correctly NOT in any task. ✓

**2. Placeholder scan:** No "TBD"/"TODO"/"handle edge cases"/"similar to". Full file content is inline in Task 1 Step 1; edit anchors are exact strings in Tasks 2–3. ✓

**3. Type consistency:** The skill name `figma-design-to-working-prototype` is identical in the frontmatter (Task 1), the CLAUDE.md entry (Task 3.1), the convention bullet (Task 3.2), and the ROADMAP heading (Task 3.4). The ADR filename `0002-p1-composes-sibling-suite-skills` matches across Task 1 body, Task 3.1, Task 3.2, and the (committed) spec. Sibling names `use-case-narrative-to-prototype` / `implement-figma-design` are spelled consistently throughout. ✓

No gaps found.
