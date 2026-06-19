# Product Design Skill Suite — Claude Code

A portable, **stack-agnostic** set of [Claude Code](https://claude.com/claude-code) skills that turn Figma, FigJam, and plain product docs into narratives, specs, prototypes, and pixel-perfect builds — in either direction across the design/code boundary. They detect and conform to whatever project you run them against — no hardcoded framework, design system, or domain. Every Figma/FigJam skill follows one rule: **clarify until clear** — it stops and asks rather than inventing a missing detail.

This repo is a **skill-only scaffold**. There is no application code, no build step, and nothing to compile — just the twelve skills under [`skills/`](skills/) and an installer.

---

## Skills overview

Twelve skills across four groups. Most go **design/flow → code or doc**; `page-to-figma` is the one that runs the other way (running page → Figma).

### 1. The pipeline — FigJam → narrative → prototype

| Skill | Direction | What it does |
|-------|-----------|--------------|
| **[figjam-to-use-case-narrative](skills/figjam-to-use-case-narrative/SKILL.md)** | FigJam → narrative *(step 1)* | Reads a user-flow diagram from FigJam and writes a structured **use-case-narrative (UCN)** markdown doc. Read-only; never edits the board. |
| **[use-case-narrative-to-prototype](skills/use-case-narrative-to-prototype/SKILL.md)** | narrative → code *(step 3)* | Turns a UCN doc into a walkable, clickable code prototype (behavioral fidelity, not pixel fidelity; React by default, stack-aware). |

### 2. Fusion — finished design + flow → working prototype

| Skill | Direction | What it does |
|-------|-----------|--------------|
| **[figma-design-to-working-prototype](skills/figma-design-to-working-prototype/SKILL.md)** | design + flow → prototype | A **thin orchestrator** that fuses a finished Figma design (pixels) with its UCN (behavior) into one prototype that is **both** pixel-perfect **and** walkable. Behavior-first: delegates the walkable skeleton to `use-case-narrative-to-prototype`, then re-skins each screen in place via `implement-figma-design` (presentation only, wiring untouched). Fires only when **both** a finished design and a flow are present for the same screens. |

### 3. Standalone Figma paths

| Skill | Direction | What it does |
|-------|-----------|--------------|
| **[implement-figma-design](skills/implement-figma-design/SKILL.md)** | design → code | Transcribes a finished Figma frame into a 1:1, pixel-perfect build in your codebase. Extracts the frame into a persisted `design-spec.md`, builds from it, then verifies with an inline per-element ✓/Δ summary against the Figma screenshot — emits no report (that's `verify-design-match`). Use when someone shares a `figma.com` link and wants it built. *(Web/React path.)* |
| **[figjam-sitemap-to-spec](skills/figjam-sitemap-to-spec/SKILL.md)** | FigJam → spec | Reads a sitemap / site-structure diagram from FigJam and writes a **product spec** markdown doc (sitemap tree + per-page specs). Read-only; composes with the doc skills and build skills. |
| **[page-to-figma](skills/page-to-figma/SKILL.md)** | running page → Figma | Transcribes a **running** product page into a 1:1 Figma frame. Extracts live-DOM computed styles as ground truth, delegates the build to the official Figma plugin, then gates on a **numeric property read-back** — correcting until every value matches. *(Requires the official Figma plugin.)* |
| **[critique-figma-design](skills/critique-figma-design/SKILL.md)** | Figma frame → critique *(command-only)* | A **read-only** self-check that runs a finished Figma frame through an objective checklist and returns a severity-ranked report: four **measured** categories (accessibility, design-system consistency, structure/hierarchy, layer hygiene — each finding citing value · threshold · source) plus an evidence-anchored **Nielsen-10 heuristic** pass. A self-check, not a taste-maker — no aesthetic preference, no quality score. Runs only when you type `/critique-figma-design`. |
| **[verify-design-match](skills/verify-design-match/SKILL.md)** | running page ↔ Figma frame/section *(command-only)* | A **read-only** parity audit: compares a running page against the finished Figma frame(s) — **or a whole section of state-variant frames** — and reports, **per breakpoint and per state**, where the implementation diverges. Read-only on code & Figma; may drive the live app to reach states **only with your authorization**. Section inputs are **auto-matched then ask-the-gaps** (you supply the route + interaction recipe for states it can't reach). Visual pass locates regions; property pass quantifies them; matching is geometry-first/text-anchored with a "couldn't align" gap list. Output is a per-category ✓/⚠/✗ verdict + cited findings, **no overall score**, emitted as **both a PDF and an AI-agent Markdown handoff** (feeds `implement-figma-design`). Runs only when you type `/verify-design-match`. *(Requires Playwright + Figma access.)* |
| **[figma-to-dev-docs](skills/figma-to-dev-docs/SKILL.md)** | Figma frame/section → dev docs *(command-only)* | A **read-only** skill that turns a finished Figma frame or section into a bundle of AI-developer docs — a **developer-facing PRD**, a spec-driven `spec.md` (EARS requirements + design + tasks), and Gherkin `test-cases.md` — after a batched **context interview** for the behavior a static design can't show. Never writes to Figma, never builds code (that's `implement-figma-design`); its PRD is build context, not a buy-in brief (that's `spec-to-brief`). Keeps a **REQ → task → test** traceability chain. Runs only when you type `/figma-to-dev-docs`. |

### 4. Doc skills — no Figma required

| Skill | Direction | What it does |
|-------|-----------|--------------|
| **[harden-doc](skills/harden-doc/SKILL.md)** | doc → hardened doc *(command-only)* | Interviews you relentlessly about a plan, spec, or UCN — one question at a time, with a recommended answer each — until every branch of the decision tree is resolved. **Resolves ambiguity.** Runs only when you type `/harden-doc`. |
| **[biz-review](skills/biz-review/SKILL.md)** | doc → scope decisions *(command-only)* | Challenges a plan/spec/UCN from the founder lens — premise, demand evidence, narrowest wedge, alternatives — then puts every scope change in front of you as an explicit opt-in. **Challenges premise/value/scope.** Runs only when you type `/biz-review`. Distilled from gstack's `plan-ceo-review` / `office-hours` (MIT). |
| **[spec-to-brief](skills/spec-to-brief/SKILL.md)** | spec/UCN → product brief | Synthesizes a stakeholder-ready product brief / PRD-lite from an existing spec, UCN, sitemap, or idea — problem, target user, demand evidence, goals & metrics, solution, scope, handoff. **Produces** the writeup of what survived review. Model-invocable; composes *after* `/biz-review` and `/harden-doc`. Never fabricates a metric — unsourced facts go to Open Questions. |

> **The three doc lenses are distinct:** `harden-doc` *resolves* ambiguity, `biz-review` *challenges* premise/value/scope, and `spec-to-brief` *produces* the brief from what survives.

**Pipeline at a glance:**

```
  FigJam flow      ──▶  figjam-to-use-case-narrative  ──▶  UCN.md  ──▶  use-case-narrative-to-prototype  ──▶  clickable prototype
  Figma design     ──▶  implement-figma-design  ──▶  pixel-perfect build
  design + flow    ──▶  figma-design-to-working-prototype  ──▶  pixel-perfect AND walkable prototype
  FigJam sitemap   ──▶  figjam-sitemap-to-spec  ──▶  product-spec.md
  Running page     ──▶  page-to-figma  ──▶  pixel-perfect Figma frame
  Finished frame   ──▶  /critique-figma-design  ──▶  severity-ranked self-check (read-only)
  Finished frame   ──▶  /figma-to-dev-docs  ──▶  PRD.md + spec.md + test-cases.md (read-only)
  Running page+Figma──▶  /verify-design-match  ──▶  per-state parity report: PDF + AI-agent MD (read-only)
  Any plan/spec    ──▶  /biz-review  ──▶  /harden-doc  ──▶  spec-to-brief  ──▶  stakeholder brief
```

> `implement-figma-design` is the pixel-fidelity path; `use-case-narrative-to-prototype` is the behavior-fidelity path; `figma-design-to-working-prototype` fuses both. When a finished design exists and you need 1:1 accuracy, reach for the former two depending on whether you also need behavior.

---

## Requirements

- **Claude Code** (CLI, desktop, or IDE extension).
- The **Figma MCP server** connected, so the skills can read from Figma/FigJam. The skills use the read tools `get_design_context`, `get_screenshot`, `get_metadata`, `get_variable_defs`, and `get_figjam`. To connect it, see Figma's [Guide to the Figma MCP server](https://help.figma.com/hc/en-us/articles/32132100833559-Guide-to-the-Figma-MCP-server) and the [developer docs](https://developers.figma.com/docs/figma-mcp-server/). These are the current, unified tool names (local Dev Mode server **and** the hosted connector). An **outdated** Figma desktop install may still expose the legacy names `get_code` / `get_image` — if a skill reports "tool not found" on step 1, update Figma.
- For `page-to-figma` only: the **official Figma plugin** must be installed (it provides the `figma-use` and `figma-generate-design` skills this one supervises) and the write tools `use_figma` / `generate_figma_design` must be available. This is the one suite skill with a hard dependency beyond the MCP read tools — see [docs/adr/0001-page-to-figma-depends-on-official-figma-plugin.md](docs/adr/0001-page-to-figma-depends-on-official-figma-plugin.md).
- For `figma-design-to-working-prototype`: needs the Figma MCP read tools **transitively** through the two siblings it orchestrates (`use-case-narrative-to-prototype` + `implement-figma-design`) — see [docs/adr/0002-p1-composes-sibling-suite-skills.md](docs/adr/0002-p1-composes-sibling-suite-skills.md).
- For `verify-design-match`: a **hard, fail-closed** dependency on **both** browser automation (Playwright **MCP or CLI**) **and** Figma access (Figma **MCP read tools or REST API + token**). The skill stops with setup instructions if either is missing — see [docs/adr/0003-verify-design-match-requires-playwright-and-figma-access.md](docs/adr/0003-verify-design-match-requires-playwright-and-figma-access.md).
- For screenshot-based verification in `implement-figma-design` (and walkable verification in the prototype skills): any browser/screenshot tooling available in your project (e.g. Playwright).
- `harden-doc`, `biz-review`, and `spec-to-brief` need **no Figma connection at all** — they operate on markdown documents and plans. `biz-review` and `spec-to-brief` can optionally use web search / the `deep-research` plugin for the landscape check.

---

## Portability — Claude Code vs. claude.ai chat

This suite is built for **Claude Code**, not the claude.ai chat interface. Most skills read/write a target codebase, drive a running app, or talk to the Figma plugin — none of which the claude.ai cloud sandbox can see. The dividing line is simple: **skills that operate on a doc or idea could port; skills that touch your codebase, your running app, or write to Figma cannot.**

| Skill | claude.ai chat | Blocker |
|-------|:--------------:|---------|
| **harden-doc** | ✅ Portable | Pure conversation over a pasted doc |
| **biz-review** | ✅ Portable | Conversation + web search (works on claude.ai) |
| **spec-to-brief** | ✅ Portable | Generative writeup from a pasted spec |
| **figjam-to-use-case-narrative** | 🟡 Degraded | Needs the Figma read connector; read-only so plausible |
| **figjam-sitemap-to-spec** | 🟡 Degraded | Same — Figma read connector only |
| **critique-figma-design** | 🟡 Degraded | Figma read works, but screenshot/pixel-sampling steps are unreliable in-sandbox |
| **figma-to-dev-docs** | 🟡 Degraded | Figma read works; repo-grounding for Design/Tasks is unavailable in-sandbox |
| **implement-figma-design** | ❌ No | Writes code into *your* repo + screenshots *your* running UI |
| **use-case-narrative-to-prototype** | ❌ No | Builds a runnable prototype in your project |
| **figma-design-to-working-prototype** | ❌ No | Orchestrates the two above |
| **page-to-figma** | ❌ No | Needs your running page's live DOM + Figma writes |
| **verify-design-match** | ❌ No | Hard fail-closed on Playwright **and** Figma access |

**Why the sandbox is the limit:** claude.ai Agent Skills run in an isolated cloud container that can run code and use connected MCP servers, but **cannot see your local repo** (the build skills' whole job), **cannot reach `localhost`** on your machine (your running app is invisible), and **cannot drive a browser** against your dev server (the Playwright steps `verify-design-match` and the prototype/verify skills rely on).

The cleanly portable set is the **three no-Figma doc skills** (`harden-doc`, `biz-review`, `spec-to-brief`). This repo ships **Claude Code skills only** (curl|bash install — no claude.ai package format); the table above is guidance for anyone considering a manual port, not a second supported distribution.

---

## Install

### Option A — one-liner (no clone)

```bash
curl -fsSL https://raw.githubusercontent.com/Peeradonte48/product-design-skill/main/install.sh | bash
```

Installs all twelve skills into your user skills directory, `~/.claude/skills/`.

### Option B — clone and run the installer

```bash
git clone https://github.com/Peeradonte48/product-design-skill.git
cd product-design-skill
./install.sh                 # user-level   → ~/.claude/skills
./install.sh --project       # project-only → ./.claude/skills (run from your project root)
./install.sh --dir <path>    # custom skills directory
./install.sh --update        # update installed skills to the latest (no prompts)
./install.sh --check         # report installed vs latest version, then exit
./install.sh --force         # overwrite existing copies without prompting
./install.sh --no-notify     # install/update without the daily update-check hook
./install.sh --uninstall     # remove the twelve skills (and the update-check hook)
```

### Option C — copy by hand

Each skill is a self-contained folder. Copy the twelve directories under [`skills/`](skills/) into any skills directory Claude Code reads:

```bash
cp -R skills/* ~/.claude/skills/        # user-level
# or, per project:
cp -R skills/* /path/to/project/.claude/skills/
```

After installing, restart Claude Code (or run `/doctor`) so it discovers the new skills.

**User-level vs project-level:** install to `~/.claude/skills` to use the skills in every project; install to a project's `.claude/skills` to scope them to that repo (and commit them with the project).

### Updating (already installed?)

The suite is versioned (see [`VERSION`](VERSION)). To pull the latest, **re-run the installer with `--update`** — it overwrites only the skills that changed, skips unchanged ones, removes any skill dropped from the suite, and prints a summary:

```bash
curl -fsSL https://raw.githubusercontent.com/Peeradonte48/product-design-skill/main/install.sh | bash -s -- --update
```

Check whether you're behind without changing anything:

```bash
curl -fsSL https://raw.githubusercontent.com/Peeradonte48/product-design-skill/main/install.sh | bash -s -- --check
```

(Cloned the repo instead? `git pull` then `./install.sh --update`.) Each install stamps a small `~/.claude/skills/.product-design-skill.version` manifest so `--check`/`--update` know what you have. Then restart Claude Code (or run `/doctor`).

**From inside Claude Code**, the suite also ships a slash command so you don't have to drop to a terminal:

```
/update-design-skills
```

It runs the same `--update` for you in-session, then reports the summary. (Installed into `~/.claude/commands/` alongside the skills; a restart or `/doctor` still loads the freshly-updated files.)

### Update notifications

So you don't have to remember to run `--check`, the installer adds a Claude Code **`SessionStart` hook** that checks for a newer version and, when one exists, prints a one-line notice (with the update command and a [changelog](CHANGELOG.md) link) at the start of a session.

- **On by default.** Opt out at install time with `--no-notify`; remove it later with `--uninstall` (or re-run `--update --no-notify`).
- **Quiet and safe.** It checks at most once every 24 hours, makes a single lightweight request to GitHub's raw [`VERSION`](VERSION) file, and **fails silently** when you're offline. It never blocks or delays a session.
- **Where it lives.** The hook is registered in your `settings.json` (`~/.claude/settings.json` for a user install, `<project>/.claude/settings.json` for `--project`); a small notifier script sits next to the version manifest. Registration uses `python3` or `jq` — if neither is present the installer prints manual steps instead. Custom `--dir` installs write the script but don't auto-register it.

---

## Usage

Most skills trigger automatically from natural language — you generally don't need to name them. The **command-only** skills (`/harden-doc`, `/biz-review`, `/critique-figma-design`, `/verify-design-match`, `/figma-to-dev-docs`) never auto-trigger; you invoke them explicitly so they don't fire uninvited.

**Model-invocable (trigger from a request):**

- **Build a Figma design** → `implement-figma-design`
  > "Implement this frame: `https://figma.com/design/…?node-id=…`"

- **Document a FigJam flow** → `figjam-to-use-case-narrative`
  > "Turn this FigJam flow into a use-case narrative: `https://figma.com/board/…`"

- **Prototype from a narrative** → `use-case-narrative-to-prototype`
  > "Build a clickable prototype from `docs/flows/checkout-flow.md`"

- **Fuse a design + flow into a working prototype** → `figma-design-to-working-prototype`
  > "Make a prototype that looks like `<figma link>` and behaves like `docs/flows/checkout.md`"

- **Spec out an app from a sitemap** → `figjam-sitemap-to-spec`
  > "Turn this FigJam sitemap into a product spec: `https://figma.com/board/…`"

- **Mirror a running page into Figma** → `page-to-figma`
  > "Put our live settings page into Figma exactly: `http://localhost:3000/settings`"

- **Write a stakeholder brief from a spec** → `spec-to-brief`
  > "Write a product brief from `docs/specs/pos-spec.md`"

**Command-only (invoke explicitly):**

- **Objective self-check of a Figma frame:**
  > `/critique-figma-design` *(with the frame selected / linked)*

- **Check a running page matches its Figma design (any/all states):**
  > `/verify-design-match` *(with the page URL/route and the Figma frame **or section** it should match; it auto-matches the default state and asks you for the route + recipe of any others, then emits a PDF + an AI-agent Markdown report)*

- **Generate AI-developer docs (PRD + spec + tests) from a Figma frame/section:**
  > `/figma-to-dev-docs` *(with the frame or section linked; it confirms the screen/state mapping, interviews you for the missing behavior/business context, then writes `PRD.md` + `spec.md` + `test-cases.md`)*

- **Stress-test a plan or spec until every branch is resolved:**
  > `/harden-doc docs/specs/pos-spec.md`

- **Challenge the business case and scope:**
  > `/biz-review docs/specs/pos-spec.md`

You can also invoke any skill explicitly by name, e.g. *"use the use-case-narrative-to-prototype skill on …"*.

---

## Guide

### End-to-end: FigJam flow → walkable prototype

```text
1.  "Document this FigJam flow → UCN"      →  figjam-to-use-case-narrative  →  checkout-flow.md
2.  "/harden-doc checkout-flow.md"         →  resolve every ambiguous branch
3.  "Prototype checkout-flow.md"           →  use-case-narrative-to-prototype  →  walkable screens
4.  (optional) "Make it match <figma>"     →  figma-design-to-working-prototype  →  pixel-perfect + walkable
```

### End-to-end: idea/spec → vetted stakeholder brief

```text
1.  "/biz-review docs/specs/idea.md"       →  challenge premise, demand evidence, scope opt-ins
2.  "/harden-doc docs/specs/idea.md"       →  resolve every decision branch
3.  "Write a brief from docs/specs/idea.md" →  spec-to-brief  →  product-brief.md (handoff-ready)
```

### Choosing the right skill

- **Have a finished Figma design, want code?** → `implement-figma-design` (pixel) — add a flow and use `figma-design-to-working-prototype` if you also need it walkable.
- **Have a flow/diagram, want something to click?** → `figjam-to-use-case-narrative` then `use-case-narrative-to-prototype`.
- **Have a running page, want it in Figma?** → `page-to-figma`.
- **Have a sitemap, want a spec?** → `figjam-sitemap-to-spec`.
- **Want to vet a Figma frame objectively?** → `/critique-figma-design`.
- **Want to vet a *document*?** → `/biz-review` (premise/scope) and `/harden-doc` (ambiguity), then `spec-to-brief` to write it up.

### Example output

`figjam-to-use-case-narrative` reads a flow diagram and writes a doc like this (shape, abridged):

```markdown
# UC-01: Checkout

**Primary Actor:** Shopper
**Trigger:** Shopper clicks "Checkout" from the cart.

## Main Success Scenario
1. Shopper reviews the cart and confirms items.
2. System requests shipping details.
3. Shopper enters address; system validates it.
4. Shopper selects a payment method and pays.
5. System confirms the order and shows a receipt.

## Extensions
3a. Address fails validation → system shows the error and re-prompts (back to step 3).
4a. Payment declined → system keeps the cart and offers another method.

## Postconditions
- Success: order created, cart cleared, receipt shown.
- Exit: cart preserved, no charge made.

## Business Rules
- An order can never be created without a successful payment.
```

`use-case-narrative-to-prototype` then turns that UCN into a runnable app — every Main Success Scenario step becomes a reachable screen, every Extension a triggerable branch/error/gate, and Business Rules become enforced client-side logic — and reports exactly which steps, extensions, and rules are covered vs stubbed.

### How the skills are structured

```
skills/
├── implement-figma-design/
│   ├── SKILL.md
│   └── references/
│       └── design-spec-format.md          # single-owner: design-spec.md columns + Gaps rules
├── figjam-to-use-case-narrative/
│   ├── SKILL.md
│   └── references/
│       ├── figjam-mapping.md                # FigJam primitive → UCN section mapping
│       └── use-case-narrative-format.md     # canonical UCN template (shared contract)
├── use-case-narrative-to-prototype/
│   ├── SKILL.md
│   └── references/
│       ├── prototype-mapping.md             # UCN section → prototype element mapping
│       └── use-case-narrative-format.md     # identical copy of the UCN template
├── figma-design-to-working-prototype/
│   └── SKILL.md                             # thin orchestrator: skeleton (UCN) + re-skin (Figma)
├── figjam-sitemap-to-spec/
│   ├── SKILL.md
│   └── references/
│       ├── sitemap-mapping.md               # FigJam sitemap primitive → spec section mapping
│       └── product-spec-guide.md            # flexible product-spec authoring guide (single-owner)
├── page-to-figma/
│   └── SKILL.md                             # running page → Figma accuracy orchestrator
├── critique-figma-design/
│   ├── SKILL.md                             # read-only Figma self-check (/critique-figma-design)
│   └── references/
│       ├── check-catalog.md                 # measured checks + thresholds + Nielsen-10 catalog
│       └── report-template.html             # optional styled PDF report skeleton (editorial + dashboard)
├── verify-design-match/
│   ├── SKILL.md                             # read-only live↔Figma parity audit (/verify-design-match)
│   └── references/
│       ├── parity-check-catalog.md          # categories, tolerances, matching algorithm, report templates
│       └── report-template.html             # styled PDF report skeleton (editorial + dashboard)
├── harden-doc/
│   └── SKILL.md                             # doc command: resolve every decision branch (/harden-doc)
├── biz-review/
│   └── SKILL.md                             # doc command: founder-lens scope review (/biz-review)
├── spec-to-brief/
│   ├── SKILL.md                             # generative: spec/UCN → stakeholder brief
│   └── references/
│       └── product-brief-template.md        # flexible product-brief template (single-owner)
└── figma-to-dev-docs/
    ├── SKILL.md                             # read-only Figma → dev docs (/figma-to-dev-docs)
    └── references/
        ├── context-interview.md             # interview topics + completion bar (single-owner)
        └── doc-templates.md                 # the three output formats + traceability (single-owner)

docs/                                        # ADRs only — gitignored, not shipped to users
└── adr/
    ├── 0001-page-to-figma-depends-on-official-figma-plugin.md
    ├── 0002-p1-composes-sibling-suite-skills.md
    ├── 0003-verify-design-match-requires-playwright-and-figma-access.md
    ├── 0004-implement-figma-design-emits-no-report.md
    └── 0005-figma-to-dev-docs-separate-from-spec-to-brief.md
```

> **Shared format contract:** the two `references/use-case-narrative-format.md` files are byte-identical on purpose — one skill writes the format, the other reads it. **If you edit one, edit the other to match.**

---

## Contributing / editing the skills

Keep these conventions (see [`CLAUDE.md`](CLAUDE.md) for the full list):

- **Stay stack-agnostic.** Skills detect the target project's framework, file layout, components, styling, and token system and conform to them. Don't bake in a specific stack, design system, or domain.
- **Honor the target project's own conventions** (token systems, accessibility/ergonomics rules) — and surface a conflict rather than silently shipping something that breaks a rule.
- **Reuse over reinvention; match every breakpoint.** A match at one width that breaks at another is not a match.
- **Clarify until clear.** A wrong guess that looks right silently corrupts the spec — don't proceed past an unresolved ambiguity.
- **Keep the two UCN format copies in sync.**
- **Keep command-only skills command-only.** Don't remove `disable-model-invocation: true` from `harden-doc`, `biz-review`, or `critique-figma-design`.
- **Keep the fusion skill thin and behavior-first.** `figma-design-to-working-prototype` orchestrates its siblings; don't inline their logic or reverse it to pixels-first.

---

## License

MIT — see [`LICENSE`](LICENSE).
