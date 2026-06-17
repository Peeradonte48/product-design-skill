# `verify-design-match` — design spec

**Date:** 2026-06-17
**Status:** approved (pending implementation)
**Branch:** `feat/verify-design-match`

---

## 1. Problem

The suite can build a Figma design into code (`implement-figma-design`), push code into Figma
(`page-to-figma`), and self-check a single Figma frame (`critique-figma-design`). What it
*can't* do is tell a designer or engineer **how faithfully a page that's already shipped
matches the design it was built from.** `implement-figma-design` diffs the running UI against
Figma, but only as a step *while building*, and it edits code to close the gap.

`verify-design-match` fills that gap as a standalone, **read-only design-QA audit**: given a
**running page** and the **finished Figma frame(s)** it should match, it reports — per
breakpoint — exactly where the implementation diverges from the design, and changes nothing.

It honors the suite's guiding principles: **never guess** (an unresolvable element pairing is
reported, not invented) and **match every breakpoint** (each Figma frame is compared against
the page rendered at that frame's width).

---

## 2. Locked decisions

1. **Read-only parity report.** The skill compares and reports. It **never edits code and
   never edits Figma.** Fixing the code is `implement-figma-design`'s job; updating the design
   to match shipped code is out of scope entirely.

2. **Command-only.** Frontmatter carries `disable-model-invocation: true`; it fires only on
   explicit `/verify-design-match`. Rationale: its inputs (a Figma link + a running app) are
   exactly what `implement-figma-design` reacts to — a model-invocable parity check would
   collide with the build path and risk firing a report when the user wanted a build (or vice
   versa). Consistent with the suite's other review skills (`critique-figma-design`,
   `harden-doc`, `biz-review`), all command-only.

3. **Detection = both passes, in order.** Divergence is found by a **visual pass** then a
   **property pass**:
   - **Visual pass** — screenshot the live page (at frame width) and overlay it against the
     Figma reference screenshot to locate diverging *regions*.
   - **Property pass** — on each diverging region, pair elements and diff **measured values**
     (live-DOM computed styles vs Figma node properties) so each finding states *what* differs
     and *by how much*, not merely "this region looks off."

4. **Element matching = geometry-first, text-anchored.** Both artifacts are normalized to the
   frame width; live elements are paired to Figma nodes by **bounding-box position + matching
   text content**. Pairs that cannot be resolved confidently are **never guessed** — they go to
   a **"Couldn't align"** list in the report (a coverage gap, stated explicitly).

5. **Unit of work = per Figma frame, page rendered at that frame's width.** Each comparison is
   one Figma frame ↔ the live page rendered at the frame's width. Multiple frames (e.g.
   mobile + tablet + desktop) produce **one report section per frame**, catching
   breakpoint-specific drift. If the user supplies many frames (>~6), confirm scope rather
   than silently grinding through all of them (clarify-until-clear).

6. **Five categories, per-category verdict, no overall score.**
   - Categories: **color · typography · spacing · layout/position · sizing.**
   - Each frame section opens with a **per-category verdict line** — ✓ (match) / ⚠ (minor
     drift) / ✗ (fails) for each of the five — followed by **severity-ranked findings**, then
     the **"Couldn't align"** list.
   - **No single match score / percentage.** A headline "94% match" hides critical mismatches
     behind a high average and implies false precision. Per-category ✓/⚠/✗ gives an at-a-glance
     status without that failure mode (consistent with `critique-figma-design`'s no-score
     stance).

7. **Every finding is measured & cited.** A finding MUST cite **element (live selector / Figma
   layer + node id) · property · live value · Figma value · delta · category · severity.** No
   bare aesthetic finding — this is a conformance audit, not a taste review (that's
   `critique-figma-design`, and even there taste is out of scope).

8. **Tolerances conform to target first, else defaults.** Use the target project's documented
   rules (token system, allowed deviations) first; else defaults: **sub-pixel ≤1px ignored**
   (anti-aliasing/rounding); **color** compared by hex, with a small ΔE tolerance for
   near-identical rendered colors; **font-size / font-weight exact**; spacing/layout/sizing in
   px against the paired node. Each finding states which tolerance/source it used.

9. **Severity** is derived from category + magnitude + role — e.g. a body-text font-family or
   size mismatch (legibility/brand) outranks a 2px shadow-offset drift. Defaults fixed at the
   implementation-plan stage in `references/parity-check-catalog.md`.

10. **Clarify-until-clear inputs.** Needs: the live page (URL/route, or how to run the app),
    the Figma frame(s), the **frame↔route/state pairing**, and any auth/seed state to reach the
    page in the right state. Anything ambiguous → stop and ask; never guess a pairing or a
    state.

