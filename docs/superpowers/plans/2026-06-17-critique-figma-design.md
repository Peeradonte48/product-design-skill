# critique-figma-design Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the P2 skill `critique-figma-design` — a command-only, read-only Figma self-check that returns a severity-ranked report of measured violations plus an evidence-anchored Nielsen-10 heuristic pass.

**Architecture:** One command-only SKILL.md (the workflow) + one combined `references/check-catalog.md` (measured thresholds, measurement methods, and per-heuristic observable signals). Read-only Figma MCP. Two finding types kept visibly distinct: measured (value vs threshold) and heuristic (named heuristic + observable). Plus suite-index doc updates.

**Tech Stack:** Markdown skill files only. Skill-only repo — no package.json, no test runner. "Tests" are deterministic `grep`/read checks with expected output.

## Global Constraints

- **Command-only:** frontmatter MUST carry `disable-model-invocation: true`. Fires only on `/critique-figma-design`.
- **Read-only:** only `get_design_context`, `get_screenshot`, `get_metadata`, `get_variable_defs`. NEVER `figma-use` / `use_figma` / any write.
- **Self-check, not taste-maker:** no bare aesthetic preference findings; if the only thing to say is taste, stay silent.
- **Two finding types, kept distinct:** measured cites `location · value · threshold · source`; heuristic cites `heuristic(H1–H10) · observable · why`.
- **No 0–100 quality score**, ever.
- **Conform-to-target thresholds:** project documented rules first, else WCAG AA (4.5:1 normal, 3:1 large) + platform touch defaults (44×44 iOS / 48 Android) for touch, 24×24 (WCAG 2.5.8) for pointer; source stated per finding.
- **Contrast = screenshot-pixel-sampling** primary; solid-fill fast-path; `unable-to-check` only for text over busy photo/gradient with no dominant background.
- **Role inference is evidenced, never guessed:** touch-target & heading checks require a cited role-signal (component instance / layer-name match `btn|button|cta|link|field|input` / structural cue); no signal → not flagged → coverage gap noted.
- **Touch-target is modality-aware:** infer touch vs pointer from frame width (~390–430px ⇒ touch; ~1280px+ ⇒ pointer) + project type; ask if ambiguous.
- **Spacing-scale token-gated:** flag only when explicit spacing tokens exist, else `unable-to-check`; misalignment + duplicate-text-style always run.
- **Per-frame report sectioning:** one section per frame; sub-tree scoping; confirm if >~8 frames.
- **Stay stack-agnostic.** No hardcoded framework/design-system/domain.
- **Clarify-until-clear** opener.
- Source of truth: `docs/superpowers/specs/2026-06-17-critique-figma-design-design.md`.

---

### Task 1: Write the check-catalog reference

**Files:**
- Create: `skills/critique-figma-design/references/check-catalog.md`

**Interfaces:**
- Consumes: nothing.
- Produces: the reference the SKILL.md points to. Section anchors used by Task 2's prose: "Measured checks", "Measurement methods", "Heuristic signals (Nielsen-10)".

- [ ] **Step 1: Write the reference file**

Create `skills/critique-figma-design/references/check-catalog.md` with EXACTLY this content:

````markdown
# Check catalog — critique-figma-design

This reference is single-owner (only `critique-figma-design` uses it). It defines the
measured thresholds, how to measure each from the read-only MCP, and the observable signals
for each Nielsen heuristic. Every finding cites its source; nothing here licenses an
aesthetic-taste judgment.

## Measured checks

Each measured finding records: **location (layer name + node id) · measured value · threshold
· source** (which rule supplied the threshold).

### Accessibility
| Check | Threshold (project rule first, else default) | Severity |
|---|---|---|
| Text contrast (normal <24px / <18.66px bold) | project contrast rule, else **WCAG AA 4.5:1** | Must-fix |
| Text contrast (large ≥24px / ≥18.66px bold) | project rule, else **WCAG AA 3:1** | Must-fix |
| Touch-target size (touch modality) | project min, else **44×44 iOS / 48×48 Android** | Must-fix |
| Target size (pointer modality) | project min, else **24×24 (WCAG 2.5.8)** | Must-fix |
| Min body text size | project min, else flag <12px as a review point | Should-fix |

