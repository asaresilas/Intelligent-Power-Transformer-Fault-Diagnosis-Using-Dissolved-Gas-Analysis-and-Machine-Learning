"""Study 2 models (protocol D28): pooled Random Forest on F4 (model B) and the hybrid model (model C).

Model C adds the conventional methods' inputs to the 18 F4 features: the raw answer of IEC 60599, Rogers and Duval (one-hot over
FIXED category lists, so every split has the same columns), the upper and lower normality-gate flags, and the three boundary
distances (infinite or undefined -> missing; a missing-value flag is added and the distance is filled with the training median by
the pipeline's imputer). Everything that learns (imputer, scaler, class and source weights, tuning) is fitted on training data only.
"""
from __future__ import annotations

import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "ml"))

import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402
from sklearn.base import BaseEstimator, TransformerMixin, clone  # noqa: E402
from sklearn.impute import SimpleImputer  # noqa: E402
from sklearn.pipeline import Pipeline  # noqa: E402
from sklearn.preprocessing import LabelEncoder, StandardScaler  # noqa: E402

from features import GASES, FeatureBuilder  # noqa: E402
from pipelines import BalancedClassifier, balanced_weights, load_config  # noqa: E402

CATEGORIES = {"IEC60599": ["PD", "D1", "D2", "D1/D2", "T1", "T2", "T3", "ND"],
              "Rogers": ["Normal", "PD", "D2", "T1", "T2", "T3", "ND"],
              "Duval": ["PD", "D1", "D2", "T1", "T2", "T3", "DT", "ND"]}
METHODS = list(CATEGORIES)


class HybridFeatures(BaseEstimator, TransformerMixin):
    """F4 + conventional inputs (stateless: the category lists are fixed, nothing is learned)."""

    def fit(self, X, y=None):
        return self

    def transform(self, X: pd.DataFrame) -> np.ndarray:
        f4 = FeatureBuilder("F4").transform(X[GASES])
        onehot = [np.column_stack([(X[f"{m}_raw"].to_numpy(object) == c).astype(float) for c in CATEGORIES[m]]) for m in METHODS]
        unknown = [~X[f"{m}_raw"].isin(CATEGORIES[m]) for m in METHODS]
        assert not any(u.any() for u in unknown), "answer outside the fixed category list"
        gates = X[["gate_upper_normal", "gate_lower_normal"]].to_numpy(float)
        dist = X[[f"{m}_distance" for m in METHODS]].to_numpy(float).copy()
        dist[~np.isfinite(dist)] = np.nan
        miss = np.isnan(dist).astype(float)
        return np.column_stack([f4, *onehot, gates, dist, miss])

    def get_feature_names_out(self, input_features=None):
        names = list(FeatureBuilder("F4").get_feature_names_out())
        names += [f"{m}_is_{c}" for m in METHODS for c in CATEGORIES[m]]
        names += ["gate_upper_normal", "gate_lower_normal"] + [f"{m}_distance" for m in METHODS]
        names += [f"{m}_distance_missing" for m in METHODS]
        return np.array(names, dtype=object)


class WeightedBalancedClassifier(BalancedClassifier):
    """BalancedClassifier that can also take per-record weights (equal-source-weight sensitivity analysis).
    With sample_weight=None it is identical to BalancedClassifier."""

    def fit(self, X, y, sample_weight=None):
        self.label_encoder_ = LabelEncoder().fit(y)
        self.classes_ = self.label_encoder_.classes_
        yy = self.label_encoder_.transform(y)
        w = balanced_weights(yy) if self.weighted else np.ones(len(yy))
        if sample_weight is not None:
            w = w * np.asarray(sample_weight, float)
        self.sample_weight_ = w
        self.estimator_ = clone(self.estimator)
        self.estimator_.fit(X, yy, sample_weight=w)
        return self


def build(model: str, seed: int, config: dict | None = None) -> Pipeline:
    """model 'B' (pooled, F4) or 'C' (hybrid); Random Forest with the Step 20 fixed settings, seeded."""
    cfg = config or load_config()
    from sklearn.ensemble import RandomForestClassifier
    kw = dict(cfg["models"]["random_forest"].get("fixed") or {})
    kw["random_state"] = seed
    feats = FeatureBuilder("F4") if model == "B" else HybridFeatures()
    return Pipeline([("features", feats), ("impute", SimpleImputer(strategy=cfg["preprocessing"]["imputer"])),
                     ("scale", StandardScaler()), ("clf", WeightedBalancedClassifier(RandomForestClassifier(**kw), weighted=True))])


def source_weights(sources: pd.Series) -> np.ndarray:
    """Equal total weight per training source: w = N / (S * n_s)."""
    n = sources.value_counts()
    return sources.map(len(sources) / (len(n) * n)).to_numpy(float)
