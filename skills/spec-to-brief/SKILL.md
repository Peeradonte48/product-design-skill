---
name: spec-to-brief
description: >-
  Turn a product spec, use-case narrative, sitemap, or design idea into a
  stakeholder-ready product brief / PRD-lite markdown document (spec → brief). Use this
  skill WHENEVER the user wants the business case written up for buy-in — a PRD, product
  brief, one-pager, or "make the case" doc — even if they don't say "brief." Triggers:
  "write a PRD from this spec", "turn this flow into a product brief", "make the
  stakeholder case for this <file>", "draft a one-pager for this feature", "I need a brief
  to get sign-off". It SYNTHESIZES a business artifact from what already exists; it does not
  challenge the premise (that's /biz-review) or interview to resolve ambiguity (that's
  /harden-doc), and it does not design or build anything.
---

# Spec → Product Brief

Turn a product spec, use-case narrative (UCN), FigJam sitemap spec, or a described idea
into a **stakeholder-ready product brief** — a PRD-lite the designer can use to get
buy-in, align a team, and frame the work before it's built. The brief answers, in the
user's language: what problem, for whom, what evidence there's demand, what success looks
like, what's in and out of scope, and where the design lives.

This skill is the suite's **generative** business artifact. It composes with the two
doc-review commands: run `/biz-review` (challenge premise/demand/scope) and `/harden-doc`
(resolve ambiguity) **first** as gates, then this skill writes up what survived. It reads
the suite's own outputs — a `figjam-sitemap-to-spec` spec, a `figjam-to-use-case-narrative`
UCN — as well as a plain idea described in conversation. It produces markdown only; the
designer designs the screens in Figma themselves, and the build skills
(`use-case-narrative-to-prototype`, `implement-figma-design`) take it from there.

## Before you proceed — ask until clear (but never fabricate)

A brief is a business document, and the most damaging failure is a **confident, invented
fact** — a made-up success metric, a fictional user, or "demand evidence" that's really
just interest. A design artifact (a flow, a sitemap, a frame) tells you *what the product
does*, never *whether anyone needs it* or *how you'll measure it*. So:

- **Synthesize freely** from what the artifacts actually say (problem framing, flows,
  pages, scope decisions already recorded).
- **Ask — don't invent — the business inputs the artifacts can't contain:** the target
  user with specificity, the evidence of real demand (behavior, not "that's interesting"),
  the business goal, and the success metric. Batch these into as few rounds as possible.
- If the user can't supply a metric or evidence, **say so in the brief** under Open
  Questions rather than writing a plausible-sounding number. An honest gap beats a
  fabricated certainty.

## Workflow

### 1. Gather the inputs

Read the source artifact in full (the spec / UCN / sitemap, or the conversation if the
idea is only described). If a `/biz-review` or `/harden-doc` pass produced recorded
decisions (a scope table, a premise verdict, resolved branches), read those too and treat
them as settled — the brief reports them, it doesn't re-open them. If you're in a repo,
skim its CLAUDE.md and any related specs/ADRs so the brief uses the project's real
vocabulary and doesn't contradict prior decisions.

### 2. Find the business gaps, then ask for them

Map what you have against the brief's building blocks (see
`references/product-brief-template.md`). A design/flow artifact will usually ground the
**problem**, **solution overview**, **key flows**, and often **scope**, but leave the
**target user evidence**, **demand evidence**, **business goal**, and **success metrics**
empty. Ask the user for exactly those — one batched round, specific questions, each with a
recommended starting answer where you can infer one. Do not proceed to write a section you
had to guess; mark it Open instead.

### 3. Write the brief

Write the document using the **flexible guidance** in
`references/product-brief-template.md` — it lists the building blocks of a good brief; it
is **not** a rigid template. Adapt it:

- Include the sections the inputs actually ground; drop ones that don't apply; add others
  the work calls for. Section set and order are your call per brief.
- Keep it in the **user's / stakeholder's** language — problem and solution from the
  user's perspective, not implementation detail. This is a buy-in doc, not an eng ticket.
- Pull scope (in / explicitly out / deferred) straight from a `/biz-review` record if one
  exists; otherwise state the scope the artifact implies and flag it as unconfirmed.
- Every metric and demand claim is either **sourced** (say from where) or listed under
  **Open Questions** — never asserted bare.
- Link to where the design and flows live (Figma frame, UCN file, sitemap spec) rather
  than re-describing visuals.
- One brief per feature/product. Name the file `<feature-or-product>-brief.md` and title
  it `# <Feature/Product> — Product Brief` (ask for the name if it isn't obvious).

### 4. Confirm output location and report coverage

Before writing the file, confirm the output directory with the user (a common convention
is a `docs/briefs/` folder, but don't assume it — ask). After writing, report what you
**grounded** in the source artifacts, what you got from the user, and what's still **Open**
so they can fill it. Note the natural next steps: gate it with `/biz-review` and
`/harden-doc` if not already done, design the screens in Figma, then hand to
`use-case-narrative-to-prototype` or `implement-figma-design`.

## When NOT to use

- The user wants the **premise, demand, or scope challenged** before committing — that's
  `/biz-review`. Run it first; this skill writes up what survives, it doesn't pressure-test.
- The user wants **ambiguity or open decisions resolved** one-by-one — that's
  `/harden-doc`. Harden first, then brief.
- The user wants a **use-case narrative** (actor / steps / extensions) rather than a
  business brief — that's `figjam-to-use-case-narrative`.
- The user wants the thing **built or designed** — that's the build skills; the designer
  owns the Figma design itself.

## Reference files

- `references/product-brief-template.md` — flexible guidance on the building blocks of a
  good product brief (problem, target user, demand evidence, goals & metrics, solution,
  scope, risks, handoff). This is the skill's own reference (not a shared contract) —
  adapt it per brief rather than following it verbatim.
