"""Roadmap Step 9 [Claude Code] - remove duplicates and audit leakage.

Input : 03_Data/interim/<SOURCE>_step08.csv; decision D8 (not available = 0 ppm).
Rules (fixed before looking at results):
  1. Gas values are harmonised with D8 (blank and 0.0001 -> 0) and compared rounded to 4 decimals.
  2. Exact duplicate within one source: keep the first (lowest source line). If identical gases carry
     different labels, drop all copies (the true label cannot be known).
  3. Leakage: a development record (DISTRAIN) that matches any test-role record (DISTEST, IECTC10,
     LI2019) exactly, or nearly (every gas within 1 % or 1 ppm), is removed from development.
  4. Overlaps between test roles are reported, not removed.
  5. DISIEC (Dissanayake's 49-row IEC file) is not used in any role - the full IEC TC 10 transcription
     replaces it - but its matches are traced to explain its origin.
  6. Where a Dissanayake record copies an IEC TC 10 case, its label is compared with the inspection label.
Output: 03_Data/processed/dga_master.csv, 03_Data/interim/duplicate_report.csv,
        03_Data/interim/label_agreement_iec.csv, 03_Data/interim/step09_report.md
Check : no development record matches a test-role record (exact or near); asserted here and in
        06_Python_ML/tests/test_no_leakage.py.
"""
from __future__ import annotations

import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402

from common import GASES, INTERIM, PROCESSED, SOURCES, md_table, rel  # noqa: E402

PLACEHOLDER = 0.0001
REL_TOL, ABS_TOL = 0.01, 1.0
ROLE = {"DISTRAIN": "development", "DISTEST": "internal_test", "IECTC10": "benchmark",
        "LI2019": "external_test", "DISIEC": "not_used"}
TEST_SOURCES = ["DISTEST", "IECTC10", "LI2019"]


def load() -> pd.DataFrame:
    frames = []
    for src in SOURCES:
        d = pd.read_csv(INTERIM / f"{src['source_id']}_step08.csv",
                        dtype={"original_label": str, "src_equipment_type": str})
        frames.append(d)
    df = pd.concat(frames, ignore_index=True)
    for g in GASES:
        df[f"orig_{g}"] = df[g]
        v = df[g].copy()
        v[v.isna() | (v == PLACEHOLDER)] = 0.0  # decision D8
        df[g] = v
    df["gas_key"] = df[GASES].round(4).astype(str).agg("|".join, axis=1)
    df["data_role"] = df["source_id"].map(ROLE)
    df["exclude_reason"] = ""
    return df


