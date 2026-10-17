"""Roadmap Step 6 [Claude Code] - record the missing values.

Input : 03_Data/interim/<SOURCE>_standardised.csv (Step 5).
Do    : classify every gas cell as
          measured     - a positive value other than the placeholder
          zero         - exactly 0
          placeholder  - exactly 0.0001 ppm (Step 5 finding: used by the Dissanayake files where a
                         value was not available; far below any laboratory detection limit)
          blank        - empty cell (the dash in the IEC TC 10 tables)
        Count them per gas, per source and per class; flag every record. Nothing is removed or
        replaced here - the rule chosen in decisions_log.md is applied when the data roles are
        built (Steps 9-10), using these flags.
Output: 03_Data/interim/<SOURCE>_step06.csv (standardised table + flags),
        03_Data/interim/missing_values_report.csv, 03_Data/interim/step06_report.md
Check : every gas cell falls in exactly one category; category counts add up to 5 x records.
"""
from __future__ import annotations

import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import pandas as pd  # noqa: E402

from common import GASES, INTERIM, SOURCES, md_table, rel  # noqa: E402

PLACEHOLDER = 0.0001
CATS = ["measured", "zero", "placeholder", "blank"]


def classify(v: pd.Series) -> pd.Series:
    out = pd.Series("measured", index=v.index, dtype="object")
    out[v.isna()] = "blank"
    out[v == 0] = "zero"
    out[v == PLACEHOLDER] = "placeholder"
    return out


def main() -> int:
    rows, impact, ok = [], [], True
    for src in SOURCES:
        sid = src["source_id"]
        df = pd.read_csv(INTERIM / f"{sid}_standardised.csv")
        cats = pd.DataFrame({g: classify(df[g]) for g in GASES})
        for c in CATS:
            df[f"n_{c}"] = (cats == c).sum(axis=1)
        if not (df[[f"n_{c}" for c in CATS]].sum(axis=1) == len(GASES)).all():
            ok = False
        # not-available = blank or placeholder (the value was not reported by the source)
        df["n_not_available"] = df["n_blank"] + df["n_placeholder"]
        df["all_five_reported"] = df["n_not_available"] == 0
        df.to_csv(INTERIM / f"{sid}_step06.csv", index=False, encoding="utf-8")

        for g in GASES:
            counts = cats[g].value_counts()
            rows.append({"source_id": sid, "gas": g, **{c: int(counts.get(c, 0)) for c in CATS}})
        for label, grp in df.groupby("original_label", sort=True):
            impact.append({
                "source_id": sid, "class": label, "records": len(grp),
                "with_blank": int((grp["n_blank"] > 0).sum()),
                "with_placeholder": int((grp["n_placeholder"] > 0).sum()),
                "with_zero": int((grp["n_zero"] > 0).sum()),
                "kept_if_not_available_excluded": int(grp["all_five_reported"].sum()),
                "kept_if_not_available_and_zero_excluded": int(((grp["n_not_available"] + grp["n_zero"]) == 0).sum()),
            })
        print(f"{sid:<9} records={len(df):<4} blank={int(df['n_blank'].sum()):<3} "
              f"placeholder={int(df['n_placeholder'].sum()):<4} zero={int(df['n_zero'].sum()):<4} "
              f"records_all_five_reported={int(df['all_five_reported'].sum())}")

    by_gas = pd.DataFrame(rows)
    by_gas.to_csv(INTERIM / "missing_values_report.csv", index=False, encoding="utf-8")
    imp = pd.DataFrame(impact)
    imp.to_csv(INTERIM / "missing_values_impact_by_class.csv", index=False, encoding="utf-8")

    L = ["# Step 6 report - missing values", "",
         f"Run date: {date.today().isoformat()}. Script: `06_Python_ML/src/data_prep/step06_missing_values.py`.", "",
         "Cell categories: measured (positive value), zero (exactly 0), placeholder (exactly 0.0001 ppm, used by the "
         "Dissanayake files where no value was available), blank (empty cell; the dash in the IEC TC 10 tables). "
         "Blank and placeholder together are called 'not available'. Nothing was removed or replaced in this step.", "",
         "## Cells by gas", "", md_table(by_gas), "",
         "## Effect of each candidate rule on the records, by class", "",
         "`kept_if_not_available_excluded` = records left if every record with a blank or placeholder is dropped; "
         "`kept_if_not_available_and_zero_excluded` = records left if zeros are dropped as well.", "",
         md_table(imp), "",
         f"Check: every gas cell is in exactly one category - {'PASS' if ok else 'FAIL'}.", "",
         "## Rule applied downstream (decision D8, decisions_log.md)", "",
         "The missingness is informative: C2H2 is not available mainly in T1, T2, T3 and PD records and never in D1/D2, "
         "i.e. the gas was not detected. Primary analysis: not available = 0 ppm (not detected), flags kept. "
         "Sensitivity analysis: complete records only (`all_five_reported` = True)."]
    (INTERIM / "step06_report.md").write_text("\n".join(L) + "\n", encoding="utf-8")
    print(f"report: {rel(INTERIM / 'step06_report.md')}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
