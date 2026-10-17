"""Roadmap Step 29 [Claude Code] - performance measures with 95 % confidence intervals.

Input : 08_Statistical_Analysis/merged_predictions.csv (Step 28) - nothing else.
Do    : (decision D25) for the ML model and the three conventional methods on every evaluation set: strict and conditional
        accuracy and coverage (Wilson intervals, Eqs. 6-7, 21); macro-F1, balanced accuracy, kappa, MCC (stratified paired
        bootstrap, Eq. 22, B = 2000); per-class precision, recall, F1; differences ML minus each method (paired bootstrap);
        sensitivity analyses (lower gate, no gate, dual answer wrong; all records of each set).
Output: 08_Statistical_Analysis/performance_measures.csv, per_class_measures.csv, differences.csv, confusion_matrices.csv;
        Tables 4.3 and 4.5 (11_Results/tables/T4_3_conventional.csv, T4_5_main_comparison.csv);
        Figures 4.5 (one per test set) and 4.8; 03_Data/interim/step29_report.md
Check : every number comes from the merged file of Step 28 (its SHA-256 is checked against merge_checks.json).
"""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "data_prep"))
sys.path.insert(0, str(HERE.parent / "analysis"))

import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402
from scipy.stats import norm  # noqa: E402

import plotstyle as ps  # noqa: E402
from common import INTERIM, PROJECT_ROOT, md_table, verify_data_version  # noqa: E402

SA = PROJECT_ROOT / "08_Statistical_Analysis"
B, SEED, Z = 2000, 20261010, float(norm.ppf(0.975))
SEVEN = ["Normal", "PD", "D1", "D2", "T1", "T2", "T3"]
MERGED5 = ["PD", "D1", "D2", "T12", "T3"]
METHODS = [("ML", "ML (selected model)"), ("Rogers", "Rogers Ratio"), ("IEC60599", "IEC 60599 ratio"), ("Duval", "Duval Triangle 1")]
# (name, role, filter column, merged?, class list, primary?)
SETS = [("Internal test", "internal_test", "independent_of_benchmark", False, SEVEN, True),
        ("IEC TC 10 (power transformers)", "benchmark", "in_scope_primary", True, MERGED5, True),
        ("Li 2019", "external_test", "independent_of_benchmark", False, SEVEN[1:], True),
        ("Internal test - all records", "internal_test", None, False, SEVEN, False),
        ("IEC TC 10 - all records", "benchmark", None, True, MERGED5, False),
        ("Li 2019 - all records", "external_test", None, True, MERGED5, False)]
VARIANTS = ["primary", "lower_gate", "no_gate", "dual_wrong"]
NOT_ANSWER = "ND"


def wilson(k: int, n: int) -> tuple[float, float]:
    if n == 0:
        return (np.nan, np.nan)
    p = k / n
    c = (p + Z * Z / (2 * n)) / (1 + Z * Z / n)
    h = Z * np.sqrt(p * (1 - p) / n + Z * Z / (4 * n * n)) / (1 + Z * Z / n)
    return (c - h, c + h)


def answers(df: pd.DataFrame, method: str, merged: bool, variant: str) -> np.ndarray:
    if method == "ML":
        return (df.ml_pred_merged if merged else df.ml_pred).to_numpy(object)
    col = {"primary": f"{method}_result", "dual_wrong": f"{method}_result", "lower_gate": f"{method}_result_lower_gate",
           "no_gate": f"{method}_raw"}[variant]
    a = df[col].copy()
    if merged:
        a = a.map(lambda v: {"T1": "T12", "T2": "T12"}.get(v, v))
    return a.to_numpy(object)


def effective(truth: np.ndarray, ans: np.ndarray, dual_ok: bool) -> np.ndarray:
    """Answer with a correct dual D1/D2 replaced by the true class (D11 rule 4)."""
    eff = ans.copy()
    if dual_ok:
        hit = (ans == "D1/D2") & np.isin(truth, ["D1", "D2"])
        eff[hit] = truth[hit]
    return eff


def class_counts(truth, eff, labels):
    tp = np.array([np.sum((truth == c) & (eff == c)) for c in labels], float)
    fp = np.array([np.sum((truth != c) & ((eff == c) | ((eff == "D1/D2") & (c in ("D1", "D2"))))) for c in labels], float)
    fn = np.array([np.sum((truth == c) & (eff != c)) for c in labels], float)
    return tp, fp, fn


