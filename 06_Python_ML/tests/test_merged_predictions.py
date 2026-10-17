"""Integrity of the merged prediction file (roadmap Step 28): no record lost or duplicated, values copied unchanged."""
from pathlib import Path

import pandas as pd
import pytest

ROOT = Path(__file__).resolve().parents[2]
MERGED = ROOT / "08_Statistical_Analysis" / "merged_predictions.csv"
pytestmark = pytest.mark.skipif(not MERGED.exists(), reason="Step 28 not yet run")


@pytest.fixture(scope="module")
def merged():
    return pd.read_csv(MERGED, keep_default_na=False, na_values=["NaN", ""])


def test_one_row_per_test_record(merged):
    master = pd.read_csv(ROOT / "03_Data" / "processed" / "dga_master.csv")
    test_ids = set(master.record_id[master.data_role != "development"])
    assert merged.record_id.is_unique and set(merged.record_id) == test_ids


def test_ml_values_copied_unchanged(merged):
    ml = pd.read_csv(ROOT / "11_Results" / "ml" / "ml_predictions.csv").set_index("record_id")
    m = merged.set_index("record_id").loc[ml.index]
    assert (m.ml_pred == ml.y_pred).all()
    assert ((m.ml_p_D2 - ml.p_D2).abs() < 1e-12).all()


def test_conventional_values_copied_unchanged(merged):
    conv = pd.read_csv(ROOT / "11_Results" / "conventional" / "conventional_predictions.csv",
                       keep_default_na=False, na_values=["NaN", ""])
    m = merged.set_index("record_id")
    for meth in ("IEC60599", "Rogers", "Duval"):
        c = conv[conv.method == meth].set_index("record_id").loc[m.index]
        assert (m[f"{meth}_result"] == c.result).all()
        assert (m[f"{meth}_raw"] == c.raw_result).all()


def test_merged_labels(merged):
    for meth in ("IEC60599", "Rogers", "Duval"):
        assert not merged[f"{meth}_result_merged"].isin(["T1", "T2"]).any()
    assert not merged.ml_pred_merged.isin(["T1", "T2"]).any()