def near_matches(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    """Boolean matrix [len(a), len(b)]: every gas equal within REL_TOL relative or ABS_TOL ppm."""
    diff = np.abs(a[:, None, :] - b[None, :, :])
    scale = np.maximum(np.abs(a[:, None, :]), np.abs(b[None, :, :]))
    return (diff <= np.maximum(ABS_TOL, REL_TOL * scale)).all(axis=2)


def main() -> int:
    df = load()
    dup_rows = []

    # Rule 2: exact duplicates within each source
    for (sid, key), grp in df.groupby(["source_id", "gas_key"], sort=False):
        if len(grp) < 2:
            continue
        grp = grp.sort_values("source_line")
        labels = set(grp["class_merged"])
        if len(labels) == 1:
            keep = grp.index[0]
            for i in grp.index[1:]:
                df.at[i, "exclude_reason"] = f"exact duplicate within {sid} of {df.at[keep, 'record_id']}"
                dup_rows.append({"record_id": df.at[i, "record_id"], "source_id": sid, "match": "within_exact",
                                 "matched_record_id": df.at[keep, "record_id"], "matched_source": sid,
                                 "labels": "/".join(sorted(labels)), "action": "removed (copy)"})
        else:
            for i in grp.index:
                df.at[i, "exclude_reason"] = f"identical gases with conflicting labels within {sid}"
                dup_rows.append({"record_id": df.at[i, "record_id"], "source_id": sid, "match": "within_conflict",
                                 "matched_record_id": ";".join(grp["record_id"]), "matched_source": sid,
                                 "labels": "/".join(sorted(labels)), "action": "removed (label conflict)"})

    # Rules 3-6: matches across sources (exact or near), using records not already removed
    live = df[df["exclude_reason"] == ""]
    pairs = []
    sids = [s["source_id"] for s in SOURCES]
    for i, sa in enumerate(sids):
        for sb in sids[i + 1:]:
            A, B = live[live.source_id == sa], live[live.source_id == sb]
            if A.empty or B.empty:
                continue
            m = near_matches(A[GASES].to_numpy(float), B[GASES].to_numpy(float))
            for ia, ib in zip(*np.nonzero(m)):
                ra, rb = A.iloc[ia], B.iloc[ib]
                pairs.append({"a": ra.name, "b": rb.name, "source_a": sa, "source_b": sb,
                              "match": "cross_exact" if ra.gas_key == rb.gas_key else "cross_near"})
    pairs = pd.DataFrame(pairs, columns=["a", "b", "source_a", "source_b", "match"])

    for _, p in pairs.iterrows():
        a, b = df.loc[p.a], df.loc[p.b]
        dev, other = (a, b) if a.source_id == "DISTRAIN" else (b, a) if b.source_id == "DISTRAIN" else (None, None)
        if dev is not None and other.source_id in TEST_SOURCES:
            if df.at[dev.name, "exclude_reason"] == "":
                df.at[dev.name, "exclude_reason"] = f"leakage: matches {other.source_id} {other.record_id} ({p.match})"
            action = "removed from development (leakage)"
        else:
            action = "reported (no removal)"
        dup_rows.append({"record_id": a.record_id, "source_id": a.source_id, "match": p.match,
                         "matched_record_id": b.record_id, "matched_source": b.source_id,
                         "labels": f"{a.class_merged}/{b.class_merged}", "action": action})
    dup = pd.DataFrame(dup_rows)
    dup.to_csv(INTERIM / "duplicate_report.csv", index=False, encoding="utf-8")

    # Rule 6: label agreement where a Dissanayake record copies an IEC TC 10 case
    agree = []
    for _, p in pairs.iterrows():
        a, b = df.loc[p.a], df.loc[p.b]
        if "IECTC10" in (a.source_id, b.source_id) and {a.source_id, b.source_id} & {"DISTRAIN", "DISTEST", "DISIEC", "LI2019"}:
            iec, dis = (a, b) if a.source_id == "IECTC10" else (b, a)
            agree.append({"iec_record": iec.record_id, "iec_label": iec.class_merged,
                          "iec_equipment": iec.get("src_equipment_type", ""),
                          "dis_record": dis.record_id, "dis_source": dis.source_id,
                          "dis_fine_label": dis.class_name, "dis_merged_label": dis.class_merged,
                          "match": p.match, "same_merged_label": iec.class_merged == dis.class_merged})
    agree = pd.DataFrame(agree)
    agree.to_csv(INTERIM / "label_agreement_iec.csv", index=False, encoding="utf-8")

    # Test records that duplicate a benchmark (IEC TC 10) case are flagged, so that test sets reported as
    # separate evidence do not share records (decision D9).
    bench_ids = set(df.index[df.source_id == "IECTC10"])
    overlap = {}
    for _, p in pairs.iterrows():
        if p.a in bench_ids and df.at[p.b, "source_id"] in ("DISTEST", "LI2019"):
            overlap.setdefault(p.b, []).append(df.at[p.a, "record_id"])
        elif p.b in bench_ids and df.at[p.a, "source_id"] in ("DISTEST", "LI2019"):
            overlap.setdefault(p.a, []).append(df.at[p.b, "record_id"])
    df["benchmark_duplicate_of"] = [";".join(overlap.get(i, [])) for i in df.index]
    df["independent_of_benchmark"] = df["benchmark_duplicate_of"] == ""

    # Master table: usable records of the four roles
    keep = df[(df["exclude_reason"] == "") & (df["data_role"] != "not_used")].copy()
    cols = (["record_id", "source_id", "source_file", "source_line", "data_role", "original_label",
             "class_code", "class_name", "class_merged"] + GASES +
            ["n_blank", "n_placeholder", "n_zero", "all_five_reported", "in_scope_primary", "scope_reason",
             "independent_of_benchmark", "benchmark_duplicate_of",
             "src_equipment_type", "src_inspection", "src_ref"] + [f"orig_{g}" for g in GASES])
    master = keep[cols].rename(columns={"src_equipment_type": "equipment_type", "src_inspection": "inspection",
                                        "src_ref": "iec_ref"})
    PROCESSED.mkdir(parents=True, exist_ok=True)
    master.to_csv(PROCESSED / "dga_master.csv", index=False, encoding="utf-8")

    # Check: no development record matches a test-role record (exact or near)
    dev = master[master.data_role == "development"][GASES].to_numpy(float)
    tst = master[master.data_role.isin(["internal_test", "benchmark", "external_test"])][GASES].to_numpy(float)
    leaks = int(near_matches(dev, tst).sum()) if len(dev) and len(tst) else 0
    ok = leaks == 0

    # Report
    removed = df[df["exclude_reason"] != ""]
    rem_tab = (removed.assign(kind=removed["exclude_reason"].str.extract(r"^(leakage|exact duplicate|identical gases)")[0])
               .groupby(["source_id", "kind"]).size().reset_index(name="records"))
    leak_by_src = (removed[removed.exclude_reason.str.startswith("leakage")]
                   .exclude_reason.str.extract(r"matches (\w+)")[0].value_counts().rename_axis("matched source")
                   .reset_index(name="development records removed"))
    roles = master.groupby(["data_role", "class_merged"]).size().unstack(fill_value=0)
    roles.insert(0, "data_role", roles.index)
    pair_tab = (pairs.groupby(["source_a", "source_b", "match"]).size().reset_index(name="pairs")
                if len(pairs) else pd.DataFrame())
    L = ["# Step 9 report - duplicates and leakage audit", "",
         f"Run date: {date.today().isoformat()}. Script: `06_Python_ML/src/data_prep/step09_dedup_leakage.py`.", "",
         f"Comparison: gases harmonised with decision D8 (blank and 0.0001 -> 0), exact = equal to 4 decimals, "
         f"near = every gas within {REL_TOL:.0%} or {ABS_TOL:g} ppm.", "",
         "## Matching pairs between sources (before removal)", "", md_table(pair_tab) if len(pair_tab) else "None.", "",
         "## Records removed", "", md_table(rem_tab) if len(rem_tab) else "None.", "",
         "### Development records removed for leakage, by the test source they match", "",
         md_table(leak_by_src) if len(leak_by_src) else "None.", ""]
    if len(agree):
        dis_iec = agree[agree.dis_source != "DISIEC"]
        L += ["## Label agreement where Dissanayake or Li records copy IEC TC 10 cases", "",
              f"Pairs: {len(agree)} (DISTRAIN/DISTEST/LI2019: {len(dis_iec)}, DISIEC: {int((agree.dis_source == 'DISIEC').sum())}). "
              f"Same merged label as the inspection label: {int(agree.same_merged_label.sum())} of {len(agree)}.", "",
              md_table(agree.fillna({"dis_fine_label": "(merged T12)"}).groupby(["dis_source", "iec_label", "dis_fine_label"]).size()
                       .reset_index(name="pairs")), ""]
    disiec = df[df.source_id == "DISIEC"]
    matched_disiec = set(agree.loc[agree.dis_source == "DISIEC", "dis_record"]) if len(agree) else set()
    ind = master[master.data_role.isin(["internal_test", "external_test"])].groupby("data_role")["independent_of_benchmark"].agg(["size", "sum"])
    ind = ind.rename(columns={"size": "records", "sum": "independent of benchmark"}).reset_index()
    L += ["## Test records that duplicate benchmark cases (decision D9)", "",
          "A test record that matches an IEC TC 10 case is flagged `independent_of_benchmark` = False. Results reported as "
          "separate evidence from the internal or external test set use only the independent records; the full sets are "
          "reported as a sensitivity analysis.", "", md_table(ind), ""]
    L += ["## Origin of DISIEC (Dissanayake IEC_TC_10_data.xlsx)", "",
          f"{len(matched_disiec)} of {len(disiec)} rows match an IEC TC 10 Annex 1 case (exact or near); "
          f"{len(disiec) - len(matched_disiec)} do not (including its {int((disiec.class_merged == 'Normal').sum())} Normal rows, "
          "which Annex 1 cannot contain). DISIEC is not used in any role.", "",
          "## Master table (`03_Data/processed/dga_master.csv`) - records per role and class (merged scheme)", "",
          md_table(roles.reset_index(drop=True)), "",
          f"Total records in master: {len(master)}. IEC TC 10 records in scope for the primary benchmark (P, U): "
          f"{int(master[(master.data_role == 'benchmark') & master.in_scope_primary].shape[0])}.", "",
          f"Check: development records matching a test-role record (exact or near) = {leaks} - {'PASS' if ok else 'FAIL'}."]
    (INTERIM / "step09_report.md").write_text("\n".join(L) + "\n", encoding="utf-8")

    print(f"pairs across sources: {len(pairs)}; removed records: {len(removed)}; master records: {len(master)}")
    print(f"leakage check (dev vs tests, exact or near): {leaks} -> {'PASS' if ok else 'FAIL'}")
    print(f"report: {rel(INTERIM / 'step09_report.md')}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