def macro_f1(truth, eff, labels) -> float:
    tp, fp, fn = class_counts(truth, eff, labels)
    d = 2 * tp + fp + fn
    return float(np.mean(np.divide(2 * tp, d, out=np.zeros_like(tp), where=d > 0)))


def balanced_acc(truth, eff, labels) -> float:
    rec = [np.mean(eff[truth == c] == c) for c in labels if np.any(truth == c)]
    return float(np.mean(rec))


def kappa_mcc(truth, eff) -> tuple[float, float]:
    cats = sorted(set(truth) | set(eff))
    idx = {c: i for i, c in enumerate(cats)}
    k = len(cats)
    cm = np.zeros((k, k))
    for t, p in zip(truth, eff):
        cm[idx[t], idx[p]] += 1
    n = cm.sum()
    po = np.trace(cm) / n
    pe = (cm.sum(1) @ cm.sum(0)) / n ** 2
    kap = (po - pe) / (1 - pe) if pe < 1 else np.nan
    t, p = cm.sum(1), cm.sum(0)
    c = np.trace(cm)
    den = np.sqrt((n * n - p @ p) * (n * n - t @ t))
    mcc = (c * n - t @ p) / den if den > 0 else 0.0
    return float(kap), float(mcc)


def point_measures(truth, ans, labels, dual_ok) -> dict:
    eff = effective(truth, ans, dual_ok)
    n = len(truth)
    nd = int(np.sum(ans == NOT_ANSWER))
    correct = int(np.sum(eff == truth))
    kap, mcc = kappa_mcc(truth, eff)
    return {"n": n, "n_correct": correct, "n_nd": nd, "n_dt": int(np.sum(ans == "DT")), "n_dual": int(np.sum(ans == "D1/D2")),
            "n_normal_answers": int(np.sum(ans == "Normal")),
            "strict_accuracy": correct / n, "conditional_accuracy": correct / (n - nd) if n > nd else np.nan,
            "coverage": (n - nd) / n, "macro_f1": macro_f1(truth, eff, labels),
            "balanced_accuracy": balanced_acc(truth, eff, labels), "kappa": kap, "mcc": mcc}


