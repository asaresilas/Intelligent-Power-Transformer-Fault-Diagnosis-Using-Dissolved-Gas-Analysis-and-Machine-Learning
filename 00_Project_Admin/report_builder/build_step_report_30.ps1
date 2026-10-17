$ErrorActionPreference = "Stop"
# build_step_report_30.ps1 - Word report of roadmap Step 30. Every number is read from 08_Statistical_Analysis.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report30_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8

$inv = [Globalization.CultureInfo]::InvariantCulture
function D([string]$v) { [double]::Parse($v, $inv) }
function F3([string]$v) { (D $v).ToString("0.000", $inv) }
function F2([string]$v) { (D $v).ToString("0.00", $inv) }
function PV([string]$v) { $x = D $v; if ($x -lt 0.001) { "< 0.001" } else { $x.ToString("0.000", $inv) } }
$sa  = Join-Path $root "08_Statistical_Analysis"
$fig = Join-Path $root "11_Results\figures"
$fr  = Import-Csv (Join-Path $sa "friedman.csv")
$rk  = Import-Csv (Join-Path $sa "friedman_ranks_F4.csv")
$np  = Import-Csv (Join-Path $sa "nemenyi_pairs.csv")
$cq  = Import-Csv (Join-Path $sa "cochran_q.csv")
$mc  = Import-Csv (Join-Path $sa "cochran_mcnemar.csv")
$kp  = Import-Csv (Join-Path $sa "kappa_matrix.csv")
$hc  = Get-Content (Join-Path $sa "hypothesis_criteria.json") -Raw | ConvertFrom-Json
$SETS = "Internal test", "IEC TC 10 (power transformers)", "Li 2019"
function M([string]$set, [string]$m, [string]$v = "primary") { $mc | Where-Object { $_.evaluation_set -eq $set -and $_.method -eq $m -and $_.variant -eq $v } }
$f6 = $fr[0]
# statement checks
$rf = $rk | Where-Object model -eq "random_forest"; $xg = $rk | Where-Object model -eq "xgboost"
if ((D $rf.average_rank_F4) -ne ($rk | ForEach-Object { D $_.average_rank_F4 } | Measure-Object -Minimum).Minimum) { throw "RF best rank" }
if (($np | Where-Object { ($_.model_a -eq "random_forest" -and $_.model_b -eq "xgboost") }).significant -ne "False") { throw "RF-XGB not significant" }
foreach ($o in "logistic_regression", "svm", "mlp", "majority") { $row = $np | Where-Object { ($_.model_a -eq "random_forest" -and $_.model_b -eq $o) -or ($_.model_b -eq "random_forest" -and $_.model_a -eq $o) }; if ($row.significant -ne "True") { throw "RF vs $o" } }
if ($hc."IEC TC 10 (power transformers)".criterion1_met) { throw "criterion 1 on IEC" }
if (-not $hc."Internal test".criterion1_met -or -not $hc."Li 2019".criterion1_met) { throw "criterion 1 on internal/Li" }
if ((M "IEC TC 10 (power transformers)" "Duval").significant_holm -ne "False" -or [int](M "IEC TC 10 (power transformers)" "Duval").c -le [int](M "IEC TC 10 (power transformers)" "Duval").b) { throw "IEC Duval" }
if ((M "Li 2019" "Duval" "no_gate").significant_holm -ne "False") { throw "Li no-gate Duval" }
$testOut = & (Join-Path $root "06_Python_ML\.venv\Scripts\python.exe") -I -m pytest (Join-Path $root "06_Python_ML\tests") -q -p no:cacheprovider 2>&1 | Select-Object -Last 1
if ("$testOut" -notmatch '^(\d+) passed') { throw "tests failed: $testOut" }
$global:S30 = @{ q = (F3 $f6.q_alpha); cd = (F3 $f6.critical_difference); tests = ($Matches[1] + " of " + $Matches[1] + " tests pass") }
$LAB = @{ majority = "Majority baseline"; logistic_regression = "Logistic regression"; svm = "SVM (RBF)"; random_forest = "Random Forest"; xgboost = "XGBoost"; mlp = "Neural network (MLP)" }

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
. (Join-Path $sp "report_entries_30.ps1")