### Design-system consistency
| Check | Rule | Severity |
|---|---|---|
| Off-token color/spacing/radius/type | value not bound to a Figma variable from `get_variable_defs` (and not in the project token set, if one is detected) | Should-fix |
| Detached / overridden style | a style override not traceable to a token or shared style | Should-fix |

### Structure & hierarchy
| Check | Rule | Severity |
|---|---|---|
| Misalignment | element edges/centers miss a shared line beyond a 1px tolerance (from `get_metadata`) | Should-fix |
| Near-duplicate text styles | two+ text styles differing only marginally in size/weight/line-height | Should-fix |
| Spacing-scale break | a gap not on the explicit spacing-token scale — **only when spacing tokens exist**, else `unable-to-check` | Should-fix |
| Heading-size inversion | a lower-level heading rendered larger than a higher-level one — **requires an evidenced heading role** | Should-fix |

### Layer & naming hygiene
| Check | Rule | Severity |
|---|---|---|
| Default-named layer | name matches `Frame \d+`, `Group \d+`, `Rectangle \d+`, etc. | Consider |
| Ungrouped stack | sibling nodes that visually form a unit but share no frame/group | Consider |
| Detached instance | a former component instance now detached | Consider |

## Measurement methods

- **Contrast — screenshot-pixel-sampling (primary).** Sample the rendered `get_screenshot`
  pixels at the text glyphs and the dominant adjacent background; compute the ratio on the
  already-composited image (handles transparency, gradients, overlaps). **Fast-path:** when
  text and background are both single solid fills resolvable from the reads, use those exact
  hex values. Reserve `unable-to-check` for text over a busy photo/gradient with no dominant
  background.
- **Role inference — evidenced, never guessed.** Before any role-dependent check (touch-target,
  heading-inversion), require a concrete role-signal: a component instance (e.g.
  `Button/primary`), a layer name matching `btn|button|cta|link|field|input` (or heading-ish
  naming), or a clear structural cue. No signal → do not flag; note the coverage gap.
- **Touch-target — modality-aware.** Infer modality from frame width (~390–430px ⇒ touch;
  ~1280px+ ⇒ pointer) and target project type (Flutter/iOS ⇒ touch). Apply the matching
  threshold and state the assumed modality + threshold + source in the finding. If signals
  conflict or are missing (e.g. ~768px frame, no project), ask.
- **Spacing-scale — token-gated.** Only measure against an explicit spacing-token scale from
  `get_variable_defs`; with no spacing tokens, mark `unable-to-check`. Misalignment and
  near-duplicate-text-style need no scale and always run.

## Heuristic signals (Nielsen-10)

Judgment-based. Each heuristic finding cites the **named heuristic · a specific observable
element/state · why it signals that heuristic**, and a severity (Must-fix / Should-fix /
Consider). Interaction-dependent heuristics are evaluated only as far as the static frame +
shown states allow, then marked **⚠ needs live flow — partial**.

| # | Heuristic | Observable signals on a static frame | Interaction-dependent? |
|---|---|---|---|
| H1 | Visibility of system status | no loading/disabled/selected/empty state shown for an interactive element | partial |
| H2 | Match between system & real world | unclear/jargon labels, icons whose meaning isn't conventional | no |
| H3 | User control & freedom | no visible back/cancel/undo affordance on a committed action | ⚠ partial |
| H4 | Consistency & standards | two styles for the same action; inconsistent control patterns across the frame | no |
| H5 | Error prevention | required field with no visible constraint/hint; destructive action with no guard shown | partial |
| H6 | Recognition rather than recall | icon-only controls with no labels; information needed but not present on screen | no |
| H7 | Flexibility & efficiency | no visible shortcut/secondary path for a frequent action | ⚠ partial |
| H8 | Aesthetic & minimalist design | competing primary CTAs / dense unprioritized content (objectively countable, not taste) | no |
| H9 | Help users recognize & recover from errors | error state shown without a recovery affordance or plain-language message | partial |
| H10 | Help & documentation | a complex flow with no visible help/hint entry point | no |
````

