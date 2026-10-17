"""Roadmap Step 5 [Claude Code] - load and standardise the raw datasets.

Input : 03_Data/raw (read-only) and the SHA-256 values recorded in the data cards.
Do    : verify each file's hash; read it without changing it; give the gases the shared
        names and order (H2, CH4, C2H6, C2H4, C2H2); add record_id, source and the
        original label; keep blanks as missing (never zero); flag zeros and invalid values.
Output: 03_Data/interim/<SOURCE>_standardised.csv, 03_Data/interim/step05_report.md,
        03_Data/raw/checksums.sha256
Check : hashes match the data cards and record counts equal 117; 584, 70, 49; 201.
        Exit code 1 if any hard check fails.

Run (isolated mode, from anywhere):
    06_Python_ML/.venv/Scripts/python.exe -I 06_Python_ML/src/data_prep/step05_standardise.py
"""
from __future__ import annotations

import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))  # -I mode does not add the script folder

import pandas as pd  # noqa: E402

from common import GASES, INTERIM, RAW, SOURCES, UNIT, rel, sha256_of  # noqa: E402


def read_source(src: dict) -> tuple[pd.DataFrame, list[str]]:
    """Read one raw file exactly as stored. Returns the frame and notes about its structure."""
    notes = []
    path = src["path"]
    if path.suffix.lower() == ".csv":
        df = pd.read_csv(path, dtype=str, keep_default_na=False)
    else:
        sheets = pd.ExcelFile(path, engine="openpyxl").sheet_names
        if len(sheets) != 1:
            notes.append(f"workbook has {len(sheets)} sheets {sheets}; only the first was read")
        df = pd.read_excel(path, sheet_name=0, dtype=str, keep_default_na=False, engine="openpyxl")
    return df, notes


def to_number(series: pd.Series) -> tuple[pd.Series, list[str]]:
    """Convert text cells to numbers. Empty cells become missing; any other text that is
    not a number is also made missing but listed so it can be inspected."""
    text = series.astype(str).str.strip()
    empty = text.eq("")
    num = pd.to_numeric(text.where(~empty), errors="coerce")
    bad = text[~empty & num.isna()]
    return num, sorted(set(bad.tolist()))


def standardise(src: dict) -> tuple[pd.DataFrame | None, dict]:
    path = src["path"]
    res = {"source_id": src["source_id"], "file": rel(path), "hard_fail": [], "notes": []}

    # 1. hash
    actual = sha256_of(path)
    res["sha256"] = actual
    if src["sha256"] is None:
        res["hash_status"] = "recorded now (no value in the data card yet)"
    elif actual == src["sha256"]:
        res["hash_status"] = "matches data card"
    else:
        res["hash_status"] = f"MISMATCH (card {src['sha256']})"
        res["hard_fail"].append("hash mismatch")

    # 2. read
    df, notes = read_source(src)
    res["notes"] += notes
    res["columns_in_file"] = list(df.columns)
    needed = GASES + [src["label_col"]] + src["extra_cols"]
    missing_cols = [c for c in needed if c not in df.columns]
    if missing_cols:
        res["hard_fail"].append(f"missing columns {missing_cols}")
        return None, res
    unexpected = [c for c in df.columns if c not in needed]
    if unexpected:
        res["notes"].append(f"columns not used by the project: {unexpected}")

    # 3. count
    res["n_rows"] = len(df)
    if len(df) != src["n_expected"]:
        res["hard_fail"].append(f"row count {len(df)} != expected {src['n_expected']}")

    # 4. build the standardised table
    out = pd.DataFrame({
        "record_id": [f"{src['source_id']}_{i:04d}" for i in range(1, len(df) + 1)],
        "source_id": src["source_id"],
        "source_file": rel(path),
        "source_line": range(2, len(df) + 2),  # line/row number in the original file (header = 1)
        "original_label": df[src["label_col"]].astype(str).str.strip(),
    })
    gas_checks = {}
    for g in GASES:
        num, bad = to_number(df[g])
        out[g] = num
        gas_checks[g] = {
            "missing": int(num.isna().sum()),
            "zero": int((num == 0).sum()),
            "negative": int((num < 0).sum()),
            "non_numeric_text": bad,
        }
        if gas_checks[g]["negative"]:
            res["hard_fail"].append(f"{g}: {gas_checks[g]['negative']} negative values")
        if bad:
            res["notes"].append(f"{g}: non-numeric text made missing: {bad}")
    for c in src["extra_cols"]:
        out[f"src_{c}"] = df[c]
    res["gas_checks"] = gas_checks
    res["label_counts"] = out["original_label"].value_counts().sort_index().to_dict()
    res["exact_duplicate_rows_within_file"] = int(out.duplicated(subset=GASES + ["original_label"]).sum())
    res["complete_records"] = int(out[GASES].notna().all(axis=1).sum())
    return out, res