11. **Hard tooling prerequisites — fail-closed preflight (decision added at user request).**
    Before any comparison the skill verifies **both** capabilities are present, and if **either**
    is missing it **stops and tells the user exactly what to set up** — it never emits a
    partial or degraded report.
    - **Browser automation (required):** a Playwright **MCP server** *or* the Playwright
      **CLI** (`npx playwright` / an installed `@playwright/test`). Used to render the page at
      frame width, capture screenshots, and extract computed DOM styles. The skill detects
      which is available and adapts.
    - **Figma access (required):** the Figma **MCP read tools** (`get_metadata`,
      `get_variable_defs`, `get_screenshot`) *primary*; **Figma REST API + personal-access
      token** (via CLI/`curl`) as the fallback "if any" path, since there is no general-purpose
      official Figma CLI. One of the two is required.
    This is a hard external dependency in the spirit of `page-to-figma`'s dependency on the
    official Figma plugin — it warrants an **ADR** (`docs/adr/0003-verify-design-match-requires-
    playwright-and-figma-access.md`).

---

## 3. When NOT to use (routing)

- Building a Figma design into code, or **fixing** code to match Figma → `implement-figma-design`.
- Pushing running code into Figma / updating the design to match shipped code → `page-to-figma`.
- Self-checking a **single** Figma frame against rules (a11y, tokens, heuristics) →
  `critique-figma-design`.
- Aesthetic preference ("which looks better?") — out of scope; this is an objective
  conformance audit only.

---

## 4. Workflow (as it will appear in SKILL.md)

0. **Preflight (fail-closed).** Verify browser automation (Playwright MCP or CLI) **and** Figma
   access (MCP read tools or REST + token) are available. If either is missing, stop with exact
   setup instructions. (Decision 11.)
1. **Resolve inputs & conventions.** Collect the live page + run/auth/state details, the Figma
   frame(s), and the frame↔route/state pairing. Read the target project's tolerance/token rules
   if any (else note defaults apply). Ask if anything is ambiguous. Confirm scope if many frames.
2. **Per frame — pull both sides.** Figma: `get_metadata` + `get_variable_defs` (geometry +
   properties) and `get_screenshot` (reference image). Live: render the page **at the frame's
   width**, capture a full screenshot, extract computed DOM styles.
3. **Visual pass.** Overlay the two screenshots; locate diverging regions.
4. **Property pass.** Pair elements geometry-first / text-anchored; diff measured values on the
   diverging regions; record element · property · live value · Figma value · delta · tolerance/
   source. Send unresolved pairs to "Couldn't align."
5. **Assemble the frame's section** — per-category ✓/⚠/✗ verdict line, severity-ranked findings,
   then "Couldn't align." Repeat per frame; top the report with a one-line roll-up.

---

## 5. Scope of this branch

**Ships:**
- `skills/verify-design-match/SKILL.md` — the skill (command-only frontmatter).
- `skills/verify-design-match/references/parity-check-catalog.md` — single-owner reference: the
  five categories, default tolerances + how each property is read from both sides, the
  geometry-first/text-anchored matching algorithm, the severity defaults, and the report
  template. (Not part of any shared contract.)
- `docs/adr/0003-verify-design-match-requires-playwright-and-figma-access.md` — the external
  tooling dependency decision.
- `CLAUDE.md` — 10 → 11 skills: suite entry; note it is read-only, command-only, and the second
  skill (after `page-to-figma`) with a hard external-tool dependency.
- `README.md` — add to the Skills overview (likely a new "design QA" grouping or under
  standalone paths) and to Requirements (Playwright + Figma access).
- `install.sh` — add `verify-design-match` to the `SKILLS` array.

**Out of scope:**
- Any code edit or Figma write (read-only).
- Any auto-trigger (command-only).
- An overall match score / percentage.
- Fixing the divergences it finds (routes to `implement-figma-design`).
- Aesthetic / taste judgment (routes to `critique-figma-design` for rule-based, or nowhere for
  pure preference).

---

## 6. Vocabulary (canonical terms — defined in SKILL.md)

- **parity finding** — a divergence citing element · property · live value · Figma value ·
  delta · category · severity · tolerance source; objective.
- **visual pass** — screenshot overlay that locates diverging regions (the *where*).
- **property pass** — measured per-property diff on a region (the *what* and *how much*).
- **couldn't-align** — a live element / Figma node that could not be confidently paired;
  reported as a coverage gap, never guessed into a finding.
- **per-category verdict** — ✓ / ⚠ / ✗ for color, typography, spacing, layout, sizing, per
  frame; the at-a-glance status that replaces a numeric score.
- **frame-width render** — the live page rendered at a Figma frame's exact width so the two are
  compared apples-to-apples at that breakpoint.

---

## 7. Open questions

None blocking. The implementation-plan stage will fix: the exact default tolerance per
property, the severity-default table, the precise matching heuristic (position weighting vs
text-anchor priority, and the confidence bar below which a pair becomes "couldn't align"), and
the report template wording — all in `references/parity-check-catalog.md`.
