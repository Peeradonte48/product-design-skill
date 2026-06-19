# Changelog

All notable changes to the product-design-skill suite are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the suite is versioned by the repo-root [`VERSION`](VERSION) file (see
[CLAUDE.md → Distribution & versioning](CLAUDE.md)).

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

[1.5.0]: https://github.com/Peeradonte48/product-design-skill/compare/v1.4.1...main
[1.4.1]: https://github.com/Peeradonte48/product-design-skill/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/Peeradonte48/product-design-skill/compare/v1.3.1...v1.4.0
