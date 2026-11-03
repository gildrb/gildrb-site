# gildrb.com's laws

The site's requirements as Bend 2 laws about the bytes `vp build` ships; `bend PROOF.bend --verdict` checks every law against the last build.

| Part   | File                                          | Does                                                                                                                                                                           |
| ------ | --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Site   | `scripts/site.py`, `site/site.bend` (ignored) | every `.html` file of `dist/` and `dist/.well-known/poppy.json`, byte for byte, as Bend strings                                                                                |
| Laws   | `LAWS.bend`, `laws/site/`                     | requirements `R1`-`R7`, `A1`-`A6` atop LAWS.bend; laws by section: `home/`, `pages.bend`, `agents.bend`                                                                        |
| Reader | `laws/site/base/html/`                        | `Html.toks` (`tree.bend`): a page's tags (`tokens.bend`) and text as a browser reads them (`lexer.bend`); None where a browser could read it another way or build another tree |
| Terms  | `laws/site/base/page.bend`                    | files by path, attributes, words                                                                                                                                               |
| Proofs | `PROOF.bend`, `proof/`                        | one file per law; [proof/README.md](../proof/README.md)                                                                                                                        |
| Lock   | `LAWS.lock`                                   | hash of every law and spec helper; a change is an error until relocked                                                                                                         |

## Laws

| Law           | Section | Req.   | Claim                                                                                                                                                                                                                                                   |
| ------------- | ------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `home_text`   | home    | R1     | homepage text, counted from its body start tag (as the tags say): script content cut; tags, comments, declarations, style/script/title/textarea content not text; each character reference one space; at least 500 characters and 5% of the body markup |
| `home_shown`  | home    | R1     | every homepage element with `hidden` is an empty div; no text inside svg, math, dialog, details, video, audio, object, canvas, datalist, progress, meter                                                                                                |
| `rows`        | home    | R5     | every h4 opens a link labelled `<k>-title <k>-descriptor <k>-end` (k one word), each id inside that link; every labelled link is a row; every labelling id is on the page once                                                                          |
| `groups`      | home    | R6     | every h3 holds only plain text `Projects` or `Work`; the first `Projects`, a later `Work`, each with a row; no row before the first h3; no `Projects` after `Work`                                                                                      |
| `outline`     | pages   | R2, R3 | every page: one h1; a contents nav links every h2 by id (each id once on the page), in order, at least two, and holds no other href                                                                                                                     |
| `no_contents` | pages   | R4     | archetypon.html and porthmeus.html hold no `data-contents`, any case; every followable href with `#` goes to another site or to an element before the first h2                                                                                          |
| `poppy`       | agents  | R7     | `/.well-known/poppy.json` byte for byte, its domain the host of the homepage's one canonical URL, a host name a URL parser reads as itself                                                                                                              |

## Use

```sh
npm run laws                                        # vp build, site/site.bend, bend PROOF.bend --verdict
python3 scripts/site.py                             # dist/ -> site/site.bend, after vp build
bend PROOF.bend                                     # check every proof, about 30 s
bend PROOF.bend --verdict                           # check again with the proven kernel
python3 ~/.agents/skills/bend/scripts/gate.py .     # gate: proofs, verdict, hazards, findings, LAWS.lock
python3 ~/.agents/skills/bend/scripts/gate.py . --lock  # relock after a law change; commit LAWS.lock with it
```

## Limitations

- Trusted, not proven: `scripts/site.py` (dist/ to Bend), the build, the checker, and the host sending pages as `text/html; charset=utf-8` (A6).
- The laws hold for the build `site/site.bend` was written from: run `npm run laws` after a change.
- `groups` does not pin which rows sit in which group.
- The laws read HTML, not CSS: text hidden by CSS counts as shown.
- A group is an h3, named by its text: ARIA roles or labels and CSS looks are not read.
- The laws read no script: what scripts, event handlers or `javascript:` URLs do is not checked.
- HTML the reader refuses fails every law that reads that page: uppercase is folded, but `noscript`, `template`, `iframe`, `base`, `table`, `select`, comments a browser ends early, `&` in an attribute the laws read, U+0000 in text, `/>` on an element with an end tag, and tags a browser would build into another tree are refused: an end tag must close the element opened last; no block element while a `p` is open, no link inside a link, `li` only right inside `ul`/`ol`/`menu`; inside svg or math only svg, math and elements the reader has no rule for (`laws/site/base/html/tree.bend`).
- `--verdict` gives each proof a fixed budget: a pass with `Nat` arithmetic per character runs out on the homepage (proof/README.md).
