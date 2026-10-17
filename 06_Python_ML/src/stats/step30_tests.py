"""Roadmap Step 30 [Claude Code] - significance tests.

Input : 07_Experiments/2026-10-11_nestedcv_v1/fold_metrics.csv (Step 20); 08_Statistical_Analysis/merged_predictions.csv (Step 28).
Do    : (decision D26)
        (1) Friedman (Eq. 26) and Nemenyi critical difference (Eq. 27) for the six models on F4 over the 50 outer folds
            (supplementary: 24 model-feature combinations); Figure 4.7 (critical-difference diagram);
        (2) per primary test set: Cochran's Q (Eq. 29) over ML, Rogers, IEC 60599, Duval; McNemar ML vs each (Eqs. 30-31)
            with Holm (Eq. 32); odds ratio b/c with 95 % CI; sensitivity with no-gate answers -> Table 4.6;
        (3) Cohen's kappa between all pairs of methods and the true label -> Table 4.7, Figure 4.11;
        (4) hypothesis criteria 1 and 2 (criterion 3: Step 31).
Output: 08_Statistical_Analysis/ (friedman.csv, nemenyi_pairs.csv, cochran_mcnemar.csv, kappa_matrix.csv, hypothesis_criteria.json),
        11_Results/tables/T4_6_mcnemar.csv, T4_7_kappa.csv; Figures F4_7, F4_11; 03_Data/interim/step30_report.md
"""
from __future__ import annotations

import hashlib
import json
import sys
from itertools import combinations
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "data_prep"))
sys.path.insert(0, str(HERE.parent / "analysis"))

import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402
from scipy import stats  # noqa: E402

import plotstyle as ps  # noqa: E402
from common import INTERIM, PROJECT_ROOT, md_table, verify_data_version  # noqa: E402
from step29_measures import METHODS, SETS, answers, effective, kappa_mcc  # noqa: E402

SA = PROJECT_ROOT / "08_Statistical_Analysis"
ALPHA = 0.05
MODEL_LABEL = {"majority": "Majority baseline", "logistic_regression": "Logistic regression", "svm": "SVM (RBF)",
               "random_forest": "Random Forest", "xgboost": "XGBoost", "mlp": "Neural network (MLP)"}


def friedman(scores: np.ndarray) -> dict:
    """scores: n_folds x k (higher = better). Eq. 26 with average ranks (1 = best); ties get average ranks."""
    n, k = scores.shape
    ranks = np.vstack([stats.rankdata(-row) for row in scores])
    R = ranks.mean(axis=0)
    chi2 = 12 * n / (k * (k + 1)) * (np.sum(R ** 2) - k * (k + 1) ** 2 / 4)
    p = float(stats.chi2.sf(chi2, k - 1))
    q = float(stats.studentized_range.ppf(1 - ALPHA, k, np.inf) / np.sqrt(2))
    cd = q * np.sqrt(k * (k + 1) / (6 * n))
    return {"n_folds": n, "k": k, "avg_ranks": R, "chi2": float(chi2), "df": k - 1, "p": p, "q_alpha": q, "cd": float(cd)}


def mcnemar(b: int, c: int) -> dict:
    if b + c == 0:
        return {"test": "none (no discordant records)", "statistic": np.nan, "p": 1.0}
    if b + c < 25:
        p = min(1.0, 2 * stats.binom.cdf(min(b, c), b + c, 0.5))
        return {"test": "exact binomial (Eq. 31)", "statistic": np.nan, "p": float(p)}
    chi2 = (abs(b - c) - 1) ** 2 / (b + c)
    return {"test": "chi-square, continuity corrected (Eq. 30)", "statistic": float(chi2), "p": float(stats.chi2.sf(chi2, 1))}


def holm(pvals: list[float]) -> list[float]:
    """Holm-adjusted p-values (step-down, monotone, capped at 1); reject where adjusted p <= alpha (equivalent to Eq. 32)."""
    m = len(pvals)
    order = np.argsort(pvals)
    adj = np.empty(m)
    run = 0.0
    for i, j in enumerate(order):
        run = max(run, (m - i) * pvals[j])
        adj[j] = min(1.0, run)
    return list(adj)


