# Step 21 - model selection by the written rule

Date: 2026-10-11T23:51:52. Input: `07_Experiments/2026-10-11_nestedcv_v1/fold_metrics.csv` (50 outer folds, development records only). Data version 1.0 verified.

Rule (Analysis Plan 5.4 and 7.1; details in decision D18, fixed before the Step 20 results were read): the highest mean outer-fold macro-F1; if the best and the next pipeline are not significantly different (corrected resampled t-test, Eq. 28, two-sided, alpha 0.05, 49 df), the simpler one is chosen. Simplicity: logistic regression < SVM < Random Forest < XGBoost < MLP, then fewer input features.

Test-to-training size ratio used in Eq. 28: 87.80 / 351.20 = 0.2500.

## Best and next

- Best: **random_forest on F4**, mean macro-F1 0.8500
- Next: **xgboost on F4**, mean macro-F1 0.8424
- Mean difference 0.0077; t = 0.497; p = 0.6213

## Decision: **random_forest on feature set F4**

Reason: best and next are not significantly different; the best is at least as simple, so the best is chosen.

Settings most often chosen by the inner loop for this pipeline (fold count):

| setting | folds |
|---|---|
| {"max_depth": null, "min_samples_leaf": 1} | 22 |
| {"max_depth": null, "min_samples_leaf": 2} | 10 |
| {"max_depth": 10, "min_samples_leaf": 1} | 6 |
| {"max_depth": null, "min_samples_leaf": 5} | 4 |
| {"max_depth": 10, "min_samples_leaf": 2} | 3 |

The final settings are tuned again on all development records in Step 22 (roadmap), with the same inner procedure.

## All candidates compared with the best (supporting information)

| feature_set | model | mean_macro_f1 | sd_macro_f1 | mean_difference_to_best | t | p | significantly_worse_than_best | family_rank | n_features |
|---|---|---|---|---|---|---|---|---|---|
| F4 | random_forest | 0.85 | 0.038 | 0.0 | nan | nan | False | 3 | 18 |
| F4 | xgboost | 0.8424 | 0.0389 | 0.0077 | 0.497 | 0.6213 | False | 4 | 18 |
| F3 | xgboost | 0.8328 | 0.0405 | 0.0172 | 0.972 | 0.3359 | False | 4 | 8 |
| F3 | random_forest | 0.8244 | 0.0357 | 0.0256 | 1.482 | 0.1448 | False | 3 | 8 |
| F3 | logistic_regression | 0.8211 | 0.0384 | 0.0289 | 1.679 | 0.0995 | False | 1 | 8 |
| F4 | logistic_regression | 0.8196 | 0.0387 | 0.0304 | 1.713 | 0.0931 | False | 1 | 18 |
| F4 | svm | 0.8189 | 0.0377 | 0.0311 | 1.701 | 0.0954 | False | 2 | 18 |
| F3 | svm | 0.8101 | 0.0407 | 0.04 | 2.229 | 0.0304 | True | 2 | 8 |
| F1 | logistic_regression | 0.8075 | 0.0355 | 0.0425 | 2.668 | 0.0103 | True | 1 | 5 |
| F2 | random_forest | 0.8054 | 0.0405 | 0.0446 | 2.858 | 0.0062 | True | 3 | 5 |
| F4 | mlp | 0.8049 | 0.0397 | 0.0451 | 1.967 | 0.0549 | False | 5 | 18 |
| F1 | svm | 0.8038 | 0.0352 | 0.0462 | 2.452 | 0.0178 | True | 2 | 5 |
| F3 | mlp | 0.7946 | 0.0438 | 0.0554 | 2.949 | 0.0049 | True | 5 | 8 |
| F2 | svm | 0.7939 | 0.0375 | 0.0562 | 3.203 | 0.0024 | True | 2 | 5 |
| F1 | mlp | 0.7931 | 0.0442 | 0.057 | 2.293 | 0.0262 | True | 5 | 5 |
| F2 | xgboost | 0.7884 | 0.0408 | 0.0616 | 4.14 | 0.0001 | True | 4 | 5 |
| F1 | random_forest | 0.7733 | 0.0493 | 0.0767 | 3.233 | 0.0022 | True | 3 | 5 |
| F1 | xgboost | 0.7714 | 0.0485 | 0.0786 | 2.977 | 0.0045 | True | 4 | 5 |
| F2 | mlp | 0.7647 | 0.0316 | 0.0854 | 3.855 | 0.0003 | True | 5 | 5 |
| F2 | logistic_regression | 0.7422 | 0.0445 | 0.1079 | 5.085 | 0.0 | True | 1 | 5 |

Pipelines not significantly worse than the best (no multiplicity correction, descriptive only): 8 of 20.

Test sets opened before this choice: no (Step 20 run_info test_sets_opened = false; `11_Results/ml/ml_predictions.csv` does not exist).
