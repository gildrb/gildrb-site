# /// script
# requires-python = ">=3.11"
# dependencies = ["fonttools[woff]==4.60.2", "certifi"]
# ///
"""Builds the site's EB Garamond file from Google Fonts' release.

    uv run scripts/garamond.py

public/fonts/eb-garamond.woff2, for the inscription line: the Latin the page sets in it
(`garamondRanges`, src/layout.tsx) and the Greek alphabet, so the projects' names (Elpis,
Heph, Archetypon) can set a word in it too. Weights 400 to 500.
"""

import io
import ssl
import urllib.request
from pathlib import Path

import certifi
from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

SOURCE = "https://github.com/google/fonts/raw/main/ofl/ebgaramond/EBGaramond%5Bwght%5D.ttf"
ROOT = Path(__file__).resolve().parent.parent
PAGE = ROOT / "public/fonts/eb-garamond.woff2"
# Must match `garamondRanges` in src/layout.tsx.
RANGES = [
    (0x0020, 0x007E), (0x00A0, 0x00FF), (0x2010, 0x205E), (0x20AC, 0x20AC),
    (0x0370, 0x03FF), (0x1F00, 0x1FFF),
]
FEATURES = ["kern", "locl", "liga"]


def main() -> None:
    # certifi's CA bundle, so the download verifies on any machine, whatever its system store.
    context = ssl.create_default_context(cafile=certifi.where())
    with urllib.request.urlopen(SOURCE, context=context) as response:
        font = TTFont(io.BytesIO(response.read()), lazy=False)
    characters = sorted({c for start, end in RANGES for c in range(start, end + 1)} & set(font.getBestCmap()))
    options = subset.Options()
    options.layout_features = FEATURES
    options.name_IDs = ["*"]
    options.notdef_outline = True
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=characters)
    subsetter.subset(font)
    font = instancer.instantiateVariableFont(font, {"wght": (400, 500)})
    font.flavor = "woff2"
    font.save(PAGE)
    print(f"{PAGE.relative_to(ROOT)}: {len(characters)} characters, {PAGE.stat().st_size} bytes")


if __name__ == "__main__":
    main()
