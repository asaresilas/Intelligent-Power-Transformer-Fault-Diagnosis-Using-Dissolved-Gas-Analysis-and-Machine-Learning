"""Roadmap Step 20 [Claude Code] - summarise the nested cross-validation and check reproducibility.

Input : 07_Experiments/<run>/fold_metrics.csv and predictions.csv (written by step20_nested_cv.py).
Do    : (1) completeness: 6 models x 4 feature sets x 50 outer folds = 1200 tasks, every development record predicted
        exactly once per repeat, model and feature set; (2) Table 4.4: mean and SD over the 50 outer folds of macro-F1
        (primary) and the secondary measures, plus the average rank per fold over the 24 model-feature combinations
        (descriptive; the Friedman/Nemenyi tests are Step 30); (3) reproducibility: re-run saved tasks from their
        configuration and compare predictions and probabilities (roadmap check for Step 20).
Output: 11_Results/tables/T4_4_cv_results.csv, 07_Experiments/<run>/reproducibility_check.csv,
        03_Data/interim/step20_report.md
Note  : no model is selected here - Step 21 applies the written selection rule.
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
import tempfile
from datetime import date
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "data_prep"))

import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402

import step20_nested_cv as s20  # noqa: E402
from common import INTERIM, PROJECT_ROOT, md_table, verify_data_version  # noqa: E402

MODEL_ORDER = ["majority", "logistic_regression", "svm", "random_forest", "xgboost", "mlp"]
MEASURES = ["macro_f1", "balanced_accuracy", "accuracy", "kappa", "mcc", "macro_f1_merged_T12"]
REPRO_TASKS = [("F4", "xgboost", "rep01", 1), ("F1", "svm", "rep07", 3), ("F3", "mlp", "rep10", 5),
               ("F2", "random_forest", "rep04", 2)]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--run", default="2026-10-11_nestedcv_v1")
    ap.add_argument("--table-only", action="store_true", help="rebuild Table 4.4 only (Step 32); skip the reproducibility re-fits")
    a = ap.parse_args()
    if verify_data_version():
        raise SystemExit("data version 1.0 changed")
    run_dir = PROJECT_ROOT / "07_Experiments" / a.run
    fm = pd.read_csv(run_dir / "fold_metrics.csv")
    preds = pd.read_csv(run_dir / "predictions.csv")
    dev = s20.development_data()

    # (1) completeness
    n_expected = len(MODEL_ORDER) * 4 * 50
    per_rep = preds.groupby(["feature_set", "model", "rep"]).record_id.agg(["count", "nunique"])
    complete = (len(fm) == n_expected and (per_rep["count"] == len(dev)).all() and (per_rep["nunique"] == len(dev)).all())
    warn_tasks = int((fm.warnings != "{}").sum())

    # (2) Table 4.4
    fm["combo"] = fm.feature_set + "/" + fm.model
    fm["rank"] = fm.groupby(["rep", "fold"]).macro_f1.rank(ascending=False, method="average")
    rows = []
    for (fs, m), g in fm.groupby(["feature_set", "model"]):
        rec = {"feature_set": fs, "model": m, "n_folds": len(g)}
        for k in MEASURES:
            rec[f"{k}_mean"] = round(g[k].mean(), 4)
            rec[f"{k}_sd"] = round(g[k].std(ddof=1), 4)
        for c in s20.CLASS_NAMES.values():
            rec[f"f1_{c}_mean"] = round(g[f"f1_{c}"].mean(), 4)
        rec["average_rank"] = round(g["rank"].mean(), 2)
        rec["most_chosen_setting"] = g.best_params.value_counts().index[0]
        rows.append(rec)
    t44 = pd.DataFrame(rows)
    t44["model"] = pd.Categorical(t44.model, MODEL_ORDER, ordered=True)
    t44 = t44.sort_values(["feature_set", "model"]).reset_index(drop=True)
    out = PROJECT_ROOT / "11_Results" / "tables" / "T4_4_cv_results.csv"
    t44.to_csv(out, index=False)
    if a.table_only:
        return 0

    # (3) reproducibility: re-run saved tasks into a temporary folder and compare
    rep_rows = []
    with tempfile.TemporaryDirectory() as tmp:
        (Path(tmp) / "tasks").mkdir()
        for fs, m, rep, k in REPRO_TASKS:
            s20.run_task(fs, m, rep, k, tmp)
            name = f"{fs}_{m}_{rep}_f{k}"
            new = pd.read_csv(Path(tmp) / "tasks" / f"{name}_pred.csv")
            old = pd.read_csv(run_dir / "tasks" / f"{name}_pred.csv")
            pcols = [c for c in old.columns if c.startswith("p_")]
            same_pred = bool((new.y_pred.to_numpy() == old.y_pred.to_numpy()).all())
            max_dp = float(np.abs(new[pcols].to_numpy() - old[pcols].to_numpy()).max())
            jn, jo = (json.loads((d / "tasks" / f"{name}.json").read_text()) for d in (Path(tmp), run_dir))
            rep_rows.append({"task": name, "same_predictions": same_pred, "max_probability_difference": max_dp,
                             "same_best_setting": jn["best_params"] == jo["best_params"],
                             "same_macro_f1": jn["macro_f1"] == jo["macro_f1"]})
    rp = pd.DataFrame(rep_rows)
    rp.to_csv(run_dir / "reproducibility_check.csv", index=False)
    repro_ok = bool(rp.same_predictions.all() and rp.same_best_setting.all() and rp.same_macro_f1.all()
                    and (rp.max_probability_difference <= 1e-12).all())

    checks = {"data_version_ok": True, "tasks": int(len(fm)), "tasks_expected": n_expected,
              "every_record_once_per_repeat": bool(complete), "tasks_with_warnings": warn_tasks,
              "prediction_rows": int(len(preds)), "reproducible": repro_ok, "repro_tasks": int(len(rp)),
              "max_probability_difference": float(rp.max_probability_difference.max())}
    (run_dir / "step20_checks.json").write_text(json.dumps(checks, indent=1), encoding="utf-8")
    info = json.loads((run_dir / "run_info.json").read_text())
    show = t44[["feature_set", "model", "macro_f1_mean", "macro_f1_sd", "balanced_accuracy_mean", "kappa_mean",
                "mcc_mean", "average_rank"]]
    report = [
        "# Step 20 report - nested cross-validation", "",
        f"Run date: {date.today().isoformat()}. Run folder: `07_Experiments/{a.run}` (start {info.get('start')}, end "
        f"{info.get('end')}, {info.get('jobs')} parallel workers). Data version 1.0 verified. Test sets opened: no.", "",
        f"Completeness: {len(fm)} of {n_expected} tasks; every development record predicted once per repeat, model and "
        f"feature set: {'PASS' if complete else 'FAIL'}. Tasks with any warning: {warn_tasks}.", "",
        "## Table 4.4 - cross-validation results (mean and SD over 50 outer folds)", "", md_table(show), "",
        "Average rank: rank of each model-feature combination within every outer fold by macro-F1 (1 = best), averaged "
        "over the 50 folds (descriptive; the Friedman and Nemenyi tests follow in Step 30). No model is selected here.", "",
        "## Reproducibility (saved tasks re-run from their configuration)", "", md_table(rp), "",
        f"Reproducibility: {'PASS' if repro_ok else 'FAIL'}.", "",
    ]
    (INTERIM / "step20_report.md").write_text("\n".join(report), encoding="utf-8")
    print("\n".join(report))
    return 0 if (complete and repro_ok) else 1


if __name__ == "__main__":
    raise SystemExit(main())
