"""Roadmap Step 10 [Claude Code] - confirm data roles and fix the cross-validation folds.

Input : 03_Data/processed/dga_master.csv (roles assigned in Step 9).
Do    : 1. Near-duplicate groups inside the development set (every gas within 1 % or 1 ppm, linked
           transitively) are found, so that near-copies always fall in the same fold - otherwise
           cross-validation would test on near-copies of training records and overstate accuracy.
        2. Repeated stratified group k-fold on the development set: 5 folds x 10 repeats, stratified by
           the fine class code (0-6), one fixed seed recorded in the file (analysis-plan item 10).
Output: 03_Data/processed/folds.csv (record_id, group_id, rep01..rep10 = fold 1-5),
        03_Data/interim/step10_report.md
Check : every development record has a fold in every repeat; no near-duplicate group is split across
        folds; class proportions per fold stay close to the overall proportions (largest deviation reported).
"""
from __future__ import annotations

import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402
from sklearn.model_selection import StratifiedGroupKFold  # noqa: E402

from common import GASES, INTERIM, PROCESSED, md_table, rel  # noqa: E402

SEED = 20261010          # fixed seed (date the folds were frozen); repeat r uses SEED + r
N_SPLITS, N_REPEATS = 5, 10
REL_TOL, ABS_TOL = 0.01, 1.0


def near_groups(x: np.ndarray) -> np.ndarray:
    """Connected components of the 'near' relation (union-find)."""
    n = len(x)
    diff = np.abs(x[:, None, :] - x[None, :, :])
    scale = np.maximum(np.abs(x[:, None, :]), np.abs(x[None, :, :]))
    near = (diff <= np.maximum(ABS_TOL, REL_TOL * scale)).all(axis=2)
    parent = list(range(n))

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    for i, j in zip(*np.nonzero(np.triu(near, k=1))):
        ri, rj = find(i), find(j)
        if ri != rj:
            parent[rj] = ri
    roots = [find(i) for i in range(n)]
    _, gid = np.unique(roots, return_inverse=True)
    return gid


def main() -> int:
    master = pd.read_csv(PROCESSED / "dga_master.csv")
    roles = master.groupby("data_role").size()
    dev = master[master.data_role == "development"].reset_index(drop=True)
    y = dev["class_code"].astype(int).to_numpy()
    groups = near_groups(dev[GASES].to_numpy(float))
    sizes = pd.Series(groups).value_counts()
    multi = sizes[sizes > 1]

    folds = pd.DataFrame({"record_id": dev["record_id"], "class_code": y, "group_id": groups})
    dev_ok, worst = True, 0.0
    overall = pd.Series(y).value_counts(normalize=True).sort_index()
    for r in range(1, N_REPEATS + 1):
        sgkf = StratifiedGroupKFold(n_splits=N_SPLITS, shuffle=True, random_state=SEED + r)
        col = np.zeros(len(dev), dtype=int)
        for k, (_, test_idx) in enumerate(sgkf.split(dev[GASES], y, groups), start=1):
            col[test_idx] = k
        folds[f"rep{r:02d}"] = col
        if (col == 0).any():
            dev_ok = False
        # no group split across folds
        if (folds.groupby("group_id")[f"rep{r:02d}"].nunique() > 1).any():
            dev_ok = False
        for k in range(1, N_SPLITS + 1):
            p = pd.Series(y[col == k]).value_counts(normalize=True).reindex(overall.index, fill_value=0)
            worst = max(worst, float((p - overall).abs().max()))
    folds.insert(0, "seed", SEED)
    folds.to_csv(PROCESSED / "folds.csv", index=False, encoding="utf-8")

    fold_sizes = folds.groupby("rep01").size()
    cls_names = {0: "Normal", 1: "PD", 2: "D1", 3: "D2", 4: "T1", 5: "T2", 6: "T3"}
    cls_tab = pd.DataFrame({"class": [cls_names[c] for c in overall.index],
                            "records": pd.Series(y).value_counts().sort_index().to_numpy(),
                            "share_%": (overall * 100).round(1).to_numpy()})
    role_tab = roles.rename("records").reset_index()
    bench = master[master.data_role == "benchmark"]
    sub = pd.DataFrame([
        {"set": "benchmark, primary (P, U)", "records": int(bench.in_scope_primary.sum())},
        {"set": "benchmark, all equipment (sensitivity)", "records": len(bench)},
        {"set": "internal test, independent of benchmark", "records": int(master[(master.data_role == 'internal_test') & master.independent_of_benchmark].shape[0])},
        {"set": "external test, independent of benchmark", "records": int(master[(master.data_role == 'external_test') & master.independent_of_benchmark].shape[0])},
        {"set": "development, all five gases reported (complete-case sensitivity)", "records": int(dev.all_five_reported.sum())},
    ])
    L = ["# Step 10 report - data roles and cross-validation folds", "",
         f"Run date: {date.today().isoformat()}. Script: `06_Python_ML/src/data_prep/step10_folds.py`.", "",
         "## Records per data role", "", md_table(role_tab), "",
         "## Analysis subsets defined by the flags", "", md_table(sub), "",
         "## Development set - classes", "", md_table(cls_tab), "",
         "## Near-duplicate groups inside the development set", "",
         f"{len(multi)} groups contain more than one record ({int(multi.sum())} records in total; largest group "
         f"{int(multi.max()) if len(multi) else 1}). Each group is kept inside one fold in every repeat.", "",
         "## Folds", "",
         f"Repeated stratified group k-fold: {N_SPLITS} folds x {N_REPEATS} repeats, stratified by fine class code, "
         f"seed {SEED} (repeat r uses seed {SEED} + r). Fold sizes in repeat 1: "
         + ", ".join(f"fold {k}: {v}" for k, v in fold_sizes.items()) + ".", "",
         f"Largest deviation of a class share in any fold from its overall share: {worst * 100:.1f} percentage points.", "",
         f"Check: every development record has a fold in every repeat and no near-duplicate group is split - "
         f"{'PASS' if dev_ok else 'FAIL'}."]
    (INTERIM / "step10_report.md").write_text("\n".join(L) + "\n", encoding="utf-8")
    print(f"development={len(dev)} groups>1={len(multi)} (records {int(multi.sum())}) "
          f"worst class-share deviation={worst * 100:.1f} pp  check={'PASS' if dev_ok else 'FAIL'}")
    print(f"folds: {rel(PROCESSED / 'folds.csv')}  report: {rel(INTERIM / 'step10_report.md')}")
    return 0 if dev_ok else 1


if __name__ == "__main__":
    sys.exit(main())
