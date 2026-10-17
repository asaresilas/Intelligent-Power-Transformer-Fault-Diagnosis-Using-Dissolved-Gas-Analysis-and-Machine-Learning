# report_entries_28.ps1 - "Method used" and closing entries for roadmap Step 28 (report standard 2026-10-10/11).

$s = $global:S28
$global:Methods["28"] = @{
  Approach = @(
    "All predictions for the 388 test records were joined into one table, one row per record, using the record identifier: the true class and evaluation flags from the master table, the ML prediction and its seven class probabilities (Step 22), and for each conventional method (IEC 60599, Rogers, Duval; Steps 14-17) its raw answer, its answer after the upper normality gate (primary) and after the lower gate (sensitivity), and its distance to the nearest decision boundary.",
    "Versions with T1 and T2 merged into one class were added for the IEC TC 10 scoring. No answer is scored in this step; the scoring rules are applied in Step 29.")
  Why = @(
    "Every later measure and statistical test (Steps 29-32) must use exactly the same records and answers; one merged file makes this certain and checkable.",
    "Joining with strict one-to-one checks proves that no record was lost or counted twice - a common source of silent error in method comparisons.")
  Settings = @(
    @("Records", "388 test records: internal test 70, IEC TC 10 benchmark 117, Li 2019 201"),
    @("Join key", "record_id; every join checked one-to-one"),
    @("Conventional answers", "raw; upper gate (primary, D11); lower gate (sensitivity); T1/T2-merged versions"),
    @("ML answers", "predicted class, merged class, probability of each of the seven classes"),
    @("Columns", ("" + $s.cols + " columns; data version 1.0")))
  Eqs = @()
  Tools = @("06_Python_ML/src/stats/step28_merge_predictions.py (join and checks)", "tests/test_merged_predictions.py (4 tests: one row per test record, values copied unchanged)")
  Refs = @()
}

$global:Closings["28"] = @{
  Achieved = @(
    "All ML and conventional answers for the 388 test records are in one checked file.",
    "No record was lost or duplicated, and every value was copied unchanged (automated tests).")
  Record = @(
    @("Step", "28 - Merge all predictions"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "12 October 2026"), @("Status", "Done"),
    @("Main inputs", "dga_master.csv; 11_Results/conventional/conventional_predictions.csv; 11_Results/ml/ml_predictions.csv"),
    @("Main outputs", "08_Statistical_Analysis/merged_predictions.csv and merge_checks.json"),
    @("Checks", ("no record lost or duplicated; values unchanged; normality gate identical for all methods; " + $s.tests)),
    @("Decisions", "none new (scoring rules of D11-D13, D19 apply in Step 29)"))
  Helps = @(
    "Step 29 computes all performance measures with confidence intervals from this file only.",
    "Step 30 runs the significance tests and Step 31 the boundary analysis on the same records.")
  Open = @(
    ("The normality gate calls " + $s.gateN + " of the 388 test records Normal, although most of them come from faulty units (the IEC TC 10 and Li 2019 sets contain only faults). This will lower the conventional methods' scores; Step 29 also reports them with the lower gate and without the gate (raw answers) so the effect is visible."),
    "Decision D23 rule (4) (Step 26) is still awaiting the researcher's confirmation; it does not affect this file.")
  Exclude = @()
}

$global:StepSources["28"] = @("DF2", "DF9", "DF25", "DF34", "DF6", "SW1")
