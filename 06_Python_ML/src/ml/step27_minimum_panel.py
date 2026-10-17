"""Roadmap Step 27 [Claude Code] - find the minimum gas panel.

Input : 07_Experiments/2026-10-12_reducedgas_v1/predictions.csv and fold_metrics.csv (Step 25);
        11_Results/reduced_gas/reduced_gas_subsets.csv; 11_Results/conventional/conventional_applicability.csv (Step 26).
Do    : (decision D24) for every gas subset: macro-F1 = mean over the 10 repeats of macro-F1 on the 439 out-of-fold
        predictions; loss Delta_S vs the five-gas panel (Eq. 36); 95 % stratified percentile bootstrap (Section 6.2, B = 2000,
        records resampled within class, the same resample for every subset - paired); minimum panel = fewest gases with
        upper 95 % limit of the loss <= delta = 0.05 (Eq. 37); sensitivity: corrected resampled t interval of the fold loss.
Output: Table 4.9 -> 11_Results/tables/T4_9_reduced_gas.csv; Figures 4.16 and 4.17 (PNG, PDF, CSV);
        11_Results/reduced_gas/minimum_panel.json; 03_Data/interim/step27_report.md
Check : the tolerance used is the one approved before the results were seen (delta = 0.05, Analysis Plan item 13).
"""
from __future__ import annotations

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
from features import GASES  # noqa: E402

RUN = PROJECT_ROOT / "07_Experiments" / "2026-10-12_reducedgas_v1"
RG = PROJECT_ROOT / "11_Results" / "reduced_gas"
DELTA, B, SEED, K = 0.05, 2000, 20261010, 7          # tolerance (approved item 13), resamples, seed, classes
FULL = "+".join(GASES)
METHODS = [("Rogers", "Rogers"), ("IEC60599", "IEC 60599"), ("Duval", "Duval")]


def macro_f1_from_codes(yt: np.ndarray, yp: np.ndarray, k: int = K) -> float:
    """Macro-F1 over the k classes (labels 0..k-1), F1 = 0 for a class never true and never predicted - as in Step 20."""
    cm = np.bincount(k * yt + yp, minlength=k * k).reshape(k, k)
    tp = np.diag(cm).astype(float)
    denom = cm.sum(axis=0) + cm.sum(axis=1)
    f1 = np.divide(2 * tp, denom, out=np.zeros(k), where=denom > 0)
    return float(f1.mean())


