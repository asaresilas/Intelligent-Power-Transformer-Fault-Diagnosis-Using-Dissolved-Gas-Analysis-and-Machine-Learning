"""Shared constants and helpers for the data-preparation steps (roadmap Steps 5-13).

Every value here traces to a data card in 03_Data/provenance or to the
approved analysis plan (00_Project_Admin/Expected_Results_and_Analysis_Plan.docx).
"""
from __future__ import annotations

import hashlib
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[3]
RAW = PROJECT_ROOT / "03_Data" / "raw"
INTERIM = PROJECT_ROOT / "03_Data" / "interim"
PROCESSED = PROJECT_ROOT / "03_Data" / "processed"

# Shared gas order and unit for every hand-over file (roadmap Section 3, rule 2).
GASES = ["H2", "CH4", "C2H6", "C2H4", "C2H2"]
UNIT = "ppm"

# Source registry. sha256 = value recorded in the data card (None = not recorded
# there yet; Step 5 records it). n_expected = verified record count in the card.
SOURCES = [
    {
        "source_id": "IECTC10",
        "path": RAW / "iec_tc10_duval2001_full" / "iec_tc10_faulty_equipment.csv",
        "card": "data_card_iec_tc10_duval2001_full.md",
        "sha256": None,
        "n_expected": 117,
        "label_col": "fault_class",
        "extra_cols": ["equipment_type", "inspection", "ref", "CO", "CO2"],
    },
    {
        "source_id": "DISTRAIN",
        "path": RAW / "ieee_dataport_1375187" / "DGA_train.xlsx",
        "card": "data_card_ieee_dataport_1375187.md",
        "sha256": "C1C376718D72A747B72CFF127839D5DF488913127CA096B911CC5586DFCEDBBF",
        "n_expected": 584,
        "label_col": "Fault class",
        "extra_cols": [],
    },
    {
        "source_id": "DISTEST",
        "path": RAW / "ieee_dataport_1375187" / "DGA_test_unseen.xlsx",
        "card": "data_card_ieee_dataport_1375187.md",
        "sha256": "23513C428C52F3BDB0508859CFB72CCC6E7639EF9BAF2165B6E03531945C2EAA",
        "n_expected": 70,
        "label_col": "Fault class",
        "extra_cols": [],
    },
    {
        "source_id": "DISIEC",
        "path": RAW / "ieee_dataport_1375187" / "IEC_TC_10_data.xlsx",
        "card": "data_card_ieee_dataport_1375187.md",
        "sha256": "2B5B128ABF38533E83E021D923328A7E879AF73034CFBF1428BDBCBD9F791C3F",
        "n_expected": 49,
        "label_col": "Fault class",
        "extra_cols": [],
    },
    {
        "source_id": "LI2019",
        "path": RAW / "ieee_dataport_7226" / "DGA dataset.xlsx",
        "card": "data_card_ieee_dataport_7226.md",
        "sha256": "B797638252DB69C02FC86AE834FA7752DCAF1EBE4AA32E8CBBB457915322CAC3",
        "n_expected": 201,
        "label_col": "Type",
        "extra_cols": ["NM"],
    },
]


def sha256_of(path: Path) -> str:
    """Upper-case hex SHA-256 of a file (same format as the data cards)."""
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def md_table(df) -> str:
    """Render a pandas DataFrame as a Markdown table (no extra dependency)."""
    cols = [str(c) for c in df.columns]
    lines = ["| " + " | ".join(cols) + " |", "|" + "---|" * len(cols)]
    for row in df.itertuples(index=False):
        lines.append("| " + " | ".join("" if v is None else str(v) for v in row) + " |")
    return "\n".join(lines)


def rel(path: Path) -> str:
    """Path relative to the project root, with forward slashes (for reports)."""
    return path.resolve().relative_to(PROJECT_ROOT).as_posix()


DATA_VERSION = "1.0"


def manifest_path(version: str = DATA_VERSION) -> Path:
    """Fingerprint list of a frozen data version (roadmap Step 13)."""
    return PROJECT_ROOT / "03_Data" / f"data_version_{version}.sha256"


def verify_data_version(version: str = DATA_VERSION) -> list[str]:
    """Return the files whose SHA-256 differs from the frozen manifest (empty list = all identical).
    Every step after Step 13 calls this before reading the data."""
    problems = []
    for line in manifest_path(version).read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        digest, name = line.split("  ", 1)
        path = PROJECT_ROOT / name
        if not path.exists():
            problems.append(f"missing: {name}")
        elif sha256_of(path) != digest.upper():
            problems.append(f"changed: {name}")
    return problems
