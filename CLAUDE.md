# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This is a **skill-only scaffold**, not an application. It contains seven portable, stack-agnostic Claude Code skills under [skills/](skills/) and nothing else — no `package.json`, no source tree, and no test setup. There are therefore no build/lint/test commands to document. If real app code is ever added, update this file with the actual commands.

The skills are deliberately **not** tied to any one project, framework, or design system. They detect and conform to whatever target project they're run against. (An earlier version of this repo hardcoded a "Ramen POS / Next.js / Tailwind" target; that coupling has been removed — do not reintroduce project-specific assumptions into the skills.)

## The skill suite

The seven skills form a **FigJam → narrative → prototype** pipeline, plus three standalone paths (design→code, sitemap→spec, and running-page→Figma) and two **command-only doc-review** skills (`harden-doc`, `biz-review`) that need no Figma at all and run only on explicit `/harden-doc` / `/biz-review` invocation (`disable-model-invocation: true`). The five Figma/FigJam skills read via the Figma MCP plugin and never guess — every skill opens with a "clarify until clear" rule: stop and ask the user rather than inventing a missing detail.

- **[implement-figma-design](skills/implement-figma-design/SKILL.md)** — *standalone, design → code.* Transcribes a finished Figma frame into a 1:1, pixel-perfect build in the target codebase, then verifies by diffing a screenshot of the running UI against the Figma reference. Use when the user shares a figma.com link and wants it built/matched. This is the web/React path; it does **not** push code into Figma (that's `figma-generate-design`) and does **not** build Flutter/mobile (that's `implement-figma-design-mobile`).

- **[figjam-to-use-case-narrative](skills/figjam-to-use-case-narrative/SKILL.md)** — *pipeline step 1, FigJam → narrative.* Reads a user-flow diagram from FigJam (via `get_figjam`) and writes a structured use-case-narrative (UCN) markdown doc. Reads only; never edits the board.

- **[use-case-narrative-to-prototype](skills/use-case-narrative-to-prototype/SKILL.md)** — *pipeline step 3, narrative → code.* Turns a UCN doc into a walkable, clickable code prototype (behavioral fidelity, not pixel fidelity; React by default, stack-aware). When a finished Figma design exists and pixel fidelity is needed, defer to `implement-figma-design`.

- **[figjam-sitemap-to-spec](skills/figjam-sitemap-to-spec/SKILL.md)** — *standalone, FigJam → spec.* Reads a sitemap / site-structure diagram from FigJam (via `get_figjam`) and writes a product spec markdown doc (sitemap tree + per-page specs). Reads only; never edits the board. Standalone, but the spec is plain markdown that composes with the suite's doc-review commands (`/harden-doc`, `/biz-review`) and the build skills above. Its `references/product-spec-guide.md` is flexible guidance, not a strict template, and is single-owner (not part of the shared contract below).

- **[page-to-figma](skills/page-to-figma/SKILL.md)** — *standalone, running page → Figma.* The inverse of `implement-figma-design`: transcribes a **running** product page into a 1:1 Figma frame. It is an **accuracy orchestrator** on top of the official Figma plugin (which it distrusts): it extracts live-DOM computed styles as ground truth, delegates bulk assembly to `figma-generate-design`, and gates on a **deterministic numeric property read-back** (not a screenshot diff), correcting wrong properties with direct `use_figma` writes until the checklist is green. **This is the first suite skill with a hard dependency on another plugin's skills** (`figma-use`, `figma-generate-design`) — see `docs/adr/0001-page-to-figma-depends-on-official-figma-plugin.md`. Contrast: `implement-figma-design` is Figma → code; the official `figma-generate-design` is the distrusted code → Figma path this skill supervises.

- **[harden-doc](skills/harden-doc/SKILL.md)** — *doc-review command, doc → hardened doc.* Interviews the user relentlessly about a plan/spec/UCN — one question at a time, a recommended answer with each — until every branch of the decision tree is resolved. Fork of the standalone `grill-me`, renamed and adapted to suite style; **command-only** (`/harden-doc`, `disable-model-invocation: true`). Resolves **ambiguity**; for premise/scope challenge, route to `biz-review`. Needs no Figma.

- **[biz-review](skills/biz-review/SKILL.md)** — *doc-review command, doc → scope decisions.* Challenges a plan/spec/UCN from the founder lens: premise challenge, demand-evidence forcing questions, mandatory alternatives (minimal-viable vs ideal), then a four-posture scope review where **every scope change is an individual user opt-in**. **Command-only** (`/biz-review`, `disable-model-invocation: true`). Distilled from gstack's `plan-ceo-review` + `office-hours` (MIT, © 2026 Garry Tan) with the gstack runtime, telemetry, and state machinery removed — **keep it portable; do not reintroduce gstack binary calls or `~/.gstack` paths.** Needs no Figma; uses WebSearch for the landscape check when available.

## Shared format contract — keep in sync

Both `figjam-to-use-case-narrative` and `use-case-narrative-to-prototype` carry an identical copy of `references/use-case-narrative-format.md` (the canonical UCN template — one skill writes it, the other reads it). These two copies are a shared contract: **when you edit one, edit the other to match.** Each skill also has a one-directional mapping reference (`references/figjam-mapping.md` and `references/prototype-mapping.md` respectively).

## Conventions when editing these skills

- **Stay stack-agnostic.** Skills detect the target project's framework, file structure, component patterns, styling, and token system and conform to them. Don't bake in a specific stack, design system, or domain.
- **Honor the target project's own conventions** (token systems, accessibility/ergonomics rules like touch-target or body-font minimums) while matching the design — and surface a conflict rather than silently shipping something that breaks a rule.
- **Reuse over reinvention; match every breakpoint.** Use existing components/tokens; a match at one width that breaks at another is not a match.
- **Clarify until clear.** This is the cross-cutting rule in all the skills — a wrong guess that looks right silently corrupts the spec. Batch related questions, but don't proceed past an unresolved ambiguity.
- **Don't confuse direction.** Most of these skills go design/flow → code (or doc); `page-to-figma` is the one exception, going running-page → Figma. Three directions stay distinct: pushing a *finished Figma design into code* is `implement-figma-design`; pushing *raw code into Figma* with no accuracy supervision is the separate `figma-generate-design` / `figma-generate-library` suite; `page-to-figma` is the supervised running-page → Figma path that orchestrates that suite. Don't reach for one when the user wants another.
- **Load `figma-use` before any `use_figma` write call.** Pure reads (`get_design_context`, `get_screenshot`, `get_metadata`, `get_variable_defs`, `get_figjam`) generally don't need it.
- **Keep the two doc-review lenses distinct, and keep them command-only.** `harden-doc` resolves ambiguity until shared understanding; `biz-review` challenges premise/value/scope. Their "When NOT to use" sections point at each other — keep that routing intact when editing either, and don't remove their `disable-model-invocation: true` (they must never auto-trigger).

## Tooling available

Figma MCP read tools (`get_design_context`, `get_screenshot`, `get_metadata`, `get_variable_defs`, `get_libraries`, `search_design_system`, `get_figjam`) and write tools (`use_figma`, plus `generate_figma_design` — the running-app capture `page-to-figma` uses to source image hashes), the `shadcn` MCP, and browser/screenshot tooling (e.g. Playwright) for DOM extraction and screenshot-based verification.
