"""Study 2 pooled data set (roadmap Step 31B, protocol D28): deduplication, groups, scope and hybrid inputs."""
from pathlib import Path

import pandas as pd
import pytest

ROOT = Path(__file__).resolve().parents[2]
S2 = ROOT / "03_Data" / "study2"
GASES = ["H2", "CH4", "C2H6", "C2H4", "C2H2"]
pytestmark = pytest.mark.skipif(not (S2 / "study2_pooled.csv").exists(), reason="Step 31B not yet run")


@pytest.fixture(scope="module")
def pooled():
    return pd.read_csv(S2 / "study2_pooled.csv", keep_default_na=False, na_values=["NaN", ""])


def test_no_exact_copy_across_sources(pooled):
    key = pooled[GASES].round(6).astype(str).agg("|".join, axis=1)
    assert (pooled.groupby(key).source_id.nunique() == 1).all()


def test_priority_respected():
    log = pd.read_csv(S2 / "study2_dedup_log.csv")
    order = ["IECTC10", "DISTRAIN", "DISTEST", "LI2019"]
    assert (log.kept_source.map(order.index) < log.removed_source.map(order.index)).all()


def test_step10_groups_kept_together(pooled):
    folds = pd.read_csv(ROOT / "03_Data" / "processed" / "folds.csv")
    j = folds.merge(pooled[["record_id", "group_id"]], on="record_id")
    assert len(j) == len(folds) and (j.groupby("group_id_x").group_id_y.nunique() == 1).all()


def test_scope_and_classes(pooled):
    prim = pooled[pooled.in_primary_scope]
    assert len(prim) == 643
    assert set(prim.class6) <= {"Normal", "PD", "D1", "D2", "T12", "T3"}
    assert (prim.source_id == "IECTC10").sum() == 58


def test_hybrid_inputs_present(pooled):
    for m in ("IEC60599", "Rogers", "Duval"):
        assert pooled[f"{m}_raw"].notna().all()
    assert set(pooled.gate_upper_normal) <= {0, 1}
