"""Roadmap Step 31C [Claude Code] - Study 2: leave-one-source-out training and prediction (protocol D28).

Input : 03_Data/study2/study2_pooled.csv (Step 31B; manifest checked); configs/ml_config.yaml; models/dga_model_v1.joblib.
Do    : hold out each source in turn (DISTRAIN, DISTEST, IECTC10, LI2019); tune and fit model B (pooled RF/F4) and model C
        (hybrid) on the other sources only (GridSearchCV over the Step 20 grid, StratifiedGroupKFold(5) with the pooled
        near-duplicate groups, macro-F1, balanced class weights, seed 20261012 + index); predict the held-out source once;
        apply model A (released dga_model_v1, T1/T2 merged) unchanged to the external sources.
        Variants: primary; equal_source_weight (sensitivity); iec_all (all 117 IEC TC 10 records instead of the 58 power
        transformers - sensitivity).
Output: 07_Experiments/2026-10-12_study2_loso/ (config.json, fits.json, predictions.csv, rerun_check.json);
        03_Data/interim/step31c_report.md
Check : no held-out record or near-copy in any training set; re-running saved tasks gives identical predictions.
"""
from __future__ import annotations

import hashlib
import json
import sys
import tempfile
import time
import warnings
from datetime import datetime
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "ml"))
sys.path.insert(0, str(HERE.parent / "data_prep"))

import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402
from sklearn.model_selection import GridSearchCV, StratifiedGroupKFold  # noqa: E402

from common import INTERIM, PROJECT_ROOT, md_table, verify_data_version  # noqa: E402
from model_io import CLASS_NAMES, load_model  # noqa: E402
from pipelines import load_config, param_grid  # noqa: E402
from study2_models import build, source_weights  # noqa: E402

S2 = PROJECT_ROOT / "03_Data" / "study2"
RUN = PROJECT_ROOT / "07_Experiments" / "2026-10-12_study2_loso"
SOURCES = ["DISTRAIN", "DISTEST", "IECTC10", "LI2019"]
CLASSES6 = ["Normal", "PD", "D1", "D2", "T12", "T3"]
SEED = 20261012
VARIANTS = ["primary", "equal_source_weight", "iec_all"]
GASES = ["H2", "CH4", "C2H6", "C2H4", "C2H2"]


