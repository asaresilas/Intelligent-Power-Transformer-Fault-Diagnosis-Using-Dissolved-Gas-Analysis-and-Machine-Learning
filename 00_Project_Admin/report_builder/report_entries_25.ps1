# report_entries_25.ps1 - "Method used" and closing entries for roadmap Step 25 (report standard 2026-10-10/11).
# Result numbers are NOT typed here: the builder fills $global:S25 from the result files before dot-sourcing.

$s = $global:S25
$global:Methods["25"] = @{
  Approach = @(
    "The selected pipeline (Random Forest on feature set F4) was trained and tested again for every one of the 31 possible combinations of the five gases, as if only those gases had been measured. Everything else stayed the same: the 50 outer folds of Step 10, the inner tuning of Step 20 with the same seeds, and the same search grid.",
    "For a gas combination, the F4 features are built only from the gases available: the log value of each available gas; the percentage of each gas in their total (when at least two gases are available); a gas ratio only when both of its gases are available (Analysis Plan Section 8); and the Duval percentages only when CH4, C2H4 and C2H2 are all available (decision D22). With all five gases this is exactly F4, which was used as a check.")
  Why = @(
    "Online gas monitors and portable analysers often measure fewer than five gases; the study shows how much diagnostic power is lost when gases are missing - a practical question for utilities choosing monitoring equipment.",
    "Keeping the folds, seeds and tuning identical means that any change in score is caused only by the missing gases (a paired design, Analysis Plan Eq. 36).",
    "Retraining for each combination is fairer than feeding zeros for missing gases to the full model, which would give misleading inputs.")
  Settings = @(
    @("Gas combinations", "31 = 2^5 - 1 (Analysis Plan Eq. 35)"),
    @("Pipeline", "Random Forest (500 trees, class weights), F4 restricted to the available gases (D22); 9-point grid"),
    @("Validation", "nested: 50 outer folds of folds.csv; inner StratifiedGroupKFold(5), seeds as in Step 20; macro-F1"),
    @("Tasks", ("31 x 50 = 1 550; " + $s.jobs + " parallel processes; run time " + $s.duration)),
    @("Records", "439 development records only"),
    @("Software", ("Python " + $s.python + ", scikit-learn " + $s.sklearn)))
  Eqs = @(
    @{ Eq = '2^5-1=31'; Where = @(@('2^5', 'ways to include or leave out each of the five gases (32), less the empty combination')) },
    @{ Eq = 'Δ_S="Macro-F1"_full-"Macro-F1"_S'; Where = @(
        @('Δ_S', 'loss of macro-F1 when only the gases in combination S are available (positive = worse)'),
        @('"Macro-F1"_full, "Macro-F1"_S', 'macro-F1 with all five gases and with the gases in S, on the same fold')) })
  Tools = @("06_Python_ML/src/ml/step25_reduced_gas.py (subset feature builder, nested runs, summary, checks)",
            "tests/test_reduced_gas.py (5 tests: 31 subsets, full panel = F4 exactly, ratio and Duval rules, percentages)")
  Refs = @("M13", "M15")
}

$global:Closings["25"] = @{
  Achieved = @(
    ("All " + $s.tasks + " tasks finished; every development record was predicted once per repeat for every gas combination."),
    "All 31 combinations used the identical folds of Step 10, and the five-gas run reproduced the Step 20 results exactly.",
    "The cross-validated macro-F1 and its loss against the full panel are available for every gas combination, with every prediction saved for Step 27.")
  Record = @(
    @("Step", "25 - Retrain on every gas subset"), @("Environment", "Claude Code (this chat)"),
    @("Completed", $s.completed), @("Status", "Done"),
    @("Main inputs", "dga_master.csv and folds.csv (data version 1.0); configs/ml_config.yaml; the pipeline chosen in Step 21"),
    @("Main outputs", ("07_Experiments/" + $s.run + "; 11_Results/reduced_gas/reduced_gas_results.csv and reduced_gas_subsets.csv")),
    @("Checks", $s.checks),
    @("Decisions", "D22 (scope: researcher; feature rules: procedural)"))
  Helps = @(
    "Step 26 (MATLAB) uses reduced_gas_subsets.csv to show which conventional method can still give a diagnosis for each combination.",
    "Step 27 computes the loss with its 95 % bootstrap interval and finds the smallest gas panel within the approved tolerance (delta = 0.05), with Table 4.9 and Figures 4.16-4.17.")
  Open = @(
    "These are cross-validation results on the development data; the reduced-gas models are not tested on the test sets (not part of the roadmap).",
    "Only the selected pipeline was retrained (D22); another classifier could lose more or less when gases are missing.",
    "Which gas combinations correspond to commercial online monitors must be taken from published sources (TO VERIFY); this is a labelling step only.",
    "Missing gases were simulated by removing them; a real monitor may also measure the remaining gases with different accuracy.")
  Exclude = @()
}

$global:StepSources["25"] = @("DF2", "DF3", "DF6", "DF18", "DF20", "DF23", "DF28", "SW1")
