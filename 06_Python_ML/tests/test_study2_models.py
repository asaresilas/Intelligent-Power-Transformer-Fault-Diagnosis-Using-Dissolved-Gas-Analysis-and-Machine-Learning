"""Study 2 model components (Step 31C): hybrid features, weighted classifier, source weights, leakage-free splits."""
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import pytest

SRC = Path(__file__).resolve().parents[1] / "src"
for sub in ("study2", "ml", "data_prep"):
    sys.path.insert(0, str(SRC / sub))

from study2_models import CATEGORIES, HybridFeatures, WeightedBalancedClassifier, source_weights  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]


def _rows():
    return pd.DataFrame({"H2": [100.0, 5], "CH4": [20.0, 0], "C2H6": [3.0, 0], "C2H4": [1.0, 0], "C2H2": [0.0, 0],
                         "IEC60599_raw": ["PD", "ND"], "Rogers_raw": ["Normal", "ND"], "Duval_raw": ["PD", "ND"],
                         "gate_upper_normal": [0, 1], "gate_lower_normal": [0, 1],
                         "IEC60599_distance": [0.3, np.inf], "Rogers_distance": [0.2, np.nan], "Duval_distance": [5.0, 1.0]})


def test_hybrid_shape_and_flags():
    hf = HybridFeatures()
    X = hf.transform(_rows())
    names = list(hf.get_feature_names_out())
    assert X.shape == (2, len(names)) == (2, 18 + sum(len(v) for v in CATEGORIES.values()) + 2 + 3 + 3)
    assert X[1, names.index("IEC60599_distance_missing")] == 1 and np.isnan(X[1, names.index("IEC60599_distance")])
    assert X[0, names.index("IEC60599_is_PD")] == 1 and X[1, names.index("Duval_is_ND")] == 1


def test_unknown_answer_rejected():
    r = _rows()
    r.loc[0, "Duval_raw"] = "XX"
    with pytest.raises(AssertionError):
        HybridFeatures().transform(r)


def test_weighted_classifier_equals_balanced_without_weights():
    from sklearn.ensemble import RandomForestClassifier
    from pipelines import BalancedClassifier
    rng = np.random.default_rng(0)
    X, y = rng.normal(size=(80, 4)), rng.choice(["a", "b", "c"], 80)
    a = WeightedBalancedClassifier(RandomForestClassifier(n_estimators=20, random_state=1)).fit(X, y)
    b = BalancedClassifier(RandomForestClassifier(n_estimators=20, random_state=1)).fit(X, y)
    assert np.array_equal(a.predict_proba(X), b.predict_proba(X))


def test_source_weights_equal_totals():
    s = pd.Series(["A"] * 10 + ["B"] * 30)
    w = source_weights(s)
    assert abs(w[:10].sum() - w[10:].sum()) < 1e-12 and abs(w.sum() - 40) < 1e-12


@pytest.mark.skipif(not (ROOT / "03_Data" / "study2" / "study2_pooled.csv").exists(), reason="Step 31B not run")
def test_splits_have_no_leakage():
    from step31c_loso import SOURCES, load_pooled, split
    pool = load_pooled()
    for v in ("primary", "iec_all"):
        for s in SOURCES:
            tr, te = split(pool, s, v)
            assert not set(tr.group_id) & set(te.group_id) and (te.source_id == s).all() and (tr.source_id != s).all()
