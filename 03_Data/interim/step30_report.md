# Step 30 report - significance tests

## Friedman / Nemenyi (cross-validation, 50 folds)

| analysis | k | n_folds | chi2 | df | p | q_alpha | critical_difference |
|---|---|---|---|---|---|---|---|
| 6 models on F4 (primary) | 6 | 50 | 158.0571 | 5 | 0.0 | 2.8497 | 1.0663 |
| 24 model-feature combinations (supplementary) | 24 | 50 | 757.5602 | 23 | 0.0 | 3.6373 | 5.1439 |

| model | label | average_rank_F4 | mean_macro_f1_F4 |
|---|---|---|---|
| majority | Majority baseline | 6.0 | 0.0463 |
| logistic_regression | Logistic regression | 3.42 | 0.8196 |
| svm | SVM (RBF) | 3.5 | 0.8189 |
| random_forest | Random Forest | 1.76 | 0.85 |
| xgboost | XGBoost | 2.28 | 0.8424 |
| mlp | Neural network (MLP) | 4.04 | 0.8049 |

## Cochran's Q

| evaluation_set | variant | n | Q | df | p | correct_ML | correct_Rogers | correct_IEC60599 | correct_Duval |
|---|---|---|---|---|---|---|---|---|---|
| Internal test | primary | 61 | 42.2 | 3 | 0.0 | 50 | 20 | 29 | 34 |
| Internal test | no_gate | 61 | 37.2162 | 3 | 0.0 | 50 | 22 | 26 | 32 |
| IEC TC 10 (power transformers) | primary | 58 | 21.6522 | 3 | 0.0001 | 42 | 28 | 37 | 45 |
| IEC TC 10 (power transformers) | no_gate | 58 | 26.2277 | 3 | 0.0 | 42 | 31 | 42 | 52 |
| Li 2019 | primary | 86 | 57.236 | 3 | 0.0 | 54 | 15 | 26 | 39 |
| Li 2019 | no_gate | 86 | 66.4565 | 3 | 0.0 | 54 | 22 | 38 | 64 |

## McNemar with Holm (Table 4.6; primary and no-gate)

| evaluation_set | variant | comparison | b | c | test | p | p_holm | odds_ratio | or_lo | or_hi | significant_holm |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Internal test | primary | ML vs Rogers Ratio | 33 | 3 | chi-square, continuity corrected (Eq. 30) | 0.0 | 0.0 | 11.0 | 3.3736 | 35.8671 | True |
| Internal test | primary | ML vs IEC 60599 ratio | 24 | 3 | chi-square, continuity corrected (Eq. 30) | 0.0001 | 0.0002 | 8.0 | 2.409 | 26.5676 | True |
| Internal test | primary | ML vs Duval Triangle 1 | 22 | 6 | chi-square, continuity corrected (Eq. 30) | 0.0046 | 0.0046 | 3.6667 | 1.4867 | 9.043 | True |
| Internal test | no_gate | ML vs Rogers Ratio | 30 | 2 | chi-square, continuity corrected (Eq. 30) | 0.0 | 0.0 | 15.0 | 3.5847 | 62.7671 | True |
| Internal test | no_gate | ML vs IEC 60599 ratio | 24 | 0 | exact binomial (Eq. 31) | 0.0 | 0.0 | 49.0 | 2.9797 | 805.7877 | True |
| Internal test | no_gate | ML vs Duval Triangle 1 | 22 | 4 | chi-square, continuity corrected (Eq. 30) | 0.0009 | 0.0009 | 5.5 | 1.8953 | 15.9606 | True |
| IEC TC 10 (power transformers) | primary | ML vs Rogers Ratio | 17 | 3 | exact binomial (Eq. 31) | 0.0026 | 0.0077 | 5.6667 | 1.6606 | 19.3366 | True |
| IEC TC 10 (power transformers) | primary | ML vs IEC 60599 ratio | 8 | 3 | exact binomial (Eq. 31) | 0.2266 | 0.4531 | 2.6667 | 0.7074 | 10.0518 | False |
| IEC TC 10 (power transformers) | primary | ML vs Duval Triangle 1 | 6 | 9 | exact binomial (Eq. 31) | 0.6072 | 0.6072 | 0.6667 | 0.2373 | 1.873 | False |
| IEC TC 10 (power transformers) | no_gate | ML vs Rogers Ratio | 15 | 4 | exact binomial (Eq. 31) | 0.0192 | 0.0576 | 3.75 | 1.2446 | 11.2989 | False |
| IEC TC 10 (power transformers) | no_gate | ML vs IEC 60599 ratio | 6 | 6 | exact binomial (Eq. 31) | 1.0 | 1.0 | 1.0 | 0.3225 | 3.1006 | False |
| IEC TC 10 (power transformers) | no_gate | ML vs Duval Triangle 1 | 3 | 13 | exact binomial (Eq. 31) | 0.0213 | 0.0576 | 0.2308 | 0.0658 | 0.8098 | False |
| Li 2019 | primary | ML vs Rogers Ratio | 41 | 2 | chi-square, continuity corrected (Eq. 30) | 0.0 | 0.0 | 20.5 | 4.9585 | 84.7542 | True |
| Li 2019 | primary | ML vs IEC 60599 ratio | 30 | 2 | chi-square, continuity corrected (Eq. 30) | 0.0 | 0.0 | 15.0 | 3.5847 | 62.7671 | True |
| Li 2019 | primary | ML vs Duval Triangle 1 | 29 | 14 | chi-square, continuity corrected (Eq. 30) | 0.0328 | 0.0328 | 2.0714 | 1.0946 | 3.92 | True |
| Li 2019 | no_gate | ML vs Rogers Ratio | 34 | 2 | chi-square, continuity corrected (Eq. 30) | 0.0 | 0.0 | 17.0 | 4.0841 | 70.762 | True |
| Li 2019 | no_gate | ML vs IEC 60599 ratio | 19 | 3 | exact binomial (Eq. 31) | 0.0009 | 0.0017 | 6.3333 | 1.8742 | 21.4023 | True |
| Li 2019 | no_gate | ML vs Duval Triangle 1 | 8 | 18 | chi-square, continuity corrected (Eq. 30) | 0.0776 | 0.0776 | 0.4444 | 0.1933 | 1.0222 | False |

## Hypothesis criteria

```
{
 "Internal test": {
  "criterion1_ML_higher_and_significant": {
   "Rogers": true,
   "IEC60599": true,
   "Duval": true
  },
  "criterion1_met": true,
  "criterion2_conditional_gap_smaller": {
   "Rogers": true,
   "IEC60599": true,
   "Duval": false
  },
  "criterion2_met": false,
  "criterion3": "decided in Step 31"
 },
 "IEC TC 10 (power transformers)": {
  "criterion1_ML_higher_and_significant": {
   "Rogers": true,
   "IEC60599": false,
   "Duval": false
  },
  "criterion1_met": false,
  "criterion2_conditional_gap_smaller": {
   "Rogers": true,
   "IEC60599": true,
   "Duval": false
  },
  "criterion2_met": false,
  "criterion3": "decided in Step 31"
 },
 "Li 2019": {
  "criterion1_ML_higher_and_significant": {
   "Rogers": true,
   "IEC60599": true,
   "Duval": true
  },
  "criterion1_met": true,
  "criterion2_conditional_gap_smaller": {
   "Rogers": true,
   "IEC60599": true,
   "Duval": false
  },
  "criterion2_met": false,
  "criterion3": "decided in Step 31"
 },
 "decisive_set": "IEC TC 10 (power transformers)"
}
```
