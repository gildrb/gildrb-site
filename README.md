Source for [gildrb.com](https://gildrb.com). Preact, StyleX, strict TypeScript, Vite+, Cloudflare Pages; Bend 2 laws on the built site.

## Install

```sh
vp install  # dependencies
```

[Bend](https://github.com/bendlang/bend) 2 and Python 3.9+ for the laws.

## Use

```sh
vp dev         # dev server, http://127.0.0.1:5174
vp check       # format, lint, type check
vp build       # prerender into dist/
npm run laws   # build, then prove every law on dist/
```

## Laws

`LAWS.bend` states the site's requirements as laws about the bytes in `dist/`; `PROOF.bend` proves them. Parts, laws and commands: [docs/laws.md](docs/laws.md).

## License

MIT ([LICENSE](LICENSE)).
