"""Roadmap Step 20 [Claude Code] - train and tune the classifiers with nested cross-validation.

Input : development records of dga_master.csv + folds.csv (data version 1.0, verified); configs/ml_config.yaml;
        the 24 pipelines of Step 19.
Design (Analysis Plan 5.4, approved item 10; decision D17):
  outer loop  the 50 fixed folds of folds.csv (5 folds x 10 repeats, stratified, near-duplicate groups kept together)
  inner loop  GridSearchCV with StratifiedGroupKFold(5) inside each outer training part (groups = near-duplicate
              groups, as in the outer loop); seed = 20261010 + 1000 x repeat + fold; tuning score macro-F1
  refit       the best setting is refitted on the whole outer training part and predicts the outer held-out fold
Output: 07_Experiments/<run>/  config.yaml (copy), run_info.json (data version, seed, versions, start/end),
        tasks/<feature_set>_<model>_<rep>_f<k>.json (best setting, inner score, metrics, warnings, seconds) and
        tasks/<...>_pred.csv (record, true class, predicted class, probability of every class);
        fold_metrics.csv and predictions.csv (all tasks); 11_Results/tables/T4_4_cv_results.csv; step20_report.md.
Only development records are read - the three test sets are not opened in this step (roadmap Step 22 rule).
Resumable: a task whose result file exists is skipped. Run:  python -I step20_nested_cv.py [--jobs 6] [--run NAME]
"""
from __future__ import annotations

import argparse
import json
import platform
import shutil
import sys
import time
import warnings
from datetime import datetime
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "data_prep"))

import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402

from common import PROCESSED, PROJECT_ROOT, verify_data_version  # noqa: E402

CLASS_NAMES = {0: "Normal", 1: "PD", 2: "D1", 3: "D2", 4: "T1", 5: "T2", 6: "T3"}
MERGE = {0: "Normal", 1: "PD", 2: "D1", 3: "D2", 4: "T12", 5: "T12", 6: "T3"}
_DEV = None


def development_data() -> pd.DataFrame:
    """Development records with their fold numbers. Refuses to return any test-role record."""
    global _DEV
    if _DEV is None:
        m = pd.read_csv(PROCESSED / "dga_master.csv")
        dev = m[m.data_role == "development"].reset_index(drop=True)
        folds = pd.read_csv(PROCESSED / "folds.csv")
        chk = dev[["record_id", "class_code"]].merge(folds[["record_id", "class_code"]], on="record_id")
        assert len(chk) == len(dev) and (chk.class_code_x == chk.class_code_y).all()
        dev = dev.merge(folds.drop(columns=["class_code", "seed"]), on="record_id", validate="one_to_one")
        assert set(dev.data_role) == {"development"}
        _DEV = dev
    return _DEV


def metrics(y, pred) -> dict:
    from sklearn.metrics import (accuracy_score, balanced_accuracy_score, cohen_kappa_score, confusion_matrix,
                                 f1_score, matthews_corrcoef, precision_recall_fscore_support)
    labels = list(CLASS_NAMES)
    p, r, f, s = precision_recall_fscore_support(y, pred, labels=labels, zero_division=0)
    ym, pm = [MERGE[v] for v in y], [MERGE[v] for v in pred]
    out = {
        "macro_f1": f1_score(y, pred, labels=labels, average="macro", zero_division=0),
        "balanced_accuracy": balanced_accuracy_score(y, pred),
        "accuracy": accuracy_score(y, pred),
        "kappa": cohen_kappa_score(y, pred),
        "mcc": matthews_corrcoef(y, pred),
        "macro_f1_merged_T12": f1_score(ym, pm, average="macro", zero_division=0),
        "confusion_matrix": confusion_matrix(y, pred, labels=labels).tolist(),
    }
    for c, pc, rc, fc, sc in zip(labels, p, r, f, s):
        out[f"precision_{CLASS_NAMES[c]}"], out[f"recall_{CLASS_NAMES[c]}"] = pc, rc
        out[f"f1_{CLASS_NAMES[c]}"], out[f"support_{CLASS_NAMES[c]}"] = fc, int(sc)
    return {k: (float(v) if isinstance(v, (np.floating, float)) else v) for k, v in out.items()}


