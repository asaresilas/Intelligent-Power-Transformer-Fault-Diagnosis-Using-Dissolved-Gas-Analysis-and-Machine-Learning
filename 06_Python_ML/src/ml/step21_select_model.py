"""Roadmap Step 21 [Claude Code] - select the final model by the written rule.

Input : 07_Experiments/<run>/fold_metrics.csv (Step 20; development records only).
Rule  : Analysis Plan 5.4 - the highest mean outer-fold macro-F1; if the best and the next pipeline are not
        significantly different (corrected resampled t-test, Eq. 28; Nadeau and Bengio, 2003), the simpler one is chosen.
        Details fixed in advance in decision D18 (candidates, "next", test settings, simplicity order).
Output: 07_Experiments/model_selection.md, 07_Experiments/model_selection_tests.csv
Check : the choice follows the written rule and is made before any test set is opened (no ML test prediction exists,
        Step 20 run_info says test_sets_opened = false).
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "data_prep"))

import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402
from scipy import stats  # noqa: E402

from common import PROJECT_ROOT, md_table, verify_data_version  # noqa: E402

# D18 (4): simplicity order fixed before any Step 20 result was read
FAMILY_ORDER = ["logistic_regression", "svm", "random_forest", "xgboost", "mlp"]
N_FEATURES = {"F1": 5, "F2": 5, "F3": 8, "F4": 18}
ALPHA = 0.05
K, R = 5, 10


def corrected_resampled_t(d: np.ndarray, test_train_ratio: float, k: int = K, r: int = R) -> tuple[float, float]:
    """Eq. 28: t = mean(d) / sqrt((1/(k r) + n_test/n_train) * var(d)); two-sided p from t with k r - 1 df."""
    d = np.asarray(d, dtype=float)
    assert len(d) == k * r
    var = d.var(ddof=1)
    if var == 0:
        return (0.0, 1.0) if d.mean() == 0 else (float(np.sign(d.mean()) * np.inf), 0.0)
    t = d.mean() / np.sqrt((1 / (k * r) + test_train_ratio) * var)
    return float(t), float(2 * stats.t.sf(abs(t), k * r - 1))


def simplicity(fs: str, model: str) -> tuple[int, int]:
    return FAMILY_ORDER.index(model), N_FEATURES[fs]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--run", default="2026-10-11_nestedcv_v1")
    a = ap.parse_args()
    if verify_data_version():
        raise SystemExit("data version 1.0 changed")
    exp = PROJECT_ROOT / "07_Experiments"
    run_dir = exp / a.run
    info = json.loads((run_dir / "run_info.json").read_text())
    ml_pred = PROJECT_ROOT / "11_Results" / "ml" / "ml_predictions.csv"
    assert info["test_sets_opened"] is False and not ml_pred.exists(), "a test set has already been opened"

    fm = pd.read_csv(run_dir / "fold_metrics.csv")
    fm = fm[fm.model.isin(FAMILY_ORDER)]                       # D18 (1): baseline is not a candidate
    wide = fm.pivot_table(index=["rep", "fold"], columns=["feature_set", "model"], values="macro_f1")
    assert wide.shape == (K * R, 20) and not wide.isna().any().any()
    ratio = fm.n_test.mean() / fm.n_train.mean()
    means = wide.mean().sort_values(ascending=False)
    best, nxt = means.index[0], means.index[1]

    rows = []
    for cand in means.index:
        d = (wide[best] - wide[cand]).to_numpy()
        t, p = corrected_resampled_t(d, ratio) if cand != best else (np.nan, np.nan)
        rows.append({"feature_set": cand[0], "model": cand[1], "mean_macro_f1": round(means[cand], 4),
                     "sd_macro_f1": round(wide[cand].std(ddof=1), 4), "mean_difference_to_best": round(d.mean(), 4),
                     "t": round(t, 3) if cand != best else np.nan, "p": round(p, 4) if cand != best else np.nan,
                     "significantly_worse_than_best": bool(p < ALPHA) if cand != best else False,
                     "family_rank": simplicity(*cand)[0] + 1, "n_features": simplicity(*cand)[1]})
    tests = pd.DataFrame(rows)
    tests.to_csv(exp / "model_selection_tests.csv", index=False)

    t_next = tests.iloc[1]
    if t_next.significantly_worse_than_best:
        chosen, reason = best, "the best pipeline is significantly better than the next, so the best is chosen"
    elif simplicity(*nxt) < simplicity(*best):
        chosen, reason = nxt, "best and next are not significantly different and the next is simpler, so the next is chosen"
    else:
        chosen, reason = best, ("best and next are not significantly different; the best is at least as simple, "
                                "so the best is chosen")
    not_diff = tests[~tests.significantly_worse_than_best]
    fm_ch = fm[(fm.feature_set == chosen[0]) & (fm.model == chosen[1])]
    settings = fm_ch.best_params.value_counts()

    md = [
        "# Step 21 - model selection by the written rule", "",
        f"Date: {datetime.now().isoformat(timespec='seconds')}. Input: `07_Experiments/{a.run}/fold_metrics.csv` "
        f"(50 outer folds, development records only). Data version 1.0 verified.", "",
        "Rule (Analysis Plan 5.4 and 7.1; details in decision D18, fixed before the Step 20 results were read): the "
        "highest mean outer-fold macro-F1; if the best and the next pipeline are not significantly different "
        "(corrected resampled t-test, Eq. 28, two-sided, alpha 0.05, 49 df), the simpler one is chosen. Simplicity: "
        "logistic regression < SVM < Random Forest < XGBoost < MLP, then fewer input features.", "",
        f"Test-to-training size ratio used in Eq. 28: {fm.n_test.mean():.2f} / {fm.n_train.mean():.2f} = {ratio:.4f}.", "",
        "## Best and next", "",
        f"- Best: **{best[1]} on {best[0]}**, mean macro-F1 {means[best]:.4f}",
        f"- Next: **{nxt[1]} on {nxt[0]}**, mean macro-F1 {means[nxt]:.4f}",
        f"- Mean difference {t_next.mean_difference_to_best:.4f}; t = {t_next.t:.3f}; p = {t_next.p:.4f}", "",
        f"## Decision: **{chosen[1]} on feature set {chosen[0]}**", "", f"Reason: {reason}.", "",
        "Settings most often chosen by the inner loop for this pipeline (fold count):", "",
        md_table(settings.rename_axis("setting").reset_index(name="folds").head(5)), "",
        "The final settings are tuned again on all development records in Step 22 (roadmap), with the same inner "
        "procedure.", "",
        "## All candidates compared with the best (supporting information)", "",
        md_table(tests), "",
        f"Pipelines not significantly worse than the best (no multiplicity correction, descriptive only): "
        f"{len(not_diff)} of {len(tests)}.", "",
        f"Test sets opened before this choice: no (Step 20 run_info test_sets_opened = false; "
        f"`11_Results/ml/ml_predictions.csv` does not exist).", "",
    ]
    (exp / "model_selection.md").write_text("\n".join(md), encoding="utf-8")
    print("\n".join(md))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
