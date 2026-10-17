"""Tests of the reduced-gas feature rules (roadmap Step 25, decision D22)."""
import sys
from pathlib import Path

import numpy as np
import pandas as pd

ML = Path(__file__).resolve().parents[1] / "src" / "ml"
sys.path.insert(0, str(ML))
sys.path.insert(0, str(ML.parent / "data_prep"))

from features import GASES, FeatureBuilder  # noqa: E402
from step25_reduced_gas import SubsetFeatureBuilder, subset_feature_names, subsets  # noqa: E402

X = pd.DataFrame({"H2": [100.0, 0, 35], "CH4": [20.0, 5, 0], "C2H6": [3.0, 0, 7], "C2H4": [1.0, 0, 50],
                  "C2H2": [0.0, 0, 12]})


def test_31_subsets():
    s = subsets()
    assert len(s) == 31 and len(set(s)) == 31 and all(len(x) >= 1 for x in s)


def test_full_panel_equals_f4_exactly():
    a = SubsetFeatureBuilder(tuple(GASES)).transform(X)
    b = FeatureBuilder("F4").transform(X)
    assert a.shape == b.shape == (3, 18)
    assert np.array_equal(np.isnan(a), np.isnan(b)) and np.array_equal(np.nan_to_num(a), np.nan_to_num(b))
    assert list(SubsetFeatureBuilder(tuple(GASES)).get_feature_names_out()) == list(FeatureBuilder("F4").get_feature_names_out())


def test_ratio_only_with_both_gases():
    names = subset_feature_names(("H2", "CH4", "C2H4"))
    assert "log_R1" in names                      # CH4/H2
    assert not any(n in names for n in ("log_R2", "log_R3", "log_R4", "log_R5"))
    assert not any(n.startswith("duval_pct") for n in names)


def test_duval_needs_three_gases_and_single_gas_has_one_feature():
    assert any(n.startswith("duval_pct") for n in subset_feature_names(("CH4", "C2H4", "C2H2")))
    assert subset_feature_names(("H2",)) == ["log_H2"]
    assert SubsetFeatureBuilder(("H2",)).transform(X).shape == (3, 1)


def test_percentages_of_subset_sum_to_100():
    out = SubsetFeatureBuilder(("H2", "CH4")).transform(X)
    names = subset_feature_names(("H2", "CH4"))
    pct = out[:, [names.index("pct_H2"), names.index("pct_CH4")]]
    assert np.allclose(pct[[0, 1]].sum(axis=1), 100.0)