function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed = "12 October 2026") {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "30" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }
$PAGEW = 453

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "30" "Run the significance tests" "Claude Code (this chat)"
Summary "On the main benchmark (IEC TC 10, inspected power transformers) the ML model is significantly better only than the Rogers ratios; it is not significantly different from IEC 60599 or the Duval Triangle, and Duval was right more often. Criterion 1 of the research hypothesis is therefore not met on the main benchmark, so the hypothesis is not supported there, whatever Step 31 shows. On the internal and Li 2019 test sets the ML model is significantly better than all three methods with the approved normality gate; without the gate it is no longer significantly better than Duval on Li 2019. Among the classifiers, Random Forest and XGBoost cannot be told apart and both rank above the others."
H1N "Purpose of this step"
Body "This step tests which observed differences are larger than chance and judges the research hypothesis by the criteria written before any data were analysed (Analysis Plan Section 2.1)."
MethodSection "30"
H1N "What was done, step by step"
NumItem "1" "Recorded the researcher's confirmation of decision D23 rule (4), and checked open source details online: Crossref, the DOI registration agency, confirmed four references; Duval (2002) was added to the register, its full text still to be read."
NumItem "2" "Fixed the test details as decision D26 before computing."
NumItem "3" "Wrote step30_tests.py and five tests comparing its functions with statsmodels and scipy; ran it; tidied the layout of Figure 4.7 and ran it again with identical results."
H1N "What we found"
H2 "Classifiers: Friedman and Nemenyi (50 outer folds, feature set F4)"
$rows = @(); foreach ($r in ($rk | Sort-Object { D $_.average_rank_F4 })) { $rows += , @($r.label, (F2 $r.average_rank_F4), (F3 $r.mean_macro_f1_F4)) }
AddTable @("Model", "Average rank (1 = best)", "Mean macro-F1") $rows @(160, 120, 120)
Body ("Friedman: chi-square = " + (F2 $f6.chi2) + ", df = " + $f6.df + ", p " + (PV $f6.p) + ". Critical difference (Nemenyi, alpha 0.05) = " + (F3 $f6.critical_difference) + ". Random Forest and XGBoost differ by less than the critical difference and cannot be told apart; Random Forest ranks significantly better than logistic regression, the SVM, the neural network and the baseline. This agrees with Step 21 (corrected resampled t-test, p = 0.621 for Random Forest against XGBoost). Supplementary, over all 24 model-feature combinations: chi-square = " + (F2 $fr[1].chi2) + ", p " + (PV $fr[1].p) + ", CD = " + (F2 $fr[1].critical_difference) + ".")
Caption "Figure 4.7  Critical-difference diagram of the six models (feature set F4, 50 outer folds)"
Pic (Join-Path $fig "F4_7_critical_difference.png") $PAGEW
Body "Models joined by a thick bar differ by less than the critical difference and cannot be told apart statistically."
H2 "Cochran's Q: do the four methods differ at all?"
$rows = @(); foreach ($r in $cq) { $rows += , @($r.evaluation_set, $(if ($r.variant -eq "primary") { "with gate" } else { "no gate" }), $r.n, ($r.correct_ML + " / " + $r.correct_Rogers + " / " + $r.correct_IEC60599 + " / " + $r.correct_Duval), (F2 $r.Q), (PV $r.p)) }
AddTable @("Test set", "Gate", "Records", "Correct: ML / Rogers / IEC / Duval", "Q (df 3)", "p") $rows @(115, 55, 55, 130, 50, 50)
Body "On every test set the four methods differ significantly in their share of correct answers, so the pairwise McNemar tests are justified."
H2 "Table 4.6 - ML against each conventional method (McNemar, Holm-adjusted)"
foreach ($v in "primary", "no_gate") {
  H3 $(if ($v -eq "primary") { "With the approved normality gate (primary)" } else { "Sensitivity: without the normality gate" })
  $rows = @()
  foreach ($s in $SETS) { foreach ($m in "Rogers", "IEC60599", "Duval") { $r = M $s $m $v; $rows += , @($s, $r.comparison, $r.b, $r.c, $(if ($r.test -like "exact*") { "exact" } else { "chi2 " + (F2 $r.statistic) }), (PV $r.p), (PV $r.p_holm), ((F2 $r.odds_ratio) + " [" + (F2 $r.or_lo) + ", " + (F2 $r.or_hi) + "]"), $(if ($r.significant_holm -eq "True") { "yes" } else { "no" })) } }
  AddTable @("Test set", "Comparison", "b", "c", "Test", "p", "p (Holm)", "Odds ratio b/c [95 % CI]", "Signif.") $rows @(76, 88, 25, 25, 45, 44, 45, 82, 44)
}
Body "b: ML right, other method wrong; c: other method right, ML wrong. An odds ratio below 1 means the conventional method was right more often. On IEC TC 10 the conventional methods have a home advantage (IEC 60599 limits refined on these cases)."
H2 "Table 4.7 - agreement between methods (Cohen's kappa)"
Caption "Figure 4.11  Cohen's kappa between the true label and every method, on each test set"
Pic (Join-Path $fig "F4_11_kappa_agreement.png") $PAGEW
$iecK = $kp | Where-Object { $_.evaluation_set -eq "IEC TC 10 (power transformers)" -and $_.a -eq "True label" }
Body ("Agreement with the true label on IEC TC 10: " + (($iecK | ForEach-Object { $_.b + " " + (F2 $_.kappa) }) -join ", ") + ". Verbal labels for kappa are a guide only, never a test (plan Section 7.5).")
H2 "The research hypothesis - criteria 1 and 2"
$rows = @()
foreach ($s in $SETS) {
  $h = $hc.$s
  $c1 = ($h.criterion1_ML_higher_and_significant.PSObject.Properties | ForEach-Object { ($_.Name -replace "IEC60599", "IEC") + " " + $(if ($_.Value) { "yes" } else { "no" }) }) -join ", "
  $c2 = ($h.criterion2_conditional_gap_smaller.PSObject.Properties | ForEach-Object { ($_.Name -replace "IEC60599", "IEC") + " " + $(if ($_.Value) { "yes" } else { "no" }) }) -join ", "
  $rows += , @($s, ($c1 + " -> " + $(if ($h.criterion1_met) { "MET" } else { "NOT MET" })), ($c2 + " -> " + $(if ($h.criterion2_met) { "MET" } else { "NOT MET" })))
}
AddTable @("Test set", "Criterion 1: ML more accurate, Holm p < 0.05", "Criterion 2: conditional gap smaller than strict gap") $rows @(110, 180, 170)
Bullet "Main benchmark (IEC TC 10, decision D26): criterion 1 is not met - the ML model is significantly better than Rogers only; against IEC 60599 the difference is not significant, and Duval was right on more records than the ML model (not significant). By the written rule, the hypothesis is NOT SUPPORTED on the main benchmark, whatever criterion 3 shows."
Bullet "Supporting test sets: on the internal and Li 2019 sets criterion 1 is met with the approved gate. Criterion 2 is met against Rogers and IEC 60599 (part of the ML advantage comes from always answering) but cannot be met against Duval, which always answers, so these sets give partial support."
Bullet "The final verdict, with criterion 3, is stated after Step 31."
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("Data version 1.0 and merged file unchanged (SHA-256)", "PASS")
  , @("McNemar, Holm, Cochran's Q equal statsmodels; Friedman equals scipy; q_alpha equals Demsar's table (k = 6: 2.850)", "PASS")
  , @("Re-run after the figure change: identical results", "PASS")
  , @("Text statements checked against the result files by the report builder", "PASS")
  , @("Full automated test suite", ("PASS - " + $S30.tests))
) @(300, 150)
H1N "Problems and fixes"
Bullet "Online checks: Crossref returned a wrong record for Holm (1979) and was rate-limited for Cochran (1950); both were confirmed from other records (JSTOR identifier; published reference lists). Cochran's DOI and Nemenyi's thesis details remain TO VERIFY."
Bullet "The primary source needed to settle whether the Duval Triangle zones were tuned on the IEC TC 10 cases (Duval 2002) is behind a subscription; it was added to the register as TO VERIFY."
H1N "Decisions"
Bullet "D26 (procedural): models in the Friedman test, McNemar and Holm details, odds-ratio correction, kappa categories, main benchmark for the verdict."
Bullet "D23 rule (4) confirmed by the researcher: a sample with a missing gas is never declared Normal by the gate."
H1N "Files produced"
Bullet "08_Statistical_Analysis/: cochran_mcnemar.csv, cochran_q.csv, friedman.csv, friedman_ranks_F4.csv, nemenyi_pairs.csv, kappa_matrix.csv, hypothesis_criteria.json"
Bullet "11_Results/tables/T4_6_mcnemar.csv, T4_7_kappa.csv; 11_Results/figures/F4_7_critical_difference, F4_11_kappa_agreement (PNG, PDF, CSV)"
Bullet "06_Python_ML/src/stats/step30_tests.py; 06_Python_ML/tests/test_significance.py; 03_Data/interim/step30_report.md"
Closing "30" 0 "Step 31: fit the logistic regression of disagreement (ML different from each conventional method) on the distance to the nearest decision boundary, to decide criterion 3 and complete the verdict." $global:Blocks["30"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_30_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_30_Report.docx") -Force
("SAVED Step_30_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
