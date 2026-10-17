"""Draws the two schematic figures of Chapter 3 that are not data plots:
Figure 3.1 (integrated framework) and the nested cross-validation scheme. Output: 12_Thesis/figures/*.png (300 dpi).
Counts written on the diagrams are read from the result files, not typed.
"""
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch  # noqa: E402
import pandas as pd  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "12_Thesis" / "figures"
OUT.mkdir(exist_ok=True)
plt.rcParams.update({"font.family": "Arial", "font.size": 7.5})
flow = pd.read_csv(ROOT / "11_Results" / "figures" / "F3_2_data_preparation_flow.csv")
FV = {f"{r.stage}:{r.item}": int(r.records) for r in flow.itertuples()}

C_PY, C_SL, C_DATA, C_UI = "#DCE9F7", "#DDF2E7", "#EEEEEE", "#E9E3F5"
E_PY, E_SL, E_DATA, E_UI = "#2A78D6", "#1BAF7A", "#7A7A7A", "#4A3AA7"


def box(ax, x, y, w, h, title, body, fc, ec):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0,rounding_size=0.015", fc=fc, ec=ec, lw=1.0))
    ax.text(x + w / 2, y + h - 0.018, title, ha="center", va="top", fontsize=7.8, fontweight="bold")
    ax.text(x + w / 2, y + h - 0.058, body, ha="center", va="top", fontsize=7, linespacing=1.25)


LBL = dict(fontsize=7, style="italic", color="#333333", linespacing=1.2)


def arrow(ax, *pts, text=None, tx=None, ha="left", va="center"):
    """Continuous arrow through the given points (straight or elbowed); the label is placed beside it, never on it."""
    for p, q in zip(pts[:-2], pts[1:-1]):
        ax.plot([p[0], q[0]], [p[1], q[1]], color="#333333", lw=1.0, solid_capstyle="butt")
    ax.add_patch(FancyArrowPatch(pts[-2], pts[-1], arrowstyle="-|>", mutation_scale=10, lw=1.0, color="#333333",
                                 shrinkA=0, shrinkB=0))
    if text:
        ax.text(tx[0], tx[1], text, ha=ha, va=va, **LBL)


def framework():
    fig, ax = plt.subplots(figsize=(7.2, 6.4))
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    A, B, C, Wd = 0.0, 0.37, 0.75, 0.25
    for x, t, c in ((A, "Measured data", E_DATA), (B, "Python", E_PY), (C, "MATLAB / Simulink", E_SL)):
        ax.text(x, 0.995, t, fontsize=9, fontweight="bold", color=c, va="top")
    # column A
    box(ax, A, 0.78, Wd, 0.17, "Published DGA records", f"IEC TC 10 ({FV['raw:IECTC10']})\nDissanayake ({FV['raw:DISTRAIN']} + "
        f"{FV['raw:DISTEST']})\nLi 2019 ({FV['raw:LI2019']})", C_DATA, E_DATA)
    box(ax, A, 0.54, Wd, 0.16, "Master table", f"{FV['master:all']} records, five gases (ppm)\ndevelopment {FV['role:development']}, "
        f"held-out {FV['role:internal_test'] + FV['role:benchmark'] + FV['role:external_test']}\nfrozen data version 1.0",
        C_DATA, E_DATA)
    box(ax, A, 0.02, Wd, 0.43, "Statistical evaluation", "macro-F1 with Wilson and\nbootstrap intervals\n\nMcNemar and Cochran\n"
        "tests with Holm\n\nCohen's kappa\n\nboundary regression\n\nreduced-gas loss\n\n(uses the conventional\nanswers from MATLAB)",
        C_PY, E_PY)
    arrow(ax, (0.125, 0.78), (0.125, 0.70), text="clean, map labels,\nremove leakage", tx=(0.135, 0.74))
    arrow(ax, (0.125, 0.54), (0.125, 0.45), text="held-out records\n(opened once)", tx=(0.135, 0.495))
    # column B
    box(ax, B, 0.78, Wd + 0.01, 0.17, "Machine-learning pipeline", "features F1–F4; five classifiers\nand a baseline; nested CV\n"
        "(5 × 10 outer, 5 inner folds)", C_PY, E_PY)
    box(ax, B, 0.54, Wd + 0.01, 0.16, "Released model", "Random Forest on F4\nSHA-256 fingerprint checked\n"
        "explained by permutation, SHAP", C_PY, E_PY)
    box(ax, B, 0.28, Wd + 0.01, 0.17, "FastAPI diagnosis service", "POST /diagnose\n(127.0.0.1:8000)\nclass, probabilities,\nmodel version",
        C_PY, E_PY)
    arrow(ax, (Wd, 0.62), (0.31, 0.62), (0.31, 0.865), (B, 0.865), text="development\nrecords", tx=(0.318, 0.745))
    arrow(ax, (0.50, 0.78), (0.50, 0.70))
    arrow(ax, (0.50, 0.54), (0.50, 0.45), text="loads", tx=(0.51, 0.495))
    arrow(ax, (B, 0.58), (0.29, 0.58), (0.29, 0.36), (Wd, 0.36), text="test\npredictions", tx=(0.298, 0.50))
    # column C
    box(ax, C, 0.78, Wd, 0.17, "Conventional methods", "Rogers ratio\nIEC 60599 ratio\nDuval Triangle 1\n"
        "normality gate\nboundary distance", C_SL, E_SL)
    box(ax, C, 0.28, Wd, 0.17, "Dashboard and test bench", "MATLAB App Designer\nboth diagnoses side by side\n"
        "agreement lamp, Duval plot\nresponse-time log", C_UI, E_UI)
    box(ax, C, 0.02, Wd, 0.18, "Simulink operating model", "40 MVA, 110/20 kV transformer\nIEC 60076-7 thermal network,\n"
        "ageing; sampling events give\na record_id, never a gas value", C_SL, E_SL)
    arrow(ax, (0.875, 0.78), (0.875, 0.45), text="called for\nevery record", tx=(0.885, 0.615))
    arrow(ax, (0.875, 0.20), (0.875, 0.28), text="record_id at\nsampling events", tx=(0.885, 0.24))
    arrow(ax, (C, 0.40), (B + Wd + 0.01, 0.40), text="five gases\n(JSON)", tx=(0.69, 0.415), ha="center", va="bottom")
    arrow(ax, (B + Wd + 0.01, 0.33), (C, 0.33), text="ML class and\nprobabilities", tx=(0.69, 0.315), ha="center", va="top")
    fig.savefig(OUT / "F3_1_framework.png", dpi=300, bbox_inches="tight", facecolor="white")
    plt.close(fig)

