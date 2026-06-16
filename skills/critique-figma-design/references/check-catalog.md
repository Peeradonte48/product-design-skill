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
