"""Roadmap Step 28 [Claude Code] - merge all predictions of the test sets.

Input : 03_Data/processed/dga_master.csv (true classes and flags), 11_Results/conventional/conventional_predictions.csv
        (Steps 14-17, MATLAB; 3 methods x 827 records), 11_Results/ml/ml_predictions.csv (Step 22; 388 test records).
Do    : one row per test record (internal test, IEC TC 10 benchmark, Li 2019): true class (7-class and merged), evaluation
        flags, the ML prediction and class probabilities, and for each conventional method the raw answer, the answer after the
        upper normality gate (primary, D11) and after the lower gate (sensitivity), plus the boundary distance, ratios and Duval
        percentages (for Step 31). Merged versions (T1, T2 -> T12) are added for the IEC TC 10 scoring (plan item 6).
        No scoring here - Step 29 applies the scoring rules.
Output: 08_Statistical_Analysis/merged_predictions.csv, merge_checks.json, 03_Data/interim/step28_report.md
Check : no record is lost or duplicated in the join.
"""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "data_prep"))

import pandas as pd  # noqa: E402

from common import INTERIM, PROCESSED, PROJECT_ROOT, md_table, verify_data_version  # noqa: E402

OUT = PROJECT_ROOT / "08_Statistical_Analysis"
METHODS = ["IEC60599", "Rogers", "Duval"]
TO_MERGED = {"T1": "T12", "T2": "T12"}
CLASSES = ["Normal", "PD", "D1", "D2", "T1", "T2", "T3"]


def merge_label(s: pd.Series) -> pd.Series:
    return s.map(lambda v: TO_MERGED.get(v, v) if isinstance(v, str) else v)


def sha256(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest().upper()


def main() -> int:
    problems = verify_data_version()
    if problems:
        raise SystemExit("data version 1.0 changed: " + "; ".join(problems))
    master = pd.read_csv(PROCESSED / "dga_master.csv")
    conv_path = PROJECT_ROOT / "11_Results" / "conventional" / "conventional_predictions.csv"
    ml_path = PROJECT_ROOT / "11_Results" / "ml" / "ml_predictions.csv"
    conv = pd.read_csv(conv_path, keep_default_na=False, na_values=["NaN", ""], float_precision="round_trip")
    ml = pd.read_csv(ml_path, float_precision="round_trip")

    test = master[master.data_role != "development"][
        ["record_id", "source_id", "data_role", "class_code", "class_name", "class_merged", "in_scope_primary",
         "independent_of_benchmark", "benchmark_duplicate_of", "equipment_type", "H2", "CH4", "C2H6", "C2H4", "C2H2"]]
    n_test = len(test)

    # ML part
    mlc = ml[["record_id", "y_pred", "y_pred_merged"] + [f"p_{c}" for c in CLASSES]].rename(
        columns={"y_pred": "ml_pred", "y_pred_merged": "ml_pred_merged", **{f"p_{c}": f"ml_p_{c}" for c in CLASSES}})

    # conventional part: one block of columns per method
    assert set(conv.method) == set(METHODS)
    gate = conv.groupby("record_id").agg(gate_upper=("gate_upper", "first"), gate_lower=("gate_lower", "first"),
                                         n_gate_upper=("gate_upper", "nunique"), n_gate_lower=("gate_lower", "nunique"))
    gate_consistent = bool(((gate.n_gate_upper <= 1) & (gate.n_gate_lower <= 1)).all())
    gate = gate[["gate_upper", "gate_lower"]].reset_index()
    gate["gate_upper_normal"] = gate.gate_upper.eq("Normal")
    gate["gate_lower_normal"] = gate.gate_lower.eq("Normal")
    blocks = []
    for m in METHODS:
        c = conv[conv.method == m].set_index("record_id")
        b = pd.DataFrame(index=c.index)
        b[f"{m}_raw"] = c.raw_result
        b[f"{m}_result"] = c.result                                        # upper gate (primary, D11)
        b[f"{m}_result_lower_gate"] = c.raw_result.where(c.gate_lower.ne("Normal"), "Normal")
        b[f"{m}_result_merged"] = merge_label(b[f"{m}_result"])
        b[f"{m}_result_lower_gate_merged"] = merge_label(b[f"{m}_result_lower_gate"])
        b[f"{m}_boundary_distance"] = c.boundary_distance
        blocks.append(b)
    ratios = conv[conv.method == "IEC60599"].set_index("record_id")[["ratio_R1", "ratio_R2", "ratio_R5"]]
    duval_pct = conv[conv.method == "Duval"].set_index("record_id")[["pct_CH4", "pct_C2H4", "pct_C2H2"]].add_prefix("duval_")
    convw = pd.concat(blocks + [ratios, duval_pct], axis=1).reset_index()

    merged = (test.merge(mlc, on="record_id", how="left", validate="one_to_one", indicator="ml_join")
                  .merge(gate[["record_id", "gate_upper_normal", "gate_lower_normal"]], on="record_id", how="left",
                         validate="one_to_one")
                  .merge(convw, on="record_id", how="left", validate="one_to_one", indicator="conv_join"))
    merged["data_version"] = "1.0"

    checks = {
        "test_records_in_master": n_test,
        "rows_merged": len(merged),
        "unique_record_ids": int(merged.record_id.nunique()),
        "no_record_lost": bool(len(merged) == n_test and (merged.ml_join == "both").all() and (merged.conv_join == "both").all()),
        "no_record_duplicated": bool(merged.record_id.is_unique),
        "no_development_record": bool((merged.data_role != "development").all()),
        "ml_records_all_used": bool(set(ml.record_id) == set(merged.record_id)),
        "conventional_rows_per_test_record": int(conv[conv.record_id.isin(test.record_id)].groupby("record_id").size().min()),
        "gate_same_for_all_methods": gate_consistent,
        "no_missing_prediction": bool(merged[["ml_pred"] + [f"{m}_result" for m in METHODS]].notna().all().all()),
        "per_role": merged.data_role.value_counts().to_dict(),
        "ml_predictions_sha256": sha256(ml_path), "conventional_predictions_sha256": sha256(conv_path),
    }
    merged = merged.drop(columns=["ml_join", "conv_join"])
    OUT.mkdir(parents=True, exist_ok=True)
    out = OUT / "merged_predictions.csv"
    merged.to_csv(out, index=False)
    checks["merged_sha256"] = sha256(out)
    (OUT / "merge_checks.json").write_text(json.dumps(checks, indent=1), encoding="utf-8")
    ok = all(checks[k] for k in ("no_record_lost", "no_record_duplicated", "no_development_record", "ml_records_all_used",
                                 "gate_same_for_all_methods", "no_missing_prediction")) and checks["conventional_rows_per_test_record"] == 3

    counts = pd.concat({m: merged[f"{m}_result"].value_counts() for m in METHODS} | {"ML": merged.ml_pred.value_counts()},
                       axis=1).fillna(0).astype(int)
    rep = ["# Step 28 report - merged predictions", "", "Checks: " + json.dumps(checks), "", f"Overall: {'PASS' if ok else 'FAIL'}", "",
           "## Answers per method (all 388 test records; conventional after the upper gate)", "",
           md_table(counts.rename_axis("answer").reset_index()), "",
           f"Columns ({merged.shape[1]}): " + ", ".join(merged.columns), ""]
    (INTERIM / "step28_report.md").write_text("\n".join(rep), encoding="utf-8")
    print("\n".join(rep))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
