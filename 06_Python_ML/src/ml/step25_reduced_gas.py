"""Roadmap Step 25 [Claude Code] - retrain the selected pipeline on every gas subset (reduced-gas study).

Input : development records of dga_master.csv + folds.csv (data version 1.0); configs/ml_config.yaml; the pipeline chosen in
        Step 21 (Random Forest, F4).
Design (Analysis Plan Section 8, Eq. 35; decision D22):
  subsets   all 31 non-empty subsets of the five gases
  features  F4 restricted to the subset: log gases in S; percentages of the gases in S (|S| >= 2); log-ratios R1-R5 only
            when both gases are in S; Duval percentages only when CH4, C2H4 and C2H2 are in S. All five gases = F4 exactly.
  validation the nested design of Step 20 on the identical 50 outer folds and inner seeds; tuning score macro-F1
Output: 07_Experiments/<run>/ (config, run_info, tasks/*.json and *_pred.csv, fold_metrics.csv, predictions.csv),
        11_Results/reduced_gas/reduced_gas_subsets.csv and reduced_gas_results.csv, 03_Data/interim/step25_report.md
Check : every subset uses the identical folds of Step 10; the full panel reproduces the Step 20 RF/F4 fold results exactly.
Resumable: a task whose result file exists is skipped.  Run:  python -I step25_reduced_gas.py [--jobs 7]
"""
from __future__ import annotations

import argparse
import itertools
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
from sklearn.base import BaseEstimator, TransformerMixin  # noqa: E402

import step20_nested_cv as s20  # noqa: E402
from common import INTERIM, PROJECT_ROOT, md_table, verify_data_version  # noqa: E402
from features import GASES, RATIOS  # noqa: E402

MODEL, FULL = "random_forest", "F4"
DUVAL = ["CH4", "C2H4", "C2H2"]
OUT = PROJECT_ROOT / "11_Results" / "reduced_gas"


def subsets() -> list[tuple[str, ...]]:
    """The 31 non-empty subsets, ordered by size, then by the order of GASES."""
    return [c for k in range(1, 6) for c in itertools.combinations(GASES, k)]


def subset_id(s: tuple[str, ...]) -> str:
    return "+".join(s)


def subset_feature_names(s: tuple[str, ...]) -> list[str]:
    names = [f"log_{g}" for g in s]
    if len(s) >= 2:
        names += [f"pct_{g}" for g in s]
    names += [f"log_{r}" for r, (a, b) in RATIOS.items() if a in s and b in s]
    if all(g in s for g in DUVAL):
        names += [f"duval_pct_{g}" for g in DUVAL]
    return names


class SubsetFeatureBuilder(BaseEstimator, TransformerMixin):
    """F4 restricted to the gases of one subset (decision D22). Stateless; fit() learns nothing."""

    def __init__(self, gases=tuple(GASES)):
        self.gases = gases

    def fit(self, X, y=None):
        return self

    def transform(self, X):
        g = X if isinstance(X, pd.DataFrame) else pd.DataFrame(np.asarray(X, float), columns=GASES)
        s = tuple(self.gases)
        cols = [np.log10(g[k].to_numpy(float) + 1.0) for k in s]
        if len(s) >= 2:
            tot = sum(g[k].to_numpy(float) for k in s)
            with np.errstate(invalid="ignore", divide="ignore"):
                cols += [np.where(tot > 0, 100.0 * g[k].to_numpy(float) / tot, np.nan) for k in s]
        cols += [np.log10((g[a].to_numpy(float) + 1.0) / (g[b].to_numpy(float) + 1.0))
                 for a, b in RATIOS.values() if a in s and b in s]
        if all(k in s for k in DUVAL):
            tot = sum(g[k].to_numpy(float) for k in DUVAL)
            with np.errstate(invalid="ignore", divide="ignore"):
                cols += [np.where(tot > 0, 100.0 * g[k].to_numpy(float) / tot, np.nan) for k in DUVAL]
        return np.column_stack(cols)

    def get_feature_names_out(self, input_features=None):
        return np.array(subset_feature_names(tuple(self.gases)), dtype=object)


