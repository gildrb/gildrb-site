import * as stylex from "@stylexjs/stylex";
import type { Link } from "./site.ts";
import { colors } from "./tokens.stylex.ts";
import { type Style, ui } from "./ui.tsx";

/** Where a link goes, as people read an address: no scheme, no `www.`, no trailing slash. */
function destination(href: string): string {
  const url = new URL(href);
  const path = url.pathname === "/" ? "" : url.pathname.replace(/\/$/, "");
  return `${url.hostname.replace(/^www\./, "")}${path}`;
}

/**
 * "Source" or "Sources", then the address each link goes to, so the parties involved (the code, a
 * site, posts) are named. The source code sits under the opening; other links end the page.
 */
export function SourcesLine({ links, style }: { links: readonly Link[]; style?: Style }) {
  return (
    <p {...stylex.props(ui.prose, styles.line, style)}>
      <span {...stylex.props(styles.label)}>{links.length === 1 ? "Source: " : "Sources: "}</span>
      {links.map(({ label, href }, index) => (
        <>
          {index > 0 && ", "}
          <a
            {...stylex.props(ui.focusRing, ui.quiet, ui.respond, styles.address)}
            href={href}
            rel="noopener noreferrer"
            aria-label={`${label}: ${destination(href)}`}
          >
            {destination(href)}
          </a>
        </>
      ))}
    </p>
  );
}

const styles = stylex.create({
  /** The name in full contrast, as the page's headings. */
  label: { color: colors.primary },
  /** The Sources line: running text, an address may break anywhere rather than overflow. */
  line: { margin: 0, color: colors.primary, overflowWrap: "anywhere" },
  /** Quiet, as the sidebar's links: bronze at rest, full contrast on hover, no underline. */
  address: { overflowWrap: "anywhere" },
});
