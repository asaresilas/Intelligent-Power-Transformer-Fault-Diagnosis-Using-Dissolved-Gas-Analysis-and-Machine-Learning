"""Roadmap Step 9 check: the master table is free of leakage and structurally sound.

Independent of the Step 9 script: reads 03_Data/processed/dga_master.csv only.
Run:  06_Python_ML/.venv/Scripts/python.exe -I -m pytest 06_Python_ML/tests -q
"""
from pathlib import Path

import numpy as np
import pandas as pd
import pytest

ROOT = Path(__file__).resolve().parents[2]
MASTER = ROOT / "03_Data" / "processed" / "dga_master.csv"
GASES = ["H2", "CH4", "C2H6", "C2H4", "C2H2"]
TEST_ROLES = ["internal_test", "benchmark", "external_test"]


@pytest.fixture(scope="module")
def master() -> pd.DataFrame:
    return pd.read_csv(MASTER)


def _near(a: np.ndarray, b: np.ndarray, rel: float = 0.01, abs_tol: float = 1.0) -> np.ndarray:
    diff = np.abs(a[:, None, :] - b[None, :, :])
    scale = np.maximum(np.abs(a[:, None, :]), np.abs(b[None, :, :]))
    return (diff <= np.maximum(abs_tol, rel * scale)).all(axis=2)


def test_record_ids_unique(master):
    assert master["record_id"].is_unique


def test_roles_and_classes_valid(master):
    assert set(master["data_role"]) <= {"development"} | set(TEST_ROLES)
    assert master["class_merged"].isin(["Normal", "PD", "D1", "D2", "T12", "T3"]).all()


def test_gases_complete_and_non_negative(master):
    # decision D8: not-available values are already 0 ppm in the master table
    assert master[GASES].notna().all().all()
    assert (master[GASES] >= 0).all().all()


def test_no_development_record_in_any_test_set(master):
    dev = master.loc[master.data_role == "development", GASES].to_numpy(float)
    tst = master.loc[master.data_role.isin(TEST_ROLES), GASES].to_numpy(float)
    assert _near(dev, tst).sum() == 0, "a development record matches a test record (exact or near)"


def test_no_exact_duplicates_within_a_role(master):
    key = master[GASES].round(4).astype(str).agg("|".join, axis=1)
    dup = master.assign(key=key).duplicated(["data_role", "key"])
    assert not dup.any(), f"{int(dup.sum())} exact duplicates within a role"
