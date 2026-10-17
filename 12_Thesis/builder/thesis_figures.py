"""Thesis versions of the result figures, redrawn with full axis labels, units and one consistent style.

Every figure is drawn from the data file saved beside the original figure in 11_Results/figures (the plotted
numbers), from 11_Results/08_Statistical_Analysis result files, or - for the gas box plots - from the frozen
development records of dga_master.csv. No value is computed differently from the analysis; the logistic curves of
the boundary figure are refitted from the saved boundary data and checked against the saved coefficients.
Output: 12_Thesis/figures/thesis/*.png (300 dpi).
"""
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402
import statsmodels.api as sm  # noqa: E402
from matplotlib.patches import Polygon, FancyBboxPatch, FancyArrowPatch  # noqa: E402
import sys  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
FIG = ROOT / "11_Results" / "figures"
STAT = ROOT / "08_Statistical_Analysis"
OUT = ROOT / "12_Thesis" / "figures" / "thesis"
OUT.mkdir(parents=True, exist_ok=True)
sys.path.insert(0, str(ROOT / "06_Python_ML" / "src" / "conventional"))
import conventional_methods as CM  # noqa: E402

plt.rcParams.update({"font.family": "Arial", "font.size": 9, "axes.titlesize": 9.5, "axes.labelsize": 9,
                     "xtick.labelsize": 8.5, "ytick.labelsize": 8.5, "legend.fontsize": 8, "axes.edgecolor": "#555555",
                     "axes.grid": True, "grid.color": "#E1E0D9", "grid.linewidth": 0.6, "axes.axisbelow": True,
                     "axes.spines.top": False, "axes.spines.right": False, "savefig.dpi": 300, "figure.dpi": 100})
STYLE = pd.read_csv(FIG / "plot_style.csv")
CCOL = {r.item: r.colour_hex for r in STYLE[STYLE.kind == "class"].itertuples()}
CMK = {r.item: r.marker_matplotlib for r in STYLE[STYLE.kind == "class"].itertuples()}
MCOL = {r.item: r.colour_hex for r in STYLE[STYLE.kind == "method"].itertuples()}
MMK = {r.item: r.marker_matplotlib for r in STYLE[STYLE.kind == "method"].itertuples()}
CNAME = {"Normal": "Normal", "PD": "PD", "D1": "D1", "D2": "D2", "T1": "T1", "T2": "T2", "T12": "T1/T2", "T3": "T3"}
CLONG = {"Normal": "Normal", "PD": "PD – partial discharge", "D1": "D1 – low-energy discharge",
         "D2": "D2 – high-energy discharge", "T1": "T1 – thermal < 300 °C", "T2": "T2 – thermal 300–700 °C",
         "T12": "T1/T2 – thermal < 700 °C (merged)", "T3": "T3 – thermal > 700 °C"}
GAS_TEX = {"H2": "H$_2$", "CH4": "CH$_4$", "C2H6": "C$_2$H$_6$", "C2H4": "C$_2$H$_4$", "C2H2": "C$_2$H$_2$"}
METH = {"ML": "ML (Random Forest)", "Rogers": "Rogers ratio", "IEC60599": "IEC 60599 ratio", "Duval": "Duval Triangle 1"}
SETS = {"Internal test": "Internal test set (n = 61)", "IEC TC 10 (power transformers)": "IEC TC 10 power transformers (n = 58)",
        "Li 2019": "Li (2019) set (n = 86)"}
W = 6.3   # full text width in inches


def tex(s):
    import re
    return re.sub(r"C2H6|C2H4|C2H2|CH4|H2", lambda m: GAS_TEX[m.group(0)], s)


