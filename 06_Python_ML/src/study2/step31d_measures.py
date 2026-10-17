"""Roadmap Step 31D [Claude Code] - Study 2: measures, paired contrasts and reject option (protocol D28, clarification D29).

Input : 07_Experiments/2026-10-12_study2_loso/predictions.csv (Step 31C); 03_Data/study2/study2_pooled.csv (conventional raw
        answers and gate flags of the same records).
Do    : per variant and held-out source: macro-F1 over the classes present (primary), strict and balanced accuracy, coverage and
        conditional accuracy (conventional), Wilson intervals and a stratified paired bootstrap (B = 2000, seed 20261012);
        contrasts B-A, C-B and C vs the best conventional method (bootstrap CI of the macro-F1 difference; McNemar on correctness
        with Holm per source); reject option (Chow 1970): tau set so the model's coverage equals that of IEC 60599 / Rogers on the
        source (labels not used), selective accuracy vs the method's conditional accuracy (bootstrap CI, tau fixed).
Output: 08_Statistical_Analysis/study2/ (measures.csv, contrasts.csv, reject_option.csv, risk_coverage.csv);
        Tables 4.12 (T4_12_study2_results.csv) and 4.13 (T4_13_study2_contrasts.csv); Figures 4.23 and 4.24;
        03_Data/interim/step31d_report.md.   All results are EXPLORATORY.
"""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
for sub in ("stats", "data_prep", "analysis"):
    sys.path.insert(0, str(HERE.parent / sub))

import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402

import plotstyle as ps  # noqa: E402
from common import INTERIM, PROJECT_ROOT, md_table  # noqa: E402
from step29_measures import balanced_acc, effective, macro_f1, wilson  # noqa: E402
from step30_tests import holm, mcnemar  # noqa: E402

RUN = PROJECT_ROOT / "07_Experiments" / "2026-10-12_study2_loso"
S2 = PROJECT_ROOT / "03_Data" / "study2"
OUT = PROJECT_ROOT / "08_Statistical_Analysis" / "study2"
SOURCES = ["DISTRAIN", "DISTEST", "IECTC10", "LI2019"]
LABEL = {"DISTRAIN": "Dissanayake training", "DISTEST": "Dissanayake unseen", "IECTC10": "IEC TC 10", "LI2019": "Li 2019"}
CLASSES6 = ["Normal", "PD", "D1", "D2", "T12", "T3"]
CONV = ["IEC60599", "Rogers", "Duval"]
NAME = {"A": "A released", "B": "B pooled", "C": "C hybrid", "IEC60599": "IEC 60599", "Rogers": "Rogers", "Duval": "Duval"}
B_RES, SEED = 2000, 20261012


