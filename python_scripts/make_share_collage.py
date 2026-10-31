"""Build web/images/share-collage.jpg, the picture shown when someone shares
an easiYESt link (og:image). Square vendor photos in a grid on plum, with the
logo in the middle, so a shared link shows many vendors instead of one.

Usage:
    python python_scripts/make_share_collage.py photo1.jpg photo2.jpg ... photo14.jpg

Pass 14 photos, in reading order; the logo takes the middle square. Only use
photos from vendors who are happy to appear in link previews.
"""

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageOps

ROOT = Path(__file__).resolve().parent.parent
LOGO = ROOT / "web" / "icons" / "Icon-512.png"
OUT = ROOT / "web" / "images" / "share-collage.jpg"

WIDTH, HEIGHT = 1200, 630  # what Facebook, iMessage and X expect
COLS, ROWS = 5, 3
TILE, GAP = 190, 10
PLUM = (123, 63, 97)
CHAMPAGNE = (220, 199, 170)


def square(path, size):
    """Centre-crop to a square and resize."""
    img = ImageOps.exif_transpose(Image.open(path)).convert("RGB")
    return ImageOps.fit(img, (size, size), Image.LANCZOS)


def main(photos):
    if len(photos) != COLS * ROWS - 1:
        sys.exit(f"Pass {COLS * ROWS - 1} photos, got {len(photos)}.")

    canvas = Image.new("RGB", (WIDTH, HEIGHT), PLUM)
    draw = ImageDraw.Draw(canvas)
    grid_w = COLS * TILE + (COLS - 1) * GAP
    grid_h = ROWS * TILE + (ROWS - 1) * GAP
    left, top = (WIDTH - grid_w) // 2, (HEIGHT - grid_h) // 2

    # The site's thin champagne inset frame around the grid.
    pad = 12
    draw.rectangle([left - pad, top - pad, left + grid_w + pad - 1, top + grid_h + pad - 1], outline=CHAMPAGNE, width=1)

    middle = (ROWS // 2) * COLS + COLS // 2
    queue = iter(photos)
    for i in range(COLS * ROWS):
        x = left + (i % COLS) * (TILE + GAP)
        y = top + (i // COLS) * (TILE + GAP)
        if i == middle:
            canvas.paste(square(LOGO, TILE), (x, y))
            draw.rectangle([x, y, x + TILE - 1, y + TILE - 1], outline=CHAMPAGNE, width=2)
        else:
            canvas.paste(square(next(queue), TILE), (x, y))

    canvas.save(OUT, "JPEG", quality=82, optimize=True, progressive=True)
    print(f"Wrote {OUT.relative_to(ROOT)} ({OUT.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main(sys.argv[1:])
