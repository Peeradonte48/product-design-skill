---
name: figjam-sitemap-to-spec
description: >-
  Read a sitemap / site-structure diagram from FigJam and turn it into a product
  spec markdown document (FigJam → spec). Use this skill WHENEVER the user shares a
  FigJam link or a sitemap / IA / site-structure node and wants it written up as a
  spec for building a web-app or application, even if they don't say "spec." Triggers:
  "turn this FigJam sitemap into a spec", "document this site map / IA", "write a
  product spec from this site structure <figjam-link>", "spec out the app from this
  whiteboard sitemap". This reads FROM FigJam only — it does not draw or edit the
  diagram. It produces a markdown spec, not code and not a use-case narrative. The
  spec is plain markdown you can stress-test with a doc-review skill (e.g. /harden-doc)
  and then feed to use-case-narrative-to-prototype or implement-figma-design.
---

# FigJam Sitemap → Product Spec

Turn a FigJam sitemap (a site-structure / information-architecture diagram) into a
**product spec** markdown document. A sitemap encodes a product's skeleton: which pages
or screens exist, how they nest, which feature areas group them, and how navigation
connects them. Your job is to read that structure faithfully and re-express it as a
build-ready spec — what each page is for, what it contains, what it links to, and what
must be true around it.

This skill reads FROM FigJam only (via the Figma plugin / MCP) — it never draws or edits
the board. It is a **standalone** path (not part of the flow → narrative → prototype
pipeline), but its output composes: the spec is plain self-contained markdown you can
grill with a doc-review skill, hand to `use-case-narrative-to-prototype`, or use to scope
an `implement-figma-design` build.

## Before you proceed — ask until clear

A sitemap is lossy: a box names a page but rarely names its route, its purpose, the data
behind it, or who may see it. **Never invent the missing pieces.** While this skill is
active, whenever a node, connector, grouping, or label is ambiguous — or something the
spec needs (a page's purpose, its route, an access rule, the product's scope) cannot be
grounded in something actually on the board — **stop and ask the user, and keep asking
until it's clear.** Batch related questions, but do not write a section you had to guess.
A confidently-worded spec built on a guess is worse than an explicit "this page isn't
described on the board — what is it for?"

## Workflow

### 1. Read the sitemap (ground truth, don't infer from the picture alone)

Parse the FigJam URL into `fileKey` and `nodeId`. FigJam boards live at
`figma.com/board/:fileKey/...`; when a `?node-id=:nodeId` is present, convert the `-` in
the node id to `:`. **If the link has no `node-id` (a whole-board link, or the user just
says "this board"), don't guess a node** — read the whole board, or ask which
section to focus on if the board holds more than one sitemap. Then:

- `get_figjam` — the primary source of truth. Returns the node tree: shapes/cards, text,
  **connectors** (the lines that define hierarchy and links), and sections/lanes. Read this
  first and let it drive the structure.
- `get_screenshot` — a visual cross-check. Use it to resolve what `get_figjam` leaves
  ambiguous: which box is the root, how nesting is drawn, what a colored region groups.
  The picture confirms; the node tree decides.

Build a page-hierarchy graph: nodes (pages / screens), parent-child nesting, navigation
connectors, and groupings (sections, colored regions, lanes).

### 2. Map the diagram to spec sections

Use `references/sitemap-mapping.md` for the full primitive → section cheatsheet. The core
mapping:

- **Root / home node** → the entry page and the spec's top of the sitemap tree.
- **Page card / box** → one page entry (with its own per-page detail).
- **Nested card / tree child, parent-child connector** → a sub-page (child route) and a
  hierarchy edge.
- **Navigation connector / link line** → a navigation edge; its label is the link
  relationship.
- **Section / colored region** → a feature area or module grouping the pages under it.
- **Sticky note / callout** → a per-page note or a business/access rule for a nearby page.
- **Lane / role label** → access / which user role reaches which pages.

Anything a section needs that the board doesn't supply → ask the user (see above).

### 3. Write the spec

Write the document using the **flexible guidance** in `references/product-spec-guide.md`.
The guide lists the building blocks a good product spec covers — it is **not** a rigid
template. Adapt it to the board:

- Include the sections the sitemap actually grounds; drop the ones it doesn't; add others
  if the board calls for them. The section set and order are your call per sitemap.
- Always render the page hierarchy as a sitemap tree, and give each page a concrete entry.
- Prefer omitting an ungrounded section over fabricating it; record every gap under an
  **Open Questions & Assumptions** section instead.
- Bilingual labels (e.g. Thai/English) are **optional** — include them only if the board
  uses them; otherwise write in the board's language.
- One spec per sitemap. Name the file `<product-or-area>-spec.md` and title it
  `# <Product/Area> — Product Spec` (ask the user for the product/area name if the board
  doesn't make it obvious).

### 4. Confirm output location and report coverage

Before writing the file, confirm the output directory with the user (a common convention is
a `docs/specs/` folder, but don't assume it — ask). After writing, report what you grounded
in the diagram vs. what you had to ask about, and list any thin sections. Note that the spec
is plain markdown ready to be stress-tested with a doc-review command (e.g. `/harden-doc`,
or `/biz-review` for the business case) or fed to `use-case-narrative-to-prototype` /
`implement-figma-design`.

## Reference files

- `references/sitemap-mapping.md` — diagram-primitive → spec-section mapping cheatsheet, plus
  what sitemaps routinely omit (so: ask).
- `references/product-spec-guide.md` — flexible guidance on the building blocks of a good
  product spec. This is the skill's own reference (not a shared contract) — adapt it per
  sitemap rather than following it verbatim.
