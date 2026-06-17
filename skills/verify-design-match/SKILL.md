---
name: verify-design-match
description: >-
  Compare a RUNNING page against the finished Figma frame(s) — or a whole SECTION of state-variant
  frames — it should match, and return a per-breakpoint, per-state, severity-ranked report of
  where the implementation diverges from the design, emitted as BOTH a human PDF and an AI-agent
  Markdown handoff. Read-only on your codebase and Figma: it NEVER edits code and NEVER writes to
  Figma (it may drive the live app under test to reach states, only with explicit authorization).
  This is a COMMAND-ONLY skill — it runs ONLY when the user explicitly invokes
  /verify-design-match, never automatically. Detection is a visual pass (screenshot overlay) then
  a property pass (measured DOM-vs-Figma diff); element matching is geometry-first/text-anchored
  and unmatched pairs are reported, never guessed; output is a per-category verdict plus cited
  findings, with NO overall score. To BUILD or FIX code from a Figma design use
  implement-figma-design; to push code INTO Figma use page-to-figma; to self-check a single Figma
  frame against rules use critique-figma-design.
disable-model-invocation: true
---

# Verify Design Match (live ↔ Figma parity audit)

Tell the team **how faithfully a page that's already running matches the Figma design it was
built from.** Given a running page and the finished frame(s) — or a whole **section** of
state-variant frames — it should match, this skill reports, **per breakpoint and per state**,
exactly where the implementation diverges. Its outputs are a human **PDF** and an **AI-agent
Markdown** handoff.

It is **read-only on your codebase and Figma**: it never edits code and never writes to Figma —
fixing the code is `implement-figma-design`'s job (the Markdown report hands off to it). To reach
server-driven states it may drive the **live app under test** (form submits, navigation) — but
**only with your explicit authorization** (see step 1). Every finding is **measured and cited** —
never a bare aesthetic preference. There is **no overall match score**; status is a per-category
✓/⚠/✗.

## Before you proceed — ask until clear

While this skill is active, **never silently guess.** Stop and ask until you know: the live page
(URL/route, or how to run the app), the Figma **frame or section**, **which frame pairs to which
route and state** (and how to *reach* each state — the interaction recipe), and any auth/seed
state needed. If the input is a section, you inventory and map its variants in step 2. If a live
element and a Figma node can't be confidently paired — or a state can't be reached — that goes to
"Couldn't align," never guessed into a finding.

## Preflight — required tools (stop if missing)

This skill **cannot run a partial audit.** Before anything else, confirm BOTH capabilities are
available; if **either** is missing, **stop and tell the user exactly what to set up.**

1. **Browser automation** — a **Playwright MCP** server **or** the **Playwright CLI**
   (`npx playwright` / an installed `@playwright/test`). Used to render the page at frame width,
   screenshot it, and read computed DOM styles. Detect which is present and use it.
2. **Figma access** — the **Figma MCP read tools** (`get_metadata`, `get_variable_defs`,
   `get_screenshot`) *primary*, **or** the **Figma REST API + a personal-access token** (via
   CLI/`curl`) as fallback. (There is no general-purpose official Figma CLI, so MCP is primary.)

Do not proceed to step 1 of the workflow until both are confirmed. (No third dependency for
output: the **PDF** is rendered with the Chromium you already have via Playwright — `page.pdf()` —
and the **Markdown** report is a plain file write.)

## When NOT to use

- Building a Figma design into code, or **fixing** code to match Figma → `implement-figma-design`.
- Pushing running code into Figma / updating the design to match shipped code → `page-to-figma`.
- Self-checking a **single** Figma frame against rules (a11y, tokens, heuristics) →
  `critique-figma-design`.
- Pure aesthetic preference ("which looks better?") — out of scope; this is an objective
  conformance audit only.

## Workflow

Use `references/parity-check-catalog.md` for the categories, tolerances, matching algorithm,
severity defaults, and the report templates (human PDF/HTML + AI-agent Markdown).

### 0. Preflight
Confirm browser automation **and** Figma access per the Preflight section. If either is missing,
stop with setup instructions.

### 1. Resolve inputs & authorize
Collect: the live page (+ run/auth details), the Figma **frame OR section** node, and the
breakpoint(s). Read the target project's tolerance/token rules if any (else note defaults apply).
Ask whatever is ambiguous.

- **A node-id may be a single frame or a whole *section* of state-variants** (default / filled /
  error / expanded / empty …). If it's a section, you inventory and map it in step 2 — never
  assume the linked node is one screen.
- **Watch for SPA in-memory auth.** Many single-page apps hold the auth token in memory, so a
  hard navigation to a deep route (`goto('/deep/route')`) silently bounces to the login guard.
  Log in, then reach the target **by client-side navigation** (click the nav/links) so the
  session survives. Confirm you're on the intended route, not a redirect.
