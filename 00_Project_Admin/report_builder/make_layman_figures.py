"""Two simple pictures for Project_Explained_Simply.docx (17 Oct 2026). Only words and arrows: no data values.
Run with the project venv:  06_Python_ML/.venv/Scripts/python.exe -I make_layman_figures.py
"""
from pathlib import Path
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

OUT = Path(__file__).resolve().parents[1] / "layman_figures"
OUT.mkdir(exist_ok=True)


def box(ax, x, y, w, h, text, fc, fs=9.5, bold=False):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.02,rounding_size=0.15", fc=fc, ec="#333333", lw=1.2))
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center", fontsize=fs, fontweight="bold" if bold else "normal", wrap=True)


def arrow(ax, x1, y1, x2, y2):
    ax.add_patch(FancyArrowPatch((x1, y1), (x2, y2), arrowstyle="-|>", mutation_scale=16, lw=1.5, color="#333333"))


# 1 the whole idea in one picture ---------------------------------------------------------------------------------------
fig, ax = plt.subplots(figsize=(11, 4.6))
ax.set_xlim(0, 22.3); ax.set_ylim(0, 9.2); ax.axis("off")
box(ax, 0.2, 3.6, 3.6, 2.2, "1. A sample of the\ntransformer oil", "#e8f0fb")
box(ax, 4.8, 3.6, 3.6, 2.2, "2. A laboratory\nmeasures 5 gases\nin the oil", "#e8f0fb")
box(ax, 9.4, 6.0, 4.4, 2.2, "3a. Three rulebooks\n(Rogers, IEC 60599,\nDuval Triangle)", "#fdf0d8")
box(ax, 9.4, 1.2, 4.4, 2.2, "3b. A computer model\n(machine learning)", "#fdf0d8")
box(ax, 14.7, 3.6, 3.2, 2.2, "4. Compare the\nfour opinions", "#e6f3e6")
box(ax, 18.9, 3.6, 3.1, 2.2, "5. ONE answer:\nhealthy or\nfault type", "#f6dede", fs=9, bold=True)
arrow(ax, 3.8, 4.7, 4.8, 4.7)
arrow(ax, 8.4, 4.9, 9.4, 6.6)
arrow(ax, 8.4, 4.5, 9.4, 3.0)
arrow(ax, 13.8, 6.6, 14.7, 5.2)
arrow(ax, 13.8, 3.0, 14.7, 4.2)
arrow(ax, 17.9, 4.7, 18.9, 4.7)
ax.text(11, 8.9, "From a drop of oil to a decision", ha="center", fontsize=14, fontweight="bold")
fig.savefig(OUT / "L1_big_picture.png", dpi=170, bbox_inches="tight")
plt.close(fig)

# 2 the project in three parts --------------------------------------------------------------------------------------------
fig, ax = plt.subplots(figsize=(11, 4.2))
ax.set_xlim(0, 22); ax.set_ylim(0, 8.4); ax.axis("off")
box(ax, 0.3, 2.0, 6.2, 4.4, "PYTHON\n(the learner)\n\nStudies 827 labelled\ngas records and learns\nwhich gas pattern means\nwhich fault", "#e8f0fb", fs=10)
box(ax, 7.9, 2.0, 6.2, 4.4, "SIMULINK / MATLAB\n(the operator)\n\nSimulates how hot the\ntransformer runs, takes\noil samples on a schedule,\ncomputes the 3 rulebooks", "#fdf0d8", fs=10)
box(ax, 15.5, 2.0, 6.2, 4.4, "DASHBOARD\n(the screen)\n\nShows the four opinions\nside by side, one verdict,\nand what to do", "#e6f3e6", fs=10)
arrow(ax, 6.5, 4.2, 7.9, 4.2)
arrow(ax, 14.1, 4.2, 15.5, 4.2)
ax.text(7.2, 4.75, "service", ha="center", fontsize=9)
ax.text(14.8, 4.75, "results", ha="center", fontsize=9)
ax.text(11, 7.7, "The three parts of the project", ha="center", fontsize=14, fontweight="bold")
fig.savefig(OUT / "L2_three_parts.png", dpi=170, bbox_inches="tight")
plt.close(fig)
print("written", sorted(p.name for p in OUT.iterdir()))

