---
name: page-to-figma
description: >-
  Transcribe a RUNNING product page into Figma as a 1:1, pixel-perfect frame
  (running page → Figma). Use this skill WHENEVER the user has a live page, URL, or
  running app and wants it recreated/mirrored in Figma exactly. Triggers: "put our
  settings page into Figma", "recreate this screen in Figma exactly", "mirror our live
  pricing page in Figma", "build our running app's page in Figma to match." This is the
  accuracy orchestrator: it drives the vendored figma-cli (local, no rate limit)
  to build and verify, falling back to the official Figma plugin only when the CLI is unavailable.
  Do NOT use it to push a finished Figma design INTO code (that's implement-figma-design),
  or to design something brand-new in Figma with no source page.
---

# Page → Figma (pixel-perfect, by correction not by eye)

The goal is a **1:1, 100% pixel-perfect match** between the Figma frame you produce and
the **running rendered page** — fills, sizes, spacing, radii, typography, icons, and
imagery. "Close enough" is a failure. You prove the match with a **numeric property
read-back against the page's real computed styles**, never by eyeballing two screenshots —
and that read-back is **position-first**: a node's absolute x/y is the assertion that most
encodes "matches the page." Matching sizes, padding, color, and type is necessary but **not
sufficient** — a perfectly-sized node in the wrong spot is still wrong.

**Pixel-perfect is half the job — the frame must also be a *usable design artifact*, not a
vector tracing.** The output is a **nested tree of auto-layout frames that mirrors the page's
box model** (containers with direction / gap / padding / sizing, leaf text and icons inside
them), with every layer named from its DOM source. A flat pile of absolutely-positioned
siblings that *looks* identical is still a **failure**: nothing reflows, nothing is nameable,
rows aren't duplicable, and the whole reason to put a page in Figma — to *work* with it —
is gone. Pixel-perfect **and** structured are both required; a frame that is one but not the
other does not pass. The two only genuinely conflict at font metrics — named and handled
below, not dodged by going flat.

This skill exists because the official Figma plugin's code→Figma transfer is **not
accurate enough**, and the usual fix (build, then visually compare and tweak) **does not
converge** — it oscillates or plays whack-a-mole and still ships slop. This skill is an
**accuracy orchestrator on top of the plugin**: it feeds the build real ground truth, then
holds that truth as a checklist and corrects the plugin's output until every property
matches. It is the **running-page → Figma** path; its mirror is `implement-figma-design`
(Figma → code).

## Engines — figma-cli primary, Figma MCP fallback

This skill drives Figma through the **vendored figma-cli** (it talks to Figma Desktop
locally over CDP — no API token, no rate limit, far cheaper in tokens), and supervises its
output for accuracy. Invoke it by absolute path; define this once at the start of a run:

    FIGMA_CLI="node ${PWD}/.claude/figma-cli/src/index.js"     # project install, if present
    # else: FIGMA_CLI="node ${HOME}/.claude/figma-cli/src/index.js"   # user install

Prefer the project copy (`./.claude/figma-cli/src/index.js`) when it exists, else the user
copy (`~/.claude/figma-cli/src/index.js`).

### Connection & consent — never patch Figma silently

1. Check `$FIGMA_CLI daemon status`. If connected, proceed.
2. If it is **down**, STOP and ask the user to connect — explain the two modes in plain
   terms: **Yolo** (`$FIGMA_CLI connect`) applies a small reversible patch to Figma Desktop
   for a hands-off connection; **Safe** (`$FIGMA_CLI connect --safe`) uses a plugin bridge
   and patches nothing. **Never auto-run `connect`** — patching the user's Figma is their
   decision, not a silent side-effect of this skill.
3. Confirm the **target file** before the first write: run `$FIGMA_CLI files` / `$FIGMA_CLI
   canvas info`. The CLI builds into whatever Figma Desktop file is focused (it has no
   per-node URL targeting). If more than one file is open or the active page is ambiguous,
   state the detected target and ask before building. With one unambiguous file, name it in
   your narration and proceed.

### When the CLI is unavailable — announce, then fall back

If the user cannot or will not connect the CLI (no Figma Desktop, restricted machine, no
Node), do **not** silently degrade. **Announce** that you are switching to the
**rate-limited Figma MCP path** (the verify loop may throttle) and how to enable the fast
path, then follow `references/mcp-fallback.md`. Stop entirely only when **neither** engine
is available — then tell the user what to install.

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
representative frame, run the *full* verify on it (the numeric checklist, the **structure
gate**, and the clipping / negative-space pass in step 4), and only then batch the rest. A
systematic extraction gap — a dropped clip, a mis-keyed asset, a subtree that flattened
instead of nesting — is identical across every frame; catching it once is far cheaper than
rebuilding a dozen frames (and re-stashing a shared asset dictionary) after the user reviews
them.

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
3. **Build and fully verify ONE base state to green** (steps 3–4, full checklist + structure
   gate + clipping pass). This is the representative frame from "prove on ONE first" — and
   because every sibling clones it, its **structure** is what they all inherit, so a flat base
   would make every state flat. Get the base nested and green once.
4. **For each remaining state, clone the verified base in Figma and apply only the delta.**
   One `$FIGMA_CLI duplicate` of the green base costs a single round-trip and inherits every
   already-correct value **and the base's nesting**; then write *only* the nodes the
   inter-state delta flagged as changed/added/removed, **patching against the tree** (replace
   a container's children; never re-stamp the subtree as flat siblings). Do **not** rebuild
   the shared layout — it is already proven.
5. **Delta-verify, not full-verify, the clones (step 4).** Run the numeric checklist on the
   **changed nodes only**, plus a cheap re-assert that the clone's shared invariants still
   hold (frame size, the clip rects of any scroll container the delta touched, and that the
   patched subtree is still nested — not flattened by the patch). A clone starts green and
   structured by construction, so a full re-read of every property on every state is wasted
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
- Box model — flex/grid direction, alignment, sizing **per container node** (this is what
  you rebuild each node as auto-layout — keep it, don't collapse the tree to a paint list).
- A **layer name** per node, derived from its class/role/tag (`.snav-item` → "NavItem",
  `.tbl tbody tr` → "Row") — captured here so the build can name layers for free.
- Icons / images — the asset and its rendered size/position.
- **Overflow / clipping** — record `overflow-x/y` for every node; treat `hidden | auto |
  scroll | clip` as a clip boundary (see the clip paragraph below).
- **Placeholder text** — capture input `placeholder` attributes (and any `value`). They are
  not DOM text nodes, so an empty field reads blank in Figma unless you capture the prompt
  explicitly — and the build must then *render* it (step 3), not just hold it.
- **Positioning** — record each node's `position`. Treat `absolute | fixed` as **out of
  flow**: capture its offset within the nearest positioned ancestor (for `fixed`, the
  viewport), and **exclude it from any geometry-based direction inference** for its parent.
  An out-of-flow child's x/y must never vote row-vs-column — an absolutely-positioned overlay
  icon whose `y` differs from a sibling input will wrongly flip the parent to a column and
  stack the icon *above* the field instead of *over* it.

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

Inspect the destination Figma file with the CLI: `$FIGMA_CLI variables list` (alias
`var list`), `$FIGMA_CLI collections list` (alias `col list`), and `$FIGMA_CLI spec
"<Component>"` to see a reusable component's authoritative spec + reuse handle. Then **ask the user**:

- **Bind mode** — bind product values to matching Figma variables/components. Bind product values to Figma variables via `render`'s `var:name` syntax (pin a named collection with `--collection`); drop existing components as real instances with `$FIGMA_CLI instantiate "<Component>"` instead of rebuilding them.
- **Raw mode** — emit exact values, no binding. Emit exact values via `render` / `render-batch` directly from the DOM tree; this avoids the plugin's inaccuracy at
  the source and is the most trustworthy path.

If no design system exists, default to **raw** and say so. **For a flow, prefer raw even
when a design system exists** — it minimizes the per-state correction iterations you'd
otherwise pay N times (see Flow mode). Choose bind mode for a flow only when the user needs
design-system binding and accepts that cost.

**Bind-vs-raw is orthogonal to structure.** It decides only whether values resolve to
Figma variables/components or to literals — **both modes build the same nested auto-layout
tree** (the build contract in step 3). Raw is *not* a license to flatten: driving `render` / `render-batch`
straight from the DOM tree means transpiling that tree's nesting, not stamping its nodes as
absolute siblings.

### 3. Build — delegate the bulk, own the values

**Build with `render` / `render-batch` — its JSX *is* nested auto-layout, so it matches the
build contract natively.** Never use `eval` to create nodes (the CLI's own hard rule) — `eval`
is read/mutate only.

- **Bind mode:** build with `$FIGMA_CLI render` / `render-batch` using `var:name` bindings
  (`--collection <name>` to pin the system); use `$FIGMA_CLI instantiate "<Component>"` to
  reuse an existing component rather than cloning it.
- **Raw mode:** build auto-layout frames directly with `$FIGMA_CLI render` / `render-batch`
  using the extracted numbers, no binding.
- **Images:** the CLI fetches external image URLs directly — use `$FIGMA_CLI create image
  "<url>"` or a `<Image>` node in JSX. (This removes the MCP path's `imageHash` workaround.)
  If a fetch fails for an auth'd/CORS'd asset, fall back to the MCP `generate_figma_design`
  capture for that one asset (see `references/mcp-fallback.md`).
- **Build the DOM tree, not a paint list — this is the build contract.** Transpile the
  extracted tree (step 1) node-for-node into nested auto-layout: each block/flex/grid
  **container** → an auto-layout frame carrying its captured direction / gap / padding /
  sizing modes; each **leaf with bg/border** → a frame with those fills/strokes; each **text
  run** → a text leaf (fixed-width per the font-metric note below); each **icon/svg** → a
  vector; each **`<input>`** → a text leaf rendering its captured `placeholder`/`value`
  (step 1) in the input's computed placeholder color/font (an input has no DOM text child, so
  without this the field ships blank — a captured-but-unrendered placeholder is a dropped
  value, not a handled one); each **out-of-flow node** (`position:absolute|fixed`) → a child
  with `layoutPositioning='ABSOLUTE'` at its captured offset within the nearest positioned
  ancestor, **never** a flow sibling (which mis-infers the parent's direction). Set direction,
  gap, padding, and sizing to match the box model rather than stamping
  absolute x/y. Absolute coordinates ripple — a fix to one node breaks its siblings — *and*
  produce exactly the flat tracing this skill exists to avoid. The data to do this is already
  in the extracted tree; only the build target is in question, so the auto-layout tree is the
  default and only ship target.
- **Translate alignment faithfully — it's where the container lands its content.** Map
  `justify-content` → `primaryAxisAlignItems` and `align-items` → `counterAxisAlignItems`;
  translate a `table-cell` `vertical-align:middle` → `counterAxisAlignItems='CENTER'`. **Don't
  silently drop alignment** when CSS resolves to `normal`/`stretch` — emit the explicit Figma
  equivalent. Lost cross-axis alignment is invisible to a sizes-only checklist (content sticks
  to the top/left of an over-tall/wide box, off by several px) until the position assertion
  (step 4) catches it — so build it right *and* verify it.
- **Name every layer from its DOM source** — use the name captured in step 1 (`.snav-item` →
  "NavItem", `.tbl tbody tr` → "Row", `.pm-method-name` → "MethodName"). A navigable layer
  panel is free and high-value; a pile of `Frame 217`s is not a deliverable.
- **Flat absolute is a per-subtree last resort, and it must be `log()`ged.** Drop to absolute
  placement *only* for a subtree you genuinely cannot express as auto-layout (e.g.
  `display:grid` with `subgrid`, or arbitrary overlap with no box-model parent). When you do,
  `log()` **which** subtree and **why** (e.g. "PaymentGrid: subgrid — flattened") so the lost
  structure is visible up front, not discovered as a 200-sibling pile at the end. Never
  flatten a whole frame because flat is easier to build or verify — that is the failure mode
  this skill guards against, not a sanctioned shortcut.
- **Carry clipping into the build.** For every source element that clips (step 1), set
  `clipsContent = true` on the frame you build from it — which the nested build makes trivial:
  the clip attaches to that container frame and reproduces the paint exactly. Only inside a
  `log()`ged flat-fallback subtree, where there is no container to attach to, fall back to the
  step-1 clip-stack cull/clamp instead.
- **Key any deduped assets by content hash, not usage order.** If you dedup icons/images into
  a shared dictionary, hash the content for the key. Usage-order keys reindex the *whole*
  dictionary the moment extraction culls one asset (e.g. the clip fix drops an off-screen
  icon), invalidating every already-built frame and forcing a full rebuild instead of a
  partial one.
- **Flow mode — clone the proven base, write only the delta.** For sibling states, duplicate
  the green base frame via `$FIGMA_CLI duplicate` and apply only the nodes the inter-state delta flagged
  (step 1); do not rebuild the shared layout. The clone inherits the base's correct values,
  **nesting**, clipping (`clipsContent`), and asset fills. **Patch the delta against the tree,
  not a flat index** — replace the children of the one container the state changed (e.g. swap
  the `Table` frame's `Row` children; leave the `Sidebar` and `Topbar` frames untouched),
  addressing nodes by their place in the structure. A structured base makes a state a
  localized subtree replacement; a flat base would force per-state re-stamping. This is also
  why the asset dictionary must be **content-hash keyed** (above): a clone has to resolve the
  same hashes the base did, and usage-order keys would reindex out from under it.
- **Font metrics are the one real conflict between structure and pixels — pin text width to
  resolve it.** Figma's text advance for many fonts is a few px wider than Chrome's (e.g. Geist,
  Geist Mono, Noto Looped Thai). In a flat build that's harmless (a left-anchored run just
  renders slightly wider in place) — which is the actual reason flat feels "safer." But in a
  nested build a **hug-content** text box that's a few px wide **pushes its siblings**, and the
  deviation **compounds down a row**. Do not retreat to flat over this. Default text leaves to a
  **FIXED width = the measured DOM rect width** (you already measured it in step 1), with the
  parent giving the leaf `FILL`/fixed rather than `HUG`. That keeps reflow at the container
  level while pinning the pixels — most of the editing benefit, none of the metric drift. Where
  a gap must be exact, prefer **fixed item-spacing** (and a fixed-size spacer frame if needed)
  over trusting `space-between` to resolve identically.

### 4. Verify by numeric read-back — and correct until green (the heart of this skill)

Do **not** gate on a screenshot diff. Browser and Figma rasterize differently
(anti-aliasing, font hinting, subpixel rounding), so a picture diff is never zero even when
the design is semantically perfect — a vision gate can't terminate. Instead:

1. **Read actual Figma values back** with **one** `$FIGMA_CLI eval` script returning a single JSON blob (fills, width, height, padding, itemSpacing, cornerRadius, strokes, effects, font properties, **`absoluteBoundingBox`**, **`layoutMode` / `primaryAxisAlignItems` / `counterAxisAlignItems` / `layoutPositioning`**, **plus each node's parent id and direct-child count**). `$FIGMA_CLI verify "<id>" --measure` is a fast sizing cross-check; `$FIGMA_CLI spec "<Comp>" --check "<id>"` enforces component fidelity (exit-nonzero on mismatch).
2. **Assert numerically** against the DOM-extracted values on a **finite per-property
   checklist**, with explicit tolerances:
   - **Absolute position — x/y relative to the frame root, ±1px. This is the PRIMARY
     assertion.** The DOM rect (viewport-absolute, frame pinned at 0,0) maps directly to
     frame-relative position — a free, exact ground truth; read it as `node.absoluteBoundingBox`
     minus the root's. Auto-layout can place a perfectly-sized node in the wrong spot when an
     ancestor's offset wasn't reproduced (a row whose every cell width is exact but that starts
     29px too far left because the scroll column collapsed its children to its edge). Matching
     sizes/padding/gap is necessary but **not** sufficient — position is what "matches the page"
     means. **The frame is not green until every node's x/y matches.**
   - **Alignment — exact:** `layoutMode`, `primaryAxisAlignItems`, `counterAxisAlignItems`,
     `layoutPositioning`, against the CSS the node was built from — so a dropped vertical-center
     or a flow node that should be `ABSOLUTE` can't pass unnoticed.
   - Colors: **exact hex**.
   - Geometry (w/h/padding/gap/radius): **±0.5px**.
   - Font family/weight: **exact**. Font size/line-height: **±0.5px**.
   Each property is a definite pass/fail — no subjective "close enough."
3. **Correct every failure** with a targeted write inside **one batched `$FIGMA_CLI eval` script** that mutates the wrong nodes (mutate-existing only — not node creation, and not one `set` per fix, which would be a round-trip per correction) using the **exact extracted value** — stamp the truth on top of the plugin's output. **A position failure is fixed at the cause, not the symptom:** don't nudge the drifting node — correct the responsible ancestor (its padding / alignment / gap, or a per-child margin or centering it dropped), or for a genuinely out-of-flow node pin it with `layoutPositioning='ABSOLUTE'` at the DOM coordinate. Absolute drift almost always traces to one container collapsing its children to its edge, so fixing that ancestor re-seats the whole subtree in a single write.
4. **Re-read the whole checklist** after each batch of corrections (not just the nodes you
   touched) to catch ripple. **Loop until the checklist is all-green.** Green pixels are
   necessary but **not** the whole termination condition — the structure gate (next) must
   also pass before the frame is done. Don't keep visually polishing past green.
5. **Structure gate — assert the frame is a tree, not a pile.** The per-property checklist
   has *no notion of structure*: a flat frame of absolutely-positioned siblings passes every
   color/geometry/font assertion above while being structurally useless, so the numeric
   checklist exerts **zero** pressure toward nesting. Without this gate the build optimizes
   hard for the thing it measures (pixels) and not at all for the thing it doesn't (layers).
   Add — and require — a cheap structural read-back alongside the numeric one:
   - **Direct-child sanity:** each built frame's direct-child count tracks its DOM container's
     child count (a handful), not the whole node total. A frame with dozens-to-hundreds of
     direct children is flat by definition — **fail**.
   - **Ancestry:** every text/icon leaf has a non-frame-root auto-layout ancestor — it lives
     inside a real container, not pinned to the page root.
   - **Fallback accounting:** the only flat regions are subtrees you `log()`ged as deliberate
     fallbacks (step 3). An *unlogged* flat region is a regression — rebuild it nested, don't
     sign it off. What isn't measured won't get built; this gate is that measurement.
6. **Clipping / negative-space pass — verify what the page *hides*, not just what it shows.**
   The per-property checklist only inspects nodes that *exist*, so it stays green while
   *extra* content that should have been clipped away bleeds into view. For each scroll/clip
   container, assert no emitted node extends beyond its clip rect (or is clamped to it). Then
   add a **container-edge visual backstop**: `$FIGMA_CLI verify "<id>" --save <png>` (then Read the PNG to inspect the card/scroll edges) the right/bottom edges of cards
   and scroll regions *specifically* — a bleed is invisible at full-frame thumbnail zoom but
   obvious at the card's corner. A green property checklist is necessary but **not
   sufficient**; also verify the hide.
7. **Screenshot diff is a coarse backstop only.** Once green, `$FIGMA_CLI verify "<id>" --save <png>` (then Read it) and visually confirm only what numbers can't catch: z-order, a missing/extra element, a
   blank image placeholder. A full-frame thumbnail at ~0.5 scale is **far too coarse to show a
   small layout shift or a blank field** — a 29px row shift and an empty search box both vanish
   at that zoom. That is exactly why position/alignment must be caught numerically (steps
   4.2–4.3), not here. As a cheap **secondary** aid you may save **per-region edge shots** (a
   column's left edge, a row's baseline) the same way the clipping pass does — but the numeric
   position assertion is the real guard. Never treat the screenshot as the convergence
   criterion. Never report pixel-perfect without a green property checklist (**position and
   alignment included**), a **passing structure gate**, and a clean clipping pass.

**Batch the round-trips — each CLI call is the latency unit.** Read **all** of a frame's
node properties back in a *single* `$FIGMA_CLI eval` script that returns one JSON blob,
**diff in-agent** against the extracted truth, apply **all** of that frame's corrections in a
*single* `$FIGMA_CLI eval` write script (mutate-existing), then re-read once — ~3 calls per
iteration, not hundreds. Have the read-back also return each node's `absoluteBoundingBox`,
alignment props, parent id, and direct-child count so the position/alignment assertions
(step 4.2) and the structure gate (step 5) both run in-agent off the one blob. On a cloned
flow state, the read-back covers only the delta nodes plus shared invariants.

## When to stop and ask

This section restates the clarify rule for the moments it bites hardest. **Stop and ask**
when you hit an unreadable computed value, an asset you can't reach, an interaction/state
the page implies but doesn't show, or a responsive reflow you can't observe. Ask — don't
improvise.

## Helpful resources

- **Vendored figma-cli (primary engine):** `node ~/.claude/figma-cli/src/index.js` (or the
  project copy under `./.claude/figma-cli/`). Key verbs: `daemon status`, `connect` /
  `connect --safe` (user-run only), `files`, `canvas info`, `variables list`,
  `collections list`, `spec`, `instantiate`, `render` / `render-batch`, `create image`,
  `duplicate`, `eval` (bulk read / mutate-existing — never to create), `verify --measure` /
  `verify --save`. Full reference: the vendored `REFERENCE.md` is not shipped; rely on these.
- **MCP fallback:** `references/mcp-fallback.md` — used only when the CLI is unavailable
  and the user has been told (announce the rate-limited path).
- **Browser tooling:** Playwright (or the project's equivalent) for DOM extraction and the
  backstop screenshot — unchanged; the page is always read from the live DOM, never Figma.
