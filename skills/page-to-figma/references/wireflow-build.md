# Wireflow build mechanics (page-to-figma)

Concrete recipes the skill calls. Run node ops via **`use_figma`** (primary engine — see §0);
the `$FIGMA_CLI eval` form shown in the snippets is the vendored figma-cli
(`node ~/.claude/figma-cli/src/index.js`, or the project copy) **fallback**.

## 0. Driver prerequisites & environment (check before any capture)

These are the things a real run will fail on if you skip them. Check §0 first.

- **Node-op engine: prefer `use_figma` (Figma MCP Plugin API).** Every container / reparent /
  arrange / connector op below is Plugin API JS. Run it via **`use_figma`** — load the `figma-use`
  skill first; use the **async** API (`getNodeByIdAsync`, `setCurrentPageAsync`, `loadFontAsync`);
  `use_figma` scripts are **atomic**, so batch ~5–6 ops per call (a throw rolls the whole batch
  back). This is the **same MCP bridge** already required for `generate_figma_design` / `whoami` /
  `get_metadata`, so it adds no new dependency. The `$FIGMA_CLI eval` form in these snippets is the
  **figma-cli fallback** — usable only when its local CDP bridge is up, which **can fail outright**
  (e.g. `open -a Figma --args --remote-debugging-port=9222` → error -600). **Don't depend on
  figma-cli.**
- **Playwright is a hard, fail-closed dependency. Prefer a Playwright MCP.** It runs in the
  user's environment and can open a headed browser for login. **Check for it up front.** If there
  is no Playwright MCP **and** no importable `playwright` / `playwright-core` on a reachable path,
  **stop and tell the user to install it** —
  `claude mcp add playwright npx @playwright/mcp@latest` (then restart the session). Do **not**
  improvise a driver by hand-locating a cached Chromium binary; that is the slow, fragile path the
  MCP exists to avoid. With the MCP present, the whole drive-then-capture flow is trivial.
- **Pre-authorize the in-page code-execution tool — the most common hard block.** Capture *must*
  run Figma's `capture.js` inside the live page (§1 step 3), so it needs a tool that executes
  arbitrary JS in the page (e.g. the Playwright MCP's `browser_run_code_unsafe`), and those are
  **denied by default**. **Only the user can grant it.** `acceptEdits`/auto modes do **not** help:
  `.claude/` is a **protected path** (an agent edit to `.claude/settings.local.json` still prompts
  the user, and stricter setups deny the self-grant outright), and `acceptEdits` only auto-approves
  file edits + a few filesystem Bash commands — **never an MCP tool call**. Good news: once added,
  **`permissions` hot-reload immediately — no session restart needed.** Confirm it's allowed
  **before** capturing; being blocked partway wastes the whole run.

  **Walk the user through the grant — assume they are not technical.** Don't just print a tool
  name. When the tool is blocked (or up front, in pipeline step 1), tell the user, in plain
  language, something like this and **wait** for them to confirm before retrying:

  > To copy your page into Figma I need a one-time permission: to run Figma's capture script inside
  > your app's browser tab. Your setup blocks that by default and I'm not allowed to turn it on
  > myself — you have to. Pick either way:
  >
  > **Easiest — approve when asked:** if a permission prompt appears when I try, choose
  > **"Yes, and don't ask again."** Done.
  >
  > **Or add it once in settings (~20 seconds):**
  > 1. In **this project's** folder, open `.claude/settings.local.json` (create it if it's missing).
  > 2. Add `"mcp__playwright__browser_run_code_unsafe"` to the `permissions.allow` list.
  > 3. Save — it takes effect right away, **no restart**. Then tell me "continue".
  >
  > File doesn't exist yet — paste this whole thing in:
  > ```json
  > { "permissions": { "allow": ["mcp__playwright__browser_run_code_unsafe"] } }
  > ```
  > File already exists — add the line inside the existing `allow` array:
  > ```json
  > { "permissions": { "allow": [ "...your existing entries...",
  >   "mcp__playwright__browser_run_code_unsafe" ] } }
  > ```
  > (Want it for all Playwright tools, or everywhere? Use `"mcp__playwright__*"`, or put the same
  > line in your user-level `~/.claude/settings.json`.)
  >
  > This only lets me run Figma's own capture script in your own app to send it to your own Figma —
  > exactly what this command does. Safe to leave on for this; remove it later if you like.

  - **You may offer to make the edit, but expect a prompt either way.** `.claude/` is protected, so
    even if you edit `settings.local.json` yourself the user must still approve the write (and some
    setups deny the agent self-grant outright). The human always consents — so default to guiding
    them, and only edit-for-them if they ask.
  - **Bash node-driver path (§1b):** needs Bash + an importable `playwright`/`playwright-core`; it
    runs the same in-page JS via `page.addScriptTag` + `page.evaluate`, so it may hit its own
    guard. Not a way to dodge the permission — just a different gate.

  The grant is reasonable for this skill (it runs Figma's *first-party* capture script in the
  user's *own* app and uploads to Figma's cloud — exactly what `page-to-figma` does), but it is a
  real arbitrary-code capability, so present it as a conscious, scoped grant — don't enable it for
  untrusted work.