def save(fig, name):
    fig.savefig(OUT / f"{name}.png", bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print("  ", name)


# ------------------------------------------------------------------ data chapter
def records_per_class():
    d = pd.read_csv(FIG / "F4_1_records_per_class.csv")
    titles = {"Development": "(a) Development set (n = 439)", "Internal test": "(b) Internal test set (n = 70)",
              "IEC TC 10 benchmark": "(c) IEC TC 10 benchmark (n = 117)", "External test (Li 2019)": "(d) Li (2019) set (n = 201)"}
    fig, axs = plt.subplots(2, 2, figsize=(W, 5.0))
    for ax, (p, g) in zip(axs.flat, d.groupby("panel", sort=False)):
        cls = list(g["class"])
        b = ax.bar([CNAME[c] for c in cls], g.records, color=[CCOL[c] for c in cls], width=0.7)
        ax.bar_label(b, fontsize=8, padding=1)
        ax.set_title(titles.get(p, p), loc="left")
        ax.set_xlabel("Fault class")
        ax.set_ylabel("Number of records")
        ax.set_ylim(0, g.records.max() * 1.18)
        ax.grid(axis="x", visible=False)
    fig.tight_layout()
    save(fig, "records_per_class")


def gas_boxplots():
    m = pd.read_csv(ROOT / "03_Data" / "processed" / "dga_master.csv")
    dev = m[m.data_role == "development"]
    stats = pd.read_csv(ROOT / "11_Results" / "tables" / "T4_2_gas_by_class_development.csv").set_index("Gas")
    classes = ["Normal", "PD", "D1", "D2", "T1", "T2", "T3"]
    fig, axs = plt.subplots(2, 3, figsize=(W, 5.4))
    for ax, g in zip(axs.flat, ["H2", "CH4", "C2H6", "C2H4", "C2H2"]):
        data = [dev.loc[dev.class_name == c, g].to_numpy(float) + 1 for c in classes]
        bp = ax.boxplot(data, patch_artist=True, widths=0.6, whis=1.5, flierprops=dict(marker=".", ms=3, mec="#888888"),
                        medianprops=dict(color="black", lw=1.1))
        for patch, c in zip(bp["boxes"], classes):
            patch.set_facecolor(CCOL[c])
            patch.set_alpha(0.85)
        ax.set_yscale("log")
        ax.set_xticks(range(1, 8), classes, rotation=45, ha="right", rotation_mode="anchor")
        st = stats.loc[g]
        ax.set_title(f"{tex(g)}: H = {st['KW H']:.1f}, ε$^2_R$ = {st['epsilon2_R']:.2f}", loc="left")
        ax.set_xlabel("Fault class")
        ax.set_ylabel("Concentration + 1 (ppm)")
        ax.grid(axis="x", visible=False)
    axs.flat[-1].axis("off")
    axs.flat[-1].text(0.02, 0.7, "Box: interquartile range\nLine: median\nWhiskers: 1.5 × interquartile range\n"
                      "Points: values outside the whiskers\nVertical axes: logarithmic scale\n"
                      "H: Kruskal–Wallis statistic (all p < 0.001)\nε$^2_R$: rank epsilon-squared effect size",
                      fontsize=8, va="top", linespacing=1.5)
    fig.tight_layout()
    save(fig, "gas_boxplots")


def gas_correlation():
    d = pd.read_csv(FIG / "F4_3_gas_correlation.csv").set_index("gas")
    fig, ax = plt.subplots(figsize=(4.4, 3.6))
    im = ax.imshow(d.to_numpy(), cmap="RdBu", vmin=-1, vmax=1)
    labels = [tex(g) for g in d.index]
    ax.set_xticks(range(5), labels)
    ax.set_yticks(range(5), labels)
    for i in range(5):
        for j in range(5):
            v = d.iloc[i, j]
            ax.text(j, i, f"{v:.2f}", ha="center", va="center", fontsize=8.5, color="white" if v > 0.7 else "black")
    ax.set_xlabel("Gas")
    ax.set_ylabel("Gas")
    ax.grid(False)
    cb = fig.colorbar(im, ax=ax, fraction=0.046, pad=0.04)
    cb.set_label("Spearman rank correlation ρ$_s$")
    save(fig, "gas_correlation")


# ------------------------------------------------------------------ Duval triangle
ZONE_FILL = {"PD": "#CDE2FB", "T1": "#FBE7B5", "T2": "#F7D3E1", "T3": "#C9E6C9", "D1": "#F8D2C2", "D2": "#C8EEDF",
             "DT": "#EEEEEE"}


def tri_xy(c2h4, c2h2):
    ch4 = 100 - c2h4 - c2h2
    return c2h4 + ch4 / 2, ch4 * np.sqrt(3) / 2


def duval_axes(ax):
    rules = CM.load_duval()
    centers = {}
    for zone, poly in CM.rule_polygons(rules):
        ax.add_patch(Polygon(poly, closed=True, fc=ZONE_FILL[zone], ec="#999999", lw=0.6, zorder=0))
        centers.setdefault(zone, []).append(np.mean(np.array(poly), axis=0))
    tri = np.array([(0, 0), (100, 0), (50, 50 * np.sqrt(3)), (0, 0)])
    ax.plot(tri[:, 0], tri[:, 1], color="black", lw=1.0, zorder=3)
    s3 = np.sqrt(3) / 2
    for v in range(10, 100, 10):   # ticks on the three sides
        xb = float(v)                # base (CH4 = 0): %C2H4 = v at x = v
        ax.plot([xb, xb], [0, -2.0], color="black", lw=0.6)
        ax.text(xb, -3.0, f"{v}", ha="center", va="top", fontsize=7)
        xr, yr = (100 - v) + v / 2, v * s3   # right side (C2H2 = 0): %CH4 = v
        ax.plot([xr, xr + 2.2], [yr, yr], color="black", lw=0.6)
        ax.text(xr + 3.0, yr, f"{v}", ha="left", va="center", fontsize=7)
        xl, yl = (100 - v) / 2, (100 - v) * s3   # left side (C2H4 = 0): %C2H2 = v
        ax.plot([xl, xl - 2.2], [yl, yl], color="black", lw=0.6)
        ax.text(xl - 3.0, yl, f"{v}", ha="right", va="center", fontsize=7)
    ax.text(50, -9.5, "% C$_2$H$_4$ →", ha="center", va="top", fontsize=8.5)
    ax.text(88, 50, "← % CH$_4$", ha="left", va="center", fontsize=8.5, rotation=-60)
    ax.text(12, 50, "% C$_2$H$_2$ →", ha="right", va="center", fontsize=8.5, rotation=60)
    polys = {}
    for zone, poly in CM.rule_polygons(rules):
        a = np.array(poly)
        area = 0.5 * abs(np.dot(a[:, 0], np.roll(a[:, 1], 1)) - np.dot(a[:, 1], np.roll(a[:, 0], 1)))
        if zone not in polys or area > polys[zone][0]:
            polys[zone] = (area, a.mean(axis=0))
    for z in ["D1", "D2", "DT", "T3"]:
        x, y = polys[z][1]
        ax.text(x, y, z, fontsize=8.5, fontweight="bold", color="#333333", ha="center", va="center", zorder=7, bbox=dict(fc="white", ec="none", alpha=0.75, pad=0.8))
    ax.text(50, 88.5, "PD", fontsize=8.5, fontweight="bold", color="#333333", ha="center", va="bottom", zorder=4)
    for z, (tx, ty) in {"T1": (20, 91), "T2": (20, 83)}.items():
        x, y = polys[z][1]
        ax.annotate(z, (x, y), (tx, ty), fontsize=8.5, fontweight="bold", color="#333333", ha="center", va="center",
                    arrowprops=dict(arrowstyle="-", color="#555555", lw=0.6), zorder=7)
    ax.set_xlim(-14, 114)
    ax.set_ylim(-16, 95)
    ax.set_aspect("equal")
    ax.axis("off")


def duval_plot(csvname, title, outname):
    d = pd.read_csv(FIG / csvname).dropna(subset=["pct_CH4"])
    fig, ax = plt.subplots(figsize=(5.2, 4.9))
    duval_axes(ax)
    for c in ["Normal", "PD", "D1", "D2", "T1", "T2", "T12", "T3"]:
        g = d[d.true_class == c]
        if len(g) == 0:
            continue
        x, y = tri_xy(g.pct_C2H4.to_numpy(), g.pct_C2H2.to_numpy())
        ax.scatter(x, y, s=16, marker=CMK[c], color=CCOL[c], edgecolor="black", linewidth=0.3, zorder=5,
                   label=f"{CLONG[c]} (n = {len(g)})")
    ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.02), ncol=2, frameon=False, title="True fault class",
              title_fontsize=8.5)
    ax.set_title(title)
    save(fig, outname)


