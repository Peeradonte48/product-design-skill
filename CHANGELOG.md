# Changelog

All notable changes to the product-design-skill suite are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the suite is versioned by the repo-root [`VERSION`](VERSION) file (see
[CLAUDE.md → Distribution & versioning](CLAUDE.md)).

## [1.16.0] - 2026-06-22

### Added
- **`page-to-figma` connect-only fast path — connect frames that already exist in Figma** (a
  section/page the user points at) without capturing anything (`§0b`). When the screens are already
  in the file, the run **skips the entire capture apparatus** — Playwright, the
  `browser_run_code_unsafe` permission grant, `generate_figma_design`, auth (`§6`), and crawl
  (`§7`) — collapsing to ~2–4 `use_figma` calls: confirm the flow graph → read all frame coords in
  one call → batch-draw connectors → verify once. The skill description + Inputs now trigger on
  "connect these Figma frames/this section as a wireflow."

### Changed
- **Magnetic connectors are now the primary *attempt* behind a mandatory verify-and-fallback gate**
  (`§4`), not an unconditional primary. A production run proved that in some `/design/` files via
  the `use_figma` plugin bridge, **re-pointing `connectorStart` is inert** — `connectorEnd` re-binds
  live but the *start* vertex freezes at the donor's original location (reproduced across two
  donors, node-magnet/free-position/position-offset forms, atomic `set`, clear-then-rebind,
  line-type toggle, clone *and* original, page-level *and* section-nested, surviving a real frame
  nudge), and the property read-back **falsely reads correct**. CONNECTOR nodes expose no
  `vectorNetwork` to fix geometry by hand. The skill now **smoke-tests ONE edge, verifies the start
  landed by *geometry* (not endpoint-id), and auto-falls-back to VECTOR for all edges** if it's
  frozen. The completion gate rejects a frozen-start connector.
- **`§4` now sets connector stroke caps explicitly for arrow direction.** A donor's arrowhead can
  live on its *start* cap (`connectorStartStrokeCap`), which silently points every cloned arrow
  **backward** even when endpoints are perfect. The recipe now sets `connectorStartStrokeCap = "NONE"`
  + `connectorEndStrokeCap = <arrow>` per edge, and the verify gate + completion gate check direction
  (caught live: a re-pasted donor connected correctly via magnetic, but pointed backward until the
  caps were set). This also confirmed magnetic **does** work end-to-end via `use_figma` when the
  donor's start re-points — the verify-and-fallback gate is what tells the two environments apart.
- **`§4b` VECTOR fallback gained a proven `use_figma` recipe** (preferred over the `$FIGMA_CLI`
  form): node-level `strokeCap = "ARROW_LINES"` **does** render arrowheads on straight *and*
  multi-segment elbow paths (confirmed via `vectorNetwork` last-vertex read-back), plus a
  **white-chip label** pattern (readable over dark canvas/frames) and straight-vs-drop edge geometry.

### Notes
- **Sections renumber and drop loose children.** A `SECTION`'s node id can change and it can drop
  loosely-parented connectors when the user cut/pastes or re-sections it mid-run; contained frames
  travel safely. The skill now references frames by **stable frame ids** and re-resolves the section
  id before the final verify (`§0b` gotcha).

## [1.15.0] - 2026-06-22