- **Authorize live-app interaction.** Reaching non-default states (error, expanded, post-save)
  may require driving the live app — including **state-changing** actions (a submit that persists
  data). Confirm the target is a **safe/staging environment** and get the user's **explicit
  authorization** for destructive steps before running them. This skill never edits code and never
  writes to Figma; live-app writes happen **only** with that authorization, and each destructive
  step is **named in the report**.

### 2. Build the state inventory & map  (auto, then ask the gaps)
- **Enumerate.** If given a section, list every child frame; for each, capture name + thumbnail +
  detected distinguishing features (default / sample-filled / validation-error / expanded /
  empty …).
- **Auto-match proposes; the user confirms the default.** Audit the **default/initial** live
  state first and *propose* the frame it matches (geometry- and state-first) — then **confirm
  that pairing with the user before auditing.** Visual similarity to the live state is an
  **unreliable** way to pick the "default" frame: when the live default is itself a UX transform
  of the design (e.g. an expanded master collapsed into accordions on load, or a fresh/empty vs
  sample-filled form), the closest-looking frame is often *not* the design's intended default.
  Several frames sharing one layout and differing only by expand/collapse or fill state is the
  signal to confirm, not assume.
- **Ask the gaps.** For each remaining frame, show it and ask the user for (a) the live **route**
  and (b) the **interaction recipe** to reproduce that state ("submit empty → error", "click
  section X → expand", "save then reopen"). A frame the user can't map → "Couldn't align," never
  guessed.
- Confirm the full **(frame ↔ state ↔ recipe)** map before grinding through all states; if many
  (>~6), confirm scope first.

### 3. Per mapped state — drive & pull both sides
- **Drive the live app** into the state via its recipe (authorized interactions only).
- **Figma:** `get_metadata` + `get_variable_defs` (geometry + token-resolved properties) and
  `get_screenshot` (reference image). (Or the REST equivalents if using the token fallback.)
- **Live:** render **at that frame's width**, capture a full screenshot, and extract computed DOM
  styles + bounding boxes. If the content lives in an **inner scroll container** (common with
  `h-full`/`h-screen` app shells), `fullPage` only captures the viewport — grow the **viewport
  height** to the content height instead. **Do not mutate the DOM** (forcing `overflow`/`height`
  on ancestors distorts sticky panels and grids, producing phantom "missing element" findings);
  prefer a tall viewport, or scroll-stitch without style edits.

### 4. Visual pass
Overlay the live screenshot against the Figma reference to **locate diverging regions** (the
*where*).

### 5. Property pass
On the diverging regions, pair elements **geometry-first, text-anchored** (catalog algorithm);
diff measured values per category; record **element · property · live value · Figma value ·
delta · tolerance source**. Send sub-confidence pairs and unmatched elements to "Couldn't
align."

### 6. Assemble & emit — multi-state report, PDF + Markdown
- **One section per mapped state:** a per-category verdict line (✓/⚠/✗ for color, typography,
  spacing, layout, sizing), then severity-ranked findings (Must-fix, Should-fix), then "Couldn't
  align." Top the report with a one-line roll-up **across all states**. **No overall score.**
- **Emit BOTH formats** (templates in the catalog):
  - **PDF** — human-readable; render the assembled HTML via the Chromium you already have
    (`page.pdf()`). No extra dependency.
  - **Markdown (AI-agent), both layers** — a tool-agnostic machine-readable findings block (YAML
    frontmatter + per-state/per-category tables) **plus** an `implement-figma-design`-ready
    handoff section (per-state fix list: element · property · current · target · source).
- Write both files next to each other and report their paths. The Markdown is the handoff to a
  code-fixing agent; the skill itself still changes nothing in code or Figma.

## Dependencies

- **Required — browser automation:** Playwright MCP or CLI (render at frame width, screenshot,
  computed-style extraction).
- **Required — Figma access:** Figma MCP **read** tools (`get_metadata`, `get_variable_defs`,
  `get_screenshot`) or Figma REST API + token. **No `figma-use`, no write tools, ever.**
- **Outputs:** a human **PDF** (rendered via the same Chromium — no extra dependency) and an
  **AI-agent Markdown** report (two layers: machine-readable findings + an `implement-figma-design`
  handoff). The Markdown is a one-way handoff; this skill never invokes the fixer itself.
- **Read-only scope:** never edits **code**, never writes to **Figma**. The only writes are the
  two report files and — **when explicitly authorized** — state-changing interactions against the
  **live app under test** (never the codebase).
- Standalone — depends on no other suite skill (the Markdown report *composes* with
  `implement-figma-design` downstream, but does not call it).
