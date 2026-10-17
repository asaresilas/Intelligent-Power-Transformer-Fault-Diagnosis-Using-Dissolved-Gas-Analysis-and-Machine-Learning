"""Step 31 logistic regression checked against statsmodels; Firth reduces an infinite estimate to a finite one (D27)."""
import sys
from pathlib import Path

import numpy as np
import statsmodels.api as sm

SRC = Path(__file__).resolve().parents[1] / "src"
for sub in ("stats", "data_prep", "analysis"):
    sys.path.insert(0, str(SRC / sub))

from step31_boundary import disagree, logit_fit  # noqa: E402


def test_ml_logit_matches_statsmodels():
    rng = np.random.default_rng(4)
    x = rng.normal(size=200)
    y = (rng.random(200) < 1 / (1 + np.exp(-(0.3 - 0.8 * x)))).astype(int)
    X = np.column_stack([np.ones(200), x])
    ours = logit_fit(X, y)
    ref = sm.Logit(y, X).fit(disp=0)
    assert np.allclose(ours["beta"], ref.params, atol=1e-8) and np.allclose(ours["se"], ref.bse, atol=1e-8)


def test_firth_finite_under_separation():
    x = np.array([-2, -1.5, -1, -0.5, 0.5, 1, 1.5, 2.0])
    y = np.array([1, 1, 1, 1, 0, 0, 0, 0])
    f = logit_fit(np.column_stack([np.ones(8), x]), y, firth=True)
    assert np.isfinite(f["beta"]).all() and f["beta"][1] < 0


def test_disagreement_rule():
    ml = np.array(["D1", "D2", "T3", "PD"], object)
    ans = np.array(["D1/D2", "D1/D2", "D1/D2", "ND"], object)
    assert list(disagree(ml, ans)) == [0, 0, 1, 1]
