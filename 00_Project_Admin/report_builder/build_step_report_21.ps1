$ErrorActionPreference = "Stop"
# build_step_report_21.ps1 - Word report of roadmap Step 21. Every number is read from model_selection_tests.csv and fold_metrics.csv.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report21_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8

# ---- results (read before the entries file, which uses $global:S21) ------------------------------------------------
$inv = [Globalization.CultureInfo]::InvariantCulture
function D([string]$v) { [double]::Parse($v, $inv) }
function F3([string]$v) { (D $v).ToString("0.000", $inv) }
$label = @{ logistic_regression = "Logistic regression"; svm = "SVM (RBF)"; random_forest = "Random Forest"; xgboost = "XGBoost"; mlp = "Neural network (MLP)" }
$tests = Import-Csv (Join-Path $root "07_Experiments\model_selection_tests.csv")
$fm    = Import-Csv (Join-Path $root "07_Experiments\2026-10-11_nestedcv_v1\fold_metrics.csv")
$sel   = Get-Content (Join-Path $root "07_Experiments\model_selection.md") -Raw
$nTe = ($fm | ForEach-Object { [double]$_.n_test } | Measure-Object -Average).Average
$nTr = ($fm | ForEach-Object { [double]$_.n_train } | Measure-Object -Average).Average
$best = $tests[0]; $next = $tests[1]
if ($sel -notmatch 'Decision: \*\*(\w+) on feature set (F\d)\*\*') { throw "decision not found in model_selection.md" }
$chModel = $Matches[1]; $chFs = $Matches[2]
$notDiff = @($tests | Where-Object { $_.significantly_worse_than_best -eq "False" })
$simp = $notDiff | Sort-Object { [int]$_.family_rank }, { [int]$_.n_features }, { -(D $_.mean_macro_f1) } | Select-Object -First 1
$global:S21 = @{
  ratio = ("{0:0.00} / {1:0.00} = {2:0.000}" -f $nTe, $nTr, ($nTe / $nTr)).Replace(",", ".")
  chosen = ($label[$chModel] + " on feature set " + $chFs)
  more = ($notDiff.Count - 2)
  simplest = ($label[$simp.model] + " on " + $simp.feature_set + " (mean macro-F1 " + (F3 $simp.mean_macro_f1) + ", p = " + (D $simp.p).ToString("0.000", $inv) + ")")
}
$nSig = @($tests | Where-Object { $_.significantly_worse_than_best -eq "True" }).Count
# the text below states that every F1/F2 pipeline is significantly worse and every not-worse pipeline uses F3/F4 - verify
if (@($tests | Where-Object { $_.feature_set -in "F1", "F2" -and $_.significantly_worse_than_best -ne "True" }).Count -gt 0) { throw "F1/F2 statement not true" }

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
. (Join-Path $sp "report_entries_14_17.ps1")
. (Join-Path $sp "report_entries_18.ps1")
. (Join-Path $sp "report_entries_19.ps1")
$global:S20 = @{}
. (Join-Path $sp "report_entries_20.ps1")
. (Join-Path $sp "report_entries_21.ps1")

