// Desktop: holding G lays the page's construction over it: the six fields of the layout (`space`
// in tokens.stylex.ts) and the 8px grid every line pitch is made of, drawn in the hairline colour
// of the fixed cross (`layout.tsx`). Shown on the key's press and gone on its release, with no
// fade either way: it is a look under the page, under the reader's hand, not a state.
//
// The fields hang from the layout block's measured left edge, not from a copy of its centring
// arithmetic: the wrapper's margin grows beside a notch and the block narrows below 816px, and the
// lines must stay on the edges the text actually uses. The 8px rows are fixed to the viewport, like
// the cross, so the sticky sidebar and every fixed rule sit on them while the page scrolls.

import { isCommandKey } from "./keys.ts";
import { colors, space } from "./tokens.stylex.ts";

const desktop = matchMedia("(min-width: 768px)");
/** Six fields: the sidebar's two and the text's four. */
const fields = 6;

/** Field edges at the cross's strength; the 8px rows at half, so the columns read first. */
const rows = `color-mix(in oklab, ${colors.hairline} 50%, transparent)`;

function build(): { overlay: HTMLElement; frame: HTMLElement } {
  const overlay = document.createElement("div");
  overlay.ariaHidden = "true";
  overlay.dataset.grid = "";
  overlay.style.cssText = [
    "position:fixed",
    "inset:0",
    // Over everything, the enlarged artwork (`zoom.ts`) and the page scrollbar included.
    "z-index:10000",
    "pointer-events:none",
    "display:none",
    `background:repeating-linear-gradient(to bottom, ${rows} 0 1px, transparent 1px ${space.unit})`,
  ].join(";");
  const frame = document.createElement("div");
  frame.style.cssText = "position:absolute;inset-block:0";
  for (let index = 0; index < fields; index += 1) {
    const field = document.createElement("div");
    // A field is a title column wide; fields stand a gutter (the layout gap) apart. Its lines sit
    // inside it: the first pixel column where its text starts, the last where its text ends. The
    // last field ends on the block's own edge, so where the block narrows (the text column is
    // `1fr`) it narrows with it and still marks where the dates end.
    field.style.cssText = [
      "position:absolute",
      "inset-block:0",
      `left:calc(${index} * (${space.titleColumn} + ${space.layoutGap}))`,
      index === fields - 1 ? "right:0" : `width:${space.titleColumn}`,
      `border-inline:1px solid ${colors.hairline}`,
    ].join(";");
    frame.append(field);
  }
  overlay.append(frame);
  document.body.append(overlay);
  return { overlay, frame };
}

export function enableGrid() {
  let grid: { overlay: HTMLElement; frame: HTMLElement } | null = null;
  let held = false;

  const hide = () => {
    held = false;
    if (grid) grid.overlay.style.display = "none";
  };

  const place = () => {
    if (!grid || !held) return;
    // The two-column block: the sidebar's parent, as in `align.ts`.
    const layout = document.querySelector("aside")?.parentElement;
    if (!desktop.matches || !layout) return hide();
    const box = layout.getBoundingClientRect();
    grid.frame.style.left = `${box.left}px`;
    grid.frame.style.width = `${box.width}px`;
  };

  const show = () => {
    if (held || !desktop.matches) return;
    held = true;
    grid ??= build();
    grid.overlay.style.display = "block";
    place();
  };

  document.addEventListener("keydown", (event) => {
    // Caps Lock reads as "G"; Shift+G is someone typing a capital, not asking for the grid.
    if (event.key.toLowerCase() !== "g" || event.shiftKey || !isCommandKey(event)) return;
    show();
  });
  // Any release of the key hides it, whatever else was pressed meanwhile.
  document.addEventListener("keyup", (event) => {
    if (event.key.toLowerCase() === "g") hide();
  });
  // A key released in another window or tab never reaches this one.
  addEventListener("blur", hide);
  document.addEventListener("visibilitychange", hide);
  addEventListener("resize", place);
}
