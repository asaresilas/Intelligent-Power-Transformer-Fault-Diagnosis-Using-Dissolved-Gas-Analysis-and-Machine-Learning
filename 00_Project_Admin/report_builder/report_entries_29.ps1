# report_entries_29.ps1 - "Method used" and closing entries for roadmap Step 29 (report standard 2026-10-10/11).

$s = $global:S29
$global:Methods["29"] = @{
  Approach = @(
    "From the merged file of Step 28 only, the performance of the ML model and of the three conventional methods was measured on each test set: strict accuracy (every no-diagnosis counted as wrong), conditional accuracy (only the records that got a diagnosis), coverage, macro-F1, balanced accuracy, Cohen's kappa and the Matthews correlation coefficient, with per-class precision, recall and F1 and the confusion matrices.",
    "95 % confidence intervals: the Wilson interval for the three proportions, and a stratified percentile bootstrap (2000 resamples within each true class, the same resample for all four methods) for macro-F1, the other measures and the differences between the ML model and each method.",
    "The scoring rules were fixed before computing (decision D25): the IEC dual answer D1/D2 counts as correct for a true D1 or D2; the Duval DT zone and a Normal answer on a fault-only set count as wrong; IEC TC 10 is scored on five merged classes. Sensitivity analyses repeat the scoring with the lower normality gate, with no gate, and with the dual answer counted wrong.")
  Why = @(
    "Strict accuracy, conditional accuracy and coverage together show whether a method is better because it is more often right, or only because it answers more often (Analysis Plan Section 4.3) - the core of the research hypothesis.",
    "Macro-F1 gives every fault class equal weight, so a method cannot look good by recognising only the common faults.",
    "Intervals show how uncertain each number is on these small test sets (58-86 records); the paired bootstrap of the differences shows whether a gap between two methods is larger than the uncertainty.")
  Settings = @(
    @("Evaluation sets (D19)", "internal test 61 independent records, 7 classes; IEC TC 10 58 power transformers, 5 merged classes; Li 2019 86 independent records, 6 classes; plus all records of each set as sensitivity"),
    @("Scoring (D25)", "D1/D2 correct for true D1 or D2; DT wrong; Normal on a fault-only set wrong; ND wrong in strict accuracy, excluded from conditional accuracy"),
    @("Gate", "upper normality gate (primary, D11); lower gate and no gate as sensitivity"),
    @("Intervals", ("Wilson (z = 1.96); stratified paired bootstrap, B = " + $s.B + ", seed 20261010")),
    @("Input", "08_Statistical_Analysis/merged_predictions.csv only (fingerprint checked)"))
  Eqs = @(
    @{ Eq = 'U=n_ND/N{SP}"Coverage"=1-U'; Where = @(@('n_ND, N', 'number of no-diagnosis answers; number of test records')) },
    @{ Eq = 'A_strict=n_correct/N{SP}A_cond=n_correct/(N-n_ND )'; Where = @(@('n_correct', 'number of records diagnosed correctly')) },
    @{ Eq = '"CI"_95=(p+z^2/2n±z√(p(1-p)/n+z^2/(4n^2 )))/(1+z^2/n)'; Where = @(
        @('p, n', 'observed proportion and the number of records it is based on'), @('z', '1.96 for 95 % confidence')) })
  Tools = @("06_Python_ML/src/stats/step29_measures.py (measures, intervals, Tables 4.3 and 4.5, Figures 4.5 and 4.8)",
            "tests/test_measures.py (measures equal scikit-learn's where comparable; ND and dual rules; Wilson hand value)")
  Refs = @("M21", "M20", "M22", "M23")
}

$global:Closings["29"] = @{
  Achieved = @(
    "All Chapter 4 performance measures of the test sets are computed with 95 % confidence intervals from one checked file.",
    "Tables 4.3 and 4.5 and Figures 4.5 (one per test set) and 4.8 are produced with their data files.",
    "The sensitivity analyses show how much the results depend on the normality gate and on the dual-answer rule.")
  Record = @(
    @("Step", "29 - Compute the performance measures with 95 % confidence intervals"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "12 October 2026"), @("Status", "Done"),
    @("Main inputs", "08_Statistical_Analysis/merged_predictions.csv (Step 28)"),
    @("Main outputs", "08_Statistical_Analysis/performance_measures.csv, per_class_measures.csv, differences.csv, confusion_matrices.csv; Tables T4_3, T4_5; Figures F4_5a-c, F4_8"),
    @("Checks", ("ML values equal the Step 22 first look; re-run identical; " + $s.tests)),
    @("Decisions", "D25 (scoring details; procedural)"))
  Helps = @(
    "Step 30 tests whether the differences are statistically significant (Cochran's Q, McNemar with Holm correction, kappa between methods) and judges the research hypothesis by its three written criteria.",
    "Step 31 uses the same records to test whether disagreements cluster near the conventional decision boundaries.")
  Open = @(
    "On the IEC TC 10 benchmark the conventional methods have a home advantage: the IEC 60599 limits were refined with these cases (Duval and dePablo, 2001, p. 32). Whether the Duval Triangle zones were also tuned on these cases has not been checked in a primary source (TO VERIFY); its strong result on this set should be read with that question in mind.",
    "The results for the conventional methods depend strongly on the normality gate (decision D11): it calls many low-gas faults Normal. The gate is part of the approved method, so the primary results keep it; the no-gate results are reported beside them.",
    "The test sets are small; most intervals are wide, and differences inside them should not be over-interpreted.",
    "Gorodkin (2004): DOI not yet confirmed (register M23, TO VERIFY).")
  Exclude = @()
}

$global:StepSources["29"] = @("DF34", "DF35", "DF36", "DS1", "SW1")
