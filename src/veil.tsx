import * as stylex from "@stylexjs/stylex";
import { colors, media, space } from "./tokens.stylex.ts";

/**
 * A veil across the top of the viewport on scrolling desktop pages: what scrolls up under it sinks
 * into shadow, as the top of Batoni's "Vulcan" falls into umber, so the name over it stays
 * readable. A soft blur (16px) under the page color at 72%: text dims and softens as it rises;
 * nothing glows. Over empty page the veil is the page itself, so it has no shape of its own: full
 * width, with no side edges, and only text passing under it shows it is there.
 *
 * It starts 24px above the viewport: a blur ending exactly at the top edge thins out there and
 * leaves a sharp strip; started above, it stays full to the edge. A mask holds it solid to just
 * past the name, then eases it out in factory.com's steps, so it has no visible lower edge.
 *
 * Phones have none: the pinned name has no background, the page scrolls beneath it, and Safari's
 * own top bar blurs what passes under the status bar. Safari 26 samples a fixed element with a
 * background or backdrop filter at the top edge, even at opacity 0, and tints its top bar flat
 * from it, so a veil there cut Safari's blur off at the page's edge.
 *
 * It rises in over the first 48px of scroll (the page's top inset), so at rest it covers nothing:
 * the page's first line starts below it. It is hidden unless the scroll timeline drives it: a page
 * that does not scroll has an inactive timeline, and browsers without scroll-driven animations have
 * none. The sidebar sits above it (z-index 100).
 */
export function Veil() {
  return <div {...stylex.props(styles.veil)} aria-hidden="true" />;
}

const scrollDriven = "@supports (animation-timeline: scroll())";
const above = `calc(3 * ${space.unit})`;
/**
 * How far down the veil is solid, from its top: 38px into the viewport, as factory.com's. Below
 * it, factory.com's fade: 78% after 33px, 42% after 74px, none after 121px.
 */
const solid = `calc(${above} + 38px)`;
const fade = `linear-gradient(black ${solid}, rgb(0 0 0 / 0.78) calc(${solid} + 33px), rgb(0 0 0 / 0.42) calc(${solid} + 74px), transparent calc(${solid} + 121px))`;

const rise = stylex.keyframes({ from: { opacity: 0 }, to: { opacity: 1 } });

const styles = stylex.create({
  veil: {
    // `display: none` on phones, not opacity: Safari samples hidden fixed elements too.
    display: { default: "none", [scrollDriven]: { default: "block", [media.mobile]: "none" } },
    position: "fixed",
    insetInline: 0,
    top: `calc(-1 * ${above})`,
    height: `calc(${solid} + 121px)`,
    zIndex: 99,
    pointerEvents: "none",
    opacity: 0,
    animationName: rise,
    animationTimingFunction: "linear",
    animationFillMode: "both",
    animationTimeline: "scroll(root)",
    animationRange: `0 ${space.pageInset}`,
    backdropFilter: "blur(16px)",
    backgroundColor: `color-mix(in oklch, ${colors.bg} 72%, transparent)`,
    maskImage: fade,
  },
});
