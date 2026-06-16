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
