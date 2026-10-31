import * as stylex from "@stylexjs/stylex";
import { useEffect, useRef, useState } from "preact/hooks";
import { Row } from "../row.tsx";
import { groups, projects } from "../site.ts";
import { colors, media, rootMarker, rowMarker, space } from "../tokens.stylex.ts";
import { Figures, ui } from "../ui.tsx";

/**
 * The homepage project table in two groups, each under its label: Projects (software Gil
 * maintains: name and one line), then Design (client work and studies: name, what was made, year).
 * The label sits where a table header would, with the header's hairline under it; the second
 * label stands two row pitches below the last row before it, so rows stay on the 40px rhythm the
 * sidebar aligns to. The archive closes the Design group: "Archive" in the title column, the
 * count beside it. Edge fades show while the list scrolls on phones. The row under the pointer or
 * in focus brightens; nothing else appears.
 */
export function Portfolio({ more }: { more: number }) {
  const [edges, setEdges] = useState({ top: false, bottom: false });
  const section = useRef<HTMLElement>(null);
  const list = useRef<HTMLDivElement>(null);

  // Browsers with scroll-driven animations tie the edge fades to the scroll position in CSS, so
  // they are right from the first frame; this fallback only serves the others. The up-and-down
  // scroller is the list on phones, the section on dense desktops.
  useEffect(() => {
    if (CSS.supports("animation-timeline: scroll()")) return undefined;
    const elements = [section.current, list.current].filter((element) => element !== null);
    const update = () => {
      const element = elements.find((each) => getComputedStyle(each).overflowY === "auto");
      setEdges(
        element === undefined
          ? { top: false, bottom: false }
          : {
              top: element.scrollTop > 1,
              bottom: element.scrollHeight - element.clientHeight - element.scrollTop > 1,
            },
      );
    };
    update();
    const observer = new ResizeObserver(update);
    for (const element of elements) {
      observer.observe(element);
      element.addEventListener("scroll", update, { passive: true });
    }
    return () => {
      observer.disconnect();
      for (const element of elements) element.removeEventListener("scroll", update);
    };
  }, []);

  return (
    <div
      data-portfolio
      {...stylex.props(
        styles.frame,
        edges.top && styles.fadeTop,
        edges.bottom && styles.fadeBottom,
      )}
    >
      <section
        data-scroll-list
        ref={section}
        {...stylex.props(styles.section)}
        aria-labelledby="portfolio-title"
      >
        <h2 {...stylex.props(ui.srOnly)} id="portfolio-title">
          Work
        </h2>
        <div data-rows data-scroll-list ref={list} {...stylex.props(styles.list)}>
          {groups.map((group, index) => (
            <div key={group} {...stylex.props(styles.group)}>
              <h3
                {...stylex.props(ui.label, ui.sans, styles.label, index > 0 && styles.laterLabel)}
              >
                {group}
              </h3>
              {projects
                .filter((project) => project.group.$ === group)
                .map((project, row) => (
                  <Row key={project.href} project={project} first={row === 0} home />
                ))}
              {group === "Design" && (
                <a {...stylex.props(rowMarker, ui.respond, styles.archive)} href="/all">
                  <span {...stylex.props(ui.text, ui.emphasis, styles.title)}>Archive</span>
                  <span {...stylex.props(ui.text, ui.respond, styles.more)}>
                    <Figures text={String(more)} /> more
                  </span>
                </a>
              )}
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}

const scrollDriven = "@supports (animation-timeline: scroll())";

// Scroll-linked: the top fade appears once the list scrolls, the bottom one leaves at the end.
const revealTop = stylex.keyframes({ "0%": { opacity: 0 }, "4%, 100%": { opacity: 1 } });
const hideBottom = stylex.keyframes({ "0%, 96%": { opacity: 1 }, "100%": { opacity: 0 } });

const styles = stylex.create({
  frame: {
    display: "grid",
    // Both groups share these columns, so their descriptors start in one place on every screen.
    gridTemplateColumns: space.projectColumns,
    columnGap: { default: space.tableGap, [media.mobile]: space.mobileTableGap },
    // Dense desktop viewports (see `align.ts`) borrow the phone layout: the list scrolls between
    // edge fades.
    gridTemplateRows: {
      default: null,
      [media.mobile]: "minmax(0, 1fr)",
      [stylex.when.ancestor("[data-dense]", rootMarker)]: {
        [media.desktop]: "minmax(0, 1fr)",
      },
    },
    gridColumn: { default: null, [media.mobile]: "1 / -1" },
    gridRow: { default: null, [media.mobile]: 4, [media.desktop]: 2 },
    alignSelf: {
      default: null,
      [media.desktop]: "start",
      [stylex.when.ancestor("[data-dense]", rootMarker)]: { [media.desktop]: "stretch" },
    },
    containerType: "inline-size",
    position: {
      default: null,
      [media.mobile]: "relative",
      [stylex.when.ancestor("[data-dense]", rootMarker)]: { [media.desktop]: "relative" },
    },
    minHeight: {
      default: null,
      [media.mobile]: 0,
      [stylex.when.ancestor("[data-dense]", rootMarker)]: { [media.desktop]: 0 },
    },
    marginBottom: {
      default: space.textMediaGap,
      // Phones: above Safari's bottom bar too, which floats over the page.
      [media.mobile]: `calc(${space.sectionGap} + env(safe-area-inset-bottom))`,
      [stylex.when.ancestor("[data-dense]", rootMarker)]: { [media.desktop]: 0 },
    },
    timelineScope: "--portfolio",
    "::before": {
      content: {
        default: null,
        [media.mobile]: '""',
        [stylex.when.ancestor("[data-dense]", rootMarker)]: { [media.desktop]: '""' },
      },
      // At the list's top edge.
      top: 0,
      backgroundImage: `linear-gradient(to bottom, ${colors.bg}, transparent)`,
      opacity: 0,
      position: "absolute",
      insetInline: 0,
      zIndex: 2,
      // One row (a touch target): what passes under the fade is at most one row.
      height: space.touchTarget,
      pointerEvents: "none",
      animationName: { default: null, [scrollDriven]: revealTop },
      animationTimeline: "--portfolio",
      animationTimingFunction: "linear",
      animationFillMode: "both",
    },
    "::after": {
      content: {
        default: null,
        [media.mobile]: '""',
        [stylex.when.ancestor("[data-dense]", rootMarker)]: { [media.desktop]: '""' },
      },
      bottom: 0,
      backgroundImage: `linear-gradient(to top, ${colors.bg}, transparent)`,
      opacity: "var(--list-overflows, 0)",
      position: "absolute",
      insetInline: 0,
      zIndex: 2,
      height: space.touchTarget,
      pointerEvents: "none",
      animationName: { default: null, [scrollDriven]: hideBottom },
      animationTimeline: "--portfolio",
      animationTimingFunction: "linear",
      animationFillMode: "both",
    },
  },
  fadeTop: { "::before": { opacity: 1 } },
  fadeBottom: { "::after": { opacity: 1 } },
  /**
   * One group: its label and rows on the table's shared columns: the title column, then what
   * fills the rest; Design sets its full date right, its last figure on the table's edge where the
   * hairlines end. Client work keeps when it was made; Projects, which are ongoing, show no date
   * but where they run, set right in the same column.
   */
  group: {
    display: "grid",
    gridColumn: "1 / -1",
    // Phones: each group is its own sideways scroller, so only one wider than the screen
    // scrolls; one that fits stays put. Its columns are its own, the title column one field wide
    // in both, so the descriptors still start in one place.
    gridTemplateColumns: {
      default: "subgrid",
      [media.mobile]: `${space.titleColumn} minmax(max-content, 1fr) max-content`,
    },
    columnGap: { default: null, [media.mobile]: space.mobileTableGap },
    overflowX: { default: null, [media.mobile]: "auto" },
    overflowY: { default: null, [media.mobile]: "hidden" },
    // A sideways swipe past either end stops here: it never turns into the browser's Back.
    overscrollBehaviorX: { default: null, [media.mobile]: "contain" },
    // As paco.me's lists: the scroller reaches the screen's edges (the list bleeds to them) and
    // pads back to the text's, so at rest the table stands where it would; scrolled, rows pass
    // under a fade as wide as each margin instead of being cut at the text's edge.
    paddingInline: { default: null, [media.mobile]: "var(--inset-left) var(--inset-right)" },
    maskImage: {
      default: null,
      [media.mobile]:
        "linear-gradient(to right, transparent, black var(--inset-left), black calc(100% - var(--inset-right)), transparent)",
    },
    scrollbarWidth: "none",
    "::-webkit-scrollbar": { display: "none" },
  },
  /**
   * A group's label, where a table header would be: the label's size, grey, a hairline under it
   * drawn inside, so it never adds to the height. Desktop: 32px, the old header's box (its line
   * and a row padding below), so Contact still sits on it. Phones: one touch target.
   */
  label: {
    gridColumn: "1 / -1",
    margin: 0,
    paddingBlock: { default: space.touchInset, [media.desktop]: `0 ${space.portfolioRowPadding}` },
    color: colors.tertiary,
    fontWeight: "inherit",
    boxShadow: `inset 0 -1px ${colors.hairline}`,
  },
  /**
   * A later group's label stands one empty line below the last row, as every group does. Desktop:
   * `groupGap` from the last line's box, less the row padding already there. Phones: its baseline
   * two line intervals (64px) below the last row's, as the first label stands below the About
   * line; the row's touch inset and the label's own count toward it.
   */
  laterLabel: {
    paddingTop: {
      default: `calc(8 * ${space.unit} - ${space.linkLineHeight} - ${space.touchInset})`,
      [media.desktop]: `calc(${space.groupGap} - ${space.portfolioRowPadding})`,
    },
  },
  title: { gridColumn: 1 },
  /** The Design group's footer: "Archive" in the title column, the count beside it. */
  archive: {
    display: "grid",
    gridColumn: "1 / -1",
    gridTemplateColumns: "subgrid",
    alignItems: "baseline",
    paddingBlock: { default: space.touchInset, [media.desktop]: space.portfolioRowPadding },
    boxShadow: `inset 0 1px ${colors.hairline}`,
    color: colors.primary,
    textDecoration: "none",
    touchAction: "manipulation",
    userSelect: "none",
    outline: { default: null, ":focus-visible": `1px solid ${colors.primary}` },
    outlineOffset: space.focusOffset,
    borderRadius: { default: null, ":focus-visible": `calc(${space.radius} / 2)` },
  },
  /** As a row's subject: dim until the footer is hovered or focused. */
  more: {
    gridColumn: 2,
    color: {
      default: colors.tertiary,
      [stylex.when.ancestor(":hover", rowMarker)]: { [media.hover]: colors.primary },
      [stylex.when.ancestor(":focus-visible", rowMarker)]: colors.primary,
    },
  },
  section: {
    display: {
      default: "grid",
      [media.desktop]: "contents",
      [stylex.when.ancestor("[data-dense]", rootMarker)]: { [media.desktop]: "grid" },
    },
    // Phones: one axis per scroller, so a drag moves the table one way at a time: the list
    // scrolls up and down (`list`), each group inside it sideways (`group`).
    gridTemplateColumns: { default: "subgrid", [media.mobile]: "minmax(0, 1fr)" },
    gridTemplateRows: { default: null, [media.mobile]: "minmax(0, 1fr)" },
    gridColumn: "1 / -1",
    gridRow: {
      default: null,
      [media.mobile]: 1,
      [stylex.when.ancestor("[data-dense]", rootMarker)]: { [media.desktop]: 1 },
    },
    minWidth: 0,
    minHeight: {
      default: null,
      [media.mobile]: 0,
      [stylex.when.ancestor("[data-dense]", rootMarker)]: { [media.desktop]: 0 },
    },
    alignContent: "start",
    overflowY: {
      default: null,
      [stylex.when.ancestor("[data-dense]", rootMarker)]: { [media.desktop]: "auto" },
    },
    scrollbarWidth: "none",
    // No overscroll lock: a pull past the list's top must chain to the page so the browser's
    // pull to refresh stays available.
    scrollTimeline: { default: "--portfolio y", [media.mobile]: "none" },
    // One row padding below the last row, as above each row's text.
    paddingBottom: {
      default: null,
      [stylex.when.ancestor("[data-dense]", rootMarker)]: {
        [media.desktop]: space.portfolioRowPadding,
      },
    },
    "::-webkit-scrollbar": { display: "none" },
  },
  list: {
    display: "grid",
    gridColumn: "1 / -1",
    // Phones: one column; each group sets its own (`group`). The list reaches the screen's
    // edges, so the groups' sideways scrollers do.
    gridTemplateColumns: { default: "subgrid", [media.mobile]: "minmax(0, 1fr)" },
    marginInline: {
      default: null,
      [media.mobile]: "calc(-1 * var(--inset-left)) calc(-1 * var(--inset-right))",
    },
    // Groups are scroll containers, whose minimum height is 0: rows as tall as their content keep
    // them whole, so the list scrolls instead of squeezing them.
    gridAutoRows: { default: null, [media.mobile]: "max-content" },
    alignContent: "start",
    position: "relative",
    // Phones: the up-and-down scroller.
    minHeight: { default: null, [media.mobile]: 0 },
    overflowY: { default: null, [media.mobile]: "auto" },
    overflowX: { default: null, [media.mobile]: "hidden" },
    scrollbarWidth: "none",
    // No overscroll lock: a pull past the list's top must chain to the page so the browser's
    // pull to refresh stays available.
    scrollTimeline: { default: null, [media.mobile]: "--portfolio y" },
    paddingBottom: { default: null, [media.mobile]: space.portfolioRowPadding },
    "::-webkit-scrollbar": { display: "none" },
  },
});
