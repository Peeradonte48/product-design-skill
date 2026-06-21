---
name: page-to-figma
description: >-
  Capture a RUNNING product page (or several) into Figma as a pixel-accurate WIREFLOW
  (running page → Figma): capture each screen with Figma's native page-capture, arrange
  them, and connect them with labeled arrows. Use WHENEVER the user has a live page, URL,
  or running app and wants it mirrored in Figma — one screen, or a whole flow of connected
  screens. Triggers: "capture our app's screens into Figma", "put this page into Figma",
  "turn our live signup flow into a Figma wireflow", "mirror these running pages in Figma
  and connect them." Do NOT use it to push a finished Figma design INTO code (that's
  implement-figma-design), or to design something brand-new in Figma with no source page.
---

# page-to-figma — running page → Figma wireflow

Capture each screen of a running product with **Figma's own native capture**
(`generate_figma_design`), arrange the captured frames, and connect them with labeled arrows
into a **wireflow**. Fidelity is Figma's capture's job — this skill does **not** reconstruct
pages node-by-node (that approach is gone; see `docs/adr/0007-page-to-figma-capture-wireflow.md`).

## Before you proceed — ask until clear

Never silently guess. If the screen set, the flow connections, a route, or how to reach a state
is ambiguous, **stop and ask**. A wrong guess that looks right corrupts the wireflow. Batch
related questions, but don't proceed past an unresolved ambiguity.

## Engines & hard dependency (fail-closed)

- **Capture: Figma MCP `generate_figma_design`** — agent-invocable, headless, pixel-accurate.
  The capture is **driven from inside the running page** (inject Figma's `capture.js`, call
  `captureForDesign` — `references/wireflow-build.md` §1), not a single MCP call. This is a
  **hard, fail-closed dependency**: if unavailable, **stop and tell the user** — no reconstruction
  fallback.
- **Target file: Figma MCP `create_new_file` + `whoami`** — to make/resolve the design file.
- **Page driving: Playwright — prefer the Playwright MCP.** Reaches URLs and drives states/auth
  before capture. **Check it up front** (`references/wireflow-build.md` §0): if there is no
  Playwright MCP **and** no importable `playwright`/`playwright-core`, this is **fail-closed** —
  stop and tell the user to install it (`claude mcp add playwright npx @playwright/mcp@latest`,
  then restart). Don't hand-locate a cached Chromium binary.
- **In-page code execution: a denied-by-default permission.** Capture injects Figma's `capture.js`
  into the live page, which needs an arbitrary-JS-in-page tool (e.g. the MCP's
  `browser_run_code_unsafe`). It's **blocked by default and the agent can't self-grant it** — the
  user must allow it in the target project's `.claude/settings.local.json` **before** capturing
  (`references/wireflow-build.md` §0).
- **Node ops (container / reparent / arrange / connect): prefer `use_figma`** (Figma MCP Plugin
  API — load the `figma-use` skill first; async API; atomic, batch ~5–6 ops/call). It's the same
  MCP bridge already required above, so no new dependency. The vendored **figma-cli `eval`**
  (`FIGMA_CLI="node ${PWD}/.claude/figma-cli/src/index.js"` else `${HOME}/...`) is a **fallback**
  only — its local CDP bridge can fail outright (error -600); don't depend on it
  (`references/wireflow-build.md` §0).
- **Arrows: magnetic FigJam connectors (primary), static VECTOR (fallback).** Connectors can't be
  *created* in a `/design/` file, but a connector **pasted from FigJam survives** and is cloned +
  re-pointed per edge → real snapping, auto-rerouting arrows (`references/wireflow-build.md` §4).
  This needs a one-time human **donor** paste; if the user declines, fall back to static VECTOR
  arrows (§4b). The donor's style propagates to every clone.

All concrete recipes (capture+poll, one-page container, arrange math, the arrow `eval`,
placeholders, auth, crawl) live in **`references/wireflow-build.md`** — follow it exactly.

## Inputs

- **Screens to capture** (required): URLs / localhost routes, one per screen or state.
- **Flow connections** (optional, combinable — see "Flow sources"): a user transition list, a
  FigJam/UCN, and/or a bounded crawl. None given → capture + arrange only, then ask before arrows.
- **Target** (optional): an existing `/design/` file (extract `fileKey` from its URL), else create one.

## Pipeline

