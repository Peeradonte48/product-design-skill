# 0007. page-to-figma becomes capture + wireflow (native MCP capture replaces reconstruction)

**Status:** Accepted (2026-06-21). Supersedes [ADR 0006](0006-page-to-figma-vendored-figma-cli.md)
and the engine premise of [ADR 0001](0001-page-to-figma-depends-on-official-figma-plugin.md).

## Context

page-to-figma reconstructed a running page node-by-node: extract computed styles → rebuild a
nested auto-layout tree → verify by numeric read-back (a screenshot diff was *forbidden* on the
grounds that it "can't terminate"). Despite many patches — position-first verify (v1.9.0),
clipping pass, extraction-completeness gate (v1.10.0), structure gate, css-figma-map (v1.11.0) —
output **kept mismatching** in three recurring classes the user confirmed:

1. **Positions/spacing drift** — auto-layout *recomputes* positions from content + font metrics,
   so they emerge differently than the DOM; the correction loop fights itself and often never
   converges.
2. **Passes the checks, looks wrong** — verify is numeric-only, so nothing in the loop ever
   compares the result to the page; holistic defects (clipping, overlap, z-order, proportion)
   sail through green.
3. **Missing / extra content** — holes leak because no visual check would *see* them.

Root cause: the skill optimizes a **proxy** (per-node numbers) instead of the **goal** (does it
look like the page), and builds in a way (auto-layout) whose positions can't hold still. Every
new mismatch class only ever added another numeric gate. The approach itself was the problem.

The Figma MCP exposes **`generate_figma_design`** — an **agent-invocable, headless** tool that
captures a running page (URL or localhost) into a Figma design file using Figma's *own* renderer.
Fidelity is inherent because Figma produces the pixels; the old skill already called this tool,
but only as a fallback to source image hashes.

## Decision

1. **Replace reconstruction with native capture.** page-to-figma captures each screen via
   `generate_figma_design` into a single design page. The entire extract → build → numeric-verify
   machine is **deleted** (computed-style walk, nested-auto-layout build contract, correct-until-
   green loop, structure/clipping/completeness gates, `references/css-figma-map.md`,
   `references/mcp-fallback.md`, breakpoint re-extract-build).
2. **The value-add is the wireflow.** Captured frames are arranged (**lanes + branch drop-rows**,
   full size) on one page and joined by **labeled arrows** denoting transitions. Wireflow **nodes
   are defined by the flow source** (an explicit user list, a FigJam/UCN, and/or a confirmed
   crawl proposal — all optional, combinable); the skill never invents granularity.
3. **Arrows are `eval`-created `LINE`/`VECTOR` nodes** with an arrow `strokeCap` + a `TEXT` label.
   Native connectors (`figma.createConnector`) are **FigJam-only and throw in Figma Design**, and
   Figma has restricted the API so community workarounds no longer work. This **consciously
   overrides the vendored CLI's own "never eval-create visual nodes" rule** for this narrow case:
   endpoints are fully positioned from known frame rects, so that rule's rationale does not apply.
   Consequence: arrows are **static** (they do not reroute when a frame is moved).
4. **figma-cli is demoted** from primary build/verify engine to an **`eval` helper** for frame-
   arrange and arrow-create. It is **kept** (its CDP `eval` bridge is now load-bearing), which
   updates ADR 0006's "CLI is the primary engine" framing.
5. **Fail-closed hard dependency on the Figma MCP capture (+ Playwright).** With reconstruction
   and the MCP-fallback path gone, there is no degraded mode: if `generate_figma_design` is
   unavailable the skill **stops and says so** (the `verify-design-match` posture, ADR 0003).
   This updates ADR 0001 — page-to-figma is still a hard, documented dependency, but on the
   **capture tool**, not on the official plugin as an accuracy-supervised build engine.
6. **Auth & crawl are safe-by-default.** Default access model is **interactive user login +
   session reuse** (the agent never handles the password); fallbacks are a provided
   session/token or (discouraged) credentials. The skill never evades a block/CAPTCHA/MFA (it
   hands the browser to the user), never persists secrets, keeps crawl conservative (no
   destructive clicks) and bounded (prompted scope, defaults: same-origin, depth 3, ~20 screens).

## Consequences

- **The three mismatch classes are eliminated by construction** — there is no reconstruction to
  drift. `SKILL.md` collapses from ~479 to ~120 lines; several reference files are deleted.
- **Trade-off accepted:** captures are **raw pixel layers**, so per-screen editable auto-layout
  structure and design-system **bind mode** are lost. This is acceptable because the goal is a
  faithful **wireflow** (screens-as-pictures + arrows), not an editable component tree — that is
  a different tool.
- **The vendored figma-cli is now mostly idle** (only `eval`). It is retained for that bridge;
  whether to keep shipping it is revisited once the implementation measures `eval` vs `use_figma`.
- **New glossary term "Wireflow"** added to `CONTEXT.md`, kept distinct from *use-case narrative*
  and *sitemap*.
- `CLAUDE.md` / `README.md` must be rewritten: page-to-figma is no longer an "accuracy
  orchestrator on the figma-cli." ADRs 0006 and 0001 get superseded/updated status notes.
- VERSION gets a notable bump; `CHANGELOG.md` records the pivot.

## Alternatives considered

- **Keep patching reconstruction** — each fix adds a gate while the root cause (proxy ≠ goal,
  emergent positions) remains. Rejected; this is exactly the failure history above.
- **Tiered "place-exact build + visual oracle"** (an earlier brainstorm direction — place every
  node at its measured rect, gate on a screenshot overlay) — strictly more work and lower
  fidelity than letting Figma's own capture produce the pixels. Rejected once the MCP capture was
  identified.
- **Third-party importer APIs** (code.to.design / Codia / Magicul) for capture — rejected: the
  Figma MCP already captures natively and agent-invocably with no API key, and every third-party
  path ultimately writes into Figma via a human-in-the-loop plugin/clipboard the CLI cannot drive
  headlessly.
- **Native connectors for arrows** — rejected: FigJam-only, API-restricted in Figma Design.
- **`use_figma` (MCP) for arrows** — capable but more tokens; `eval`-create chosen for token
  economy (a handful of arrows, fully positioned).
- **Keep figma-cli as primary engine (ADR 0006)** — superseded: native capture moves the engine
  to the Figma MCP; the CLI survives only as an `eval` helper.
- **Crawl as an authoritative flow source** — rejected: crawl is fragile on non-link/stateful
  transitions, so it **proposes** a graph the user confirms, never ships a guessed flow.
