"""Roadmap Step 8 [Claude Code] - apply the scope filter.

Input : 03_Data/interim/<SOURCE>_step07.csv; analysis-plan item 8 (decisions_log.md).
Rule  : primary analysis = power transformers only. In IEC TC 10 (Duval & dePablo 2001, Annex 1 Table 1)
        P = power transformer without communicating OLTC, U = with communicating OLTC -> in scope.
        R reactor, I instrument transformer, B bushing, C cable -> out of scope (sensitivity analysis only).
        S (selector / tap-changer compartment; used in the tables but not defined in Table 1) -> out of scope.
        Empty equipment type -> cannot be confirmed as a power transformer -> out of scope.
        Dissanayake and Li files record no equipment type -> kept, and this is reported as a limitation.
        Nothing is deleted: every record gets in_scope_primary and scope_reason.
Output: 03_Data/interim/<SOURCE>_step08.csv, 03_Data/interim/exclusion_log.csv, 03_Data/interim/step08_report.md
Check : counts per class before and after the filter are recorded; kept + excluded = total.
"""
from __future__ import annotations

import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import pandas as pd  # noqa: E402

from common import INTERIM, SOURCES, md_table, rel  # noqa: E402

IEC_TYPES = {
    "P": (True, "power transformer without communicating OLTC (Table 1)"),
    "U": (True, "power transformer with communicating OLTC (Table 1)"),
    "R": (False, "reactor (Table 1) - not a power transformer"),
    "I": (False, "instrument transformer (Table 1) - not a power transformer"),
    "B": (False, "bushing (Table 1) - not a power transformer"),
    "C": (False, "cable (Table 1) - not a power transformer"),
    "S": (False, "selector / tap-changer compartment - code not defined in Table 1; not the main tank"),
    "": (False, "equipment type not given - cannot be confirmed as a power transformer"),
}
CLASSES = ["Normal", "PD", "D1", "D2", "T12", "T3"]


def main() -> int:
    ok, log_rows, summary = True, [], []
    for src in SOURCES:
        sid = src["source_id"]
        df = pd.read_csv(INTERIM / f"{sid}_step07.csv", dtype={"original_label": str, "src_equipment_type": str},
                         keep_default_na=True)
        if "src_equipment_type" in df.columns:
            eq = df["src_equipment_type"].fillna("").astype(str).str.strip()
            unknown = sorted(set(eq) - set(IEC_TYPES))
            if unknown:
                ok = False
                print(f"{sid}: unknown equipment codes {unknown}")
            df["in_scope_primary"] = eq.map(lambda e: IEC_TYPES.get(e, (False, "unknown code"))[0])
            df["scope_reason"] = eq.map(lambda e: IEC_TYPES.get(e, (False, "unknown code"))[1])
        else:
            df["in_scope_primary"] = True
            df["scope_reason"] = "equipment type not recorded in the source; kept (limitation)"
        df.to_csv(INTERIM / f"{sid}_step08.csv", index=False, encoding="utf-8")

        out = df[~df["in_scope_primary"]]
        for _, r in out.iterrows():
            log_rows.append({"record_id": r["record_id"], "source_id": sid,
                             "equipment_type": (str(r["src_equipment_type"]).strip() if pd.notna(r.get("src_equipment_type")) else "(blank)"),
                             "class_merged": r["class_merged"], "reason": r["scope_reason"],
                             "inspection": r.get("src_inspection", "")})
        before = df.groupby("class_merged").size()
        after = df[df["in_scope_primary"]].groupby("class_merged").size()
        for k in CLASSES:
            if before.get(k, 0):
                summary.append({"source_id": sid, "class_merged": k, "before": int(before.get(k, 0)),
                                "kept_primary": int(after.get(k, 0)),
                                "excluded": int(before.get(k, 0) - after.get(k, 0))})
        if len(out) + int(df["in_scope_primary"].sum()) != len(df):
            ok = False
        print(f"{sid:<9} records={len(df):<4} kept_primary={int(df['in_scope_primary'].sum()):<4} excluded={len(out)}")

    log = pd.DataFrame(log_rows)
    log.to_csv(INTERIM / "exclusion_log.csv", index=False, encoding="utf-8")
    summ = pd.DataFrame(summary)
    by_type = (log.groupby(["equipment_type", "reason"], dropna=False).size().reset_index(name="records")
               if len(log) else pd.DataFrame())
    L = ["# Step 8 report - scope filter", "",
         f"Run date: {date.today().isoformat()}. Script: `06_Python_ML/src/data_prep/step08_scope_filter.py`.", "",
         "Primary analysis: power transformers only (IEC TC 10 codes P and U). Excluded records are not deleted; "
         "they are flagged (`in_scope_primary` = False) and used in the sensitivity analysis. The Dissanayake and "
         "Li files record no equipment type, so no filter can be applied to them (reported as a limitation).", "",
         "## Excluded records by equipment type", "", md_table(by_type) if len(by_type) else "None.", "",
         "## Records per class before and after the filter", "", md_table(summ), "",
         f"Check: kept + excluded = total for every source - {'PASS' if ok else 'FAIL'}."]
    (INTERIM / "step08_report.md").write_text("\n".join(L) + "\n", encoding="utf-8")
    print(f"report: {rel(INTERIM / 'step08_report.md')}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
