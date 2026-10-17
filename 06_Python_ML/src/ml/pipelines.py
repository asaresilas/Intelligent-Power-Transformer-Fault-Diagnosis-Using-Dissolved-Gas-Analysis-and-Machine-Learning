"""scikit-learn pipelines for the machine-learning step (roadmap Steps 19-24).

    gases (ppm) -> FeatureBuilder (F1-F4, stateless) -> SimpleImputer(median) -> StandardScaler -> BalancedClassifier

Everything that learns from data - the imputer medians, the scaler means and standard deviations, and the class
weights - is fitted inside the training fold only, because the whole chain is one Pipeline that is refitted on
every training fold (Analysis Plan Section 5; decision D15). Settings come from configs/ml_config.yaml.
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
import yaml
from sklearn.base import BaseEstimator, ClassifierMixin, clone
from sklearn.calibration import CalibratedClassifierCV
from sklearn.dummy import DummyClassifier
from sklearn.model_selection import StratifiedKFold
from sklearn.ensemble import RandomForestClassifier
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.neural_network import MLPClassifier
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.svm import SVC
from xgboost import XGBClassifier

from features import FeatureBuilder

CONFIG = Path(__file__).resolve().parents[2] / "configs" / "ml_config.yaml"


class PlattSVC(ClassifierMixin, BaseEstimator):
    """RBF support vector machine with Platt-scaled class probabilities (decision D16).

    scikit-learn 1.9 deprecates SVC(probability=True) (removal in 1.11) and recommends
    CalibratedClassifierCV(SVC(), ensemble=False) instead - the same sigmoid (Platt) calibration fitted on internal
    cross-validation predictions, with one SVC refitted on all the training rows. Predictions are the most probable
    class, so the predicted class and the probabilities always agree. Sample weights reach both the SVC and the
    calibration."""

    def __init__(self, C=1.0, gamma="scale", kernel="rbf", cv=5, random_state=None):
        self.C, self.gamma, self.kernel, self.cv, self.random_state = C, gamma, kernel, cv, random_state

    def fit(self, X, y, sample_weight=None):
        inner = StratifiedKFold(n_splits=self.cv, shuffle=True, random_state=self.random_state)
        svc = SVC(C=self.C, gamma=self.gamma, kernel=self.kernel)
        self.model_ = CalibratedClassifierCV(svc, method="sigmoid", ensemble=False, cv=inner)
        self.model_.fit(X, y, sample_weight=sample_weight)
        self.classes_ = self.model_.classes_
        return self

    def predict_proba(self, X):
        return self.model_.predict_proba(X)

    def predict(self, X):
        return self.classes_[np.argmax(self.predict_proba(X), axis=1)]


ESTIMATORS = {"DummyClassifier": DummyClassifier, "PlattSVC": PlattSVC, "RandomForestClassifier": RandomForestClassifier,
              "XGBClassifier": XGBClassifier, "MLPClassifier": MLPClassifier, "LogisticRegression": LogisticRegression}


def load_config() -> dict:
    return yaml.safe_load(CONFIG.read_text(encoding="utf-8"))


def balanced_weights(y) -> np.ndarray:
    """w_c = N / (K n_c) for every record of class c (Analysis Plan Eq. 14), from the labels given (the training fold)."""
    y = np.asarray(y)
    classes, counts = np.unique(y, return_counts=True)
    w = {c: len(y) / (len(classes) * n) for c, n in zip(classes, counts)}
    return np.array([w[v] for v in y])


class BalancedClassifier(ClassifierMixin, BaseEstimator):
    """Wraps a classifier so that (1) the class weights are computed from the labels of the data it is fitted on,
    i.e. from the training fold only, and (2) labels are encoded as 0..K-1 inside the fit (needed by XGBoost)."""

    def __init__(self, estimator=None, weighted: bool = True):
        self.estimator = estimator
        self.weighted = weighted

    def fit(self, X, y):
        self.label_encoder_ = LabelEncoder().fit(y)
        self.classes_ = self.label_encoder_.classes_
        yy = self.label_encoder_.transform(y)
        self.sample_weight_ = balanced_weights(yy) if self.weighted else None
        self.estimator_ = clone(self.estimator)
        if self.weighted:
            self.estimator_.fit(X, yy, sample_weight=self.sample_weight_)
        else:
            self.estimator_.fit(X, yy)
        return self

    def predict(self, X):
        return self.label_encoder_.inverse_transform(self.estimator_.predict(X).astype(int))

    def predict_proba(self, X):
        return self.estimator_.predict_proba(X)


def make_pipeline(feature_set: str, model: str, params: dict | None = None, config: dict | None = None) -> Pipeline:
    """One pipeline for a feature set (F1-F4) and a model name from ml_config.yaml; params override the grid values."""
    cfg = config or load_config()
    spec = cfg["models"][model]
    kw = dict(spec.get("fixed") or {})
    est_cls = ESTIMATORS[spec["estimator"]]
    if "random_state" in est_cls().get_params():
        kw["random_state"] = cfg["seed"]
    if "hidden_layer_sizes" in kw:
        kw["hidden_layer_sizes"] = tuple(kw["hidden_layer_sizes"])
    clf = BalancedClassifier(est_cls(**kw), weighted=bool(spec["weighted"]))
    pipe = Pipeline([
        ("features", FeatureBuilder(feature_set)),
        ("impute", SimpleImputer(strategy=cfg["preprocessing"]["imputer"])),
        ("scale", StandardScaler()),
        ("clf", clf),
    ])
    if params:
        pipe.set_params(**{f"clf__estimator__{k}": (tuple(v) if k == "hidden_layer_sizes" else v)
                           for k, v in params.items()})
    return pipe


def param_grid(model: str, config: dict | None = None) -> dict:
    """Search grid of a model in Pipeline parameter names (for GridSearchCV in Step 20)."""
    cfg = config or load_config()
    grid = cfg["models"][model].get("grid") or {}
    out = {}
    for k, vals in grid.items():
        vals = [tuple(v) if k == "hidden_layer_sizes" else v for v in vals]
        out[f"clf__estimator__{k}"] = vals
    return out
