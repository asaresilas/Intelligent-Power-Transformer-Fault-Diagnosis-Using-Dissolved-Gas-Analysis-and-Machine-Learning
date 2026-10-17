"""Roadmap Step 7 [Claude Code] - harmonise the fault labels.

Input : 03_Data/interim/<SOURCE>_step06.csv; decisions D3 and analysis-plan items 6-7 (decisions_log.md).
Do    : map every original label onto
          class_code / class_name - shared fine scheme 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3
                                    (empty when the source does not separate T1 and T2)
          class_merged            - scheme with T1 and T2 merged (Normal, PD, D1, D2, T12, T3), used to
                                    score sources that cannot separate T1 from T2
        Every map row states its reason and evidence.
Output: 03_Data/processed/label_map.csv, 03_Data/interim/<SOURCE>_step07.csv, 03_Data/interim/step07_report.md
Check : every original label in every source maps to exactly one row; no record left unmapped.
"""
from __future__ import annotations

import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import pandas as pd  # noqa: E402

from common import INTERIM, PROCESSED, SOURCES, md_table, rel  # noqa: E402

FINE = {0: "Normal", 1: "PD", 2: "D1", 3: "D2", 4: "T1", 5: "T2", 6: "T3"}
MERGE = {"Normal": "Normal", "PD": "PD", "D1": "D1", "D2": "D2", "T1": "T12", "T2": "T12", "T3": "T3"}

DP_PAGE = "IEEE DataPort 'DGA dataset' page (DOI 10.21227/27vy-h479): 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3"
IEC_REF = "Duval & dePablo (2001), Annex 1 Tables 2-6 (faults identified by inspection)"
LI_REF = "Li (2019) label text; analysis-plan item 7; Duval & dePablo (2001) Annex 1 puts sparking cases in D1 (Table 3) and arcing cases in D2 (Table 4)"

# (source_id, original_label, class_code or None, reason, evidence)
ROWS = []
for sid in ["DISTRAIN", "DISTEST", "DISIEC"]:
    for code, name in FINE.items():
        ROWS.append((sid, str(code), code, f"Dataset code {code} = {name}, used as given", DP_PAGE))
ROWS += [
    ("IECTC10", "PD", 1, "Partial discharges identified by inspection (Table 2)", IEC_REF),
    ("IECTC10", "D1", 2, "Low-energy discharges identified by inspection (Table 3)", IEC_REF),
    ("IECTC10", "D2", 3, "High-energy discharges identified by inspection (Table 4)", IEC_REF),
    ("IECTC10", "T1/T2", None, "Table 5 combines T1 and T2 (< 700 C) and does not say which row is which; merged class T12 (plan item 6)", IEC_REF),
    ("IECTC10", "T3", 6, "Thermal faults > 700 C identified by inspection (Table 6)", IEC_REF),
    ("LI2019", "Partial discharge", 1, "Same fault type", LI_REF),
    ("LI2019", "Spark discharge", 2, "Sparking = low-energy discharge (D1)", LI_REF),
    ("LI2019", "Arc discharge", 3, "Arcing = high-energy discharge (D2)", LI_REF),
    ("LI2019", "Low-temperature overheating", 4, "Low-temperature thermal fault = T1; Li's temperature bands TO VERIFY", LI_REF),
    ("LI2019", "Middle-temperature overheating", 5, "Middle-temperature thermal fault = T2; Li's temperature bands TO VERIFY", LI_REF),
    ("LI2019", "High-temperature overheating", 6, "High-temperature thermal fault = T3; Li's temperature bands TO VERIFY", LI_REF),
    ("LI2019", "Low/Middle-temperature overheating", None, "Spans T1 and T2; merged class T12 (plan item 7)", LI_REF),
]


def build_map() -> pd.DataFrame:
    recs = []
    for sid, orig, code, reason, ev in ROWS:
        if code is None:
            name, merged = "", "T12"
        else:
            name, merged = FINE[code], MERGE[FINE[code]]
        recs.append({"source_id": sid, "original_label": orig,
                     "class_code": "" if code is None else code, "class_name": name,
                     "class_merged": merged, "reason": reason, "evidence": ev})
    m = pd.DataFrame(recs)
    if m.duplicated(["source_id", "original_label"]).any():
        raise SystemExit("label map has duplicate keys")
    return m


def main() -> int:
    PROCESSED.mkdir(parents=True, exist_ok=True)
    lmap = build_map()
    lmap.to_csv(PROCESSED / "label_map.csv", index=False, encoding="utf-8")
    key = lmap.set_index(["source_id", "original_label"])

    ok, counts = True, []
    for src in SOURCES:
        sid = src["source_id"]
        df = pd.read_csv(INTERIM / f"{sid}_step06.csv", dtype={"original_label": str})
        labels = df["original_label"].astype(str)
        unmapped = sorted(set(labels) - set(lmap.loc[lmap.source_id == sid, "original_label"]))
        if unmapped:
            ok = False
            print(f"{sid}: UNMAPPED labels {unmapped}")
            continue
        sub = key.loc[sid]
        df["class_code"] = labels.map(sub["class_code"]).replace("", pd.NA)
        df["class_name"] = labels.map(sub["class_name"]).replace("", pd.NA)
        df["class_merged"] = labels.map(sub["class_merged"])
        df.to_csv(INTERIM / f"{sid}_step07.csv", index=False, encoding="utf-8")
        c = df.groupby("class_merged").size()
        counts.append({"source_id": sid, "records": len(df),
                       **{k: int(c.get(k, 0)) for k in ["Normal", "PD", "D1", "D2", "T12", "T3"]},
                       "T1": int((df["class_name"] == "T1").sum()), "T2": int((df["class_name"] == "T2").sum()),
                       "fine_label_missing": int(df["class_code"].isna().sum())})
        print(f"{sid:<9} records={len(df):<4} mapped=all  fine-class unknown (T12 only)={int(df['class_code'].isna().sum())}")

    cnt = pd.DataFrame(counts)
    L = ["# Step 7 report - harmonised fault labels", "",
         f"Run date: {date.today().isoformat()}. Script: `06_Python_ML/src/data_prep/step07_label_map.py`.", "",
         "Fine scheme: 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3. Merged scheme: T1 and T2 combined as T12 "
         "(used to score the IEC TC 10 benchmark and the Li 2019 records that do not separate T1 from T2).", "",
         "## Label map (`03_Data/processed/label_map.csv`)", "", md_table(lmap), "",
         "## Records per class after mapping", "",
         "Columns Normal to T3 use the merged scheme; T1 and T2 give the split where the source provides it.", "",
         md_table(cnt), "",
         f"Check: every original label maps to exactly one row - {'PASS' if ok else 'FAIL'}."]
    (INTERIM / "step07_report.md").write_text("\n".join(L) + "\n", encoding="utf-8")
    print(f"report: {rel(INTERIM / 'step07_report.md')}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