- **Magnetic arrows need a one-time "donor" connector (recommended).** True FigJam-style connectors
  that snap to screens and auto-reroute can't be *created* in a `/design/` file (`createConnector`
  throws), but a connector **pasted from FigJam survives** and can be cloned per edge (§4). That
  needs one human step. Ask the user up front; if they decline, fall back to static VECTOR arrows
  (§4b). Walk a non-technical user through it:

  > For arrows that snap to your screens and auto-reroute when you move things, I need one "donor"
  > connector (one-time): open any **FigJam** file → draw one connector/arrow → copy it
  > (⌘/Ctrl-C) → switch to your **design** file → paste (⌘/Ctrl-V). Style that one the way you want
  > *all* arrows to look (color, thickness, arrowhead) — every wireflow arrow copies it. Then send
  > me its link (or say "find it" and I'll locate the `CONNECTOR` node). Prefer plain static arrows?
  > Say so and I'll skip this.

  **Keep the donor permanently** — every clone depends on it.
- **One long-lived process per run — *Bash node-driver path only*.** A capture upload continues
  *after* the JS promise resolves (§1 step 4). On the **Bash node-driver path**, many agent
  sandboxes **kill still-running background jobs when a new shell command starts**, cutting off
  in-flight uploads — so there you must drive **all** screens inside **one** process, run no other
  shell command until it exits, and confirm landings *after* it exits (you can't poll mid-run).
  **On the Playwright MCP path this does not apply:** the browser session lives in the MCP server
  and survives shell commands, so you capture **one screen at a time** and interleave arrow `eval`s
  — the incremental default (§8).
- **Never wait silently — bound every wait and emit a heartbeat.** Navigation, capture, "hold", and
  poll each get a **max time budget** and print progress as they go (`fired 02…`, `poll 3/10…`). A
  step that runs for minutes with **no output is a bug, not slowness** — stop and localize (§9), do
  not sit in the wait. Set explicit timeouts on `browser_navigate` / `browser_run_code_unsafe`;
  never rely on an unbounded default, and **never `await` a promise that's known to resolve early or
  may never settle** (§1 step 3) — that is the #1 silent-hang cause.
- **Headless in a sandbox.** A headed Chromium hangs where there is no display. Use
  `headless: true` for the capture driver; reserve headed mode for interactive login via the MCP
  or the user's own browser (§6).
- **Dev servers never go `networkidle`.** Vite/HMR keeps a websocket open, so
  `waitUntil: 'networkidle'` **never resolves** and hangs the driver. Use
  `waitUntil: 'domcontentloaded'` then `waitForSelector(<app root>)`.
- **Don't pipe driver stdout through `| head`** — buffering can swallow it all. Write progress to
  a file instead (the template in §1b does this).

## 1. Capture one screen

The capture is **driven from inside the running page** (not a single MCP call): you inject Figma's
`capture.js` and call `captureForDesign` in the live page. Per screen:

1. **Get a capture handle.** Call `generate_figma_design` with the target `fileKey` (and the
   wireflow container `nodeId`, §2) and **no** `captureId`. It returns a `captureId`, an
   `endpoint`, and an injectable **`capture.js`**.
2. **Reach the exact state (Playwright).** Navigate (`domcontentloaded` + `waitForSelector`, §0)
   and drive any interaction (open the modal, switch tab, submit) so the live page shows the state.
   Apps **without deep-linkable routes must** drive state this way — see §1b.
3. **Inject + fire — do NOT `await` it to completion in the page.** Inject `capture.js`, then call
   `window.figma.captureForDesign({ captureId, endpoint, selector: 'body' })`. **Fire it; return
   from the in-page call right away.** Its promise resolves *before* the cloud upload finishes (and
   in some environments the long tail never settles), so **awaiting it inside
   `browser_run_code_unsafe` / `page.evaluate` is exactly how a run hangs silently with no output.**
   Give the in-page call a short evaluate timeout (e.g. 10–15s); treat real completion as
   out-of-band (step 5), not as "the promise returned." If it hangs here, localize per §9.
4. **Keep the page open until the upload lands — without *blocking* on it.**
   - **MCP path:** the browser stays open between tool calls on its own — do **nothing** to "hold"
     it (no in-page sleep, no in-page poll loop). Just don't close it; confirm via step 5.
   - **Bash node-driver path:** the process owns the browser, so keep it alive past the fire with a
     **bounded** guard (`waitForTimeout(10000)`), then `browser.close()` after **all** screens.
     Confirm after exit (step 5).
   ⚠️ Closing too early silently drops the capture (`pending` forever); holding/awaiting with **no
   timeout** is the mirror-image failure (**silent hang**). Bound every wait and emit a heartbeat
   (§0).
5. **Confirm by new frames (not by status).** `pending` is **ambiguous**: a never-submitted capture
   and a still-uploading one both report `pending`, so status polling alone can't tell a cut-off
   upload from a slow one. The reliable signal is a **new frame at the capture viewport size**
   (whatever you set — e.g. 1440×900) appearing — enumerate the container's (and the file's) frames
   (`$FIGMA_CLI eval 'figma.getNodeById("<containerId>").children.map(c=>({id:c.id,name:c.name,w:c.width}))'`
   or `get_metadata`) and match each expected screen to a newly-added frame; rename matched frames.
   **MCP path:** confirm each screen **immediately** (the browser isn't a shell job, so an `eval`
   won't kill it) — this is what makes the incremental build (§8) possible. **Bash node-driver
   path:** you can't poll mid-run (§0), so do this audit *after* the driver exits.

**Smoke-test ONE screen first.** The native serializer can mis-render non-Latin scripts (e.g.
Thai) and some CSS frameworks (e.g. Tailwind v4). Capture **one** screen and eyeball fidelity
**before** scaling to the whole flow — a serializer gap is far cheaper to catch on screen 1 than
on screen 6.

**Failure:** any expected screen with **no** matching frame after the run → **retry just those
screens once** (a second driver pass). If a screen still produces no frame, create a placeholder
in its slot (§5) and record the failure for the end-of-run report. Never silently drop it.

## 1b. No-routing SPA recipe (drive-then-capture, even on localhost)

Apps with **no deep-linkable routes** — every screen is the same URL with internal React/Vue
state — **cannot** be reached by opening a URL with a `#figmacapture=` hash; that loads a fresh
page at the default state and can never show "sheet open, Branches tab, override sub-sheet." For
these the **only** path is: drive the state with Playwright, then inject + fire the capture in that
same live page (§1). **This applies on `localhost` too** — there is no localhost shortcut.

Driver template — headless, one process, all screens, progress to a file. Adjust selectors per app:

```js
// node driver.js  — runs ALL captures in ONE process; never touch the shell until it exits (§0)
const { chromium } = require('playwright'); // or 'playwright-core'
const fs = require('fs');
const log = (m) => fs.appendFileSync('capture.log', m + '\n');

// One entry per screen. `drive(page)` leaves the page ON the state to capture.
// `captureId` / `endpoint` come from one generate_figma_design call per screen (§1 step 1).
const SCREENS = [
  { name: '01 Home',         captureId: '...', endpoint: '...', drive: async (p) => {} },
  { name: '02 Method sheet', captureId: '...', endpoint: '...',
    drive: async (p) => {
      await p.click('button.snav-item:has-text("Payment")');
      await p.waitForSelector('.sheet[data-screen-label="02 Method definition"]');
    } },
  // ... a sub-sheet that REPLACES its parent shares one scrim, does not stack — drive it the same way
];

(async () => {
  const browser = await chromium.launch({ headless: true });          // headless (§0)
  const ctx = await browser.newContext(/* { storageState: 'state.json' } if authed (§6) */);
  const page = await ctx.newPage();
  await page.goto('http://localhost:5173', { waitUntil: 'domcontentloaded' }); // not networkidle (§0)
  await page.waitForSelector('#root');                                 // app root

  for (const s of SCREENS) {
    await s.drive(page);
    await page.addScriptTag({ path: 'capture.js' });                   // Figma's capture.js (§1 step 1)
    await page.evaluate(({ captureId, endpoint }) =>
      window.figma.captureForDesign({ captureId, endpoint, selector: 'body' }),
      { captureId: s.captureId, endpoint: s.endpoint });
    log('fired ' + s.name);
    await page.waitForTimeout(10000);  // HOLD so the upload finishes (§1 step 4). Do NOT close early.
  }
  await browser.close();               // only after ALL screens fired + held
  log('done');
})();
```

Fetch all the per-screen `captureId`/`endpoint` handles **first** (one `generate_figma_design`
call each, §1 step 1), then run the driver once over all screens. After it exits, audit which
frames landed (§1 step 5) and retry any that didn't.

## 2. One page, one container

A wireflow needs all screens on **one** page. Before capturing, create one wireflow page +
a container frame:

```bash
$FIGMA_CLI eval '(function(){
  const page = figma.createPage(); page.name = "Wireflow";
  figma.currentPage = page;
  const c = figma.createFrame(); c.name = "WireflowBoard";
  c.layoutMode = "NONE"; c.clipsContent = false; c.fills = [];
  return { pageId: page.id, containerId: c.id };
})()'
```

**Reparent is the primary strategy — passing the container `nodeId` to `generate_figma_design` is
unreliable.** Captures frequently still land **loose on an unrelated page** even when the `nodeId`
is supplied. So: still pass the `nodeId` (it helps when it works), but **expect to reparent**.
After each capture lands (§1 step 5), locate the new frame by scanning for recently-added
viewport-size frames **wherever they landed** (not only inside the container), then move it onto
the container — via `use_figma` (primary, async) or `$FIGMA_CLI eval` (fallback):

```js
// use_figma (primary):
(await figma.getNodeByIdAsync("<containerId>")).appendChild(await figma.getNodeByIdAsync("<frameId>"))
// $FIGMA_CLI eval (fallback): figma.getNodeById("<containerId>").appendChild(figma.getNodeById("<frameId>"))
```

## 3. Arrange — lanes + branch drop-rows

Place full-size captured frames; do not scale. Constants: `GUTTER_X = 240`, `GUTTER_Y = 160`.

- Each flow = a row. Walk the flow in order; place frame *i* at
  `x = rowOriginX + Σ(prev widths + GUTTER_X)`, `y = rowY`.
- A **branch** (a node with >1 outgoing edge): the primary next stays on the row; each
  additional target drops to a sub-row at `y = rowY + maxRowHeight + GUTTER_Y` and continues.
- Set each frame's `x`/`y` in one batch (via `use_figma` async, or `$FIGMA_CLI eval` fallback):
  `frames.forEach(f => { const n = figma.getNodeById(f.id); n.x = f.x; n.y = f.y; })`
  (`use_figma`: `for (const f of frames) { (await figma.getNodeByIdAsync(f.id)) ... }`).
- **Size the corridor by fan-out.** Connector labels auto-center on the line, so de-crowd with
  *frame spacing*, not label moves: a wide fan (e.g. 6 branches off one screen) crowds at the
  default `GUTTER_Y`; widen that row's drop gap (~580px for ~6 branches) so the connectors and their
  labels spread along the bus. Because magnetic connectors (§4) auto-reroute, **just move the
  frames** (`frame.y` + resize the board) — no arrow edits needed.

## 4. Connect screens with a magnetic connector (clone the donor) — primary

`createConnector()` **throws** in a `/design/` file (connectors are FigJam-only). **But** a
connector **copy-pasted from FigJam into the design file survives as a real `CONNECTOR` node**, and
the Plugin API can read/write its `connectorStart` / `connectorEnd` / `magnet`. So a single pasted
**donor** (§0) is **cloned and re-pointed** for every edge — giving true magnetic, `ELBOWED`,
auto-rerouting arrows whose label rides on the line and whose style is inherited from the donor.
If no donor exists, use the VECTOR fallback (§4b).

Per edge `A → B`, via **`use_figma`** (load `figma-use` first; **batch ~5–6 edges per call** —
scripts are atomic, a throw rolls the whole batch back):

```js
const src   = await figma.getNodeByIdAsync(DONOR_ID);   // the pasted FigJam connector (§0)
const board = await figma.getNodeByIdAsync(BOARD_ID);
let pg = board; while (pg && pg.type !== "PAGE") pg = pg.parent;
await figma.setCurrentPageAsync(pg);                    // endpoints must live on this page

const c = src.clone();
board.appendChild(c);                                   // ⚠ appendChild BEFORE setting endpoints
c.connectorStart = { endpointNodeId: FRAME_A, magnet: START_MAGNET };
c.connectorEnd   = { endpointNodeId: FRAME_B, magnet: END_MAGNET };
c.name = "C · " + label;

await figma.loadFontAsync({ family: "Inter", style: "Regular" });   // before writing text
c.text.fontName   = { family: "Inter", style: "Regular" };
c.text.fontSize   = 16;
c.text.characters = label;                              // label rides ON the connector
```

**Magnets** (`"AUTO" | "TOP" | "BOTTOM" | "LEFT" | "RIGHT"`), chosen per edge direction:

| Edge kind | start | end |
|---|---|---|
| horizontal spine (left→right) | `RIGHT` | `LEFT` |
| vertical drop (branch to row below) | `BOTTOM` | `TOP` |
| let Figma decide | `AUTO` | `AUTO` |

`connectorLineType` is inherited `ELBOWED` — it auto-routes orthogonally and fans multiple
connectors leaving the same magnet edge. A placeholder ("⚠ Capture failed") frame is a valid
endpoint too.

**Hard rules / gotchas:**
- **`appendChild` BEFORE setting endpoints** — endpoint nodes must share the connector's page; the
  clone lands on the donor's page, so move it onto the board first.
- `clone()` **preserves the `CONNECTOR` type**; `createConnector` stays unavailable — never call it.
- **Keep the donor** — every clone depends on it; don't delete it.
- `loadFontAsync` before `c.text.characters`.
- Batch ~5–6 connectors per `use_figma` call (atomic rollback on any throw).

**Connector read-back check:** assert `clone.type === "CONNECTOR"` and that
`connectorStart.endpointNodeId` / `connectorEnd.endpointNodeId` equal the intended `FRAME_A` /
`FRAME_B`. **No arrowhead/strokeCap check is needed** — the head is the donor's, inherited; the
VECTOR `strokeCap` fragility (§4b) does not exist on this path.

## 4b. VECTOR fallback (no donor connector available)

When the user declines the donor step, draw a static axis-aligned VECTOR with an arrow cap (no
rotation math) from source right-mid to target left-mid, plus an Inter label at the elbow. These are
**static** — they do not attach to frames or re-route when a screen moves.

```bash
$FIGMA_CLI eval '(async function(){
  const a = figma.getNodeById("SRC_ID"), b = figma.getNodeById("DST_ID");
  const ax = a.x + a.width, ay = a.y + a.height/2;
  const bx = b.x, by = b.y + b.height/2;
  const mx = (ax + bx) / 2;
  const v = figma.createVector();
  v.x = 0; v.y = 0; v.name = "→ " + b.name;
  v.vectorPaths = [{ windingRule: "NONE",
    data: "M " + ax + " " + ay + " L " + mx + " " + ay + " L " + mx + " " + by + " L " + bx + " " + by }];
  v.strokes = [{ type: "SOLID", color: { r: 0.2, g: 0.2, b: 0.2 } }];
  v.strokeWeight = 2; v.strokeCap = "ARROW_LINES";
  // NOTE: if the arrowhead does not render, the node-level strokeCap alone may be
  // insufficient when geometry came from vectorPaths (assigning vectorPaths regenerates
  // the underlying vectorNetwork whose per-vertex strokeCap defaults to NONE).
  // Fallback to try during the live run: read v.vectorNetwork, set the LAST vertex's
  // strokeCap = "ARROW_LINES", then reassign via await v.setVectorNetworkAsync(network).
  let labelId = null;
  const LABEL = "LABEL_TEXT";
  if (LABEL) {
    await figma.loadFontAsync({ family: "Inter", style: "Regular" });
    const t = figma.createText();
    t.fontName = { family: "Inter", style: "Regular" };
    t.characters = LABEL; t.fontSize = 14;
    t.x = mx - t.width / 2; t.y = Math.min(ay, by) - 22;
    labelId = t.id;
  }
  return { arrow: v.id, label: labelId, p0: [ax, ay], p1: [bx, by] };
})()'
```

A placeholder target ("⚠ Capture failed") is still a valid `DST_ID` — arrows draw to it too.

**VECTOR read-back check:** assert the returned `p0 ≈ source right-mid` and `p1 ≈ target
left-mid` (±2px). If off, the source/target ids or rects were wrong — fix before continuing.
Additionally, **confirm that an arrowhead actually rendered**: read the end vertex's `strokeCap`
(via `v.vectorNetwork`) and assert it is not `"NONE"`. Endpoints matching does not prove the
head drew — a headless line that passes the ±2px endpoint check is a **silent failure**. If the
cap is `NONE`, apply the per-vertex `setVectorNetworkAsync` fallback described in the code
comment above before continuing. (The magnetic connector path, §4, avoids all of this.)

## 5. Placeholder frame for a failed capture

```bash
$FIGMA_CLI eval '(async function(){
  const c = figma.getNodeById("CONTAINER_ID");
  const f = figma.createFrame(); f.name = "⚠ Capture failed: SCREEN — REASON";
  f.resize(800, 600); f.x = X; f.y = Y;
  f.fills = [{ type: "SOLID", color: { r: 0.98, g: 0.9, b: 0.9 } }];
  c.appendChild(f);
  return { id: f.id };
})()'
```

## 6. Auth (default: interactive login, reuse session)

Interactive login needs a **headed** browser, which only works via a **Playwright MCP** or the
**user's own browser** — **not** in a headless-only agent sandbox (§0), where a headed browser
hangs. If you're headless-only, skip steps 1–2 and use the user-provided `storageState` fallback
below.

1. Open a **headed** Playwright browser at the login URL; **pause** and ask the user to log in
   (they handle MFA / SSO / CAPTCHA).
2. On their go-ahead, save `storageState` to an ephemeral temp file and reuse it for every
   capture + crawl navigation in this run.
3. **Delete the `storageState` file at end of run.** Never write credentials/cookies/tokens to
   the repo, the Figma file, or any output.
4. On a block / CAPTCHA / MFA wall mid-run: **hand the live browser to the user** to clear it,
   then resume. Never attempt to evade or automate the challenge.

Fallbacks (only if the user asks): load a user-provided `storageState`/cookies/token; or
(discouraged) fill the login form once from user-supplied credentials — never stored or logged.

## 7. Crawl (optional flow source)

Prompt the user to confirm/adjust bounds, defaults: **same-origin + path-prefix under the start
URL, max depth 3, cap ~20 screens.** Within bounds, drive the app, follow **non-destructive**
nav only (never click delete/pay/submit-like actions — ask for a recipe instead). Record each
edge's trigger from the observed click (visible text / selector / resulting URL, e.g.
`click "Checkout"`); an edge you can't label is surfaced for the user to name, never invented.
Emit a **proposed** graph and get user confirmation **before** any capture or arrow.

## 8. Incremental build — capture → place → connect, one screen at a time (default)

On the **Playwright MCP path** the browser session lives in the MCP server and survives shell
commands (§0), so don't batch. Build the wireflow **incrementally** — capture one screen, place it,
connect it, then move on. It's more robust (a mid-run failure leaves a *connected* partial flow,
not a pile of loose captures) and lets you verify each link as you go.

