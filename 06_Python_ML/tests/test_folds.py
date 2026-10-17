"""Roadmap Step 10 check: folds.csv covers the development set correctly and never splits a near-duplicate group."""
from pathlib import Path

import pandas as pd
import pytest

ROOT = Path(__file__).resolve().parents[2]
MASTER = ROOT / "03_Data" / "processed" / "dga_master.csv"
FOLDS = ROOT / "03_Data" / "processed" / "folds.csv"
REPS = [f"rep{r:02d}" for r in range(1, 11)]


@pytest.fixture(scope="module")
def data():
    return pd.read_csv(MASTER), pd.read_csv(FOLDS)


def test_folds_cover_exactly_the_development_set(data):
    master, folds = data
    dev_ids = set(master.loc[master.data_role == "development", "record_id"])
    assert set(folds["record_id"]) == dev_ids
    assert folds["record_id"].is_unique


def test_ten_repeats_of_five_folds(data):
    _, folds = data
    for rep in REPS:
        assert set(folds[rep]) == {1, 2, 3, 4, 5}


def test_near_duplicate_groups_never_split(data):
    _, folds = data
    for rep in REPS:
        assert (folds.groupby("group_id")[rep].nunique() == 1).all(), rep


def test_single_fixed_seed(data):
    _, folds = data
    assert folds["seed"].nunique() == 1
