"""Roadmap Step 18 checks: the independent Python implementation of the conventional methods reproduces the
published worked examples, follows decisions D11-D13 at the edges, and agrees with MATLAB on every record."""
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "06_Python_ML" / "src" / "conventional"))

import conventional_methods as cm  # noqa: E402

EX = pd.read_csv(ROOT / "02_Standards" / "worked_examples.csv")


def _gases(**kw):
    return pd.DataFrame([{g: float(kw.get(g, 0.0)) for g in cm.GASES}])


@pytest.mark.parametrize("row", EX[EX.method == "Duval Triangle 1"].to_dict("records"), ids=lambda r: r["example_id"])
def test_duval_worked_examples(row):
    g = pd.DataFrame([{k: (0.0 if pd.isna(row[k]) else row[k]) for k in cm.GASES}])  # blank = 0 ppm (D8)
    zone = cm.duval_zone(cm.ratios(g), cm.load_duval())[0]
    assert zone == row["diagnosis_printed"]


def test_rogers_worked_example_of_the_standard():
    row = EX[EX.method == "Rogers ratios"].iloc[0]
    g = pd.DataFrame([{k: row[k] for k in cm.GASES}])
    assert cm.ratio_method(cm.ratios(g), cm.load_rogers()) == ["D2"]          # Case 2 -> D2 (D11 rule 5)


def test_zero_denominator_gives_undefined_ratio_and_nd():
    g = _gases(H2=0, CH4=10, C2H6=0, C2H4=0, C2H2=0)
    r = cm.ratios(g)
    assert np.isnan(r.R1[0]) and np.isnan(r.R2[0]) and np.isnan(r.R5[0])
    assert cm.ratio_method(r, cm.load_rogers()) == ["ND"]
    assert np.isnan(cm.ratio_distance(r, cm.load_iec())[0])


def test_printed_range_includes_end_points():
    # IEC D1: C2H2/C2H4 > 1, CH4/H2 0.1 - 0.5 (inclusive by D11), C2H4/C2H6 > 1; R1 exactly 0.1
    r = pd.DataFrame({"R1": [0.1], "R2": [2.0], "R5": [2.0]})
    assert "D1" in cm.ratio_method(r, cm.load_iec())[0]


def test_iec_t1_needs_ch4_h2_above_one():
    # D13: PD-like sample (R1 < 0.1, R5 < 0.2) must not also be T1
    r = pd.DataFrame({"R1": [0.05], "R2": [np.nan], "R5": [0.1]})
    assert cm.ratio_method(r, cm.load_iec()) == ["PD"]


def test_normality_gate_uses_oltc_row_only_for_code_u():
    g = _gases(H2=10, CH4=10, C2H6=10, C2H4=10, C2H2=50)
    assert not cm.normality_gate(g, pd.Series([""]), "high")[0]     # 50 > 20 (no OLTC, upper end)
    assert cm.normality_gate(g, pd.Series(["U"]), "high")[0]        # 50 <= 280 (communicating OLTC)


def test_matlab_and_python_agree_on_every_record():
    chk = pd.read_csv(ROOT / "08_Statistical_Analysis" / "cross_language_check.csv")
    assert len(chk) == 3 * 827
    assert chk.all_same.all()