- [ ] **Step 2: Verify the reference content**

Run:
```bash
F=skills/critique-figma-design/references/check-catalog.md
for s in 'Measured checks' 'Measurement methods' 'Heuristic signals (Nielsen-10)'; do grep -q "$s" "$F" && echo "SECTION_OK: $s"; done
grep -q 'screenshot-pixel-sampling' "$F" && echo CONTRAST_OK
grep -q 'modality-aware' "$F" && echo MODALITY_OK
grep -q 'token-gated' "$F" && echo SPACING_OK
grep -Eqc 'H1|H10' "$F" && echo HEURISTICS_OK
```
Expected: three `SECTION_OK` lines, plus `CONTRAST_OK`, `MODALITY_OK`, `SPACING_OK`, `HEURISTICS_OK`.

- [ ] **Step 3: Commit**

```bash
git add skills/critique-figma-design/references/check-catalog.md
git commit -m "feat: add check-catalog reference for critique-figma-design

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Write the SKILL.md

**Files:**
- Create: `skills/critique-figma-design/SKILL.md`

**Interfaces:**
- Consumes: `references/check-catalog.md` from Task 1 (referenced by relative path).
- Produces: the skill. Later tasks reference the exact skill name `critique-figma-design`.

- [ ] **Step 1: Write the skill file**

Create `skills/critique-figma-design/SKILL.md` with EXACTLY this content:

````markdown
---
name: critique-figma-design
description: >-
  Run an objective self-check over a finished Figma frame and return a severity-ranked report
  of measured violations (accessibility, design-system consistency, structure, layer hygiene)
  plus an evidence-anchored Nielsen-10 heuristic pass. Read-only; never writes to Figma. This
  is a COMMAND-ONLY skill — it runs ONLY when the user explicitly invokes /critique-figma-design,
  never automatically. It is a self-check, not a taste-maker: every finding cites a measured
  value vs a threshold, or a named heuristic vs a specific observable — never bare aesthetic
  preference. For building a Figma into code use implement-figma-design; for pushing code into
  Figma use page-to-figma; for product premise/scope use biz-review.
disable-model-invocation: true
---

# Critique Figma Design (objective self-check)

Give a designer a **second pair of eyes** on a Figma frame they drew — flagging only what is
*checkable*. This is a **self-check, not a taste-maker**: the designer owns the aesthetic. The
report carries two kinds of findings, kept visibly distinct:

- **measured finding** — cites **location (layer + node id) · value · threshold · source**.
- **heuristic finding** — cites **a named Nielsen heuristic (H1–H10) · a specific observable
  element/state · why it signals that heuristic**.

No finding may be a bare aesthetic preference ("make it bolder", "this color is ugly"). If the
only thing to say about something is taste, **stay silent** — that is the designer's call.
There is **no 0–100 quality score** (a grade judges goodness, which is taste-making).

This skill is **read-only**: it uses only the Figma MCP read tools and **never** writes.

## Before you proceed — ask until clear

While this skill is active, **never silently guess.** If the target frame or selection is
ambiguous, if you can't tell whether the design is touch or pointer, or if you don't know which
project's conventions apply — **stop and ask the user, and keep asking until it's clear.** A
confident-but-wrong finding erodes trust faster than a question.

## When NOT to use

- Building a Figma design into code → `implement-figma-design`.
- Pushing running code into Figma → `page-to-figma`.
- Challenging product premise / value / scope → `biz-review`.
- **Pure aesthetic preference** ("which color looks better?", "is this beautiful?") — out of
  scope; decline, because that is the designer's craft.

## Workflow

Use `references/check-catalog.md` for the exact thresholds, measurement methods, and
per-heuristic observable signals.

### 1. Resolve the target & conventions
Parse the Figma frame/node (or selection). Read the target project's documented
accessibility/ergonomics rules if any (touch-target / body-font minimums, a contrast
standard); otherwise note that defaults will apply. If the target is ambiguous, ask.

### 2. Pull the reads
`get_design_context`, `get_metadata`, `get_variable_defs`, `get_screenshot` — ground truth for
measurements and the token set. **No writes, ever.**

### 3. Run the four measured categories
Apply the methods in `references/check-catalog.md`:
- **Contrast** by sampling the `get_screenshot` pixels (solid-fill fast-path when both are
  single solid fills); `unable-to-check` only for text over a busy photo/gradient.
- **Role-dependent checks** (touch-target, heading-inversion) only when a concrete role-signal
  exists; no signal → don't flag, note the coverage gap.
- **Touch-target** thresholds chosen by inferred modality (touch 44/48 vs pointer 24×24);
  state the assumed modality + threshold + source; ask if ambiguous.
- **Spacing-scale** only against explicit spacing tokens, else `unable-to-check`; misalignment
  and near-duplicate-text-style always run.

Record each finding as **location · value · threshold · source**. Mark un-evaluable checks
`unable-to-check` — never a pass.

### 4. Run the heuristic pass (Nielsen-10)
For each heuristic, look for the observable signals in the catalog; anchor each finding to a
specific element/state and say why it signals that heuristic. Mark interaction-dependent gaps
**⚠ needs live flow — partial**.

### 5. Assemble the report
One section **per frame** (a multi-frame selection → one section each + a one-line roll-up; a
sub-tree selection → scope to it; >~8 frames → confirm scope first). Shape:

```
## Critique: <frame name>
Measured — Must-fix (n) · Should-fix (n) · Consider (n)
Heuristic — n findings (m partial) · Must n · Should n · Consider n