function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed = "11 October 2026") {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "21" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }
$pNext = (D $next.p).ToString("0.000", $inv)

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "21" "Select the final model by the written rule" "Claude Code (this chat)"
Summary ("The final model is " + $S21.chosen + ". It had the highest mean macro-F1 over the 50 cross-validation folds (" + (F3 $best.mean_macro_f1) + "). The next pipeline, " + $label[$next.model] + " on " + $next.feature_set + " (" + (F3 $next.mean_macro_f1) + "), was not significantly different (corrected resampled t-test, p = " + $pNext + "), so the rule then asks for the simpler of the two; by the order fixed in advance (decision D18) " + $label[$best.model] + " is the simpler, so it stays. The choice was made before any test set was opened.")
H1N "Purpose of this step"
Body "This step chooses, by the rule written in the Analysis Plan before the work began, the one pipeline (inputs, preprocessing and classifier) that will be fitted on all development records and tested once on the three test sets in Step 22."
MethodSection "21"
H1N "What was done, step by step"
NumItem "1" "Fixed the details of the rule that the plan left open as decision D18 (candidates, which pipeline is 'next', test settings, order of simplicity), at 21:55 while the Step 20 run was at 750 of 1 200 tasks - before any of its results were read."
NumItem "2" "Wrote the selection program (step21_select_model.py) and its tests; the program refuses to run if a test set has already been opened."
NumItem "3" "After Step 20 finished, ran the program on the saved fold results: ranked the 20 candidates by mean macro-F1, tested the best against the next, applied the simplicity order, and compared every candidate with the best as supporting information."
H1N "What we found"
H2 "Best and next pipeline"
AddTable @("", "Pipeline", "Mean macro-F1 (SD)", "Difference to best", "t", "p") @(
  , @("Best", ($label[$best.model] + ", " + $best.feature_set), ((F3 $best.mean_macro_f1) + " (" + (F3 $best.sd_macro_f1) + ")"), "-", "-", "-")
  , @("Next", ($label[$next.model] + ", " + $next.feature_set), ((F3 $next.mean_macro_f1) + " (" + (F3 $next.sd_macro_f1) + ")"), (F3 $next.mean_difference_to_best), (D $next.t).ToString("0.000", $inv), $pNext)
) @(40, 130, 90, 70, 45, 45)
Body ("The difference is not significant (p = " + $pNext + " > 0.05). By the simplicity order of D18, " + $label[$best.model] + " (family " + $best.family_rank + " of 5) is simpler than " + $label[$next.model] + " (family " + $next.family_rank + " of 5), and both use the same " + $best.n_features + " inputs; the rule therefore keeps " + $S21.chosen + ".")
H2 "Settings most often chosen for the selected pipeline in the 50 outer folds"
$fmc = $fm | Where-Object { $_.model -eq $chModel -and $_.feature_set -eq $chFs }
$rows = @()
foreach ($g in ($fmc | Group-Object best_params | Sort-Object Count -Descending | Select-Object -First 5)) { $rows += , @($g.Name, ("" + $g.Count)) }
AddTable @("Setting (inner-loop choice)", "Folds") $rows @(330, 60)
Body "The settings are chosen again on all development records in Step 22 with the same inner procedure; the table shows how stable the choice was across folds."
H2 "Every candidate compared with the best (supporting information)"
$rows = @()
foreach ($r in $tests) {
  $rows += , @(($label[$r.model] + ", " + $r.feature_set), ((F3 $r.mean_macro_f1) + " (" + (F3 $r.sd_macro_f1) + ")"), $(if ($r.t -eq "") { "-" } else { (F3 $r.mean_difference_to_best) }), $(if ($r.t -eq "") { "-" } else { (D $r.t).ToString("0.00", $inv) }), $(if ($r.p -eq "") { "-" } else { (D $r.p).ToString("0.000", $inv) }), $(if ($r.t -eq "") { "(best)" } elseif ($r.significantly_worse_than_best -eq "True") { "yes" } else { "no" }))
}
AddTable @("Pipeline", "Mean macro-F1 (SD)", "Difference to best", "t", "p", "Significantly worse?") $rows @(140, 90, 70, 45, 50, 75)
Body ("" + $nSig + " of the 19 other pipelines are significantly worse than the best; " + ($notDiff.Count - 1) + " are not. These 19 comparisons are not corrected for multiple testing and are descriptive only; the formal comparison of all models (Friedman and Nemenyi tests) is Step 30. Every pipeline built only on F1 (log gas values) or F2 (gas percentages) was significantly worse than the best; the pipelines that are not significantly worse all use F3 or F4, the sets that contain the gas ratios and Duval percentages.")
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("Data version 1.0 unchanged (SHA-256 manifest)", "PASS")
  , @("Rule details fixed before the Step 20 results were read (D18, 21:55; results first read after 23:44)", "PASS")
  , @("Test sets opened before the choice", "No - checked by the program (run_info test_sets_opened = false; no ML test predictions exist)")
  , @("Choice follows the written rule", "PASS - made by the program, not by hand")
  , @("Unit tests (test_model_selection.py) and full suite", "4 of 4; 91 of 91 pass")
) @(300, 150)
H1N "Problems and fixes"
Bullet "None. One point of interpretation was settled in advance rather than after the results: whether a 'model' means a classifier or a classifier with its feature set. D18 treats each of the 20 classifier-feature set pipelines as a candidate, because the inputs are part of what is deployed."
H1N "Decisions"
Bullet "D18 (procedural, within the approved plan): candidates, meaning of 'next', settings of the corrected resampled t-test and the order of simplicity, all fixed before the results were read."
H1N "Files produced"
Bullet "07_Experiments/model_selection.md (the choice and its reasons); 07_Experiments/model_selection_tests.csv (every candidate against the best)"
Bullet "06_Python_ML/src/ml/step21_select_model.py; 06_Python_ML/tests/test_model_selection.py"
Closing "21" 0 ("Step 22: tune and fit " + $S21.chosen + " on all development records and predict the internal test set, the IEC TC 10 benchmark and the Li 2019 set - once, with a log showing that the test sets were opened only then.") $global:Blocks["21"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_21_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_21_Report.docx") -Force
("SAVED Step_21_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
