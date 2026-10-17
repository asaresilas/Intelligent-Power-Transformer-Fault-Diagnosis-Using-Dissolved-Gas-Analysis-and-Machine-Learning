"""Roadmap Step 19 checks: feature formulas, class weights, and - the key requirement - that every learned step
(imputer, scaler, class weights) sees the training rows only (Analysis Plan Section 5; decision D15)."""
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import pytest
from sklearn.base import clone
from sklearn.impute import SimpleImputer
from sklearn.model_selection import GridSearchCV, StratifiedKFold
from sklearn.preprocessing import StandardScaler

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "06_Python_ML" / "src" / "ml"))
sys.path.insert(0, str(ROOT / "06_Python_ML" / "src" / "data_prep"))

import pipelines as pl  # noqa: E402
from features import GASES, FeatureBuilder  # noqa: E402

CFG = pl.load_config()


@pytest.fixture(scope="module")
def dev():
    m = pd.read_csv(ROOT / "03_Data" / "processed" / "dga_master.csv")
    d = m[m.data_role == "development"].reset_index(drop=True)
    f = pd.read_csv(ROOT / "03_Data" / "processed" / "folds.csv").drop(columns=["class_code", "seed"])
    return d.merge(f, on="record_id", validate="one_to_one")


def test_feature_formulas_on_a_hand_example():
    g = pd.DataFrame([{"H2": 99.0, "CH4": 9.0, "C2H6": 0.0, "C2H4": 9.0, "C2H2": 0.0}])
    f1 = FeatureBuilder("F1").fit(g).transform(g)[0]
    assert np.allclose(f1, [2.0, 1.0, 0.0, 1.0, 0.0])                       # log10(x + 1)
    f2 = FeatureBuilder("F2").fit(g).transform(g)[0]
    assert np.isclose(f2.sum(), 100.0) and np.isclose(f2[0], 100 * 99 / 117)
    f3 = FeatureBuilder("F3").fit(g).transform(g)[0]
    assert np.isclose(f3[0], np.log10(10 / 100))                            # R1 = CH4/H2 with +1 ppm (D15)
    assert np.isclose(f3[1], np.log10(1 / 10))                              # R2 = C2H2/C2H4: C2H2 = 0 stays defined
    assert np.allclose(f3[5:], [50.0, 50.0, 0.0])                           # Duval percentages
    assert FeatureBuilder("F4").fit(g).transform(g).shape == (1, 18)


def test_undefined_duval_percentages_are_nan_before_imputation():
    g = pd.DataFrame([{"H2": 5.0, "CH4": 0.0, "C2H6": 3.0, "C2H4": 0.0, "C2H2": 0.0}])
    assert np.isnan(FeatureBuilder("F3").fit(g).transform(g)[0, 5:]).all()


def test_class_weights_follow_equation_14():
    y = np.array([0] * 6 + [1] * 3 + [2] * 1)
    w = pl.balanced_weights(y)
    assert np.allclose(w[:6], 10 / (3 * 6)) and np.allclose(w[6:9], 10 / (3 * 3)) and np.isclose(w[9], 10 / 3)
    assert np.allclose([w[y == c].sum() for c in (0, 1, 2)], 10 / 3)       # equal total weight per class


class SpyScaler(StandardScaler):
    seen = []

    def fit(self, X, y=None, sample_weight=None):
        SpyScaler.seen.append(np.asarray(X).copy())
        return super().fit(X, y, sample_weight)


class SpyImputer(SimpleImputer):
    seen = []

    def fit(self, X, y=None):
        SpyImputer.seen.append(np.asarray(X).copy())
        return super().fit(X, y)


