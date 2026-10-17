"""Roadmap Step 22 [Claude Code] - fit the final model and predict the test sets once.

Input : the pipeline chosen in Step 21 (07_Experiments/model_selection.md); development records of dga_master.csv with the
        near-duplicate groups of folds.csv; the three test sets (internal test, IEC TC 10 benchmark, Li 2019) - used ONCE here.
Do    : (1) tune the chosen pipeline on all 439 development records (GridSearchCV, StratifiedGroupKFold(5), groups, seed
        20261010, macro-F1 - the inner procedure of Step 20) and refit it on all of them; (2) save the fitted pipeline with its
        SHA-256 BEFORE any test record is predicted; (3) predict all 388 test records in one call; (4) first-look scores on the
        approved evaluation sets (decision D19). Formal measures with confidence intervals and the comparison with the
        conventional methods are Steps 28-30.
Output: 07_Experiments/<date>_final_fit/ (final_pipeline.joblib, final_fit.json, inner_cv_results.csv),
        11_Results/ml/ml_predictions.csv, 11_Results/ml/ml_first_look.csv, 11_Results/ml/test_set_access.log,
        03_Data/interim/step22_report.md
Check : the log shows the test sets were predicted only in this step; the program refuses to run a second time.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import time
import warnings
from datetime import datetime
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "data_prep"))

import joblib  # noqa: E402
import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402
from sklearn.metrics import (accuracy_score, balanced_accuracy_score, cohen_kappa_score, confusion_matrix,  # noqa: E402
                             f1_score, matthews_corrcoef)

import step20_nested_cv as s20  # noqa: E402
from common import INTERIM, PROCESSED, PROJECT_ROOT, md_table, verify_data_version  # noqa: E402

ML_DIR = PROJECT_ROOT / "11_Results" / "ml"
PRED = ML_DIR / "ml_predictions.csv"
LOG = ML_DIR / "test_set_access.log"
SEVEN = ["Normal", "PD", "D1", "D2", "T1", "T2", "T3"]
MERGED5 = ["PD", "D1", "D2", "T12", "T3"]
TO_MERGED = {"Normal": "Normal", "PD": "PD", "D1": "D1", "D2": "D2", "T1": "T12", "T2": "T12", "T3": "T3"}


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def log(msg: str) -> None:
    with open(LOG, "a", encoding="utf-8") as fh:
        fh.write(f"{datetime.now().isoformat(timespec='seconds')}  {msg}\n")


def chosen_pipeline() -> tuple[str, str]:
    text = (PROJECT_ROOT / "07_Experiments" / "model_selection.md").read_text(encoding="utf-8")
    m = re.search(r"Decision: \*\*(\w+) on feature set (F\d)\*\*", text)
    assert m, "no decision in model_selection.md"
    return m.group(1), m.group(2)


def scores(y_true: pd.Series, y_pred: pd.Series, labels: list[str]) -> dict:
    return {"n": len(y_true), "macro_f1": f1_score(y_true, y_pred, labels=labels, average="macro", zero_division=0),
            "accuracy": accuracy_score(y_true, y_pred), "balanced_accuracy": balanced_accuracy_score(y_true, y_pred),
            "kappa": cohen_kappa_score(y_true, y_pred), "mcc": matthews_corrcoef(y_true, y_pred),
            "n_predicted_normal": int((y_pred == "Normal").sum())}


# evaluation sets of decision D19: (name, role, filter column or None, label column, class list, primary?)
EVAL_SETS = [
    ("Internal test - independent", "internal_test", "independent_of_benchmark", "class_name", SEVEN, True),
    ("Internal test - all", "internal_test", None, "class_name", SEVEN, False),
    ("IEC TC 10 - power transformers", "benchmark", "in_scope_primary", "class_merged", MERGED5, True),
    ("IEC TC 10 - all", "benchmark", None, "class_merged", MERGED5, False),
    ("Li 2019 - independent", "external_test", "independent_of_benchmark", "class_name", SEVEN[1:], True),
    ("Li 2019 - all (merged classes)", "external_test", None, "class_merged", MERGED5, False),
]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--run", default=f"{datetime.now():%Y-%m-%d}_final_fit")
    ap.add_argument("--score-only", action="store_true", help="recompute first-look scores from saved predictions")
    a = ap.parse_args()
    if a.score_only:
        return first_look(PROJECT_ROOT / "07_Experiments" / a.run)
    if PRED.exists():
        raise SystemExit("ml_predictions.csv exists - the test sets have already been predicted; Step 22 runs only once")
    problems = verify_data_version()
    if problems:
        raise SystemExit("data version 1.0 changed: " + "; ".join(problems))
    from sklearn.model_selection import GridSearchCV, StratifiedGroupKFold

    from features import GASES
    from pipelines import load_config, make_pipeline, param_grid
    import sklearn

    cfg = load_config()
    model, fs = chosen_pipeline()
    ML_DIR.mkdir(parents=True, exist_ok=True)
    run_dir = PROJECT_ROOT / "07_Experiments" / a.run
    run_dir.mkdir(parents=True, exist_ok=False)
    log(f"Step 22 started; selected pipeline {model} / {fs} (from model_selection.md); data version 1.0 verified")

    # (1) tune and fit on development records only
    dev = s20.development_data()
    X, y, grp = dev[GASES], dev[cfg["target"]].astype(int).to_numpy(), dev["group_id"].to_numpy()
    inner = StratifiedGroupKFold(n_splits=cfg["validation"]["inner_folds"], shuffle=True, random_state=cfg["seed"])
    gs = GridSearchCV(make_pipeline(fs, model, config=cfg), param_grid(model, cfg),
                      scoring=cfg["validation"]["tuning_score"], cv=inner, n_jobs=-1, refit=True, error_score="raise")
    t0 = time.perf_counter()
    with warnings.catch_warnings(record=True) as wl:
        warnings.simplefilter("always")
        gs.fit(X, y, groups=grp)
    secs = time.perf_counter() - t0
    best = gs.best_estimator_
    cvr = pd.DataFrame(gs.cv_results_)
    keep = [c for c in cvr.columns if c.startswith("param_") or c in ("mean_test_score", "std_test_score", "rank_test_score")]
    cvr[keep].to_csv(run_dir / "inner_cv_results.csv", index=False)

    # (2) save the fitted pipeline before any test record is predicted
    pkl = run_dir / "final_pipeline.joblib"
    joblib.dump(best, pkl)
    pkl_hash = sha256(pkl)
    info = {"model": model, "feature_set": fs, "n_development": int(len(dev)),
            "best_params": {k.replace("clf__estimator__", ""): v for k, v in gs.best_params_.items()},
            "inner_macro_f1": float(gs.best_score_), "inner_seed": cfg["seed"], "fit_seconds": round(secs, 1),
            "warnings": len(wl), "pipeline_sha256": pkl_hash, "scikit_learn": sklearn.__version__,
            "data_version": cfg["data_version"], "fitted": datetime.now().isoformat(timespec="seconds")}
    (run_dir / "final_fit.json").write_text(json.dumps(info, indent=1, default=str), encoding="utf-8")
    log(f"final pipeline fitted on {len(dev)} development records and saved: {pkl.relative_to(PROJECT_ROOT).as_posix()} "
        f"SHA-256 {pkl_hash}; best setting {info['best_params']}")

    # (3) open the test sets and predict them, once, in one call
    master = pd.read_csv(PROCESSED / "dga_master.csv")
    test = master[master.data_role != "development"].reset_index(drop=True)
    log("TEST SETS OPENED for ML prediction: " + ", ".join(f"{r} {n}" for r, n in test.data_role.value_counts().items()))
    proba = best.predict_proba(test[GASES])
    pred = best.predict(test[GASES])
    classes = [s20.CLASS_NAMES[int(c)] for c in best.named_steps["clf"].classes_]
    out = test[["record_id", "source_id", "data_role", "class_name", "class_merged", "in_scope_primary",
                "independent_of_benchmark"]].copy()
    out["y_pred"] = [s20.CLASS_NAMES[int(c)] for c in pred]
    out["y_pred_merged"] = out.y_pred.map(TO_MERGED)
    for j, c in enumerate(classes):
        out[f"p_{c}"] = proba[:, j]
    out["model"], out["feature_set"], out["data_version"] = model, fs, cfg["data_version"]
    out.to_csv(PRED, index=False)
    log(f"predictions written: {PRED.relative_to(PROJECT_ROOT).as_posix()} ({len(out)} rows) SHA-256 {sha256(PRED)}")
    return first_look(run_dir)


def first_look(run_dir: Path) -> int:
    """(4) first-look scores on the approved evaluation sets, from the saved predictions (never predicts again)."""
    info = json.loads((run_dir / "final_fit.json").read_text(encoding="utf-8"))
    out = pd.read_csv(PRED)
    model, fs, pkl_hash = info["model"], info["feature_set"], info["pipeline_sha256"]
    pkl = run_dir / "final_pipeline.joblib"
    rows, cms = [], []
    for name, role, filt, lab, labels, primary in EVAL_SETS:
        s = out[out.data_role == role]
        if filt:
            s = s[s[filt]]
        yp = s.y_pred_merged if lab == "class_merged" else s.y_pred
        assert s[lab].notna().all(), f"{name}: records without a {lab} label"
        rec ={"evaluation_set": name, "primary": primary, "classes": "/".join(labels), **scores(s[lab], yp, labels)}
        rows.append(rec)
        if primary:
            cm = confusion_matrix(s[lab], yp, labels=labels + (["Normal"] if "Normal" not in labels else []))
            cms.append((name, labels + (["Normal"] if "Normal" not in labels else []), cm))
    fl = pd.DataFrame(rows)
    fl.to_csv(ML_DIR / "ml_first_look.csv", index=False)
    pd.DataFrame([{"evaluation_set": nm, "true": lt, "predicted": lp, "count": int(cm[i, j])}
                  for nm, lab, cm in cms for i, lt in enumerate(lab) for j, lp in enumerate(lab)]
                 ).to_csv(ML_DIR / "ml_first_look_confusion.csv", index=False)
    log(f"first-look scores written from the saved predictions: 11_Results/ml/ml_first_look.csv")

    rep = ["# Step 22 report - final fit and one-time test prediction", "",
           f"Selected pipeline (Step 21): {model} on {fs}. Tuned on all {info['n_development']} development records "
           f"(inner StratifiedGroupKFold(5), seed {info['inner_seed']}): best setting {info['best_params']}, inner macro-F1 "
           f"{info['inner_macro_f1']:.4f}; fit time {info['fit_seconds']:.0f} s; warnings {info['warnings']}.", "",
           f"Fitted pipeline: `{pkl.relative_to(PROJECT_ROOT).as_posix()}` SHA-256 {pkl_hash} (saved before any test prediction).", "",
           f"Test records predicted once: {len(out)}. Log: `11_Results/ml/test_set_access.log`.", "",
           "## First-look scores (formal measures with confidence intervals: Step 29)", "", md_table(fl.round(4)), ""]
    for name, labels, cm in cms:
        rep += [f"### Confusion matrix - {name} (rows true, columns predicted)", "",
                md_table(pd.DataFrame(cm, index=labels, columns=labels).rename_axis("true").reset_index()), ""]
    (INTERIM / "step22_report.md").write_text("\n".join(rep), encoding="utf-8")
    print("\n".join(rep))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
