"""Load the versioned DGA model safely (decision D21).

The model file is a pickled scikit-learn pipeline that refers to the project modules features.py and pipelines.py, so this
folder must be importable; the file is refused if its SHA-256 differs from the recorded fingerprint.

    from model_io import load_model
    model = load_model()                      # 06_Python_ML/models/dga_model_v1.joblib
    model.predict(df[["H2", "CH4", "C2H6", "C2H4", "C2H2"]])   # gases in ppm; not detected = 0 (decision D8)
"""
from __future__ import annotations

import hashlib
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
MODELS = HERE.parents[1] / "models"
MODEL_V1 = MODELS / "dga_model_v1.joblib"
CLASS_NAMES = {0: "Normal", 1: "PD", 2: "D1", 3: "D2", 4: "T1", 5: "T2", 6: "T3"}


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def recorded_sha256(path: Path = MODEL_V1) -> str:
    return path.with_suffix(".sha256").read_text(encoding="utf-8").split()[0].strip().upper()


def load_model(path: Path = MODEL_V1):
    """Return the fitted pipeline after checking its fingerprint against <name>.sha256."""
    path = Path(path)
    got, want = sha256(path), recorded_sha256(path)
    if got != want:
        raise ValueError(f"{path.name}: SHA-256 {got} does not match the recorded {want}; refusing to load")
    if str(HERE) not in sys.path:
        sys.path.insert(0, str(HERE))      # the pickle refers to the modules features and pipelines
    import joblib
    return joblib.load(path)
