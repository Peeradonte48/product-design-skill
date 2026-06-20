# CSS → Figma fidelity map

The skill's default extraction handles solid fills, box metrics, uniform borders, radius, and
basic type. This reference covers the **richer CSS** the page may use — gradients, blur /
glassmorphism, blend modes, `object-fit`, transforms, `text-transform`, mixed inline runs,
per-side / dashed borders, and modern color. Each row says **what to capture** (step 1),
**how to build it** (step 3), and **what to read back** (step 4) so the property is *verified*,
not just emitted.

## How to use this map

The build splits the same way the skill already splits work:

- **JSX-direct** — the `render` / `render-batch` JSX has a prop for it; set it at build time.
- **eval-mutate** — JSX has no prop; set it in the **step-4 correction `eval` batch** that
  already mutates existing nodes (render the structure, then stamp the rich property on top).
- **log() + rasterize** — no faithful Figma target; fall back to a `log()`ged image of that
  subtree (same contract as the flat-fallback and unwalkable rules).

**Every row is also a checklist item.** If you build a property, add its read-back to the
step-4 verify so a dropped gradient or a lost blend mode fails closed — the lesson of the
position and completeness gates: *unmeasured ⇒ unbuilt.*

## Normalize color FIRST — to sRGB

Figma paints are sRGB `{r,g,b,a}` in 0–1. Modern pages emit `oklch()`, `lab()`, `color(display-p3 …)`,
and `color-mix()` (Tailwind v4 ships `oklch` by default), and `getComputedStyle` may serialize
the color in its authored space. **Normalize every captured color to sRGB before recording or
asserting it.** Robust, dependency-free method: paint the computed color onto a 1×1 `<canvas>`
and read it back —

```js
const ctx = document.createElement('canvas').getContext('2d');
ctx.fillStyle = computedColor;          // any CSS color, any space
ctx.fillRect(0, 0, 1, 1);
const [r, g, b, a] = ctx.getImageData(0, 0, 1, 1).data;   // sRGB 0–255, gamut-clamped
```

This forces the browser's own sRGB conversion (incl. P3 gamut clamping) — more reliable than a
hand-rolled oklch→sRGB matrix. Record the sRGB value; assert exact-hex against it.

## The map