### Measured
#### Must-fix
- [a11y] '<layer>' contrast 3.1:1 < 4.5:1 AA — node 12:34 · source: WCAG AA (no project rule)
#### Should-fix
- [tokens] '<layer>' #3A7BD5 not in color tokens — node 9:2
#### Consider
- [hygiene] 12 default-named layers

### Heuristic (judgment-based)
- [H4 Consistency · Should-fix] two button styles for the same action — nodes 9:1, 9:7
- [H3 User control · Consider] ⚠ needs live flow — no visible back/cancel on the confirm step
```

Keep **measured** and **heuristic** findings in separate sections; never merge their counts. A
clean category says so explicitly.

## Dependencies

- **Figma MCP read tools only:** `get_design_context`, `get_screenshot`, `get_metadata`,
  `get_variable_defs`. No `figma-use`. No write tools. This skill is standalone — it depends on
  no other suite skill.
````

- [ ] **Step 2: Verify frontmatter and command-only posture**

Run:
```bash
F=skills/critique-figma-design/SKILL.md
head -1 "$F"
grep -q '^name: critique-figma-design$' "$F" && echo NAME_OK
grep -q '^disable-model-invocation: true$' "$F" && echo COMMAND_ONLY_OK
grep -qi 'ask until clear' "$F" && echo CLARIFY_OK
for h in 'When NOT to use' 'Workflow' 'Dependencies'; do grep -q "$h" "$F" && echo "SECTION_OK: $h"; done
```
Expected: `---`, `NAME_OK`, `COMMAND_ONLY_OK`, `CLARIFY_OK`, and three `SECTION_OK` lines.

- [ ] **Step 3: Verify read-only + guardrails + routing**

Run:
```bash
F=skills/critique-figma-design/SKILL.md
test "$(grep -c 'use_figma' "$F")" = "0" && echo NO_WRITE_TOOL_OK || echo "WARN: use_figma appears — verify no write is invoked"
grep -q 'No `figma-use`' "$F" && echo NO_FIGMA_USE_OK
grep -q 'no 0–100 quality score' "$F" && echo NO_SCORE_OK
grep -q 'screenshot' "$F" && echo CONTRAST_METHOD_OK
grep -q 'check-catalog.md' "$F" && echo CATALOG_REF_OK
for s in 'implement-figma-design' 'page-to-figma' 'biz-review'; do grep -q "$s" "$F" && echo "ROUTE_OK: $s"; done
```
Expected: `NO_WRITE_TOOL_OK`, `NO_FIGMA_USE_OK`, `NO_SCORE_OK`, `CONTRAST_METHOD_OK`, `CATALOG_REF_OK`, and three `ROUTE_OK` lines. (`use_figma` must not appear; the only `figma-use` mention is the "No `figma-use`" prohibition.)

- [ ] **Step 4: Read the file once for house-style fidelity**

Read top to bottom and confirm by eye: (a) opens with clarify-until-clear; (b) two finding
types defined distinctly; (c) workflow is the five steps from spec §4; (d) no hardcoded
framework/design-system/domain; (e) no write tool is ever invoked. Fix any drift inline.

- [ ] **Step 5: Commit**

```bash
git add skills/critique-figma-design/SKILL.md
git commit -m "feat: add critique-figma-design skill (P2)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Update suite docs (CLAUDE.md + ROADMAP.md)

