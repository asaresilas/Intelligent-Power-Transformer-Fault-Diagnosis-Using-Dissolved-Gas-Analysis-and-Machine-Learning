"""Tests of the DGA diagnosis service (roadmap Step 38, decision D36).

The identity test sends the 388 held-out records and compares the answers with the saved offline predictions
(ml_predictions.csv, Step 22) - true labels are not read and no measure is computed (as in the Step 24 reload check).
"""
import json
import shutil
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import pytest
from fastapi.testclient import TestClient

API = Path(__file__).resolve().parents[1]
ROOT = API.parent
sys.path.insert(0, str(API))

from app.main import create_app  # noqa: E402
from app.schemas import CLASS_ORDER, GASES  # noqa: E402
from model_io import MODEL_V1, load_model, recorded_sha256  # noqa: E402  (path set by app.main)

GOOD = {"H2": 200.0, "CH4": 300.0, "C2H6": 80.0, "C2H4": 450.0, "C2H2": 2.0}


@pytest.fixture(scope="module")
def client():
    with TestClient(create_app()) as c:
        yield c


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok", "model_loaded": True, "model_sha256": recorded_sha256(MODEL_V1),
                        "model_version": "1.0"}


def test_version_returns_model_metadata(client):
    v = client.get("/version").json()
    meta = json.loads(MODEL_V1.with_name("dga_model_v1_meta.json").read_text(encoding="utf-8"))
    assert {k: v[k] for k in meta} == meta
    assert v["inputs"] == GASES


def test_diagnose_answer_structure(client):
    r = client.post("/diagnose", json={"record_id": "R1", **GOOD})
    assert r.status_code == 200
    d = r.json()
    assert d["record_id"] == "R1"
    assert list(d["probabilities"]) == CLASS_ORDER
    p = np.array(list(d["probabilities"].values()))
    assert np.all(p >= 0) and abs(p.sum() - 1) < 1e-9
    assert d["fault_class"] == CLASS_ORDER[int(p.argmax())] and d["confidence"] == p.max()
    assert d["model_sha256"] == recorded_sha256(MODEL_V1) and d["model_version"] == "1.0" and d["data_version"] == "1.0"
    assert d["notes"] == []


def test_whole_numbers_and_missing_record_id_accepted(client):
    r = client.post("/diagnose", json={"H2": 0, "CH4": 12, "C2H6": 3, "C2H4": 1, "C2H2": 0})
    assert r.status_code == 200 and r.json()["record_id"] is None


@pytest.mark.parametrize("bad, field", [
    ({k: v for k, v in GOOD.items() if k != "C2H2"}, "C2H2"),          # missing gas
    ({**GOOD, "H2": -1.0}, "H2"),                                        # negative
    ({**GOOD, "CH4": "300"}, "CH4"),                                     # text
    ({**GOOD, "C2H4": True}, "C2H4"),                                    # true/false
    ({**GOOD, "C2H6": None}, "C2H6"),                                    # null
    ({**GOOD, "h2": 5.0}, "h2"),                                         # unknown (misspelt) field
    ({**GOOD, "CO": 5.0}, "CO"),                                         # gas not used by the model (D2)
    ({**GOOD, "record_id": "x" * 65}, "record_id"),                      # label too long
])
def test_invalid_input_refused(client, bad, field):
    r = client.post("/diagnose", json=bad)
    assert r.status_code == 422
    assert any(e["loc"][-1] == field for e in r.json()["detail"])


@pytest.mark.parametrize("token", ["NaN", "Infinity", "-Infinity"])
def test_non_finite_refused(client, token):
    body = json.dumps(GOOD).replace("200.0", token)
    r = client.post("/diagnose", content=body, headers={"Content-Type": "application/json"})
    assert r.status_code == 422                                          # not a server error (found in Step 38)
    assert [e["loc"][-1] for e in r.json()["detail"]] == ["H2"]


def test_body_must_be_one_object(client):
    assert client.post("/diagnose", json=[GOOD]).status_code == 422
    assert client.post("/diagnose", content="not json", headers={"Content-Type": "application/json"}).status_code == 422


def test_notes_for_undefined_percentages(client):
    zero = client.post("/diagnose", json={g: 0 for g in GASES}).json()
    assert len(zero["notes"]) == 1 and "All five gases" in zero["notes"][0]
    duval = client.post("/diagnose", json={"H2": 50, "CH4": 0, "C2H6": 10, "C2H4": 0, "C2H2": 0}).json()
    assert len(duval["notes"]) == 1 and "Duval" in duval["notes"][0]


def test_service_equals_model_on_development_records(client):
    master = pd.read_csv(ROOT / "03_Data" / "processed" / "dga_master.csv", usecols=["record_id", "data_role", *GASES])
    dev = master[master.data_role == "development"].head(60)
    p = load_model().predict_proba(dev[GASES])
    for row, pm in zip(dev.itertuples(index=False), p):
        d = client.post("/diagnose", json={g: float(getattr(row, g)) for g in GASES}).json()
        assert list(d["probabilities"].values()) == pm.tolist()


def test_identity_with_offline_predictions_on_held_out_records(client):
    saved = pd.read_csv(ROOT / "11_Results" / "ml" / "ml_predictions.csv", float_precision="round_trip",
                        usecols=["record_id", "y_pred", *[f"p_{c}" for c in CLASS_ORDER]])
    gases = pd.read_csv(ROOT / "03_Data" / "processed" / "dga_master.csv", usecols=["record_id", *GASES],
                        float_precision="round_trip").set_index("record_id").loc[saved.record_id]
    assert len(saved) == 388
    for s, g in zip(saved.itertuples(index=False), gases.itertuples()):
        d = client.post("/diagnose", json={"record_id": s.record_id, **{k: float(getattr(g, k)) for k in GASES}}).json()
        assert d["record_id"] == s.record_id and d["fault_class"] == s.y_pred
        assert [d["probabilities"][c] for c in CLASS_ORDER] == [getattr(s, f"p_{c}") for c in CLASS_ORDER]


def test_changed_model_file_stops_start_up(tmp_path):
    bad = tmp_path / "dga_model_v1.joblib"
    shutil.copyfile(MODEL_V1, bad)
    with open(bad, "ab") as fh:
        fh.write(b"\0")
    shutil.copyfile(MODEL_V1.with_suffix(".sha256"), bad.with_suffix(".sha256"))
    with pytest.raises(ValueError, match="does not match"):
        with TestClient(create_app(bad)):
            pass


def test_openapi_file_is_current():
    sys.path.insert(0, str(API))
    from export_openapi import OPENAPI, schema_text
    assert OPENAPI.read_text(encoding="utf-8") == schema_text()
    spec = json.loads(OPENAPI.read_text(encoding="utf-8"))
    assert {"/diagnose", "/health", "/version"} <= set(spec["paths"])
    assert spec["components"]["schemas"]["GasSample"]["required"] == GASES
