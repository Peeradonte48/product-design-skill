# Product Brief — building blocks (flexible guidance)

This is **guidance, not a rigid template.** A product brief is a buy-in document: enough
for a stakeholder to understand the problem, believe there's demand, agree on success, and
sign off on scope — without reading the design file. Include the blocks the inputs ground;
drop the ones they don't; reorder freely. The two non-negotiables: **never fabricate a
metric or a demand claim**, and **keep it in the user's language**, not implementation
detail.

A useful default order:

---

## `# <Feature/Product> — Product Brief`

**One-liner.** A single sentence a stakeholder could repeat: what this is and who it's for.

## Problem

The problem from the **user's** perspective — what they're trying to do and where it
breaks today. Concrete, not abstract. If the source spec/UCN frames the problem, ground it
there. Avoid leading with the solution.

## Target user

Who specifically has this problem. Push past categories ("enterprises", "users") to a
nameable person: role, what they're responsible for, what a win looks like for them.
- **Evidence marker:** if the specificity came from the user, say so. If it's an
  assumption, label it `(assumed — confirm)`. Never invent a persona detail.

## Demand evidence

Why we believe this is wanted — **behavior, not interest.** Workarounds people use today,
money or time they spend, requests, churn, observed pain. "That's interesting" and
waitlists are not evidence.
- If there is no real evidence yet, write that plainly and move the question to **Open
  Questions**. Do not dress interest up as demand.

## Goals & success metrics

What outcome this moves and how you'll know. Each metric: a name, a current baseline (if
known), and a target.
- Every number is **sourced or Open.** If the user can't give a baseline/target, list the
  metric and mark the value `(TBD — needs a number)` under Open Questions rather than
  guessing one.
- Prefer 1–3 real metrics over a long list of vanity numbers.

## Solution overview

What the product does, from the user's perspective — the shape of the experience, not the
tech. Link to where it lives: the Figma frame, the UCN, the sitemap spec. Don't re-describe
pixels the design already holds.

## Key flows

The core journeys, by name, each linked to its artifact (UCN file, FigJam flow, sitemap
node). One line on what each flow accomplishes. This is the bridge from brief to build.

## Scope

Three explicit lists — this is what gets signed off:
- **In scope** — what this delivers.
- **Explicitly out** — what it deliberately does not, and why (prevents creep).
- **Deferred** — wanted, but not now.
If a `/biz-review` produced a scope decision record, copy it here verbatim. Otherwise state
the scope the artifact implies and mark it `(unconfirmed — gate with /biz-review)`.

## Risks & open questions

What could make this fail or stall, and every unanswered question surfaced along the way —
including the business inputs that came back empty (missing evidence, TBD metrics,
unconfirmed users). This section is where honest gaps live; a brief with no open questions
is usually hiding them.

## Handoff / next steps

The concrete next actions: gate with `/biz-review` and `/harden-doc` if not already done;
design the screens in Figma; then build via `use-case-narrative-to-prototype` (behavioral
prototype) or `implement-figma-design` (pixel-perfect from a finished design). End on one
clear owner-able next step, not a strategy.
