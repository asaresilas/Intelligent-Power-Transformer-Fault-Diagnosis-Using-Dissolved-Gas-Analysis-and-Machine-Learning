"""Tests of the Step 21 selection rule helpers (corrected resampled t-test, Eq. 28; simplicity order, D18)."""
import sys
from pathlib import Path

import numpy as np
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src" / "ml"))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src" / "data_prep"))

from step21_select_model import corrected_resampled_t, simplicity  # noqa: E402


def test_corrected_t_hand_value():
    # d = 0.1 and 0.3 repeated: mean 0.2; variance (ddof 1) of 50 values; ratio 0.25
    d = np.array([0.1, 0.3] * 25)
    var = d.var(ddof=1)
    t, p = corrected_resampled_t(d, 0.25)
    assert t == pytest.approx(0.2 / np.sqrt((1 / 50 + 0.25) * var))
    assert 0 < p < 1


def test_correction_is_more_conservative_than_paired_t():
    rng = np.random.default_rng(1)
    d = rng.normal(0.01, 0.03, 50)
    t_corr, _ = corrected_resampled_t(d, 0.25)
    t_plain = d.mean() / (d.std(ddof=1) / np.sqrt(50))
    assert abs(t_corr) < abs(t_plain)


def test_zero_differences():
    assert corrected_resampled_t(np.zeros(50), 0.25) == (0.0, 1.0)


def test_simplicity_order():
    assert simplicity("F4", "logistic_regression") < simplicity("F1", "svm")
    assert simplicity("F3", "xgboost") < simplicity("F4", "xgboost")
    assert simplicity("F1", "mlp") > simplicity("F4", "xgboost")
    assert simplicity("F1", "random_forest") == simplicity("F2", "random_forest")
