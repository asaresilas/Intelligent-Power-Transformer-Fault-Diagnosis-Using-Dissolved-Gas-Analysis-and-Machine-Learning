"""Roadmap Step 13 check: every file of the frozen data version is unchanged, and the key files are covered."""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "06_Python_ML" / "src" / "data_prep"))

from common import manifest_path, verify_data_version  # noqa: E402


def test_frozen_files_unchanged():
    assert verify_data_version() == []


def test_manifest_covers_key_files():
    listed = {line.split("  ", 1)[1] for line in manifest_path().read_text(encoding="utf-8").splitlines() if line}
    for name in ["03_Data/processed/dga_master.csv", "03_Data/processed/folds.csv",
                 "03_Data/processed/label_map.csv", "02_Standards/iec_ratio_table.csv",
                 "02_Standards/duval_triangle_zones.csv", "02_Standards/rogers_ratio_table.csv",
                 "02_Standards/iec_typical_values.csv", "11_Results/figures/plot_style.csv"]:
        assert name in listed, name
