import * as stylex from "@stylexjs/stylex";
import type { TargetedMouseEvent } from "preact";
import { useRef, useState } from "preact/hooks";
import { announce } from "../announce.ts";
import { email } from "../site.ts";
import { colors, fontFeatures, space } from "../tokens.stylex.ts";
import { ui } from "../ui.tsx";

/** Copies the address and says so through the live region; `c` anywhere does too (`keys.ts`). */
export async function copyEmail(): Promise<boolean> {
  const copied = await navigator.clipboard.writeText(email).then(
    () => true,
    () => false,
  );
  announce(copied ? "Email copied to clipboard" : "Email could not be copied");
  return copied;
}

export function Email() {
  const [state, setState] = useState<"idle" | "copied" | "failed">("idle");
  const timer = useRef(0);
  async function copy(event: TargetedMouseEvent<HTMLButtonElement>) {
    event.currentTarget.blur();
    const copied = await copyEmail();
    setState(copied ? "copied" : "failed");
    clearTimeout(timer.current);
    timer.current = window.setTimeout(() => setState("idle"), 1000);
  }
  return (
    <button
      {...stylex.props(
        ui.reset,
        ui.text,
        ui.quiet,
        ui.respond,
        ui.focusRing,
        styles.email,
        state === "failed" && styles.failed,
      )}
      type="button"
      aria-label={`Copy ${email}`}
      onClick={(event) => void copy(event)}
    >
      {state === "idle" ? (
        <span data-nosnippet>{email}</span>
      ) : state === "copied" ? (
        "Copied"
      ) : (
        "Copy failed"
      )}
    </button>
  );
}

const styles = stylex.create({
  email: {
    lineHeight: space.linkLineHeight,
    paddingBlock: `calc(${space.linkGap} / 2)`,
    marginBlock: `calc(${space.linkGap} / -2)`,
    // An address is lowercase: its @ keeps the default form, not the capitals' one.
    fontFeatureSettings: fontFeatures.prose,
  },
  failed: { color: colors.secondary },
});
