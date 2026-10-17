# report_entries_20.ps1 - "Method used" and closing entries for roadmap Step 20 (report standard 2026-10-10/11).
# Result numbers are NOT typed here: the builder fills $global:S20 from the result files before dot-sourcing.

$s = $global:S20
$global:Methods["20"] = @{
  Approach = @(
    "Nested cross-validation. The outer loop uses the 50 fixed train/test splits of Step 10 (5 folds x 10 repeats). Inside each outer training part, an inner 5-fold cross-validation tries every setting in the model's search grid and keeps the one with the highest macro-F1. That setting is refitted on the whole outer training part and then predicts the outer held-out fold, which played no part in training or tuning.",
    "This was done for all 6 models on all 4 feature sets: 6 x 4 x 50 = 1 200 outer-fold tasks, each with its own inner search. For every held-out record the predicted class and the probability of every class were saved, together with the chosen setting and all performance measures of Analysis Plan Section 6.")
  Why = @(
    "If the same data are used both to choose settings and to measure performance, the measured performance is too optimistic; nested cross-validation keeps tuning and measurement apart (Varma and Simon, 2006) and is the approved design (plan item 10).",
    "Fifty outer folds give 50 paired estimates for every model, which the statistical comparisons of Step 30 (Friedman, Nemenyi, corrected resampled t-test) require.",
    "Saving every prediction and probability means that any later measure or figure can be recomputed without training again.")
  Settings = @(
    @("Outer loop", "50 fixed folds from folds.csv (stratified, near-duplicate groups kept together)"),
    @("Inner loop", "StratifiedGroupKFold(5), near-duplicate groups kept together (D17); seed 20261010 + 1000 x repeat + fold"),
    @("Tuning score", "macro-F1 (approved primary measure)"),
    @("Search grids", "Analysis Plan 5.2: SVM 20, Random Forest 9, XGBoost 18, MLP 9, logistic regression 3 combinations; baseline none"),
    @("Records", "439 development records only - the test sets were not opened"),
    @("Execution", ("" + $s.jobs + " parallel processes, single-threaded models (results independent of the number of workers); run time " + $s.duration)),
    @("Software", ("Python " + $s.python + ", scikit-learn " + $s.sklearn + ", xgboost " + $s.xgboost)))
  Eqs = @(
    @{ Eq = '"Macro-F1"=1/K ∑_(c=1)^K▒"F1"_c'; Where = @(
        @('"Macro-F1"', 'unweighted mean of the per-class F1-scores (Analysis Plan Eq. 17); K = 7 classes'),
        @('"F1"_c', 'harmonic mean of precision and recall of class c on the held-out fold')) },
    @{ Eq = 'm{BAR}=1/50 ∑_(i=1)^50▒m_i{SP}s=√(1/49 ∑_(i=1)^50▒(m_i−m{BAR})^2 )'; Where = @(
        @('m_i', 'a measure (e.g. macro-F1) on outer fold i'),
        @('m{BAR}, s', 'mean and standard deviation over the 50 outer folds, as reported in Table 4.4')) })
  Tools = @("06_Python_ML/src/ml/step20_nested_cv.py (runs the tasks; resumable), step20_summarize.py (Table 4.4, completeness, reproducibility)",
            "scikit-learn GridSearchCV and StratifiedGroupKFold; joblib for parallel processes")
  Refs = @("M13", "M3", "M10")
}

$global:Closings["20"] = @{
  Achieved = @(
    ("All " + $s.tasks + " outer-fold tasks finished; every development record was predicted once per repeat for every model and feature set."),
    "Table 4.4 gives, for all 24 model-feature combinations, the mean and standard deviation over 50 folds of macro-F1 and the secondary measures.",
    "Every fold's chosen setting, measures, predictions and class probabilities are saved, so later statistics need no retraining.",
    "Re-running saved tasks from their configuration reproduced exactly the same predictions, settings and scores.")
  Record = @(
    @("Step", "20 - Train and tune the classifiers (nested cross-validation)"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "11 October 2026"), @("Status", "Done"),
    @("Main inputs", "dga_master.csv and folds.csv (data version 1.0); configs/ml_config.yaml; the 24 pipelines of Step 19"),
    @("Main outputs", ("07_Experiments/" + $s.run + " (tasks, fold_metrics.csv, predictions.csv, run_info.json); 11_Results/tables/T4_4_cv_results.csv")),
    @("Checks", ("completeness " + $s.complete + "; reproducibility " + $s.repro + "; test sets opened: no")), @("Decisions", "D17 (inner-loop and run details; procedural)"))
  Helps = @(
    "Step 21 applies the written selection rule to these results: the highest mean outer-fold macro-F1, and the simpler model if the best two are not significantly different.",
    "Steps 30 and 32 draw Figure 4.6 (box plots of the 50 fold values) and Figure 4.7 (critical-difference diagram) and run the Friedman and Nemenyi tests directly from the saved fold results.",
    "The saved probabilities support the calibration and uncertainty displays of the dashboard (Step 38 onwards).")
  Open = @(
    "These are cross-validation estimates on the development data only; how well the chosen model generalises is measured once, on the three test sets, in Step 22.",
    "The development labels come from the Dissanayake dataset, whose labelling method is not documented (see the register); the inspection-based IEC TC 10 benchmark in Step 22 is the stronger test.")
  Exclude = @()
}

$global:StepSources["20"] = @("DF2", "DF3", "DF6", "DF18", "DF20", "DF21", "DF22", "SW1")