def main() -> int:
    problems = verify_data_version()
    if problems:
        raise SystemExit("data version 1.0 changed: " + "; ".join(problems))
    subs = pd.read_csv(RG / "reduced_gas_subsets.csv")
    pred = pd.read_csv(RUN / "predictions.csv", usecols=["subset", "rep", "fold", "record_id", "y_true", "y_pred"])
    records = np.sort(pred.record_id.unique())
    n = len(records)
    pos = {r: i for i, r in enumerate(records)}
    reps = sorted(pred.rep.unique())
    ids = list(subs.subset_id)
    YT = np.full(n, -1)
    YP = np.full((len(ids), len(reps), n), -1)
    for (sid, rep), g in pred.groupby(["subset", "rep"]):
        idx = g.record_id.map(pos).to_numpy()
        YP[ids.index(sid), reps.index(rep), idx] = g.y_pred.to_numpy()
        YT[idx] = g.y_true.to_numpy()
    assert (YP >= 0).all() and (YT >= 0).all(), "every record predicted once per subset and repeat"

    def score_all(idx: np.ndarray) -> np.ndarray:
        """macro-F1 per subset (mean over repeats) on the records idx."""
        return np.array([np.mean([macro_f1_from_codes(YT[idx], YP[s, r, idx]) for r in range(len(reps))])
                         for s in range(len(ids))])

    point = score_all(np.arange(n))
    f_full = ids.index(FULL)
    loss = point[f_full] - point
    rng = np.random.default_rng(SEED)
    strata = [np.flatnonzero(YT == c) for c in range(K)]
    boot = np.empty((B, len(ids)))
    for b in range(B):
        idx = np.concatenate([rng.choice(s, size=len(s), replace=True) for s in strata if len(s)])
        boot[b] = score_all(idx)
    bloss = boot[:, [f_full]] - boot
    f_lo, f_hi = np.percentile(boot, [2.5, 97.5], axis=0)
    l_lo, l_hi = np.percentile(bloss, [2.5, 97.5], axis=0)

    # sensitivity: corrected resampled t interval of the mean fold-wise loss (Eq. 28, k = 5, r = 10)
    fm = pd.read_csv(RUN / "fold_metrics.csv", float_precision="round_trip")
    w = fm.pivot_table(index=["rep", "fold"], columns="subset", values="macro_f1")
    ratio = fm.n_test.mean() / fm.n_train.mean()
    tq = stats.t.ppf(0.975, 49)
    t_rows = {}
    for sid in ids:
        d = (w[FULL] - w[sid]).to_numpy()
        half = tq * np.sqrt((1 / 50 + ratio) * d.var(ddof=1)) if d.var(ddof=1) > 0 else 0.0
        t_rows[sid] = (d.mean(), d.mean() - half, d.mean() + half)

    app = pd.read_csv(PROJECT_ROOT / "11_Results" / "conventional" / "conventional_applicability.csv")
    app = app[app.data_role == "all"]
    usable = {sid: [lab for m, lab in METHODS if int(app[(app.subset_id == sid) & (app.method == m)].applicable.iloc[0])]
              for sid in ids}
    rows = []
    for i, sid in enumerate(ids):
        r = subs.set_index("subset_id").loc[sid]
        rows.append({"subset_id": sid, "n_gases": int(r.n_gases), "n_features": int(r.n_features),
                     "macro_f1": point[i], "macro_f1_ci_low": f_lo[i], "macro_f1_ci_high": f_hi[i],
                     "loss": loss[i], "loss_ci_low": l_lo[i], "loss_ci_high": l_hi[i],
                     "within_tolerance": bool(sid != FULL and l_hi[i] <= DELTA) if sid != FULL else None,
                     "fold_loss_mean": t_rows[sid][0], "fold_loss_t_low": t_rows[sid][1], "fold_loss_t_high": t_rows[sid][2],
                     "within_tolerance_t": bool(t_rows[sid][2] <= DELTA) if sid != FULL else None,
                     "conventional_usable": ", ".join(usable[sid]) if usable[sid] else "none",
                     **{f"has_{g}": bool(r[f"has_{g}"]) for g in GASES}})
    t49 = pd.DataFrame(rows).sort_values(["n_gases", "loss"], ascending=[False, True]).reset_index(drop=True)
    (PROJECT_ROOT / "11_Results" / "tables").mkdir(parents=True, exist_ok=True)
    t49.round(4).to_csv(PROJECT_ROOT / "11_Results" / "tables" / "T4_9_reduced_gas.csv", index=False)

    ok = t49[(t49.subset_id != FULL) & (t49.loss_ci_high <= DELTA)]
    if len(ok):
        kmin = int(ok.n_gases.min())
        cands = ok[ok.n_gases == kmin].sort_values("loss")
        minimum = {"n_gases": kmin, "subset": cands.iloc[0].subset_id, "all_qualifying_of_that_size": list(cands.subset_id)}
    else:
        minimum = {"n_gases": 5, "subset": FULL, "all_qualifying_of_that_size": [FULL]}
    ok_t = t49[(t49.subset_id != FULL) & (t49.fold_loss_t_high <= DELTA)]
    minimum_t = (ok_t.sort_values(["n_gases", "fold_loss_mean"]).iloc[0].subset_id if len(ok_t) else FULL)
    summary = {"delta": DELTA, "B": B, "seed": SEED, "n_records": n, "minimum_panel": minimum,
               "qualifying_subsets_bootstrap": list(ok.subset_id), "minimum_panel_t_sensitivity": minimum_t,
               "qualifying_subsets_t": list(ok_t.subset_id), "full_macro_f1": point[f_full],
               "full_macro_f1_ci": [f_lo[f_full], f_hi[f_full]]}
    (RG / "minimum_panel.json").write_text(json.dumps(summary, indent=1), encoding="utf-8")

    # Figure 4.16 - accuracy against number of gases
    ps.apply()
    import matplotlib.pyplot as plt
    best = t49.sort_values("macro_f1", ascending=False).groupby("n_gases").head(1).sort_values("n_gases")
    fig, ax = plt.subplots(figsize=(ps.FULL_WIDTH, 9 * ps.CM))
    jit = np.random.default_rng(SEED).uniform(-0.08, 0.08, len(t49))
    ax.scatter(t49.n_gases + jit, t49.macro_f1, s=12, color=ps.INK["muted"], zorder=2, label="each gas combination (31)")
    ax.fill_between(best.n_gases, best.macro_f1_ci_low, best.macro_f1_ci_high, color=ps.METHOD.loc["ML", "colour_hex"],
                    alpha=0.18, lw=0, zorder=1, label="95 % bootstrap interval of the best combination")
    ax.plot(best.n_gases, best.macro_f1, "-o", color=ps.METHOD.loc["ML", "colour_hex"], ms=4, zorder=3,
            label="best combination of each size")
    ref = point[f_full] - DELTA
    ax.axhline(ref, color=ps.INK["text"], lw=0.8, ls="--", zorder=1)
    ax.text(1.0, ref + 0.012, f"five-gas macro-F1 minus tolerance ({point[f_full]:.3f} - {DELTA:.2f})", fontsize=7)
    mp = t49[t49.subset_id == minimum["subset"]].iloc[0]
    ax.annotate(f"minimum panel: {mp.subset_id}", (mp.n_gases, mp.macro_f1), xytext=(-170, 22), textcoords="offset points",
                fontsize=7, arrowprops={"arrowstyle": "-", "color": ps.INK["muted"], "lw": 0.6})
    ax.set_xticks(range(1, 6))
    ax.set_xlim(0.7, 5.3)
    ax.set_ylim(0, 1)
    ax.set_xlabel("Number of gases available [-]")
    ax.set_ylabel("Macro-F1 [-]")
    ax.legend(loc="lower right", frameon=False)
    fig.tight_layout()
    ps.save(fig, "F4_16_accuracy_vs_number_of_gases",
            t49[["subset_id", "n_gases", "macro_f1", "macro_f1_ci_low", "macro_f1_ci_high"]].round(4))

    # Figure 4.17 - gas-subset matrix (UpSet-style)
    order = t49.sort_values("macro_f1", ascending=False).reset_index(drop=True)
    x = np.arange(len(order))
    fig, (a1, a2, a3) = plt.subplots(3, 1, figsize=(ps.FULL_WIDTH, 13 * ps.CM), sharex=True,
                                     gridspec_kw={"height_ratios": [3, 1.6, 1.0], "hspace": 0.08})
    a1.bar(x, order.macro_f1, color=ps.METHOD.loc["ML", "colour_hex"], width=0.7)
    a1.errorbar(x, order.macro_f1, yerr=[order.macro_f1 - order.macro_f1_ci_low, order.macro_f1_ci_high - order.macro_f1],
                fmt="none", ecolor=ps.INK["text"], elinewidth=0.6, capsize=1.5)
    a1.axhline(ref, color=ps.INK["text"], lw=0.8, ls="--")
    a1.set_ylabel("ML macro-F1 [-]")
    a1.set_ylim(0, 1)
    for j, g in enumerate(GASES):
        has = order[f"has_{g}"].to_numpy()
        a2.scatter(x[has], np.full(has.sum(), j), s=16, color=ps.INK["text"], zorder=3)
        a2.scatter(x[~has], np.full((~has).sum(), j), s=16, color=ps.INK["grid"], zorder=2)
    for i in range(len(order)):
        js = [j for j, g in enumerate(GASES) if order.loc[i, f"has_{g}"]]
        if len(js) > 1:
            a2.plot([i, i], [min(js), max(js)], color=ps.INK["text"], lw=0.8, zorder=2)
    a2.set_yticks(range(5))
    a2.set_yticklabels(GASES)
    a2.set_ylim(-0.6, 4.6)
    a2.grid(False)
    for j, (m, lab) in enumerate(METHODS):
        u = order.conventional_usable.str.contains(lab, regex=False).to_numpy()
        a3.scatter(x[u], np.full(u.sum(), j), marker="|", s=60, color=ps.METHOD.loc[m, "colour_hex"])
    a3.set_yticks(range(3))
    a3.set_yticklabels([lab + " usable" for _, lab in METHODS])
    a3.set_ylim(-0.6, 2.6)
    a3.grid(False)
    a3.set_xticks(x)
    a3.set_xticklabels([str(int(v)) for v in order.n_gases], fontsize=6)
    a3.set_xlabel("Gas combinations, best to worst (number = gases in the combination) [-]")
    fig.align_ylabels()
    ps.save(fig, "F4_17_gas_subset_matrix",
            order[["subset_id", "n_gases", "macro_f1", "macro_f1_ci_low", "macro_f1_ci_high", "conventional_usable"]
                  + [f"has_{g}" for g in GASES]].round(4))

    show = t49[["subset_id", "n_gases", "macro_f1", "macro_f1_ci_low", "macro_f1_ci_high", "loss", "loss_ci_low",
                "loss_ci_high", "within_tolerance", "fold_loss_t_high", "conventional_usable"]].round(4)
    rep = ["# Step 27 report - minimum gas panel", "", f"delta = {DELTA} (approved item 13); B = {B}; seed {SEED}; n = {n}.", "",
           "Summary: " + json.dumps(summary, default=float), "", "## Table 4.9", "", md_table(show), ""]
    (INTERIM / "step27_report.md").write_text("\n".join(rep), encoding="utf-8")
    print("\n".join(rep))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
