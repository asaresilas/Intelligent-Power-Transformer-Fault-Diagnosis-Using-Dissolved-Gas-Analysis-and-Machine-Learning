"""The fast macro-F1 of Step 27 must equal scikit-learn's macro-F1 over the seven classes (as used in Step 20)."""
import sys
from pathlib import Path

import numpy as np
from sklearn.metrics import f1_score

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src" / "ml"))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src" / "data_prep"))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src" / "analysis"))

from step27_minimum_panel import macro_f1_from_codes  # noqa: E402


def test_fast_macro_f1_equals_sklearn():
    rng = np.random.default_rng(3)
    for _ in range(200):
        yt, yp = rng.integers(0, 7, 120), rng.integers(0, 7, 120)
        mask = rng.random(120) < 0.6               # make most predictions correct, like a real classifier
        yp[mask] = yt[mask]
        ref = f1_score(yt, yp, labels=list(range(7)), average="macro", zero_division=0)
        assert abs(macro_f1_from_codes(yt, yp) - ref) < 1e-12


def test_missing_classes_count_as_zero():
    yt = np.array([0, 0, 1, 1])
    yp = np.array([0, 0, 1, 2])
    ref = f1_score(yt, yp, labels=list(range(7)), average="macro", zero_division=0)
    assert abs(macro_f1_from_codes(yt, yp) - ref) < 1e-12
