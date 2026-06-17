# verify-design-match Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `verify-design-match` — a command-only, read-only skill that compares a running page against the finished Figma frame(s) it should match and reports per-breakpoint divergences, changing nothing.

**Architecture:** One command-only `SKILL.md` (the workflow, opening with a fail-closed tooling preflight) + one single-owner `references/parity-check-catalog.md` (five categories, default tolerances, the geometry-first/text-anchored matching algorithm, severity defaults, report template). Detection is a visual pass (screenshot overlay locates regions) then a property pass (measured live-DOM-vs-Figma diff). Plus an ADR for the external tooling dependency and suite-index doc updates.

**Tech Stack:** Markdown skill files only. Skill-only repo — no `package.json`, no test runner. "Tests" are deterministic `grep`/read checks with expected output.

## Global Constraints

- **Command-only:** frontmatter MUST carry `disable-model-invocation: true`. Fires only on `/verify-design-match`.
- **Read-only:** NEVER edits code, NEVER writes to Figma. No `figma-use` / `use_figma` / `generate_figma_design` / any write tool. Reads only.
- **Fail-closed preflight:** require BOTH (a) browser automation — Playwright MCP **or** CLI; and (b) Figma access — Figma MCP read tools **or** Figma REST API + token. If either is missing, STOP with exact setup instructions; never emit a partial/degraded report.
- **Detection = visual pass then property pass.** Overlay screenshots to locate diverging regions, then diff measured values on those regions.
- **Matching = geometry-first, text-anchored.** Pairs below the confidence bar go to a **"Couldn't align"** list — never guessed into a finding.
- **Unit of work = per Figma frame, page rendered at that frame's width.** One report section per frame (breakpoint-aware). Confirm scope if >~6 frames.
- **Five categories:** color · typography · spacing · layout/position · sizing.
- **Per-category verdict (✓/⚠/✗), NO overall score / percentage.**
- **Every finding measured & cited:** `element (live selector / Figma layer + node id) · property · live value · Figma value · delta · category · severity · tolerance source`. No bare aesthetic finding.
- **Tolerances conform to target first, else defaults:** sub-pixel ≤1px ignored; color by hex + small ΔE; font-size/weight/family exact. State source per finding.
- **Stay stack-agnostic.** No hardcoded framework/design-system/domain.
- **Clarify-until-clear** opener (inputs, frame↔route/state pairing, auth/seed state).
- Source of truth: `docs/superpowers/specs/2026-06-17-verify-design-match-design.md`.

## Sequencing prerequisite (read before Task 5)

`CLAUDE.md` on `main` already documents **10** skills, so Task 4 (CLAUDE.md) goes 10→11 cleanly off `main`. But `README.md` and `install.sh` on `main` still document **7** skills — the 7→10 fix lives in the **unmerged PR #6** (branch `docs/readme-ten-skills`). Task 5 is written against the **post-#6 (10-skill)** baseline. **Before doing Task 5, merge PR #6 to `main` and rebase this branch onto `main`** (or cherry-pick #6's two commits in). If #6 is not merged, do Tasks 1–4 now and hold Task 5 until it is. Tasks 1–4 do not depend on #6.

---

### Task 1: Write the parity-check-catalog reference

**Files:**
- Create: `skills/verify-design-match/references/parity-check-catalog.md`

**Interfaces:**
- Consumes: nothing.
- Produces: the reference the SKILL.md points to. Section anchors used by Task 2's prose: "Categories & properties", "Tolerances", "Matching algorithm", "Severity defaults", "Report template".

- [ ] **Step 1: Write the reference file**

Create `skills/verify-design-match/references/parity-check-catalog.md` with EXACTLY this content:

````markdown
# Parity check catalog — verify-design-match

Single-owner reference (only `verify-design-match` uses it). Defines the five comparison
categories, how each property is read from both sides, default tolerances, the element-matching
algorithm, severity defaults, and the report template. Every finding cites its source; nothing
here licenses an aesthetic-taste judgment — this is an objective conformance audit.

## Categories & properties

Each comparison runs five categories. For each property: read the **live** value from the DOM
(`getComputedStyle` / bounding box via the browser tool) and the **Figma** value from the node
(`get_metadata` geometry/props + `get_variable_defs` for token-resolved values), then diff.

