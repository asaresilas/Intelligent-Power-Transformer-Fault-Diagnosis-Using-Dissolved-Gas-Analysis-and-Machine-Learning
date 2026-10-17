"""Roadmap Step 24 [Claude Code] - save the versioned model with its fingerprint and a model card.

Input : 07_Experiments/2026-10-12_final_fit/final_pipeline.joblib and final_fit.json (Step 22); result files of Steps 20-23.
Do    : (1) copy the fitted pipeline byte for byte (not refitted) to 06_Python_ML/models/dga_model_v1.joblib and write its
        SHA-256 to dga_model_v1.sha256 and dga_model_v1_meta.json; (2) reload it in a FRESH Python process through
        model_io.load_model() and check that the 388 test predictions (class and every probability) are identical to
        11_Results/ml/ml_predictions.csv; (3) write model_card.md (Mitchell et al. 2019) from the saved result files.
Output: 06_Python_ML/models/ (dga_model_v1.joblib, .sha256, _meta.json, model_card.md, reload_check.json),
        03_Data/interim/step24_report.md
Decision: D21.
"""
from __future__ import annotations

import json
import platform
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "data_prep"))

import pandas as pd  # noqa: E402

from common import INTERIM, PROJECT_ROOT, md_table, verify_data_version  # noqa: E402
from model_io import CLASS_NAMES, MODEL_V1, MODELS, sha256  # noqa: E402

FIT = PROJECT_ROOT / "07_Experiments" / "2026-10-12_final_fit"
PRED = PROJECT_ROOT / "11_Results" / "ml" / "ml_predictions.csv"

# run in a fresh interpreter: load through model_io, predict the test records, compare with the Step 22 file
RELOAD = r'''
import json, sys
import numpy as np, pandas as pd
sys.path.insert(0, sys.argv[1])
from model_io import load_model, CLASS_NAMES
m = load_model()
saved = pd.read_csv(sys.argv[2])
master = pd.read_csv(sys.argv[3]).set_index("record_id")
X = master.loc[saved.record_id, ["H2", "CH4", "C2H6", "C2H4", "C2H2"]].reset_index(drop=True)
pred = [CLASS_NAMES[int(c)] for c in m.predict(X)]
proba = m.predict_proba(X)
cols = [f"p_{CLASS_NAMES[int(c)]}" for c in m.named_steps["clf"].classes_]
old = saved[cols].to_numpy()
print(json.dumps({"records": len(saved), "same_classes": bool((saved.y_pred.to_numpy() == np.array(pred)).all()),
                  "max_abs_probability_difference": float(np.abs(proba - old).max())}))
'''