def sha256(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest().upper()


def conv_answers(df: pd.DataFrame, m: str) -> np.ndarray:
    a = df[f"{m}_raw"].where(df.gate_upper_normal == 0, "Normal")          # upper gate (primary scoring, D25)
    return a.map(lambda v: {"T1": "T12", "T2": "T12"}.get(v, v)).to_numpy(object)


def main() -> int:
    P = pd.read_csv(RUN / "predictions.csv")
    pool = pd.read_csv(S2 / "study2_pooled.csv", keep_default_na=False, na_values=["NaN", ""]).set_index("record_id")
    for line in (S2 / "study2_data.sha256").read_text(encoding="ascii").splitlines():
        h, f = line.split("  ")
        assert sha256(PROJECT_ROOT / f) == h
    OUT.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(SEED)
    mrows, crows, rrows, curve = [], [], [], []
    for variant in sorted(P.variant.unique()):
        for held in SOURCES:
            d = P[(P.variant == variant) & (P.held_out == held)]
            ids = d[d.model == "B"].record_id.to_numpy()
            if held != "DISTRAIN" and not (d.model == "A").any():
                # model A does not depend on the training sources' weights: reuse its predictions for the same records
                a = P[(P.variant == "primary") & (P.held_out == held) & (P.model == "A") & P.record_id.isin(ids)]
                assert len(a) == len(ids)
                d = pd.concat([d, a.assign(variant=variant)], ignore_index=True)
            truth = pool.loc[ids, "class6"].to_numpy(object)
            labels = [c for c in CLASSES6 if np.any(truth == c)]
            ans, prob = {}, {}
            for mdl in ("A", "B", "C"):
                x = d[d.model == mdl].set_index("record_id")
                if len(x):
                    x = x.loc[ids]
                    ans[mdl] = x.y_pred.to_numpy(object)
                    prob[mdl] = x[[f"p_{c}" for c in CLASSES6]].to_numpy()
            for m in CONV:
                ans[m] = conv_answers(pool.loc[ids], m)
            eff = {k: effective(truth, a, True) for k, a in ans.items()}
            corr = {k: (e == truth).astype(int) for k, e in eff.items()}
            strata = [np.flatnonzero(truth == c) for c in labels]
            boots = [np.concatenate([rng.choice(s, len(s), replace=True) for s in strata]) for _ in range(B_RES)]
            bf1 = {k: np.array([macro_f1(truth[i], eff[k][i], labels) for i in boots]) for k in eff}
            n = len(ids)
            for k in eff:
                nd = int(np.sum(ans[k] == "ND"))
                lo, hi = wilson(int(corr[k].sum()), n)
                clo, chi = wilson(int(corr[k].sum()), n - nd) if n > nd else (np.nan, np.nan)
                mrows.append({"variant": variant, "held_out": held, "model": k, "n": n, "classes": "/".join(labels),
                              "macro_f1": macro_f1(truth, eff[k], labels), "macro_f1_lo": np.percentile(bf1[k], 2.5),
                              "macro_f1_hi": np.percentile(bf1[k], 97.5), "strict_accuracy": corr[k].mean(),
                              "strict_lo": lo, "strict_hi": hi, "balanced_accuracy": balanced_acc(truth, eff[k], labels),
                              "coverage": (n - nd) / n, "conditional_accuracy": corr[k].sum() / (n - nd) if n > nd else np.nan,
                              "conditional_lo": clo, "conditional_hi": chi})
            # contrasts
            best = max(CONV, key=lambda m: corr[m].mean())
            pairs = ([("B", "A")] if "A" in eff else []) + [("C", "B"), ("C", best)]
            cr = []
            for x, y in pairs:
                dif = bf1[x] - bf1[y]
                b = int(np.sum((corr[x] == 1) & (corr[y] == 0)))
                c = int(np.sum((corr[x] == 0) & (corr[y] == 1)))
                cr.append({"variant": variant, "held_out": held, "contrast": f"{x} - {y}", "first": x, "second": y,
                           "best_conventional": best, "macro_f1_diff": macro_f1(truth, eff[x], labels) - macro_f1(truth, eff[y], labels),
                           "diff_lo": np.percentile(dif, 2.5), "diff_hi": np.percentile(dif, 97.5),
                           "strict_diff": corr[x].mean() - corr[y].mean(), "b": b, "c": c, **mcnemar(b, c)})
            adj = holm([r["p"] for r in cr])
            for r, pa in zip(cr, adj):
                r["p_holm"] = pa
                r["ci_excludes_0_positive"] = bool(r["diff_lo"] > 0)
            crows += cr
            # reject option: tau from model probabilities only, coverage matched to IEC 60599 / Rogers
            for mdl in [k for k in ("A", "B", "C") if k in prob]:
                conf = prob[mdl].max(axis=1)
                order = np.sort(conf)[::-1]
                for q in np.linspace(0.05, 1.0, 20):
                    k = max(1, int(round(q * n)))
                    sel_ = conf >= order[k - 1]
                    curve.append({"variant": variant, "held_out": held, "model": mdl, "target_coverage": q,
                                  "coverage": sel_.mean(), "selective_accuracy": corr[mdl][sel_].mean()})
                for m in ("IEC60599", "Rogers"):
                    cov = float(np.mean(ans[m] != "ND"))
                    k = max(1, int(round(cov * n)))
                    tau = order[k - 1]
                    sel_ = conf >= tau
                    cond_m = corr[m].sum() / max(1, np.sum(ans[m] != "ND"))
                    sa = corr[mdl][sel_].mean()
                    bd = []
                    for i in boots:
                        s_i = conf[i] >= tau
                        a_i = ans[m][i] != "ND"
                        if s_i.sum() and a_i.sum():
                            bd.append(corr[mdl][i][s_i].mean() - corr[m][i][a_i].mean())
                    rrows.append({"variant": variant, "held_out": held, "model": mdl, "method": m, "method_coverage": cov,
                                  "model_coverage": sel_.mean(), "tau": tau, "selective_accuracy": sa,
                                  "method_conditional_accuracy": cond_m, "diff": sa - cond_m,
                                  "diff_lo": np.percentile(bd, 2.5), "diff_hi": np.percentile(bd, 97.5)})
    M, C, R, K = (pd.DataFrame(x) for x in (mrows, crows, rrows, curve))
    M.round(6).to_csv(OUT / "measures.csv", index=False)
    C.round(6).to_csv(OUT / "contrasts.csv", index=False)
    R.round(6).to_csv(OUT / "reject_option.csv", index=False)
    K.round(6).to_csv(OUT / "risk_coverage.csv", index=False)
    tables = PROJECT_ROOT / "11_Results" / "tables"
    M[M.variant == "primary"].round(4).to_csv(tables / "T4_12_study2_results.csv", index=False)
    pd.concat([C[C.variant == "primary"].assign(kind="contrast"),
               R[(R.variant == "primary") & (R.model == "C")].assign(kind="reject option")], ignore_index=True
              ).round(4).to_csv(tables / "T4_13_study2_contrasts.csv", index=False)

    # Figures 4.23 and 4.24
    ps.apply()
    import matplotlib.pyplot as plt
    col = {"A": ps.INK["muted"], "B": "#7FA7E3", "C": ps.METHOD.loc["ML", "colour_hex"], "IEC60599": ps.METHOD.loc["IEC60599", "colour_hex"],
           "Rogers": ps.METHOD.loc["Rogers", "colour_hex"], "Duval": ps.METHOD.loc["Duval", "colour_hex"]}
    mk = {"A": "o", "B": "o", "C": "o", "IEC60599": "D", "Rogers": "s", "Duval": "^"}
    prim = M[M.variant == "primary"]
    fig, axes = plt.subplots(1, 4, figsize=(ps.FULL_WIDTH, 7 * ps.CM), sharex=True)
    order = ["A", "B", "C", "IEC60599", "Rogers", "Duval"]
    for ax, held in zip(axes, SOURCES):
        p = prim[prim.held_out == held].set_index("model")
        for j, k in enumerate(order):
            if k in p.index:
                r = p.loc[k]
                ax.errorbar(r.macro_f1, j, xerr=[[r.macro_f1 - r.macro_f1_lo], [r.macro_f1_hi - r.macro_f1]], fmt=mk[k],
                            color=col[k], ms=4, elinewidth=1, capsize=2)
        ax.set_yticks(range(len(order)))
        ax.set_yticklabels([NAME[k] for k in order] if held == SOURCES[0] else [], fontsize=7)
        ax.set_ylim(len(order) - 0.5, -0.5)
        ax.set_xlim(0, 1)
        ax.set_title(f"{LABEL[held]}\n(n = {int(p.n.iloc[0])})", loc="left", fontsize=8)
        ax.set_xlabel("Macro-F1 [-]", fontsize=7)
    fig.tight_layout()
    ps.save(fig, "F4_23_study2_macro_f1", prim.round(4))

    kp = K[K.variant == "primary"]
    rp = M[(M.variant == "primary") & M.model.isin(CONV)]
    fig, axes = plt.subplots(1, 4, figsize=(ps.FULL_WIDTH, 7 * ps.CM), sharey=True)
    for ax, held in zip(axes, SOURCES):
        for mdl in ("A", "B", "C"):
            q = kp[(kp.held_out == held) & (kp.model == mdl)].sort_values("coverage")
            if len(q):
                ax.plot(q.coverage, q.selective_accuracy, "-", color=col[mdl], lw=1.4 if mdl == "C" else 0.9, label=NAME[mdl])
        for m in CONV:
            r = rp[(rp.held_out == held) & (rp.model == m)].iloc[0]
            ax.plot(r.coverage, r.conditional_accuracy, mk[m], color=col[m], ms=5, label=NAME[m])
        ax.set_xlim(0, 1.02)
        ax.set_ylim(0, 1.02)
        ax.set_title(LABEL[held], loc="left", fontsize=8)
        ax.set_xlabel("Coverage [-]", fontsize=7)
    axes[0].set_ylabel("Accuracy on answered records [-]")
    h, l_ = axes[1].get_legend_handles_labels()
    fig.legend(h, l_, loc="lower center", ncol=6, frameon=False, fontsize=7)
    fig.tight_layout(rect=(0, 0.08, 1, 1))
    ps.save(fig, "F4_24_study2_accuracy_coverage", kp.round(4))

    show = prim[["held_out", "model", "n", "macro_f1", "macro_f1_lo", "macro_f1_hi", "strict_accuracy", "coverage"]].round(3)
    rep = ["# Step 31D report - Study 2 measures (EXPLORATORY)", "", "## Table 4.12 (primary variant)", "", md_table(show), "",
           "## Contrasts (all variants)", "", md_table(C[["variant", "held_out", "contrast", "macro_f1_diff", "diff_lo", "diff_hi",
                                                          "b", "c", "p", "p_holm"]].round(3)), "",
           "## Reject option (model C, primary)", "", md_table(R[(R.variant == "primary") & (R.model == "C")][
               ["held_out", "method", "method_coverage", "selective_accuracy", "method_conditional_accuracy", "diff", "diff_lo",
                "diff_hi"]].round(3)), ""]
    (INTERIM / "step31d_report.md").write_text("\n".join(rep), encoding="utf-8")
    print("\n".join(rep))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
