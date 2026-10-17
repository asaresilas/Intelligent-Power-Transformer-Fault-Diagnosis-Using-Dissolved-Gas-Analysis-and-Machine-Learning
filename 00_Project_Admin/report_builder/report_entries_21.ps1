# report_entries_21.ps1 - "Method used" and closing entries for roadmap Step 21 (report standard 2026-10-10/11).
# Result numbers are NOT typed here: the builder fills $global:S21 from the result files before dot-sourcing.

$s = $global:S21
$global:Methods["21"] = @{
  Approach = @(
    "A written rule, fixed in the Analysis Plan (Section 5.4) before any data were analysed, chooses the final model from the cross-validation results of Step 20: the pipeline with the highest mean macro-F1 over the 50 outer folds; if it is not significantly better than the next pipeline, the simpler of the two is chosen.",
    "The details the plan left open were fixed in decision D18 while the Step 20 run was still going and before any of its results were read: the 20 candidates are the 5 classifiers x 4 feature sets (the majority baseline is only a reference); significance is judged with the corrected resampled t-test; and the order of simplicity is set in advance.")
  Why = @(
    "Choosing by a rule written in advance keeps the choice from being fitted to the results, which would make the reported performance too optimistic (Varma and Simon, 2006).",
    "Cross-validation folds share most of their training records, so an ordinary paired t-test finds differences too easily; the corrected resampled t-test of Nadeau and Bengio (2003) enlarges the variance to allow for this (Analysis Plan Eq. 28).",
    "Preferring the simpler of two equally good models (parsimony) gives a model that is easier to explain, check and maintain in a utility, at no measured cost in accuracy.")
  Settings = @(
    @("Candidates", "20 pipelines: logistic regression, SVM (RBF), Random Forest, XGBoost, MLP, each on F1, F2, F3, F4"),
    @("Score compared", "macro-F1 on the 50 outer folds, paired by repeat and fold"),
    @("Test", ("corrected resampled t-test (Eq. 28), two-sided, alpha 0.05, 49 degrees of freedom; n_test/n_train = " + $s.ratio)),
    @("Simplicity order (D18)", "logistic regression < SVM < Random Forest < XGBoost < MLP; then fewer input features (F1 = F2 = 5 < F3 = 8 < F4 = 18)"),
    @("Test sets", "not opened (checked by the program before it runs)"))
  Eqs = @(
    @{ Eq = 't=d{BAR}/√((1/(k r)+n_test/n_train ) σ_d^2 )'; Where = @(
        @('t', 'corrected resampled t statistic, compared with a t distribution with k r - 1 = 49 degrees of freedom'),
        @('d{BAR}', 'mean over the 50 folds of the difference in macro-F1 between the two pipelines'),
        @('σ_d^2', 'variance (sample, n - 1) of those 50 differences'),
        @('k, r', 'folds per repeat (5) and repeats (10)'),
        @('n_test, n_train', 'mean number of held-out and of training records per fold')) })
  Tools = @("06_Python_ML/src/ml/step21_select_model.py (applies the rule; writes model_selection.md and model_selection_tests.csv)",
            "tests/test_model_selection.py (hand-computed t value, correction more cautious than the plain paired t-test, simplicity order); scipy.stats for the t distribution")
  Refs = @("M14", "M13")
}

$global:Closings["21"] = @{
  Achieved = @(
    ("The final model was chosen by the written rule: " + $s.chosen + "."),
    "Every candidate was compared with the best on the same 50 folds, so the strength of the choice is visible, not only its result.",
    "The choice was made and saved before any test set was opened, as the roadmap requires.")
  Record = @(
    @("Step", "21 - Select the final model by the written rule"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "11 October 2026"), @("Status", "Done"),
    @("Main inputs", "07_Experiments/2026-10-11_nestedcv_v1/fold_metrics.csv (Step 20)"),
    @("Main outputs", "07_Experiments/model_selection.md; 07_Experiments/model_selection_tests.csv"),
    @("Checks", "rule followed by program; details fixed before results were read (D18); test sets opened: no; 91 of 91 tests pass"),
    @("Decisions", "D18 (selection details; procedural)"))
  Helps = @(
    "Step 22 tunes the chosen pipeline once more on all 439 development records (same inner procedure), fits it, and predicts the internal test set, the IEC TC 10 benchmark and the Li 2019 set once.",
    "The comparison table feeds the discussion in Chapter 4 and the Friedman and Nemenyi tests of Step 30.")
  Open = @(
    "'Not significantly different' is not proof that two models are equal; with 50 folds, differences of about 0.01 to 0.03 in macro-F1 cannot be resolved.",
    ("The rule compares only the best and the next pipeline, as written. Besides the next, " + $s.more + " more pipelines are not significantly worse than the best (no correction for multiple comparisons), including simpler ones such as " + $s.simplest + "; this is reported as supporting information and does not change the choice."),
    "The choice rests on development data whose labelling method is not documented; the inspection-based IEC TC 10 benchmark in Step 22 is the stronger test.")
  Exclude = @()
}

$global:StepSources["21"] = @("DF21", "DF22", "DF23", "DF6", "SW1")
