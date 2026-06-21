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
  This is a **hard, fail-closed dependency**: if it is unavailable, **stop and tell the user** —
  there is no reconstruction fallback.
- **Target file: Figma MCP `create_new_file` + `whoami`** — to make/resolve the design file.
- **Page driving: Playwright** — to reach external URLs and drive states/auth before capture.
- **Arrange + arrows: vendored figma-cli `eval`** — `FIGMA_CLI="node ${PWD}/.claude/figma-cli/src/index.js"`
  (project install) else `node ${HOME}/.claude/figma-cli/src/index.js`. Its `connect` is
  auto-run on a down daemon (announce first; see v1.12.0 behavior). The CLI is an `eval` helper
  here, not a build engine.

All concrete recipes (capture+poll, one-page container, arrange math, the arrow `eval`,
placeholders, auth, crawl) live in **`references/wireflow-build.md`** — follow it exactly.

## Inputs

- **Screens to capture** (required): URLs / localhost routes, one per screen or state.
- **Flow connections** (optional, combinable — see "Flow sources"): a user transition list, a
  FigJam/UCN, and/or a bounded crawl. None given → capture + arrange only, then ask before arrows.
- **Target** (optional): an existing `/design/` file (extract `fileKey` from its URL), else create one.

## Pipeline

1. **Resolve the target design file.** Use the user's existing `/design/` file, else
   `create_new_file` (editorType `design`; load the `figma-create-new-file` skill first; resolve
   the plan via `whoami`). Create one **Wireflow page + container** (`references/wireflow-build.md` §2).
2. **Establish access if the app is authed.** Default: open a headed Playwright browser, let the
   user log in, save and reuse the session (`references/wireflow-build.md` §6). Never evade a
   block/CAPTCHA — hand the browser to the user. Never persist secrets.
3. **If crawl is a flow source: discover + propose the flow first** within prompted bounds
   (same-origin, path-prefix, depth 3, ~20 screens), label edges from the observed trigger, and
   get the user to confirm the graph before capturing (`references/wireflow-build.md` §7).
4. **Capture each screen/state** into the container, polling to `completed`; rename each frame to
   its screen name. Granularity is whatever the **flow source enumerates** — never invent states;
   reach states via Playwright before capturing (`references/wireflow-build.md` §1).
5. **Arrange** the frames — **lanes + branch drop-rows**, full size, generous gutters
   (`references/wireflow-build.md` §3).
6. **Draw labeled arrows** for each transition — orthogonal VECTOR + arrow `strokeCap` + Inter
   label, via `eval` (`references/wireflow-build.md` §4). Arrows are **static** (they don't
   reroute if frames move). Read-back-check each arrow connects the intended frames.

## Flow sources (three, optional, combinable)

- **Explicit list** — the user gives `from → to` + trigger. Authoritative.
- **FigJam / UCN** — read an existing user-flow / use-case-narrative and reproduce its edges.
  Authoritative.
- **Crawl** — drive the live app to discover the graph; **proposes**, the user confirms before
  anything is drawn (`references/wireflow-build.md` §7).

When more than one is given, the explicit list / FigJam / UCN win; crawl only fills gaps.

## Completion gate (this replaces any numeric verify)

Fidelity is Figma's capture's responsibility. Check only coverage + wiring:

- Every flow node produced a **completed** capture + a named frame; arrows connect the intended
  frames (read-back per `references/wireflow-build.md` §4).
- **Failed captures:** retry **once**; if still failing, drop a loud labeled **placeholder**
  (`⚠ Capture failed: <screen> — <reason>`) in its slot, still draw its arrows, continue, and
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