def test_learned_steps_see_training_rows_only(dev):
    """Leakage test (roadmap Step 19 check): fit on one outer training fold and prove that the imputer, the scaler
    and the class weights were computed from exactly the training rows - none of the held-out fold."""
    X, y = dev[GASES], dev.class_code.astype(int).to_numpy()
    tr, va = (dev.rep01 != 1).to_numpy(), (dev.rep01 == 1).to_numpy()
    pipe = pl.make_pipeline("F4", "logistic_regression")
    pipe.set_params(impute=SpyImputer(strategy="median"), scale=SpyScaler())
    SpyScaler.seen.clear(); SpyImputer.seen.clear()
    pipe.fit(X[tr], y[tr])
    feats_tr = FeatureBuilder("F4").fit(X).transform(X[tr])
    feats_va = FeatureBuilder("F4").fit(X).transform(X[va])
    assert len(SpyImputer.seen) == 1 and np.array_equal(SpyImputer.seen[0], feats_tr, equal_nan=True)
    assert len(SpyScaler.seen) == 1 and SpyScaler.seen[0].shape[0] == tr.sum() and feats_va.shape[0] == va.sum()
    # the scaler saw exactly the imputed TRAINING features, and its mean is their mean, not the mean of all records
    imputed_tr = SimpleImputer(strategy="median").fit(feats_tr).transform(feats_tr)
    assert np.allclose(SpyScaler.seen[0], imputed_tr)
    assert np.allclose(pipe.named_steps["scale"].mean_, imputed_tr.mean(axis=0))
    all_feats = SimpleImputer(strategy="median").fit_transform(FeatureBuilder("F4").fit(X).transform(X))
    assert not np.allclose(pipe.named_steps["scale"].mean_, all_feats.mean(axis=0))
    # class weights from the training labels only
    assert np.allclose(pipe.named_steps["clf"].sample_weight_, pl.balanced_weights(y[tr]))


def test_learned_steps_are_refitted_inside_inner_folds(dev):
    """Inside GridSearchCV (Step 20) every inner training part refits the scaler on its own rows."""
    X, y = dev[GASES], dev.class_code.astype(int).to_numpy()
    pipe = pl.make_pipeline("F1", "logistic_regression")
    pipe.set_params(scale=SpyScaler())
    SpyScaler.seen.clear()
    inner = StratifiedKFold(n_splits=3, shuffle=True, random_state=CFG["seed"])
    GridSearchCV(pipe, {"clf__estimator__C": [1.0]}, cv=inner, scoring="f1_macro", refit=False).fit(X, y)
    sizes = sorted(s.shape[0] for s in SpyScaler.seen)
    expected = sorted(len(trn) for trn, _ in inner.split(X, y))
    assert sizes == expected                                                # never the full development set


@pytest.mark.parametrize("fs", ["F1", "F2", "F3", "F4"])
@pytest.mark.parametrize("model", list(CFG["models"]))
def test_every_pipeline_fits_and_predicts(dev, fs, model):
    X, y = dev[GASES], dev.class_code.astype(int).to_numpy()
    tr, va = (dev.rep01 != 1).to_numpy(), (dev.rep01 == 1).to_numpy()
    pipe = pl.make_pipeline(fs, model)
    if model in ("random_forest", "xgboost", "mlp", "svm"):
        pipe.set_params(**({"clf__estimator__n_estimators": 20} if model in ("random_forest", "xgboost") else {}))
    pipe.fit(X[tr], y[tr])
    p = pipe.predict_proba(X[va])
    assert np.allclose(p.sum(axis=1), 1.0)
    assert set(pipe.predict(X[va])) <= set(np.unique(y[tr]))
    assert clone(pipe).get_params()["features__feature_set"] == fs


def test_svm_prediction_is_the_most_probable_class(dev):
    X, y = dev[GASES], dev.class_code.astype(int).to_numpy()
    tr, va = (dev.rep01 != 1).to_numpy(), (dev.rep01 == 1).to_numpy()
    pipe = pl.make_pipeline("F1", "svm").fit(X[tr], y[tr])
    p = pipe.predict_proba(X[va])
    assert np.array_equal(pipe.predict(X[va]), pipe.named_steps["clf"].classes_[p.argmax(axis=1)])


def test_param_grids_match_the_analysis_plan():
    assert len(pl.param_grid("svm")["clf__estimator__C"]) == 4
    assert pl.param_grid("mlp")["clf__estimator__hidden_layer_sizes"] == [(16,), (32,), (32, 16)]
    assert pl.param_grid("majority") == {}