def duval_disagreements():
    d = pd.read_csv(FIG / "F4_13_duval_disagreements.csv").dropna(subset=["pct_CH4"])
    fig, ax = plt.subplots(figsize=(5.2, 5.0))
    duval_axes(ax)
    a = d[~d.disagree]
    x, y = tri_xy(a.pct_C2H4.to_numpy(), a.pct_C2H2.to_numpy())
    ax.scatter(x, y, s=6, color="#777777", zorder=5, label=f"ML and Duval agree (n = {len(a)})")
    for c in ["Normal", "PD", "D1", "D2", "T1", "T2", "T12", "T3"]:
        g = d[d.disagree & (d.true_class == c)]
        if len(g) == 0:
            continue
        x, y = tri_xy(g.pct_C2H4.to_numpy(), g.pct_C2H2.to_numpy())
        ax.scatter(x, y, s=22, marker=CMK[c], color=CCOL[c], edgecolor="black", linewidth=0.3, zorder=6,
                   label=f"disagree, true {CNAME[c]} (n = {len(g)})")
    ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.02), ncol=2, frameon=False)
    save(fig, "duval_disagreements")


# ------------------------------------------------------------------ confusion matrices
def confusion(csvname, outname, methods, label_by_set=False):
    d = pd.read_csv(FIG / csvname)
    d = d[d.evaluation_set.isin(SETS.keys())]          # the three primary test sets only
    panels = list(dict.fromkeys(zip(d.evaluation_set, d.method)))
    n = len(panels)
    ncols = []
    for s, m in panels:
        g = d[(d.evaluation_set == s) & (d.method == m)]
        rows = set(g.true)
        ncols.append(sum(1 for c in dict.fromkeys(g.answer) if g[g.answer == c]["count"].sum() > 0 or c in rows))
    fig, axs = plt.subplots(1, n, figsize=(W, 3.0 if label_by_set else 2.6), gridspec_kw=dict(width_ratios=ncols))
    for ax, (s, m) in zip(np.atleast_1d(axs), panels):
        g = d[(d.evaluation_set == s) & (d.method == m)]
        rows = list(dict.fromkeys(g.true))
        cols = [c for c in dict.fromkeys(g.answer) if g[g.answer == c]["count"].sum() > 0 or c in rows]
        mat = g.pivot_table(index="true", columns="answer", values="count", aggfunc="sum").reindex(index=rows, columns=cols).fillna(0)
        pct = mat.div(mat.sum(axis=1).replace(0, 1), axis=0)
        ax.imshow(pct.to_numpy(), cmap="Blues", vmin=0, vmax=1, aspect="auto")
        for i in range(len(rows)):
            for j in range(len(cols)):
                v = int(mat.iloc[i, j])
                ax.text(j, i, f"{v}", ha="center", va="center", fontsize=7, color="white" if pct.iloc[i, j] > 0.6 else "black")
        ax.set_xticks(range(len(cols)), [CNAME.get(c, c) for c in cols], rotation=60, fontsize=7.5)
        ax.set_yticks(range(len(rows)), [CNAME.get(c, c) for c in rows], fontsize=7.5)
        ax.set_title(SETS.get(s, s).replace(" (n = ", "\n(n = ") if label_by_set else METH.get(m, m), fontsize=8.5)
        ax.set_xlabel("Diagnosis given")
        ax.set_ylabel("True fault class")
        ax.grid(False)
    fig.tight_layout()
    save(fig, outname)


# ------------------------------------------------------------------ cross-validation
MODEL = {"majority": "Majority\nbaseline", "logistic_regression": "Logistic\nregression", "svm": "SVM\n(RBF)",
         "random_forest": "Random\nForest", "xgboost": "XGBoost", "mlp": "MLP neural\nnetwork"}


def cv_boxplots():
    d = pd.read_csv(FIG / "F4_6_cv_boxplots.csv")
    order = ["majority", "logistic_regression", "svm", "random_forest", "xgboost", "mlp"]
    fig, ax = plt.subplots(figsize=(W, 3.0))
    data = [d[d.model == m].macro_f1.to_numpy() for m in order]
    bp = ax.boxplot(data, widths=0.5, patch_artist=True, showfliers=False, medianprops=dict(color="black"))
    for p, m in zip(bp["boxes"], order):
        p.set_facecolor("#CDE2FB" if m != "majority" else "#DDDDDD")
    rng = np.random.default_rng(1)
    for i, v in enumerate(data, 1):
        ax.scatter(i + rng.uniform(-0.12, 0.12, len(v)), v, s=6, color="#0D366B", zorder=3)
    ax.set_xticks(range(1, 7), [MODEL[m] for m in order])
    ax.set_xlabel("Classifier (feature set F4)")
    ax.set_ylabel("Macro-F1 in each outer fold")
    ax.set_ylim(0, 1)
    ax.grid(axis="x", visible=False)
    save(fig, "cv_boxplots")


def cd_diagram():
    d = pd.read_csv(FIG / "F4_7_critical_difference.csv").sort_values("average_rank")
    cd = d.cd.iloc[0]
    names = {"majority": "Majority baseline", "logistic_regression": "Logistic regression", "svm": "SVM (RBF)",
             "random_forest": "Random Forest", "xgboost": "XGBoost", "mlp": "MLP neural network"}
    fig, ax = plt.subplots(figsize=(W, 2.3))
    ax.set_xlim(0.6, 6.4)
    ax.set_ylim(-3.2, 1.6)
    ax.axis("off")
    ax.plot([1, 6], [0, 0], color="black", lw=1)
    for k in range(1, 7):
        ax.plot([k, k], [0, 0.12], color="black", lw=1)
        ax.text(k, 0.25, str(k), ha="center", va="bottom", fontsize=8.5)
    ax.text(3.5, 0.75, "Average rank over the 50 outer folds (1 = best)", ha="center", fontsize=8.5)
    ax.plot([1, 1 + cd], [1.3, 1.3], color="black", lw=2)
    ax.text(1 + cd / 2, 1.42, f"Critical difference = {cd:.2f}", ha="center", va="bottom", fontsize=8)
    left = d.iloc[:3]
    right = d.iloc[3:]
    for i, r in enumerate(left.itertuples()):
        y = -0.6 - 0.7 * i
        ax.plot([r.average_rank, r.average_rank, 0.95], [0, y, y], color="#555555", lw=0.8)
        ax.text(0.9, y, f"{names[r.model]} ({r.average_rank:.2f})", ha="right", va="center", fontsize=8.5)
    for i, r in enumerate(right.itertuples()):
        y = -0.6 - 0.7 * (len(right) - 1 - i)
        ax.plot([r.average_rank, r.average_rank, 6.05], [0, y, y], color="#555555", lw=0.8)
        ax.text(6.1, y, f"{names[r.model]} ({r.average_rank:.2f})", ha="left", va="center", fontsize=8.5)
    ranks = list(d.average_rank)
    groups, i = [], 0
    for i in range(len(ranks)):
        j = max(k for k in range(len(ranks)) if ranks[k] - ranks[i] < cd)
        if j > i and not any(a <= i and j <= b for a, b in groups):
            groups.append((i, j))
    for k, (a, b) in enumerate(groups):
        ax.plot([ranks[a] - 0.03, ranks[b] + 0.03], [-0.25 - 0.18 * k] * 2, color="black", lw=3)
    fig.subplots_adjust(left=0.2, right=0.8)
    save(fig, "cd_diagram")


