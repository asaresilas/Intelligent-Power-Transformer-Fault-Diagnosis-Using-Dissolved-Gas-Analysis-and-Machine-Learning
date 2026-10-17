"""Step 12 - second, independent check of the transcribed standards tables.

1. Double entry: every value is typed a second time below (re-read from the
   source) and compared with the CSV files in 02_Standards.
2. Duval Triangle 1: the zone rules must cover the whole triangle with no gap
   and no overlap (PD is checked first, as the rule order says).
3. Worked examples: the zone rules must reproduce every Duval diagnosis printed
   in the sources.
4. The gas values of the Manisha et al. (2022) examples must be found in our own
   IEC TC 10 transcription (03_Data/raw/iec_tc10_duval2001_full).
Writes 02_Standards/transcription_check.md.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "data_prep"))
import numpy as np
import pandas as pd
from common import PROJECT_ROOT, RAW, md_table

STD = PROJECT_ROOT / "02_Standards"

# ---------------------------------------------------------------- second entry
# IEC 60599:1999+A1:2007 Table 2 (p.11) and Table 3 (p.12), re-typed.
IEC_SECOND = {
    ("PD", "C2H2/C2H4"): "NS", ("PD", "CH4/H2"): "<0.1", ("PD", "C2H4/C2H6"): "<0.2",
    ("D1", "C2H2/C2H4"): ">1", ("D1", "CH4/H2"): "0.1 - 0.5", ("D1", "C2H4/C2H6"): ">1",
    ("D2", "C2H2/C2H4"): "0.6 - 2.5", ("D2", "CH4/H2"): "0.1 - 1", ("D2", "C2H4/C2H6"): ">2",
    ("T1", "C2H2/C2H4"): "NS", ("T1", "CH4/H2"): ">1 but NS", ("T1", "C2H4/C2H6"): "<1",
    ("T2", "C2H2/C2H4"): "<0.1", ("T2", "CH4/H2"): ">1", ("T2", "C2H4/C2H6"): "1 - 4",
    ("T3", "C2H2/C2H4"): "<0.2", ("T3", "CH4/H2"): ">1", ("T3", "C2H4/C2H6"): ">4",
    ("PD-simplified", "CH4/H2"): "<0.2",
    ("D-simplified", "C2H2/C2H4"): ">0.2", ("T-simplified", "C2H2/C2H4"): "<0.2",
}
# IEC 60599:1999/AMD1:2007 Table A.2 (AMD1 p.3), re-typed: (group, gas) -> (low, high)
A2_SECOND = {
    ("All transformers", "H2"): (50, 150), ("All transformers", "CH4"): (30, 130),
    ("All transformers", "C2H4"): (60, 280), ("All transformers", "C2H6"): (20, 90),
    ("All transformers", "CO"): (400, 600), ("All transformers", "CO2"): (3800, 14000),
    ("No OLTC", "C2H2"): (2, 20), ("Communicating OLTC", "C2H2"): (60, 280),
}
# Duval Triangle 1, Moser (2025) Table 1, re-typed:
# zone, CH4 min/max, C2H4 min/max, C2H2 min/max (None = no limit)
DUVAL_SECOND = [
    ("PD", 98, None, None, None, None, None),
    ("T1", None, 98, None, 20, None, 4),
    ("T2", None, None, 20, 50, None, 4),
    ("T3", None, None, 50, None, None, 15),
    ("DT", None, None, None, 50, 4, 13),
    ("DT", None, None, 40, 50, 13, 29),
    ("DT", None, None, 50, None, 15, 29),
    ("D1", None, None, None, 23, 13, None),
    ("D2", None, None, 23, None, 29, None),
    ("D2", None, None, 23, 40, 13, 29),
]


# IEEE C57.104-2008 Table 6 (p.16), re-typed: case -> (R2 C2H2/C2H4, R1 CH4/H2, R5 C2H4/C2H6) as printed
ROGERS_SECOND = {
    0: ("<0.1", ">0.1 to <1.0", "<1.0"),
    1: ("<0.1", "<0.1", "<1.0"),
    2: ("0.1 to 3.0", "0.1 to 1.0", ">3.0"),
    3: ("<0.1", ">0.1 to <1.0", "1.0 to 3.0"),
    4: ("<0.1", ">1.0", "1.0 to 3.0"),
    5: ("<0.1", ">1.0", ">3.0"),
}
# IEEE C57.104-2008 Table 1 Condition 1 (p.10), re-typed
COND1_SECOND = {"H2": 100, "CH4": 120, "C2H2": 1, "C2H4": 50, "C2H6": 65, "CO": 350, "CO2": 2500, "TDCG": 720}


def check_rogers(rows):
    rg = pd.read_csv(STD / "rogers_ratio_table.csv")
    order = ["C2H2/C2H4 (R2)", "CH4/H2 (R1)", "C2H4/C2H6 (R5)"]
    bad = 0
    for _, r in rg.iterrows():
        expected = ROGERS_SECOND[int(r.case)][order.index(r.ratio)]
        ok = expected == r.as_printed
        bad += not ok
        rows.append(("Rogers (IEEE C57.104-2008 T6)", f"case {r.case} {r.ratio}", r.as_printed, expected, "PASS" if ok else "FAIL"))
    c1 = pd.read_csv(STD / "ieee_condition1_limits.csv")
    for _, r in c1.iterrows():
        ok = COND1_SECOND[r.gas] == r.condition1_limit_ppm
        bad += not ok
        rows.append(("IEEE Condition 1 limits (T1)", r.gas, r.condition1_limit_ppm, COND1_SECOND[r.gas], "PASS" if ok else "FAIL"))
    return bad, len(rg) + len(c1)


def rogers_case(rg, r2, r1, r5):
    """Cases whose three conditions hold (ranges with unstated end points taken as inclusive)."""
    vals = {"C2H2/C2H4 (R2)": r2, "CH4/H2 (R1)": r1, "C2H4/C2H6 (R5)": r5}
    hits = []
    for case, grp in rg.groupby("case"):
        ok = True
        for _, r in grp.iterrows():
            v = vals[r.ratio]
            if r.bound_type == "lt":
                ok &= v < r.upper
            elif r.bound_type == "gt":
                ok &= v > r.lower
            elif r.bound_type == "gt_lt":
                ok &= r.lower < v < r.upper
            else:
                ok &= r.lower <= v <= r.upper
        if ok:
            hits.append(int(case))
    return hits


def check_rogers_examples(rows):
    rg = pd.read_csv(STD / "rogers_ratio_table.csv")
    ex = pd.read_csv(STD / "worked_examples.csv")
    ex = ex[ex.method == "Rogers ratios"]
    bad = 0
    for _, e in ex.iterrows():
        hits = rogers_case(rg, e.C2H2 / e.C2H4, e.CH4 / e.H2, e.C2H4 / e.C2H6)
        printed = int(str(e.diagnosis_printed).split()[1])
        ok = hits == [printed]
        bad += not ok
        rows.append(("Rogers worked example", e.example_id, f"case {hits}", e.diagnosis_printed, "PASS" if ok else "FAIL"))
    return bad, len(ex)


def nz(v):
    return None if pd.isna(v) else float(v)


def check_iec(rows):
    iec = pd.read_csv(STD / "iec_ratio_table.csv")
    bad = 0
    for _, r in iec.iterrows():
        code = r.fault_code if "simplified" not in r.source_table else f"{r.fault_code}-simplified"
        expected = IEC_SECOND.get((code, r.ratio))
        ok = expected == r.as_printed
        bad += not ok
        rows.append(("IEC ratio table", f"{code} {r.ratio}", r.as_printed, expected, "PASS" if ok else "FAIL"))
    missing = set(IEC_SECOND) - {(r.fault_code if "simplified" not in r.source_table else f"{r.fault_code}-simplified", r.ratio) for _, r in iec.iterrows()}
    bad += len(missing)
    return bad, len(iec), missing


def check_a2(rows):
    a2 = pd.read_csv(STD / "iec_typical_values.csv")
    bad = 0
    for _, r in a2.iterrows():
        expected = A2_SECOND.get((r.group, r.gas))
        ok = expected == (r.low, r.high)
        bad += not ok
        rows.append(("IEC Table A.2", f"{r.group} {r.gas}", f"{r.low:g}-{r.high:g}", expected, "PASS" if ok else "FAIL"))
    return bad + len(set(A2_SECOND) - set(zip(a2.group, a2.gas))), len(a2)


def load_zones():
    z = pd.read_csv(STD / "duval_triangle_zones.csv").sort_values("rule_order")
    return [(r.zone, nz(r.pct_CH4_min), nz(r.pct_CH4_max), nz(r.pct_C2H4_min), nz(r.pct_C2H4_max),
             nz(r.pct_C2H2_min), nz(r.pct_C2H2_max)) for _, r in z.iterrows()]


def check_duval_entry(zones, rows):
    bad = 0
    for i, (a, b) in enumerate(zip(zones, DUVAL_SECOND), 1):
        ok = tuple(a) == tuple(None if v is None else (float(v) if not isinstance(v, str) else v) for v in b)
        bad += not ok
        rows.append(("Duval Triangle 1", f"rule {i} ({a[0]})", str(a[1:]), str(b[1:]), "PASS" if ok else "FAIL"))
    return bad + abs(len(zones) - len(DUVAL_SECOND))


def inside(rule, ch4, c2h4, c2h2):
    _, a, b, c, d, e, f = rule
    for v, lo, hi in ((ch4, a, b), (c2h4, c, d), (c2h2, e, f)):
        if lo is not None and v < lo:   # minimum is inclusive (>=)
            return False
        if hi is not None and v >= hi:  # maximum is exclusive (<)
            return False
    return True


def duval_zone(zones, ch4, c2h4, c2h2):
    """First matching rule in rule order (PD first)."""
    total = ch4 + c2h4 + c2h2
    p = [100 * x / total for x in (ch4, c2h4, c2h2)]
    for rule in zones:
        if inside(rule, *p):
            return rule[0]
    return None


def check_partition(zones):
    """Grid over the triangle in 0.1 % steps: count points with 0 or >1 zones."""
    step = 0.1
    gaps = overlaps = n = 0
    for c2h4 in np.arange(0, 100 + 1e-9, step):
        for c2h2 in np.arange(0, 100 - c2h4 + 1e-9, step):
            ch4 = max(0.0, 100 - c2h4 - c2h2)
            hits = {r[0] for r in zones if inside(r, ch4, c2h4, c2h2)}
            n += 1
            if not hits:
                gaps += 1
            elif len(hits) > 1 and hits != {"PD", "T1"}:
                overlaps += 1
    return n, gaps, overlaps


def check_examples(zones, rows):
    ex = pd.read_csv(STD / "worked_examples.csv")
    ex = ex[ex.method == "Duval Triangle 1"].copy()
    gas = ex[["CH4", "C2H4", "C2H2"]].fillna(0.0)  # blank = not detected = 0 ppm (D8)
    ex["diagnosis_rules"] = [duval_zone(zones, *g) for g in gas.itertuples(index=False)]
    bad = 0
    for _, r in ex.iterrows():
        ok = r.diagnosis_rules == r.diagnosis_printed
        bad += not ok
        rows.append(("Duval worked example", r.example_id, r.diagnosis_rules, r.diagnosis_printed, "PASS" if ok else "FAIL"))
    return bad, len(ex)


def check_manisha_in_tc10():
    tc10 = pd.read_csv(RAW / "iec_tc10_duval2001_full" / "iec_tc10_faulty_equipment.csv")
    ex = pd.read_csv(STD / "worked_examples.csv")
    ex = ex[ex.example_id.str.match(r"MAN-\d+")]
    cols = ["H2", "CH4", "C2H2", "C2H4", "C2H6"]
    key = lambda df: df[cols].fillna(-1).round(2).astype(str).agg("|".join, axis=1)
    found = key(ex).isin(set(key(tc10)))
    return int(found.sum()), len(ex), list(ex.example_id[~found])


def main():
    rows = []
    iec_bad, iec_n, iec_missing = check_iec(rows)
    a2_bad, a2_n = check_a2(rows)
    zones = load_zones()
    du_bad = check_duval_entry(zones, rows)
    n_grid, gaps, overlaps = check_partition(zones)
    ex_bad, ex_n = check_examples(zones, rows)
    man_found, man_n, man_missing = check_manisha_in_tc10()
    rg_bad, rg_n = check_rogers(rows)
    rx_bad, rx_n = check_rogers_examples(rows)

    summary = pd.DataFrame([
        ("IEC ratio table: CSV vs second entry", f"{iec_n - iec_bad} of {iec_n} agree", "PASS" if iec_bad == 0 else "FAIL"),
        ("IEC Table A.2: CSV vs second entry", f"{a2_n - a2_bad} of {a2_n} agree", "PASS" if a2_bad == 0 else "FAIL"),
        ("Duval Triangle 1 rules: CSV vs second entry", f"{len(zones) - du_bad} of {len(zones)} agree", "PASS" if du_bad == 0 else "FAIL"),
        ("Duval zones cover the triangle (0.1 % grid)", f"{n_grid} points, {gaps} gaps, {overlaps} overlaps (PD/T1 apex overlap resolved by rule order)", "PASS" if gaps == 0 and overlaps == 0 else "FAIL"),
        ("Duval worked examples reproduced", f"{ex_n - ex_bad} of {ex_n}", "PASS" if ex_bad == 0 else "FAIL"),
        ("Manisha et al. gas values found in our IEC TC 10 file", f"{man_found} of {man_n}" + (f" (not found: {', '.join(man_missing)})" if man_missing else ""), "PASS" if man_found == man_n else "CHECK"),
        ("Rogers table and Condition 1 limits: CSV vs second entry", f"{rg_n - rg_bad} of {rg_n} agree", "PASS" if rg_bad == 0 else "FAIL"),
        ("Rogers worked example of the standard reproduced", f"{rx_n - rx_bad} of {rx_n}", "PASS" if rx_bad == 0 else "FAIL"),
    ], columns=["Check", "Result", "Verdict"])

    detail = pd.DataFrame(rows, columns=["Table", "Item", "CSV value", "Second entry / printed", "Verdict"])
    text = [
        "# Step 12 - Transcription check (second, independent pass)", "",
        "Generated by `06_Python_ML/src/standards/step12_check_tables.py`. Every value in the CSV files was typed a "
        "second time from the source and compared automatically. Duval worked examples treat a blank gas as 0 ppm (decision D8).", "",
        "## Summary", "", md_table(summary), "",
        "## Status of the sources", "",
        "- IEC ratio table (Table 2 of Ed. 2.1, 2007) and Table A.2 (Amendment 1, 2007): PRIMARY, read from the official iTeh previews. "
        "The official change lists of Ed. 3.0 (2015) and Ed. 4.0 (2022) do not include these clauses, so the values are expected to be "
        "unchanged - TO VERIFY against the full IEC 60599:2022 text.",
        "- Duval Triangle 1 zones: SECONDARY (two agreeing sources) - TO VERIFY against IEC 60599:2022 Figure B.3 or IEEE C57.104-2019 clause 6.2.3.",
        "- Rogers ratios (IEEE C57.104-2008 Table 6) and Condition 1 limits (Table 1): transcribed from the standard; the copy "
        "consulted was not licensed to the researcher - TO VERIFY against a licensed copy before submission. The standard "
        "shows that both secondary versions contained an error (kept in rogers_secondary_versions.csv).", "",
        "## Item-by-item record", "", md_table(detail), "",
    ]
    (STD / "transcription_check.md").write_text("\n".join(text), encoding="utf-8")
    print(md_table(summary))
    if iec_missing:
        print("missing IEC items:", iec_missing)


if __name__ == "__main__":
    main()
