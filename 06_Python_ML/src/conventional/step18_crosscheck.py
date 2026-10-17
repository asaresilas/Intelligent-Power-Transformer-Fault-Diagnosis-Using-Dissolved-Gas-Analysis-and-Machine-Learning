"""Roadmap Step 18 [Claude Code] - cross-check MATLAB against Python.

Input : 11_Results/conventional/conventional_predictions.csv (MATLAB, Steps 14-16); the 02_Standards tables;
        03_Data/processed/dga_master.csv (data version 1.0, verified first).
Do    : re-run the three conventional methods with the independent Python implementation
        (conventional_methods.py) and compare every record and method with MATLAB.
Output: 08_Statistical_Analysis/cross_language_check.csv (one row per record and method),
        11_Results/conventional/conventional_predictions_python.csv, 03_Data/interim/step18_report.md
Check : identical diagnoses (raw_result, result, gate_upper, gate_lower) on 100 % of records; ratios, Duval
        percentages and boundary distances equal within 1e-9 (absolute or relative); Inf/NaN in the same places.
"""
from __future__ import annotations

import sys
from datetime import date
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "data_prep"))

import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402

import conventional_methods as cm  # noqa: E402
from common import INTERIM, PROCESSED, PROJECT_ROOT, md_table, rel, verify_data_version  # noqa: E402

TOL = 1e-9
TEXT = ["gate_upper", "gate_lower", "raw_result", "result"]
NUM = ["ratio_R1", "ratio_R2", "ratio_R5", "pct_CH4", "pct_C2H4", "pct_C2H2", "boundary_distance"]


def same_number(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    both_nan = np.isnan(a) & np.isnan(b)
    both_inf = np.isinf(a) & np.isinf(b) & (np.sign(a) == np.sign(b))
    with np.errstate(invalid="ignore"):
        close = np.abs(a - b) <= TOL * np.maximum(1.0, np.maximum(np.abs(a), np.abs(b)))
    return both_nan | both_inf | np.nan_to_num(close, nan=False)


def main() -> int:
    problems = verify_data_version()
    if problems:
        raise SystemExit("data version 1.0 changed: " + "; ".join(problems))
    master = pd.read_csv(PROCESSED / "dga_master.csv")
    py = cm.diagnose(master[cm.GASES], master["equipment_type"])
    py.insert(0, "record_id", np.tile(master.record_id.to_numpy(), 3))
    py["data_version"] = "1.0"
    out_dir = PROJECT_ROOT / "11_Results" / "conventional"
    py.to_csv(out_dir / "conventional_predictions_python.csv", index=False)

    ml = pd.read_csv(out_dir / "conventional_predictions.csv", keep_default_na=False, dtype=str)
    for c in NUM:
        ml[c] = ml[c].replace("", "nan").map(float)          # blank (other method's columns), NaN, Inf
    for c in TEXT:
        ml[c] = ml[c].str.strip()
    m = py.merge(ml, on=["record_id", "method"], how="outer", suffixes=("_py", "_ml"), indicator=True)
    assert (m["_merge"] == "both").all(), "record/method rows differ between MATLAB and Python"

    rows = pd.DataFrame({"record_id": m.record_id, "method": m.method})
    for c in TEXT:
        rows[f"{c}_python"] = m[f"{c}_py"].fillna("")
        rows[f"{c}_matlab"] = m[f"{c}_ml"].fillna("")
        rows[f"{c}_same"] = rows[f"{c}_python"] == rows[f"{c}_matlab"]
    for c in NUM:
        a, b = m[f"{c}_py"].to_numpy(float), m[f"{c}_ml"].to_numpy(float)
        rows[f"{c}_python"], rows[f"{c}_matlab"] = a, b
        rows[f"{c}_same"] = same_number(a, b)
        with np.errstate(invalid="ignore"):
            rows[f"{c}_absdiff"] = np.where(np.isfinite(a) & np.isfinite(b), np.abs(a - b), 0.0)
    rows["all_same"] = rows[[c for c in rows.columns if c.endswith("_same")]].all(axis=1)
    out = PROJECT_ROOT / "08_Statistical_Analysis" / "cross_language_check.csv"
    out.parent.mkdir(parents=True, exist_ok=True)
    rows.to_csv(out, index=False)

    summ = []
    for method, g in rows.groupby("method", sort=False):
        rec = {"method": method, "rows": len(g)}
        for c in TEXT:
            rec[f"{c} identical"] = f"{int(g[f'{c}_same'].sum())}/{len(g)}"
        rec["numbers within 1e-9"] = f"{int(g[[f'{c}_same' for c in NUM]].all(axis=1).sum())}/{len(g)}"
        rec["max abs difference"] = f"{g[[f'{c}_absdiff' for c in NUM]].to_numpy().max():.2e}"
        summ.append(rec)
    summ = pd.DataFrame(summ)
    counts = (py.assign(raw=py.raw_result).groupby("method", sort=False)
              .agg(ND=("raw", lambda s: int((s == "ND").sum())), DT=("raw", lambda s: int((s == "DT").sum())),
                   dual=("raw", lambda s: int(s.str.contains("/").sum())),
                   gate_upper=("gate_upper", lambda s: int((s == "Normal").sum()))).reset_index())
    n_diff = int((~rows.all_same).sum())
    report = [
        "# Step 18 report - MATLAB versus Python cross-check", "",
        f"Run date: {date.today().isoformat()}. Script: `06_Python_ML/src/conventional/step18_crosscheck.py` "
        "(independent implementation `conventional_methods.py`). Data version 1.0 verified: PASS.", "",
        "## Agreement per method", "", md_table(summ), "",
        f"Rows with any difference: {n_diff} of {len(rows)} -> {'PASS' if n_diff == 0 else 'FAIL'}.", "",
        "## Python raw-result counts (827 records)", "", md_table(counts), "",
        f"Detail: `{rel(out)}`; Python predictions: `11_Results/conventional/conventional_predictions_python.csv`.", "",
    ]
    if n_diff:
        report += ["## Differences", "", md_table(rows.loc[~rows.all_same, ["record_id", "method"] +
                                                  [f"{c}_python" for c in TEXT] + [f"{c}_matlab" for c in TEXT]].head(50)), ""]
    (INTERIM / "step18_report.md").write_text("\n".join(report), encoding="utf-8")
    print(md_table(summ))
    print(md_table(counts))
    print(f"rows with any difference: {n_diff}")
    return 0 if n_diff == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
