# report_entries_22.ps1 - "Method used" and closing entries for roadmap Step 22 (report standard 2026-10-10/11).
# Result numbers are NOT typed here: the builder fills $global:S22 from the result files before dot-sourcing.

$s = $global:S22
$global:Methods["22"] = @{
  Approach = @(
    "The pipeline chosen in Step 21 (Random Forest on feature set F4) was tuned once more on all 439 development records, with the same settings grid and the same inner procedure as in Step 20, and then fitted on all of them. The fitted pipeline was saved, with its SHA-256 fingerprint, before any test record was touched.",
    "The three test sets - the internal test set, the IEC TC 10 benchmark and the Li 2019 set - were then predicted once, in a single call. A log file records each action with its time and fingerprint, and the program refuses to run a second time.",
    "A first-look score was computed on the evaluation sets approved earlier (decision D19). The formal measures with 95 % confidence intervals and the comparison with the conventional methods follow in Steps 28 to 30.")
  Why = @(
    "Using every development record for the final fit gives the model the most information; the cross-validation of Step 20 already estimated how well this procedure works (Varma and Simon, 2006).",
    "Opening each test set only once, after the model is fixed, means the test results cannot have influenced any choice - the condition for an honest, publishable estimate.",
    "Saving the fitted model before the test prediction, with its fingerprint, proves that the model was not changed after the test sets were seen.")
  Settings = @(
    @("Pipeline", "Random Forest (500 trees, class weights) on F4 (18 features), from Step 21"),
    @("Final tuning", ("GridSearchCV over 9 settings; StratifiedGroupKFold(5), near-duplicate groups kept together; seed 20261010; macro-F1. Chosen: " + $s.best)),
    @("Training records", "439 development records only"),
    @("Test records", "388, predicted once: internal test 70, IEC TC 10 117, Li 2019 201"),
    @("Primary evaluation sets (D19)", "internal test: 61 independent records, 7 classes; IEC TC 10: 58 power transformers, 5 merged classes; Li 2019: 86 independent records, 6 fault classes"),
    @("Scoring rule (IEC TC 10)", "T1 or T2 predicted for a T1/T2 record counts as correct; a Normal prediction counts as wrong (Analysis Plan item 6)"),
    @("Software", ("Python " + $s.python + ", scikit-learn " + $s.sklearn)))
  Eqs = @(
    @{ Eq = '"Macro-F1"_S=1/|C_S | ∑_(c∈C_S)▒"F1"_c'; Where = @(
        @('C_S', 'the classes scored on evaluation set S (7, 5 merged, or 6 fault classes)'),
        @('"F1"_c', 'F1-score of class c on that set; a class counts equally however few records it has')) })
  Tools = @("06_Python_ML/src/ml/step22_final_fit.py (final tuning, saving, one-time prediction, access log; --score-only recomputes the first-look scores from the saved predictions without predicting again)",
            "scikit-learn GridSearchCV, StratifiedGroupKFold and metrics; joblib for saving the fitted pipeline")
  Refs = @("M13", "M3")
}

$global:Closings["22"] = @{
  Achieved = @(
    "The final model was fitted on the development data only and saved with its fingerprint before any test record was predicted.",
    "All 388 test records were predicted once; the access log and the run-once guard document this.",
    ("First-look macro-F1: internal test " + $s.int + ", IEC TC 10 power transformers " + $s.iec + ", Li 2019 " + $s.li + "."))
  Record = @(
    @("Step", "22 - Fit the final model and predict the test sets once"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "12 October 2026"), @("Status", "Done"),
    @("Main inputs", "07_Experiments/model_selection.md; dga_master.csv and folds.csv (data version 1.0)"),
    @("Main outputs", "11_Results/ml/ml_predictions.csv, ml_first_look.csv, ml_first_look_confusion.csv, test_set_access.log; 07_Experiments/2026-10-12_final_fit/"),
    @("Checks", "test sets predicted once (log); second run refused; predictions fingerprint unchanged after re-scoring"),
    @("Decisions", "D19 (final fit and evaluation sets; procedural)"))
  Helps = @(
    "Step 23 explains the fitted model (permutation importance and SHAP) using these predictions.",
    "Step 24 saves the versioned model (dga_model_v1.joblib) and checks that reloading it reproduces ml_predictions.csv exactly.",
    "Steps 28 to 30 join these predictions with the conventional ones and give the formal measures, confidence intervals and significance tests.")
  Open = @(
    "These are first-look point estimates on small sets (58 to 86 records): one record can move macro-F1 by several points; confidence intervals follow in Step 29.",
    "No comparison with the conventional methods is made here. On the IEC TC 10 benchmark the conventional methods have a 'home advantage': the IEC ratio limits were refined using these cases (Duval and dePablo, 2001).",
    "The development labels come from a source whose labelling method is not documented (decision D7); the lower scores on IEC TC 10 and Li 2019 may partly reflect differences in labelling practice as well as dataset shift.")
  Exclude = @()
}

$global:StepSources["22"] = @("DS1", "DF2", "DF3", "DF6", "DF20", "DF23", "DF24", "DF25", "SW1")
