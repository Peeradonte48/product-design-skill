# MCP fallback path (page-to-figma)

Use this path **only** when the primary figma-cli engine is unavailable and the user
has been told (see SKILL.md "Connection & consent"). This is the suite's prior behavior,
frozen here. Announce to the user that you are on the **rate-limited Figma MCP path** and
that the verify loop may throttle; offer the figma-cli fast path.

> **Naming note:** the official Figma plugin **skill** `figma-use` (loaded before any
> `use_figma` write) is a different artifact from the npm package `figma-use` that the
> vendored CLI depends on. This fallback uses the *skill*.

## Hard dependency for this path

Requires the official Figma plugin skills `figma-use` and `figma-generate-design`, plus
the Figma MCP tools (incl. `generate_figma_design`). If they are absent too, stop — both
engines are unavailable (SKILL.md says when to stop).

## Engine mapping (same workflow, MCP verbs)

The extract → build → correct-until-green → structure-gate → clipping discipline in
SKILL.md is unchanged. Only the Figma I/O changes:

| Step | Purpose | MCP verb |
|---|---|---|
| 2 | Design-system detect | `get_variable_defs`, `search_design_system`, `get_libraries` |
| 3 raw | Build nested auto-layout | `use_figma` (load `figma-use` first) |
| 3 bind | Build bound to design system | `figma-generate-design` |
| 3 | Images | `use_figma` cannot fetch URLs → run `figma-generate-design`'s mandatory parallel `generate_figma_design` capture for `imageHash` values |
| 4 | Numeric read-back | one `use_figma` script returning one JSON blob (fills, w/h, padding, itemSpacing, radius, strokes, effects, font, parent id, direct-child count) |
| 5 | Structure gate | child-count + ancestry from that blob |
| 6 | Clipping / edge backstop | `get_screenshot` of card/scroll-region edges |
| 7 | Coarse backstop | `get_screenshot` of the node |

## Round-trip discipline

One `use_figma` read script → diff in-agent → one `use_figma` write script applying all
corrections → one re-read. ~3 round-trips per correction iteration. If a tool returns
"tool not found," the connected Figma MCP is outdated — tell the user to update Figma.