**Files:**
- Modify: `CLAUDE.md` (count nine→ten, suite entry, doc-lens convention)
- Modify: `ROADMAP.md` (mark P2 SHIPPED)

**Interfaces:**
- Consumes: skill name + behavior from Tasks 1–2.
- Produces: nothing downstream.

- [ ] **Step 1: Update the count in CLAUDE.md**

In `CLAUDE.md`, change both count references from nine to ten. Find and replace:
- `nine portable` → `ten portable`
- `The nine skills form` → `The ten skills form`

- [ ] **Step 2: Add the suite entry in CLAUDE.md**

In the "## The skill suite" list, add this entry immediately after the
`page-to-figma` entry:

```markdown
- **[critique-figma-design](skills/critique-figma-design/SKILL.md)** — *command-only, Figma frame → objective critique.* A **read-only** self-check that runs a finished Figma frame through an objective checklist and returns a severity-ranked report: four **measured** categories (accessibility, design-system consistency, structure/hierarchy, layer hygiene — each finding citing value · threshold · source) plus an evidence-anchored **Nielsen-10 heuristic** pass kept in a separate section. It is a **self-check, not a taste-maker** — never a bare aesthetic preference, and **no quality score**. Contrast is measured by screenshot-pixel-sampling; thresholds conform to the target project's rules first (else WCAG AA + platform defaults); touch-target is modality-aware; role-dependent checks require a cited role-signal. **Command-only** (`/critique-figma-design`, `disable-model-invocation: true`) so it never fires uninvited or collides with `implement-figma-design`. Read-only Figma MCP; depends on no other suite skill. See `references/check-catalog.md`.
```

- [ ] **Step 3: Update the doc-lens convention note in CLAUDE.md**

In the "## Conventions when editing these skills" section, find the bullet that begins
"**Keep the three doc lenses distinct.**" and append this sentence to the END of that
bullet's text (inside the same bullet):

```markdown
 A fourth review-type skill, `critique-figma-design`, is also **command-only** but is a *read-only Figma self-check* (objective + heuristic), not a doc lens — keep its `disable-model-invocation: true` too, and keep it from drifting into aesthetic taste-making (it cites measured values or named heuristics, never bare preference).
```

- [ ] **Step 4: Verify the CLAUDE.md edits**

Run:
```bash
grep -q 'ten portable' CLAUDE.md && echo COUNT1_OK
grep -q 'The ten skills form' CLAUDE.md && echo COUNT2_OK
grep -qc 'nine' CLAUDE.md && echo "WARN_nine_remains" || echo NO_STALE_NINE_OK
grep -q 'critique-figma-design](skills/critique-figma-design/SKILL.md)' CLAUDE.md && echo ENTRY_OK
grep -q 'fourth review-type skill' CLAUDE.md && echo CONVENTION_OK
```
Expected: `COUNT1_OK`, `COUNT2_OK`, `NO_STALE_NINE_OK`, `ENTRY_OK`, `CONVENTION_OK`. If `WARN_nine_remains` prints, find the remaining "nine" and fix it to "ten" (it is a stale skill count), then re-run.

