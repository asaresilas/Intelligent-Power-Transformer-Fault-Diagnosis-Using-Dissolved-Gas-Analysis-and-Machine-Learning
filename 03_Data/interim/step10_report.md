# Step 10 report - data roles and cross-validation folds

Run date: 2026-10-10. Script: `06_Python_ML/src/data_prep/step10_folds.py`.

## Records per data role

| data_role | records |
|---|---|
| benchmark | 117 |
| development | 439 |
| external_test | 201 |
| internal_test | 70 |

## Analysis subsets defined by the flags

| set | records |
|---|---|
| benchmark, primary (P, U) | 58 |
| benchmark, all equipment (sensitivity) | 117 |
| internal test, independent of benchmark | 61 |
| external test, independent of benchmark | 86 |
| development, all five gases reported (complete-case sensitivity) | 262 |

## Development set - classes

| class | records | share_% |
|---|---|---|
| Normal | 75 | 17.1 |
| PD | 37 | 8.4 |
| D1 | 53 | 12.1 |
| D2 | 85 | 19.4 |
| T1 | 80 | 18.2 |
| T2 | 39 | 8.9 |
| T3 | 70 | 15.9 |

## Near-duplicate groups inside the development set

9 groups contain more than one record (26 records in total; largest group 7). Each group is kept inside one fold in every repeat.

## Folds

Repeated stratified group k-fold: 5 folds x 10 repeats, stratified by fine class code, seed 20261010 (repeat r uses seed 20261010 + r). Fold sizes in repeat 1: fold 1: 88, fold 2: 87, fold 3: 87, fold 4: 88, fold 5: 89.

Largest deviation of a class share in any fold from its overall share: 0.9 percentage points.

Check: every development record has a fold in every repeat and no near-duplicate group is split - PASS.
