"""Roadmap Step 32 [Claude Code] - the Chapter 4 figures not made by earlier steps (Analysis Plan Section 12).

Figure 4.6  cross-validation macro-F1 of the classifiers (box plots with the 50 fold values; feature set F4, as in D26)
Figure 4.9  ML versus conventional methods: strict accuracy, conditional accuracy, macro-F1 with 95 % CI (one figure per test set)
Figure 4.10 F1-score per fault class with 95 % bootstrap CI, one bar per method (three test-set panels)
Figure 4.13 disagreements between the ML model and Duval in the Duval Triangle (primary test records)
Input : saved result files only (fold_metrics.csv of Step 20; performance_measures.csv, merged_predictions.csv of Steps 28-29;
        02_Standards/duval_triangle_zones.csv). Output: 11_Results/figures (PNG, PDF, CSV); 08_Statistical_Analysis/per_class_ci.csv
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
for sub in ("stats", "data_prep", "conventional", "ml"):
    sys.path.insert(0, str(HERE.parent / sub))
sys.path.insert(0, str(HERE))

import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402

import plotstyle as ps  # noqa: E402
from common import PROJECT_ROOT  # noqa: E402
from conventional_methods import load_duval, rule_polygons  # noqa: E402
from step29_measures import METHODS, SETS, answers, class_counts, effective  # noqa: E402

SA = PROJECT_ROOT / "08_Statistical_Analysis"
B, SEED = 2000, 20261010
MODEL_LABEL = {"majority": "Majority\nbaseline", "logistic_regression": "Logistic\nregression", "svm": "SVM\n(RBF)",
               "random_forest": "Random\nForest", "xgboost": "XGBoost", "mlp": "Neural\nnetwork"}
MCOL = {"ML": ps.METHOD.loc["ML", "colour_hex"], "Rogers": ps.METHOD.loc["Rogers", "colour_hex"],
        "IEC60599": ps.METHOD.loc["IEC60599", "colour_hex"], "Duval": ps.METHOD.loc["Duval", "colour_hex"]}
MLAB = {m: lab for m, lab in METHODS}
PRIMARY = [s for s in SETS if s[5]]


def fig_4_6(plt) -> None:
    fm = pd.read_csv(PROJECT_ROOT / "07_Experiments" / "2026-10-11_nestedcv_v1" / "fold_metrics.csv", float_precision="round_trip")
    fm = fm[fm.feature_set == "F4"]
    models = list(MODEL_LABEL)
    fig, ax = plt.subplots(figsize=(ps.FULL_WIDTH, 8 * ps.CM))
    data = [fm[fm.model == m].macro_f1.to_numpy() for m in models]
    bp = ax.boxplot(data, widths=0.5, patch_artist=True, showfliers=False, medianprops={"color": ps.INK["text"], "lw": 1})
    for patch, m in zip(bp["boxes"], models):
        patch.set_facecolor(ps.INK["muted"] if m == "majority" else ps.METHOD.loc["ML", "colour_hex"])
        patch.set_alpha(0.35)
    jit = np.random.default_rng(SEED)
    for i, d in enumerate(data, start=1):
        ax.scatter(i + jit.uniform(-0.12, 0.12, len(d)), d, s=6, color=ps.INK["text"], zorder=3, linewidths=0)
    ax.set_xticks(range(1, len(models) + 1))
    ax.set_xticklabels([MODEL_LABEL[m] for m in models])
    ax.set_ylim(0, 1)
    ax.set_ylabel("Macro-F1 per outer fold [-]")
    ax.set_xlabel("Model (feature set F4; 50 outer folds)")
    fig.tight_layout()
    ps.save(fig, "F4_6_cv_boxplots", fm[["model", "rep", "fold", "macro_f1"]].sort_values(["model", "rep", "fold"]).round(6))


def fig_4_9(plt) -> None:
    perf = pd.read_csv(SA / "performance_measures.csv")
    perf = perf[perf.primary_set & (perf.variant == "primary")]
    order = [m for m, _ in METHODS]
    for k, (sname, *_r) in enumerate(PRIMARY):
        d = perf[perf.evaluation_set == sname].set_index("method").loc[order]
        fig, axes = plt.subplots(1, 3, figsize=(ps.FULL_WIDTH, 6 * ps.CM), sharey=True)
        for ax, (col, title) in zip(axes, (("strict_accuracy", "Strict accuracy"), ("conditional_accuracy", "Conditional accuracy"),
                                           ("macro_f1", "Macro-F1"))):
            for j, m in enumerate(order):
                r = d.loc[m]
                ax.errorbar(r[col], j, xerr=[[r[col] - r[f"{col}_lo"]], [r[f"{col}_hi"] - r[col]]], fmt="o", ms=4, color=MCOL[m],
                            elinewidth=1.2, capsize=2)
            ax.set_xlim(0, 1)
            ax.set_title(title, loc="left", fontsize=8)
            ax.set_xlabel("Value [-]", fontsize=7)
        axes[0].set_yticks(range(len(order)))
        axes[0].set_yticklabels([f"{MLAB[m]}\n(coverage {d.loc[m, 'coverage']:.2f})" for m in order], fontsize=7)
        axes[0].set_ylim(len(order) - 0.5, -0.5)
        fig.suptitle(f"{sname} (n = {int(d.n.iloc[0])}); 95 % CI", x=0.01, ha="left", fontsize=8)
        fig.tight_layout()
        ps.save(fig, f"F4_9{'abc'[k]}_main_comparison_{['internal', 'iec_tc10', 'li2019'][k]}",
                d.reset_index()[["evaluation_set", "method", "n", "strict_accuracy", "strict_accuracy_lo", "strict_accuracy_hi",
                                 "conditional_accuracy", "conditional_accuracy_lo", "conditional_accuracy_hi", "macro_f1",
                                 "macro_f1_lo", "macro_f1_hi", "coverage"]].round(6))


def per_class_ci(mg: pd.DataFrame) -> pd.DataFrame:
    rng = np.random.default_rng(SEED)
    rows = []
    for sname, role, filt, merged, labels, _p in PRIMARY:
        df = mg[(mg.data_role == role) & mg[filt]].reset_index(drop=True)
        truth = (df.class_merged if merged else df.class_name).to_numpy(object)
        strata = [np.flatnonzero(truth == c) for c in labels if np.any(truth == c)]
        boots = [np.concatenate([rng.choice(s, len(s), replace=True) for s in strata]) for _ in range(B)]
        for m, _lab in METHODS:
            eff = effective(truth, answers(df, m, merged, "primary"), True)

            def f1(idx):
                tp, fp, fn = class_counts(truth[idx], eff[idx], labels)
                d = 2 * tp + fp + fn
                return np.divide(2 * tp, d, out=np.zeros_like(tp), where=d > 0)
            point = f1(np.arange(len(truth)))
            bs = np.array([f1(i) for i in boots])
            for j, c in enumerate(labels):
                rows.append({"evaluation_set": sname, "method": m, "class": c, "support": int(np.sum(truth == c)),
                             "f1": point[j], "f1_lo": np.percentile(bs[:, j], 2.5), "f1_hi": np.percentile(bs[:, j], 97.5)})
    return pd.DataFrame(rows)


def fig_4_10(plt, mg: pd.DataFrame) -> None:
    pc = per_class_ci(mg)
    pc.round(6).to_csv(SA / "per_class_ci.csv", index=False)
    order = [m for m, _ in METHODS]
    fig, axes = plt.subplots(3, 1, figsize=(ps.FULL_WIDTH, 17 * ps.CM))
    for ax, (sname, *_r) in zip(axes, PRIMARY):
        d = pc[pc.evaluation_set == sname]
        classes = list(dict.fromkeys(d["class"]))
        w = 0.8 / len(order)
        for j, m in enumerate(order):
            q = d[d.method == m].set_index("class").loc[classes]
            x = np.arange(len(classes)) - 0.4 + w / 2 + j * w
            ax.bar(x, q.f1, width=w, color=MCOL[m], label=MLAB[m])
            ax.errorbar(x, q.f1, yerr=[q.f1 - q.f1_lo, q.f1_hi - q.f1], fmt="none", ecolor=ps.INK["text"], elinewidth=0.6, capsize=1.5)
        ax.set_xticks(range(len(classes)))
        ax.set_xticklabels([f"{c.replace('T12', 'T1/T2')}\n(n = {int(d[d['class'] == c].support.iloc[0])})" for c in classes], fontsize=7)
        ax.set_ylim(0, 1.05)
        ax.set_ylabel("F1-score [-]")
        ax.set_title(sname, loc="left", fontsize=8)
    h, l_ = axes[0].get_legend_handles_labels()
    fig.legend(h, l_, loc="upper center", ncol=4, frameon=False, fontsize=7)
    fig.tight_layout(rect=(0, 0, 1, 0.965))
    ps.save(fig, "F4_10_f1_per_class", pc.round(6))


def fig_4_13(plt, mg: pd.DataFrame) -> None:
    rows = []
    for sname, role, filt, merged, labels, _p in PRIMARY:
        df = mg[(mg.data_role == role) & mg[filt]].reset_index(drop=True)
        truth = (df.class_merged if merged else df.class_name).to_numpy(object)
        ml = answers(df, "ML", merged, "primary")
        du = answers(df, "Duval", merged, "primary")
        for i in range(len(df)):
            rows.append({"record_id": df.record_id[i], "evaluation_set": sname, "true_class": truth[i], "ml": ml[i], "duval": du[i],
                         "pct_CH4": df.duval_pct_CH4[i], "pct_C2H4": df.duval_pct_C2H4[i], "pct_C2H2": df.duval_pct_C2H2[i]})
    d = pd.DataFrame(rows)
    d["disagree"] = d.ml != d.duval
    d = d[d[["pct_CH4", "pct_C2H4", "pct_C2H2"]].notna().all(axis=1)].copy()
    d["x"] = d.pct_C2H4 + d.pct_CH4 / 2.0                      # side-100 triangle: C2H2 (0,0), C2H4 (100,0), CH4 (50, 86.6)
    d["y"] = d.pct_CH4 * math.sqrt(3.0) / 2.0
    fig, ax = plt.subplots(figsize=(ps.FULL_WIDTH, 13 * ps.CM))
    for zone, poly in rule_polygons(load_duval()):
        xs, ys = zip(*(poly + [poly[0]]))
        ax.plot(xs, ys, color=ps.INK["grid"], lw=0.8, zorder=1)
        cx, cy = np.mean(xs[:-1]), np.mean(ys[:-1])
        ax.text(cx, cy, zone, fontsize=6, color=ps.INK["muted"], ha="center", va="center", zorder=1)
    ax.plot([0, 100, 50, 0], [0, 0, 50 * math.sqrt(3), 0], color=ps.INK["muted"], lw=1, zorder=2)
    a = d[~d.disagree]
    ax.scatter(a.x, a.y, s=6, color=ps.INK["muted"], zorder=3, label=f"ML and Duval agree (n = {len(a)})", linewidths=0)
    for c in ps.CLASS_ORDER:
        q = d[d.disagree & (d.true_class == c)]
        if len(q):
            ax.scatter(q.x, q.y, s=22, color=ps.CLASS.loc[c, "colour_hex"], marker=ps.CLASS.loc[c, "marker_matplotlib"],
                       edgecolors=ps.INK["text"], linewidths=0.3, zorder=4, label=f"disagree, true {c.replace('T12', 'T1/T2')} (n = {len(q)})")
    ax.text(-3, -4, "100 % C2H2", fontsize=7, ha="right")
    ax.text(103, -4, "100 % C2H4", fontsize=7, ha="left")
    ax.text(50, 50 * math.sqrt(3) + 3, "100 % CH4", fontsize=7, ha="center")
    ax.set_aspect("equal")
    ax.axis("off")
    ax.legend(loc="upper left", frameon=False, fontsize=7)
    fig.tight_layout()
    ps.save(fig, "F4_13_duval_disagreements", d.drop(columns=["x", "y"]).round(6))


def main() -> int:
    ps.apply()
    import matplotlib.pyplot as plt
    mg = pd.read_csv(SA / "merged_predictions.csv", keep_default_na=False, na_values=["NaN", ""])
    fig_4_6(plt)
    fig_4_9(plt)
    fig_4_10(plt, mg)
    fig_4_13(plt, mg)
    print("Figures 4.6, 4.9a-c, 4.10, 4.13 written")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