- [ ] **Step 5: Mark P2 shipped in ROADMAP.md**

In `ROADMAP.md`, change the P2 heading from:

```markdown
### P2 — `critique-figma-design` (self-check, not taste-maker)
```

to:

```markdown
### P2 — `critique-figma-design` (self-check, not taste-maker) — ✅ SHIPPED
```

Then add this status line immediately under that heading, before the existing
`**Input → output:**` line:

```markdown
**Status:** shipped. Command-only, read-only Figma self-check. Four measured categories +
evidence-anchored Nielsen-10 heuristic pass (separate section), severity-first, no quality
score. Contrast via screenshot-pixel-sampling; conform-to-target thresholds; modality-aware
touch-targets; evidenced role-signals; token-gated spacing. Decisions in
`docs/superpowers/specs/2026-06-17-critique-figma-design-design.md`.
```

- [ ] **Step 6: Verify the ROADMAP.md edits**

Run:
```bash
grep -q 'P2 — `critique-figma-design` (self-check, not taste-maker) — ✅ SHIPPED' ROADMAP.md && echo P2_SHIPPED_OK
grep -q 'screenshot-pixel-sampling; conform-to-target' ROADMAP.md && echo STATUS_OK
```
Expected: `P2_SHIPPED_OK`, `STATUS_OK`.

- [ ] **Step 7: Commit**

```bash
git add CLAUDE.md ROADMAP.md
git commit -m "docs: document P2 critique-figma-design in CLAUDE.md and ROADMAP.md

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Self-Review

**1. Spec coverage** (spec decision → task):
- Command-only (1) → Task 2 frontmatter + Step 2 `COMMAND_ONLY_OK`; CLAUDE convention (Task 3.3). ✓
- Read-only (2) → Task 2 body + Step 3 `READ_ONLY_OK`/`NO_FIGMA_USE_OK`. ✓
- Five categories (3) → Task 1 catalog (four measured tables + Nielsen-10 table) + Task 2 workflow §3–4. ✓
- Taste guardrail + role-signal (4) → Task 1 "Measurement methods" + Task 2 intro/§3 + Step 3 `NO_SCORE_OK`. ✓
- Conform-to-target thresholds (5) → Task 1 tables ("project rule first, else…") + Task 2 §1/§3. ✓
- Report shape, severity, no score (6) → Task 2 §5 report template + Task 1 severities. ✓
- Clarify-until-clear (7) → Task 2 opener + Step 2 `CLARIFY_OK`. ✓
- Measurement methods: contrast sampling, role-evidence, modality, spacing-gating (8) → Task 1 "Measurement methods" + Task 2 §3. ✓
- Per-frame unit of work (9) → Task 2 §5. ✓
- Files (§5): SKILL.md (Task 2), check-catalog.md (Task 1), CLAUDE.md + ROADMAP.md (Task 3). No ADR (spec says none). ✓
- Out-of-scope items (no write, no score, no auto-trigger) → enforced by Tasks, not added. ✓

**2. Placeholder scan:** No "TBD"/"TODO"/"handle edge cases"/"similar to". Full file content inline in Tasks 1–2; edit anchors are exact strings in Task 3. ✓

**3. Type consistency:** Skill name `critique-figma-design` identical across frontmatter (Task 2), CLAUDE entry (Task 3.2), ROADMAP heading (Task 3.5). Reference path `references/check-catalog.md` identical in Task 1 (created), Task 2 (referenced), CLAUDE entry. Section anchors ("Measured checks", "Measurement methods", "Heuristic signals (Nielsen-10)") created in Task 1 and named in Task 1 Step 2 checks. Sibling routing names (`implement-figma-design`, `page-to-figma`, `biz-review`) spelled consistently. ✓

One note for the implementer: Task 3 Step 4's `grep -qc 'nine'` guard is a *safety net* — after the eight→nine work in the P1 branch, "nine" appears exactly in the two count sentences this task rewrites; if any "nine" survives, it is a stale count to fix. (The ROADMAP "seven skills" audit-baseline text is intentional and unrelated — do not touch it.)
