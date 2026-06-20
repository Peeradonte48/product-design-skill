# 0006. page-to-figma drives a vendored figma-cli (official plugin becomes fallback)

**Status:** Accepted (2026-06-20). Supersedes in part [ADR 0001](0001-page-to-figma-depends-on-official-figma-plugin.md).

## Context

page-to-figma's value is a correct-until-green verify loop that *hammers* Figma reads. Driven
through the official Figma MCP (cloud REST API), that loop hits hard rate limits — as low as 6
read calls/month on a View seat — and pays a large token tax for MCP tool schemas and verbose
JSON. `silships/figma-cli` (MIT) drives Figma Desktop locally over CDP: no API token, no rate
limit, works offline, terse output, and it fetches external image URLs directly (the MCP
`use_figma` Plugin API cannot).

## Decision

1. **Vendor the CLI** into the repo at `figma-cli/`, pinned to upstream tag **v2.1.0**
   (commit `e69cba0d…`), shipped and installed alongside the skills.
2. **figma-cli is page-to-figma's primary engine; the official Figma plugin (figma-use +
   figma-generate-design + Figma MCP) is the fallback** — used, with an explicit announcement,
   only when the CLI is unavailable.
3. **Vendor as real committed files, never a git submodule.** The suite installs via GitHub
   codeload tarball, which does not recurse submodules — a submodule'd copy would arrive empty
   for every `curl | bash` user. The files are a clean upstream copy and are never hand-edited;
   updates are a deliberate re-vendor (see `figma-cli/VENDORED.md`).
4. **Consent: the skill never auto-connects.** Yolo-mode `connect` patches Figma Desktop; that
   is the user's decision. If the daemon is down the skill stops and asks. This preserves the
   fail-closed consent posture ADR 0001 established.
5. **CLI install is best-effort and non-fatal.** No Node/npm, or a failed `npm install`, leaves
   the skills installed and page-to-figma on the MCP fallback.

## Consequences

- The verify loop is no longer rate-limited and costs fewer tokens; the image-URL limitation
  disappears; render's JSX (nested auto-layout) reinforces the structure contract.
- The repo gains a real Node source tree and a maintenance duty (re-vendor on upstream
  releases); `install.sh` runs `npm install`.
- Two I/O paths exist in the skill (CLI inline, MCP in `references/mcp-fallback.md`) — kept in
  sync, but the MCP path is frozen current behavior so drift risk is low.
- **Naming caveat:** the npm package `figma-use` (a vendored-CLI dependency) is *not* the
  official Figma plugin **skill** `figma-use`; they share a name only.

## Alternatives considered

- *Keep MCP primary, CLI opt-in* — leaves the rate-limit pain in place; rejected.
- *Install from npm (`npm install figma-ds-cli`)* — **dead, not merely inferior.** The npm
  package `figma-ds-cli` has only **`1.0.0`** published; the audited version (and the one the
  skill's verb/flag contract is written against) is the GitHub tag **`2.1.0`**, which the
  maintainer never pushed to npm. `npm install` would silently ship a two-major-behind CLI whose
  command surface may not match the skill. Worse, the bare name `figma-cli` on npm is an
  **unrelated, squatted package** (`unic/figma-cli`, "export/scaffold from Figma into style
  guides") — a name-collision trap. Committing the exact tag is the only way to guarantee the
  shipped CLI is the one we verified.
- *External dependency (user installs the CLI themselves)* — same blocker as npm (2.1.0 isn't on
  npm, so the user would have to git-clone a tag by hand), and it breaks the self-contained
  curl|bash one-liner; rejected.
- *Fetch-at-install from GitHub (clone tag `v2.1.0` at install time, nothing committed)* —
  tempting because it returns the repo to skill-only with **zero committed JS**. Rejected for
  this suite's portability ethos: it loses offline reproducibility, makes install fail if upstream
  moves/deletes the tag, and the shipped tree is no longer byte-for-byte auditable from our git.
  The committed copy is self-contained, offline-safe, and pinned to commit `e69cba0`. The cost —
  ~22.8k LOC of third-party JS in a formerly skill-only repo — is accepted and fenced (its own
  `figma-cli/` dir + `VENDORED.md`, never hand-edited).
- *Git submodule / subtree* — impossible with tarball installs (above).
- *CLI-only, no fallback* — hard-fails on any box without Figma Desktop/Node; rejected for
  portability.
