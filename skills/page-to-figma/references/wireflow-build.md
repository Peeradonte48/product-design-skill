# Wireflow build mechanics (page-to-figma)

Concrete recipes the skill calls. `$FIGMA_CLI` is the vendored CLI
(`node ~/.claude/figma-cli/src/index.js`, or the project copy).

## 0. Driver prerequisites & environment (check before any capture)

These are the things a real run will fail on if you skip them. Check §0 first.

- **Playwright is a hard, fail-closed dependency. Prefer a Playwright MCP.** It runs in the
  user's environment and can open a headed browser for login. **Check for it up front.** If there
  is no Playwright MCP **and** no importable `playwright` / `playwright-core` on a reachable path,
  **stop and tell the user to install it** —
  `claude mcp add playwright npx @playwright/mcp@latest` (then restart the session). Do **not**
  improvise a driver by hand-locating a cached Chromium binary; that is the slow, fragile path the
  MCP exists to avoid. With the MCP present, the whole drive-then-capture flow is trivial.
- **Pre-authorize the in-page code-execution tool — the most common hard block.** Capture *must*
  run Figma's `capture.js` inside the live page (§1 step 3), so it needs a tool that executes
  arbitrary JS in the page, and those are **denied by default**. The agent **cannot self-grant**
  it (a classifier blocks even the attempt to add the permission) — only the user can. So confirm
  it's allowed **before** capturing; being blocked partway in wastes the whole run.

  **Walk the user through the grant — assume they are not technical.** Don't just print a tool
  name. When the tool is blocked (or up front, in step 1 of the pipeline), tell the user, in plain
  language, something like this and **wait** for them to confirm before retrying:

  > To copy your page into Figma I need a one-time permission: to run Figma's capture script inside
  > your app's browser tab. Your setup blocks that by default and I'm not allowed to turn it on
  > myself — you have to. It takes ~20 seconds:
  >
  > 1. In **this project's** folder, open the file `.claude/settings.local.json`.
  >    (If it doesn't exist, create it with the full contents shown below.)
  > 2. Add `"mcp__playwright__browser_run_code_unsafe"` to the `permissions.allow` list.
  > 3. Save the file. If I still can't proceed right after, restart this session so it loads.
  > 4. Tell me "continue".
  >
  > File doesn't exist yet — paste this whole thing in:
  > ```json
  > { "permissions": { "allow": ["mcp__playwright__browser_run_code_unsafe"] } }
  > ```
  > File already exists — just add the line inside the existing `allow` array:
  > ```json
  > { "permissions": { "allow": [ "...your existing entries...",
  >   "mcp__playwright__browser_run_code_unsafe" ] } }
  > ```
  > This only lets me run Figma's own capture script in your own app to send it to your own Figma —
  > exactly what this command does. It's safe to leave on for this; you can remove the line later.

  - **The user must make the change — don't assume you can.** A live run showed the guard also
    blocks the agent from *adding the permission rule itself*, so don't promise to "just do it" and
    then dead-end. You may *offer* to edit the file if they ask, but if that edit is blocked, fall
    back to walking them through the manual steps above. The human grants; you guide.
  - **Bash node-driver path (§1b):** needs Bash + an importable `playwright`/`playwright-core`; it
    runs the same in-page JS via `page.addScriptTag` + `page.evaluate`, so it may hit its own
    guard. Not a way to dodge the permission — just a different gate.

  The grant is reasonable for this skill (it runs Figma's *first-party* capture script in the
  user's *own* app and uploads to Figma's cloud — exactly what `page-to-figma` does), but it is a
  real arbitrary-code capability, so present it as a conscious, scoped grant — don't enable it for
  untrusted work.
- **One long-lived process per run.** A capture upload continues *after* the JS promise resolves
  (§1 step 4). In many agent sandboxes **starting a new shell command kills still-running
  background jobs**, which cuts off in-flight uploads. So drive **all** screens inside **one**
  process and **do not run any other shell command until it self-exits**. This also means you
  generally **cannot** poll the Figma file mid-run (that `eval`/MCP call is a new shell that would
  kill the driver) — confirm landings *after* the driver exits (§1 step 5).
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
3. **Inject + fire.** Inject `capture.js` into the page, then call
   `window.figma.captureForDesign({ captureId, endpoint, selector: 'body' })` (or a tighter
   selector for a sub-region).
4. **Hold the page open until the upload is confirmed received.** ⚠️ **CRITICAL.**
   `captureForDesign` resolves **before** the screenshot finishes uploading to Figma's cloud.
   **Closing the page/context now silently drops the capture** — it sits at `pending` forever and
   no frame ever lands. Do **not** close on promise-resolve. Either `await` a true completion
   signal if the capture API exposes one, or hold each screen open with a generous in-process wait
   (seconds, not ~0.5s) before moving on. Only `browser.close()` after **every** screen is done.
5. **Confirm by new frames — after the driver exits.** `pending` is **ambiguous**: a
   never-submitted capture and a still-uploading one both report `pending`, so status polling alone
   can't tell a cut-off upload from a slow one. The reliable signal is a **new ~1600px frame**
   appearing. Because polling mid-run would kill the driver (§0), do the audit *after* it exits:
   enumerate the container's (and the file's) frames
   (`$FIGMA_CLI eval 'figma.getNodeById("<containerId>").children.map(c=>({id:c.id,name:c.name,w:c.width}))'`
   or `get_metadata`) and match each expected screen to a newly-added frame. Rename matched frames
   to their screen names.

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
After each capture lands (§1 step 5), locate the new frame by scanning for recently-added ~1600px
frames **wherever they landed** (not only inside the container), then move it onto the container —

```bash
$FIGMA_CLI eval 'figma.getNodeById("<containerId>").appendChild(figma.getNodeById("<frameId>"))'
```

## 3. Arrange — lanes + branch drop-rows

Place full-size captured frames; do not scale. Constants: `GUTTER_X = 240`, `GUTTER_Y = 160`.

- Each flow = a row. Walk the flow in order; place frame *i* at
  `x = rowOriginX + Σ(prev widths + GUTTER_X)`, `y = rowY`.
- A **branch** (a node with >1 outgoing edge): the primary next stays on the row; each
  additional target drops to a sub-row at `y = rowY + maxRowHeight + GUTTER_Y` and continues.
- Set each frame's `x`/`y` in one `eval` batch:
  `frames.forEach(f => { const n = figma.getNodeById(f.id); n.x = f.x; n.y = f.y; })`.

## 4. Draw a labeled arrow (orthogonal, static)

Native connectors are FigJam-only; draw an axis-aligned VECTOR with an arrow cap (no rotation
math) from source right-mid to target left-mid, plus an Inter label at the elbow:

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

**Arrow read-back check:** assert the returned `p0 ≈ source right-mid` and `p1 ≈ target
left-mid` (±2px). If off, the source/target ids or rects were wrong — fix before continuing.
Additionally, **confirm that an arrowhead actually rendered**: read the end vertex's `strokeCap`
(via `v.vectorNetwork`) and assert it is not `"NONE"`. Endpoints matching does not prove the
head drew — a headless line that passes the ±2px endpoint check is a **silent failure**. If the
cap is `NONE`, apply the per-vertex `setVectorNetworkAsync` fallback described in the code
comment above before continuing.

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