def main() -> int:
    problems = verify_data_version()
    if problems:
        raise SystemExit("data version 1.0 changed: " + "; ".join(problems))
    mp = SA / "merged_predictions.csv"
    ck = json.loads((SA / "merge_checks.json").read_text(encoding="utf-8"))
    assert hashlib.sha256(mp.read_bytes()).hexdigest().upper() == ck["merged_sha256"], "merged file changed since Step 28"
    mg = pd.read_csv(mp, keep_default_na=False, na_values=["NaN", ""])

    rows, per_class, diffs, cms = [], [], [], []
    rng = np.random.default_rng(SEED)
    for sname, role, filt, merged, labels, primary in SETS:
        df = mg[mg.data_role == role]
        if filt:
            df = df[df[filt]]
        df = df.reset_index(drop=True)
        truth = (df.class_merged if merged else df.class_name).to_numpy(object)
        assert pd.notna(truth).all() and set(truth) <= set(labels), sname
        strata = [np.flatnonzero(truth == c) for c in labels if np.any(truth == c)]
        boots = [np.concatenate([rng.choice(s, len(s), replace=True) for s in strata]) for _ in range(B)]
        for variant in (VARIANTS if primary else ["primary"]):
            dual_ok = variant != "dual_wrong"
            A = {m: answers(df, m, merged, variant) for m, _ in METHODS}
            bs = {m: np.array([[macro_f1(truth[i], effective(truth[i], A[m][i], dual_ok), labels),
                                balanced_acc(truth[i], effective(truth[i], A[m][i], dual_ok), labels),
                                *kappa_mcc(truth[i], effective(truth[i], A[m][i], dual_ok)),
                                np.mean(effective(truth[i], A[m][i], dual_ok) == truth[i]),
                                ] for i in boots]) for m, _ in METHODS}
            for m, mlabel in METHODS:
                if m == "ML" and variant != "primary":
                    continue
                pm = point_measures(truth, A[m], labels, dual_ok)
                rec = {"evaluation_set": sname, "primary_set": primary, "variant": variant, "method": m, "method_label": mlabel, **pm}
                for key in ("strict_accuracy", "coverage"):
                    k = pm["n_correct"] if key == "strict_accuracy" else pm["n"] - pm["n_nd"]
                    rec[f"{key}_lo"], rec[f"{key}_hi"] = wilson(k, pm["n"])
                rec["conditional_accuracy_lo"], rec["conditional_accuracy_hi"] = wilson(pm["n_correct"], pm["n"] - pm["n_nd"])
                for j, key in enumerate(("macro_f1", "balanced_accuracy", "kappa", "mcc")):
                    rec[f"{key}_lo"], rec[f"{key}_hi"] = np.nanpercentile(bs[m][:, j], [2.5, 97.5])
                rows.append(rec)
                if variant == "primary":
                    eff = effective(truth, A[m], dual_ok)
                    tp, fp, fn = class_counts(truth, eff, labels)
                    for c, a, b_, f in zip(labels, tp, fp, fn):
                        per_class.append({"evaluation_set": sname, "method": m, "class": c, "support": int(a + f),
                                          "precision": a / (a + b_) if a + b_ else np.nan, "recall": a / (a + f) if a + f else np.nan,
                                          "f1": 2 * a / (2 * a + b_ + f) if (2 * a + b_ + f) else 0.0})
                    cols = labels + [x for x in ["Normal", "D1/D2", "DT", "ND"] if x not in labels]
                    for t in labels:
                        for p in cols:
                            cms.append({"evaluation_set": sname, "method": m, "true": t, "answer": p,
                                        "count": int(np.sum((truth == t) & (A[m] == p)))})
            # differences ML minus each method (paired bootstrap), primary answers of ML
            mlp = point_measures(truth, A["ML"], labels, True)
            for m, mlabel in METHODS[1:]:
                pm = point_measures(truth, A[m], labels, dual_ok)
                cond_gap = mlp["conditional_accuracy"] - pm["conditional_accuracy"]
                d_strict = bs["ML"][:, 4] - bs[m][:, 4]
                d_f1 = bs["ML"][:, 0] - bs[m][:, 0]
                diffs.append({"evaluation_set": sname, "primary_set": primary, "variant": variant, "method": m,
                              "strict_gap": mlp["strict_accuracy"] - pm["strict_accuracy"],
                              "strict_gap_lo": np.percentile(d_strict, 2.5), "strict_gap_hi": np.percentile(d_strict, 97.5),
                              "conditional_gap": cond_gap,
                              "macro_f1_gap": mlp["macro_f1"] - pm["macro_f1"],
                              "macro_f1_gap_lo": np.percentile(d_f1, 2.5), "macro_f1_gap_hi": np.percentile(d_f1, 97.5),
                              "criterion2_conditional_gap_smaller": bool(cond_gap < mlp["strict_accuracy"] - pm["strict_accuracy"])})
    perf = pd.DataFrame(rows)
    perf.round(6).to_csv(SA / "performance_measures.csv", index=False)
    pd.DataFrame(per_class).round(6).to_csv(SA / "per_class_measures.csv", index=False)
    dif = pd.DataFrame(diffs)
    dif.round(6).to_csv(SA / "differences.csv", index=False)
    cmd = pd.DataFrame(cms)
    cmd.to_csv(SA / "confusion_matrices.csv", index=False)

    tables = PROJECT_ROOT / "11_Results" / "tables"
    prim = perf[perf.primary_set & (perf.variant == "primary")]
    t43 = prim[prim.method != "ML"][["evaluation_set", "method_label", "n", "strict_accuracy", "strict_accuracy_lo", "strict_accuracy_hi",
                                     "conditional_accuracy", "conditional_accuracy_lo", "conditional_accuracy_hi", "coverage",
                                     "coverage_lo", "coverage_hi", "n_nd", "n_dt", "n_dual", "n_normal_answers"]]
    t43.round(4).to_csv(tables / "T4_3_conventional.csv", index=False)
    t45 = prim[["evaluation_set", "method_label", "n", "strict_accuracy", "strict_accuracy_lo", "strict_accuracy_hi", "conditional_accuracy",
                "conditional_accuracy_lo", "conditional_accuracy_hi", "coverage", "coverage_lo", "coverage_hi", "macro_f1",
                "macro_f1_lo", "macro_f1_hi", "balanced_accuracy", "kappa", "mcc"]]
    t45.round(4).to_csv(tables / "T4_5_main_comparison.csv", index=False)

    # Figures 4.5 (conventional, one figure per primary set) and 4.8 (ML, three panels)
    ps.apply()
    import matplotlib.pyplot as plt
    from matplotlib.colors import LinearSegmentedColormap
    WHITE_BLUE = LinearSegmentedColormap.from_list("white_blue", ["#FFFFFF", ps.SCALE["sequential_high"]])

    def heat(ax, sname, m, title):
        d = cmd[(cmd.evaluation_set == sname) & (cmd.method == m)]
        rows_ = list(dict.fromkeys(d["true"]))
        cols_ = [c for c in dict.fromkeys(d.answer) if m != "ML" or c in rows_ or d[d.answer == c]["count"].sum() > 0]
        if m != "ML":
            cols_ = [c for c in cols_ if c in rows_ or d[d.answer == c]["count"].sum() > 0 or c == "ND"]
        mat = np.array([[int(d[(d["true"] == t) & (d.answer == a)]["count"].sum()) for a in cols_] for t in rows_])
        pct = 100 * mat / np.maximum(mat.sum(1, keepdims=True), 1)
        ax.imshow(pct, cmap=WHITE_BLUE, vmin=0, vmax=100, aspect="auto")      # white = 0 %, dark blue = 100 % (plan Fig. 4.5)
        for i in range(len(rows_)):
            for j in range(len(cols_)):
                ax.text(j, i, f"{mat[i, j]}\n{pct[i, j]:.0f}%", ha="center", va="center", fontsize=6,
                        color="white" if pct[i, j] > 55 else ps.INK["text"])
        ax.set_xticks(range(len(cols_)))
        ax.set_xticklabels([c.replace("T12", "T1/T2") for c in cols_], fontsize=7, rotation=45, ha="right")
        ax.set_yticks(range(len(rows_)))
        ax.set_yticklabels([c.replace("T12", "T1/T2") for c in rows_], fontsize=7)
        ax.set_xlabel("Answer given [-]", fontsize=7)
        ax.set_ylabel("True class [-]", fontsize=7)
        ax.set_title(title, loc="left")
        ax.grid(False)
    for k, (sname, *_rest) in enumerate([s for s in SETS if s[5]]):
        fig, axes = plt.subplots(1, 3, figsize=(ps.FULL_WIDTH, 8 * ps.CM))
        for ax, (m, lab) in zip(axes, METHODS[1:]):
            heat(ax, sname, m, lab)
        fig.tight_layout()
        ps.save(fig, f"F4_5{'abc'[k]}_confusion_conventional_{['internal', 'iec_tc10', 'li2019'][k]}",
                cmd[(cmd.evaluation_set == sname) & (cmd.method != "ML")])
    fig, axes = plt.subplots(1, 3, figsize=(ps.FULL_WIDTH, 8 * ps.CM))
    for ax, (sname, *_rest) in zip(axes, [s for s in SETS if s[5]]):
        heat(ax, sname, "ML", sname)
    fig.tight_layout()
    ps.save(fig, "F4_8_confusion_ml", cmd[cmd.method == "ML"])

    show = t45.copy()
    for c in ("strict_accuracy", "conditional_accuracy", "coverage", "macro_f1"):
        show[c] = [f"{v:.3f} [{lo:.3f}, {hi:.3f}]" for v, lo, hi in zip(show[c], show[f"{c}_lo"], show[f"{c}_hi"])]
    rep = ["# Step 29 report - performance measures", "", f"B = {B}, seed {SEED}; Wilson for proportions; merged file verified.", "",
           "## Table 4.5 - main comparison (primary sets, primary scoring)", "",
           md_table(show[["evaluation_set", "method_label", "n", "strict_accuracy", "conditional_accuracy", "coverage", "macro_f1"]]), "",
           "## Differences ML minus each method (primary scoring)", "",
           md_table(dif[dif.primary_set & (dif.variant == "primary")].round(4)), "",
           "## Sensitivity (strict accuracy / macro-F1 by variant, primary sets)", "",
           md_table(perf[perf.primary_set].pivot_table(index=["evaluation_set", "method"], columns="variant",
                                                       values="strict_accuracy").round(3).reset_index()), ""]
    (INTERIM / "step29_report.md").write_text("\n".join(rep), encoding="utf-8")
    print("\n".join(rep))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