| Category | Properties compared | Live source | Figma source |
|---|---|---|---|
| Color | text color, background, border/stroke color, fill | `getComputedStyle` color / background-color / border-color | node fills / strokes, resolved to hex (via variables) |
| Typography | font-family, font-size, font-weight, line-height, letter-spacing, text-align | `getComputedStyle` font-* | text node style props |
| Spacing | padding, gap between paired siblings, margin | `getComputedStyle` padding/margin + measured inter-element gaps | auto-layout padding / itemSpacing, else measured from geometry |
| Layout / position | x/y offset within the frame, alignment, sibling order | element bounding box relative to frame origin | `absoluteBoundingBox` relative to frame |
| Sizing | width, height | element bounding box w/h | node w/h |

## Tolerances

Conform to the **target project's documented rules first** (token system, any documented
allowed deviation); else use these defaults. **State which tolerance/source each finding used.**

- **Sub-pixel:** differences ≤1px are ignored (anti-aliasing / rounding).
- **Color:** compare by hex; treat ΔE ≤ 2 (near-identical rendered color) as a match.
- **Typography:** font-family, font-size, font-weight compared **exact**; line-height /
  letter-spacing use the ≤1px / ≤0.5px sub-pixel rule.
- **Spacing / layout / sizing:** px against the paired node, ≤1px ignored.
- Note fluid/`%`/`auto` live values explicitly rather than forcing a px comparison.

## Matching algorithm (geometry-first, text-anchored)

Goal: pair each live element with its Figma node without guessing.

1. **Normalize.** Render the live page at the frame's exact width so both share one coordinate
   space (scale factor 1). All boxes are expressed relative to the frame origin.
2. **Candidate pairs by geometry.** For each significant Figma node (leaf or labeled
   container), find live elements whose bounding box overlaps it; score overlap by IoU
   (intersection-over-union).
3. **Disambiguate by text.** If the node carries text, prefer the candidate whose visible text
   matches (exact, then closest). Text match breaks geometry ties.
4. **Confidence.** `confidence = f(IoU, text match, type compatibility)`. Pair only when
   confidence ≥ the bar (default **0.6**). Below the bar → **couldn't-align** (emit NO property
   findings for it).
5. **Leftovers.** A Figma node with no live counterpart, or a live element with no Figma
   counterpart, goes to **couldn't-align**, tagged which side is missing (a missing/extra
   element is itself a Must-fix finding, distinct from a low-confidence pairing).

## Severity defaults

Severity = category × magnitude × role (body text / primary CTA outrank decorative chrome).

| Severity | Examples |
|---|---|
| **✗ Must-fix** | element present in Figma but absent live (or extra live element); wrong font-family; large color delta (ΔE > 5) on text/primary surface; size off > 10% or > 24px; wrong sibling order |
| **⚠ Should-fix** | spacing/position off 2–8px; font-size off 1–2px; minor color delta (ΔE 2–5); line-height / letter-spacing drift |
| **✓ within tolerance** | all properties inside the tolerances above |

## Per-category verdict

For each frame, each of the five categories gets one mark:
- **✓** — every paired property in that category is within tolerance.
- **⚠** — only Should-fix drift in that category.
- **✗** — at least one Must-fix in that category.

## Report template

```
# Design-match report — <page/route> ↔ <figma file>
Roll-up: <N> frames · Must-fix <m> · Should-fix <s> · couldn't-align <c>   (no overall score)

## Frame: <frame name> @ <width>px
Color ✓ · Typography ✗ · Spacing ⚠ · Layout ✓ · Sizing ⚠

### Must-fix
- [typography] 'Hero heading' font-family: live `Inter` vs Figma `Söhne` (Δ family) —
  live `.hero h1` / node 12:3 · tol: exact
### Should-fix
- [spacing] 'CTA' padding-top: live `12px` vs Figma `16px` (Δ4px) —
  live `.cta` / node 9:7 · tol: ≤1px default
### Couldn't align
- Figma node 'Badge/new' (14:2) — no live match (confidence 0.31 < 0.6 bar)
- live `.cookie-banner` — no Figma node (present live, absent in design)
```

