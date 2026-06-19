---
name: page-to-figma
description: >-
  Transcribe a RUNNING product page into Figma as a 1:1, pixel-perfect frame
  (running page → Figma). Use this skill WHENEVER the user has a live page, URL, or
  running app and wants it recreated/mirrored in Figma exactly. Triggers: "put our
  settings page into Figma", "recreate this screen in Figma exactly", "mirror our live
  pricing page in Figma", "build our running app's page in Figma to match." This is the
  accuracy orchestrator: it supervises the official Figma plugin rather than trusting it.
  Do NOT use it to push a finished Figma design INTO code (that's implement-figma-design),
  or to design something brand-new in Figma with no source page.
---

# Page → Figma (pixel-perfect, by correction not by eye)

The goal is a **1:1, 100% pixel-perfect match** between the Figma frame you produce and
the **running rendered page** — fills, sizes, spacing, radii, typography, icons, and
imagery. "Close enough" is a failure. You prove the match with a **numeric property
read-back against the page's real computed styles**, never by eyeballing two screenshots.

This skill exists because the official Figma plugin's code→Figma transfer is **not
accurate enough**, and the usual fix (build, then visually compare and tweak) **does not
converge** — it oscillates or plays whack-a-mole and still ships slop. This skill is an
**accuracy orchestrator on top of the plugin**: it feeds the build real ground truth, then
holds that truth as a checklist and corrects the plugin's output until every property
matches. It is the **running-page → Figma** path; its mirror is `implement-figma-design`
(Figma → code).

## Hard dependency — stop if it's missing

This skill **supervises** the official Figma plugin; it does not reimplement its write
mechanics. It requires the official Figma plugin skills `figma-use` and
`figma-generate-design`, plus the Figma MCP tools (including `generate_figma_design`).
This is a deliberate hard dependency (see the repo's
`docs/adr/0001-page-to-figma-depends-on-official-figma-plugin.md`). **If the official
Figma plugin is not installed, stop and tell the user to install it** — do not silently
degrade or hand-roll a partial build.

## Before you proceed — ask until clear

While this skill is active, **never silently guess.** If a computed value is unreadable, an
asset is unreachable, an element's role is ambiguous, a responsive width is unobservable,
or an interaction/state the page implies isn't shown — **stop and ask, and keep asking
until it's clear.** Batch related questions. A wrong value that looks right silently
corrupts the frame.

## Source of truth

The **running rendered page** (live URL / dev server), driven via the project's browser
tooling (Playwright). Read **computed styles from the DOM** (`getComputedStyle`) as ground
truth — not source code, not values inferred from a screenshot. Capture a reference
screenshot for the **coarse backstop only**. If no running page is available, say so and
stop — do not fall back to guessing from source. If no browser/screenshot tooling exists,
do not eyeball — mark the result **unverified** or offer to set up Playwright.

## Workflow

**When a run spans multiple frames/states, prove the pipeline on ONE first.** Build one
representative frame, run the *full* verify on it (the numeric checklist **and** the
clipping / negative-space pass in step 4), and only then batch the rest. A systematic
extraction gap — a dropped clip, a mis-keyed asset — is identical across every frame;
catching it once is far cheaper than rebuilding a dozen frames (and re-stashing a shared
asset dictionary) after the user reviews them.

### Flow mode — reuse the proven base, don't rebuild N frames

A "flow" is a set of **near-duplicate states** of the same screen (a payment flow's 12
states share one layout; they differ by a small delta — a modal opens, an error banner
appears, a radio flips selected, a button disables). Rebuilding and re-verifying the whole
tree per state is the dominant cost of a flow run, and almost all of it is redundant. When
the run is a flow, switch the pipeline from *N independent builds* to **one proven base +
per-state deltas**:

1. **Extract every state up front, in one Playwright pass (step 1).** Drive the page through
   all states and capture each state's section→element tree of real numbers *before any
   Figma write*. Extraction touches only the page, so doing it all first is cheap and lets
   you compute the **inter-state delta** (which nodes changed, were added, or removed
   between states) while no Figma round-trip is in flight.
2. **Default a flow to raw mode (step 2).** Raw mode bypasses the plugin's inaccuracy at the
   source, so it needs the fewest correction iterations — and you pay that tax once on the
   base instead of N times.
3. **Build and fully verify ONE base state to green** (steps 3–4, full checklist + clipping
   pass). This is the representative frame from "prove on ONE first" — now it also becomes
   the thing every sibling reuses.
4. **For each remaining state, clone the verified base in Figma and apply only the delta.**
   One `use_figma` clone of the green base costs a single round-trip and inherits every
   already-correct value; then write *only* the nodes the inter-state delta flagged as
   changed/added/removed. Do **not** rebuild the shared layout — it is already proven.
5. **Delta-verify, not full-verify, the clones (step 4).** Run the numeric checklist on the
   **changed nodes only**, plus a cheap re-assert that the clone's shared invariants still
   hold (frame size, the clip rects of any scroll container the delta touched). A clone
   starts green by construction, so a full re-read of every property on every state is wasted
   work — reserve that for the base.

This collapses a flow from `N × (build + full-verify)` to `1 × (build + full-verify) +
(N−1) × (clone + delta-verify)`. The numeric-correctness guarantee is unchanged — every
shipped value still traces to a green checkpoint; deltas just stop re-proving what the base
already proved.

### 1. Extract truth from the running page

Open the page with Playwright. Walk the layout into a structured **section → element
tree**. For each node, record real numbers from `getComputedStyle`:

- Fills / strokes — exact hex (and per-state, e.g. hover).
- Box metrics — width, height, padding, margins, gaps.
- `border-radius`, borders, shadows.
- Typography — family, size, weight, line-height, letter-spacing.
- Box model — flex/grid direction, alignment, sizing (so you can rebuild as auto-layout).
- Icons / images — the asset and its rendered size/position.
- **Overflow / clipping** — record `overflow-x/y` for every node; treat `hidden | auto |
  scroll | clip` as a clip boundary (see the clip paragraph below).
- **Placeholder text** — capture input `placeholder` attributes. They are not DOM text
  nodes, so an empty field reads blank in Figma unless you capture the prompt explicitly.

**Record overflow and reproduce clipping — it's what the browser actually paints.**
`getBoundingClientRect()` returns full geometry regardless of overflow, so off-screen
content (a 1240px-wide table inside a 1120px scroll card) extracts as if visible and will
*bleed past* the container's rounded edge in Figma — every node placed and styled correctly,
the frame still wrong because content the page *hides* is *shown*. Maintain a **clip-rect
stack** as you walk the DOM: push the intersection of the current clip with an element's box
whenever its `overflow-x/y` clips, and **cull or clamp every emitted node to the active
clip** — exactly what the browser paints. **Positioned elements escape the stack:** on
entering a `position: fixed` element, **reset the clip to the viewport** (it's
viewport-relative and ignores overflow ancestors) before emitting it and its subtree;
`position: absolute` escapes clipping from *statically-positioned* ancestors too. Modals,
drawers, scrims, toasts, and dropdowns all hit this — a naive clip stack wrongly shrinks a
full-viewport `inset: 0` scrim down to its scroll-container ancestor.

Capture the reference screenshot. This tree of real numbers is the **only** thing you
trust for the rest of the run.

**For a flow, extract every state in this one pass** (see Flow mode) and record, per state,
its **delta from the base** — which nodes change value, appear, or disappear. Extraction is
page-only and cheap, so batching all states here keeps the Figma write phase uninterrupted
and gives you the delta you need to clone-and-patch instead of rebuild.

### 2. Detect the design system, then ask bind-vs-raw (per run)

Inspect the destination Figma file (`get_variable_defs`, `search_design_system`,
`get_libraries`). Then **ask the user**:

- **Bind mode** — bind product values to matching Figma variables/components. Needs
  `figma-generate-design` for component/variable discovery and reuse.
- **Raw mode** — emit exact values, no binding. You may **bypass `figma-generate-design`**
  and drive `figma-use` directly from the DOM tree; this avoids the plugin's inaccuracy at
  the source and is the most trustworthy path.

If no design system exists, default to **raw** and say so. **For a flow, prefer raw even
when a design system exists** — it minimizes the per-state correction iterations you'd
otherwise pay N times (see Flow mode). Choose bind mode for a flow only when the user needs
design-system binding and accepts that cost.

### 3. Build — delegate the bulk, own the values

**Load `figma-use` first** (mandatory before any `use_figma` call — it carries the
color-range, font-loading, and layout rules that make writes work).

- **Bind mode:** hand assembly to `figma-generate-design` and follow its workflow. **Do
  not re-describe or paraphrase its assembly steps here** — that duplication silently
  drifts out of sync. Just delegate.
- **Raw mode:** build auto-layout frames directly via `figma-use`, using the extracted
  numbers.
- **Images:** the `use_figma` Plugin API **cannot** fetch external image URLs. When the
  page has any image, run `figma-generate-design`'s **mandatory parallel
  `generate_figma_design` capture** of the running page to source `imageHash` values, then
  apply those hashes to your image fills. (The same capture doubles as a pixel-perfect
  visual reference.)
- Build and correct at **auto-layout altitude** — set layout direction, gap, padding, and
  sizing modes to match the DOM box model rather than stamping absolute x/y. Absolute
  coordinates ripple: a fix to one node breaks its siblings.
- **Carry clipping into the build.** For every source element that clips (step 1), set
  `clipsContent = true` on the frame you build from it — that reproduces the paint exactly,
  but only while the build preserves nesting (the auto-layout altitude above does). If a path
  collapses to a flat list of absolutely-positioned nodes, nesting is lost and `clipsContent`
  has nothing to attach to — fall back to the step-1 clip-stack cull/clamp instead.
- **Key any deduped assets by content hash, not usage order.** If you dedup icons/images into
  a shared dictionary, hash the content for the key. Usage-order keys reindex the *whole*
  dictionary the moment extraction culls one asset (e.g. the clip fix drops an off-screen
  icon), invalidating every already-built frame and forcing a full rebuild instead of a
  partial one.
- **Flow mode — clone the proven base, write only the delta.** For sibling states, duplicate
  the green base frame via `use_figma` and apply only the nodes the inter-state delta flagged
  (step 1); do not rebuild the shared layout. The clone inherits the base's correct values,
  clipping (`clipsContent`), and asset fills — which is exactly why the asset dictionary must
  be **content-hash keyed** (above): a clone has to resolve the same hashes the base did, and
  usage-order keys would reindex out from under it.
- **Auto-width text can drift a few px** when Figma's font metrics differ from the browser's
  (e.g. Noto Looped Thai advances wider than Chrome's). Harmless for left-aligned runs; it can
  nudge a centered label off-center. When exactness matters, set a **fixed width = measured DOM
  width** instead of auto-resize.

### 4. Verify by numeric read-back — and correct until green (the heart of this skill)

Do **not** gate on a screenshot diff. Browser and Figma rasterize differently
(anti-aliasing, font hinting, subpixel rounding), so a picture diff is never zero even when
the design is semantically perfect — a vision gate can't terminate. Instead:

1. **Read actual Figma values back** off the built nodes via `use_figma` — `fills`,
   `width`, `height`, padding, `itemSpacing`, `cornerRadius`, strokes, effects, and font
   properties.
2. **Assert numerically** against the DOM-extracted values on a **finite per-property
   checklist**, with explicit tolerances:
   - Colors: **exact hex**.
   - Geometry (w/h/padding/gap/radius): **±0.5px**.
   - Font family/weight: **exact**. Font size/line-height: **±0.5px**.
   Each property is a definite pass/fail — no subjective "close enough."
3. **Correct every failure** with a targeted `use_figma` write using the **exact extracted
   value** — stamp the truth on top of the plugin's output.
4. **Re-read the whole checklist** after each batch of corrections (not just the nodes you
   touched) to catch ripple. **Loop until the checklist is all-green.** That green state is
   the termination condition — stop there; do not keep visually polishing.
5. **Clipping / negative-space pass — verify what the page *hides*, not just what it shows.**
   The per-property checklist only inspects nodes that *exist*, so it stays green while
   *extra* content that should have been clipped away bleeds into view. For each scroll/clip
   container, assert no emitted node extends beyond its clip rect (or is clamped to it). Then
   add a **container-edge visual backstop**: `get_screenshot` the right/bottom edges of cards
   and scroll regions *specifically* — a bleed is invisible at full-frame thumbnail zoom but
   obvious at the card's corner. A green property checklist is necessary but **not
   sufficient**; also verify the hide.
6. **Screenshot diff is a coarse backstop only.** Once green, `get_screenshot` the node and
   visually confirm only what numbers can't catch: z-order, a missing/extra element, a
   blank image placeholder. Never treat it as the convergence criterion. Never report
   pixel-perfect without a green property checklist **and** a clean clipping pass.

**Batch the round-trips — the MCP call is the latency unit, not the diff.** Each `use_figma`
call is a round-trip to the plugin; doing one per node or per property is what makes a flow
crawl. Read **all** of a frame's node properties back in a *single* `use_figma` script that
returns one JSON blob, **diff in-agent** against the extracted truth, apply **all** of that
frame's corrections in a *single* write script, then re-read once. That is ~3 round-trips per
correction iteration instead of hundreds — identical checklist and tolerances, far less
wall-clock. On a cloned flow state, the batched read-back covers only the **delta nodes plus
shared invariants** (see Flow mode), not the whole tree.

## When to stop and ask

This section restates the clarify rule for the moments it bites hardest. **Stop and ask**
when you hit an unreadable computed value, an asset you can't reach, an interaction/state
the page implies but doesn't show, or a responsive reflow you can't observe. Ask — don't
improvise.

## Helpful resources

- **Official Figma plugin skills (hard dependency):** `figma-use` (mandatory before any
  `use_figma` write) and `figma-generate-design` (bulk assembly + design-system discovery).
- **Figma MCP tools** (only the ones this skill actually uses — it reads the *page* from
  the DOM, not the design from Figma): `get_variable_defs`, `search_design_system`,
  `get_libraries` (design-system detection, step 2); `get_screenshot` (the coarse backstop,
  step 4); `use_figma` and `generate_figma_design` (build). If a call returns "tool not
  found," the connected Figma MCP is outdated — tell the user to update Figma.
- **Browser tooling:** Playwright (or the project's equivalent) for DOM extraction and the
  backstop screenshot.