| CSS | Figma target | Where | Build / verify |
|-----|--------------|-------|----------------|
| `background-image: linear-gradient()` | `GRADIENT_LINEAR` paint | eval | Set `fills=[{type:'GRADIENT_LINEAR', gradientTransform, gradientStops:[{position,color:{r,g,b,a}}]}]`; encode the CSS angle in `gradientTransform`. **Verify:** `fills[].type` + stop colors/positions. |
| `radial-gradient()` | `GRADIENT_RADIAL` | eval | Same shape, `type:'GRADIENT_RADIAL'`. |
| `conic-gradient()` | `GRADIENT_ANGULAR` | eval | Same shape, `type:'GRADIENT_ANGULAR'`. |
| multiple background layers | stacked paints | eval | Push one paint per layer onto `fills` (bottom CSS layer = first). |
| `filter: blur(N)` (element) | `LAYER_BLUR` | **JSX** `blur={N}` | **Verify:** `effects[]` has `LAYER_BLUR` radius N. |
| `backdrop-filter: blur(N)` (**glassmorphism**) | `BACKGROUND_BLUR` | **JSX** `bgBlur={N}` (or `glass` for the full glass look) | **Verify:** `effects[]` has `BACKGROUND_BLUR` radius N. |
| `mix-blend-mode: X` | `blendMode` | **JSX** `blendMode` (Frame) / eval (other nodes) | Map keyword→enum: `multiply`→`MULTIPLY`, `screen`→`SCREEN`, `overlay`→`OVERLAY`, `darken`→`DARKEN`, `lighten`→`LIGHTEN`, `color-dodge`→`COLOR_DODGE`, `color-burn`→`COLOR_BURN`, `hard-light`→`HARD_LIGHT`, `soft-light`→`SOFT_LIGHT`, `difference`→`DIFFERENCE`, `exclusion`→`EXCLUSION`, `hue`/`saturation`/`color`/`luminosity`→same upper. **Verify:** `blendMode`. |
| `object-fit` on an image | image-paint `scaleMode` | **JSX** `imageScale` / eval | `cover`→`FILL`, `contain`→`FIT`, `none`→`CROP` (at natural size), `scale-down`→`FIT`. **Verify:** the image paint's `scaleMode`. |
| `transform: rotate(θ)` | node rotation | **JSX** `rotate={θ}` | **Verify:** `rotation`. |
| `transform: scale()` | (no rotation needed) | — | Already reflected in the **measured rect** (`getBoundingClientRect` is post-transform) — build to the rendered size; nothing extra to set. |
| `transform: skew() / matrix3d / perspective` | **none** | **log()+rasterize** | No faithful Figma target — `log()` the subtree and rasterize it to an image (per step 3's rasterize rule). |
| `text-transform: X` | `textCase` | eval | `uppercase`→`UPPER`, `lowercase`→`LOWER`, `capitalize`→`TITLE`, `none`→`ORIGINAL`. (`<Text>` JSX has no `textCase`, so set it post-render and keep the original string.) **Verify:** `textCase`. Alternative: capture the *visibly transformed* string and render that directly. |
| `text-decoration` (underline/strike) | `textDecoration` | eval | `UNDERLINE` / `STRIKETHROUGH`. **Verify:** `textDecoration`. |
| `text-overflow: ellipsis` / `-webkit-line-clamp:N` | truncation | **JSX** `truncate` / `maxLines={N}` | Capture the **visible (clamped) text**, not the full string, when you can't truncate. **Verify:** `truncate`/`maxLines` or the rendered text. |
| mixed inline runs (`<p>` with `<b>`,`<a>`,`<em>`) | one Text node, styled ranges | eval | Build the Text leaf with the *base* style + concatenated string; capture per-run `[start,end,style]`; then `setRange*` per run (`setRangeFontName`, `setRangeFontSize`, `setRangeFills`, `setRangeTextDecoration`). **Verify:** spot-check a couple of ranges. |
| per-side borders (`border-top` ≠ others) | individual stroke weights | eval | `strokeTopWeight` / `strokeRightWeight` / `strokeBottomWeight` / `strokeLeftWeight`. **Verify:** the four weights. |
| `border-style: dashed/dotted` | `dashPattern` | eval | `dashPattern=[dash,gap]` (dotted ≈ `[w,w]`). **Verify:** `dashPattern`. |
| `border-image` | **none** (clean) | **log()+rasterize** or approximate | No faithful target — rasterize the bordered box or approximate with a solid stroke and `log()`. |
| multiple / `inset` box-shadows | `effects[]` array | eval (JSX `shadow`/`innerShadow` cover the single case) | One effect per shadow: `{type:'DROP_SHADOW'|'INNER_SHADOW', color, offset:{x,y}, radius, spread, visible:true}`. **Verify:** `effects[]` length + fields. |
| `opacity` (element vs `rgba` fill) | layer opacity vs fill alpha | **JSX** `opacity` / fill alpha | Element `opacity`→node `opacity`; `rgba()`/alpha channel→the paint's `a`. Keep them distinct. |

## What has no faithful equivalent — `log()` it

Don't fake these silently; `log()` the subtree and either rasterize it or approximate with a
noted compromise, so the loss is visible up front (same rule as flat-fallback / unwalkable):

- `transform: skew()`, `matrix3d()`, `perspective`, 3D rotations.
- `border-image`, complex `clip-path` (non-rect polygons), `mask-image`.
- `filter` functions beyond blur (`brightness`, `contrast`, `hue-rotate`, `drop-shadow` stacks)
  when they can't be expressed as a Figma effect.

## Cross-references

- **Step 1 (extract):** capture these properties per-node, and run the color-normalization
  pass on every color first.
- **Step 3 (build):** JSX-direct rows at render time; eval-mutate rows in the same correction
  batch that fixes numeric drift; log()+rasterize rows via the step-3 rasterize rule.
- **Step 4 (verify):** add each built row's read-back to the numeric checklist so a dropped
  gradient / blur / blend / case fails closed.
