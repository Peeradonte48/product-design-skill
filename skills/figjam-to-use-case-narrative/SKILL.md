---
name: figjam-to-use-case-narrative
description: >-
  Read a user-flow diagram from FigJam and turn it into a use-case-narrative (UCN)
  markdown document (FigJam → narrative). Use this skill WHENEVER the user shares a
  FigJam link or flow/diagram node and wants it written up, documented, or "turned into
  a use case", even if they don't say "narrative." Triggers: "turn this FigJam flow into
  a use case narrative", "generate a UCN from this flow <figjam-link>", "document this
  user flow", "write up the flow on this whiteboard". This reads FROM FigJam only — it
  does not draw or edit the diagram. Pair it with use-case-narrative-to-prototype to then
  build a clickable prototype from the narrative.
---

# FigJam Flow → Use-Case Narrative

Turn a FigJam user-flow diagram into a structured **use-case-narrative (UCN)** markdown
document. A flow diagram encodes a use case implicitly — start node, steps, decision
branches, end states, annotations. Your job is to read that diagram faithfully and
re-express it in the UCN format: a precise, testable description of who does what, in
what order, what can branch, and what must be true afterward.

This skill reads FROM FigJam only (via the Figma plugin / MCP) — it never draws or edits
the board. It is step 1 of the pipeline **FigJam → narrative → prototype**; the narrative
it emits is the exact input that `use-case-narrative-to-prototype` consumes.

## Before you proceed — ask until clear

A diagram is lossy: arrows rarely label every condition, and sticky notes rarely spell
out every precondition or stakeholder interest. **Never invent the missing pieces.** While
this skill is active, whenever a node, connector, branch, or label is ambiguous — or a
required UCN section (Preconditions, Stakeholders & Interests, Business Rules, the actor
behind a step) cannot be grounded in something actually on the board — **stop and ask the
user.** Batch related questions into as few rounds as possible (don't drip them one at a
time), but do not write a section you had to guess. A confidently-worded narrative built
on a guess is worse than an explicit "this wasn't on the diagram — who is the actor here?"

For **minor or optional** gaps the board doesn't settle, you don't have to block forever:
prefer omitting the ungrounded detail over inventing it, and record it in the coverage
report (step 4) so the user can fill it in. Reserve the hard stop for the required-section
gaps above — the things a narrative is meaningless without.

## When NOT to use

- The FigJam board is a **sitemap / IA / site-structure** diagram (pages and how they
  nest), not a user **flow** (steps, decisions, end states) → `figjam-sitemap-to-spec`,
  which writes a product spec instead of a narrative. If a bare FigJam link could be
  either, look at the board: connected steps and decision branches → this skill; a tree
  of named pages → the sitemap skill. When it's genuinely ambiguous, ask the user which
  one they want rather than guessing.
- The user wants the flow **built as a clickable prototype**, not written up →
  `use-case-narrative-to-prototype` (this skill produces its input doc first).

## Workflow

### 1. Read the diagram (ground truth, don't infer from the picture alone)

Parse the FigJam URL into `fileKey` and `nodeId`. FigJam boards live at
`figma.com/board/:fileKey/...`; when a `?node-id=:nodeId` is present, convert the `-` in
the node id to `:`. **If the link has no `node-id` (a whole-board link, or the user just
says "this board"), don't guess a node** — read the whole board, or ask which
section / frame to focus on if the board holds several flows. Then:

- `get_figjam` — the primary source of truth. Returns the node tree: shapes/cards, text,
  **connectors** (the arrows that define order and branching), and sections/swimlanes.
  Read this first and let it drive the structure.
- `get_screenshot` — a visual cross-check. Use it to resolve ambiguity `get_figjam` leaves
  open: which arrow leaves which node, how lanes are grouped, what a hand-drawn cluster
  means. The picture confirms; the node tree decides.

Build a mental graph: nodes (steps / screens / decisions / states), directed connectors
(transitions and their conditions), and groupings (swimlanes, sections, colored regions).

### 2. Map the diagram to UCN sections

Use `references/figjam-mapping.md` for the full primitive → section cheatsheet. The core
mapping:

- **Start / entry node** → `Trigger` (what kicks the flow off).
- **Main happy-path connector chain** → `Main Success Scenario` (numbered steps in order).
- **Decision diamonds and alternate/branch connectors** → `Extensions`, each numbered to
  the main step it branches from (e.g. a branch off step 5 becomes `5a.`).
- **Terminal / end nodes** → `Postconditions`, split by outcome (success vs. exit/failure).
- **Sticky notes, callouts, annotations** → `Business Rules` (constraints, gates, "always /
  never" statements) — only when they read as rules, not as step labels.
- **Swimlane / lane labels, the actor on the start node** → `Primary Actor` and
  `Stakeholders & Interests`.

Anything a required section needs that the board doesn't supply → ask the user (see above).
Omit the optional `Technical Notes` section entirely — a FigJam flow has no codebase
context to fill it, and you must not fabricate one.

### 3. Write the narrative

Write the document using the template and section-by-section guidance in
`references/use-case-narrative-format.md`. Honor it exactly:

- Follow the required section order; use numbered steps for the Main Success Scenario and
  step-anchored numbering for Extensions.
- Keep steps concrete and testable (an observable actor action + system response), not vague.
- Bilingual labels (e.g. Thai/English) are **optional** — include them only if the diagram
  uses them; otherwise write in the diagram's language.
- One narrative per flow. Name the file `<flow-name>-flow.md` and title it `# UC-NN: Title`
  (ask the user for the UC number if the diagram doesn't imply an ordering).

### 4. Confirm output location and report coverage

Before writing the file, confirm the output directory with the user (a common convention is
a `flows/use-case-narrative/` docs folder, but don't assume it — ask). After writing,
report what you grounded in the diagram vs. what you had to ask about, and list any sections
that are still thin so the user can fill them.

## Reference files

- `references/use-case-narrative-format.md` — the canonical UCN template + per-section
  authoring guidance (required vs. optional sections; bilingual optional). **Keep this in
  sync** with the identical copy in the `use-case-narrative-to-prototype` skill — the two
  skills share one format contract.
- `references/figjam-mapping.md` — diagram-primitive → UCN-section mapping cheatsheet.