def nested_cv():
    fig, ax = plt.subplots(figsize=(7.2, 3.3))
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    ax.text(0.0, 0.98, f"Outer loop on the development set ({FV['role:development']} records)", fontweight="bold", va="top",
            fontsize=8.5)
    ax.text(0.62, 0.98, "Inner loop (each outer training part)", fontweight="bold", va="top", fontsize=8.5)
    for r, lab in enumerate(["Repeat 1", "Repeat 2", "...", "Repeat 10"]):
        y = 0.76 - r * 0.13
        ax.text(0.0, y + 0.045, lab, fontsize=7.5, va="center")
        for k in range(5):
            test = k == [0, 1, None, 2][r]
            if r == 2:
                continue
            ax.add_patch(FancyBboxPatch((0.10 + k * 0.088, y), 0.082, 0.09, boxstyle="square,pad=0",
                                        fc="#F6C7AE" if test else "#CFE2F7", ec="#555555", lw=0.6))
            ax.text(0.10 + k * 0.088 + 0.041, y + 0.045, "test" if test else "train", ha="center", va="center", fontsize=7)
    ax.text(0.10, 0.27, "5 stratified folds that keep near-duplicate groups together,\nrepeated 10 times = 50 test-fold "
            "estimates per pipeline", fontsize=7.3, va="top")
    arrow(ax, (0.55, 0.81), (0.61, 0.81))
    for k in range(5):
        val = k == 2
        ax.add_patch(FancyBboxPatch((0.62 + k * 0.074, 0.76), 0.068, 0.09, boxstyle="square,pad=0",
                                    fc="#FBE3D6" if val else "#DDF2E7", ec="#555555", lw=0.6))
        ax.text(0.62 + k * 0.074 + 0.034, 0.805, "val" if val else "fit", ha="center", va="center", fontsize=7)
    ax.text(0.62, 0.70, "StratifiedGroupKFold(5) grid search,\ntuning score macro-F1; the best setting\nis refitted on the "
            "whole outer training\npart and scored on the outer test fold", fontsize=7.3, va="top")
    ax.add_patch(FancyBboxPatch((0.0, 0.0), 1.0, 0.13, boxstyle="round,pad=0,rounding_size=0.01", fc="#EEEEEE", ec="#7A7A7A",
                                lw=0.8))
    ax.text(0.5, 0.065, f"Closed until the final model was chosen, then opened once (logged): internal test "
            f"({FV['role:internal_test']}), IEC TC 10 ({FV['role:benchmark']}), Li 2019 ({FV['role:external_test']})",
            ha="center", va="center", fontsize=7.5)
    fig.savefig(OUT / "F3_3_nested_cv.png", dpi=300, bbox_inches="tight", facecolor="white")
    plt.close(fig)


if __name__ == "__main__":
    framework()
    nested_cv()
    print("diagrams written")
