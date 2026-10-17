"""Feature sets F1-F4 of the Analysis Plan (Section 5.1), with the zero handling of decision D15.

The feature builder is STATELESS: every value is computed from one record's own five gases, so it learns nothing
from other records and cannot leak information between training and validation folds. Everything that is
learned from data (imputation, scaling, class weights) happens later in the pipeline, inside the training fold.

  log_gas    x~_g = log10(x_g + 1)                                    Eq. 11   (5 features)
  pct_gas    p_g  = 100 x_g / (H2 + CH4 + C2H6 + C2H4 + C2H2)         Eq. 12   (5 features)
  log_ratio  log10((a + 1)/(b + 1)) for R1 = CH4/H2, R2 = C2H2/C2H4,          (5 features, D15 (1);
             R3 = C2H2/CH4, R4 = C2H6/C2H2, R5 = C2H4/C2H6                     ratio names: IEEE C57.104-2008 6.7)
  duval_pct  100 g / (CH4 + C2H4 + C2H2) for g = CH4, C2H4, C2H2      Eq. 4    (3 features; NaN when the sum is
                                                                               0 - imputed in the fold, D15 (2))
"""
from __future__ import annotations

import numpy as np
import pandas as pd
from sklearn.base import BaseEstimator, TransformerMixin

GASES = ["H2", "CH4", "C2H6", "C2H4", "C2H2"]
RATIOS = {"R1": ("CH4", "H2"), "R2": ("C2H2", "C2H4"), "R3": ("C2H2", "CH4"),
          "R4": ("C2H6", "C2H2"), "R5": ("C2H4", "C2H6")}
BLOCKS = {
    "log_gas": [f"log_{g}" for g in GASES],
    "pct_gas": [f"pct_{g}" for g in GASES],
    "log_ratio": [f"log_{r}" for r in RATIOS],
    "duval_pct": ["duval_pct_CH4", "duval_pct_C2H4", "duval_pct_C2H2"],
}
FEATURE_SETS = {
    "F1": ["log_gas"],
    "F2": ["pct_gas"],
    "F3": ["log_ratio", "duval_pct"],
    "F4": ["log_gas", "pct_gas", "log_ratio", "duval_pct"],
}


def block(name: str, g: pd.DataFrame) -> np.ndarray:
    x = {k: g[k].to_numpy(float) for k in GASES}
    if name == "log_gas":
        return np.column_stack([np.log10(x[k] + 1.0) for k in GASES])
    if name == "pct_gas":
        tot = sum(x[k] for k in GASES)
        with np.errstate(divide="ignore", invalid="ignore"):
            return np.column_stack([np.where(tot > 0, 100.0 * x[k] / tot, np.nan) for k in GASES])
    if name == "log_ratio":
        return np.column_stack([np.log10((x[a] + 1.0) / (x[b] + 1.0)) for a, b in RATIOS.values()])
    if name == "duval_pct":
        s = x["CH4"] + x["C2H4"] + x["C2H2"]
        with np.errstate(divide="ignore", invalid="ignore"):
            return np.column_stack([np.where(s > 0, 100.0 * x[k] / s, np.nan) for k in ["CH4", "C2H4", "C2H2"]])
    raise ValueError(f"unknown feature block {name}")


class FeatureBuilder(BaseEstimator, TransformerMixin):
    """Turns the five gas columns (ppm) into feature set F1, F2, F3 or F4. Stateless: fit() learns nothing."""

    def __init__(self, feature_set: str = "F1"):
        self.feature_set = feature_set

    def fit(self, X, y=None):
        if self.feature_set not in FEATURE_SETS:
            raise ValueError(f"unknown feature set {self.feature_set}")
        self.n_features_in_ = len(GASES)
        return self

    def transform(self, X):
        g = X if isinstance(X, pd.DataFrame) else pd.DataFrame(np.asarray(X, float), columns=GASES)
        return np.column_stack([block(b, g[GASES]) for b in FEATURE_SETS[self.feature_set]])

    def get_feature_names_out(self, input_features=None):
        return np.array([n for b in FEATURE_SETS[self.feature_set] for n in BLOCKS[b]], dtype=object)
