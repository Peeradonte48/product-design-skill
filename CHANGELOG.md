# Changelog

All notable changes to the product-design-skill suite are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the suite is versioned by the repo-root [`VERSION`](VERSION) file (see
[CLAUDE.md → Distribution & versioning](CLAUDE.md)).

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

[1.9.0]: https://github.com/Peeradonte48/product-design-skill/compare/v1.8.0...main
[1.8.0]: https://github.com/Peeradonte48/product-design-skill/compare/v1.7.0...v1.8.0
[1.7.0]: https://github.com/Peeradonte48/product-design-skill/compare/v1.6.0...v1.7.0
[1.6.0]: https://github.com/Peeradonte48/product-design-skill/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/Peeradonte48/product-design-skill/compare/v1.4.1...v1.5.0
[1.4.1]: https://github.com/Peeradonte48/product-design-skill/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/Peeradonte48/product-design-skill/compare/v1.3.1...v1.4.0