def run_task(fs: str, model: str, rep: str, k: int, run_dir: str) -> str:
    from sklearn.model_selection import GridSearchCV, StratifiedGroupKFold

    from features import GASES
    from pipelines import load_config, make_pipeline, param_grid

    tasks = Path(run_dir) / "tasks"
    name = f"{fs}_{model}_{rep}_f{k}"
    if (tasks / f"{name}.json").exists():
        return name + " (skipped)"
    cfg = load_config()
    dev = development_data()
    tr, va = (dev[rep] != k).to_numpy(), (dev[rep] == k).to_numpy()
    X, y, grp = dev[GASES], dev[cfg["target"]].astype(int).to_numpy(), dev["group_id"].to_numpy()
    rep_no = int(rep[3:])
    inner_seed = cfg["seed"] + 1000 * rep_no + k
    pipe, grid = make_pipeline(fs, model, config=cfg), param_grid(model, cfg)
    t0 = time.perf_counter()
    with warnings.catch_warnings(record=True) as wlist:
        warnings.simplefilter("always")
        if grid:
            inner = StratifiedGroupKFold(n_splits=cfg["validation"]["inner_folds"], shuffle=True, random_state=inner_seed)
            gs = GridSearchCV(pipe, grid, scoring=cfg["validation"]["tuning_score"], cv=inner, n_jobs=1,
                              refit=True, error_score="raise")
            gs.fit(X[tr], y[tr], groups=grp[tr])
            best, best_params, inner_score = gs.best_estimator_, gs.best_params_, float(gs.best_score_)
        else:
            best, best_params, inner_score = pipe.fit(X[tr], y[tr]), {}, float("nan")
        pred = best.predict(X[va])
        proba = best.predict_proba(X[va])
    secs = time.perf_counter() - t0
    wcount = {}
    for w in wlist:
        key = w.category.__name__
        wcount[key] = wcount.get(key, 0) + 1
    res = {"feature_set": fs, "model": model, "rep": rep, "fold": k, "inner_seed": inner_seed,
           "n_train": int(tr.sum()), "n_test": int(va.sum()),
           "best_params": {p.replace("clf__estimator__", ""): (list(v) if isinstance(v, tuple) else v)
                           for p, v in best_params.items()},
           "inner_macro_f1": inner_score, "seconds": round(secs, 2), "warnings": wcount, **metrics(y[va], pred)}
    classes = best.named_steps["clf"].classes_
    pr = pd.DataFrame(proba, columns=[f"p_{CLASS_NAMES[int(c)]}" for c in classes])
    pr.insert(0, "y_pred", pred)
    pr.insert(0, "y_true", y[va])
    pr.insert(0, "record_id", dev.record_id.to_numpy()[va])
    for col, val in [("feature_set", fs), ("model", model), ("rep", rep), ("fold", k)]:
        pr.insert(0, col, val)
    pr.to_csv(tasks / f"{name}_pred.csv", index=False)
    (tasks / f"{name}.json").write_text(json.dumps(res, indent=1), encoding="utf-8")   # written last = task done
    return name


def collect(run_dir: Path) -> tuple[pd.DataFrame, pd.DataFrame]:
    rows = [json.loads(p.read_text(encoding="utf-8")) for p in sorted((run_dir / "tasks").glob("*.json"))]
    fm = pd.DataFrame(rows)
    fm["best_params"] = fm.best_params.map(lambda d: json.dumps(d, sort_keys=True))
    fm["warnings"] = fm.warnings.map(lambda d: json.dumps(d, sort_keys=True))
    fm["confusion_matrix"] = fm.confusion_matrix.map(json.dumps)
    preds = pd.concat([pd.read_csv(p) for p in sorted((run_dir / "tasks").glob("*_pred.csv"))], ignore_index=True)
    return fm, preds


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--jobs", type=int, default=6)
    ap.add_argument("--run", default="2026-10-11_nestedcv_v1")
    ap.add_argument("--limit", type=int, default=0, help="run only the first N tasks (smoke test)")
    a = ap.parse_args()

    problems = verify_data_version()
    if problems:
        raise SystemExit("data version 1.0 changed: " + "; ".join(problems))
    from joblib import Parallel, delayed

    from pipelines import CONFIG, load_config
    cfg = load_config()
    run_dir = PROJECT_ROOT / "07_Experiments" / a.run
    (run_dir / "tasks").mkdir(parents=True, exist_ok=True)
    shutil.copy(CONFIG, run_dir / "config.yaml")
    import sklearn, xgboost, joblib  # noqa: E401
    info = {"run": a.run, "data_version": cfg["data_version"], "seed": cfg["seed"], "jobs": a.jobs,
            "python": platform.python_version(), "scikit_learn": sklearn.__version__, "xgboost": xgboost.__version__,
            "numpy": np.__version__, "pandas": pd.__version__, "joblib": joblib.__version__,
            "machine": platform.processor(), "start": datetime.now().isoformat(timespec="seconds"),
            "development_records": len(development_data()), "test_sets_opened": False}
    (run_dir / "run_info.json").write_text(json.dumps(info, indent=1), encoding="utf-8")

    reps = [f"rep{r:02d}" for r in range(1, 11)]
    order = ["majority", "logistic_regression", "svm", "xgboost", "mlp", "random_forest"]
    tasks = [(fs, m, rep, k) for m in order for fs in cfg["feature_sets"] for rep in reps for k in range(1, 6)]
    if a.limit:
        tasks = tasks[: a.limit]
    log = run_dir / "progress.log"
    done = 0
    with open(log, "a", encoding="utf-8") as fh:
        fh.write(f"start {datetime.now().isoformat(timespec='seconds')} tasks {len(tasks)}\n")
        for name in Parallel(n_jobs=a.jobs, return_as="generator_unordered", batch_size=1)(
                delayed(run_task)(*t, str(run_dir)) for t in tasks):
            done += 1
            fh.write(f"{datetime.now().strftime('%H:%M:%S')} {done}/{len(tasks)} {name}\n")
            fh.flush()
    info["end"] = datetime.now().isoformat(timespec="seconds")
    (run_dir / "run_info.json").write_text(json.dumps(info, indent=1), encoding="utf-8")
    fm, preds = collect(run_dir)
    fm.to_csv(run_dir / "fold_metrics.csv", index=False)
    preds.to_csv(run_dir / "predictions.csv", index=False)
    print(f"tasks finished: {len(fm)}; prediction rows: {len(preds)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
