"""Shared figure style (Analysis Plan, Section 12.2), read from 11_Results/figures/plot_style.csv
so that Python and MATLAB figures use identical colours and markers."""
from __future__ import annotations

from pathlib import Path

import matplotlib

matplotlib.use("Agg")  # file output only
import matplotlib.pyplot as plt  # noqa: E402
import pandas as pd  # noqa: E402
from matplotlib.colors import LinearSegmentedColormap  # noqa: E402

PROJECT_ROOT = Path(__file__).resolve().parents[3]
FIG_DIR = PROJECT_ROOT / "11_Results" / "figures"
TAB_DIR = PROJECT_ROOT / "11_Results" / "tables"
STYLE = pd.read_csv(FIG_DIR / "plot_style.csv")

CM = 1 / 2.54  # inches per cm
FULL_WIDTH = 16 * CM
HALF_WIDTH = 8 * CM


def _rows(kind: str) -> pd.DataFrame:
    return STYLE[STYLE.kind == kind].set_index("item")


CLASS = _rows("class")
METHOD = _rows("method")
SCALE = _rows("scale")["colour_hex"]
INK = _rows("ink")["colour_hex"]
CLASS_ORDER = list(CLASS.sort_values("order").index)

SEQUENTIAL = LinearSegmentedColormap.from_list("seq", [SCALE["sequential_low"], SCALE["sequential_high"]])
DIVERGING = LinearSegmentedColormap.from_list(
    "div", [SCALE["diverging_negative"], SCALE["diverging_mid"], SCALE["diverging_positive"]])


def apply() -> None:
    plt.rcParams.update({
        "font.family": "Arial",
        "font.size": 9,
        "axes.titlesize": 9,
        "axes.labelsize": 9,
        "xtick.labelsize": 8,
        "ytick.labelsize": 8,
        "legend.fontsize": 8,
        "axes.edgecolor": INK["muted"],
        "axes.labelcolor": INK["text"],
        "xtick.color": INK["muted"],
        "ytick.color": INK["muted"],
        "axes.grid": True,
        "grid.color": INK["grid"],
        "grid.linewidth": 0.6,
        "grid.linestyle": "-",
        "axes.axisbelow": True,
        "axes.spines.top": False,
        "axes.spines.right": False,
        "figure.dpi": 100,
        "savefig.dpi": 300,
        "pdf.fonttype": 42,
    })


def save(fig, name: str, data: pd.DataFrame) -> list[Path]:
    """Save figure as 300-dpi PNG and vector PDF, with its plotted data as CSV (the figure's table view)."""
    FIG_DIR.mkdir(parents=True, exist_ok=True)
    paths = [FIG_DIR / f"{name}.png", FIG_DIR / f"{name}.pdf", FIG_DIR / f"{name}.csv"]
    fig.savefig(paths[0], bbox_inches="tight")
    fig.savefig(paths[1], bbox_inches="tight", metadata={"CreationDate": None})   # no date stamp: identical re-runs
    data.to_csv(paths[2], index=False, encoding="utf-8")
    plt.close(fig)
    return paths
