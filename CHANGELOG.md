# Changelog

All notable changes to the product-design-skill suite are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the suite is versioned by the repo-root [`VERSION`](VERSION) file (see
[CLAUDE.md → Distribution & versioning](CLAUDE.md)).

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

[1.4.0]: https://github.com/Peeradonte48/product-design-skill/compare/v1.3.1...main
