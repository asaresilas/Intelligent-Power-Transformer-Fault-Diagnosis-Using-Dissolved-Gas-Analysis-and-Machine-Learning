# 08 — Statistical Analysis

**Purpose.** Objective 5 and the research hypothesis: quantify and test the differences between classifiers and between ML and conventional diagnoses.

**Inputs.** `fold_predictions.csv` from `07_Experiments/`; `conventional_diagnoses.csv` and boundary distances from folder 04.

**Analyses**
1. **Classifier comparison** — Friedman test across folds with Nemenyi post-hoc; confidence intervals on macro-F1.
2. **ML vs each conventional method** on identical held-out samples — accuracy, "no diagnosis" rate, McNemar test, Cohen's kappa; Holm correction for multiple comparisons.
3. **Agreement among conventional methods** — pairwise kappa.
4. **Hypothesis test** — logistic regression of disagreement (ML ≠ conventional) on distance to the nearest decision boundary; report odds ratio with confidence interval.
5. **Reduced-gas study** — paired differences from the full-panel baseline on the same folds, with confidence intervals and a tolerance declared before the runs.

**Rules.** Tests and the ablation tolerance are fixed in `analysis_plan.md` before results are viewed. "No diagnosis" outcomes are counted, never dropped. Effect sizes are reported alongside p-values.

**Acceptance criteria.** Each analysis is a script that regenerates its table/figure into `11_Results/`.

**Feeds thesis.** Chapter 4 (disagreement analysis, hypothesis outcome).
