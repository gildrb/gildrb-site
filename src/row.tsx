import * as stylex from "@stylexjs/stylex";
import { useId } from "preact/hooks";
import type { Project } from "./site.ts";
import { colors, media, rowMarker, space, typeScale } from "./tokens.stylex.ts";
import { Figures, ui, untranslated } from "./ui.tsx";

/**
 * One project in a three-column subgrid. The parent grid owns the columns; `home` rows live in
 * the homepage table, the others in the case pages' next-project lists, and both look the same:
 * no glyph, the row under the pointer or in focus brightens (`ui.respond`). A row that leaves the
 * site underlines its title, as the article links do. Every row: the title, a short noun phrase,
 * and a fact set right, closing the row on its right edge.
 * - Projects: what it is (`descriptor`) and where it runs (`platform`). No date: what it does
 *   matters, not when it started.
 * - Work: what was made (`work`) and the date.
 * Named by what it shows; the full `description` describes it.
 */
export function Row({ project, first, home }: { project: Project; first: boolean; home: boolean }) {
  const Title = home ? "h4" : "span";
  const id = useId();
  const { group } = project;
  return (
    <a
      {...stylex.props(
        rowMarker,
        ui.respond,
        styles.row,
        !first && styles.divided,
        !home && styles.next,
      )}
      href={project.href}
      // Named by what it shows, in reading order; the full sentence describes it.
      aria-labelledby={`${id}-title ${id}-descriptor ${id}-end`}
      aria-describedby={`${id}-description`}
    >
      <Title
        {...stylex.props(
          ui.text,
          styles.cell,
          styles.title,
          project.external && [ui.respond, ui.outbound],
        )}
        id={`${id}-title`}
        {...untranslated}
      >
        {project.title}
      </Title>
      <span {...stylex.props(ui.text, styles.descriptor)} id={`${id}-descriptor`}>
        {group.$ === "Work" ? group.work : project.descriptor}
      </span>
      {group.$ === "Work" ? (
        <time
          {...stylex.props(ui.text, styles.cell, styles.date)}
          id={`${id}-end`}
          dateTime={project.date}
        >
          <Figures text={project.date} />
        </time>
      ) : (
        <span {...stylex.props(ui.text, styles.cell, styles.date)} id={`${id}-end`}>
          {group.platform}
        </span>
      )}
      <span {...stylex.props(ui.srOnly)} id={`${id}-description`}>
        {project.description}
      </span>
    </a>
  );
}

const styles = stylex.create({
  /**
   * Desktop: one line on the table's columns (subgrid). Phones: a two-line cell, as in iOS Mail:
   * the title and the fact set right on the first line, the descriptor under them across the row,
   * so nothing is cut and nothing scrolls. Two 24px lines and a unit above and below: 64px.
   */
  row: {
    display: "grid",
    gridColumn: "1 / -1",
    gridTemplateColumns: { default: "subgrid", [media.mobile]: "minmax(0, 1fr) auto" },
    columnGap: { default: null, [media.mobile]: space.mobileTableGap },
    alignItems: "baseline",
    width: "100%",
    // Phones: a unit above and below the two lines. Desktop: 2.5rem, the pitch the sidebar is
    // aligned to.
    paddingBlock: { default: space.unit, [media.desktop]: space.portfolioRowPadding },
    // Only hover (where there is hover) and keyboard focus raise the row; a finger's press
    // does not (the grey tap flash is off too, see `layout.tsx`). J and K select a row the way
    // the pointer would (`keys.ts`), so the selection is lit as the hover is.
    color: {
      default: colors.tertiary,
      ":hover": { [media.hover]: colors.primary },
      ":focus-visible": colors.primary,
      ":is([data-selected])": colors.primary,
    },
    textDecoration: "none",
    touchAction: "manipulation",
    userSelect: "none",
    outline: { default: null, ":focus-visible": `1px solid ${colors.primary}` },
    outlineOffset: space.focusOffset,
    borderRadius: { default: null, ":focus-visible": `calc(${space.radius} / 2)` },
  },
  // A hairline drawn inside the row, so it never adds to the row's height.
  divided: { boxShadow: `inset 0 1px ${colors.hairline}` },
  next: {
    paddingBottom: { default: null, ":last-child": { [media.desktop]: 0 } },
  },
  cell: {
    gridRow: 1,
    whiteSpace: "nowrap",
    paddingInlineEnd: { default: null, [media.mobile]: space.mobileCellEndSpace },
  },
  /**
   * Set right, as a ledger's figures: the digits line up into a column that closes the row, the
   * last figure on the row's right edge.
   */
  date: {
    gridColumn: { default: 3, [media.mobile]: 2 },
    justifySelf: "end",
    position: "relative",
    display: "block",
    textAlign: "end",
    color: "inherit",
    paddingInlineEnd: 0,
  },
  /** The thing named, at the emphasis weight; the descriptor and date beside it stay at the text's. */
  title: { gridColumn: 1, margin: 0, color: colors.primary, fontWeight: typeScale.emphasisWeight },
  descriptor: {
    gridColumn: { default: 2, [media.mobile]: "1 / -1" },
    gridRow: { default: 1, [media.mobile]: 2 },
    // The row's own colour (grey, full contrast on its hover or focus), inherited, so the subject
    // fades with the row on leaving; a colour of its own here would switch at once.
    color: "inherit",
  },
});
