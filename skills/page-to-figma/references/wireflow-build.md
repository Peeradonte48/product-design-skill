# Wireflow build mechanics (page-to-figma)

Concrete recipes the skill calls. `$FIGMA_CLI` is the vendored CLI
(`node ~/.claude/figma-cli/src/index.js`, or the project copy).

## 1. Capture one screen

`generate_figma_design` is agent-invocable and headless. Per screen:

1. Reach the exact state first (Playwright): navigate to the URL/route and drive any
   interaction (open the modal, submit the form) so the live page shows the state to capture.
2. Call `generate_figma_design` with the target `fileKey` **and the wireflow container
   `nodeId`** (so every capture lands on one page — see §2). No `captureId` on the first call.
3. Poll: call again with the returned `captureId` **every 5 seconds, up to 10 times**, until
   `status: completed`. Each `captureId` is single-use.
4. On `completed`, find the new frame: enumerate the container's children
   (`$FIGMA_CLI eval 'figma.getNodeById("<containerId>").children.map(c=>({id:c.id,name:c.name}))'`
   or `get_metadata`) and take the newly-added frame. Rename it to the screen name.

**Failure:** if polling exhausts (10×) or the call errors, **retry the whole capture once**.
If it still fails, create a placeholder in its slot (§4) and record the failure for the
end-of-run report. Never silently drop it.

## 2. One page, one container

Captures default to a **new page per call** unless a `nodeId` is passed. A wireflow needs all
screens on one page, so before capturing, create one wireflow page + a container frame and pass
its id to every capture:

```bash
$FIGMA_CLI eval '(function(){
  const page = figma.createPage(); page.name = "Wireflow";
  figma.currentPage = page;
  const c = figma.createFrame(); c.name = "WireflowBoard";
  c.layoutMode = "NONE"; c.clipsContent = false; c.fills = [];
  return { pageId: page.id, containerId: c.id };
})()'
```

**Fallback** if a capture still lands on its own page: reparent it onto the container —
`figma.getNodeById("<containerId>").appendChild(figma.getNodeById("<frameId>"))`.

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