def write_checksums() -> Path:
    target = RAW / "checksums.sha256"
    files = sorted(p for p in RAW.rglob("*") if p.is_file() and p.name != "checksums.sha256")
    lines = [f"{sha256_of(p).lower()}  {p.relative_to(RAW).as_posix()}" for p in files]
    target.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return target


def write_report(results: list[dict], checksum_file: Path) -> Path:
    L = [
        "# Step 5 report - load and standardise the raw datasets",
        "",
        f"Run date: {date.today().isoformat()}. Script: `06_Python_ML/src/data_prep/step05_standardise.py`.",
        "",
        f"Gas order and unit for every output file: {', '.join(GASES)} in {UNIT}. "
        "Units are not stated inside the Dissanayake and Li files; ppm (µL/L) is the DGA convention "
        "and is recorded as an assumption (TO VERIFY against the dataset pages).",
        "",
        "Blank cells are kept as missing (never replaced by zero). Zeros are counted, not changed.",
        "",
        f"Raw-file checksums written to `{rel(checksum_file)}`.",
        "",
        "## Summary",
        "",
        "| Source | File | Hash | Rows (expected) | Complete records | Exact duplicate rows | Result |",
        "|---|---|---|---|---|---|---|",
    ]
    exp = {s["source_id"]: s["n_expected"] for s in SOURCES}
    for r in results:
        verdict = "PASS" if not r["hard_fail"] else "FAIL: " + "; ".join(r["hard_fail"])
        L.append(f"| {r['source_id']} | `{r['file']}` | {r.get('hash_status', '')} | "
                 f"{r.get('n_rows', '-')} ({exp[r['source_id']]}) | {r.get('complete_records', '-')} | "
                 f"{r.get('exact_duplicate_rows_within_file', '-')} | {verdict} |")
    for r in results:
        L += ["", f"## {r['source_id']}", "", f"- SHA-256: `{r['sha256']}` ({r['hash_status']})",
              f"- Columns in file: {r.get('columns_in_file')}"]
        for n in r["notes"]:
            L.append(f"- Note: {n}")
        if "gas_checks" in r:
            L += ["", "| Gas | Missing | Zero | Negative | Non-numeric text |", "|---|---|---|---|---|"]
            for g, c in r["gas_checks"].items():
                L.append(f"| {g} | {c['missing']} | {c['zero']} | {c['negative']} | "
                         f"{', '.join(c['non_numeric_text']) or '-'} |")
            L += ["", "Original labels (count): " +
                  ", ".join(f"{k}: {v}" for k, v in r["label_counts"].items())]
    out = INTERIM / "step05_report.md"
    out.write_text("\n".join(L) + "\n", encoding="utf-8")
    return out


def main() -> int:
    INTERIM.mkdir(parents=True, exist_ok=True)
    results = []
    for src in SOURCES:
        table, res = standardise(src)
        if table is not None:
            target = INTERIM / f"{src['source_id']}_standardised.csv"
            table.to_csv(target, index=False, encoding="utf-8")
            res["output"] = rel(target)
        results.append(res)
        status = "PASS" if not res["hard_fail"] else "FAIL " + "; ".join(res["hard_fail"])
        print(f"{src['source_id']:<9} rows={res.get('n_rows', '-'):<4} "
              f"complete={res.get('complete_records', '-'):<4} hash={res['hash_status']:<45} {status}")
    checksum_file = write_checksums()
    report = write_report(results, checksum_file)
    print(f"report: {rel(report)}")
    print(f"checksums: {rel(checksum_file)}")
    return 1 if any(r["hard_fail"] for r in results) else 0


if __name__ == "__main__":
    sys.exit(main())
