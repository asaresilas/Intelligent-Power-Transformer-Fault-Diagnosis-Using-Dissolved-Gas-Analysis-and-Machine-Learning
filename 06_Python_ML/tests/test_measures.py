"""Measure functions of Step 29 checked against scikit-learn and a hand-computed Wilson interval (decision D25)."""
import sys
from pathlib import Path

import numpy as np
from sklearn.metrics import balanced_accuracy_score, cohen_kappa_score, f1_score, matthews_corrcoef

SRC = Path(__file__).resolve().parents[1] / "src"
for sub in ("stats", "data_prep", "analysis"):
    sys.path.insert(0, str(SRC / sub))

from step29_measures import (balanced_acc, effective, kappa_mcc, macro_f1, point_measures,  # noqa: E402
                             wilson)

LAB = ["Normal", "PD", "D1", "D2", "T1", "T2", "T3"]


def _rand(seed, n=90):
    rng = np.random.default_rng(seed)
    t = rng.choice(LAB, n).astype(object)
    p = t.copy()
    flip = rng.random(n) < 0.35
    p[flip] = rng.choice(LAB, flip.sum())
    return t, p


def test_against_sklearn_without_special_answers():
    for s in range(30):
        t, p = _rand(s)
        assert abs(macro_f1(t, p, LAB) - f1_score(t, p, labels=LAB, average="macro", zero_division=0)) < 1e-12
        assert abs(balanced_acc(t, p, LAB) - balanced_accuracy_score(t, p)) < 1e-12
        k, m = kappa_mcc(t, p)
        assert abs(k - cohen_kappa_score(t, p)) < 1e-12 and abs(m - matthews_corrcoef(t, p)) < 1e-12


def test_nd_and_dual_rules():
    t = np.array(["D1", "D2", "T3", "PD"], object)
    a = np.array(["D1/D2", "D1/D2", "D1/D2", "ND"], object)
    pm = point_measures(t, a, LAB, dual_ok=True)
    assert pm["n_correct"] == 2 and pm["n_nd"] == 1 and pm["coverage"] == 0.75
    assert abs(pm["conditional_accuracy"] - 2 / 3) < 1e-12 and pm["strict_accuracy"] == 0.5
    assert point_measures(t, a, LAB, dual_ok=False)["n_correct"] == 0
    assert list(effective(t, a, True)) == ["D1", "D2", "D1/D2", "ND"]


def test_wilson_hand_value():
    lo, hi = wilson(8, 10)                   # p = 0.8, n = 10, z = 1.96
    assert abs(lo - 0.4902) < 1e-4 and abs(hi - 0.9433) < 1e-4
