"""Roadmap Step 31B [Claude Code] - Study 2: build the pooled, deduplicated data set (protocol D28, Study2_Protocol.docx).

Input : 03_Data/processed/dga_master.csv (data version 1.0); 11_Results/conventional/conventional_predictions.csv;
        the Study 2 protocol (its SHA-256 is checked against 03_Data/study2/study2_protocol.sha256).
Do    : (1) exact copies across sources (identical five gas values) kept once, priority IECTC10 > DISTRAIN > DISTEST > LI2019;
            label conflicts listed; (2) near-duplicate groups over ALL remaining records with the Step 10 rule (every gas within
            1 % or 1 ppm, transitive) - imported from step10_folds.near_groups; (3) six classes (T1 and T2 merged);
        (4) hybrid inputs: raw answers of IEC 60599, Rogers and Duval, upper/lower gate flags, three boundary distances
            (transformed at training time in Step 31C); (5) IEC TC 10 primary scope = power transformers (P, U), all = sensitivity.
Output: 03_Data/study2/study2_pooled.csv, study2_dedup_log.csv, study2_counts.csv, study2_data.sha256;
        03_Data/interim/step31b_report.md
Check : no exact copy left across sources; every label conflict listed; data version 1.0 unchanged.
"""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "data_prep"))

import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402

from common import INTERIM, PROCESSED, PROJECT_ROOT, md_table, verify_data_version  # noqa: E402
from step10_folds import near_groups  # noqa: E402

S2 = PROJECT_ROOT / "03_Data" / "study2"
GASES = ["H2", "CH4", "C2H6", "C2H4", "C2H2"]
PRIORITY = ["IECTC10", "DISTRAIN", "DISTEST", "LI2019"]
CLASSES6 = ["Normal", "PD", "D1", "D2", "T12", "T3"]
METHODS = ["IEC60599", "Rogers", "Duval"]


