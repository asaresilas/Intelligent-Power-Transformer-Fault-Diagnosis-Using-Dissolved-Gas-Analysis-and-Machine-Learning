"""Roadmap Step 31 [Claude Code] - test the boundary hypothesis (RQ2; hypothesis criterion 3).

Input : 08_Statistical_Analysis/merged_predictions.csv (Step 28).
Do    : (decision D27) for each conventional method, logistic regression of disagreement (ML answer != method answer) on the
        standardised distance to the nearest decision boundary (Eq. 33); odds ratio per SD with 95 % CI (Eq. 34); Firth's
        penalised regression if separation occurs. Main analysis: the 205 primary test records pooled, answers after the gate;
        sensitivity: raw answers, per test set, test-set indicators.
Output: 08_Statistical_Analysis/boundary_regression.csv, boundary_data.csv; Table 4.8 (11_Results/tables/T4_8_boundary.csv);
        Figure 4.12; criterion 3 added to hypothesis_criteria.json; 03_Data/interim/step31_report.md
"""
from __future__ import annotations

import hashlib
import json
import sys
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
from step29_measures import SETS, answers, wilson  # noqa: E402

SA = PROJECT_ROOT / "08_Statistical_Analysis"
CONV = [("Rogers", "Rogers Ratio"), ("IEC60599", "IEC 60599 ratio"), ("Duval", "Duval Triangle 1")]
Z = float(stats.norm.ppf(0.975))


def logit_fit(X: np.ndarray, y: np.ndarray, firth: bool = False, iters: int = 100) -> dict:
    """Newton-Raphson logistic regression; firth=True uses Firth's modified score (Heinze and Schemper 2002 form)."""
    beta = np.zeros(X.shape[1])
    for _ in range(iters):
        p = 1 / (1 + np.exp(-(X @ beta)))
        W = p * (1 - p)
        info = X.T @ (X * W[:, None])
        if firth:
            inv = np.linalg.inv(info)
            h = np.einsum("ij,jk,ik->i", X * np.sqrt(W)[:, None], inv, X * np.sqrt(W)[:, None])
            score = X.T @ (y - p + h * (0.5 - p))
        else:
            score = X.T @ (y - p)
        step = np.linalg.solve(info, score)
        beta = beta + step
        if np.max(np.abs(step)) < 1e-10:
            break
    p = 1 / (1 + np.exp(-(X @ beta)))
    info = X.T @ (X * (p * (1 - p))[:, None])
    se = np.sqrt(np.diag(np.linalg.inv(info)))
    return {"beta": beta, "se": se, "converged": bool(np.max(np.abs(step)) < 1e-8)}


def separated(X: np.ndarray, y: np.ndarray, fit: dict) -> bool:
    p = 1 / (1 + np.exp(-(X @ fit["beta"])))
    return (not fit["converged"]) or bool(np.any(np.abs(fit["beta"]) > 15)) or bool(np.all((p > 0.5) == (y == 1)))


def disagree(ml: np.ndarray, ans: np.ndarray) -> np.ndarray:
    same = (ml == ans) | ((ans == "D1/D2") & np.isin(ml, ["D1", "D2"]))
    return (~same).astype(int)


def fit_one(d: np.ndarray, y: np.ndarray, extra: np.ndarray | None = None) -> dict:
    z = (d - d.mean()) / d.std(ddof=1)
    cols = [np.ones_like(z), z] + ([] if extra is None else [extra[:, j] for j in range(extra.shape[1])])
    X = np.column_stack(cols)
    if y.min() == y.max():
        return {"n": len(y), "n_disagree": int(y.sum()), "beta1": np.nan, "se": np.nan, "p": np.nan, "or": np.nan,
                "or_lo": np.nan, "or_hi": np.nan, "method_used": "not estimable (no variation)", "beta0": np.nan}
    f = logit_fit(X, y)
    used = "maximum likelihood"
    if separated(X, y, f):
        f = logit_fit(X, y, firth=True)
        used = "Firth penalised"
    b1, se = f["beta"][1], f["se"][1]
    return {"n": len(y), "n_disagree": int(y.sum()), "beta0": f["beta"][0], "beta1": b1, "se": se,
            "p": float(2 * stats.norm.sf(abs(b1 / se))), "or": float(np.exp(b1)), "or_lo": float(np.exp(b1 - Z * se)),
            "or_hi": float(np.exp(b1 + Z * se)), "method_used": used, "z_mean": d.mean(), "z_sd": d.std(ddof=1)}


