"""Roadmap Step 26 - independent Python check of the MATLAB table conventional_applicability.csv.

Input : 11_Results/conventional/conventional_applicability.csv   (MATLAB, Step 26)
        11_Results/reduced_gas/reduced_gas_subsets.csv           (31 gas combinations, Step 25)
        03_Data/processed/dga_master.csv                         (data version 1.0, verified first)
Do    : recompute every number of the table with the independent Python implementation of Step 18
        (conventional_methods.py): removed gases -> NaN (not measured, NOT 0 ppm); a method that needs a removed
        gas gives ND for every record (IEC 60599 and Rogers need all five gases, Duval needs CH4, C2H4, C2H2); an
        applicable method is run as in Step 18; the normality gate is never passed with a gas missing (D23 rule 4).
        The required gases are written here again, independently of conv_config.m, from the analysis plan sentence.
Output: 08_Statistical_Analysis/cross_language_check_step26.csv (one row per table row, MATLAB and Python side by side)
Check : applicable, n_records, n_nd, n_diagnosed, n_nd_raw and n_nd_gate_measured identical on 100 % of the 465 rows.
Run   : py -I 06_Python_ML/src/conventional/step26_crosscheck.py
"""
from __future__ import annotations

import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "data_prep"))

import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402

import conventional_methods as cm  # noqa: E402
from common import PROCESSED, PROJECT_ROOT, verify_data_version  # noqa: E402

GASES = ["H2", "CH4", "C2H6", "C2H4", "C2H2"]
NEEDS = {"IEC60599": set(GASES), "Rogers": set(GASES), "Duval": {"CH4", "C2H4", "C2H2"}}   # analysis plan, Section 8
ROLES = ["all", "development", "internal_test", "benchmark", "external_test"]


def main() -> int:
    verify_data_version()
    master = pd.read_csv(PROCESSED / "dga_master.csv")
    subsets = pd.read_csv(PROJECT_ROOT / "11_Results" / "reduced_gas" / "reduced_gas_subsets.csv")
    ml = pd.read_csv(PROJECT_ROOT / "11_Results" / "conventional" / "conventional_applicability.csv")
    n = len(master)
    rows = []
    for _, s in subsets.iterrows():
        keep = [g for g in GASES if str(s[f"has_{g}"]).lower() == "true"]
        g = master[GASES].astype(float).copy()
        for gas in GASES:
            if gas not in keep:
                g[gas] = np.nan                                    # not measured
        d = cm.diagnose(g, master["equipment_type"])               # Step 18 implementation on the masked data
        gate_measured = cm.normality_gate(g.fillna(0.0), master["equipment_type"], "high")   # sensitivity gate
        for k, method in enumerate(["IEC60599", "Rogers", "Duval"]):
            part = d[d.method == method].reset_index(drop=True)
            applicable = NEEDS[method] <= set(keep)
            if applicable:
                raw = part.raw_result.to_numpy()
                final = raw.copy()
                if len(keep) == len(GASES):                        # gate only on complete data
                    final = np.where(part.gate_upper.to_numpy() == "Normal", "Normal", raw)
                alt = np.where(gate_measured, "Normal", raw)
            else:
                raw = final = alt = np.array(["ND"] * n)
            for role in ROLES:
                sel = np.ones(n, bool) if role == "all" else (master.data_role == role).to_numpy()
                nd = int((final[sel] == "ND").sum())
                rows.append({"subset_id": s["subset_id"], "method": method, "data_role": role,
                             "py_applicable": int(applicable), "py_n_records": int(sel.sum()), "py_n_nd": nd,
                             "py_n_diagnosed": int(sel.sum()) - nd, "py_n_nd_raw": int((raw[sel] == "ND").sum()),
                             "py_n_nd_gate_measured": int((alt[sel] == "ND").sum())})
    py = pd.DataFrame(rows)
    m = ml.merge(py, on=["subset_id", "method", "data_role"], how="outer", indicator=True)
    pairs = [("applicable", "py_applicable"), ("n_records", "py_n_records"), ("n_nd", "py_n_nd"),
             ("n_diagnosed", "py_n_diagnosed"), ("n_nd_raw", "py_n_nd_raw"),
             ("n_nd_gate_measured", "py_n_nd_gate_measured")]
    m["identical"] = (m["_merge"] == "both") & np.logical_and.reduce([m[a] == m[b] for a, b in pairs])
    out = PROJECT_ROOT / "08_Statistical_Analysis" / "cross_language_check_step26.csv"
    out.parent.mkdir(exist_ok=True)
    m.drop(columns="_merge").to_csv(out, index=False)
    ok = bool(m["identical"].all())
    print(f"rows MATLAB {len(ml)}, Python {len(py)}, compared {int((m['_merge'] == 'both').sum())}; "
          f"identical {int(m['identical'].sum())} of {len(m)} -> {'PASS' if ok else 'FAIL'}")
    print(f"written: {out}")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
