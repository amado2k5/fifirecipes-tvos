#!/usr/bin/env python3
"""
Renders the tvOS "App Icon & Top Shelf Image" brandassets from the bundled
emblem + brand palette — no Xcode needed.

    python3 scripts/generate-tv-icons.py

Layout produced under FifiRecipesTV/Assets.xcassets/:

    App Icon & Top Shelf Image.brandassets/
      App Icon.imagestack/               400x240 (+@2x 800x480)
      App Icon - App Store.imagestack/   1280x768 (+@2x 2560x1536)
      Top Shelf Image.imageset/          1920x720 (+@2x 3840x1440)
      Top Shelf Image Wide.imageset/     2320x720 (+@2x 4640x1440)

Layer recipe (parallax): back = opaque paper gradient, middle = soft brand
blobs, front = the FiFi emblem centred. Top shelf = wide paper banner with
emblem + wordmark (Plus Jakarta Sans ExtraBold) on the leading third.
"""
import json
import math
import os
import shutil

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, 'FifiRecipesTV', 'Assets.xcassets')
BRAND = os.path.join(ASSETS, 'App Icon & Top Shelf Image.brandassets')
EMBLEM = os.path.join(ASSETS, 'Emblem.imageset', 'emblem.png')
FONT_BOLD = os.path.join(ROOT, 'FifiRecipesTV', 'Fonts', 'PlusJakartaSans-800.ttf')

# Brand palette (see FifiRecipesTV/Theme/Palette.swift)
PAPER = (253, 244, 227)
PAPER_DEEP = (246, 233, 210)
LEAF = (77, 148, 38)
LEAF_DEEP = (58, 122, 30)
LEAF_SOFT = (230, 243, 216)
TOMATO = (232, 89, 12)
SUN = (255, 197, 61)
SUN_SOFT = (255, 243, 196)

INFO = {"info": {"author": "xcode", "version": 1}}


def write_json(path, obj):
    with open(path, 'w') as f:
        json.dump(obj, f, indent=2, sort_keys=True)
        f.write('\n')


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def paper_gradient(w, h):
    """Diagonal paper → paper-deep gradient, opaque RGB."""
    img = Image.new('RGB', (w, h))
    px = img.load()
    diag = w + h
    for y in range(h):
        for x in range(0, w, 4):  # 4px columns are plenty for a smooth ramp
            t = (x + y) / diag
            c = lerp(PAPER, PAPER_DEEP, t)
            for dx in range(4):
                if x + dx < w:
                    px[x + dx, y] = c
    return img


def blob(canvas, cx, cy, r, color, alpha):
    """Soft radial blob composited onto an RGBA canvas."""
    layer = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color + (alpha,))
    layer = layer.filter(ImageFilter.GaussianBlur(r * 0.35))
    canvas.alpha_composite(layer)


def middle_layer(w, h):
    """Transparent middle layer — a few soft brand blobs for parallax."""
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    blob(img, w * 0.82, h * 0.18, h * 0.42, SUN_SOFT, 220)
    blob(img, w * 0.12, h * 0.85, h * 0.38, LEAF_SOFT, 230)
    blob(img, w * 0.92, h * 0.85, h * 0.30, SUN_SOFT, 160)
    return img


