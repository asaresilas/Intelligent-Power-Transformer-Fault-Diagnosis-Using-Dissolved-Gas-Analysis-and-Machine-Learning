# Step 25 report - reduced-gas study (cross-validation)

Run folder: `07_Experiments/2026-10-12_reducedgas_v1`.
Checks: {"tasks": 1550, "complete": true, "every_record_once_per_repeat": true, "identical_folds_to_step10": true, "full_panel_reproduces_step20": true, "tasks_with_warnings": 0, "prediction_rows": 136090}

## Best subset for each number of gases

| n_gases | subset_id | n_features | macro_f1_mean | macro_f1_sd | loss_vs_full_mean |
|---|---|---|---|---|---|
| 1 | C2H4 | 1 | 0.384 | 0.0481 | 0.466 |
| 2 | C2H6+C2H4 | 5 | 0.5835 | 0.0436 | 0.2665 |
| 3 | C2H6+C2H4+C2H2 | 9 | 0.7329 | 0.0429 | 0.1171 |
| 4 | H2+C2H6+C2H4+C2H2 | 11 | 0.8332 | 0.0372 | 0.0168 |
| 5 | H2+CH4+C2H6+C2H4+C2H2 | 18 | 0.85 | 0.038 | 0.0 |

## All subsets

| subset_id | n_gases | n_features | macro_f1_mean | macro_f1_sd | loss_vs_full_mean |
|---|---|---|---|---|---|
| H2 | 1 | 1 | 0.2664 | 0.0404 | 0.5836 |
| CH4 | 1 | 1 | 0.2459 | 0.0393 | 0.6042 |
| C2H6 | 1 | 1 | 0.2772 | 0.0373 | 0.5728 |
| C2H4 | 1 | 1 | 0.384 | 0.0481 | 0.466 |
| C2H2 | 1 | 1 | 0.2359 | 0.0326 | 0.6141 |
| H2+CH4 | 2 | 5 | 0.4962 | 0.0478 | 0.3539 |
| H2+C2H6 | 2 | 4 | 0.435 | 0.0551 | 0.4151 |
| H2+C2H4 | 2 | 4 | 0.532 | 0.0446 | 0.318 |
| H2+C2H2 | 2 | 4 | 0.4369 | 0.047 | 0.4132 |
| CH4+C2H6 | 2 | 4 | 0.3692 | 0.0496 | 0.4808 |
| CH4+C2H4 | 2 | 4 | 0.4666 | 0.0488 | 0.3835 |
| CH4+C2H2 | 2 | 5 | 0.4327 | 0.0393 | 0.4174 |
| C2H6+C2H4 | 2 | 5 | 0.5835 | 0.0436 | 0.2665 |
| C2H6+C2H2 | 2 | 5 | 0.4409 | 0.0406 | 0.4091 |
| C2H4+C2H2 | 2 | 5 | 0.5519 | 0.0448 | 0.2981 |
| H2+CH4+C2H6 | 3 | 7 | 0.5726 | 0.0475 | 0.2774 |
| H2+CH4+C2H4 | 3 | 7 | 0.6577 | 0.0434 | 0.1924 |
| H2+CH4+C2H2 | 3 | 8 | 0.6328 | 0.044 | 0.2172 |
| H2+C2H6+C2H4 | 3 | 7 | 0.7075 | 0.0442 | 0.1425 |
| H2+C2H6+C2H2 | 3 | 7 | 0.6006 | 0.036 | 0.2495 |
| H2+C2H4+C2H2 | 3 | 7 | 0.6863 | 0.0426 | 0.1637 |
| CH4+C2H6+C2H4 | 3 | 7 | 0.5767 | 0.0462 | 0.2733 |
| CH4+C2H6+C2H2 | 3 | 8 | 0.5211 | 0.0369 | 0.329 |
| CH4+C2H4+C2H2 | 3 | 11 | 0.6153 | 0.0502 | 0.2347 |
| C2H6+C2H4+C2H2 | 3 | 9 | 0.7329 | 0.0429 | 0.1171 |
| H2+CH4+C2H6+C2H4 | 4 | 10 | 0.7318 | 0.0451 | 0.1182 |
| H2+CH4+C2H6+C2H2 | 4 | 11 | 0.7017 | 0.0372 | 0.1483 |
| H2+CH4+C2H4+C2H2 | 4 | 14 | 0.7736 | 0.045 | 0.0764 |
| H2+C2H6+C2H4+C2H2 | 4 | 11 | 0.8332 | 0.0372 | 0.0168 |
| CH4+C2H6+C2H4+C2H2 | 4 | 15 | 0.7221 | 0.0458 | 0.1279 |
| H2+CH4+C2H6+C2H4+C2H2 | 5 | 18 | 0.85 | 0.038 | 0.0 |

Loss and its 95 % bootstrap interval, the tolerance test (delta = 0.05) and the minimum panel: Step 27.