# ------------------------------------------------------------------ comparison
def main_comparison(csvname, outname):
    d = pd.read_csv(FIG / csvname)
    meas = [("strict_accuracy", "Strict accuracy"), ("conditional_accuracy", "Conditional accuracy"), ("macro_f1", "Macro-F1")]
    order = ["ML", "Rogers", "IEC60599", "Duval"]
    fig, axs = plt.subplots(1, 3, figsize=(W, 2.3), sharey=True)
    for ax, (col, lab) in zip(axs, meas):
        for i, m in enumerate(order):
            r = d[d.method == m].iloc[0]
            y = len(order) - 1 - i
            ax.errorbar(r[col], y, xerr=[[r[col] - r[col + "_lo"]], [r[col + "_hi"] - r[col]]], fmt=MMK[m], color=MCOL[m],
                        ms=5, capsize=2.5, lw=1.2)
        ax.set_xlim(0, 1)
        ax.set_xlabel(lab + " (95 % CI)")
    labels = []
    for m in order:
        r = d[d.method == m].iloc[0]
        labels.append(f"{METH[m]}\ncoverage {r.coverage:.2f}")
    axs[0].set_yticks(range(len(order) - 1, -1, -1), labels)
    axs[0].set_ylabel("Method")
    fig.tight_layout()
    save(fig, outname)


def f1_per_class():
    d = pd.read_csv(FIG / "F4_10_f1_per_class.csv")
    order = ["ML", "Rogers", "IEC60599", "Duval"]
    fig, axs = plt.subplots(3, 1, figsize=(W, 7.2))
    for ax, (s, lab) in zip(axs, SETS.items()):
        g = d[d.evaluation_set == s]
        classes = list(dict.fromkeys(g["class"]))
        x = np.arange(len(classes))
        for k, m in enumerate(order):
            h = g[g.method == m].set_index("class").reindex(classes)
            ax.bar(x + (k - 1.5) * 0.2, h.f1, width=0.2, color=MCOL[m], label=METH[m],
                   yerr=[h.f1 - h.f1_lo, h.f1_hi - h.f1], error_kw=dict(lw=0.7, capsize=1.5))
        sup = g[g.method == "ML"].set_index("class").reindex(classes).support
        ax.set_xticks(x, [f"{CNAME[c]}\n(n = {int(n)})" for c, n in zip(classes, sup)])
        ax.set_ylim(0, 1.05)
        ax.set_ylabel("F1-score")
        ax.set_title(lab, loc="left")
        ax.grid(axis="x", visible=False)
    axs[-1].set_xlabel("True fault class (number of test records)")
    axs[0].legend(ncol=4, loc="lower center", bbox_to_anchor=(0.5, 1.12), frameon=False)
    fig.tight_layout()
    save(fig, "f1_per_class")


def kappa():
    d = pd.read_csv(FIG / "F4_11_kappa_agreement.csv")
    lab = {"True label": "True class", "ML (selected model)": "ML", "Rogers Ratio": "Rogers", "IEC 60599 ratio": "IEC 60599",
           "Duval Triangle 1": "Duval"}
    names = list(lab.values())
    fig, axs = plt.subplots(1, 3, figsize=(W, 2.6))
    for ax, (s, title) in zip(axs, SETS.items()):
        g = d[d.evaluation_set == s]
        mat = np.eye(5)
        for r in g.itertuples():
            i, j = names.index(lab[r.a]), names.index(lab[r.b])
            mat[i, j] = mat[j, i] = r.kappa
        ax.imshow(mat, cmap="RdBu", vmin=-1, vmax=1)
        for i in range(5):
            for j in range(5):
                ax.text(j, i, f"{mat[i, j]:.2f}", ha="center", va="center", fontsize=7, color="white" if mat[i, j] > 0.7 else "black")
        ax.set_xticks(range(5), names, rotation=50, fontsize=7.5)
        ax.set_yticks(range(5), names, fontsize=7.5)
        ax.set_title(title.replace(" (n = ", "\n(n = "), fontsize=8.5)
        ax.grid(False)
    axs[0].set_ylabel("Rater")
    axs[1].set_xlabel("Rater")
    fig.tight_layout()
    save(fig, "kappa")