def sha256(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest().upper()


def load_pooled() -> pd.DataFrame:
    for line in (S2 / "study2_data.sha256").read_text(encoding="ascii").splitlines():
        h, f = line.split("  ")
        assert sha256(PROJECT_ROOT / f) == h, f"Study 2 data changed: {f}"
    return pd.read_csv(S2 / "study2_pooled.csv", keep_default_na=False, na_values=["NaN", ""])


def split(pool: pd.DataFrame, held: str, variant: str) -> tuple[pd.DataFrame, pd.DataFrame]:
    data = pool if variant == "iec_all" else pool[pool.in_primary_scope]
    test = data[data.source_id == held]
    train = data[(data.source_id != held) & ~data.group_id.isin(set(test.group_id))]
    assert not set(train.record_id) & set(test.record_id)
    assert not set(train.group_id) & set(test.group_id)
    return train.reset_index(drop=True), test.reset_index(drop=True)


def fit_predict(model: str, train: pd.DataFrame, test: pd.DataFrame, seed: int, weighted_sources: bool, n_jobs: int) -> dict:
    cfg = load_config()
    pipe = build(model, seed, cfg)
    grid = param_grid("random_forest", cfg)
    inner = StratifiedGroupKFold(n_splits=cfg["validation"]["inner_folds"], shuffle=True, random_state=seed)
    gs = GridSearchCV(pipe, grid, scoring=cfg["validation"]["tuning_score"], cv=inner, n_jobs=n_jobs, refit=True,
                      error_score="raise")
    fit_kw = {"clf__sample_weight": source_weights(train.source_id)} if weighted_sources else {}
    t0 = time.perf_counter()
    with warnings.catch_warnings(record=True) as wl:
        warnings.simplefilter("always")
        gs.fit(train, train.class6.to_numpy(), groups=train.group_id.to_numpy(), **fit_kw)
    best = gs.best_estimator_
    proba = best.predict_proba(test)
    classes = list(best.named_steps["clf"].classes_)
    return {"pred": best.predict(test), "proba": proba, "classes": classes,
            "best_params": {k.replace("clf__estimator__", ""): v for k, v in gs.best_params_.items()},
            "inner_macro_f1": float(gs.best_score_), "seconds": round(time.perf_counter() - t0, 1), "warnings": len(wl),
            "n_features": int(best.named_steps["scale"].n_features_in_)}


def frame(variant, held, model, test, pred, proba, classes) -> pd.DataFrame:
    out = pd.DataFrame({"variant": variant, "held_out": held, "model": model, "record_id": test.record_id,
                        "y_true": test.class6, "y_pred": pred})
    for c in CLASSES6:
        out[f"p_{c}"] = proba[:, classes.index(c)] if c in classes else 0.0
    return out


def model_a(test: pd.DataFrame) -> tuple[np.ndarray, np.ndarray, list]:
    a = load_model()
    codes = a.named_steps["clf"].classes_
    names = [CLASS_NAMES[int(c)] for c in codes]
    p7 = a.predict_proba(test[GASES])
    pred = np.array([{"T1": "T12", "T2": "T12"}.get(CLASS_NAMES[int(c)], CLASS_NAMES[int(c)]) for c in a.predict(test[GASES])])
    p6 = np.column_stack([p7[:, names.index("T1")] + p7[:, names.index("T2")] if c == "T12" else p7[:, names.index(c)]
                          for c in CLASSES6])
    return pred, p6, CLASSES6


def main() -> int:
    problems = verify_data_version()
    if problems:
        raise SystemExit("data version 1.0 changed: " + "; ".join(problems))
    rec = (S2 / "study2_protocol.sha256").read_text(encoding="ascii").split()[0]
    assert sha256(PROJECT_ROOT / "00_Project_Admin" / "Study2_Protocol.docx") == rec, "protocol changed after registration"
    pool = load_pooled()
    RUN.mkdir(parents=True, exist_ok=True)
    import sklearn
    (RUN / "config.json").write_text(json.dumps({"protocol_sha256": rec, "seed": SEED, "sources": SOURCES, "variants": VARIANTS,
                                                 "scikit_learn": sklearn.__version__, "start": datetime.now().isoformat(timespec="seconds")},
                                                indent=1), encoding="utf-8")
    preds, fits = [], []
    for variant in VARIANTS:
        for idx, held in enumerate(SOURCES):
            train, test = split(pool, held, variant)
            if held != "DISTRAIN" and variant != "equal_source_weight":
                p, pr, cl = model_a(test)
                preds.append(frame(variant, held, "A", test, p, pr, cl))
            for model in ("B", "C"):
                r = fit_predict(model, train, test, SEED + idx, variant == "equal_source_weight", n_jobs=7)
                preds.append(frame(variant, held, model, test, r["pred"], r["proba"], r["classes"]))
                fits.append({"variant": variant, "held_out": held, "model": model, "seed": SEED + idx, "n_train": len(train),
                             "n_test": len(test), "train_sources": sorted(train.source_id.unique()),
                             **{k: r[k] for k in ("best_params", "inner_macro_f1", "seconds", "warnings", "n_features")}})
                print(f"{datetime.now():%H:%M:%S} {variant:20s} {held:8s} {model}  inner {r['inner_macro_f1']:.3f}  {r['seconds']} s", flush=True)
    P = pd.concat(preds, ignore_index=True)
    P.to_csv(RUN / "predictions.csv", index=False)
    (RUN / "fits.json").write_text(json.dumps(fits, indent=1, default=str), encoding="utf-8")

    # rerun check: two saved tasks re-fitted from scratch must give identical predictions and probabilities
    checks = []
    for variant, held, model in (("primary", "DISTEST", "B"), ("primary", "IECTC10", "C")):
        idx = SOURCES.index(held)
        train, test = split(pool, held, variant)
        r = fit_predict(model, train, test, SEED + idx, False, n_jobs=7)
        old = P[(P.variant == variant) & (P.held_out == held) & (P.model == model)].reset_index(drop=True)
        new = frame(variant, held, model, test, r["pred"], r["proba"], r["classes"])
        pc = [f"p_{c}" for c in CLASSES6]
        checks.append({"task": f"{variant}/{held}/{model}", "same_predictions": bool((old.y_pred == new.y_pred).all()),
                       "max_probability_difference": float(np.abs(old[pc].to_numpy() - new[pc].to_numpy()).max())})
    (RUN / "rerun_check.json").write_text(json.dumps(checks, indent=1), encoding="utf-8")
    cfg = json.loads((RUN / "config.json").read_text(encoding="utf-8"))
    cfg["end"] = datetime.now().isoformat(timespec="seconds")
    (RUN / "config.json").write_text(json.dumps(cfg, indent=1), encoding="utf-8")

    fdf = pd.DataFrame(fits)
    rep = ["# Step 31C report - Study 2 leave-one-source-out runs", "",
           md_table(fdf[["variant", "held_out", "model", "n_train", "n_test", "inner_macro_f1", "n_features", "seconds", "warnings"]].round(3)), "",
           "Rerun check: " + json.dumps(checks), ""]
    (INTERIM / "step31c_report.md").write_text("\n".join(rep), encoding="utf-8")
    print("\n".join(rep))
    return 0 if all(c["same_predictions"] and c["max_probability_difference"] == 0 for c in checks) else 1


if __name__ == "__main__":
    raise SystemExit(main())
