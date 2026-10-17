"""Tests of the integration evaluation (roadmap Step 42, decision D40): fidelity rules on small examples and the saved results."""
import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src" / "analysis"))

import step42_integration as s42  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
pytestmark = pytest.mark.skipif(not s42.LOG.exists(), reason="test-bench log of Step 41 not present")


def tiny():
    probs = {f"p_{c}": [1.0 if c == "PD" else 0.0, 1.0 if c == "T3" else 0.0, 1.0 if c == "D1" else 0.0] for c in s42.CLASSES}
    ml = pd.DataFrame({"record_id": ["a", "b", "c"], "data_role": ["benchmark"] * 3, "y_pred": ["PD", "T3", "D1"], **probs})
    conv = pd.DataFrame({"record_id": ["a", "b", "c"], "offline_Rogers": ["ND"] * 3, "offline_IEC60599": ["PD"] * 3,
                         "offline_Duval": ["PD"] * 3})
    log = pd.DataFrame({"record_id": ["a", "b"], "data_role": ["benchmark"] * 2, "ml_status": ["OK", "ERROR: timeout"],
                        "ml_class": ["PD", "T3"], "error": [np.nan, "timeout"], "rogers": ["ND", "ND"], "iec60599": ["PD", "PD"],
                        "duval": ["PD", "T3"], "model_sha256": [s42.MODEL_SHA.lower(), s42.MODEL_SHA],
                        **{k: v[:2] for k, v in probs.items()}})
    return log, ml, conv


def test_failed_and_missing_records_count_as_mismatch():
    d = s42.compare(*tiny())
    assert d.class_match.tolist() == [True, False, False]          # b: failed call; c: not in the log
    k, n, f = s42.fidelity(d.class_match)
    assert (k, n) == (1, 3) and f == pytest.approx(1 / 3)
    assert d.duval_match.tolist() == [True, False, False]
    assert d.hash_match.tolist() == [True, True, False]             # hash compared without regard to letter case


def test_time_stats_uses_linear_percentile():
    st = s42.time_stats(np.arange(1, 101, dtype=float))
    assert st["median"] == 50.5 and st["p95"] == pytest.approx(95.05) and st["min"] == 1 and st["max"] == 100


def test_saved_results_are_consistent():
    log, ml, conv = s42.load()
    d = s42.compare(log, ml, conv)
    chk = json.loads((s42.OUT / "integration_checks.json").read_text(encoding="utf-8"))
    assert chk["fidelity_ml_class"]["matches"] == int(d.class_match.sum()) and chk["fidelity_ml_class"]["N"] == len(d) == 388
    assert chk["labels_read"] is False and "class_name" not in log.columns
    t = pd.read_csv(ROOT / "11_Results" / "tables" / "T4_11_integration.csv")
    p95 = t[(t.group == "Response time (service request)") & (t.measure == "95th percentile - all records")].iloc[0]
    assert p95.value == pytest.approx(np.percentile(log.response_ms, 95), abs=1e-6)
    assert t[t.measure.str.startswith("ML class identical to")].iloc[0].records == f"{int(d.class_match.sum())}/388"
