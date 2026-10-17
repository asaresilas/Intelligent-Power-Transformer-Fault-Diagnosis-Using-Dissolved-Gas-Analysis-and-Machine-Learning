"""Roadmap Step 26 checks: the MATLAB table conventional_applicability.csv is reproduced by the independent Python
implementation on every row, and the rule of decision D23 holds in the saved table itself."""
import sys
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "06_Python_ML" / "src" / "conventional"))

import step26_crosscheck  # noqa: E402

TABLE = pd.read_csv(ROOT / "11_Results" / "conventional" / "conventional_applicability.csv")
GASES = ["H2", "CH4", "C2H6", "C2H4", "C2H2"]


def test_python_reproduces_all_465_rows():
    assert step26_crosscheck.main() == 0


def test_table_shape_and_columns():
    assert len(TABLE) == 31 * 3 * 5
    assert list(TABLE.columns[:8]) == ["subset_id", "n_gases", "method", "applicable", "data_role", "n_records", "n_nd", "share_nd"]


def test_single_removed_gas_gives_nd_for_ratio_methods():
    for gas in GASES:
        keep = "+".join(g for g in GASES if g != gas)
        sub = TABLE[(TABLE.subset_id == keep) & TABLE.method.isin(["IEC60599", "Rogers"])]
        assert len(sub) == 2 * 5 and (sub.applicable == 0).all() and (sub.share_nd == 1.0).all()


def test_five_gas_rows_match_the_steps_14_17_counts():
    counts = pd.read_csv(ROOT / "11_Results" / "conventional" / "conventional_counts.csv")
    five = TABLE[TABLE.subset_id == "+".join(GASES)]
    for _, c in counts.iterrows():
        row = five[(five.method == c.method) & (five.data_role == c.data_role)].iloc[0]
        assert row.n_nd == c.ND_final and row.n_records == c.n