1. **Confirm the flow graph first** (Flow sources / §7) and **precompute each node's lane slot**
   from the graph (§3) — expected `x`/`y` using the capture viewport width (e.g. 1440; refine once
   real widths land). You know the whole graph up front, so the layout is deterministic.
2. **Walk the flow in order.** For each node the walk reaches:
   a. **Capture it** (§1) — reach the state, inject + fire, **hold until the upload lands**, then
      confirm the new frame **immediately** (MCP browser isn't a shell job, so an `eval` won't kill
      it — §1 step 5).
   b. **Reparent + place** it: `appendChild` onto the container (§2) and set its `x`/`y` to its
      precomputed slot (§3).
   c. **Connect every edge whose *both* endpoints are now placed** — clone + re-point a connector
      (§4; VECTOR if no donor, §4b) with the edge label, and read-back-check each. Usually that's
      the edge from the just-captured node's predecessor, but doing it by "both endpoints placed"
      also closes **merges** and **back-edges** correctly. (Magnetic connectors auto-reroute, so
      later frame moves won't break earlier edges.)
3. **Branches** are just nodes with >1 outgoing edge — capture each target as the walk reaches it
   (drop-row per §3, widen the corridor by fan-out) and connect each edge when both endpoints exist.

Failed capture → drop a placeholder in its slot (§5), still connect its edges, continue (§1 failure).

**Batch fallback (Bash node-driver path only):** without an MCP, interleaving an arrow `eval`
between captures would kill the driver (§0) — so capture **all** screens in one process, then
arrange (§3) and draw **all** arrows (§4) after it exits.

## 9. If a capture hangs — localize, don't wait

A capture that runs minutes "with no output" is a **silent hang**, not slow progress. Stop and find
*where* it's stuck before retrying — the fix differs completely by location. Run this cheap, bounded
ladder (MCP path) and act on the first step that stalls:

1. **Browser alive?** `browser_run_code_unsafe` returning `1+1`. Hangs → the MCP browser is wedged
   (e.g. launched **headed with no display** §0, or never started) → restart it. Works → not the
   browser; continue.
2. **Navigation?** `browser_navigate` to the URL (force **`domcontentloaded`, never `networkidle`**
   — Vite HMR never idles, §0), then `browser_take_screenshot`. Hangs → the wait-state or dev
   server; switch to `domcontentloaded` + a `waitForSelector` on the app root.
3. **Console clean?** `browser_console_messages` right after injecting `capture.js`. **The
   high-value check** — a **CSP** violation, a **CORS**-blocked upload to `endpoint`, or a font /
   resource error here means `capture.js` can't run or its upload is blocked, so the promise never
   settles. Fix the CSP/CORS/origin rather than waiting.
4. **Fire WITHOUT await.** Call `captureForDesign(...)` fire-and-forget (don't await the in-page
   promise) and return a marker immediately (§1 step 3). Returns instantly → the hang was the
   `await`; switch to fire-then-poll. Still hangs even fire-and-forget → the in-page call itself is
   blocked (back to step 3).
5. **Frame landed?** Poll `generate_figma_design(fileKey, captureId)` and enumerate container frames
   (§1 step 5), **bounded + with progress**. Appears → success, stop. Never appears → upload blocked
   (step 3) or wrong `endpoint` / `captureId`.

Whatever you find, **report it** — a silent multi-minute wait is never an acceptable end state.
