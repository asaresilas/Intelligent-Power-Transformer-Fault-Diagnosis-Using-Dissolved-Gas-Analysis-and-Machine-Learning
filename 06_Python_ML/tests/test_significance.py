"""Step 30 test functions checked against statsmodels/scipy and hand values (decision D26)."""
import sys
from pathlib import Path

import numpy as np
from scipy import stats
from statsmodels.stats.contingency_tables import cochrans_q, mcnemar as sm_mcnemar
from statsmodels.stats.multitest import multipletests

SRC = Path(__file__).resolve().parents[1] / "src"
for sub in ("stats", "data_prep", "analysis"):
    sys.path.insert(0, str(SRC / sub))

from step30_tests import cochran_q, friedman, holm, mcnemar, odds_ratio  # noqa: E402


def test_mcnemar_matches_statsmodels():
    for b, c in [(30, 10), (12, 3), (5, 5), (40, 39), (0, 7)]:
        table = [[0, b], [c, 0]]
        ours = mcnemar(b, c)
        ref = sm_mcnemar(table, exact=(b + c < 25), correction=True)
        assert abs(ours["p"] - ref.pvalue) < 1e-10


def test_holm_matches_statsmodels():
    p = [0.01, 0.04, 0.03]
    assert np.allclose(holm(p), multipletests(p, method="holm")[1])


def test_cochran_matches_statsmodels():
    rng = np.random.default_rng(1)
    x = (rng.random((60, 4)) < [0.8, 0.5, 0.6, 0.7]).astype(int)
    ref = cochrans_q(x)
    ours = cochran_q(x)
    assert abs(ours["Q"] - ref.statistic) < 1e-9 and abs(ours["p"] - ref.pvalue) < 1e-9


def test_friedman_matches_scipy_and_cd_table():
    rng = np.random.default_rng(2)
    s = rng.random((50, 6)) + np.arange(6) * 0.05
    ours = friedman(s)
    # scipy applies a tie correction; with continuous scores (no ties) both agree
    assert abs(ours["chi2"] - stats.friedmanchisquare(*s.T).statistic) < 1e-9
    assert abs(ours["q_alpha"] - 2.850) < 0.001          # Demsar (2006) table value for k = 6, alpha = 0.05


def test_odds_ratio_haldane():
    orr, lo, hi, corr = odds_ratio(6, 0)
    assert corr and abs(orr - 6.5 / 0.5) < 1e-12 and lo < orr < hi
