---
name: harden-doc
description: >-
  Interview the user relentlessly about a plan, spec, or design doc until every branch
  of the decision tree is resolved and shared understanding is reached (doc → hardened
  doc). Invoke explicitly with /harden-doc <path-or-topic> when a plan, product spec,
  or UCN should be stress-tested by questioning before it gets built. It resolves
  ambiguity and missing decisions; it does not judge business value (that's /biz-review)
  and it does not build anything.
disable-model-invocation: true
argument-hint: <doc path or plan to grill>
---

# Harden Doc (resolve every branch of the decision tree)

Interview the user relentlessly about every aspect of the plan, spec, or design at hand
until you reach a **shared understanding** — every branch of the decision tree walked,
every dependency between decisions resolved one-by-one. The output is not a verdict; it
is a plan with no unresolved ambiguity left in it.

This skill is **command-only**: it runs when the user types `/harden-doc`, never from
natural-language triggering. It is a fork of the standalone `grill-me` skill, renamed
and adapted for this suite. It pairs naturally with the suite's documents: harden a
**UCN** before `use-case-narrative-to-prototype` builds it, a **product spec** after
`figjam-sitemap-to-spec` writes it, or any plan before implementation. It is the
generalized form of the **clarify-until-clear** rule every suite skill carries — the
user invokes it when they want the questioning itself, as a session.

If the command was given an argument (a file path or topic), start there; if not, ask
what document or plan to harden.

## Method

- **One question at a time.** Ask, wait for the answer, then ask the next. Never batch a
  wall of questions — each answer changes what's worth asking next.
- **Recommend with every question.** For each question, provide your recommended answer
  and the reason. The user should always be choosing between positions, not generating
  from a blank.
- **Walk the tree, don't orbit it.** Resolve decisions in dependency order: settle the
  decisions other decisions hang on first, then descend into each branch until it
  terminates. Track which branches remain open and say so.
- **Explore before you ask.** If a question can be answered by exploring the codebase or
  the document itself, explore instead of asking. Spend the user's attention only on
  things the artifacts cannot answer.
- **Stop at shared understanding.** You're done when neither of you can name an
  unresolved decision. Close by restating the decisions made, in order, so the shared
  understanding is written down — offer to update the plan/spec document with them.

## When NOT to use

- The user wants the **business case** challenged (is this worth building? right
  problem? smallest wedge?) — that's `/biz-review`, this suite's other doc-review
  command. Hardening sharpens a plan's decisions; biz-review questions its premise.
- The user just wants a question answered or a doc summarized — no session needed.
