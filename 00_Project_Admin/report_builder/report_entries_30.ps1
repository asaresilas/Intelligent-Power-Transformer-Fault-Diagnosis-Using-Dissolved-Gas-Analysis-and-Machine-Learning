# report_entries_30.ps1 - "Method used" and closing entries for roadmap Step 30 (report standard 2026-10-10/11).

$s = $global:S30
$global:Methods["30"] = @{
  Approach = @(
    "Three groups of standard tests, all fixed in the Analysis Plan (Section 7) with the remaining details written down as decision D26 before computing.",
    "Classifiers (cross-validation): the Friedman test ranks the six models in each of the 50 outer folds and tests whether their average ranks differ; the Nemenyi critical difference then shows which pairs differ (Demsar, 2006), drawn as a critical-difference diagram (Figure 4.7).",
    "ML against the conventional methods (test sets): on each test set, Cochran's Q first tests whether the four methods have the same share of correct answers; McNemar's test then compares the ML model with each conventional method on the same records, and the Holm correction keeps the chance of any false positive among the three comparisons at 5 %. The odds ratio b/c is the effect size. The same tests were repeated without the normality gate.",
    "Agreement: Cohen's kappa between every pair of methods and the true label (Table 4.7, Figure 4.11). Finally the research hypothesis was judged by its written criteria 1 and 2 (criterion 3 follows in Step 31).")
  Why = @(
    "Comparing methods on the same records with paired tests (McNemar, Cochran's Q) uses only the records where they differ, which is the correct and most powerful way for this design.",
    "Without the Holm correction, three tests per test set would give a higher than 5 % chance of a false 'significant' result.",
    "The Friedman/Nemenyi procedure is the standard recommended for comparing several classifiers on the same folds (Demsar, 2006).")
  Settings = @(
    @("Significance level", "alpha = 0.05, two-sided; exact p-values reported"),
    @("Friedman", ("6 models on feature set F4, 50 outer folds; Nemenyi q_alpha from the studentised range distribution = " + $s.q + "; CD = " + $s.cd)),
    @("McNemar", "continuity-corrected chi-square (Eq. 30); exact binomial when b + c < 25 (Eq. 31); Holm within each test set (m = 3)"),
    @("Correct answer", "strict scoring of D25 (no diagnosis counts as wrong); upper normality gate; sensitivity without gate"),
    @("Odds ratio", "b/c with 95 % CI from the log odds ratio; 0.5 added to b and c only when one of them is 0"),
    @("Hypothesis", "judged on the main benchmark, IEC TC 10 power transformers (approved item 2); internal and Li sets supporting"))
  Eqs = @(
    @{ Eq = 'χ_F^2=(12n_f)/(k(k+1)) (∑_j▒R_j^2 -(k(k+1)^2)/4)'; Where = @(@('n_f, k', 'folds (50) and models (6)'), @('R_j', 'average rank of model j (1 = best)')) },
    @{ Eq = '"CD"=q_α √((k(k+1))/(6n_f ))'; Where = @(@('q_α', 'critical value of the studentised range statistic divided by √2, for k models at α = 0.05')) },
    @{ Eq = 'χ^2=(|b-c|-1)^2/(b+c)'; Where = @(@('b', 'records the ML model got right and the conventional method got wrong'), @('c', 'records the conventional method got right and the ML model got wrong')) })
  Tools = @("06_Python_ML/src/stats/step30_tests.py (Friedman, Nemenyi, Cochran's Q, McNemar, Holm, kappa, hypothesis criteria, Figures 4.7 and 4.11)",
            "tests/test_significance.py (5 tests: McNemar, Holm and Cochran equal statsmodels; Friedman equals scipy; q_alpha equals Demsar's table)")
  Refs = @("M25", "M26", "M27", "M28", "M29", "M30", "M22")
}

$global:Closings["30"] = @{
  Achieved = @(
    "All planned significance tests are computed with exact p-values and effect sizes, significant or not.",
    "The research hypothesis has been judged by its written criteria 1 and 2; the verdict on the main benchmark is already determined by criterion 1.",
    "Tables 4.6 and 4.7 and Figures 4.7 and 4.11 are produced with their data files.")
  Record = @(
    @("Step", "30 - Run the significance tests"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "12 October 2026"), @("Status", "Done"),
    @("Main inputs", "07_Experiments/2026-10-11_nestedcv_v1/fold_metrics.csv; 08_Statistical_Analysis/merged_predictions.csv"),
    @("Main outputs", "08_Statistical_Analysis/ (cochran_mcnemar.csv, cochran_q.csv, friedman.csv, nemenyi_pairs.csv, kappa_matrix.csv, hypothesis_criteria.json); Tables T4_6, T4_7; Figures F4_7, F4_11"),
    @("Checks", ("test functions equal statsmodels/scipy; re-run identical; " + $s.tests)),
    @("Decisions", "D26 (test details; procedural); D23 rule (4) confirmed by the researcher"))
  Helps = @(
    "Step 31 tests criterion 3 (are disagreements concentrated near the decision boundaries?) and completes the verdict.",
    "Step 32 builds all Chapter 4 tables and figures from these files, including Figures 4.6, 4.9 and 4.10.")
  Open = @(
    "The Friedman/Nemenyi tests use 50 folds of one data set, which are not independent; they support, but do not replace, the corrected resampled t-test of Step 21.",
    "With 58 records the IEC TC 10 test has limited power: 'not significant' there means the data cannot separate the methods, not that they are equal.",
    "Criterion 2 cannot be met against Duval as written, because Duval always gives a diagnosis (its strict and conditional gaps are equal); this is reported, not reinterpreted.",
    "Home advantage of the conventional methods on IEC TC 10 (IEC limits refined on these cases); whether the Duval zones were also tuned on them remains TO VERIFY from Duval (2002), register M24.")
  Exclude = @()
}

$global:StepSources["30"] = @("DF21", "DF34", "DF35", "DF37", "DF38", "DS1", "SW1")
