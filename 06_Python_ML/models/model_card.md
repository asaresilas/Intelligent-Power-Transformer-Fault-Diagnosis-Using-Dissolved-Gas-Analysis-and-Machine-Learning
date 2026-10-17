# Model card - dga_model_v1

Generated 2026-10-12 00:43 by `06_Python_ML/src/ml/step24_save_model.py` from the saved result files (format after Mitchell et al., 2019). Every number below is read from a project file.

## Model details
- File: `06_Python_ML/models/dga_model_v1.joblib`, SHA-256 `1C46D10391429385D7A35DDD7C6B8AC560C7285980752AB938A1FA42B7809523` (identical to the Step 22 fit, decision D21).
- Type: scikit-learn pipeline - feature builder (set F4: log gases, gas percentages, log ratios R1-R5, Duval percentages; 18 features) -> median imputation -> standard scaling -> Random Forest, 500 trees, balanced class weights; setting max_depth = None, min_samples_leaf = 1 (inner-CV macro-F1 0.864).
- Trained on 439 development records, data version 1.0; seed 20261010; Python 3.12.10, scikit-learn 1.9.1.
- Load only with `model_io.load_model()` (checks the fingerprint). Developed for an MPhil thesis at UMaT.

## Intended use
- Decision support for interpreting dissolved gas analysis of mineral-oil-filled power transformers: suggests one of seven classes (Normal, PD, D1, D2, T1, T2, T3) with a probability for each.
- Not intended to replace an engineer's judgement, the IEC 60599 / IEEE C57.104 procedures, gas-rate trending or inspection, and not for other equipment (reactors, bushings, instrument transformers, tap-changer compartments) or other insulating liquids.

## Inputs and outputs
- Inputs: H2, CH4, C2H6, C2H4, C2H2 in ppm (ul/l). A gas that was not detected is entered as 0 ppm (decision D8). CO and CO2 are not used (decision D2).
- Output: the most probable class and the probability of each class. The model always answers; it has no 'no diagnosis' option and no check that a sample lies far from the training data.

## Training data
- 439 development records (IEEE DataPort, Dissanayake training file) after removal of duplicates and of IEC TC 10 cases. The labelling method of this source is not documented (decision D7).

## Performance (macro-F1 = mean F1 over classes)
- Nested cross-validation on the development data (50 folds): 0.850 (SD 0.038); accuracy 0.863; per-class F1: Normal 0.905, PD 0.828, D1 0.775, D2 0.864, T1 0.876, T2 0.762, T3 0.941.
- One-time test (Step 22, first look; confidence intervals follow in Step 29):

| evaluation_set | n | macro_f1 | accuracy | kappa |
|---|---|---|---|---|
| Internal test - independent | 61 | 0.812 | 0.82 | 0.79 |
| Internal test - all | 70 | 0.831 | 0.829 | 0.8 |
| IEC TC 10 - power transformers | 58 | 0.731 | 0.724 | 0.597 |
| IEC TC 10 - all | 117 | 0.745 | 0.761 | 0.667 |
| Li 2019 - independent | 86 | 0.595 | 0.628 | 0.547 |
| Li 2019 - all (merged classes) | 201 | 0.714 | 0.711 | 0.632 |

## What the model relies on (Step 23)
- Permutation importance, gas level (drop in macro-F1 when the gas is shuffled):

| feature | IEC TC 10 (power transformers) | Internal test | Li 2019 |
|---|---|---|---|
| C2H2 | 0.371 | 0.257 | 0.277 |
| C2H4 | 0.224 | 0.36 | 0.285 |
| C2H6 | -0.033 | 0.241 | 0.097 |
| CH4 | 0.127 | 0.091 | 0.031 |
| H2 | 0.288 | 0.241 | 0.111 |

- Strongest features by mean |SHAP|: duval_pct_C2H2, log_R1, log_R5, pct_C2H2, pct_C2H4. Directions agree with IEC 60599 Table 2.

## Limitations and cautions
- Performance falls on data from other sources (dataset shift): highest on the internal test set, lower on the IEC TC 10 benchmark and on Li 2019; weakest classes externally are T1 (often called Normal or PD) and T3 vs T1/T2.
- Development labels of undocumented origin; agreement with IEC rules shows plausibility, not proof.
- Normal is learned from one source only; the model cannot judge gas increase rates or equipment history.
- Small test sets (58-86 records per primary set); single-record changes move macro-F1 noticeably.

## Reproduction check
- Reloaded in a fresh Python process: 388 test records, same classes: True, largest probability difference: 0.0 -> PASS.
