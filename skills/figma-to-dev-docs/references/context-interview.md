# Context interview — topics, batching, and the completion bar

Single-owner reference for `figma-to-dev-docs`. A finished Figma frame shows *what the UI looks
like*, never *what it does*. This interview fills the behavioral/business gaps a static design can't
hold. It is **generate-only**: it gathers what's needed to write the three docs — it does **not**
challenge the premise (route to `/biz-review`) or relentlessly resolve every ambiguity (route to
`/harden-doc`), and it **never fabricates a metric or demand claim** (unsourced → Open Questions).

## How to run it

- **Feature-level batches, not per-frame.** Ask one round per topic, naming all in-scope screens in
  that round — not the same topic repeated for every frame. This keeps a large section tractable.
- **One recommended answer per question.** Every question carries your best-inferred default so the
  user can confirm rather than compose from scratch.
- **Scope-down offer.** For a multi-screen section, before interviewing, offer to narrow this run:
  "All N screens, or a subset?" Let the user chunk the work.
- **Stop at the completion bar, not at perfection.** When the bar (below) is met, generate. Park
  genuine unknowns in Open Questions with a stated reason rather than blocking forever.

## Topics

1. **Problem · target users · demand evidence** — what the feature is for, who specifically has the
   problem, what evidence of demand exists. Never invent evidence; unsourced → Open Questions.
2. **Flow · interactions · navigation** — what each interactive element does; how the user moves
   between screens; entry and exit points.
3. **Data · dynamic content · hidden states** — what's real vs placeholder; the data source per
   dynamic region; the loading / empty / error states not drawn in the frame.
4. **Business rules · validation** — rules that govern behavior (limits, permissions, validation
   messages, side effects).
5. **Non-functional** — performance, accessibility, target platform / breakpoints, auth.
6. **Success metrics · scope in/out** — at least one success signal; what is explicitly out of scope.

## Completion bar (the "until clear" definition)

Generation may begin when, **for every screen/state in the confirmed mapping**:

- [ ] every interactive element has a defined behavior, or is explicitly marked static;
- [ ] navigation between screens is defined;
- [ ] each dynamic region has a data source, and its loading / empty / error handling is stated (or
      marked Open);
- [ ] validation / business rules touching the screen are captured (or marked Open);
- [ ] the feature's problem, target user, scope in/out, and at least one success signal are stated
      (or marked Open with a reason).

State which items you parked in Open Questions and why. Do **not** claim a "complete spec" when items
are parked.
