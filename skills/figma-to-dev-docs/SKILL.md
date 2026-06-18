---
name: figma-to-dev-docs
description: >-
  Turn a finished Figma frame or section into a bundle of AI-developer-ready documents — a
  developer-facing PRD, a spec-driven spec.md (EARS requirements + design + tasks), and Gherkin
  acceptance test-cases — after interviewing the user for the behavioral/business context a static
  design can't hold. Read-only; never writes to Figma, never builds code. This is a COMMAND-ONLY
  skill — it runs ONLY when the user explicitly invokes /figma-to-dev-docs, never automatically (so
  it never collides with implement-figma-design, which builds code from a figma link). For building
  the design into code use implement-figma-design; for a stakeholder buy-in brief use spec-to-brief;
  to challenge premise/scope use biz-review; to resolve ambiguity in an existing doc use harden-doc.
disable-model-invocation: true
---

# Figma → developer docs (PRD · spec · test cases)

Turn a **finished Figma frame or section** into the documents an **AI developer builds from**: a
developer-facing `PRD.md`, a spec-driven `spec.md` (requirements + design + tasks), and a Gherkin
`test-cases.md`. A static design shows *what the UI looks like*, never *what it does* — so this skill
**extracts what the design says**, **interviews you for the rest until it's clear**, then **writes
the three documents** with a full traceability chain (requirement → task → test).

This skill is **read-only**: it uses the Figma MCP read tools and (when run in a repo) reads the
codebase read-only to ground the docs. It **never writes to Figma and never builds or edits code** —
that is `implement-figma-design`.

## Before you proceed — ask until clear (but never fabricate)

While this skill is active, **never silently guess.** If the target frame/section is ambiguous, if
you can't tell which frames are distinct screens vs state variants, or if a behavior isn't shown —
**stop and ask, and keep asking until it's clear.** The interview is **generate-only**: it fills the
gaps needed to write the docs; it does **not** challenge the premise (→ `/biz-review`) or
relentlessly resolve every ambiguity (→ `/harden-doc`), and it **never fabricates a metric or demand
claim** (unsourced → Open Questions).

## Workflow

### 1. Preflight
Confirm the Figma MCP read tools are available. If they are not, **stop** and say so — this skill has
no input without Figma access; do not guess at the design.

### 2. Semantic extract
Read the frame/section with `get_metadata`, `get_design_context`, `get_screenshot`, and
`get_variable_defs`. Build an internal inventory: screens (frames), components, on-screen copy,
visible states, and design tokens. **Auto-detect** frame (one screen) vs section (many frames).

**Read small text at the right resolution — never transcribe labels from a zoomed-out
thumbnail.** A full-frame screenshot of a tall screen is downscaled so far that small labels
(field names, option-card text, helper copy) are easy to misread, and a confident misread silently
corrupts the spec. Before you commit any label to a requirement, confirm it against a source that
shows it at full size: `get_design_context` text nodes, `get_variable_defs`, or a **`get_screenshot`
of the specific sub-node/section** (not the whole frame). Component-*instance* text often isn't
exposed in `get_design_context` — for those, screenshot the sub-node and read the crop. When the
exact wording still isn't legible, ask rather than guess.

**Flag, don't silently fix, source-copy issues.** If the design's own copy has a typo or
inconsistency (e.g. a misspelled label), record it as an observation and route it to
`/critique-figma-design` — do not quietly "correct" it in the docs without noting you did, and never
invent copy the design doesn't contain.

**Don't assert behavior a static frame can't prove.** Layout-implied behaviors (sticky panels,
scroll, hover, transitions) are inferences — mark them assumed (or ask in the interview), the same
way unknowns go to Open Questions.

**Scope floor:** if the input is clearly a **sub-component** (a single button, a card) rather than a
screen or feature, flag it ("this looks like a component, not a screen") and ask whether to point at
the parent screen/section, proceed at component granularity anyway, or stop. Never silently emit a
thin three-doc bundle for a trivial input.

**If you are in a repo**, read it **read-only** to detect the framework, existing components,
tokens, and conventions — to *reference* in the spec's Design/Tasks. Never build or edit code.

### 3. Confirm the screen/state mapping
Present the screen/state map you inferred ("frames A/B/C look like states of one screen; D and E are
distinct screens") and ask the user to confirm or correct it. For a large section, **offer to scope
down** — "all N screens, or a subset this run?".

### 4. Context interview — until clear
Run the batched, feature-level interview in
[`references/context-interview.md`](references/context-interview.md): one round per topic naming all
in-scope screens, each question with a recommended answer. Do **not** generate until the
**completion bar** in that reference is met (checked per screen/state). Park genuine unknowns in Open
Questions with a stated reason.

### 5. Generate the three documents
Following [`references/doc-templates.md`](references/doc-templates.md), write three files:

- `PRD.md` — developer-facing build context (not a buy-in brief).
- `spec.md` — one file, three sections: EARS requirements (with `REQ-N` ids) · design (stack-aware
  when in a repo; **no pixel geometry**) · ordered tasks (each citing `REQ` ids).
- `test-cases.md` — Gherkin scenarios per screen/state, each tagged with the `REQ` id it verifies;
  these scenarios are the requirements' acceptance criteria.

Maintain the traceability chain: **REQ id → task → scenario.**

**Output location & naming:** put the three files in a per-feature folder. Priority: (1) an existing
project `docs/`/`specs/` convention if clearly present; (2) else the working directory; (3) else the
scaffold root. Name the folder a **kebab-case slug derived from the section / top-frame name,
confirmed with the user**. If the folder already exists, **never silently overwrite** — ask to
update in place, pick a new name, or abort. **Always report the final paths; never auto-edit
`.gitignore`.**

### 6. Report & hand off
Report the paths, what you grounded from the design vs got from the interview vs parked as Open, and
the natural next steps: `/biz-review` + `/harden-doc` to vet the PRD/spec; `implement-figma-design`
to build the screens pixel-perfect; `/verify-design-match` to check the build later.

## When NOT to use

- **Build the design into code** → `implement-figma-design` (this skill writes docs, not code).
- **A FigJam user-flow diagram** (not finished frames) → `figjam-to-use-case-narrative`.
- **A FigJam sitemap** → `figjam-sitemap-to-spec`.
- **A stakeholder buy-in / sign-off brief** → `spec-to-brief` (its PRD is a buy-in pitch; this
  skill's PRD is developer build context).
- **Challenge premise / value / scope** → `/biz-review`; **resolve every ambiguity in an existing
  doc** → `/harden-doc`.
- **Check a live build against Figma** → `/verify-design-match`; **critique one frame against rules**
  → `/critique-figma-design`.

## Reference files

- [`references/context-interview.md`](references/context-interview.md) — interview topics, batching,
  and the completion bar (single-owner).
- [`references/doc-templates.md`](references/doc-templates.md) — the three output formats and the
  traceability rule (single-owner).
