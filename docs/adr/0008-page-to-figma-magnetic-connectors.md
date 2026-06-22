# 0008. page-to-figma uses magnetic (cloned-donor) connectors, and `use_figma` as the primary node-op engine

**Status:** Accepted (2026-06-22). Supersedes, in part, [ADR 0007](0007-page-to-figma-capture-wireflow.md)
— specifically its "arrows are static `VECTOR`s" mechanism and its figma-cli-as-engine premise
(itself from [ADR 0006](0006-page-to-figma-vendored-figma-cli.md)).

## Context

ADR 0007 made `page-to-figma` a capture + wireflow skill: capture each screen with Figma's native
`generate_figma_design`, arrange the frames, and connect them with arrows. For the arrows it chose
**static `VECTOR`** paths, on the reasoning that **`figma.createConnector()` throws in a `/design/`
file** (connectors are a FigJam node type). Static vectors have real drawbacks, all confirmed in
live runs:

1. They don't attach to frames, so they don't move or re-route when a screen is dragged.
2. Multi-way fans (e.g. 6 branches off one screen) crowd; hand-placed labels pile up.
3. Elbow routing must be computed by hand.
4. Headless arrowhead rendering via per-vertex `strokeCap` proved fragile (a passes-the-check,
   no-head-drawn silent-failure class we kept having to guard).

Two facts discovered during the first production wireflow (FIP-Setting UI-Design, 2026-06-22)
changed the calculus:

- **A connector copy-pasted from FigJam into a design file survives as a real `CONNECTOR` node** —
  it does *not* flatten to a vector. The Plugin API can read/write `connectorStart`, `connectorEnd`,
  and `magnet` on an existing connector even though it cannot *construct* one. So a single pasted
  connector is a reusable **donor** that can be `clone()`d and re-pointed per edge.
- **The vendored figma-cli's local CDP bridge is not reliable.** On a real machine its `connect`
  failed outright (`open -a Figma --args --remote-debugging-port=9222` → error -600). The entire
  wireflow (container, reparent, arrange, connectors) was instead built through the Figma plugin
  MCP's `use_figma` — the **same bridge already required** for `generate_figma_design` / `whoami` /
  `get_metadata`.

## Decision

1. **Arrows are magnetic FigJam connectors, cloned from a human-pasted donor** (primary). For each
   edge: `clone()` the donor, `appendChild` it onto the wireflow board (before setting endpoints —
   endpoints must share the connector's page), set `connectorStart`/`connectorEnd` + `magnet`, and
   write the label onto `connector.text` (it rides on the line). The donor's style (stroke, weight,
   arrowhead, `ELBOWED` line type) propagates to every clone. `createConnector` is never called.
2. **Static `VECTOR` arrows are the fallback** when no donor is available (the donor requires a
   one-time human FigJam→design paste). The skill offers the donor setup up front and falls back
   gracefully if the user declines.
3. **`use_figma` (Figma MCP Plugin API) is the primary engine** for all node ops
   (page/container creation, reparent, arrange, connectors). The vendored figma-cli `eval` is a
   documented fallback only. The skill must not depend on the figma-cli CDP bridge.

## Consequences

- Wireflow arrows now snap to frames and **auto-reroute** when frames move, so de-crowding a fan is
  just frame spacing (no arrow edits). The fragile `strokeCap` arrowhead class disappears on the
  primary path (the head is the donor's, inherited).
- A **new human prerequisite**: paste one FigJam connector into the design file as a permanent
  donor and supply its node id. The skill walks a non-technical user through it and keeps the donor.
- `use_figma` writes require loading the `figma-use` skill first and the async Plugin API
  (`getNodeByIdAsync`, `setCurrentPageAsync`); scripts are atomic, so connector writes are batched
  (~5–6/call).
- The vendored figma-cli is retained (ADR 0006) but demoted from primary engine to fallback; ADR
  0007's static-VECTOR arrow decision is superseded. No change to capture, flow sources, the
  incremental build, auth, or the completion gate.

## Addendum (2026-06-22, v1.16.0) — magnetic is the primary *attempt*, gated by verify-and-fallback

A second production run (connecting an existing in-Figma section into a wireflow) exposed a hard
limit of Decision 1 + 3 together: **in some `/design/` files via the `use_figma` plugin bridge,
re-pointing `connectorStart` is inert.** `connectorEnd` re-binds live (snaps on assign, tracks node
moves), but the **start vertex stays frozen** at the donor's original location no matter what is
assigned — node-magnet, free-position, position-offset, atomic `node.set`, clear-then-rebind,
`connectorLineType` toggle, on a clone *or* the original donor, page-level *or* section-nested, and
it ignores a real frame nudge. Critically the **property read-back lies** (`connectorStart.endpointNodeId`
reads correct while the geometry is frozen), and CONNECTOR nodes expose **no `vectorNetwork`**, so
there is no API to relocate the start by hand. The native connector solver *does* run under the
figma-cli/CDP engine (which drives the real app), so a CDP path could lift this — but that engine is
the flaky fallback (error -600), so it was not adopted.

**Refinement (does not reverse this ADR):** magnetic stays the **primary attempt**, but the skill
now runs a **mandatory verify-and-fallback gate** (`wireflow-build.md` §4): smoke-test ONE edge,
confirm the start landed **by geometry** (the endpoint-id read-back is insufficient), and if it's
frozen, **auto-fall-back to static VECTOR (§4b) for all edges**. The completion gate rejects a
frozen-start connector. This keeps magnetic primary where the environment supports it (e.g. the
original FIP run) while never shipping broken arrows where it doesn't. The v1.15.0 claim that the
donor-clone mechanism is unconditionally reliable is corrected to "reliable where `connectorStart`
re-renders; verify per edge-1 and fall back otherwise." See also the connect-only fast path
(`§0b`), added the same version, which skips capture entirely when frames already exist in Figma.