def front_layer(w, h):
    """Transparent front layer — centred emblem."""
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    emblem = Image.open(EMBLEM).convert('RGBA')
    target_h = int(h * 0.62)
    scale = target_h / emblem.height
    emblem = emblem.resize((int(emblem.width * scale), target_h), Image.LANCZOS)
    img.alpha_composite(emblem, ((w - emblem.width) // 2, (h - emblem.height) // 2))
    return img


def top_shelf(w, h):
    """Opaque banner: paper gradient, blobs, emblem + wordmark leading side."""
    img = paper_gradient(w, h).convert('RGBA')
    blob(img, w * 0.88, h * 0.1, h * 0.55, SUN_SOFT, 200)
    blob(img, w * 0.08, h * 1.05, h * 0.5, LEAF_SOFT, 220)

    emblem = Image.open(EMBLEM).convert('RGBA')
    target_h = int(h * 0.62)
    emblem = emblem.resize(
        (int(emblem.width * target_h / emblem.height), target_h), Image.LANCZOS)

    ex = int(w * 0.08)
    ey = (h - emblem.height) // 2
    img.alpha_composite(emblem, (ex, ey))

    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT_BOLD, int(h * 0.16))
    d.text((ex + emblem.width + int(w * 0.035), h * 0.5),
           'FiFi Recipes', font=font, fill=LEAF_DEEP, anchor='lm')

    # thin leaf-green baseline accent
    d.rectangle([0, h - int(h * 0.035), w, h], fill=LEAF)
    return img


# --- asset-catalog plumbing -------------------------------------------------

def imageset(parent, name, entries):
    """<name>.imageset + Contents.json; entries = [(scale, size_str, Image)]"""
    d = os.path.join(parent, f'{name}.imageset')
    os.makedirs(d, exist_ok=True)
    images = []
    for scale, size, img in entries:
        fn = f'{name}@{scale}.png'
        img.save(os.path.join(d, fn))
        images.append({"filename": fn, "idiom": "tv", "scale": scale})
    write_json(os.path.join(d, 'Contents.json'),
               {"images": images, **INFO})


def layer(stack, name, w, h, img_fn):
    """<name>.layer with a 1x + 2x imageset produced by img_fn(w, h)."""
    ld = os.path.join(stack, f'{name}.layer')
    os.makedirs(ld, exist_ok=True)
    imageset(ld, name, [
        ("1x", f"{w}x{h}", img_fn(w, h)),
        ("2x", f"{w}x{h}", img_fn(w * 2, h * 2)),
    ])
    write_json(os.path.join(ld, 'Contents.json'),
               {"layer": {"filename": f'{name}.imageset'}, **INFO})


def imagestack(name, w, h):
    stack = os.path.join(BRAND, f'{name}.imagestack')
    os.makedirs(stack, exist_ok=True)
    layer(stack, 'Front', w, h, front_layer)
    layer(stack, 'Middle', w, h, middle_layer)
    layer(stack, 'Back', w, h, paper_gradient)
    write_json(os.path.join(stack, 'Contents.json'), {
        "layers": [
            {"filename": "Front.layer"},
            {"filename": "Middle.layer"},
            {"filename": "Back.layer"},
        ],
        **INFO,
    })


def main():
    if os.path.isdir(BRAND):
        shutil.rmtree(BRAND)
    os.makedirs(BRAND)

    imagestack('App Icon - App Store', 1280, 768)
    imagestack('App Icon', 400, 240)
    imageset(BRAND, 'Top Shelf Image', [
        ("1x", "1920x720", top_shelf(1920, 720)),
        ("2x", "1920x720", top_shelf(3840, 1440)),
    ])
    imageset(BRAND, 'Top Shelf Image Wide', [
        ("1x", "2320x720", top_shelf(2320, 720)),
        ("2x", "2320x720", top_shelf(4640, 1440)),
    ])

    write_json(os.path.join(BRAND, 'Contents.json'), {
        "assets": [
            {
                "filename": "App Icon - App Store.imagestack",
                "idiom": "tv",
                "role": "primary-app-icon",
                "size": "1280x768",
            },
            {
                "filename": "App Icon.imagestack",
                "idiom": "tv",
                "role": "primary-app-icon",
                "size": "400x240",
            },
            {
                "filename": "Top Shelf Image.imageset",
                "idiom": "tv",
                "role": "top-shelf-image",
                "size": "1920x720",
            },
            {
                "filename": "Top Shelf Image Wide.imageset",
                "idiom": "tv",
                "role": "top-shelf-image-wide",
                "size": "2320x720",
            },
        ],
        **INFO,
    })

    # Site assets: square og-image + favicon rendered the same way.
    og = Image.new('RGB', (600, 600), PAPER)
    og_rgba = og.convert('RGBA')
    blob(og_rgba, 480, 90, 200, SUN_SOFT, 220)
    blob(og_rgba, 60, 540, 190, LEAF_SOFT, 230)
    emblem = Image.open(EMBLEM).convert('RGBA').resize((320, 295), Image.LANCZOS)
    og_rgba.alpha_composite(emblem, (140, 150))
    og = og_rgba.convert('RGB')
    og.save(os.path.join(ROOT, 'site', 'og-image.png'))
    og.resize((180, 180), Image.LANCZOS).save(os.path.join(ROOT, 'site', 'favicon.png'))

    print(f'wrote brandassets + site icons under {ASSETS}')


if __name__ == '__main__':
    main()