def boundary():
    bd = pd.read_csv(STAT / "boundary_data.csv")
    reg = pd.read_csv(STAT / "boundary_regression.csv")
    binned = pd.read_csv(FIG / "F4_12_disagreement_vs_distance.csv")
    fig, axs = plt.subplots(1, 3, figsize=(W, 2.6), sharey=True)
    for ax, (m, lab) in zip(axs, [("Rogers", "Rogers ratio"), ("IEC60599", "IEC 60599 ratio"), ("Duval", "Duval Triangle 1")]):
        g = bd[(bd.method == m) & (bd.variant == "primary") & bd.finite.astype(bool)]
        z = (g.distance - g.distance.mean()) / g.distance.std(ddof=0)
        X = sm.add_constant(z.to_numpy())
        fit = sm.Logit(g.disagree.to_numpy(), X).fit(disp=0)
        saved = reg[(reg.method == m) & (reg.variant == "primary") & (reg.analysis == "pooled (main)")].iloc[0]
        if abs(fit.params[1] - saved.beta1) > 1e-3:
            z = (g.distance - g.distance.mean()) / g.distance.std(ddof=1)
            fit = sm.Logit(g.disagree.to_numpy(), sm.add_constant(z.to_numpy())).fit(disp=0)
        assert abs(fit.params[1] - saved.beta1) < 1e-3, (m, fit.params[1], saved.beta1)
        xs = np.linspace(z.min(), z.max(), 200)
        Xs = sm.add_constant(xs)
        eta = Xs @ fit.params
        se = np.sqrt(np.einsum("ij,jk,ik->i", Xs, fit.cov_params(), Xs))
        p = lambda e: 1 / (1 + np.exp(-e))  # noqa: E731
        col = MCOL[m]
        ax.fill_between(xs, p(eta - 1.96 * se), p(eta + 1.96 * se), color=col, alpha=0.2, lw=0)
        ax.plot(xs, p(eta), color=col, lw=1.6)
        b = binned[binned.method == m]
        ax.errorbar(b.z_mean, b.rate, yerr=[b.rate - b.wilson_lo, b.wilson_hi - b.rate], fmt="o", color="black", ms=3.5,
                    capsize=1.5, lw=0.8)
        ax.set_title(f"{lab}\nOR = {saved['or']:.2f} [{saved.or_lo:.2f}, {saved.or_hi:.2f}] per SD", fontsize=8.5, loc="left")
        ax.set_ylim(0, 1)
        ax.set_xlabel("Boundary distance (z-score)")
    axs[0].set_ylabel("Probability that ML and\nthe method disagree")
    fig.tight_layout()
    save(fig, "boundary")


# ------------------------------------------------------------------ explainability
FEAT = {"log_H2": "log H2", "log_CH4": "log CH4", "log_C2H6": "log C2H6", "log_C2H4": "log C2H4", "log_C2H2": "log C2H2",
        "pct_H2": "% H2", "pct_CH4": "% CH4", "pct_C2H6": "% C2H6", "pct_C2H4": "% C2H4", "pct_C2H2": "% C2H2",
        "log_R1": "log R1 (CH4/H2)", "log_R2": "log R2 (C2H2/C2H4)", "log_R3": "log R3 (C2H2/CH4)",
        "log_R4": "log R4 (C2H6/C2H2)", "log_R5": "log R5 (C2H4/C2H6)", "duval_pct_CH4": "Duval % CH4",
        "duval_pct_C2H4": "Duval % C2H4", "duval_pct_C2H2": "Duval % C2H2"}


def permutation():
    d = pd.read_csv(FIG / "F4_14_permutation_importance.csv")
    fig, axs = plt.subplots(1, 2, figsize=(W, 4.0), gridspec_kw=dict(width_ratios=[1, 1.5]))
    for ax, lev, title, ylab in [(axs[0], "gas", "(a) One gas shuffled", "Gas shuffled"),
                                 (axs[1], "feature", "(b) One feature shuffled", "Feature shuffled")]:
        g = d[d.level == lev].sort_values("importance_mean")
        labels = [tex(FEAT.get(f, f)) for f in g.feature]
        y = np.arange(len(g))
        ax.barh(y, g.importance_mean, color="#2A78D6", height=0.65,
                xerr=[g.importance_mean - g.ci_low, g.ci_high - g.importance_mean], error_kw=dict(lw=0.7, capsize=1.5))
        ax.set_yticks(y, labels, fontsize=7.5 if lev == "feature" else 8.5)
        ax.axvline(0, color="#555555", lw=0.8)
        ax.set_xlabel("Drop in macro-F1 after shuffling")
        ax.set_ylabel(ylab)
        ax.set_title(title, loc="left")
        ax.grid(axis="y", visible=False)
    fig.tight_layout()
    save(fig, "permutation_importance")


# ------------------------------------------------------------------ reduced gases
def reduced_gas():
    d = pd.read_csv(FIG / "F4_16_accuracy_vs_number_of_gases.csv")
    full = d[d.n_gases == 5].macro_f1.iloc[0]
    best = d.loc[d.groupby("n_gases").macro_f1.idxmax()].sort_values("n_gases")
    fig, ax = plt.subplots(figsize=(W, 3.2))
    rng = np.random.default_rng(2)
    ax.scatter(d.n_gases + rng.uniform(-0.08, 0.08, len(d)), d.macro_f1, s=12, color="#999999", label="every gas combination (31)")
    ax.fill_between(best.n_gases, best.macro_f1_ci_low, best.macro_f1_ci_high, color="#2A78D6", alpha=0.18, lw=0,
                    label="95 % interval of the best combination")
    ax.plot(best.n_gases, best.macro_f1, "o-", color="#2A78D6", label="best combination of each size")
    ax.axhline(full - 0.05, color="black", ls="--", lw=0.9, label=f"five-gas value minus tolerance ({full:.3f} − 0.05)")
    mp = best[best.n_gases == 4].iloc[0]
    ax.annotate(tex("minimum panel: H2 + C2H6 + C2H4 + C2H2"), (4, mp.macro_f1), (2.3, 0.93), fontsize=8,
                arrowprops=dict(arrowstyle="->", color="#555555", lw=0.8))
    ax.set_xticks(range(1, 6))
    ax.set_xlabel("Number of gases measured")
    ax.set_ylabel("Macro-F1 (cross-validation)")
    ax.set_ylim(0, 1)
    ax.legend(loc="lower right", frameon=False)
    save(fig, "reduced_gas_curve")


