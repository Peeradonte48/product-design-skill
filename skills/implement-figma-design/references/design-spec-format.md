# Design spec format — implement-figma-design

Single-owner reference (only `implement-figma-design` uses it). Defines the `design-spec.md`
artifact this skill extracts from a Figma node before building, and builds from. It is **build
guidance**, not the verification oracle — the Figma `get_screenshot` is the oracle (see SKILL.md
step 4). No other skill reads or writes this format, and it carries no sync-contract obligation.

## When & where it's written

- **Always**, right after the step-1 Figma reads and before building. Scale it to the build — a
  one-element build is a one-row table. No size threshold.
- **Filename:** `design-spec-<sanitized-node-id>.md` — one file per node, never overwriting
  another node's spec. Sanitize the node id for the filesystem (e.g. `12:34` → `12-34`).
- **Location**, in priority order: (1) an existing project `docs/`/`specs/` convention if the repo
  clearly has one; (2) else the working directory; (3) else the fresh-scaffold root. **Always
  report the path** to the user. **Never auto-edit `.gitignore`.**

## Frontmatter

```yaml
---
source: figma
file: <fileKey>
node: <nodeId>
breakpoints: [<width>, …]   # each width the design specifies
---
```

## Per-element table

One row per significant element:

| column  | meaning | source |
|---------|---------|--------|
| element | human layer name | get_design_context / get_metadata |
| node    | node id | get_metadata |
| x,y     | offset within the frame (px) | get_metadata |
| w×h     | width × height (px) | get_metadata |
| pad     | padding (px; auto-layout or measured) | get_metadata |
| gap     | item spacing between children (px) | get_metadata |
| radius  | border-radius (px) | get_metadata |
| color   | resolved hex **and** mapped project token (`#111 / --ink`); raw hex only if none matches | get_variable_defs + token mapping |
| type    | family / size / weight / line-height / letter-spacing | get_design_context |
| asset   | `export` if it needs a real exported asset (icon/image), else `—` | judgment |

For responsive designs, record one table (or column group) per breakpoint in the frontmatter — a
match at one width that breaks at another is not a match.

## `## Gaps` — split Blocking vs Noted

### Blocking
Genuine ambiguity that must be resolved **with the user before building** — do not proceed past it
(this is the skill's "clarify until clear" rule):
- an asset that can't be exported/accessed;
- an element whose purpose is unclear;
- a state the frame implies but doesn't show;
- a responsive reflow the design doesn't specify.

### Noted
Known values with no clean mapping — **flag, fall back to the raw value, carry into the build and
the inline verification**; does not block:
- a color/spacing/radius matching no project token;
- a value the project token system can't represent.

## Example

```markdown
---
source: figma
file: AbC123
node: 12:34
breakpoints: [1440]
---
# Design spec — Settings panel

| element  | node | x,y     | w×h    | pad | gap | radius | color        | type         | asset |
|----------|------|---------|--------|-----|-----|--------|--------------|--------------|-------|
| Save btn | 9:7  | 220,480 | 120×40 | 12  | —   | 8      | #111 / --ink | 14/600 Inter | —     |

## Gaps
### Blocking
- icon 14:2 — asset can't be exported; need source from user before building
### Noted
- color #3A7BD5 — no project token match; using raw value, flagged
```