def sha256(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest().upper()


def main() -> int:
    problems = verify_data_version()
    if problems:
        raise SystemExit("data version 1.0 changed: " + "; ".join(problems))
    rec = (S2 / "study2_protocol.sha256").read_text(encoding="ascii").split()[0]
    assert sha256(PROJECT_ROOT / "00_Project_Admin" / "Study2_Protocol.docx") == rec, "protocol changed after registration"

    m = pd.read_csv(PROCESSED / "dga_master.csv")
    assert set(m.source_id) == set(PRIORITY)
    m["priority"] = m.source_id.map(PRIORITY.index)
    m["gas_key"] = m[GASES].round(6).astype(str).agg("|".join, axis=1)

    # (1) exact copies across sources
    m = m.sort_values(["priority", "record_id"]).reset_index(drop=True)
    log = []
    for key, g in m.groupby("gas_key", sort=False):
        if g.source_id.nunique() < 2:
            continue
        keep = g.iloc[0]
        for _, r in g.iloc[1:].iterrows():
            if r.source_id == keep.source_id:
                continue                                   # within-source near/exact copies are handled by groups
            log.append({"removed_record": r.record_id, "removed_source": r.source_id, "removed_label": r.class_merged,
                        "kept_record": keep.record_id, "kept_source": keep.source_id, "kept_label": keep.class_merged,
                        "label_conflict": bool(r.class_merged != keep.class_merged)})
    dlog = pd.DataFrame(log, columns=["removed_record", "removed_source", "removed_label", "kept_record", "kept_source",
                                      "kept_label", "label_conflict"])
    pooled = m[~m.record_id.isin(dlog.removed_record)].copy()

    # (2) near-duplicate groups over all remaining records (Step 10 rule)
    pooled = pooled.sort_values(["priority", "record_id"]).reset_index(drop=True)
    pooled["group_id"] = near_groups(pooled[GASES].to_numpy(float))
    gsrc = pooled.groupby("group_id").source_id.nunique()
    pooled["group_size"] = pooled.group_id.map(pooled.group_id.value_counts())
    pooled["cross_source_group"] = pooled.group_id.map(gsrc > 1)

    # (3) classes and scope
    pooled["class6"] = pooled.class_merged
    assert set(pooled.class6) <= set(CLASSES6)
    pooled["in_primary_scope"] = (pooled.source_id != "IECTC10") | pooled.in_scope_primary.astype(bool)

    # (4) hybrid inputs from the conventional methods (Steps 14-17)
    conv = pd.read_csv(PROJECT_ROOT / "11_Results" / "conventional" / "conventional_predictions.csv",
                       keep_default_na=False, na_values=["NaN", ""])
    for mth in METHODS:
        c = conv[conv.method == mth].set_index("record_id")
        pooled[f"{mth}_raw"] = pooled.record_id.map(c.raw_result)
        pooled[f"{mth}_distance"] = pooled.record_id.map(c.boundary_distance).astype(float)
    g = conv.groupby("record_id").first()
    pooled["gate_upper_normal"] = pooled.record_id.map(g.gate_upper.eq("Normal")).astype(int)
    pooled["gate_lower_normal"] = pooled.record_id.map(g.gate_lower.eq("Normal")).astype(int)
    assert pooled[[f"{x}_raw" for x in METHODS]].notna().all().all()

    cols = ["record_id", "source_id", "in_primary_scope", "class6", *GASES, "group_id", "group_size", "cross_source_group",
            *[f"{x}_raw" for x in METHODS], "gate_upper_normal", "gate_lower_normal", *[f"{x}_distance" for x in METHODS]]
    out = pooled[cols]
    S2.mkdir(parents=True, exist_ok=True)
    out.to_csv(S2 / "study2_pooled.csv", index=False)
    dlog.to_csv(S2 / "study2_dedup_log.csv", index=False)

    prim = out[out.in_primary_scope]
    counts = pd.crosstab(prim.source_id, prim.class6, margins=True, margins_name="All").reindex(columns=CLASSES6 + ["All"],
                                                                                                fill_value=0)
    counts.to_csv(S2 / "study2_counts.csv")
    # training records that would be removed for each held-out source (near-copies of held-out records), primary scope
    leak = []
    for s in PRIORITY:
        test_groups = set(prim.group_id[prim.source_id == s])
        tr = prim[prim.source_id != s]
        leak.append({"held_out": s, "n_test": int((prim.source_id == s).sum()), "n_train_before": len(tr),
                     "n_train_removed_near_copies": int(tr.group_id.isin(test_groups).sum()),
                     "n_train_used": int((~tr.group_id.isin(test_groups)).sum())})
    leak = pd.DataFrame(leak)
    leak.to_csv(S2 / "study2_loso_sizes.csv", index=False)

    # checks
    left = out.assign(k=out[GASES].round(6).astype(str).agg("|".join, axis=1)).groupby("k").source_id.nunique()
    checks = {"exact_copies_left_across_sources": int((left > 1).sum()), "records_removed": len(dlog),
              "label_conflicts": int(dlog.label_conflict.sum()), "pooled_records": len(out),
              "primary_scope_records": len(prim), "near_duplicate_groups_multi": int((out.group_size > 1).groupby(out.group_id).first().sum()),
              "cross_source_groups": int(gsrc.gt(1).sum()), "data_version_1_0_unchanged": True}
    assert checks["exact_copies_left_across_sources"] == 0
    (S2 / "study2_checks.json").write_text(json.dumps(checks, indent=1), encoding="utf-8")
    files = ["study2_pooled.csv", "study2_dedup_log.csv", "study2_counts.csv", "study2_loso_sizes.csv", "study2_checks.json"]
    (S2 / "study2_data.sha256").write_text("".join(f"{sha256(S2 / f)}  03_Data/study2/{f}\n" for f in files), encoding="ascii")

    rem = dlog.groupby(["removed_source", "kept_source"]).size().rename("records").reset_index()
    rep = ["# Step 31B report - Study 2 pooled data set", "", "Checks: " + json.dumps(checks), "",
           "## Exact copies removed (kept copy's source by priority)", "", md_table(rem), "",
           "## Records per source and class (primary scope)", "", md_table(counts.reset_index()), "",
           "## Leave-one-source-out sizes", "", md_table(leak), ""]
    (INTERIM / "step31b_report.md").write_text("\n".join(rep), encoding="utf-8")
    print("\n".join(rep))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
