#!/usr/bin/env python3
"""Downloads the bundled OFL fonts (dev tool, not shipped).

Pulls static TTF instances through the Google Fonts CSS API; an empty
User-Agent is served plain TTFs, which is what UIAppFonts registration wants.
"""
import re
import subprocess
import sys
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "FifiRecipes" / "Fonts"
OUT.mkdir(parents=True, exist_ok=True)

FAMILIES = {
    "Plus Jakarta Sans": [400, 500, 700, 800],
    "Tajawal": [400, 500, 700, 800],
    "Vazirmatn": [400, 500, 700],
    "Noto Nastaliq Urdu": [400, 700],
    "Heebo": [400, 500, 700],
    "Baloo 2": [400, 600, 800],
    "Baloo Bhaijaan 2": [400, 600, 800],
}

BLOCK = re.compile(r"@font-face\s*\{([^}]*)\}")
WEIGHT = re.compile(r"font-weight:\s*(\d+)")
URL = re.compile(r"url\((https://[^)]+)\)")


def get(url: str) -> bytes:
    # urllib in this Python install lacks CA roots; curl handles TLS properly.
    return subprocess.run(
        ["curl", "-fsSL", "-A", "", url], check=True, capture_output=True
    ).stdout


def main() -> int:
    for family, weights in FAMILIES.items():
        axis = ";".join(str(w) for w in weights)
        css_url = (
            "https://fonts.googleapis.com/css2?family="
            + family.replace(" ", "+")
            + f":wght@{axis}&display=swap"
        )
        css = get(css_url).decode()
        got = 0
        for block in BLOCK.finditer(css):
            w = WEIGHT.search(block.group(1))
            u = URL.search(block.group(1))
            if not (w and u):
                continue
            name = f"{family.replace(' ', '')}-{w.group(1)}.ttf"
            (OUT / name).write_bytes(get(u.group(1)))
            print(name)
            got += 1
        if got != len(weights):
            print(f"!! {family}: expected {len(weights)} faces, got {got}", file=sys.stderr)
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
