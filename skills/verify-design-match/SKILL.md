---
name: verify-design-match
description: >-
  Compare a RUNNING page against the finished Figma frame(s) it should match and return a
  per-breakpoint, severity-ranked report of where the implementation diverges from the design.
  Read-only: it NEVER edits code and NEVER writes to Figma. This is a COMMAND-ONLY skill — it
  runs ONLY when the user explicitly invokes /verify-design-match, never automatically. Detection
  is a visual pass (screenshot overlay) then a property pass (measured DOM-vs-Figma diff);
  element matching is geometry-first/text-anchored and unmatched pairs are reported, never
  guessed; output is a per-category verdict plus cited findings, with NO overall score. To BUILD
  or FIX code from a Figma design use implement-figma-design; to push code INTO Figma use
  page-to-figma; to self-check a single Figma frame against rules use critique-figma-design.
disable-model-invocation: true
---

# Verify Design Match (live ↔ Figma parity audit)

Tell the team **how faithfully a page that's already running matches the Figma design it was
built from.** Given a running page and the finished frame(s) it should match, this skill
reports — per breakpoint — exactly where the implementation diverges, and **changes nothing**.

It is **read-only**: it never edits the code and never writes to Figma. Fixing the code is
`implement-figma-design`'s job. Every finding is **measured and cited** — never a bare
aesthetic preference. There is **no overall match score**; status is a per-category ✓/⚠/✗.

## Before you proceed — ask until clear

While this skill is active, **never silently guess.** Stop and ask until you know: the live page
(URL/route, or how to run the app), the Figma frame(s), **which frame pairs to which route and
state**, and any auth/seed state needed to reach the page in the right state. If a live element
and a Figma node can't be confidently paired, that goes to "Couldn't align" — it is never
guessed into a finding.

## Preflight — required tools (stop if missing)

This skill **cannot run a partial audit.** Before anything else, confirm BOTH capabilities are
available; if **either** is missing, **stop and tell the user exactly what to set up.**

1. **Browser automation** — a **Playwright MCP** server **or** the **Playwright CLI**
   (`npx playwright` / an installed `@playwright/test`). Used to render the page at frame width,
   screenshot it, and read computed DOM styles. Detect which is present and use it.
2. **Figma access** — the **Figma MCP read tools** (`get_metadata`, `get_variable_defs`,
   `get_screenshot`) *primary*, **or** the **Figma REST API + a personal-access token** (via
   CLI/`curl`) as fallback. (There is no general-purpose official Figma CLI, so MCP is primary.)

Do not proceed to step 1 of the workflow until both are confirmed.

## When NOT to use

- Building a Figma design into code, or **fixing** code to match Figma → `implement-figma-design`.
- Pushing running code into Figma / updating the design to match shipped code → `page-to-figma`.
- Self-checking a **single** Figma frame against rules (a11y, tokens, heuristics) →
  `critique-figma-design`.
- Pure aesthetic preference ("which looks better?") — out of scope; this is an objective
  conformance audit only.

## Workflow

Use `references/parity-check-catalog.md` for the categories, tolerances, matching algorithm,
severity defaults, and report template.

### 0. Preflight
Confirm browser automation **and** Figma access per the Preflight section. If either is missing,
stop with setup instructions.

### 1. Resolve inputs & conventions
Collect the live page (+ run/auth/state details), the Figma frame(s), and the frame↔route/state
pairing. Read the target project's tolerance/token rules if any (else note defaults apply). Ask
if anything is ambiguous. If many frames (>~6), confirm scope before grinding through all.

### 2. Per frame — pull both sides
- **Figma:** `get_metadata` + `get_variable_defs` (geometry + token-resolved properties) and
  `get_screenshot` (reference image). (Or the REST equivalents if using the token fallback.)
- **Live:** render the page **at that frame's width**, capture a full screenshot, and extract
  computed DOM styles + bounding boxes.

### 3. Visual pass
Overlay the live screenshot against the Figma reference to **locate diverging regions** (the
*where*).

### 4. Property pass
On the diverging regions, pair elements **geometry-first, text-anchored** (catalog algorithm);
diff measured values per category; record **element · property · live value · Figma value ·
delta · tolerance source**. Send sub-confidence pairs and unmatched elements to "Couldn't
align."

### 5. Assemble the frame's section
Per-category verdict line (✓/⚠/✗ for color, typography, spacing, layout, sizing), then
severity-ranked findings (Must-fix, Should-fix), then "Couldn't align." Repeat per frame; top
the report with a one-line roll-up. **No overall score.**

## Dependencies

- **Required — browser automation:** Playwright MCP or CLI (render at frame width, screenshot,
  computed-style extraction).
- **Required — Figma access:** Figma MCP **read** tools (`get_metadata`, `get_variable_defs`,
  `get_screenshot`) or Figma REST API + token. **No `figma-use`, no write tools, ever.**
- Standalone — depends on no other suite skill.
