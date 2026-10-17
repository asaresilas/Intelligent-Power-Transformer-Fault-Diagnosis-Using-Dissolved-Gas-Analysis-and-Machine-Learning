"""Roadmap Step 19 [Claude Code] - build the preprocessing and feature pipelines.

Input : 03_Data/processed/dga_master.csv and folds.csv (data version 1.0, verified first); configs/ml_config.yaml.
Do    : build one scikit-learn pipeline per feature set (F1-F4) and model (6) = 24 pipelines; run each once on the
        training part of fold 1 of repeat 1 as a working check (fit, predict, predict_proba). NO performance score is
        computed or reported here - performance is measured only in Step 20 (nested cross-validation).
Output: 06_Python_ML/configs/pipeline_catalog.csv (pipelines, features, settings), 03_Data/interim/step19_report.md
Check : every pipeline runs; features finite after imputation; probabilities sum to 1; the leakage tests in
        tests/test_pipelines.py pass (imputer, scaler and class weights see training rows only).
"""
from __future__ import annotations

import sys
import time
import warnings
from datetime import date
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "data_prep"))

import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402

from common import INTERIM, PROCESSED, PROJECT_ROOT, md_table, verify_data_version  # noqa: E402
from features import GASES  # noqa: E402
from pipelines import load_config, make_pipeline, param_grid  # noqa: E402


def development_data():
    problems = verify_data_version()
    if problems:
        raise SystemExit("data version 1.0 changed: " + "; ".join(problems))
    m = pd.read_csv(PROCESSED / "dga_master.csv")
    dev = m[m.data_role == "development"].reset_index(drop=True)
    folds = pd.read_csv(PROCESSED / "folds.csv")
    chk = dev[["record_id", "class_code"]].merge(folds[["record_id", "class_code"]], on="record_id")
    assert len(chk) == len(dev) and (chk.class_code_x == chk.class_code_y).all(), "folds.csv and master disagree"
    dev = dev.merge(folds.drop(columns=["class_code", "seed"]), on="record_id", how="left", validate="one_to_one")
    assert dev.rep01.notna().all()
    return dev


def main() -> int:
    cfg = load_config()
    dev = development_data()
    X, y = dev[GASES], dev[cfg["target"]].astype(int).to_numpy()
    tr, va = dev.rep01 != 1, dev.rep01 == 1
    rows = []
    for fs in cfg["feature_sets"]:
        for model in cfg["models"]:
            pipe = make_pipeline(fs, model, config=cfg)
            t0 = time.perf_counter()
            with warnings.catch_warnings(record=True) as w:
                warnings.simplefilter("always")
                pipe.fit(X[tr], y[tr])
                pred = pipe.predict(X[va])
                proba = pipe.predict_proba(X[va])
            secs = time.perf_counter() - t0
            Z = pipe[:-1].transform(X[va])
            grid = param_grid(model, cfg)
            n_comb = int(np.prod([len(v) for v in grid.values()])) if grid else 1
            rows.append({
                "feature_set": fs, "model": model,
                "n_features": len(pipe.named_steps["features"].get_feature_names_out()),
                "features": " ".join(pipe.named_steps["features"].get_feature_names_out()),
                "weighted": cfg["models"][model]["weighted"],
                "grid_size": n_comb,
                "runs": "yes" if set(pred) <= set(np.unique(y[tr])) else "no",
                "finite_features": bool(np.isfinite(Z).all()),
                "proba_sum_to_1": bool(np.allclose(proba.sum(axis=1), 1.0)),
                "warnings": len(w), "seconds": round(secs, 2),
            })
    cat = pd.DataFrame(rows)
    out = PROJECT_ROOT / "06_Python_ML" / "configs" / "pipeline_catalog.csv"
    cat.to_csv(out, index=False)
    ok = (cat.runs == "yes").all() and cat.finite_features.all() and cat.proba_sum_to_1.all()
    report = [
        "# Step 19 report - preprocessing and feature pipelines", "",
        f"Run date: {date.today().isoformat()}. Script: `06_Python_ML/src/ml/step19_build_pipelines.py`. "
        f"Data version 1.0 verified: PASS. Development records: {len(dev)}; working check on repeat 1, fold 1 "
        f"(training {int(tr.sum())}, held out {int(va.sum())}). No performance score is computed in this step.", "",
        "Pipeline: FeatureBuilder (F1-F4, stateless) -> SimpleImputer(median) -> StandardScaler -> "
        "BalancedClassifier (class weights from the training fold, D15).", "",
        "## Pipeline catalogue", "", md_table(cat.drop(columns=["features"])), "",
        f"All pipelines run, give finite features and probabilities that sum to 1: {'PASS' if ok else 'FAIL'}.", "",
        "## Features per set", "",
        md_table(cat.drop_duplicates("feature_set")[["feature_set", "n_features", "features"]]), "",
    ]
    (INTERIM / "step19_report.md").write_text("\n".join(report), encoding="utf-8")
    print(md_table(cat.drop(columns=["features"])))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
