---
name: implement-figma-design
description: >-
  Implement an existing Figma design into this codebase as a 1:1, pixel-perfect match
  (design → code). Use this skill WHENEVER the user shares a figma.com link or Figma
  node and wants it built, implemented, recreated, or "made to match" in the app — even
  if they never say the words "pixel perfect." Triggers: "implement this Figma on the
  settings page", "build this Figma screen", "make ours match the Figma", "recreate this
  frame in our app", "here's the Figma for the payment screen <link>". This is the
  web/React path. Do NOT use it to push existing code INTO Figma, or to build a
  Flutter / mobile UI (that's implement-figma-design-mobile).
---

# Implement Figma Design (pixel-perfect)

The goal is a **1:1, 100% pixel-perfect match** between what you build and the Figma
source — color hex, width, height, spacing, border-radius, typography, icons, and
imagery all included. "Close enough" is a failure here. The user is treating the Figma
file as the canonical spec, so your job is to transcribe it faithfully and then *prove*
the match by comparing against a screenshot, not by eyeballing your own code.

This skill depends only on the **Figma plugin (MCP)** for ground truth — no other skills
or services are required. It is the **Figma-design → code** path. Its siblings are
`figjam-to-use-case-narrative` (FigJam flow → narrative doc) and
`use-case-narrative-to-prototype` (narrative doc → code prototype); reach for those when
you have a flow diagram or a written narrative instead of a finished design. If you have
**both** a finished Figma design **and** a flow/UCN for the same screens and want one
artifact that is pixel-perfect *and* walkable, defer to `figma-design-to-working-prototype`
(the fusion orchestrator) — it builds the walkable skeleton first, then calls this skill to
re-skin it. Use this skill directly when there is a design but **no** flow.

## Before you proceed — ask until clear

While this skill is active, **never silently guess.** If at any point you do not fully
understand a detail — an element whose purpose is unclear, an asset you can't access, a
token that doesn't resolve, an interaction or state the frame implies but doesn't show, a
breakpoint that isn't specified, or which page/route the design belongs to — **stop and
ask the user, and keep asking until everything is clear.** Batch related questions
together, but do not proceed past an unresolved ambiguity. A wrong guess that looks
pixel-perfect is worse than a question, because it silently corrupts the spec.

## When this applies

The user gives you a Figma link or node and wants UI produced from it. Examples:

- "Implement this design from Figma: <figma-link> on the settings page."
- "Build the sidebar from this Figma: <figma-link>."
- "Here's the Figma for the payment screen — make ours look exactly like it."

If there's no Figma source, this skill doesn't apply — you're designing from scratch,
not transcribing.

## Workflow

Follow these steps in order. The first half is *extract the truth from Figma*; the
second half is *build, then verify against that truth*.

### 1. Pull the design context from Figma (don't guess)

Parse the Figma URL into `fileKey` and `nodeId` (in `figma.com/design/:fileKey/...?node-id=:nodeId`,
convert the `-` in the node id to `:`). Then use the Figma MCP read tools to get ground
truth rather than inferring from the rendered image:

- `get_design_context` — layout, hierarchy, and the code representation of the frame.
- `get_screenshot` — the reference image you'll diff your build against. Keep this.
- `get_metadata` — exact positions and sizes when you need to resolve ambiguity.
- `get_variable_defs` — design tokens (colors, spacing, radii, type) the design uses.

Capture the real numbers: hex values, px dimensions, gaps, radii, font family / size /
weight / line-height, and which design tokens map to which element. If a value is
ambiguous between two tools, trust `get_metadata` for geometry and `get_variable_defs`
for tokens — and if it's still unclear, ask the user rather than averaging a guess.

### 2. Map Figma tokens to this project's system

Read the design's tokens with `get_variable_defs`, then map them onto **whatever
design-token system the target project already uses** (CSS variables, a theme file, a
utility-framework config, Sass variables, a tokens JSON — whatever is there). Before hardcoding a
raw hex or px value, check whether an existing project token already represents it, and
prefer that token so the build stays consistent with the rest of the app. Only fall back
to a raw value when no token matches — and flag that gap to the user.

If the project has its own accessibility or ergonomics conventions (minimum touch-target
sizes, minimum body font, contrast rules), honor them while matching the design. If the
Figma appears to violate a convention the project enforces, surface it rather than
silently shipping a control that breaks the rule.

### 3. Build it

Implement with the target project's existing stack and conventions — match the framework,
file structure, component patterns, and styling approach already in the repo rather than
introducing new ones. Reuse existing components where the design calls for something the
codebase already has; don't reinvent a button that already exists.

**No codebase yet?** A pure designer often has no target repo — that is expected, not a
blocker. Do not hunt for a stack to conform to. Instead, scaffold a fresh standalone app to
host the build:

- Default to **React**, and **confirm that default with the user** before scaffolding (offer
  their stack if they have a preference).
- Scaffold the minimum that renders and runs — a single app with a dev server the user can
  open, using the framework's standard starter rather than hand-rolling configuration.
- Because this skill verifies by **screenshot diff** (step 4), also set up the
  browser/screenshot tooling (e.g. Playwright) as part of the scaffold, so the match can
  actually be proven rather than eyeballed.
- Keep it self-contained so it can be zipped or handed off.

Once a host exists (detected or scaffolded), build within it as below.

If the design includes responsive breakpoints, implement every breakpoint to match — a
match at one width that breaks at another is not a match. If the design only shows one
width and you're unsure how it should reflow, ask.

### 4. Verify the match — this is the part people skip

Render your build and compare it side-by-side against the `get_screenshot` reference
from step 1. Screenshot your running UI with whatever browser/screenshot tooling the
project already has available, then diff it against the Figma image.

**If the project has no browser/screenshot tooling, do not eyeball your own code and
call it a match.** That silently breaks the one promise this skill makes. Instead, say so
and offer to set up a headless browser (e.g. Playwright) to capture the screenshot, or
stop and tell the user the build is **unverified**. Never report a 1:1 / pixel-perfect
match you did not actually compare against a rendered screenshot.

When you can capture the screenshot, walk through each property deliberately:

- Colors — exact hex / token, including hovers and states.
- Dimensions — width, height, padding, margins, gaps.
- Border-radius, borders, shadows.
- Typography — family, size, weight, line-height, letter-spacing.
- Icons and images — correct asset, size, and position.

If anything is off, fix it and re-verify. Iterate until it's a 100% match. Don't declare
done after one pass — confirm with an actual comparison and report what you checked.

## When to stop and ask

This restates the clarify-until-clear rule for the moments it bites hardest. If the
design contains an element you don't understand, or one that looks like it would break
functionality (an interaction the design can't support, a component that conflicts with
an existing flow, an asset you can't access), **ask the user** instead of improvising —
and keep asking until the answer is unambiguous.

## Helpful resources

- **MCP:** the Figma plugin read tools are the only dependency — `get_design_context`,
  `get_screenshot`, `get_metadata`, `get_variable_defs`. These are the current, unified
  tool names. If a call returns "tool not found," the connected Figma MCP is outdated and
  may expose the legacy names `get_code` (≈ `get_design_context`) / `get_image`
  (≈ `get_screenshot`) instead — tell the user to update Figma, or fall back to the legacy
  names for this run.