def subset_matrix():
    d = pd.read_csv(FIG / "F4_17_gas_subset_matrix.csv").sort_values("macro_f1", ascending=False).reset_index(drop=True)
    gases = ["H2", "CH4", "C2H6", "C2H4", "C2H2"]
    fig, axs = plt.subplots(3, 1, figsize=(W, 5.4), sharex=True, gridspec_kw=dict(height_ratios=[2.2, 1.3, 0.7], hspace=0.08))
    x = np.arange(len(d))
    axs[0].bar(x, d.macro_f1, color="#2A78D6", yerr=[d.macro_f1 - d.macro_f1_ci_low, d.macro_f1_ci_high - d.macro_f1],
               error_kw=dict(lw=0.6, capsize=1.2))
    axs[0].axhline(d.macro_f1.max() - 0.05, color="black", ls="--", lw=0.8)
    axs[0].set_ylabel("Macro-F1\n(95 % CI)")
    axs[0].set_ylim(0, 1)
    for k, g in enumerate(gases):
        has = d[f"has_{g}"].astype(bool)
        axs[1].scatter(x[has], [k] * has.sum(), s=18, color="black")
        axs[1].scatter(x[~has], [k] * (~has).sum(), s=18, color="#DDDDDD")
    for i in x:
        ks = [k for k, g in enumerate(gases) if d.loc[i, f"has_{g}"]]
        axs[1].plot([i, i], [min(ks), max(ks)], color="black", lw=0.8)
    axs[1].set_yticks(range(5), [tex(g) for g in gases])
    axs[1].set_ylabel("Gases\nincluded")
    axs[1].grid(False)
    meth = [("Duval", "Duval"), ("IEC 60599", "IEC60599"), ("Rogers", "Rogers")]
    for k, (txt, key) in enumerate(meth):
        ok = d.conventional_usable.str.contains(txt)
        axs[2].scatter(x[ok], [k] * ok.sum(), marker="|", s=80, color=MCOL[key])
    axs[2].set_yticks(range(3), ["Duval usable", "IEC 60599 usable", "Rogers usable"])
    axs[2].set_ylim(-0.6, 2.6)
    axs[2].grid(False)
    axs[2].set_xticks(x, d.n_gases.astype(str), fontsize=7)
    axs[2].set_xlabel("Gas combinations ordered from best to worst (label = number of gases)")
    save(fig, "subset_matrix")


# ------------------------------------------------------------------ Simulink results
def simulink_verification():
    d = pd.read_csv(FIG / "F4_18_simulink_verification.csv")
    fig, axs = plt.subplots(2, 2, figsize=(W, 4.6), sharex=True)
    for j, (t, title) in enumerate([("Test 1 rated load", "(a) Rated load from a cold start"), ("Test 2 load step", "(b) Load step 0.6 → 1.2 pu at 6 h")]):
        g = d[d.test == t]
        ax = axs[0, j]
        ax.plot(g.time_h, g.oil_model_C, color="#0D366B", lw=1.4, label="Top-oil, Simulink model")
        ax.plot(g.time_h, g.hs_model_C, color="#E34948", lw=1.4, label="Hot-spot, Simulink model")
        ax.plot(g.time_h, g.oil_reference_C, "k--", lw=0.9, label="Independent solution of the IEC 60076-7 equations")
        ax.plot(g.time_h, g.hs_reference_C, "k--", lw=0.9)
        ax.set_title(title, loc="left")
        ax.set_ylabel("Temperature (°C)")
        ax = axs[1, j]
        ax.plot(g.time_h, g.oil_diff_K, color="#0D366B", lw=1.1, label="Top-oil")
        ax.plot(g.time_h, g.hs_diff_K, color="#E34948", lw=1.1, label="Hot-spot")
        ax.axhline(0.1, color="#888888", ls=":", lw=0.9, label="Tolerance ±0.1 K")
        ax.axhline(-0.1, color="#888888", ls=":", lw=0.9)
        ax.set_ylim(-0.15, 0.15)
        ax.set_xlabel("Time (h)")
        ax.set_ylabel("Model − reference (K)")
    h1, l1 = axs[0, 0].get_legend_handles_labels()
    h2, l2 = axs[1, 0].get_legend_handles_labels()
    fig.tight_layout(rect=(0, 0.07, 1, 1))
    fig.legend(h1 + h2[2:], l1 + l2[2:], loc="lower center", ncol=2, frameon=False, fontsize=7.5)
    save(fig, "simulink_verification")


def scenario(csvname, title, outname, L):
    d = pd.read_csv(FIG / csvname)
    t = d.time_h - d.time_h.min() if d.time_h.min() > 1 else d.time_h
    fig, axs = plt.subplots(3, 1, figsize=(W, 5.2), sharex=True)
    axs[0].plot(t, d.demand_pu, "--", color="#888888", lw=1, label="Load demand")
    axs[0].plot(t, d.K_measured_pu, color="black", lw=1.3, label="Load factor measured in the model")
    axs[0].set_ylabel("Load factor K (pu)")
    axs[0].set_ylim(0, 1.45)
    axs[0].legend(frameon=False, loc="lower right", ncol=2)
    axs[0].set_title(title, loc="left")
    axs[1].plot(t, d.ambient_C, ":", color="#888888", label="Ambient")
    axs[1].plot(t, d.top_oil_C, color="#0D366B", lw=1.3, label="Top-oil")
    axs[1].plot(t, d.hot_spot_C, color="#E34948", lw=1.3, label="Hot-spot")
    i = d.hot_spot_C.idxmax()
    axs[1].annotate(f"peak {d.hot_spot_C[i]:.1f} °C", (t[i], d.hot_spot_C[i]), (t[i] - 4 if t[i] > 16 else t[i] + 2.5, d.hot_spot_C[i] + 22),
                    fontsize=8, arrowprops=dict(arrowstyle="->", lw=0.7))
    axs[1].set_ylabel("Temperature (°C)")
    axs[1].set_ylim(0, max(175, d.hot_spot_C.max() + 45))
    axs[1].legend(frameon=False, loc="upper left", ncol=3)
    axs[2].plot(t, d.ageing_rate_V, color="#E34948", lw=1.3)
    axs[2].set_yscale("log")
    axs[2].set_ylabel("Relative ageing rate V\n(log scale)")
    axs[2].text(0.98, 0.08, f"Loss of life over the day L = {L} h", transform=axs[2].transAxes, fontsize=8, ha="right")
    axs[2].set_xlabel("Time of day (h)" if "daily" in outname else "Time (h)")
    axs[2].set_xlim(0, 24)
    axs[2].set_xticks(range(0, 25, 4))
    fig.tight_layout()
    save(fig, outname)