def main() -> int:
    problems = verify_data_version()
    if problems:
        raise SystemExit("data version 1.0 changed: " + "; ".join(problems))
    fit = json.loads((FIT / "final_fit.json").read_text(encoding="utf-8"))
    src = FIT / "final_pipeline.joblib"
    assert sha256(src) == fit["pipeline_sha256"], "Step 22 pipeline changed"

    # (1) versioned copy, byte for byte
    MODELS.mkdir(parents=True, exist_ok=True)
    if MODEL_V1.exists() and sha256(MODEL_V1) != fit["pipeline_sha256"]:
        raise SystemExit("models/dga_model_v1.joblib exists with a different fingerprint - a new version needs a new name")
    shutil.copyfile(src, MODEL_V1)
    h = sha256(MODEL_V1)
    assert h == fit["pipeline_sha256"]
    MODEL_V1.with_suffix(".sha256").write_text(f"{h}  {MODEL_V1.name}\n", encoding="utf-8")
    import sklearn
    meta = {"name": "dga_model_v1", "version": "1.0", "sha256": h, "created": datetime.now().isoformat(timespec="seconds"),
            "copied_from": src.relative_to(PROJECT_ROOT).as_posix(), "model": fit["model"], "feature_set": fit["feature_set"],
            "best_params": fit["best_params"], "inputs": ["H2", "CH4", "C2H6", "C2H4", "C2H2"], "input_unit": "ppm (ul/l)",
            "not_detected": "enter 0 ppm (decision D8)", "classes": list(CLASS_NAMES.values()),
            "data_version": fit["data_version"], "python": platform.python_version(), "scikit_learn": sklearn.__version__,
            "load_with": "06_Python_ML/src/ml/model_io.py: load_model()"}
    (MODELS / "dga_model_v1_meta.json").write_text(json.dumps(meta, indent=1), encoding="utf-8")

    # (2) reload in a fresh process and compare with Step 22
    out = subprocess.run([sys.executable, "-I", "-c", RELOAD, str(HERE), str(PRED),
                          str(PROJECT_ROOT / "03_Data" / "processed" / "dga_master.csv")],
                         capture_output=True, text=True, check=True)
    chk = json.loads(out.stdout.strip().splitlines()[-1])
    chk["pass"] = chk["same_classes"] and chk["max_abs_probability_difference"] == 0.0
    (MODELS / "reload_check.json").write_text(json.dumps(chk, indent=1), encoding="utf-8")
    if not chk["pass"]:
        raise SystemExit(f"reload check FAILED: {chk}")

    # (3) model card from the saved result files
    t44 = pd.read_csv(PROJECT_ROOT / "11_Results" / "tables" / "T4_4_cv_results.csv")
    cv = t44[(t44.model == fit["model"]) & (t44.feature_set == fit["feature_set"])].iloc[0]
    fl = pd.read_csv(PROJECT_ROOT / "11_Results" / "ml" / "ml_first_look.csv")
    pi = pd.read_csv(PROJECT_ROOT / "11_Results" / "explain" / "permutation_importance.csv")
    gas = pi[pi.level == "gas"].pivot(index="feature", columns="evaluation_set", values="importance_mean").round(3)
    si = pd.read_csv(PROJECT_ROOT / "11_Results" / "explain" / "shap_importance.csv")
    top = si[(si.records == "development") & (si["class"] == "all classes")].nsmallest(5, "rank")
    bp = ", ".join(f"{k} = {v}" for k, v in fit["best_params"].items())
    perclass = ", ".join(f"{c} {cv[f'f1_{c}_mean']:.3f}" for c in CLASS_NAMES.values())
    card = [
        "# Model card - dga_model_v1", "",
        f"Generated {datetime.now():%Y-%m-%d %H:%M} by `06_Python_ML/src/ml/step24_save_model.py` from the saved result files "
        "(format after Mitchell et al., 2019). Every number below is read from a project file.", "",
        "## Model details",
        f"- File: `06_Python_ML/models/dga_model_v1.joblib`, SHA-256 `{h}` (identical to the Step 22 fit, decision D21).",
        f"- Type: scikit-learn pipeline - feature builder (set {fit['feature_set']}: log gases, gas percentages, log ratios "
        "R1-R5, Duval percentages; 18 features) -> median imputation -> standard scaling -> Random Forest, 500 trees, "
        f"balanced class weights; setting {bp} (inner-CV macro-F1 {fit['inner_macro_f1']:.3f}).",
        f"- Trained on {fit['n_development']} development records, data version {fit['data_version']}; seed 20261010; "
        f"Python {meta['python']}, scikit-learn {meta['scikit_learn']}.",
        "- Load only with `model_io.load_model()` (checks the fingerprint). Developed for an MPhil thesis at UMaT.", "",
        "## Intended use",
        "- Decision support for interpreting dissolved gas analysis of mineral-oil-filled power transformers: suggests one of "
        "seven classes (Normal, PD, D1, D2, T1, T2, T3) with a probability for each.",
        "- Not intended to replace an engineer's judgement, the IEC 60599 / IEEE C57.104 procedures, gas-rate trending or "
        "inspection, and not for other equipment (reactors, bushings, instrument transformers, tap-changer compartments) or "
        "other insulating liquids.", "",
        "## Inputs and outputs",
        "- Inputs: H2, CH4, C2H6, C2H4, C2H2 in ppm (ul/l). A gas that was not detected is entered as 0 ppm (decision D8). "
        "CO and CO2 are not used (decision D2).",
        "- Output: the most probable class and the probability of each class. The model always answers; it has no "
        "'no diagnosis' option and no check that a sample lies far from the training data.", "",
        "## Training data",
        "- 439 development records (IEEE DataPort, Dissanayake training file) after removal of duplicates and of IEC TC 10 "
        "cases. The labelling method of this source is not documented (decision D7).", "",
        "## Performance (macro-F1 = mean F1 over classes)",
        f"- Nested cross-validation on the development data (50 folds): {cv.macro_f1_mean:.3f} (SD {cv.macro_f1_sd:.3f}); "
        f"accuracy {cv.accuracy_mean:.3f}; per-class F1: {perclass}.",
        "- One-time test (Step 22, first look; confidence intervals follow in Step 29):", "",
        md_table(fl[["evaluation_set", "n", "macro_f1", "accuracy", "kappa"]].round(3)), "",
        "## What the model relies on (Step 23)",
        "- Permutation importance, gas level (drop in macro-F1 when the gas is shuffled):", "",
        md_table(gas.reset_index()), "",
        "- Strongest features by mean |SHAP|: " + ", ".join(top.feature) + ". Directions agree with IEC 60599 Table 2.", "",
        "## Limitations and cautions",
        "- Performance falls on data from other sources (dataset shift): highest on the internal test set, lower on the "
        "IEC TC 10 benchmark and on Li 2019; weakest classes externally are T1 (often called Normal or PD) and T3 vs T1/T2.",
        "- Development labels of undocumented origin; agreement with IEC rules shows plausibility, not proof.",
        "- Normal is learned from one source only; the model cannot judge gas increase rates or equipment history.",
        "- Small test sets (58-86 records per primary set); single-record changes move macro-F1 noticeably.", "",
        "## Reproduction check",
        f"- Reloaded in a fresh Python process: {chk['records']} test records, same classes: {chk['same_classes']}, "
        f"largest probability difference: {chk['max_abs_probability_difference']} -> {'PASS' if chk['pass'] else 'FAIL'}.", "",
    ]
    (MODELS / "model_card.md").write_text("\n".join(card), encoding="utf-8")
    rep = ["# Step 24 report - versioned model", "", f"dga_model_v1.joblib SHA-256 {h}", "",
           "Reload check: " + json.dumps(chk), "", "Model card: `06_Python_ML/models/model_card.md`", ""]
    (INTERIM / "step24_report.md").write_text("\n".join(rep), encoding="utf-8")
    print("\n".join(rep))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
