# Step 20 report - nested cross-validation

Run date: 2026-10-11. Run folder: `07_Experiments/2026-10-11_nestedcv_v1` (start 2026-10-11T21:01:58, end 2026-10-11T23:44:27, 6 parallel workers). Data version 1.0 verified. Test sets opened: no.

Completeness: 1200 of 1200 tasks; every development record predicted once per repeat, model and feature set: PASS. Tasks with any warning: 5.

## Table 4.4 - cross-validation results (mean and SD over 50 outer folds)

| feature_set | model | macro_f1_mean | macro_f1_sd | balanced_accuracy_mean | kappa_mean | mcc_mean | average_rank |
|---|---|---|---|---|---|---|---|
| F1 | majority | 0.0463 | 0.0003 | 0.1429 | 0.0 | 0.0 | 22.5 |
| F1 | logistic_regression | 0.8075 | 0.0355 | 0.8204 | 0.788 | 0.7906 | 10.3 |
| F1 | svm | 0.8038 | 0.0352 | 0.8166 | 0.7827 | 0.7852 | 10.76 |
| F1 | random_forest | 0.7733 | 0.0493 | 0.7784 | 0.7571 | 0.7597 | 14.87 |
| F1 | xgboost | 0.7714 | 0.0485 | 0.7763 | 0.755 | 0.7576 | 14.8 |
| F1 | mlp | 0.7931 | 0.0442 | 0.7976 | 0.7775 | 0.7795 | 11.88 |
| F2 | majority | 0.0463 | 0.0003 | 0.1429 | 0.0 | 0.0 | 22.5 |
| F2 | logistic_regression | 0.7422 | 0.0445 | 0.7595 | 0.7075 | 0.7107 | 18.06 |
| F2 | svm | 0.7939 | 0.0375 | 0.8101 | 0.7668 | 0.7698 | 12.48 |
| F2 | random_forest | 0.8054 | 0.0405 | 0.8109 | 0.7841 | 0.786 | 10.62 |
| F2 | xgboost | 0.7884 | 0.0408 | 0.7897 | 0.7673 | 0.7697 | 13.3 |
| F2 | mlp | 0.7647 | 0.0316 | 0.7687 | 0.739 | 0.7413 | 15.74 |
| F3 | majority | 0.0463 | 0.0003 | 0.1429 | 0.0 | 0.0 | 22.5 |
| F3 | logistic_regression | 0.8211 | 0.0384 | 0.8326 | 0.8007 | 0.8031 | 7.76 |
| F3 | svm | 0.8101 | 0.0407 | 0.8227 | 0.7902 | 0.7928 | 9.62 |
| F3 | random_forest | 0.8244 | 0.0357 | 0.8315 | 0.8073 | 0.8094 | 7.0 |
| F3 | xgboost | 0.8328 | 0.0405 | 0.8364 | 0.8176 | 0.8195 | 6.04 |
| F3 | mlp | 0.7946 | 0.0438 | 0.7966 | 0.7771 | 0.779 | 12.14 |
| F4 | majority | 0.0463 | 0.0003 | 0.1429 | 0.0 | 0.0 | 22.5 |
| F4 | logistic_regression | 0.8196 | 0.0387 | 0.832 | 0.7997 | 0.8021 | 8.14 |
| F4 | svm | 0.8189 | 0.0377 | 0.8313 | 0.8009 | 0.8035 | 8.05 |
| F4 | random_forest | 0.85 | 0.038 | 0.8568 | 0.8377 | 0.8395 | 3.3 |
| F4 | xgboost | 0.8424 | 0.0389 | 0.8451 | 0.8319 | 0.8337 | 4.58 |
| F4 | mlp | 0.8049 | 0.0397 | 0.8082 | 0.7924 | 0.7943 | 10.56 |

Average rank: rank of each model-feature combination within every outer fold by macro-F1 (1 = best), averaged over the 50 folds (descriptive; the Friedman and Nemenyi tests follow in Step 30). No model is selected here.

## Reproducibility (saved tasks re-run from their configuration)

| task | same_predictions | max_probability_difference | same_best_setting | same_macro_f1 |
|---|---|---|---|---|
| F4_xgboost_rep01_f1 | True | 0.0 | True | True |
| F1_svm_rep07_f3 | True | 0.0 | True | True |
| F3_mlp_rep10_f5 | True | 0.0 | True | True |
| F2_random_forest_rep04_f2 | True | 0.0 | True | True |

Reproducibility: PASS.
