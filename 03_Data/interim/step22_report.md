# Step 22 report - final fit and one-time test prediction

Selected pipeline (Step 21): random_forest on F4. Tuned on all 439 development records (inner StratifiedGroupKFold(5), seed 20261010): best setting {'max_depth': None, 'min_samples_leaf': 1}, inner macro-F1 0.8640; fit time 21 s; warnings 0.

Fitted pipeline: `07_Experiments/2026-10-12_final_fit/final_pipeline.joblib` SHA-256 1C46D10391429385D7A35DDD7C6B8AC560C7285980752AB938A1FA42B7809523 (saved before any test prediction).

Test records predicted once: 388. Log: `11_Results/ml/test_set_access.log`.

## First-look scores (formal measures with confidence intervals: Step 29)

| evaluation_set | primary | classes | n | macro_f1 | accuracy | balanced_accuracy | kappa | mcc | n_predicted_normal |
|---|---|---|---|---|---|---|---|---|---|
| Internal test - independent | True | Normal/PD/D1/D2/T1/T2/T3 | 61 | 0.8119 | 0.8197 | 0.8158 | 0.7895 | 0.792 | 7 |
| Internal test - all | False | Normal/PD/D1/D2/T1/T2/T3 | 70 | 0.831 | 0.8286 | 0.8286 | 0.8 | 0.8015 | 7 |
| IEC TC 10 - power transformers | True | PD/D1/D2/T12/T3 | 58 | 0.7306 | 0.7241 | 0.7261 | 0.5967 | 0.6034 | 1 |
| IEC TC 10 - all | False | PD/D1/D2/T12/T3 | 117 | 0.7449 | 0.7607 | 0.7328 | 0.6666 | 0.6734 | 1 |
| Li 2019 - independent | True | PD/D1/D2/T1/T2/T3 | 86 | 0.5954 | 0.6279 | 0.5872 | 0.5468 | 0.5539 | 7 |
| Li 2019 - all (merged classes) | False | PD/D1/D2/T12/T3 | 201 | 0.7144 | 0.7114 | 0.7027 | 0.6323 | 0.6369 | 8 |

### Confusion matrix - Internal test - independent (rows true, columns predicted)

| true | Normal | PD | D1 | D2 | T1 | T2 | T3 |
|---|---|---|---|---|---|---|---|
| Normal | 7 | 1 | 0 | 0 | 1 | 0 | 1 |
| PD | 0 | 5 | 2 | 0 | 0 | 0 | 0 |
| D1 | 0 | 0 | 6 | 1 | 0 | 0 | 0 |
| D2 | 0 | 0 | 2 | 6 | 0 | 0 | 0 |
| T1 | 0 | 1 | 0 | 0 | 9 | 0 | 0 |
| T2 | 0 | 0 | 0 | 0 | 0 | 9 | 1 |
| T3 | 0 | 0 | 0 | 1 | 0 | 0 | 8 |

### Confusion matrix - IEC TC 10 - power transformers (rows true, columns predicted)

| true | PD | D1 | D2 | T12 | T3 | Normal |
|---|---|---|---|---|---|---|
| PD | 1 | 0 | 0 | 0 | 0 | 0 |
| D1 | 0 | 7 | 3 | 0 | 0 | 0 |
| D2 | 0 | 3 | 24 | 0 | 0 | 0 |
| T12 | 0 | 0 | 1 | 5 | 1 | 1 |
| T3 | 0 | 0 | 2 | 5 | 5 | 0 |
| Normal | 0 | 0 | 0 | 0 | 0 | 0 |

### Confusion matrix - Li 2019 - independent (rows true, columns predicted)

| true | PD | D1 | D2 | T1 | T2 | T3 | Normal |
|---|---|---|---|---|---|---|---|
| PD | 4 | 1 | 0 | 3 | 0 | 0 | 0 |
| D1 | 0 | 17 | 6 | 0 | 0 | 0 | 0 |
| D2 | 0 | 2 | 4 | 0 | 0 | 1 | 0 |
| T1 | 4 | 0 | 0 | 7 | 1 | 2 | 5 |
| T2 | 0 | 0 | 0 | 1 | 4 | 2 | 2 |
| T3 | 0 | 0 | 1 | 0 | 1 | 18 | 0 |
| Normal | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