def testbench():
    d = pd.read_csv(FIG / "F4_20_testbench_run.csv")
    sim = pd.read_csv(FIG / "F4_19a_scenario_rated.csv")
    fig, axs = plt.subplots(3, 1, figsize=(W, 5.6), sharex=True, gridspec_kw=dict(height_ratios=[1.2, 1.4, 1]))
    axs[0].plot(d.sim_time_h, d.hot_spot_C, color="#E34948", lw=1.2, label="Hot-spot temperature at each event")
    axs[0].scatter(d.sim_time_h, np.full(len(d), 5), marker="|", s=14, color="black", alpha=0.35, lw=0.6, label="DGA sampling event (every 15 min)")
    axs[0].set_ylabel("Temperature (°C)")
    axs[0].set_ylim(0, 120)
    axs[0].legend(frameon=False, loc="lower right", fontsize=7.5)
    axs[0].set_title("(a) Simulated transformer and the 388 sampling events", loc="left")
    classes = ["Normal", "PD", "D1", "D2", "T1", "T2", "T3"]
    for k, c in enumerate(classes):
        g = d[d.ml_class == c]
        axs[1].scatter(g.sim_time_h, [k] * len(g), marker=CMK[c], color=CCOL[c], s=10)
    axs[1].set_yticks(range(7), classes)
    axs[1].invert_yaxis()
    axs[1].set_ylabel("ML diagnosis")
    axs[1].set_title("(b) Fault class given by the ML model for the record taken at each event", loc="left")
    axs[2].scatter(d.sim_time_h, d.conventional_agreeing, s=6, color="#2A78D6")
    axs[2].set_yticks(range(4))
    axs[2].set_ylabel("Methods agreeing\nwith ML (of 3)")
    axs[2].set_xlabel("Simulated time (h)")
    axs[2].set_title("(c) Number of conventional methods that agree with the ML diagnosis", loc="left")
    fig.tight_layout()
    save(fig, "testbench_run")


def response_times():
    d = pd.read_csv(FIG / "F4_21_response_times.csv")
    med, p95 = np.median(d.response_ms), np.percentile(d.response_ms, 95)
    fig, axs = plt.subplots(1, 2, figsize=(W, 2.8), gridspec_kw=dict(width_ratios=[1.5, 1]))
    w = d.warmup == 1
    axs[0].scatter(d.event[~w], d.response_ms[~w], s=5, color="#2A78D6", label="request")
    axs[0].scatter(d.event[w], d.response_ms[w], s=18, facecolor="none", edgecolor="black", label="first 5 (warm-up)")
    axs[0].axhline(med, color="black", ls="--", lw=0.9, label=f"median {med:.1f} ms")
    axs[0].axhline(p95, color="#888888", ls=":", lw=1.1, label=f"95th percentile {p95:.1f} ms")
    axs[0].set_xlabel("Request number in the test-bench run")
    axs[0].set_ylabel("Response time (ms)")
    axs[0].set_ylim(0, 200)
    axs[0].legend(frameon=False, fontsize=7, ncol=2, loc="upper left")
    axs[0].set_title("(a) Every request in run order", loc="left")
    s = np.sort(d.response_ms.to_numpy())
    axs[1].step(s, 100 * np.arange(1, len(s) + 1) / len(s), color="#2A78D6", where="post", label="all 388 requests")
    axs[1].axvline(1000, color="#E34948", lw=1.2, label="target 1 000 ms")
    axs[1].axvline(p95, color="#888888", ls=":", lw=1.1, label="95th percentile")
    axs[1].set_xscale("log")
    axs[1].set_xlim(10, 2000)
    axs[1].set_xlabel("Response time (ms, log scale)")
    axs[1].set_ylabel("Requests answered within\nthe time (%)")
    axs[1].legend(frameon=False, fontsize=7, loc="lower right")
    axs[1].set_title("(b) Cumulative distribution", loc="left")
    fig.tight_layout()
    save(fig, "response_times")


# ------------------------------------------------------------------ exploratory study
SRC = {"DISTRAIN": "Dissanayake training\n(n = 439)", "DISTEST": "Dissanayake unseen\n(n = 61)",
       "IECTC10": "IEC TC 10 power\ntransformers (n = 58)", "LI2019": "Li (2019)\n(n = 85)"}
S2M = {"A": "A: released model", "B": "B: retrained on\npooled sources", "C": "C: hybrid model", "IEC60599": "IEC 60599 ratio",
       "Rogers": "Rogers ratio", "Duval": "Duval Triangle 1"}
S2C = {"A": "#888888", "B": "#7FB0EA", "C": "#2A78D6", "IEC60599": MCOL["IEC60599"], "Rogers": MCOL["Rogers"], "Duval": MCOL["Duval"]}


def study2_f1():
    d = pd.read_csv(FIG / "F4_23_study2_macro_f1.csv")
    d = d[d.variant == "primary"]
    order = ["A", "B", "C", "IEC60599", "Rogers", "Duval"]
    fig, axs = plt.subplots(1, 4, figsize=(W, 2.9), sharey=True)
    for ax, (s, lab) in zip(axs, SRC.items()):
        g = d[d.held_out == s]
        for i, m in enumerate(order):
            r = g[g.model == m]
            if len(r) == 0:
                continue
            r = r.iloc[0]
            ax.errorbar(r.macro_f1, i, xerr=[[r.macro_f1 - r.macro_f1_lo], [r.macro_f1_hi - r.macro_f1]], fmt="o", color=S2C[m],
                        ms=4, capsize=2)
        ax.set_xlim(0, 1)
        ax.set_title(lab, fontsize=8)
        ax.set_xlabel("Macro-F1 (95 % CI)")
    axs[0].set_yticks(range(6), [S2M[m] for m in order], fontsize=7.5)
    axs[0].invert_yaxis()
    axs[0].set_ylabel("Model or method")
    fig.tight_layout()
    save(fig, "study2_f1")


def study2_coverage():
    d = pd.read_csv(FIG / "F4_24_study2_accuracy_coverage.csv")
    d = d[d.variant == "primary"]
    pts = pd.read_csv(FIG / "F4_23_study2_macro_f1.csv")
    pts = pts[pts.variant == "primary"]
    fig, axs = plt.subplots(1, 4, figsize=(W, 2.8), sharey=True)
    for ax, (s, lab) in zip(axs, SRC.items()):
        for m in ["A", "B", "C"]:
            g = d[(d.held_out == s) & (d.model == m)].sort_values("coverage")
            if len(g):
                ax.plot(g.coverage, g.selective_accuracy, color=S2C[m], lw=1.6 if m == "C" else 1, label=S2M[m].replace("\n", " "))
        for m in ["IEC60599", "Rogers", "Duval"]:
            r = pts[(pts.held_out == s) & (pts.model == m)].iloc[0]
            ax.scatter(r.coverage, r.conditional_accuracy, marker=MMK[m], color=MCOL[m], s=28, zorder=5, label=S2M[m])
        ax.set_xlim(0, 1.03)
        ax.set_ylim(0, 1.03)
        ax.set_title(lab, fontsize=8)
        ax.set_xlabel("Coverage")
    axs[0].set_ylabel("Accuracy on the\nanswered records")
    h, l = axs[2].get_legend_handles_labels()
    fig.legend(h, l, loc="lower center", ncol=3, frameon=False, bbox_to_anchor=(0.5, -0.12))
    fig.tight_layout()
    save(fig, "study2_coverage")


