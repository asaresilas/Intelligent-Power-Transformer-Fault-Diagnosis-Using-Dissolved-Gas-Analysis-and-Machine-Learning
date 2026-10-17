"""Tests of the versioned model (roadmap Step 24, decision D21): fingerprint guard and exact reproduction of Step 22."""
import shutil
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import pytest

ML = Path(__file__).resolve().parents[1] / "src" / "ml"
sys.path.insert(0, str(ML))

from model_io import CLASS_NAMES, MODEL_V1, load_model, sha256  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
pytestmark = pytest.mark.skipif(not MODEL_V1.exists(), reason="dga_model_v1.joblib not yet saved (Step 24)")


def test_fingerprint_matches_step22():
    import json
    fit = json.loads((ROOT / "07_Experiments" / "2026-10-12_final_fit" / "final_fit.json").read_text(encoding="utf-8"))
    assert sha256(MODEL_V1) == fit["pipeline_sha256"]


def test_reload_reproduces_step22_predictions():
    m = load_model()
    saved = pd.read_csv(ROOT / "11_Results" / "ml" / "ml_predictions.csv")
    master = pd.read_csv(ROOT / "03_Data" / "processed" / "dga_master.csv").set_index("record_id")
    X = master.loc[saved.record_id, ["H2", "CH4", "C2H6", "C2H4", "C2H2"]].reset_index(drop=True)
    pred = np.array([CLASS_NAMES[int(c)] for c in m.predict(X)])
    cols = [f"p_{CLASS_NAMES[int(c)]}" for c in m.named_steps["clf"].classes_]
    assert (pred == saved.y_pred.to_numpy()).all()
    assert np.array_equal(m.predict_proba(X), saved[cols].to_numpy())


def test_tampered_file_is_refused(tmp_path):
    bad = tmp_path / "dga_model_v1.joblib"
    shutil.copyfile(MODEL_V1, bad)
    with open(bad, "ab") as fh:
        fh.write(b"\0")
    shutil.copyfile(MODEL_V1.with_suffix(".sha256"), bad.with_suffix(".sha256"))
    with pytest.raises(ValueError, match="does not match"):
        load_model(bad)