1. **Verify engines first (fail-closed).** Confirm both the **Figma capture** and **Playwright**
   (prefer the MCP) are reachable before doing anything (`references/wireflow-build.md` §0). If
   Playwright is missing, stop and have the user install `@playwright/mcp`. Don't improvise. **Also
   confirm the in-page code-execution tool is *allowed*** (e.g. `browser_run_code_unsafe`) — it's
   denied by default and the agent can't self-grant it. If it's blocked, **walk the user through
   the grant in plain language, step by step (assume they're not technical), and wait** — don't
   just print a tool name. Use the ready-to-relay script in `references/wireflow-build.md` §0. Do
   this now, not 4 screens in. **Also offer the magnetic-arrow setup now** — ask the user to paste
   one FigJam **donor** connector and send its link (§0/§4) so it's ready by the time you connect;
   if they decline, you'll use static VECTOR arrows (§4b).
2. **Resolve the target design file.** Use the user's existing `/design/` file, else
   `create_new_file` (editorType `design`; load the `figma-create-new-file` skill first; resolve
   the plan via `whoami`). Create one **Wireflow page + container** (`references/wireflow-build.md` §2).
3. **Establish access if the app is authed.** Prefer interactive login via the Playwright MCP / the
   user's own browser, then save & reuse the session. In a **headless-only sandbox** a headed login
   browser hangs — fall back to a user-provided `storageState` (`references/wireflow-build.md` §6).
   Never evade a block/CAPTCHA — hand the browser to the user. Never persist secrets.
4. **If crawl is a flow source: discover + propose the flow first** within prompted bounds
   (same-origin, path-prefix, depth 3, ~20 screens), label edges from the observed trigger, and
   get the user to confirm the graph before capturing (`references/wireflow-build.md` §7).
5. **Smoke-test ONE screen first.** Reach the state with Playwright, inject the capture, fire it,
   and **keep the page open until the upload is confirmed received** — the capture promise resolves
   *before* the upload finishes; closing early silently drops it (`references/wireflow-build.md`
   §1). Confirm it landed by a **new frame appearing**, not by `pending` status. For apps with **no
   deep-linkable routes**, drive state with Playwright even on localhost (§1b). Check fidelity
   (fonts, non-Latin scripts, CSS framework) on this one screen **before scaling**. Never invent
   states.
6. **Build incrementally — capture → place → connect, one screen at a time** (default, Playwright
   MCP path). Walk the flow in order; for each screen: capture it (**fire the in-page capture, don't
   `await` it** — then poll for the frame to confirm it landed), place it in its lane slot (**lanes +
   branch drop-rows**, full size — §3), then **connect it to its predecessor with a magnetic
   connector** (clone the donor + magnets + label — §4; static VECTOR if no donor — §4b) and
   read-back-check it. Repeat. This leaves a *connected* partial flow if a run dies and lets you
   verify each link as you go. The MCP browser persists across shell commands, so interleaving
   captures and `use_figma` ops is fine (`references/wireflow-build.md` §8). Rename each frame to its
   screen name. Magnetic connectors **auto-reroute** when frames move (VECTOR arrows don't).
   **Bound every wait and emit progress** — a capture running long with **no output is a hang, not
   slowness**; localize it (`references/wireflow-build.md` §9), never sit silently.
7. **Batch fallback (no Playwright MCP).** With only the Bash node-driver, a stray shell command
   kills the capture driver (§0), so you can't interleave — capture all screens in one process,
   then arrange (§3) and connect all edges (§4/§4b) after it exits (`references/wireflow-build.md` §8).

## Flow sources (three, optional, combinable)

- **Explicit list** — the user gives `from → to` + trigger. Authoritative.
- **FigJam / UCN** — read an existing user-flow / use-case-narrative and reproduce its edges.
  Authoritative.
- **Crawl** — drive the live app to discover the graph; **proposes**, the user confirms before
  anything is drawn (`references/wireflow-build.md` §7).

When more than one is given, the explicit list / FigJam / UCN win; crawl only fills gaps.

## Completion gate (this replaces any numeric verify)

Fidelity is Figma's capture's responsibility. Check only coverage + wiring:

- Every flow node produced a **completed** capture + a named frame; every edge connects the intended
  frames (read-back per `references/wireflow-build.md` §4 — for a magnetic connector assert
  `type === "CONNECTOR"` + endpoint ids; for a VECTOR assert endpoints + a non-`NONE` arrowhead).
- **Failed captures:** retry **once**; if still failing, drop a loud labeled **placeholder**
  (`⚠ Capture failed: <screen> — <reason>`) in its slot, still connect its edges, continue, and
  **list every failure at the end** for the user to retry (`references/wireflow-build.md` §1, §5).
- **Re-run:** a full re-run builds a **new** board and leaves any prior one untouched (no
  destructive mutation); only a failure-retry patches a placeholder in the current board.
- Optionally surface a screenshot of the assembled wireflow.

There is **no** computed-style assertion, structure gate, or correction loop.

## When NOT to use

- Pushing a finished **Figma design into code** → `implement-figma-design`.
- Designing something **brand-new in Figma** with no running source → `figma-generate-design`.
- A read-only **parity audit** of a running page vs a finished Figma frame → `verify-design-match`.

## Notes

- **Captures are raw pixel layers** — there is no design-system **bind mode** and per-screen
  layers may not be a clean editable tree. That is fine for a wireflow (screens + arrows); if the
  user needs editable system-bound components, that is a different tool.
- **Breakpoints** = one wireflow board per viewport width (layout reflows; no cross-width delta).

## Helpful resources

- **Wireflow build mechanics:** `references/wireflow-build.md` — capture+poll, one-page
  container, arrange math, the arrow `eval`, placeholders, auth, crawl.
