# Step 19 report - preprocessing and feature pipelines

Run date: 2026-10-11. Script: `06_Python_ML/src/ml/step19_build_pipelines.py`. Data version 1.0 verified: PASS. Development records: 439; working check on repeat 1, fold 1 (training 351, held out 88). No performance score is computed in this step.

Pipeline: FeatureBuilder (F1-F4, stateless) -> SimpleImputer(median) -> StandardScaler -> BalancedClassifier (class weights from the training fold, D15).

## Pipeline catalogue

| feature_set | model | n_features | weighted | grid_size | runs | finite_features | proba_sum_to_1 | warnings | seconds |
|---|---|---|---|---|---|---|---|---|---|
| F1 | majority | 5 | False | 1 | yes | True | True | 0 | 0.02 |
| F1 | svm | 5 | True | 20 | yes | True | True | 0 | 0.1 |
| F1 | random_forest | 5 | True | 9 | yes | True | True | 0 | 1.25 |
| F1 | xgboost | 5 | True | 18 | yes | True | True | 0 | 0.33 |
| F1 | mlp | 5 | True | 9 | yes | True | True | 0 | 0.31 |
| F1 | logistic_regression | 5 | True | 3 | yes | True | True | 0 | 0.02 |
| F2 | majority | 5 | False | 1 | yes | True | True | 0 | 0.01 |
| F2 | svm | 5 | True | 20 | yes | True | True | 0 | 0.09 |
| F2 | random_forest | 5 | True | 9 | yes | True | True | 0 | 1.2 |
| F2 | xgboost | 5 | True | 18 | yes | True | True | 0 | 0.35 |
| F2 | mlp | 5 | True | 9 | yes | True | True | 0 | 1.24 |
| F2 | logistic_regression | 5 | True | 3 | yes | True | True | 0 | 0.03 |
| F3 | majority | 8 | False | 1 | yes | True | True | 0 | 0.01 |
| F3 | svm | 8 | True | 20 | yes | True | True | 0 | 0.09 |
| F3 | random_forest | 8 | True | 9 | yes | True | True | 0 | 1.22 |
| F3 | xgboost | 8 | True | 18 | yes | True | True | 0 | 0.38 |
| F3 | mlp | 8 | True | 9 | yes | True | True | 0 | 0.56 |
| F3 | logistic_regression | 8 | True | 3 | yes | True | True | 0 | 0.03 |
| F4 | majority | 18 | False | 1 | yes | True | True | 0 | 0.01 |
| F4 | svm | 18 | True | 20 | yes | True | True | 0 | 0.11 |
| F4 | random_forest | 18 | True | 9 | yes | True | True | 0 | 1.28 |
| F4 | xgboost | 18 | True | 18 | yes | True | True | 0 | 0.48 |
| F4 | mlp | 18 | True | 9 | yes | True | True | 0 | 0.16 |
| F4 | logistic_regression | 18 | True | 3 | yes | True | True | 0 | 0.05 |

All pipelines run, give finite features and probabilities that sum to 1: PASS.

## Features per set

| feature_set | n_features | features |
|---|---|---|
| F1 | 5 | log_H2 log_CH4 log_C2H6 log_C2H4 log_C2H2 |
| F2 | 5 | pct_H2 pct_CH4 pct_C2H6 pct_C2H4 pct_C2H2 |
| F3 | 8 | log_R1 log_R2 log_R3 log_R4 log_R5 duval_pct_CH4 duval_pct_C2H4 duval_pct_C2H2 |
| F4 | 18 | log_H2 log_CH4 log_C2H6 log_C2H4 log_C2H2 pct_H2 pct_CH4 pct_C2H6 pct_C2H4 pct_C2H2 log_R1 log_R2 log_R3 log_R4 log_R5 duval_pct_CH4 duval_pct_C2H4 duval_pct_C2H2 |
