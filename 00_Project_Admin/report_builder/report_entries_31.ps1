# report_entries_31.ps1 - "Method used" and closing entries for roadmap Step 31 (report standard 2026-10-10/11).

$s = $global:S31
$global:Methods["31"] = @{
  Approach = @(
    "For each conventional method, every primary test record was marked as a disagreement (the ML answer differs from the method's answer) or not. A logistic regression then modelled the probability of disagreement against the record's distance to the nearest decision boundary of that method, standardised to a z-score (Analysis Plan Eq. 33). The odds ratio per standard deviation of distance, with its 95 % confidence interval, is the effect size (Eq. 34).",
    "The main analysis pools the 205 records of the three primary test sets and uses the answers after the normality gate. Sensitivity analyses repeat it with the raw answers (gate removed), for each test set separately, and with test-set indicators. The details were fixed as decision D27 before any model was fitted.",
    "Criterion 3 of the research hypothesis is met for a method when the coefficient is negative and its 95 % interval excludes zero; the hypothesis needs it for each method.")
  Why = @(
    "If the ML model mostly disagrees with a conventional method close to that method's decision lines, the disagreement reflects borderline cases where a fixed rule is uncertain - the mechanism proposed in RQ2.",
    "Logistic regression is the standard model for a yes/no outcome; the odds ratio per standard deviation makes the three methods comparable although their distances are in different units.",
    "Firth's penalised regression (Firth, 1993) was kept ready for complete separation; it was not needed.")
  Settings = @(
    @("Records", ("205 primary test records (internal 61, IEC TC 10 58, Li 2019 86); excluded for an undefined or infinite distance: Rogers " + $s.exR + ", IEC " + $s.exI + ", Duval " + $s.exD)),
    @("Disagreement", "ML answer different from the method's answer; no diagnosis = disagreement; IEC D1/D2 agrees with ML D1 or D2; merged classes on IEC TC 10"),
    @("Distance", "Steps 14-17: IEC and Rogers in decades of the ratio (Eq. 9), Duval in percentage points (Eq. 10); z-score over the records used"),
    @("Model", "maximum-likelihood logistic regression; Firth if separation (not needed); Wald 95 % CI"),
    @("Criterion 3", "beta1 < 0 and 95 % CI of the odds ratio below 1, for each method"))
  Eqs = @(
    @{ Eq = 'ln(π_i/(1-π_i ))=β_0+β_1 d_i'; Where = @(@('π_i', 'probability that record i is a disagreement case'), @('d_i', 'standardised boundary distance of record i (z-score)'), @('β_1', 'change in the log-odds of disagreement per standard deviation of distance')) },
    @{ Eq = '"OR"=e^(β_1 ){SP}"95 % CI"=e^(β_1±1.96"SE"(β_1 ))'; Where = @(@('"OR"', 'odds ratio of disagreement per standard deviation of distance; below 1 = fewer disagreements far from the boundary')) })
  Tools = @("06_Python_ML/src/stats/step31_boundary.py (data, logistic and Firth regression, Table 4.8, Figure 4.12, criterion 3)",
            "tests/test_boundary.py (3 tests: equal to statsmodels; Firth finite under separation; disagreement rule)")
  Refs = @("M31", "M21")
}

$global:Closings["31"] = @{
  Achieved = @(
    "The boundary hypothesis (RQ2) was tested for all three conventional methods, with sensitivity analyses.",
    "All three criteria of the research hypothesis are now decided, and the verdict follows exactly the written rule.",
    "Table 4.8 and Figure 4.12 are produced with their data files.")
  Record = @(
    @("Step", "31 - Test the boundary hypothesis"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "12 October 2026"), @("Status", "Done"),
    @("Main inputs", "08_Statistical_Analysis/merged_predictions.csv (Step 28); hypothesis_criteria.json (Step 30)"),
    @("Main outputs", "08_Statistical_Analysis/boundary_regression.csv, boundary_data.csv; hypothesis_criteria.json (completed); Table T4_8; Figure F4_12"),
    @("Checks", ("regression equals statsmodels; exclusion counts per set corrected and re-run; " + $s.tests)),
    @("Decisions", "D27 (boundary analysis details; procedural)"))
  Helps = @(
    "Step 32 rebuilds every Chapter 4 table and figure, including Figure 4.13 (disagreements in the Duval Triangle), from the saved files.",
    "Chapter 5 (discussion) can explain why the hypothesis was not supported and what the gate and the boundary results mean for practice.")
  Open = @(
    "The distances of the ratio methods are strongly right-skewed (a few records lie far from any limit), so a few records influence the fitted slope; the plan's z-score scale was kept as written.",
    "Disagreements caused by the normality gate are not related to any ratio or zone boundary; this is why the raw-answer sensitivity analysis is reported beside the main one.",
    "With 58 records the IEC TC 10 analysis has little power; a non-significant slope is not evidence that no boundary effect exists.")
  Exclude = @()
}

$global:StepSources["31"] = @("DF34", "DF37", "DF39", "SW1")