def run_task(gases: tuple[str, ...], rep: str, k: int, run_dir: str) -> str:
    from sklearn.model_selection import GridSearchCV, StratifiedGroupKFold

    from pipelines import load_config, make_pipeline, param_grid

    tasks = Path(run_dir) / "tasks"
    sid = subset_id(gases)
    name = f"{sid}_{rep}_f{k}"
    if (tasks / f"{name}.json").exists():
        return name + " (skipped)"
    cfg = load_config()
    dev = s20.development_data()
    tr, va = (dev[rep] != k).to_numpy(), (dev[rep] == k).to_numpy()
    X, y, grp = dev[GASES], dev[cfg["target"]].astype(int).to_numpy(), dev["group_id"].to_numpy()
    inner_seed = cfg["seed"] + 1000 * int(rep[3:]) + k
    pipe = make_pipeline(FULL, MODEL, config=cfg)
    pipe.set_params(features=SubsetFeatureBuilder(gases))
    t0 = time.perf_counter()
    with warnings.catch_warnings(record=True) as wlist:
        warnings.simplefilter("always")
        inner = StratifiedGroupKFold(n_splits=cfg["validation"]["inner_folds"], shuffle=True, random_state=inner_seed)
        gs = GridSearchCV(pipe, param_grid(MODEL, cfg), scoring=cfg["validation"]["tuning_score"], cv=inner, n_jobs=1,
                          refit=True, error_score="raise")
        gs.fit(X[tr], y[tr], groups=grp[tr])
        pred, proba = gs.best_estimator_.predict(X[va]), gs.best_estimator_.predict_proba(X[va])
    wcount = {}
    for w in wlist:
        wcount[w.category.__name__] = wcount.get(w.category.__name__, 0) + 1
    res = {"subset": sid, "n_gases": len(gases), "rep": rep, "fold": k, "inner_seed": inner_seed,
           "n_features": len(subset_feature_names(gases)), "n_train": int(tr.sum()), "n_test": int(va.sum()),
           "best_params": {p.replace("clf__estimator__", ""): v for p, v in gs.best_params_.items()},
           "inner_macro_f1": float(gs.best_score_), "seconds": round(time.perf_counter() - t0, 2), "warnings": wcount,
           **s20.metrics(y[va], pred)}
    classes = gs.best_estimator_.named_steps["clf"].classes_
    pr = pd.DataFrame(proba, columns=[f"p_{s20.CLASS_NAMES[int(c)]}" for c in classes])
    pr.insert(0, "y_pred", pred)
    pr.insert(0, "y_true", y[va])
    pr.insert(0, "record_id", dev.record_id.to_numpy()[va])
    for col, val in [("subset", sid), ("rep", rep), ("fold", k)]:
        pr.insert(0, col, val)
    pr.to_csv(tasks / f"{name}_pred.csv", index=False)
    (tasks / f"{name}.json").write_text(json.dumps(res, indent=1), encoding="utf-8")
    return name


