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
