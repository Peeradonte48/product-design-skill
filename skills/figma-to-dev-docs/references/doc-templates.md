# Output documents — formats (single-owner guidance)

Single-owner reference for `figma-to-dev-docs`. Three files per feature, written to a confirmed
per-feature folder: `PRD.md`, `spec.md`, `test-cases.md`. These are **guidance** — adapt per
feature; the invariants (traceability ids, never-fabricate, no pixel geometry) are not optional.

## `PRD.md` — developer-facing build context (NOT a buy-in brief)

Lean context that tells an AI developer *why / who / what scope* so they build the right thing. This
is **not** a stakeholder buy-in pitch — that is `spec-to-brief`'s *Product brief*; point there for
sign-off. Building blocks:

- **One-liner** — what this feature is, in one sentence.
- **Problem** — what the user is trying to do and where it breaks today.
- **Target user** — who specifically; label assumptions `(assumed — confirm)`.
- **Scope** — **In** / **Explicitly out** / **Deferred**.
- **Success signal** — at least one; **sourced or `(Open)`**. Never fabricate a number.
- **Solution overview** — the shape of the feature these screens deliver; link to the Figma frame.
- **Screen inventory** — each screen/state in the confirmed mapping, one line each.
- **Open questions** — every parked unknown.
- **Handoff** — next steps (`/spec-to-brief` for a buy-in brief; `implement-figma-design` to build).

## `spec.md` — spec-driven (one file, three sections)

### 1. Requirements
Numbered EARS-style functional requirements, grouped per screen/feature, each with an id:

```
REQ-1 — WHEN the user taps "Save", the system SHALL persist the form and show a success toast.
REQ-2 — WHILE a save is in flight, the system SHALL disable "Save" and show a spinner.
```

Keep them **terse** — no inline acceptance-criteria bullets. The Gherkin scenarios in
`test-cases.md` are the acceptance criteria (one behavioral source of truth, written once).

### 2. Design
Screens, components, states, a data-model sketch, navigation map, and the design tokens referenced.
**Stack-aware when in a repo**: name the detected framework, reuse existing components/tokens, and
cite real paths where confidently known. Framework-neutral and say so when there's no repo. **No pixel geometry** — for build fidelity, point to `implement-figma-design` (and its `design-spec.md`).

### 3. Tasks
A discrete, ordered, checkbox task list an AI agent executes one-by-one. Each task cites the `REQ`
ids it satisfies:

```
- [ ] Build the Settings form component — REQ-1, REQ-2
```

## `test-cases.md` — Gherkin acceptance scenarios

`Feature` / `Scenario` blocks per screen/state, framework-agnostic, each scenario tagged with the
`REQ` id it verifies. Cover the **interview-derived hidden states** (loading / empty / error), not
only the drawn frames:

```gherkin
Feature: Settings form

  # REQ-1
  Scenario: Saving valid settings
    Given the user has edited a valid field
    When they tap "Save"
    Then the form persists and a success toast appears

  # REQ-2
  Scenario: Save in flight
    Given a save request is pending
    When the user views the Save button
    Then it is disabled and a spinner is shown
```

## Traceability

REQ id (`spec.md` §Requirements) → task (`spec.md` §Tasks) → scenario (`test-cases.md`). Every test
traces to a requirement; every task traces to the requirements it satisfies.
