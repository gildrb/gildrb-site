# Proofs of the laws (LAWS.bend, laws/site/)

All 7 laws of laws/site/ are proven: `bend PROOF.bend` and `bend PROOF.bend --verdict` print ALL PROOFS CHECK. No law is open.

One file per law; lemmas in `base.bend`. NEVER `@unsafe`, `?` holes, or edits to LAWS.bend, laws/ or LAWS.lock. The proofs compute the laws on `site/site.bend`: write it from a fresh `vp build` first (`npm run laws`).

## What exists

| File                                          | Gives                                                                                                                                                                                                      |
| --------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `proof/base.bend`                             | `Bool.absurd` (False is not True), `And.l`, `And.r`, `And.both`                                                                                                                                            |
| `proof/site/pages/outline.bend`               | `All.outline` (every page's outline), `Outline.c0`-`c2` (computed, 6 pages each, the last every page after 12), `All.split`, `Outline.all`, `Find.ok` (Spec.find gives None or one page's text), `Pick.ok` |
| every other `proof/site/<section>/<law>.bend` | `{==}`: the closed claim computed on the build                                                                                                                                                             |

`outline` quantifies over every path: `Find.ok` goes down the page list by induction, `Pick.ok` takes both branches of `Spec.find`'s `Bool.pick`; the premise `at` rewrites the goal to `Ok.m(Spec.find(..))`.

## Cost under `--verdict`

The kernel gives each proof a fixed budget ("out of fuel" past it; not a false law). The site is about 1.1 MB, so every pass must stay cheap:

- Read a page one character at a time; match `Chr{n}` literals, one state per handler (`Lx.step`, `Page.char`); no lookahead patterns with a fallback on a computed string.
- No `Nat` or `U32` counter per character: count with strings (`Ratio.twenty`, `Ratio.le`).
- `+` on a large value only where a function runs once (`Text.end`, `Outline.of`): `+` normalizes the value on every call.
- Keep only what a law reads: the lexer drops the attributes it has no `Key` for.

- No deep `Chr{n}` literal pattern after another literal arm with a fallback (`SCon{a, SCon{b, SCon{Chr{45}, ..}}}` after `SCon{Chr{45}, t}`): `--verdict` never finished checking one; test characters with a helper (`Dash.is`).
- No string in a state the pass keeps per character (`+` copies it each step): `home_text`'s raw-text states hold an enum (`Raw`), not the element's name; with the name, it ran out.
- One def's check has one budget: 12 pages' outlines fit, 18 do not. `Outline.all` joins chunks of 6 (`All.split`); a chunk that runs out after pages are added splits again.

`bend PROOF.bend` takes about 50 s; `--verdict` several minutes, most of it in `Outline.c0`-`c2` (every page lexed).