# ------------------------------------------------------------------ data flow diagram
def data_flow():
    f = pd.read_csv(FIG / "F3_2_data_preparation_flow.csv")
    v = {f"{r.stage}:{r.item}": int(r.records) for r in f.itertuples()}
    fig, ax = plt.subplots(figsize=(W, 4.6))
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 100)
    ax.axis("off")

    def bx(x, y, w, h, txt, fc="#FFFFFF", ec="#777777", bold=False):
        ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0,rounding_size=1.2", fc=fc, ec=ec, lw=0.9))
        ax.text(x + w / 2, y + h / 2, txt, ha="center", va="center", fontsize=7.1, fontweight="bold" if bold else "normal",
                linespacing=1.3)

    def ar(x1, y1, x2, y2):
        ax.add_patch(FancyArrowPatch((x1, y1), (x2, y2), arrowstyle="-|>", mutation_scale=8, color="#555555", lw=0.8))
    src = [("IEC TC 10\ndatabase", v["raw:IECTC10"]), ("Dissanayake\ntraining file", v["raw:DISTRAIN"]),
           ("Dissanayake\nunseen test file", v["raw:DISTEST"]), ("Dissanayake\nIEC subset file", v["raw:DISIEC"]),
           ("Li (2019)\ndata set", v["raw:LI2019"])]
    for k, (t, n) in enumerate(src):
        bx(1 + k * 19.8, 84, 18.2, 14, f"{t}\nn = {n}")
        ar(10 + k * 19.8, 84, 10 + k * 19.8, 77.5)
    bx(1, 63, 97, 14, "Standardise: one table, five gases in ppm, fault classes coded 0–6\n(T1/T2 kept merged where the source merges them). "
       "Values not available treated as not detected (0 ppm), with flags.\n"
       "Power transformers flagged (IEC TC 10 equipment codes P and U)")
    ar(50, 63, 50, 56.5)
    bx(1, 41, 97, 15, f"Remove from the training file: {v['step9_removed:leakage']} records that copy a test or benchmark case, "
       f"{v['step9_removed:exact copy']} exact copies,\n{v['step9_removed:label conflict']} records with identical gases but conflicting labels. "
       "The 49-record IEC subset file is replaced by\nthe full IEC TC 10 transcription. Test records that copy a benchmark case are flagged.\n"
       f"Master table: {v['master:all']} records", bold=False)
    roles = [("Development set", f"n = {v['role:development']}"), ("Internal test set", f"n = {v['role:internal_test']}\n({v['role:internal_test independent']} independent)"),
             ("IEC TC 10 benchmark", f"n = {v['role:benchmark']}\n({v['role:benchmark power transformers']} power\ntransformers)"),
             ("External test set\n(Li 2019)", f"n = {v['role:external_test']}\n({v['role:external_test independent']} independent)")]
    for k, (t, n) in enumerate(roles):
        ar(13 + k * 24.6, 41, 13 + k * 24.6, 34.5)
        bx(1 + k * 24.6, 20, 23, 14.5, f"{t}\n{n}", fc="#DCE9F7", ec="#2A78D6")
    ar(13, 20, 13, 14.5)
    bx(1, 1, 30, 13.5, "Cross-validation folds:\n5 folds × 10 repeats, stratified,\nnear-duplicates kept together")
    ax.text(36, 7.5, "All files frozen as data version 1.0\n(SHA-256 fingerprint of every file)", fontsize=7.6, color="#555555",
            va="center")
    save(fig, "data_flow")


def main():
    print("thesis figures:")
    records_per_class(); gas_boxplots(); gas_correlation()
    duval_plot("duval_benchmark.csv", "IEC TC 10 benchmark (117 inspected cases)", "duval_benchmark")
    duval_plot("duval_development.csv", "Development set", "duval_development")
    duval_plot("duval_internal_test.csv", "Internal test set", "duval_internal")
    duval_plot("duval_external_test.csv", "Li (2019) set", "duval_external")
    duval_disagreements()
    confusion("F4_5a_confusion_conventional_internal.csv", "conf_conv_internal", None)
    confusion("F4_5b_confusion_conventional_iec_tc10.csv", "conf_conv_iec", None)
    confusion("F4_5c_confusion_conventional_li2019.csv", "conf_conv_li", None)
    confusion("F4_8_confusion_ml.csv", "conf_ml", None, label_by_set=True)
    cv_boxplots(); cd_diagram()
    main_comparison("F4_9a_main_comparison_internal.csv", "main_internal")
    main_comparison("F4_9b_main_comparison_iec_tc10.csv", "main_iec")
    main_comparison("F4_9c_main_comparison_li2019.csv", "main_li")
    f1_per_class(); kappa(); boundary(); permutation(); reduced_gas(); subset_matrix()
    simulink_verification()
    sc = pd.read_csv(ROOT / "05_Simulink_Model" / "results" / "step36_scenario_summary.csv").set_index("scenario")
    scenario("F4_19a_scenario_rated.csv", "Constant rated load", "scenario_rated", f"{sc.loc['rated', 'loss_of_life_h']:.2f}")
    scenario("F4_19b_scenario_daily.csv", "Daily load cycle (last of three simulated days)", "scenario_daily", f"{sc.loc['daily', 'loss_of_life_h']:.2f}")
    scenario("F4_19c_scenario_overload.csv", "Short overload: 1.3 pu for 2 h on a base load of 0.8 pu", "scenario_overload", f"{sc.loc['overload', 'loss_of_life_h']:.2f}")
    testbench(); response_times(); study2_f1(); study2_coverage(); data_flow()


if __name__ == "__main__":
    main()
