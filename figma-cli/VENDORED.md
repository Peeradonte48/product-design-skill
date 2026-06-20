# Vendored: figma-ds-cli

This directory is a **verbatim vendored copy** of the upstream CLI. It is shipped
and installed alongside the skill suite so `page-to-figma` can drive Figma Desktop
locally (no API token, no rate limit) instead of the rate-limited Figma MCP.

- **Upstream:** https://github.com/silships/figma-cli (MIT, © Sil Bormüller)
- **Pinned tag:** `v2.1.0`
- **Pinned commit:** `e69cba0dae4478e844516e84ba13e838f6616b6b`
- **Vendored on:** 2026-06-20
- **Vendored fileset:** `src/`, `plugin/`, `package.json`, `package-lock.json`, `LICENSE`.
  (Upstream `tests/`, `docs/`, `CLAUDE.md`, `README.md`, `REFERENCE.md`, `.github/`,
  `examples/`, `node_modules/` are intentionally NOT vendored.)

## Do not hand-edit

These files are a clean upstream copy. **Never patch them in place** — local edits
turn every future update into a merge conflict. To update:

1. `git clone --depth 1 --branch <newtag> https://github.com/silships/figma-cli`
2. Re-copy the vendored fileset above over `figma-cli/`.
3. Update the tag/commit/date in this file.
4. Re-run the install lifecycle test, bump the suite `VERSION`, add a `CHANGELOG` entry.

A git submodule is deliberately NOT used: the suite installs via GitHub codeload
tarball (`install.sh`), which does not recurse submodules — a submodule'd copy would
arrive empty for every `curl | bash` user.