def summarise(run_dir: Path) -> int:
    rows = [json.loads(p.read_text(encoding="utf-8")) for p in sorted((run_dir / "tasks").glob("*.json"))]
    fm = pd.DataFrame(rows)
    for c in ("best_params", "warnings"):
        fm[c] = fm[c].map(lambda d: json.dumps(d, sort_keys=True))
    fm["confusion_matrix"] = fm.confusion_matrix.map(json.dumps)
    fm.to_csv(run_dir / "fold_metrics.csv", index=False)
    preds = pd.concat([pd.read_csv(p) for p in sorted((run_dir / "tasks").glob("*_pred.csv"))], ignore_index=True)
    preds.to_csv(run_dir / "predictions.csv", index=False)

    dev = s20.development_data()
    complete = len(fm) == 31 * 50
    per = preds.groupby(["subset", "rep"]).record_id.agg(["count", "nunique"])
    once = bool(complete and (per["count"] == len(dev)).all() and (per["nunique"] == len(dev)).all())
    # identical folds: every task's held-out records equal folds.csv for that repeat and fold
    fold_ok = all(set(g.record_id) == set(dev.record_id[dev[rep] == k])
                  for (sub, rep, k), g in preds.groupby(["subset", "rep", "fold"]))
    # full panel must reproduce Step 20 Random Forest / F4: compare the original task files of both runs (exact values;
    # values re-read from CSV can differ in the last binary digit with the default pandas float parser)
    s20_tasks = PROJECT_ROOT / "07_Experiments" / "2026-10-11_nestedcv_v1" / "tasks"
    full_ok, n_cmp = True, 0
    for rep in [f"rep{r:02d}" for r in range(1, 11)]:
        for k in range(1, 6):
            a = json.loads((s20_tasks / f"{FULL}_{MODEL}_{rep}_f{k}.json").read_text(encoding="utf-8"))
            b = json.loads((run_dir / "tasks" / f"{subset_id(tuple(GASES))}_{rep}_f{k}.json").read_text(encoding="utf-8"))
            pa = pd.read_csv(s20_tasks / f"{FULL}_{MODEL}_{rep}_f{k}_pred.csv", float_precision="round_trip")
            pb = pd.read_csv(run_dir / "tasks" / f"{subset_id(tuple(GASES))}_{rep}_f{k}_pred.csv", float_precision="round_trip")
            pc = [c for c in pa.columns if c.startswith("p_")]
            full_ok &= (a["macro_f1"] == b["macro_f1"] and a["best_params"] == b["best_params"]
                        and (pa.y_pred.to_numpy() == pb.y_pred.to_numpy()).all()
                        and np.array_equal(pa[pc].to_numpy(), pb[pc].to_numpy()))
            n_cmp += 1
    full_ok = bool(full_ok and n_cmp == 50)

    OUT.mkdir(parents=True, exist_ok=True)
    sub_rows = []
    for s in subsets():
        names = subset_feature_names(s)
        sub_rows.append({"subset_id": subset_id(s), "n_gases": len(s), **{f"has_{g}": g in s for g in GASES},
                         "n_features": len(names), "features": ";".join(names),
                         "ratios_available": ";".join(r for r, (a, b) in RATIOS.items() if a in s and b in s),
                         "duval_available": all(g in s for g in DUVAL),
                         "iec_rogers_applicable": len(s) == 5, "monitor_panel": ""})
    pd.DataFrame(sub_rows).to_csv(OUT / "reduced_gas_subsets.csv", index=False)
    w = fm.pivot_table(index=["rep", "fold"], columns="subset", values="macro_f1")
    full_col = w[subset_id(tuple(GASES))]
    res = []
    for s in subsets():
        sid = subset_id(s)
        g = fm[fm.subset == sid]
        d = full_col - w[sid]
        res.append({"subset_id": sid, "n_gases": len(s), "n_features": len(subset_feature_names(s)),
                    "macro_f1_mean": g.macro_f1.mean(), "macro_f1_sd": g.macro_f1.std(ddof=1),
                    "balanced_accuracy_mean": g.balanced_accuracy.mean(), "accuracy_mean": g.accuracy.mean(),
                    "macro_f1_merged_T12_mean": g.macro_f1_merged_T12.mean(),
                    "loss_vs_full_mean": d.mean(), "loss_vs_full_sd": d.std(ddof=1),
                    "most_chosen_setting": g.best_params.value_counts().index[0],
                    "tasks_with_warnings": int((g.warnings != "{}").sum())})
    rg = pd.DataFrame(res)
    rg.round(4).to_csv(OUT / "reduced_gas_results.csv", index=False)
    checks = {"tasks": len(fm), "complete": complete, "every_record_once_per_repeat": once,
              "identical_folds_to_step10": bool(fold_ok), "full_panel_reproduces_step20": full_ok,
              "tasks_with_warnings": int((fm.warnings != "{}").sum()), "prediction_rows": len(preds)}
    (run_dir / "step25_checks.json").write_text(json.dumps(checks, indent=1), encoding="utf-8")
    best_k = rg.sort_values("macro_f1_mean", ascending=False).groupby("n_gases").head(1).sort_values("n_gases")
    rep = ["# Step 25 report - reduced-gas study (cross-validation)", "", f"Run folder: `{run_dir.relative_to(PROJECT_ROOT).as_posix()}`.",
           f"Checks: {json.dumps(checks)}", "", "## Best subset for each number of gases", "",
           md_table(best_k[["n_gases", "subset_id", "n_features", "macro_f1_mean", "macro_f1_sd", "loss_vs_full_mean"]].round(4)), "",
           "## All subsets", "", md_table(rg[["subset_id", "n_gases", "n_features", "macro_f1_mean", "macro_f1_sd",
                                                "loss_vs_full_mean"]].round(4)), "",
           "Loss and its 95 % bootstrap interval, the tolerance test (delta = 0.05) and the minimum panel: Step 27.", ""]
    (INTERIM / "step25_report.md").write_text("\n".join(rep), encoding="utf-8")
    print("\n".join(rep))
    return 0 if (complete and once and fold_ok and full_ok) else 1


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--jobs", type=int, default=7)
    ap.add_argument("--run", default="2026-10-12_reducedgas_v1")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--summarise-only", action="store_true")
    a = ap.parse_args()
    problems = verify_data_version()
    if problems:
        raise SystemExit("data version 1.0 changed: " + "; ".join(problems))
    run_dir = PROJECT_ROOT / "07_Experiments" / a.run
    if a.summarise_only:
        return summarise(run_dir)
    from joblib import Parallel, delayed

    from pipelines import CONFIG, load_config
    import sklearn
    cfg = load_config()
    (run_dir / "tasks").mkdir(parents=True, exist_ok=True)
    shutil.copy(CONFIG, run_dir / "config.yaml")
    info_path = run_dir / "run_info.json"
    info = json.loads(info_path.read_text()) if info_path.exists() else {
        "run": a.run, "model": MODEL, "feature_set": f"{FULL} restricted to each subset (D22)", "subsets": 31,
        "data_version": cfg["data_version"], "seed": cfg["seed"], "jobs": a.jobs, "python": platform.python_version(),
        "scikit_learn": sklearn.__version__, "start": datetime.now().isoformat(timespec="seconds"),
        "development_records": len(s20.development_data()), "test_sets_opened": False}
    info_path.write_text(json.dumps(info, indent=1), encoding="utf-8")
    reps = [f"rep{r:02d}" for r in range(1, 11)]
    # largest subsets first (slowest), so the run ends with short tasks
    tasks = [(s, rep, k) for s in sorted(subsets(), key=len, reverse=True) for rep in reps for k in range(1, 6)]
    if a.limit:
        tasks = tasks[: a.limit]
    done = 0
    with open(run_dir / "progress.log", "a", encoding="utf-8") as fh:
        fh.write(f"start {datetime.now().isoformat(timespec='seconds')} tasks {len(tasks)}\n")
        for name in Parallel(n_jobs=a.jobs, return_as="generator_unordered", batch_size=1)(
                delayed(run_task)(*t, str(run_dir)) for t in tasks):
            done += 1
            fh.write(f"{datetime.now().strftime('%H:%M:%S')} {done}/{len(tasks)} {name}\n")
            fh.flush()
    if a.limit:
        return 0
    info["end"] = datetime.now().isoformat(timespec="seconds")
    info_path.write_text(json.dumps(info, indent=1), encoding="utf-8")
    return summarise(run_dir)


if __name__ == "__main__":
    raise SystemExit(main())
