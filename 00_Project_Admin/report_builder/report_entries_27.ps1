# report_entries_27.ps1 - "Method used" and closing entries for roadmap Step 27 (report standard 2026-10-10/11).
# Result values are NOT typed here: the builder fills $global:S27 from the result files before dot-sourcing.

$s = $global:S27
$global:Methods["27"] = @{
  Approach = @(
    "For each of the 31 gas combinations of Step 25, the loss of macro-F1 against the five-gas panel was computed with a 95 % confidence interval, and the rule fixed in the Analysis Plan was applied: the minimum panel is the combination with the fewest gases whose loss, at the UPPER end of its 95 % interval, is at most the approved tolerance of 0.05.",
    "Macro-F1 for a combination is computed on all 439 out-of-fold predictions of each of the 10 repeats and averaged (decision D24). The interval comes from a stratified percentile bootstrap: the records are drawn again with replacement within each fault class, 2000 times, and the same drawn records are used for every combination, so the loss is a paired comparison.",
    "As a check on robustness, the corrected resampled t interval of the fold-by-fold loss was also computed. The conventional-method column of Table 4.9 comes from Step 26.")
  Why = @(
    "Using the upper end of the interval, not the average, means a combination is accepted only if the data show that its loss is small - the cautious choice for an engineering recommendation.",
    "The tolerance (0.05) was approved in Step 4, before any result was seen, so the decision cannot be tuned to the results.",
    "The stratified bootstrap is the interval method approved in Analysis Plan Section 6.2 (Efron and Tibshirani, 1993); pairing the resamples removes the variation that all combinations share.")
  Settings = @(
    @("Tolerance delta", "0.05 macro-F1 (approved item 13, Step 4)"),
    @("Bootstrap", ("stratified percentile; B = " + $s.B + "; seed 20261010; n = " + $s.n + " development records; paired across combinations")),
    @("Statistic", "macro-F1 on the out-of-fold predictions of each repeat, averaged over 10 repeats"),
    @("Decision rule", "fewest gases with upper 95 % limit of the loss <= 0.05 (Eq. 37)"),
    @("Sensitivity", "corrected resampled t interval of the mean fold loss (Eq. 28)"))
  Eqs = @(
    @{ Eq = 'Δ_S="Macro-F1"_full-"Macro-F1"_S'; Where = @(
        @('Δ_S', 'loss of macro-F1 with only the gases of combination S (positive = worse)')) },
    @{ Eq = 'U_95 (Δ_S)≤δ'; Where = @(
        @('U_95 (Δ_S)', 'upper limit of the 95 % bootstrap interval of the loss (97.5th percentile of the 2000 resampled losses)'),
        @('δ', 'tolerance, 0.05')) })
  Tools = @("06_Python_ML/src/ml/step27_minimum_panel.py (bootstrap, decision rule, Table 4.9, Figures 4.16 and 4.17)",
            "tests/test_minimum_panel.py (the fast macro-F1 equals scikit-learn's)")
  Refs = @("M20", "M14")
}

$global:Closings["27"] = @{
  Achieved = @(
    ("The minimum gas panel was found by the rule fixed in advance: " + $s.panel + " (loss " + $s.loss + ", 95 % interval " + $s.lossci + ")."),
    "The corrected t interval, used as a robustness check, gives the same answer.",
    "Table 4.9 and Figures 4.16-4.17 are produced with their data files.",
    "Stage E (reduced-gas study, Steps 25-27) is complete.")
  Record = @(
    @("Step", "27 - Find the minimum gas panel"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "12 October 2026"), @("Status", "Done"),
    @("Main inputs", "Step 25 run (predictions and fold results); reduced_gas_subsets.csv; conventional_applicability.csv (Step 26)"),
    @("Main outputs", "11_Results/tables/T4_9_reduced_gas.csv; 11_Results/reduced_gas/minimum_panel.json; Figures F4_16, F4_17"),
    @("Checks", "tolerance = the approved 0.05; bootstrap reproducible (seeded; re-run gave an identical table); fast macro-F1 tested against scikit-learn"),
    @("Decisions", "D24 (interval and decision details; procedural)"))
  Helps = @(
    "Chapter 4 can state which gases an online monitor must measure for the ML model to keep its accuracy, and which conventional methods are lost.",
    "The dashboard (Steps 38 onwards) can warn when a sample lacks a gas of the minimum panel.")
  Open = @(
    "Results are cross-validation results on the development data only; the reduced-gas models were not tested on the test sets.",
    "Records of a near-duplicate group are resampled independently in the bootstrap, so the intervals may be slightly too narrow.",
    "The minimum panel holds for this data set and this model; its upper loss limit under the t check is close to the tolerance, so it should be confirmed on other data.",
    "Which commercial online monitors measure this gas combination is still to be taken from published sources (TO VERIFY).",
    "Decision D23 rule (4) (normality gate with missing gases) awaits the researcher's confirmation; it does not affect which methods are usable.")
  Exclude = @()
}

$global:StepSources["27"] = @("DF28", "DF29", "DF33", "DF6", "SW1")
