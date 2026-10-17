"""Crops the Simulink snapshots (12_Thesis/figures/simulink_*.png) to the block diagram.

The exported pictures include long annotation bars (blue background) that make them very wide, so the blocks
become unreadable at page width. Rows that are mostly annotation blue are ignored and the picture is cropped to
the bounding box of the remaining non-white pixels (plus a margin). The annotation text is given in the captions.
Output: simulink_<name>_crop.png beside the original.
"""
from pathlib import Path

import numpy as np
from PIL import Image

FIG = Path(__file__).resolve().parents[1] / "figures"
for p in sorted(FIG.glob("simulink_*.png")):
    if p.stem.endswith(("_crop", "_blocks")):
        continue
    a = np.asarray(Image.open(p).convert("RGB")).astype(int)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    blue = (b > 220) & (r < 170) & (g > 150) & (g < 230)
    band_rows = blue.mean(axis=1) > 0.04
    # grow the bands by a few rows so the annotation text above/below the fill is dropped too
    k = 12
    grown = np.convolve(band_rows.astype(int), np.ones(2 * k + 1, int), mode="same") > 0
    ink = (a.sum(axis=2) < 700) & ~grown[:, None]
    ys, xs = np.nonzero(ink)
    m = 40
    y0, y1 = max(ys.min() - m, 0), min(ys.max() + m, a.shape[0])
    x0, x1 = max(xs.min() - m, 0), min(xs.max() + m, a.shape[1])
    Image.fromarray(a[y0:y1, x0:x1].astype(np.uint8)).save(p.with_name(p.stem + "_crop.png"))
    print(p.name, "->", (x1 - x0, y1 - y0), "from", a.shape[1::-1])