A clean category says so (`✓`). A frame where no pairs cleared the confidence bar reports that
explicitly (all in couldn't-align) — never a silent pass.
````

- [ ] **Step 2: Verify the reference content**

Run:
```bash
F=skills/verify-design-match/references/parity-check-catalog.md
for s in 'Categories & properties' 'Tolerances' 'Matching algorithm' 'Severity defaults' 'Report template'; do grep -q "$s" "$F" && echo "SECTION_OK: $s"; done
grep -q 'geometry-first, text-anchored' "$F" && echo MATCH_OK
grep -q 'couldn.t-align' "$F" && echo COULDNT_ALIGN_OK
grep -q 'no overall score' "$F" && echo NO_SCORE_OK
for c in 'Color' 'Typography' 'Spacing' 'Layout / position' 'Sizing'; do grep -q "$c" "$F" && echo "CAT_OK: $c"; done
```
Expected: five `SECTION_OK` lines, `MATCH_OK`, `COULDNT_ALIGN_OK`, `NO_SCORE_OK`, and five `CAT_OK` lines.

- [ ] **Step 3: Commit**

```bash
git add -f skills/verify-design-match/references/parity-check-catalog.md
git commit -m "feat: add parity-check-catalog reference for verify-design-match

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

> Note: `skills/` is NOT gitignored (only `docs/` is) — `-f` is harmless here and kept for consistency with the docs tasks. If `git add` warns, drop the `-f`.

---

### Task 2: Write the SKILL.md

**Files:**
- Create: `skills/verify-design-match/SKILL.md`

**Interfaces:**
- Consumes: `references/parity-check-catalog.md` from Task 1 (referenced by relative path).
- Produces: the skill. Later tasks reference the exact skill name `verify-design-match`.

- [ ] **Step 1: Write the skill file**

Create `skills/verify-design-match/SKILL.md` with EXACTLY this content:

````markdown
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
````

- [ ] **Step 2: Verify frontmatter and command-only posture**

Run:
```bash
F=skills/verify-design-match/SKILL.md
head -1 "$F"
grep -q '^name: verify-design-match$' "$F" && echo NAME_OK
grep -q '^disable-model-invocation: true$' "$F" && echo COMMAND_ONLY_OK
grep -qi 'ask until clear' "$F" && echo CLARIFY_OK
for h in 'Preflight' 'When NOT to use' 'Workflow' 'Dependencies'; do grep -q "$h" "$F" && echo "SECTION_OK: $h"; done
```
Expected: `---`, `NAME_OK`, `COMMAND_ONLY_OK`, `CLARIFY_OK`, and four `SECTION_OK` lines.

- [ ] **Step 3: Verify read-only + fail-closed preflight + routing**

Run:
```bash
F=skills/verify-design-match/SKILL.md
test "$(grep -c 'use_figma' "$F")" = "0" && echo NO_WRITE_TOOL_OK || echo "WARN: use_figma appears — verify no write is invoked"
grep -q 'No `figma-use`' "$F" && echo NO_FIGMA_USE_OK
grep -q 'stop and tell the user exactly what to set up' "$F" && echo FAILCLOSED_OK
grep -qi 'Playwright MCP' "$F" && grep -qi 'Playwright CLI' "$F" && echo PLAYWRIGHT_OK
grep -q 'Figma REST API' "$F" && echo FIGMA_FALLBACK_OK
grep -q 'no overall score' "$F" && echo NO_SCORE_OK
grep -q 'parity-check-catalog.md' "$F" && echo CATALOG_REF_OK
for s in 'implement-figma-design' 'page-to-figma' 'critique-figma-design'; do grep -q "$s" "$F" && echo "ROUTE_OK: $s"; done
```
Expected: `NO_WRITE_TOOL_OK`, `NO_FIGMA_USE_OK`, `FAILCLOSED_OK`, `PLAYWRIGHT_OK`, `FIGMA_FALLBACK_OK`, `NO_SCORE_OK`, `CATALOG_REF_OK`, and three `ROUTE_OK` lines. (`use_figma` must not appear; the only `figma-use` mention is the "No `figma-use`" prohibition.)

- [ ] **Step 4: Read the file once for house-style fidelity**

Read top to bottom and confirm by eye: (a) opens with clarify-until-clear, then the preflight; (b) read-only stated plainly (no code edit, no Figma write); (c) workflow is steps 0–5 from spec §4; (d) detection is visual-pass-then-property-pass; (e) no hardcoded framework/design-system/domain; (f) no write tool ever invoked. Fix any drift inline.

- [ ] **Step 5: Commit**

```bash
git add skills/verify-design-match/SKILL.md
git commit -m "feat: add verify-design-match skill (read-only live↔Figma parity audit)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Write ADR 0003 (external tooling dependency)

**Files:**
- Create: `docs/adr/0003-verify-design-match-requires-playwright-and-figma-access.md`

**Interfaces:**
- Consumes: skill name + preflight decision from Task 2.
- Produces: the ADR that Task 4's CLAUDE.md entry references.

- [ ] **Step 1: Write the ADR**

Create `docs/adr/0003-verify-design-match-requires-playwright-and-figma-access.md` with EXACTLY this content:

````markdown
# `verify-design-match` requires Playwright and Figma access (fail-closed)

**Status:** accepted

`verify-design-match` compares a running page against its finished Figma frame(s). It cannot
produce a meaningful report without (a) a real browser to render the page at the frame's width,
screenshot it, and read computed DOM styles, and (b) read access to the Figma design for
geometry, token-resolved properties, and the reference screenshot. We chose to make both a
**hard, fail-closed prerequisite**: if either is missing the skill **stops with setup
instructions** rather than emitting a partial or guessed report. Each capability accepts two
interchangeable providers — browser via **Playwright MCP or CLI**, Figma via **MCP read tools
or REST API + token**.

## Why this is worth recording

The suite's standing convention is that a skill depends only on Figma **MCP tools** and is
otherwise self-contained. ADR 0001 records the first deliberate break (`page-to-figma` needing
the external official Figma plugin); ADR 0002 records a second flavor (P1 depending on sibling
skills). This is a **third flavor**: a hard dependency on **external browser automation**
alongside Figma access, with an explicit **fail-closed** posture and a **dual-provider** (MCP
*or* CLI/REST) fallback for each. A future maintainer might try to "soften" the preflight into a
best-effort degraded mode; this ADR records that the fail-closed gate is deliberate — a partial
parity report is worse than none because it reads as "checked and fine" when it isn't.

## Considered options

- **Fail-closed, dual-provider per capability (chosen)** — require browser AND Figma access;
  accept either provider for each; stop with instructions if either capability is wholly
  absent. Keeps findings trustworthy and the skill usable across MCP-only and CLI/REST setups.
- **Degrade gracefully (rejected)** — e.g. property-only when no browser screenshot, or
  Figma-screenshot-only when no read tools. Rejected: a partial audit silently drops whole
  categories and misreports coverage as conformance.
- **Single provider each (MCP-only) (rejected)** — simpler, but excludes teams that have the
  Playwright CLI or a Figma token but not the MCP servers, for no real benefit.

## Consequences

- The `SKILL.md` opens with a **Preflight** step that confirms both capabilities and halts with
  setup instructions if either is missing — before any frame is processed.
- The skill must **detect which provider is present** (Playwright MCP vs CLI; Figma MCP vs REST)
  and adapt, rather than assuming one.
- The README **Requirements** section and the CLAUDE.md suite entry must state these hard
  dependencies, so users aren't surprised by the preflight halt.
````

- [ ] **Step 2: Verify the ADR**

Run:
```bash
F=docs/adr/0003-verify-design-match-requires-playwright-and-figma-access.md
grep -q '^# `verify-design-match` requires Playwright and Figma access' "$F" && echo TITLE_OK
grep -q '^\*\*Status:\*\* accepted$' "$F" && echo STATUS_OK
grep -q 'fail-closed' "$F" && echo FAILCLOSED_OK
grep -q 'dual-provider' "$F" && echo DUALPROVIDER_OK
for s in 'Why this is worth recording' 'Considered options' 'Consequences'; do grep -q "$s" "$F" && echo "SECTION_OK: $s"; done
```
Expected: `TITLE_OK`, `STATUS_OK`, `FAILCLOSED_OK`, `DUALPROVIDER_OK`, and three `SECTION_OK` lines.

- [ ] **Step 3: Commit**

```bash
git add -f docs/adr/0003-verify-design-match-requires-playwright-and-figma-access.md
git commit -m "docs: ADR 0003 — verify-design-match requires Playwright + Figma access (fail-closed)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Update CLAUDE.md (10 → 11 skills)

**Files:**
- Modify: `CLAUDE.md` (count ten→eleven, suite entry, conventions note)

**Interfaces:**
- Consumes: skill name + behavior from Tasks 1–3.
- Produces: nothing downstream.

- [ ] **Step 1: Update the count in CLAUDE.md**

In `CLAUDE.md`, change the skill count from ten to eleven. Find and replace:
- `ten portable` → `eleven portable`
- `The ten skills form` → `The eleven skills form`

(If the exact phrasings differ slightly, locate the two sentences in the "What this repo is" intro that state the skill count and change "ten" → "eleven" in both. There must be no stale "ten skills" count left.)

- [ ] **Step 2: Add the suite entry in CLAUDE.md**

In the "## The skill suite" list, add this entry immediately after the `critique-figma-design` entry:

```markdown
- **[verify-design-match](skills/verify-design-match/SKILL.md)** — *command-only, running page + Figma frame → parity audit.* A **read-only** check that compares a **running page** against the finished Figma frame(s) it should match and reports, **per breakpoint**, where the implementation diverges — changing nothing (it never edits code and never writes to Figma). Detection is a **visual pass** (screenshot overlay locates diverging regions) then a **property pass** (measured live-DOM-vs-Figma diff); element matching is **geometry-first/text-anchored**, and pairs below the confidence bar go to a **"Couldn't align"** list rather than being guessed. Each comparison is one frame ↔ the page rendered at that frame's width (breakpoint-aware); output is a **per-category verdict** (✓/⚠/✗ for color, typography, spacing, layout, sizing) plus severity-ranked, cited findings — **no overall score**. **Command-only** (`/verify-design-match`, `disable-model-invocation: true`) so it never fires uninvited or collides with `implement-figma-design`. It has a **hard, fail-closed tooling dependency** — Playwright (MCP or CLI) **and** Figma access (MCP read tools or REST + token); it stops if either is missing — making it the second suite skill (after `page-to-figma`) with a hard external-tool dependency. See `references/parity-check-catalog.md` and `docs/adr/0003-verify-design-match-requires-playwright-and-figma-access.md`.
```

- [ ] **Step 3: Update the conventions note in CLAUDE.md**

In the "## Conventions when editing these skills" section, find the bullet that begins "**Don't confuse direction.**" and append this sentence to the END of that bullet's text (inside the same bullet):

```markdown
 A fifth review/QA-type skill, `verify-design-match`, is **command-only** and **read-only**: it compares a *running page* against its *Figma frame* (live ↔ design parity) and never edits either side — distinct from `implement-figma-design` (which builds/fixes code), `page-to-figma` (which writes Figma), and `critique-figma-design` (which checks one frame against rules). Keep its `disable-model-invocation: true` and its read-only posture.
```

- [ ] **Step 4: Verify the CLAUDE.md edits**

Run:
```bash
grep -q 'eleven portable' CLAUDE.md && echo COUNT1_OK
grep -q 'The eleven skills form' CLAUDE.md && echo COUNT2_OK
grep -q 'ten skills form' CLAUDE.md && echo "WARN_ten_remains" || echo NO_STALE_TEN_OK
grep -q 'verify-design-match](skills/verify-design-match/SKILL.md)' CLAUDE.md && echo ENTRY_OK
grep -q 'A fifth review/QA-type skill' CLAUDE.md && echo CONVENTION_OK
```
Expected: `COUNT1_OK`, `COUNT2_OK`, `NO_STALE_TEN_OK`, `ENTRY_OK`, `CONVENTION_OK`. If `WARN_ten_remains` prints, find the remaining "ten skills" count and fix it to "eleven", then re-run.

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: document verify-design-match in CLAUDE.md (10 → 11 skills)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Update README.md + install.sh (10 → 11 skills)

> **PREREQUISITE:** PR #6 (the 7→10 README/installer fix) must be merged to `main` and this branch rebased onto it first — see "Sequencing prerequisite" above. The anchors below assume the post-#6 (10-skill) `README.md` and `install.sh`.

**Files:**
- Modify: `README.md` (overview entry, requirements, structure tree, install count)
- Modify: `install.sh` (SKILLS array, count wording, post-install hint)

**Interfaces:**
- Consumes: skill name + behavior from Tasks 1–4.
- Produces: nothing downstream.

- [ ] **Step 1: Add the README overview entry**

In `README.md`, the "### 3. Standalone Figma paths" table is where the read-only Figma checks live. Add this row to that table, immediately **after** the `critique-figma-design` row:

```markdown
| **[verify-design-match](skills/verify-design-match/SKILL.md)** | running page ↔ Figma *(command-only)* | A **read-only** parity audit: compares a running page against the finished Figma frame(s) it should match and reports, **per breakpoint**, where the implementation diverges — changing nothing. Visual pass (screenshot overlay) locates regions; property pass (measured DOM-vs-Figma diff) quantifies them; matching is geometry-first/text-anchored with a "couldn't align" gap list. Output is a per-category ✓/⚠/✗ verdict + cited findings, **no overall score**. Runs only when you type `/verify-design-match`. *(Requires Playwright + Figma access.)* |
```

- [ ] **Step 2: Update the README pipeline-at-a-glance block**

In the "**Pipeline at a glance:**" code block, add this line immediately after the `critique-figma-design` (`Finished frame …`) line:

```
  Running page+Figma──▶  /verify-design-match  ──▶  per-breakpoint parity report (read-only)
```

- [ ] **Step 3: Update the README Requirements**

In the "## Requirements" section, add this bullet immediately after the `figma-design-to-working-prototype` bullet:

```markdown
- For `verify-design-match`: a **hard, fail-closed** dependency on **both** browser automation (Playwright **MCP or CLI**) **and** Figma access (Figma **MCP read tools or REST API + token**). The skill stops with setup instructions if either is missing — see [docs/adr/0003-verify-design-match-requires-playwright-and-figma-access.md](docs/adr/0003-verify-design-match-requires-playwright-and-figma-access.md).
```

- [ ] **Step 4: Update the README structure tree**

In the "### How the skills are structured" code block, add these lines immediately after the `critique-figma-design/` block and before the `harden-doc/` block:

```
├── verify-design-match/
│   ├── SKILL.md                             # read-only live↔Figma parity audit (/verify-design-match)
│   └── references/
│       └── parity-check-catalog.md          # categories, tolerances, matching algorithm, report template
```

- [ ] **Step 5: Update README install-count wording**

In the "## Install" section, change both "ten skills" references to "eleven skills":
- `Installs all ten skills` → `Installs all eleven skills`
- `remove the ten skills` → `remove the eleven skills`
- In Option C: `Copy the ten directories` → `Copy the eleven directories`

(If a phrase isn't present verbatim, find the nearest "ten" referring to the skill/directory count in the Install section and change it to "eleven". Do not touch unrelated numbers.)

- [ ] **Step 6: Update install.sh**

In `install.sh`:

(a) Add `verify-design-match` to the `SKILLS` array, immediately after the `critique-figma-design` line:
```bash
  "verify-design-match"
```

(b) Change the uninstall comment `# remove the ten skills from the target` → `# remove the eleven skills from the target`.

(c) In the final post-install `echo` block, append `verify-design-match` to the command-only hint line so it reads:
```bash
echo "Run the command-only skills:  /critique-figma-design  •  /verify-design-match  •  /harden-doc <doc>  •  /biz-review <doc>"
```

- [ ] **Step 7: Verify README + installer**

Run:
```bash
bash -n install.sh && echo INSTALL_SYNTAX_OK
grep -q '"verify-design-match"' install.sh && echo INSTALL_ARRAY_OK
grep -q '/verify-design-match' install.sh && echo INSTALL_HINT_OK
grep -q 'verify-design-match](skills/verify-design-match/SKILL.md)' README.md && echo README_ENTRY_OK
grep -q 'parity-check-catalog.md' README.md && echo README_TREE_OK
grep -q 'eleven skills' README.md && echo README_COUNT_OK
grep -q '0003-verify-design-match' README.md && echo README_ADR_OK
for s in $(grep -oE 'skills/[a-z-]+/SKILL.md' README.md | sort -u); do [ -f "$s" ] || echo "MISSING $s"; done; echo LINKS_CHECKED
```
Expected: `INSTALL_SYNTAX_OK`, `INSTALL_ARRAY_OK`, `INSTALL_HINT_OK`, `README_ENTRY_OK`, `README_TREE_OK`, `README_COUNT_OK`, `README_ADR_OK`, and `LINKS_CHECKED` with no `MISSING` lines.

- [ ] **Step 8: Commit**

```bash
git add README.md install.sh
git commit -m "docs: add verify-design-match to README + installer (10 → 11 skills)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Self-Review

**1. Spec coverage** (spec decision → task):
- Read-only parity report (1) → Task 2 body ("read-only", "changes nothing") + Step 3 `NO_WRITE_TOOL_OK`/`NO_FIGMA_USE_OK`. ✓
- Command-only (2) → Task 2 frontmatter + Step 2 `COMMAND_ONLY_OK`; CLAUDE convention (Task 4.3). ✓
- Detection = visual then property pass (3) → Task 2 workflow §3–4 + Task 1 report/algorithm; Step 4 eye-check. ✓
- Matching geometry-first/text-anchored + couldn't-align (4) → Task 1 "Matching algorithm" + Task 2 §4 + Step 2 `MATCH_OK`/`COULDNT_ALIGN_OK`. ✓
- Per-frame, frame-width render (5) → Task 1 normalize step + Task 2 §2/§5. ✓
- Five categories, per-category verdict, no score (6) → Task 1 categories + verdict + template, Task 2 §5; Steps `CAT_OK`/`NO_SCORE_OK`. ✓
- Every finding measured & cited (7) → Task 1 report template fields + Task 2 §4. ✓
- Tolerances conform-to-target, else defaults (8) → Task 1 "Tolerances". ✓
- Severity from category×magnitude×role (9) → Task 1 "Severity defaults". ✓
- Clarify-until-clear inputs (10) → Task 2 opener + Step 2 `CLARIFY_OK`. ✓
- Fail-closed preflight: Playwright (MCP/CLI) + Figma (MCP/REST) (11) → Task 2 Preflight + Step 3 `FAILCLOSED_OK`/`PLAYWRIGHT_OK`/`FIGMA_FALLBACK_OK`; ADR 0003 (Task 3). ✓
- Files (§5): SKILL.md (Task 2), parity-check-catalog.md (Task 1), ADR 0003 (Task 3), CLAUDE.md (Task 4), README.md + install.sh (Task 5). ✓
- Routing/When-NOT (§3) → Task 2 "When NOT to use" + Step 3 three `ROUTE_OK`. ✓

**2. Placeholder scan:** No "TBD"/"TODO"/"handle edge cases"/"similar to". Full file content inline in Tasks 1–3; edit anchors are exact strings in Tasks 4–5. The only conditional language is the spec-honest "if the exact phrasing differs, locate the count sentence" guidance in Tasks 4.1 / 5.5, which still names the exact target string — not a placeholder. ✓

**3. Type consistency:** Skill name `verify-design-match` identical across frontmatter (Task 2), catalog title (Task 1), ADR (Task 3), CLAUDE entry (Task 4.2), README entry + install array (Task 5). Reference path `references/parity-check-catalog.md` identical in Task 1 (created), Task 2 (referenced), README tree (Task 5.4). ADR filename `0003-verify-design-match-requires-playwright-and-figma-access.md` identical in Task 3 (created), CLAUDE entry (Task 4.2), README requirements (Task 5.3). Sibling routing names (`implement-figma-design`, `page-to-figma`, `critique-figma-design`) spelled consistently. Category names (Color/Typography/Spacing/Layout/Sizing) identical between catalog tables, verdict, and verify checks. ✓

**Implementer notes:**
- `docs/` is gitignored but tracked docs were force-added (existing specs/ADRs); use `git add -f` for the ADR (Task 3) as shown. `skills/` is NOT ignored.
- Tasks 1–4 are independent of PR #6 and can run immediately on this branch. Task 5 requires the post-#6 (10-skill) README/installer baseline — merge #6 and rebase first.