def cochran_q(correct: np.ndarray) -> dict:
    """correct: N x m matrix of 0/1. Eq. 29."""
    N, m = correct.shape
    C = correct.sum(axis=0)
    a = correct.sum(axis=1)
    T = C.sum()
    den = m * T - np.sum(a ** 2)
    Q = (m - 1) * (m * np.sum(C ** 2) - T ** 2) / den if den > 0 else 0.0
    return {"Q": float(Q), "df": m - 1, "p": float(stats.chi2.sf(Q, m - 1))}


def odds_ratio(b: int, c: int) -> tuple[float, float, float, bool]:
    corr = b == 0 or c == 0
    bb, cc = (b + 0.5, c + 0.5) if corr else (b, c)
    lor, se = np.log(bb / cc), np.sqrt(1 / bb + 1 / cc)
    return float(np.exp(lor)), float(np.exp(lor - 1.96 * se)), float(np.exp(lor + 1.96 * se)), corr


def main() -> int:
    problems = verify_data_version()
    if problems:
        raise SystemExit("data version 1.0 changed: " + "; ".join(problems))
    # (1) Friedman / Nemenyi on the cross-validation folds
    fm = pd.read_csv(PROJECT_ROOT / "07_Experiments" / "2026-10-11_nestedcv_v1" / "fold_metrics.csv", float_precision="round_trip")
    w = fm[fm.feature_set == "F4"].pivot_table(index=["rep", "fold"], columns="model", values="macro_f1")
    models = list(MODEL_LABEL)
    fr = friedman(w[models].to_numpy())
    w24 = fm.assign(combo=fm.feature_set + "/" + fm.model).pivot_table(index=["rep", "fold"], columns="combo", values="macro_f1")
    fr24 = friedman(w24.to_numpy())
    fr_rows = [{"analysis": "6 models on F4 (primary)", "k": fr["k"], "n_folds": fr["n_folds"], "chi2": fr["chi2"], "df": fr["df"],
                "p": fr["p"], "q_alpha": fr["q_alpha"], "critical_difference": fr["cd"]},
               {"analysis": "24 model-feature combinations (supplementary)", "k": fr24["k"], "n_folds": fr24["n_folds"],
                "chi2": fr24["chi2"], "df": fr24["df"], "p": fr24["p"], "q_alpha": fr24["q_alpha"], "critical_difference": fr24["cd"]}]
    pd.DataFrame(fr_rows).to_csv(SA / "friedman.csv", index=False)
    ranks = pd.Series(fr["avg_ranks"], index=models)
    pairs = [{"model_a": a, "model_b": b, "rank_a": ranks[a], "rank_b": ranks[b], "rank_difference": abs(ranks[a] - ranks[b]),
              "significant": bool(abs(ranks[a] - ranks[b]) > fr["cd"])} for a, b in combinations(models, 2)]
    pd.DataFrame(pairs).round(4).to_csv(SA / "nemenyi_pairs.csv", index=False)
    pd.DataFrame({"model": models, "label": [MODEL_LABEL[m] for m in models], "average_rank_F4": ranks.values,
                  "mean_macro_f1_F4": w[models].mean().values}).round(4).to_csv(SA / "friedman_ranks_F4.csv", index=False)

    # (2) Cochran's Q and McNemar on the test sets; (3) kappa
    mp = SA / "merged_predictions.csv"
    ck = json.loads((SA / "merge_checks.json").read_text(encoding="utf-8"))
    assert hashlib.sha256(mp.read_bytes()).hexdigest().upper() == ck["merged_sha256"], "merged file changed since Step 28"
    mg = pd.read_csv(mp, keep_default_na=False, na_values=["NaN", ""])
    mc_rows, kap_rows, cq_rows = [], [], []
    for sname, role, filt, merged, labels, primary in SETS:
        if not primary:
            continue
        df = mg[(mg.data_role == role) & mg[filt]].reset_index(drop=True)
        truth = (df.class_merged if merged else df.class_name).to_numpy(object)
        for variant in ("primary", "no_gate"):
            eff = {m: effective(truth, answers(df, m, merged, variant), True) for m, _ in METHODS}
            corr = {m: (eff[m] == truth).astype(int) for m in eff}
            cq = cochran_q(np.column_stack([corr[m] for m, _ in METHODS]))
            cq_rows.append({"evaluation_set": sname, "variant": variant, "n": len(df), **cq,
                            **{f"correct_{m}": int(corr[m].sum()) for m, _ in METHODS}})
            rows = []
            for m, lab in METHODS[1:]:
                b = int(np.sum((corr["ML"] == 1) & (corr[m] == 0)))
                c = int(np.sum((corr["ML"] == 0) & (corr[m] == 1)))
                orr, lo, hi, hal = odds_ratio(b, c)
                rows.append({"evaluation_set": sname, "variant": variant, "comparison": f"ML vs {lab}", "method": m, "n": len(df),
                             "b": b, "c": c, **mcnemar(b, c), "odds_ratio": orr, "or_lo": lo, "or_hi": hi, "haldane": hal})
            adj = holm([r["p"] for r in rows])
            for r, pa in zip(rows, adj):
                r["p_holm"] = pa
                r["significant_holm"] = bool(pa <= ALPHA)
                r["ml_better"] = r["b"] > r["c"]
            mc_rows += rows
            if variant == "primary":
                cats = {"True label": truth, **{lab: eff[m] for m, lab in METHODS}}
                for a_name, b_name in combinations(cats, 2):
                    k, _ = kappa_mcc(cats[a_name], cats[b_name])
                    kap_rows.append({"evaluation_set": sname, "a": a_name, "b": b_name, "kappa": k})
    mc = pd.DataFrame(mc_rows)
    mc.round(6).to_csv(SA / "cochran_mcnemar.csv", index=False)
    cqd = pd.DataFrame(cq_rows)
    cqd.round(6).to_csv(SA / "cochran_q.csv", index=False)
    kap = pd.DataFrame(kap_rows)
    kap.round(4).to_csv(SA / "kappa_matrix.csv", index=False)
    tables = PROJECT_ROOT / "11_Results" / "tables"
    mc[mc.variant == "primary"][["evaluation_set", "comparison", "n", "b", "c", "test", "statistic", "p", "p_holm", "odds_ratio",
                                  "or_lo", "or_hi", "haldane", "significant_holm"]].round(4).to_csv(tables / "T4_6_mcnemar.csv", index=False)
    kap.round(3).to_csv(tables / "T4_7_kappa.csv", index=False)

    # (4) hypothesis criteria 1 and 2 (D26: judged on IEC TC 10 power transformers; others supporting)
    perf = pd.read_csv(SA / "performance_measures.csv")
    crit = {}
    for sname, *_r, primary in SETS:
        if not primary:
            continue
        m = mc[(mc.evaluation_set == sname) & (mc.variant == "primary")]
        p = perf[(perf.evaluation_set == sname) & (perf.variant == "primary")].set_index("method")
        c1 = {r.method: bool(r.ml_better and r.significant_holm) for r in m.itertuples()}
        c2 = {k_: bool((p.loc["ML", "conditional_accuracy"] - p.loc[k_, "conditional_accuracy"])
                       < (p.loc["ML", "strict_accuracy"] - p.loc[k_, "strict_accuracy"])) for k_ in ("Rogers", "IEC60599", "Duval")}
        crit[sname] = {"criterion1_ML_higher_and_significant": c1, "criterion1_met": all(c1.values()),
                       "criterion2_conditional_gap_smaller": c2, "criterion2_met": all(c2.values()),
                       "criterion3": "decided in Step 31"}
    crit["decisive_set"] = "IEC TC 10 (power transformers)"
    (SA / "hypothesis_criteria.json").write_text(json.dumps(crit, indent=1), encoding="utf-8")

    # Figures 4.7 (critical-difference diagram) and 4.11 (kappa heatmaps)
    ps.apply()
    import matplotlib.pyplot as plt
    order = ranks.sort_values()
    fig, ax = plt.subplots(figsize=(ps.FULL_WIDTH, 4.6 * ps.CM))
    k = len(order)
    ax.set_xlim(1, k)
    ax.set_ylim(0.25, 1.02)
    ax.hlines(0.75, 1, k, color=ps.INK["text"], lw=0.8)
    for x in range(1, k + 1):
        ax.vlines(x, 0.73, 0.77, color=ps.INK["text"], lw=0.8)
        ax.text(x, 0.82, str(x), ha="center", fontsize=8)
    ax.hlines(0.95, 1, 1 + fr["cd"], color=ps.INK["text"], lw=1.5)
    ax.text(1 + fr["cd"] / 2, 0.97, f"CD = {fr['cd']:.2f}", ha="center", va="bottom", fontsize=8)
    for i, (mname, r) in enumerate(order.items()):
        left = i < (k + 1) // 2
        y = 0.6 - 0.12 * (i if left else k - 1 - i)
        ax.vlines(r, y, 0.75, color=ps.INK["muted"], lw=0.7)
        ax.hlines(y, r, 1 if left else k, color=ps.INK["muted"], lw=0.7)
        ax.text(1 - 0.05 if left else k + 0.05, y, f"{MODEL_LABEL[mname]} ({r:.2f})", ha="right" if left else "left",
                va="center", fontsize=8)
    groups, ys = [], 0.68
    names = list(order.index)
    for i in range(k):
        j = max(jj for jj in range(i, k) if order.iloc[jj] - order.iloc[i] <= fr["cd"])
        if j > i and not any(g[0] <= i and j <= g[1] for g in groups):
            groups.append((i, j))
    for g in groups:
        ax.hlines(ys, order.iloc[g[0]] - 0.03, order.iloc[g[1]] + 0.03, color=ps.INK["text"], lw=3)
        ys -= 0.04
    ax.axis("off")
    fig.tight_layout()
    ps.save(fig, "F4_7_critical_difference", pd.DataFrame({"model": names, "average_rank": order.values,
                                                         "cd": fr["cd"], "friedman_p": fr["p"]}).round(4))

    labels_k = ["True label"] + [lab for _, lab in METHODS]
    fig, axes = plt.subplots(1, 3, figsize=(ps.FULL_WIDTH, 7.5 * ps.CM))
    for ax, (sname, *_r) in zip(axes, [s for s in SETS if s[5]]):
        mat = np.eye(len(labels_k))
        d = kap[kap.evaluation_set == sname]
        for r in d.itertuples():
            i, j = labels_k.index(r.a), labels_k.index(r.b)
            mat[i, j] = mat[j, i] = r.kappa
        ax.imshow(mat, cmap=ps.DIVERGING, vmin=-1, vmax=1)
        for i in range(len(labels_k)):
            for j in range(len(labels_k)):
                ax.text(j, i, f"{mat[i, j]:.2f}", ha="center", va="center", fontsize=6.5,
                        color="white" if abs(mat[i, j]) > 0.6 else ps.INK["text"])
        short = ["Truth", "ML", "Rogers", "IEC", "Duval"]
        ax.set_xticks(range(5))
        ax.set_xticklabels(short, fontsize=7, rotation=45, ha="right")
        ax.set_yticks(range(5))
        ax.set_yticklabels(short, fontsize=7)
        ax.set_title(sname, loc="left", fontsize=8)
        ax.grid(False)
    fig.tight_layout()
    ps.save(fig, "F4_11_kappa_agreement", kap.round(4))

    rep = ["# Step 30 report - significance tests", "",
           "## Friedman / Nemenyi (cross-validation, 50 folds)", "", md_table(pd.DataFrame(fr_rows).round(4)), "",
           md_table(pd.read_csv(SA / "friedman_ranks_F4.csv")), "",
           "## Cochran's Q", "", md_table(cqd.round(4)), "",
           "## McNemar with Holm (Table 4.6; primary and no-gate)", "",
           md_table(mc[["evaluation_set", "variant", "comparison", "b", "c", "test", "p", "p_holm", "odds_ratio", "or_lo", "or_hi",
                        "significant_holm"]].round(4)), "",
           "## Hypothesis criteria", "", "```", json.dumps(crit, indent=1), "```", ""]
    (INTERIM / "step30_report.md").write_text("\n".join(rep), encoding="utf-8")
    print("\n".join(rep))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