### Changed
- **`page-to-figma` arrows are now magnetic FigJam connectors (cloned donor); `use_figma` is the
  primary node-op engine.** Documented from a production wireflow run (ADR 0008, supersedes ADR
  0007's static-VECTOR + figma-cli-engine decisions).
  - **Magnetic connectors (primary).** `createConnector` throws in a `/design/` file, but a
    connector **pasted from FigJam survives as a real `CONNECTOR` node** — so the skill clones a
    one-time human-pasted **donor** and re-points its endpoints per edge (`§4`). Result: arrows that
    snap to frames, **auto-reroute** when screens move, fan cleanly via inherited `ELBOWED` routing,
    and carry their label on the line. The donor's style propagates to every clone. This also
    **eliminates the fragile `strokeCap` arrowhead** failure class on the primary path.
  - **Static VECTOR arrows demoted to a fallback** (`§4b`) for when the user declines the one-time
    donor paste. The skill offers the donor setup up front and walks a non-technical user through it
    (new `§0` prerequisite).
  - **`use_figma` (Figma MCP Plugin API) is now the primary engine** for container/reparent/arrange/
    connector ops — the same bridge already required for capture. The vendored **figma-cli `eval`**
    is a documented **fallback** only (its local CDP bridge can fail outright — e.g. error -600).
  - **Routing tidy:** size the branch corridor by fan-out (wide fans need a taller drop gap, ~580px
    for ~6 branches); because connectors are magnetic, de-crowding is just moving frames.
  - Capture **frame size now tracks the capture viewport** (e.g. 1440×900), not a hardcoded ~1600px,
    in the confirm-by-new-frame heuristic and the incremental layout precompute.

## [1.14.1] - 2026-06-22

### Fixed
- **`page-to-figma` — eliminate the silent capture hang.** A live run reported the capture step
  running for minutes with **no output and no error**. Root cause class: unbounded in-page waits.
  The 1.13.x "hold the page open until the upload is confirmed" guidance could be implemented as an
  **`await` of `captureForDesign` (or an in-page sleep/poll) inside `browser_run_code_unsafe`** —
  but that promise resolves *before* the cloud upload finishes and in some environments never
  settles, so the tool call blocks forever with nothing to show. Fixes:
  - **Don't `await` the capture in the page** (`§1` step 3): fire it and return immediately; confirm
    completion out-of-band by polling for the frame. On the MCP path the browser stays open on its
    own — no in-page "hold" at all (`§1` step 4). The bounded `waitForTimeout` guard is now scoped to
    the Bash node-driver path only.
  - **Never wait silently** (`§0`): every navigation / capture / poll gets a max budget and emits a
    heartbeat; a multi-minute step with no output is treated as a bug, not slowness. Explicit
    timeouts on `browser_navigate` / `browser_run_code_unsafe`; never wait on `networkidle`.
  - **New `§9` "If a capture hangs — localize, don't wait"** — a cheap, bounded probe ladder
    (browser-alive → navigation → console for CSP/CORS → fire-without-await → frame-landed) so the
    agent reports *where* it's stuck instead of sitting in the wait.

## [1.14.0] - 2026-06-22

### Changed
- **`page-to-figma` now builds the wireflow incrementally — capture → place → connect, one screen
  at a time** (new `§8`; replaces the old bulk-capture-then-arrange-then-arrow ordering as the
  default). It walks the confirmed flow graph and, for each screen, captures it, places it in its
  precomputed lane slot, and draws the labeled arrow to any already-placed neighbor before moving
  on. Benefits: a run that dies partway leaves a **connected partial flow** instead of a pile of
  loose captures, and each link is verifiable as it's drawn.
  - This is possible because, on the **Playwright MCP path**, the browser session lives in the MCP
    server and survives shell commands — so captures and arrow `eval`s can interleave, and each
    capture can be confirmed *immediately* (not only after a batch driver exits).
  - The old **bulk/one-process** flow is retained strictly as the **no-MCP Bash node-driver
    fallback**, where a stray shell command would kill the capture driver mid-run. `§0` and `§1`
    now scope the "one long-lived process" / "confirm after exit" rules to that path only.

## [1.13.3] - 2026-06-22

### Fixed
- **`page-to-figma` — corrected the permission-grant guidance against the official docs.** The
  1.13.2 walkthrough implied a session restart and overstated the block. Verified against Claude
  Code's permission docs and corrected `§0`:
  - **`permissions` hot-reload — no restart needed.** Adding the allow rule takes effect
    immediately; dropped the "restart the session" step.
  - **`acceptEdits`/auto modes don't help** and the script no longer implies they might: `.claude/`
    is a **protected path** (an agent edit to `settings.local.json` still prompts the user, and
    stricter setups deny the self-grant outright), and `acceptEdits` only auto-approves file edits +
    a few filesystem Bash commands — **never an MCP tool call**.
  - **Added the easiest path for non-experts:** approve the permission prompt with **"Yes, and
    don't ask again"** when it appears — no file editing at all.
  - **Added the shortcuts:** `mcp__playwright__*` wildcard (all Playwright tools) and the user-level
    `~/.claude/settings.json` location as alternatives to the per-project file.

## [1.13.2] - 2026-06-22

### Fixed
- **`page-to-figma` — front-load the in-page code-execution permission (second live-run blocker).**
  The second live run got further (one screen captured + **serializer fidelity confirmed for Thai
  fonts + Tailwind v4**) but then hard-blocked: capture must inject Figma's `capture.js` and run it
  in the live page, which needs an arbitrary-JS-in-page tool (e.g. the Playwright MCP's
  `browser_run_code_unsafe`). That tool is **denied by default and the agent cannot self-grant it**
  (a classifier blocks even the self-grant attempt). The skill now documents this as a first-class,
  checked prerequisite (`§0`, plus `SKILL.md` engines + pipeline step 1): the user must allow the
  tool in the **target project's** `.claude/settings.local.json` `permissions.allow` array *before*
  capturing — not partway through a run. Notes the Bash node-driver path (`§1b`) runs the same
  in-page JS and is gated too (not a dodge), and frames the grant as a conscious, scoped trust
  decision (Figma's first-party capture script, the user's own app, Figma's own cloud).
- **`page-to-figma` — guide non-technical users through the permission grant.** `§0` now ships a
  ready-to-relay, plain-language script the agent reads to the user when the tool is blocked:
  why it's needed, which file to open (with the create-it-if-missing case), the exact JSON to add,
  save-and-restart, then "continue." The skill instructs the agent to **walk the user through it
  and wait**, not just print a tool name — and is honest that the agent itself can't add the rule
  (a live run showed the guard blocks the self-grant), so the human grants and the agent guides.

## [1.13.1] - 2026-06-22

### Fixed
- **`page-to-figma` — hardened against the failure modes from the first live run.** The
  capture+wireflow pipeline shipped in 1.13.0 was never run end-to-end; the first real run (an
  SPA with no routing, no Playwright MCP, headless sandbox) surfaced several gaps now closed in
  `SKILL.md` and `references/wireflow-build.md`:
  - **Hold the page open until the upload is confirmed received** (new `§1` step 4). The capture
    promise resolves *before* the screenshot finishes uploading to Figma's cloud — closing the
    page/context early silently drops the capture (it sits at `pending` forever). This was the
    single biggest time sink in the live run.
  - **`pending` ≠ received** (`§1` step 5). A never-submitted and a still-uploading capture both
    report `pending`; the reliable signal is a **new ~1600px frame appearing**, audited *after* the
    driver exits. Status polling alone can't distinguish a cut-off upload from a slow one.
  - **No-routing SPA recipe** (new `§1b`) with a ready headless driver template. Apps with no
    deep-linkable routes **must** drive state with Playwright then inject+fire the capture — on
    `localhost` too; the `#figmacapture=` hash only loads a fresh page at the default state.
  - **Playwright is now a checked, fail-closed dependency** (new `§0`; `SKILL.md` engines +
    pipeline step 1). Prefer the Playwright MCP; if absent, stop and tell the user to install
    `@playwright/mcp` rather than hand-locating a cached Chromium binary.
  - **Reparent is now the primary container strategy** (`§2`). Passing the container `nodeId` to
    `generate_figma_design` is unreliable — captures often land loose on an unrelated page — so
    expect to scan for new frames wherever they landed and `appendChild` them.
  - **Documented the real capture mechanism** (inject `capture.js`, call `captureForDesign` in the
    live page) and the sandbox realities that dominated the run: one long-lived process (a new
    shell kills background jobs), `headless: true` (headed hangs with no display),
    `domcontentloaded` + `waitForSelector` (Vite/HMR never goes `networkidle`), and no `| head`
    (buffering swallows stdout).
  - **Smoke-test one screen first** — verify serializer fidelity (non-Latin scripts e.g. Thai,
    CSS frameworks e.g. Tailwind v4) on a single screen before scaling to the whole flow.

## [1.13.0] - 2026-06-21

### Changed
- **`page-to-figma` is now a capture + wireflow skill — the page-reconstruction engine is gone.**
  Instead of extracting computed styles and rebuilding a nested auto-layout tree (which kept
  mismatching — position drift, passes-checks-but-looks-wrong, missing content), it now captures
  each screen with Figma's **native** `generate_figma_design` (agent-invocable, headless,
  pixel-accurate), arranges the captured frames (lanes + branch drop-rows), and connects them with
  labeled arrows into a **wireflow**. Flow connections come from three optional, combinable
  sources — an explicit list, a FigJam/UCN, or a **bounded crawl** that proposes a graph for the
  user to confirm. Auth defaults to interactive user login + session reuse (the agent never
  handles the password, never evades blocks, never persists secrets).

### Removed
- The reconstruction machinery: the computed-style walk, nested-auto-layout build contract,
  numeric read-back verify + correct-until-green loop, structure/clipping/extraction-completeness
  gates, and the `references/css-figma-map.md` and `references/mcp-fallback.md` files.

### Dependencies
- **Figma MCP capture (`generate_figma_design`) is now a hard, fail-closed dependency** (was a
  fallback). With reconstruction gone there is no degraded mode — the skill stops if it is
  unavailable. The vendored figma-cli survives only as an `eval` helper for arrange + arrows.

See `docs/adr/0007-page-to-figma-capture-wireflow.md` (supersedes ADR 0006, updates ADR 0001).

## [1.12.0] - 2026-06-21

### Changed
- **`page-to-figma` now auto-connects the figma-cli** instead of stopping to make the user
  run `connect` by hand. On a down daemon the skill announces one line ("Connecting
  figma-cli to Figma Desktop — small, reversible one-time patch") and then runs
  `$FIGMA_CLI connect` (Yolo mode) itself — no blocking prompt. The patch is reversible and
  persists, so the cost is paid at most once per machine; later runs find the daemon already
  connected. If `connect` fails (e.g. macOS Full Disk Access not granted, or no Figma
  Desktop open) the skill **stops and surfaces the fix**, then offers the Safe-mode
  (`connect --safe`, plugin-launched-by-user) or Figma-MCP fallbacks — it never silently
  degrades and never loops on a failing connect. This replaces the prior
  "never auto-run `connect`" consent gate, per user feedback that the manual step was
  friction. (`references/mcp-fallback.md` and the Helpful-resources verb list updated to match.)

## [1.11.1] - 2026-06-21

### Fixed
- **`/update-design-skills` no longer fails with "the piped run hit error."** The command's
  embedded `! curl … | bash -s -- --update` is a pipeline, and Claude Code evaluates **every**
  segment of a piped bang command against `allowed-tools` independently. The frontmatter only
  listed `Bash(curl:*)`, so the `bash -s -- --update` segment was unauthorized; because bang
  commands run non-interactively (no tty), the unmet permission surfaced as an error instead of a
  prompt, and the update never ran. Added `Bash(bash:*)` to `allowed-tools` so the whole pipeline
  is authorized. `install.sh` itself was unchanged — it exits 0 in install/update/re-update runs.

## [1.11.0] - 2026-06-21

### Added
- **`page-to-figma` Breakpoint mode** — responsive capture is now first-class, a sibling to
  Flow mode. The same page at multiple viewport widths is treated as distinct designs (layout
  *reflows*, it doesn't delta): set the Playwright viewport per breakpoint, **re-extract truth
  at each width**, and build + full-verify one frame per breakpoint (no clone-and-delta across a
  reflow — it would fight the structure gate). The content-hash asset dictionary is shared across
  widths. Flow × Breakpoint compose: breakpoints are the outer axis (full build per width),
  flow states the inner axis (delta within a width). Container-query caveat noted.
- **`references/css-figma-map.md`** — a CSS→Figma fidelity map so the skill no longer silently
  drops rich CSS. Covers gradients (linear/radial/conic), `filter`/`backdrop-filter` blur and
  glassmorphism, `mix-blend-mode`, `object-fit`→`scaleMode`, `transform` (rotation maps; skew/3D
  log+rasterize), `text-transform`→`textCase`, `text-decoration`, ellipsis/line-clamp, **mixed
  inline runs** (one Text node with styled ranges), per-side/dashed borders, and multi/inset
  shadows. Each row says where it's set (**JSX-direct** vs **eval-mutate** vs **log()+rasterize**)
  and its **verify read-back**, so every built property is also asserted. Includes a
  **color-normalization** step (1×1-canvas read-back) that converts `oklch`/P3/`color-mix`
  (Tailwind v4 defaults) to sRGB before asserting.
- The map is wired into the pipeline: step 1 captures the rich properties + normalizes color,
  step 3 builds via the map, and step 4's checklist gains a **rich-properties assertion**.

## [1.10.0] - 2026-06-21

### Added
- `page-to-figma` now **walks the whole page**, closing the "silent-green-but-incomplete"
  class where the build was blind to content the DOM walk never produced:
  - **Shadow DOM piercing** — the walk recurses into every element's `shadowRoot` (web-component
    / design-system subtrees no longer vanish).
  - **Pseudo-element capture** — `::before` / `::after` are read via
    `getComputedStyle(el, '::before')` and emitted as real leaves (icon-font glyphs, badges,
    custom checkbox ticks, gradient overlays, dividers).
  - **Rasterize-the-unwalkable** — `<canvas>`, WebGL, `<video>`, and cross-origin `<iframe>`
    are flagged at extraction and built as a **`log()`ged image fill** (element screenshot of
    the node's rect), never an empty frame.
- **Extraction-completeness gate** — a new verify gate (step 4, peer of the structure and
  clipping gates): a **painted-area coverage** check (every non-transparent DOM region must be
  covered by an emitted Figma node, diffed against the read-back's `absoluteBoundingBox` set)
  plus **flagged-node accounting** (every unwalkable node resolved to a logged raster; every
  shadow root / pseudo-element became real nodes). This is the position blind spot generalized
  — *unmeasured ⇒ unbuilt* — and it fails closed on a blank chart canvas or a dropped subtree
  before the frame can ship green.

## [1.9.0] - 2026-06-21

### Fixed
- `page-to-figma` verify had a **position/layout blind spot**: the numeric checklist asserted
  intrinsic properties (size, padding, gap, radius, fill, type, child-count) but never where a
  node actually lands, so an auto-layout frame whose every size was exact could ship with rows
  shifted, badges misplaced, and a malformed search box and still declare "0 failures →
  pixel-perfect." A reported run passed 2662 property-checks while 565 node positions were off
  by >1.5px. Verify is now **position-first**.

### Added
- **Absolute-position assertion (PRIMARY, ±1px)** in the verify checklist — every node's x/y
  relative to the frame root (read as `absoluteBoundingBox` minus the root's) vs the DOM rect,
  plus an **alignment assertion** (`layoutMode` / `primaryAxisAlignItems` /
  `counterAxisAlignItems` / `layoutPositioning`). Both ride in the existing single read-back
  blob. The correction loop fixes position drift **at the responsible ancestor**, not by
  nudging the symptom node.
- Extraction now records each node's `position` and, for `absolute`/`fixed`, its offset within
  the nearest positioned ancestor — and **excludes out-of-flow children from direction
  inference** (the bug that stacked an overlay magnifier above the search field instead of over
  it).
- Build contract now **renders captured `<input>` `placeholder`/`value` as a real text leaf**
  (previously captured but dropped, shipping a blank field), builds out-of-flow nodes with
  `layoutPositioning='ABSOLUTE'`, and **translates cross-axis alignment faithfully** (incl.
  `table-cell` `vertical-align:middle` → `counterAxisAlignItems='CENTER'`; no silent drop of
  `normal`/`stretch`).

### Changed
- The coarse screenshot backstop is documented as unable to show small layout shifts or a blank
  field by design — reinforcing that position/alignment must be caught numerically; per-region
  edge shots are offered as an optional secondary aid.

## [1.8.0] - 2026-06-20

### Added
- Vendored `silships/figma-cli` (MIT, pinned to v2.1.0) under `figma-cli/`, installed alongside
  the skills (`npm install` best-effort; non-fatal without Node).
- `page-to-figma` now drives figma-cli as its **primary** engine — local CDP, no Figma API
  rate limit, fetches image URLs directly — with the official Figma plugin MCP retained as an
  **announced** fallback (`skills/page-to-figma/references/mcp-fallback.md`).
- ADR 0006 recording the decision; ADR 0001 marked superseded-in-part.

### Changed
- The skill never auto-connects (never patches Figma Desktop): it stops and asks the user to
  connect. It confirms the target Figma file before the first write.

## [1.7.0] — 2026-06-20

### Changed
- `page-to-figma`: **auto-layout structure is now the build contract, not just an
  aspiration.** A real run (FIP Payment Method Configuration) was pixel-perfect but emitted
  a *flat list of absolutely-positioned siblings* — 216 direct children of one frame, nothing
  grouped, named, or reflowable — because flat was the path of least resistance and the
  verifier only rewarded pixels. The skill now:
  - States a **positive build contract**: transpile the extracted DOM tree node-for-node into
    nested auto-layout (container → auto-layout frame with captured direction/gap/padding/
    sizing; bg/border leaf → frame; text → fixed-width text leaf; icon → vector), with every
    layer **named from its DOM source** (`.snav-item` → "NavItem").
  - Demotes **flat absolute to a per-subtree last resort that must be `log()`ged** (which
    subtree, and why — e.g. "subgrid — flattened"), so lost structure is visible up front, not
    discovered as a sibling pile at the end. Never flatten a whole frame because it's easier to
    verify.
  - Names the **one real structure↔pixel conflict (font metrics)** and prescribes the fix —
    fixed-width text leaves (width = measured DOM rect) so a hug-content box can't push siblings
    and compound down a row — instead of dodging it by going flat.
  - Clarifies **bind-vs-raw is orthogonal to structure**: both modes build the nested tree; raw
    is not a license to flatten.

### Added
- `page-to-figma`: a **structure gate** in the verify loop, a peer of the numeric checklist.
  Pixel-green is necessary but not sufficient — the gate asserts direct-child sanity (no
  dozens-to-hundreds of direct children), leaf ancestry (every text/icon lives in a real
  auto-layout container), and fallback accounting (the only flat regions are logged ones). It
  folds into the existing batched read-back (parent id + child count in the same blob), so it
  costs no extra round-trip. **Flow mode** clones inherit the base's nesting and patch the
  delta **against the tree** (replace a container's children), never re-stamping a flat list.

## [1.6.0] — 2026-06-19

### Added
- **Shipped slash command `/update-design-skills`** — update the suite from inside
  Claude Code instead of pasting the `curl | bash -s -- --update` one-liner. The
  installer now ships single-file slash commands from a repo-root `commands/` dir
  into the sibling `commands/` dir of the skills target (e.g. `~/.claude/commands`),
  with the same selective-update, prune-on-removal, and `--uninstall` handling the
  skills get. The version manifest records an additional `commands=` line so
  `--update` can prune a command dropped from the suite. After updating, restart
  Claude Code (or run `/doctor`) so the new command file is discovered.

## [1.5.0] — 2026-06-19

### Added
- `page-to-figma`: **flow mode** — a multi-state run (e.g. a 12-state payment flow) no
  longer rebuilds and re-verifies every frame independently. States of one screen are
  near-duplicates, so the skill now extracts **all** states in one Playwright pass up front,
  builds and fully verifies **one base** to green, then **clones that base in Figma and
  applies only the per-state delta**, delta-verifying the changed nodes (plus shared
  invariants) rather than re-reading the whole tree. Flows default to **raw mode** (fewest
  correction iterations). This collapses a flow from `N × (build + full-verify)` to
  `1 × (build + full-verify) + (N−1) × (clone + delta-verify)` with the numeric-correctness
  guarantee unchanged.

### Changed
- `page-to-figma`: the verify loop now **batches MCP round-trips** — read all of a frame's
  node properties back in one `use_figma` script, diff in-agent, apply all corrections in
  one write script, re-read once (~3 round-trips per iteration instead of hundreds). The
  per-property checklist and tolerances are unchanged; this is pure latency removal.

## [1.4.1] — 2026-06-19

### Changed
- `page-to-figma`: now treats **CSS overflow clipping as a first-class extraction
  concern**, fixing the "element-accurate but wrong-looking" failure mode (off-screen
  content bleeding past a clipping container in Figma). Step 1 records `overflow-x/y` and
  reproduces clipping via a clip-rect stack, with a `position: fixed`/`absolute` escape
  rule so overlays aren't over-clipped; Step 3 carries the clip into the build
  (`clipsContent = true`, with a flat-model fallback); Step 4 adds a **clipping /
  negative-space verification pass** that checks what the page *hides*, not just the
  per-property values of nodes that exist. Also: prove the pipeline on one frame before
  fanning out, key deduped assets by content hash (not usage order), capture input
  `placeholder` text, and a fixed-width caveat for auto-width text whose font metrics drift
  (e.g. Thai). From real-run feedback on the FIP Payment & Tax transcription.

## [1.4.0] — 2026-06-19

### Added
- **Update notifications.** The installer now writes a `SessionStart` hook into
  Claude Code's `settings.json` that checks (at most once per 24h) whether a
  newer suite version is available and, if so, shows a one-line notice at the
  start of a session. On by default; disable with `install.sh --no-notify`, and
  `--uninstall` removes it. The check is a single lightweight request to
  GitHub's raw `VERSION` file and fails silently when offline.
- This `CHANGELOG.md`. The update notice and installer output link here.

### Fixed
- The installer now ships **`figma-to-dev-docs`** — it was missing from the
  installed skill set, so the suite installed only 11 of its 12 skills.

## [1.3.1] — 2026-06-18

### Changed
- `figma-to-dev-docs`: sharpened Step 2 extraction precision — read small text at
  crop resolution, flag source-copy issues, and don't assert unprovable behavior.

## [1.3.0] — 2026-06-18

### Added
- **`figma-to-dev-docs`** skill — turns a finished Figma frame/section into an
  AI-developer doc bundle (developer-facing PRD + spec-driven spec + Gherkin
  test-cases) with a REQ → task → test traceability chain. Command-only.

## [1.2.0] — 2026-06-18

### Changed
- Documented `design-spec-format.md` in the README structure tree.

## [1.1.0] — 2026-06-18

### Added
- `critique-figma-design`: styled report template.

### Fixed
- Suite routing conflicts between overlapping skills.

## [1.0.0] — 2026-06-17

### Added
- Versioned distribution: `install.sh` gains `--update` and `--check`, and a
  repo-root `VERSION` file becomes the single version of record (stamped into a
  `~/.claude/skills/.product-design-skill.version` manifest at install time).

[1.16.0]: https://github.com/Peeradonte48/product-design-skill/compare/v1.15.0...v1.16.0
[1.15.0]: https://github.com/Peeradonte48/product-design-skill/compare/v1.12.0...v1.15.0
[1.14.1]: https://github.com/Peeradonte48/product-design-skill/compare/v1.12.0...v1.15.0
[1.14.0]: https://github.com/Peeradonte48/product-design-skill/compare/v1.12.0...v1.15.0
[1.13.3]: https://github.com/Peeradonte48/product-design-skill/compare/v1.12.0...v1.15.0
[1.13.2]: https://github.com/Peeradonte48/product-design-skill/compare/v1.12.0...v1.15.0
[1.13.1]: https://github.com/Peeradonte48/product-design-skill/compare/v1.12.0...v1.15.0
[1.13.0]: https://github.com/Peeradonte48/product-design-skill/compare/v1.12.0...v1.15.0
[1.12.0]: https://github.com/Peeradonte48/product-design-skill/compare/v1.11.1...v1.12.0
[1.11.1]: https://github.com/Peeradonte48/product-design-skill/compare/v1.11.0...v1.11.1
[1.11.0]: https://github.com/Peeradonte48/product-design-skill/compare/v1.10.0...v1.11.0
[1.10.0]: https://github.com/Peeradonte48/product-design-skill/compare/v1.9.0...v1.10.0
[1.9.0]: https://github.com/Peeradonte48/product-design-skill/compare/v1.8.0...v1.9.0
[1.8.0]: https://github.com/Peeradonte48/product-design-skill/compare/v1.7.0...v1.8.0
[1.7.0]: https://github.com/Peeradonte48/product-design-skill/compare/v1.6.0...v1.7.0
[1.6.0]: https://github.com/Peeradonte48/product-design-skill/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/Peeradonte48/product-design-skill/compare/v1.4.1...v1.5.0
[1.4.1]: https://github.com/Peeradonte48/product-design-skill/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/Peeradonte48/product-design-skill/compare/v1.3.1...v1.4.0
