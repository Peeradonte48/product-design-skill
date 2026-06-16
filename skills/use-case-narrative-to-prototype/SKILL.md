---
name: use-case-narrative-to-prototype
description: >-
  Generate an interactive, clickable code prototype from a use-case-narrative (UCN)
  markdown document (narrative → code). Use this skill WHENEVER the user points at a UCN
  doc / flow write-up and wants it built, prototyped, or "turned into screens you can
  click through." Triggers: "build a prototype from this use case narrative", "implement
  this flow doc as code", "generate the screens from this UCN <file>", "make this flow
  clickable". It produces working code (React by default, stack-aware), not a Figma file.
  When a finished Figma design already exists and you need pixel fidelity, use
  implement-figma-design instead.
---

# Use-Case Narrative → Interactive Prototype

Turn a use-case-narrative document into a **walkable, clickable code prototype**. The
narrative is a behavioral spec — actor, steps, branches, rules, resulting state — and your
job is to make that flow real enough to click through end to end: the happy path plus the
branches and errors that matter.

This is **behavioral fidelity, not pixel fidelity.** The UCN says *what happens*, not what
it looks like down to the hex. Build sensible, clean default UI and make the *flow* correct.
If a Figma design for these screens also exists, that's the job of `implement-figma-design`
(the Figma-design → code path) — note the handoff rather than guessing visuals here.

This is step 3 of the pipeline **FigJam → narrative → prototype**; the narrative it reads
is exactly what `figjam-to-use-case-narrative` produces.

## Before you proceed — ask until clear

A narrative can still be ambiguous, and a prototype that quietly invents behavior is
misleading. While this skill is active, **never silently guess.** If a step's outcome is
underspecified, an Extension's target or condition is unclear, a Business Rule is stated
without enough detail to enforce it, the data the screens need isn't described, or you
can't tell which stack/output the user wants — **stop and ask the user, and keep asking
until everything is clear.** Batch related questions, but do not build past an unresolved
gap. Flag any visual assumption you make (since the narrative is behavioral) so the user
can correct it.

## Workflow

### 1. Read the narrative against the format

Read the UCN doc. Use `references/use-case-narrative-format.md` so you know the structure
you're parsing — required sections (`Primary Actor`, `Stakeholders & Interests`,
`Preconditions`, `Trigger`, `Main Success Scenario`, `Extensions`, `Postconditions`,
`Business Rules`) and the optional `Technical Notes`. The step↔Extension numbering (`5a`
branches off main step 5) is load-bearing — it tells you which alternate states attach to
which screen.

If the doc doesn't conform to the format (missing required sections, unnumbered steps),
ask the user how to interpret it rather than forcing a mapping.

### 2. Derive the app structure

Map narrative sections to a prototype, using `references/prototype-mapping.md` for the full
guidance. The core mapping:

- **Main Success Scenario steps that show a distinct screen** → routes / views.
- **Transitions between those steps** → navigation (and the entry into the flow from the `Trigger`).
- **Extensions** → conditional UI: alternate states, error states, modals/sheets, branches
  attached to the screen of their parent step.
- **Business Rules** → client-side logic: validation, gating, enable/disable, required
  fields, authorization prompts.
- **Postconditions** → the state changes each outcome produces (reflect them in mock state).
- **Preconditions + Trigger** → the entry state the prototype starts from.
- **Technical Notes (if present)** → reuse its route mapping / store hints rather than
  re-deriving them.

### 3. Detect the stack and build

Detect the target project's stack and conventions (framework, routing, styling, component
patterns) and build within them.

**No codebase yet?** A pure designer often has no target repo — that is expected, not a
blocker. Do not hunt for a stack to conform to. Instead, scaffold a fresh standalone app
to host the prototype:

- Default to **React**, and **confirm that default with the user** before scaffolding (offer
  their stack if they have a preference).
- Scaffold the minimum that runs and is walkable — a single app with client-side routing,
  local mock state/data (no backend), and a dev server the user can open. Use the framework's
  standard starter rather than hand-rolling configuration.
- Tell the user how to run it, and keep it self-contained so it can be zipped or handed off.

Once a host exists (detected or scaffolded), build within it as below.

Build a prototype that is genuinely walkable: real navigation between screens, local mock
state/data (no backend needed), and the interactions that let someone click the happy path
through to a Postcondition. Implement the key Extensions (the important branches, errors,
and gated actions), not just the happy path. Reuse existing components where the project
has them.

### 4. Verify against the narrative

Walk the prototype against the UCN and confirm coverage. Report it explicitly:

- Every `Main Success Scenario` step is reachable in order, ending at a `Postcondition`.
- The key `Extensions` are triggerable (branch conditions, error states, gated actions).
- `Business Rules` are actually enforced (e.g. a required field blocks progress; a gated
  action prompts for authorization).

List which steps/extensions/rules are covered, which are stubbed, and any visual or data
assumptions you made — so the user can see exactly how faithful the prototype is and what
still needs their input.

## Reference files

- `references/use-case-narrative-format.md` — the canonical UCN structure (so you can parse
  the input). **Keep this in sync** with the identical copy in the
  `figjam-to-use-case-narrative` skill — the two skills share one format contract.
- `references/prototype-mapping.md` — UCN-section → screens / state / interactions /
  validation mapping guidance.
