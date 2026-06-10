# `page-to-figma` takes a hard dependency on the official Figma plugin

**Status:** accepted

`page-to-figma` is an accuracy orchestrator that supervises the official Figma plugin's
code→Figma build rather than reimplementing it, so it requires `figma-use`,
`figma-generate-design`, and the `generate_figma_design` capture tool to be present. We
chose to make this a **hard, documented prerequisite** — the skill stops and tells the
user to install the official Figma plugin if it's missing — rather than degrading
gracefully or carrying its own fallback build path.

## Why this is worth recording

Every other skill in this suite depends only on Figma **MCP tools**, never on another
**skill**. `page-to-figma` is the first to depend on skills shipped by a separate plugin.
A future maintainer reading the suite's "stay self-contained, MCP-only" convention will
reasonably wonder why this skill breaks it and may try to "fix" it back toward
self-containment. This ADR records that the coupling is deliberate.

## Considered options

- **Hard dependency, documented (chosen)** — simplest, and honest about what the skill
  needs. Reimplementing `figma-use`'s Plugin-API mechanics (color ranges, font loading,
  layout gotchas) inside this skill would be a large, perpetually-drifting duplication.
- **Soft dependency with graceful degradation** — prefer the plugin, fall back to raw
  `use_figma` writes when it's absent. Rejected: it forces the skill to carry a partial
  copy of the very mechanics we're trying not to own, which is the duplication/drift trap
  the suite explicitly avoids.

## Consequences

- The skill's `SKILL.md` and the repo's `README.md` must list the official Figma plugin as
  an install prerequisite, alongside the Figma MCP connection.
- The skill must never silently produce output when the plugin is absent — it stops and
  instructs the user to install it.
