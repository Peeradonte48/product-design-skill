# Product-Design Skill Suite — Improvement Roadmap

> Goal: a skill suite for a **product designer who works across design *and* business**,
> whose **primary tool is Figma**. This doc audits the current seven skills against that
> persona and lays out a prioritized plan to close the gaps.

---

## 1. The guiding principle

**The designer designs the Figma screens themselves — that is their craft. Do not
automate it.** The suite's job is to handle everything *around* the design that the
designer can't, or doesn't want to, do by hand:

- turning a design/flow into a **working code prototype** (behavior they can't draw),
- **documenting** flows and IA,
- **reasoning about the business** (value, scope, demand, metrics, the brief),
- **handing off** to engineering.

So the skills **augment around** a self-made Figma design — they never replace the act of
designing. This is why the suite correctly reaches into code and docs: those are the
non-Figma jobs.

```
  designer designs in Figma  ──►  [skills handle the rest]
                                   ├─ flow/IA → docs
                                   ├─ design/flow → code prototype
                                   ├─ business: challenge · clarify · brief
                                   └─ handoff to eng
```

---

## 2. Current coverage map

Seven skills, classified by what they **output** — judged against the principle above
(does it do a *non-design* job the designer needs, without stepping on their craft?):

| Skill | Input → Output | Fit |
|---|---|---|
| `use-case-narrative-to-prototype` | narrative → **code prototype** | ✅ Core — behavior the designer can't draw |
| `implement-figma-design` | Figma → **code** | ✅ Core — production handoff |
| `page-to-figma` | running page → **Figma** | ✅ Useful — reverse-engineer live product to edit |
| `figjam-to-use-case-narrative` | FigJam → **doc** | ✅ Core — documentation |
| `figjam-sitemap-to-spec` | FigJam → **doc** | ✅ Core — documentation |
| `biz-review` | doc → **scope decisions** | ✅ Core — business challenge |
| `harden-doc` | doc → **resolved doc** | ✅ Core — clarification |

**The code-output skills are a strength, not a mismatch.** They cover exactly the work the
designer can't self-serve in Figma. *(An earlier draft of this roadmap proposed a
`narrative-to-figma-design` generator and ranked it P0 — that was wrong. Generating Figma
screens steps on the designer's own job. It has been dropped.)*

---

## 3. Where the real gaps are

With Figma-design-creation correctly left to the designer, the holes are all on the
**non-design** side:

### Business craft — only reactive, never generative
- ✅ `biz-review` *challenges* the case; `harden-doc` *clarifies* it.
- ❌ Nothing **produces** the artifact the designer-in-business actually ships: a PRD /
  design brief with problem, target user, demand evidence, success metrics, scope.
  This is the clearest thing the designer can't easily do rigorously by hand.

### Prototyping — two halves that don't yet meet
- `implement-figma-design` gives **pixels** (static, pixel-perfect).
- `use-case-narrative-to-prototype` gives **behavior** (from a doc, generic visuals).
- ❌ No single path turns a **finished Figma design + its flow** into a **working,
  clickable prototype** that is both pixel-faithful *and* behaviorally real — the thing
  a designer most wants to test and hand off.

### Design evaluation — absent, but tread carefully
- ❌ No skill gives a **second-eye critique** of a Figma frame.
- ⚠️ Caveat: critique borders on the designer's own craft. Frame it as a **self-check /
  checklist tool** (a11y, contrast, consistency, hierarchy), not a taste-maker.

---

## 4. Proposed new skills (prioritized)

### P0 — `spec-to-brief` (PRD / design-brief generator) — ✅ SHIPPED
**Status:** drafted and wired into `CLAUDE.md`. `skills/spec-to-brief/SKILL.md` +
`references/product-brief-template.md`. **Model-invocable** (decided: producing ≠
reviewing); boundary with `figjam-sitemap-to-spec` is builder-spec vs stakeholder-brief;
no landscape research of its own (pulls from a prior `/biz-review` if present).

**Input → output:** flow/spec (+ what survived `biz-review`/`harden-doc`) → **stakeholder
product brief**.

Why first: the strongest **design↔business bridge**, and the one job the designer genuinely
can't self-serve. The suite can challenge and clarify a business case but can't *produce*
one. Generates: problem, target user, demand evidence, success metrics, scope decisions.
Composes cleanly **after** the two doc-review commands (run them as gates, then write the
brief from what's left). Needs no Figma; can use `deep-research`/WebSearch for landscape.

### P1 — `figma-design-to-working-prototype` — ✅ SHIPPED
**Status:** shipped. Thin orchestrator, **behavior-first** (skeleton via
`use-case-narrative-to-prototype` → in-place **re-skin** via `implement-figma-design`),
two-phase verification gate, proposed-then-confirmed frame↔step mapping, model-invocable with
a both-inputs-required trigger. Decisions in
`docs/superpowers/specs/2026-06-17-figma-design-to-working-prototype-design.md`; cross-skill
dependency in `docs/adr/0002-p1-composes-sibling-suite-skills.md`.

**Input → output:** finished Figma design **+** its flow/UCN → **pixel-faithful *and*
behaviorally real** clickable prototype.

Why: bridges the two prototype halves that don't currently meet. The designer has drawn
the screens (pixels) and has the flow (behavior) — this skill fuses them into one working
artifact to test and hand off, instead of running two skills that don't compose. Could be
built as an explicit composition of `implement-figma-design` + `use-case-narrative-to-prototype`
rather than a from-scratch skill.

### P2 — `critique-figma-design` (self-check, not taste-maker) — ✅ SHIPPED
**Status:** shipped. Command-only, read-only Figma self-check. Four measured categories +
evidence-anchored Nielsen-10 heuristic pass (separate section), severity-first, no quality
score. Contrast via screenshot-pixel-sampling; conform-to-target thresholds; modality-aware
touch-targets; evidenced role-signals; token-gated spacing. Decisions in
`docs/superpowers/specs/2026-06-17-critique-figma-design-design.md`.

**Input → output:** Figma frame (MCP reads only) → **objective checklist report**.

Why: a second pair of eyes for the things that are *checkable*, not subjective —
accessibility, contrast ratios, touch-target sizes, design-system consistency, obvious
hierarchy breaks. Deliberately scoped to *not* dictate aesthetic taste (that's the
designer's). Pure reads (`get_design_context`, `get_screenshot`, `get_variable_defs`) — no
`figma-use` needed. Lower priority precisely because it sits closest to the designer's own
craft.

---

## 5. Fixes to existing skills

1. **Add a "no codebase yet" mode.** ✅ **Done** — both `use-case-narrative-to-prototype`
   (alongside P1) and `implement-figma-design` now scaffold a fresh standalone app gracefully
   when there's no target repo (a pure designer usually has none) instead of hunting for a
   stack to conform to. (`implement-figma-design`'s scaffold also sets up the
   browser/screenshot tooling its diff-based verification needs.)
2. **Keep the code skills framed as the designer's allies,** not eng-only tools — the
   value is that the *designer* gets a clickable thing and a clean handoff.
3. **Update `CLAUDE.md`** when new skills land (suite description, pipeline, contracts).

---

## 6. Compose, don't build
- **Landscape / competitive research** feeding `biz-review` or `spec-to-brief`: lean on
  the existing `deep-research` plugin; document the handoff.
- **User-research synthesis** (interview notes → insights): check existing plugins before
  building suite-native.

---

## 7. Suggested sequence
1. **P0 `spec-to-brief`** — completes the business half (generative, not just reactive).
2. **P1 `figma-design-to-working-prototype`** — fuses pixels + behavior into one artifact.
3. **Existing-skill fixes** (no-codebase mode) — fold in alongside.
4. **P2 `critique-figma-design`** — the self-check tool, scoped to objective checks.

Net effect: the designer keeps full ownership of designing in Figma, and the suite covers
everything around it — **docs, code prototypes, business brief, handoff** — which is
exactly the work a Figma-primary, design-and-business product designer needs offloaded.
