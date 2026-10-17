# report_entries_23.ps1 - "Method used" and closing entries for roadmap Step 23 (report standard 2026-10-10/11).
# Result numbers are NOT typed here: the builder fills $global:S23 from the result files before dot-sourcing.

$s = $global:S23
$global:Methods["23"] = @{
  Approach = @(
    "Two standard, complementary explanation methods were applied to the fitted model of Step 22, which was not changed. Permutation importance asks how much worse the model gets when one input is scrambled; SHAP values show, for every record, how much each input pushed the prediction towards or away from each fault class.",
    "Permutation importance was computed on the three test sets at two levels: gas level (one of the five gases is shuffled before the features are built, so all its ratios and percentages move together) and feature level (one of the 18 features is shuffled). The gas level is the main ranking, because the 18 features are built from only five gases and share much of their information.",
    "SHAP values were computed exactly (TreeSHAP) for all 439 development records and all 388 test records. The model's reasoning was then compared with the engineering expectation written down before the results (decision D20) and with the IEC 60599 ratio table.")
  Why = @(
    "A diagnosis that engineers cannot check is hard to trust in a utility; explanations show whether the model relies on physically sensible evidence (Analysis Plan Section 8.1).",
    "Shuffling one feature at a time understates inputs whose information is shared with other features (Strobl et al., 2008); shuffling a whole gas avoids this.",
    "TreeSHAP gives exact, additive explanations for tree models (Lundberg et al., 2020), so the contributions add up to the predicted probability - this was checked.")
  Settings = @(
    @("Model explained", "final pipeline of Step 22 (Random Forest, F4), fingerprint checked"),
    @("Permutation importance", "Eq. 38; R = 30 shuffles; seed 20261010; score = macro-F1 with each set's class list"),
    @("Records (permutation)", "internal test 61, IEC TC 10 power transformers 58, Li 2019 86 (primary sets of D19)"),
    @("SHAP", ("exact TreeSHAP, class-probability units; 439 development + 388 test records; shap " + $s.shapver)),
    @("Interval", "2.5-97.5 percentile of the 30 shuffles (shuffle variability only, not sampling variability)"),
    @("Engineering check (D20)", "PD - H2; D1, D2 - C2H2; T1 - CH4 or C2H6; T2 - C2H4 or CH4; T3 - C2H4"))
  Eqs = @(
    @{ Eq = 'I_j=s-1/R ∑_(r=1)^R▒s_(r,j)'; Where = @(
        @('I_j', 'permutation importance of gas or feature j (drop in macro-F1)'),
        @('s', 'macro-F1 of the model on the unshuffled test set'),
        @('s_(r,j)', 'macro-F1 after input j is shuffled in repeat r; R = 30 repeats')) },
    @{ Eq = 'Φ_j=1/N ∑_(i=1)^N▒|φ_(i,j) |'; Where = @(
        @('Φ_j', 'overall SHAP importance of feature j for one class (probability units)'),
        @('φ_(i,j)', 'SHAP value: contribution of feature j to the predicted probability of that class for record i'),
        @('N', 'number of records explained (439 development records for Figure 4.15)')) })
  Tools = @("06_Python_ML/src/ml/step23_explain.py (permutation importance, SHAP, engineering check, Figures 4.14 and 4.15)",
            ("shap " + $s.shapver + " (TreeExplainer); scikit-learn; matplotlib with the shared style file plot_style.csv"))
  Refs = @("M15", "M16", "M17", "M18")
}

$global:Closings["23"] = @{
  Achieved = @(
    "The model's use of each gas and feature was measured on all three test sets and explained record by record with exact SHAP values.",
    ("For all six fault classes, the model's strongest evidence involves the key gas expected from engineering knowledge (" + $s.consistent + " of 6)."),
    "The directions of the strongest effects agree with the IEC 60599 ratio limits (for example, low CH4/H2 towards partial discharge, high C2H4/C2H6 towards T3).",
    "Figures 4.14 and 4.15 were produced with their data tables, in the thesis style.")
  Record = @(
    @("Step", "23 - Explain the model"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "12 October 2026"), @("Status", "Done"),
    @("Main inputs", "07_Experiments/2026-10-12_final_fit/final_pipeline.joblib; dga_master.csv (data version 1.0)"),
    @("Main outputs", "11_Results/explain/ (5 tables + SHAP values); Figures F4_14 and F4_15 (PNG, PDF, CSV)"),
    @("Checks", ("pipeline fingerprint; SHAP additivity error " + $s.adderr + "; rerun identical; development-test rank agreement " + $s.rho)),
    @("Decisions", "D20 (explainability design; procedural)"))
  Helps = @(
    "Step 24 saves the versioned model with a model card, which will summarise these explanations.",
    "Chapter 4 and the journal paper can show that the model reasons in a physically sensible way, which reviewers in power engineering expect.",
    "The per-record SHAP values can be shown in the dashboard (Step 38 onwards) so an engineer sees why each diagnosis was given.")
  Open = @(
    "Agreement with IEC 60599 and the key gases is expected in part, because the development labels may have been produced partly with such methods (decision D7); it shows the model is plausible, not that it discovered the physics independently.",
    "Explanations describe the model, not the transformer: an important feature is one the model uses, not necessarily a cause of the fault.",
    "The intervals reflect only the randomness of shuffling; the test sets are small (58-86 records), so rankings of inputs with similar importance are uncertain.",
    "Lundberg and Lee (2017) is cited without page numbers until they are confirmed (register M16, TO VERIFY).")
  Exclude = @()
}

$global:StepSources["23"] = @("ST1", "ST5", "DF2", "DF6", "DF24", "DF26", "SW1")