def main() -> int:
    problems = verify_data_version()
    if problems:
        raise SystemExit("data version 1.0 changed: " + "; ".join(problems))
    mp = SA / "merged_predictions.csv"
    ck = json.loads((SA / "merge_checks.json").read_text(encoding="utf-8"))
    assert hashlib.sha256(mp.read_bytes()).hexdigest().upper() == ck["merged_sha256"], "merged file changed since Step 28"
    mg = pd.read_csv(mp, keep_default_na=False, na_values=["NaN", ""])

    parts = []
    for sname, role, filt, merged, labels, primary in SETS:
        if not primary:
            continue
        df = mg[(mg.data_role == role) & mg[filt]].reset_index(drop=True)
        for m, lab in CONV:
            ml = answers(df, "ML", merged, "primary")
            for variant in ("primary", "no_gate"):
                parts.append(pd.DataFrame({"record_id": df.record_id, "evaluation_set": sname, "method": m, "variant": variant,
                                           "distance": df[f"{m}_boundary_distance"].astype(float),
                                           "disagree": disagree(ml, answers(df, m, merged, variant))}))
    data = pd.concat(parts, ignore_index=True)
    data["finite"] = np.isfinite(data.distance)
    data.to_csv(SA / "boundary_data.csv", index=False)

    rows = []
    sets = [s[0] for s in SETS if s[5]]
    for m, lab in CONV:
        for variant in ("primary", "no_gate"):
            dm = data[(data.method == m) & (data.variant == variant)]
            ok = dm[dm.finite]
            excl = int((~dm.finite).sum())
            base = {"method": m, "method_label": lab, "variant": variant, "n_excluded_no_distance": excl}
            rows.append({**base, "analysis": "pooled (main)", **fit_one(ok.distance.to_numpy(), ok.disagree.to_numpy())})
            dummies = pd.get_dummies(ok.evaluation_set, drop_first=True).to_numpy(float)
            rows.append({**base, "analysis": "pooled + test-set indicators",
                         **fit_one(ok.distance.to_numpy(), ok.disagree.to_numpy(), dummies)})
            for s in sets:
                o = ok[ok.evaluation_set == s]
                rows.append({**base, "n_excluded_no_distance": int((~dm[dm.evaluation_set == s].finite).sum()),
                             "analysis": f"set: {s}", **fit_one(o.distance.to_numpy(), o.disagree.to_numpy())})
    res = pd.DataFrame(rows)
    res["criterion3_met"] = (res.beta1 < 0) & (res.or_hi < 1)
    res.round(6).to_csv(SA / "boundary_regression.csv", index=False)
    t48 = res[(res.variant == "primary") & (res.analysis == "pooled (main)")][
        ["method_label", "n", "n_excluded_no_distance", "n_disagree", "beta1", "se", "or", "or_lo", "or_hi", "p", "method_used",
         "criterion3_met"]]
    t48.round(4).to_csv(PROJECT_ROOT / "11_Results" / "tables" / "T4_8_boundary.csv", index=False)

    # criterion 3 into the hypothesis file (D27: verdict read on IEC TC 10; pooled = main evidence on RQ2)
    hc_path = SA / "hypothesis_criteria.json"
    hc = json.loads(hc_path.read_text(encoding="utf-8"))
    for s in sets:
        r = res[(res.variant == "primary") & (res.analysis == f"set: {s}")].set_index("method")
        hc[s]["criterion3_beta1_negative_ci_excludes_0"] = {m: bool(r.loc[m, "criterion3_met"]) for m, _ in CONV}
        hc[s]["criterion3_met"] = bool(all(r.loc[m, "criterion3_met"] for m, _ in CONV))
        hc[s]["criterion3"] = "decided in Step 31"
    rp = res[(res.variant == "primary") & (res.analysis == "pooled (main)")].set_index("method")
    hc["pooled_primary_sets"] = {"criterion3_beta1_negative_ci_excludes_0": {m: bool(rp.loc[m, "criterion3_met"]) for m, _ in CONV},
                                 "criterion3_met": bool(all(rp.loc[m, "criterion3_met"] for m, _ in CONV))}
    dec = hc[hc["decisive_set"]]
    hc["verdict_main_benchmark"] = ("SUPPORTED" if (dec["criterion1_met"] and dec["criterion2_met"] and dec["criterion3_met"])
                                    else "NOT SUPPORTED" if not dec["criterion1_met"] else "PARTLY SUPPORTED")
    hc_path.write_text(json.dumps(hc, indent=1), encoding="utf-8")

    # Figure 4.12
    ps.apply()
    import matplotlib.pyplot as plt
    fig, axes = plt.subplots(1, 3, figsize=(ps.FULL_WIDTH, 7 * ps.CM), sharey=True)
    fig_rows = []
    for ax, (m, lab) in zip(axes, CONV):
        ok = data[(data.method == m) & (data.variant == "primary") & data.finite].reset_index(drop=True)
        r = rp.loc[m]
        z = (ok.distance - r.z_mean) / r.z_sd
        X = np.column_stack([np.ones(len(z)), z])
        f = logit_fit(X, ok.disagree.to_numpy(), firth=(r.method_used == "Firth penalised"))
        grid = np.linspace(z.min(), z.max(), 200)
        G = np.column_stack([np.ones_like(grid), grid])
        eta = G @ f["beta"]
        cov = np.linalg.inv(X.T @ (X * ((1 / (1 + np.exp(-(X @ f["beta"])))) * (1 - 1 / (1 + np.exp(-(X @ f["beta"])))))[:, None]))
        se_eta = np.sqrt(np.einsum("ij,jk,ik->i", G, cov, G))
        lo, hi = 1 / (1 + np.exp(-(eta - Z * se_eta))), 1 / (1 + np.exp(-(eta + Z * se_eta)))
        col = ps.METHOD.loc[m, "colour_hex"]
        ax.fill_between(grid, lo, hi, color=col, alpha=0.2, lw=0)
        ax.plot(grid, 1 / (1 + np.exp(-eta)), color=col, lw=1.5)
        bins = pd.qcut(z.rank(method="first"), 10, labels=False)
        for b in range(10):
            sel = bins == b
            k, n = int(ok.disagree[sel].sum()), int(sel.sum())
            l_, h_ = wilson(k, n)
            ax.errorbar(z[sel].mean(), k / n, yerr=[[k / n - l_], [h_ - k / n]], fmt="o", ms=3, color=ps.INK["text"],
                        elinewidth=0.6, capsize=1.5)
            fig_rows.append({"method": m, "group": b + 1, "z_mean": z[sel].mean(), "n": n, "disagree": k, "rate": k / n,
                             "wilson_lo": l_, "wilson_hi": h_})
        ax.plot(z[ok.disagree == 0], np.full((ok.disagree == 0).sum(), -0.03), "|", color=ps.INK["muted"], ms=4)
        ax.plot(z[ok.disagree == 1], np.full((ok.disagree == 1).sum(), 1.03), "|", color=ps.INK["muted"], ms=4)
        ax.set_ylim(-0.06, 1.06)
        ax.set_title(f"{lab}\nOR {r['or']:.2f} [{r.or_lo:.2f}, {r.or_hi:.2f}]", loc="left", fontsize=8)
        ax.set_xlabel("Boundary distance, z-score [-]", fontsize=8)
    axes[0].set_ylabel("Probability of disagreement [-]")
    fig.tight_layout()
    ps.save(fig, "F4_12_disagreement_vs_distance", pd.DataFrame(fig_rows).round(4))

    rep = ["# Step 31 report - boundary hypothesis", "", "## Table 4.8 (pooled primary test records, answers after the gate)", "",
           md_table(t48.round(4)), "", "## All fits", "",
           md_table(res[["method", "variant", "analysis", "n", "n_disagree", "n_excluded_no_distance", "beta1", "or", "or_lo",
                         "or_hi", "p", "method_used", "criterion3_met"]].round(4)), "",
           "## Hypothesis", "", "```", json.dumps({k: hc[k] for k in ("verdict_main_benchmark", "pooled_primary_sets")}, indent=1), "```", ""]
    (INTERIM / "step31_report.md").write_text("\n".join(rep), encoding="utf-8")
    print("\n".join(rep))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
