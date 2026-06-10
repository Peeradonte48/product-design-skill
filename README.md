# Figma Implement — Claude Code skill suite

A portable, **stack-agnostic** set of [Claude Code](https://claude.com/claude-code) skills that turn Figma and FigJam into code. They detect and conform to whatever project you run them against — no hardcoded framework, design system, or domain. Every skill follows one rule: **clarify until clear** — it stops and asks rather than inventing a missing detail.

This repo is a **skill-only scaffold**. There is no application code, no build step, and nothing to compile — just the skills under [`skills/`](skills/) and an installer.

---

## The skills

The suite forms a **FigJam → narrative → prototype** pipeline, plus three standalone paths — a **design → code** path, a **sitemap → spec** path, and a **running page → Figma** path — and two **doc-review** skills that harden the documents the others produce.

| Skill | Direction | What it does |
|-------|-----------|--------------|
| **[implement-figma-design](skills/implement-figma-design/SKILL.md)** | design → code | Transcribes a finished Figma frame into a 1:1, pixel-perfect build in your codebase, then verifies by diffing a screenshot of the running UI against the Figma reference. Use when someone shares a `figma.com` link and wants it built. *(Web/React path.)* |
| **[figjam-to-use-case-narrative](skills/figjam-to-use-case-narrative/SKILL.md)** | FigJam → narrative *(step 1)* | Reads a user-flow diagram from FigJam and writes a structured **use-case-narrative (UCN)** markdown doc. Read-only; never edits the board. |
| **[use-case-narrative-to-prototype](skills/use-case-narrative-to-prototype/SKILL.md)** | narrative → code *(step 3)* | Turns a UCN doc into a walkable, clickable code prototype (behavioral fidelity, not pixel fidelity; React by default, stack-aware). |
| **[figjam-sitemap-to-spec](skills/figjam-sitemap-to-spec/SKILL.md)** | FigJam → spec *(standalone)* | Reads a sitemap / site-structure diagram from FigJam and writes a **product spec** markdown doc (sitemap tree + per-page specs). Read-only; never edits the board. Composes with doc-review and build skills. |
| **[page-to-figma](skills/page-to-figma/SKILL.md)** | running page → Figma *(standalone)* | Transcribes a **running** product page into a 1:1, pixel-perfect Figma frame. Extracts live-DOM computed styles as ground truth, delegates the build to the official Figma plugin, then gates on a **numeric property read-back** — correcting until every value matches. *(Requires the official Figma plugin.)* |
| **[harden-doc](skills/harden-doc/SKILL.md)** | doc → hardened doc *(command-only)* | Interviews you relentlessly about a plan, spec, or UCN — one question at a time, with a recommended answer each — until every branch of the decision tree is resolved. Runs only when you type `/harden-doc`. No Figma required. |
| **[biz-review](skills/biz-review/SKILL.md)** | doc → scope decisions *(command-only)* | Challenges a plan/spec/UCN from the founder lens — premise, demand evidence, narrowest wedge, alternatives — then puts every scope change in front of you as an explicit opt-in. Runs only when you type `/biz-review`. Distilled from gstack's `plan-ceo-review` / `office-hours` (MIT). No Figma required. |

**Pipeline at a glance:**

```
  FigJam flow     ──▶  figjam-to-use-case-narrative  ──▶  UCN.md  ──▶  use-case-narrative-to-prototype  ──▶  clickable prototype
  Figma frame     ──▶  implement-figma-design  ──▶  pixel-perfect build (standalone)
  FigJam sitemap  ──▶  figjam-sitemap-to-spec  ──▶  product-spec.md (standalone)
  Running page    ──▶  page-to-figma  ──▶  pixel-perfect Figma frame (standalone)
  Any plan/spec   ──▶  /biz-review  ──▶  scope decisions  ──▶  /harden-doc  ──▶  hardened doc (command-only)
```

> `implement-figma-design` is the pixel-fidelity path; `use-case-narrative-to-prototype` is the behavior-fidelity path. When a finished design exists and you need 1:1 accuracy, reach for the former.

---

## Requirements

- **Claude Code** (CLI, desktop, or IDE extension).
- The **Figma MCP server** connected, so the skills can read from Figma/FigJam. The skills use the read tools `get_design_context`, `get_screenshot`, `get_metadata`, `get_variable_defs`, and `get_figjam`. To connect it, see Figma's [Guide to the Figma MCP server](https://help.figma.com/hc/en-us/articles/32132100833559-Guide-to-the-Figma-MCP-server) and the [developer docs](https://developers.figma.com/docs/figma-mcp-server/). These are the current, unified tool names (local Dev Mode server **and** the hosted connector). An **outdated** Figma desktop install may still expose the legacy names `get_code` / `get_image` instead — if a skill reports "tool not found" on step 1, update Figma.
- For `page-to-figma` only: the **official Figma plugin** must be installed (it provides the `figma-use` and `figma-generate-design` skills this one supervises) and the write tools `use_figma` / `generate_figma_design` must be available. This is the one suite skill with a hard dependency beyond the MCP read tools — see [docs/adr/0001-page-to-figma-depends-on-official-figma-plugin.md](docs/adr/0001-page-to-figma-depends-on-official-figma-plugin.md).
- For screenshot-based verification in `implement-figma-design`: any browser/screenshot tooling available in your project (e.g. Playwright).
- `harden-doc` and `biz-review` need **no Figma connection at all** — they review markdown documents and plans.

---

## Install

### Option A — one-liner (no clone)

```bash
curl -fsSL https://raw.githubusercontent.com/Peeradonte48/FIGMA-IMPLEMENT/main/install.sh | bash
```

Installs all seven skills into your user skills directory, `~/.claude/skills/`.

### Option B — clone and run the installer

```bash
git clone https://github.com/Peeradonte48/FIGMA-IMPLEMENT.git
cd FIGMA-IMPLEMENT
./install.sh                 # user-level   → ~/.claude/skills
./install.sh --project       # project-only → ./.claude/skills (run from your project root)
./install.sh --dir <path>    # custom skills directory
./install.sh --force         # overwrite existing copies without prompting
./install.sh --uninstall     # remove the seven skills
```

### Option C — copy by hand

Each skill is a self-contained folder. Copy the seven directories under [`skills/`](skills/) into any skills directory Claude Code reads:

```bash
cp -R skills/* ~/.claude/skills/        # user-level
# or, per project:
cp -R skills/* /path/to/project/.claude/skills/
```

After installing, restart Claude Code (or run `/doctor`) so it discovers the new skills.

**User-level vs project-level:** install to `~/.claude/skills` to use the skills in every project; install to a project's `.claude/skills` to scope them to that repo (and commit them with the project).

---

## Usage

Once installed, the skills trigger automatically from natural language — you generally don't need to name them:

- **Build a Figma design:**
  > "Implement this frame: `https://figma.com/design/…?node-id=…`"
  → `implement-figma-design`

- **Document a FigJam flow:**
  > "Turn this FigJam flow into a use-case narrative: `https://figma.com/board/…`"
  → `figjam-to-use-case-narrative`

- **Prototype from a narrative:**
  > "Build a clickable prototype from `docs/flows/checkout-flow.md`"
  → `use-case-narrative-to-prototype`

- **Spec out an app from a sitemap:**
  > "Turn this FigJam sitemap into a product spec: `https://figma.com/board/…`"
  → `figjam-sitemap-to-spec`

- **Mirror a running page into Figma:**
  > "Put our live settings page into Figma exactly: `http://localhost:3000/settings`"
  → `page-to-figma`

The two doc-review skills are **command-only** — they never auto-trigger; invoke them explicitly:

- **Stress-test a plan or spec:**
  > `/harden-doc docs/specs/pos-spec.md`

- **Challenge the business case:**
  > `/biz-review docs/specs/pos-spec.md`

You can also invoke a skill explicitly by name, e.g. *"use the use-case-narrative-to-prototype skill on …"*.

### End-to-end pipeline example

```text
1.  "Document this FigJam flow → UCN"        →  figjam-to-use-case-narrative  →  checkout-flow.md
2.  (review/edit the UCN doc — e.g. "/harden-doc checkout-flow.md")
3.  "Prototype checkout-flow.md"             →  use-case-narrative-to-prototype  →  walkable screens
```

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

> Want a screen recording / before-after here? A short demo GIF of a Figma frame turning into running code is the single highest-leverage adoption asset for this README.

---

## How the skills are structured

```
skills/
├── implement-figma-design/
│   └── SKILL.md
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
├── figjam-sitemap-to-spec/
│   ├── SKILL.md
│   └── references/
│       ├── sitemap-mapping.md               # FigJam sitemap primitive → spec section mapping
│       └── product-spec-guide.md            # flexible product-spec authoring guide (single-owner)
├── page-to-figma/
│   └── SKILL.md                             # running page → Figma accuracy orchestrator (no references/)
├── harden-doc/
│   └── SKILL.md                             # doc-review command: resolve every decision branch (/harden-doc)
└── biz-review/
    └── SKILL.md                             # doc-review command: business/founder-lens scope review (/biz-review)
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

---

## License

MIT — see [`LICENSE`](LICENSE).
