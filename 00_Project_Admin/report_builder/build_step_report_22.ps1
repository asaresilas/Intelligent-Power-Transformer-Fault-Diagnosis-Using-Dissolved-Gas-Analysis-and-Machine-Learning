$ErrorActionPreference = "Stop"
# build_step_report_22.ps1 - Word report of roadmap Step 22. Every number is read from 11_Results/ml and the final-fit folder.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report22_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8

# ---- results (read before the entries file, which uses $global:S22) ------------------------------------------------
$inv = [Globalization.CultureInfo]::InvariantCulture
function D([string]$v) { [double]::Parse($v, $inv) }
function F3([string]$v) { (D $v).ToString("0.000", $inv) }
$ml   = Join-Path $root "11_Results\ml"
$fl   = Import-Csv (Join-Path $ml "ml_first_look.csv")
$cmL  = Import-Csv (Join-Path $ml "ml_first_look_confusion.csv")
$logL = Get-Content (Join-Path $ml "test_set_access.log")
$fit  = Get-Content (Join-Path $root "07_Experiments\2026-10-12_final_fit\final_fit.json") -Raw | ConvertFrom-Json
$t44  = Import-Csv (Join-Path $root "11_Results\tables\T4_4_cv_results.csv") | Where-Object { $_.model -eq "random_forest" -and $_.feature_set -eq "F4" }
$runInfo = Get-Content (Join-Path $root "07_Experiments\2026-10-11_nestedcv_v1\run_info.json") -Raw | ConvertFrom-Json
function Row([string]$name) { $fl | Where-Object { $_.evaluation_set -eq $name } }
function Cell([string]$set, [string]$t, [string]$p) { [int](($cmL | Where-Object { $_.evaluation_set -eq $set -and $_.true -eq $t -and $_.predicted -eq $p }).count) }
function RowSum([string]$set, [string]$t) { (($cmL | Where-Object { $_.evaluation_set -eq $set -and $_.true -eq $t }) | ForEach-Object { [int]$_.count } | Measure-Object -Sum).Sum }
$INT = "Internal test - independent"; $IEC = "IEC TC 10 - power transformers"; $LI = "Li 2019 - independent"
$bp = ($fit.best_params.PSObject.Properties | ForEach-Object { $_.Name + " = " + $(if ($null -eq $_.Value) { "none" } else { $_.Value }) }) -join ", "
$global:S22 = @{ best = $bp; python = $runInfo.python; sklearn = $fit.scikit_learn
  int = (F3 (Row $INT).macro_f1); iec = (F3 (Row $IEC).macro_f1); li = (F3 (Row $LI).macro_f1) }

# statements made in the text below - verified against the saved results
if ((RowSum $IEC "T3") -ne 12 -or (Cell $IEC "T3" "T12") -ne 5) { throw "IEC T3 statement not true" }
if ((RowSum $IEC "PD") -ne 1) { throw "IEC PD statement not true" }
if ((RowSum $LI "T1") -ne 19 -or (Cell $LI "T1" "T1") -ne 7 -or (Cell $LI "T1" "Normal") -ne 5 -or (Cell $LI "T1" "PD") -ne 4) { throw "Li T1 statement not true" }
if ((Cell $IEC "D1" "D2") -ne 3 -or (Cell $IEC "D2" "D1") -ne 3) { throw "IEC D1/D2 statement not true" }
$opened = @($logL | Where-Object { $_ -match "TEST SETS OPENED" })
if ($opened.Count -ne 1) { throw "log must show exactly one opening" }
$mp = Import-Csv (Join-Path $ml "ml_predictions.csv")
if ($mp.Count -ne 388 -or @($mp.record_id | Select-Object -Unique).Count -ne 388) { throw "prediction count statement not true" }
$gapInt = ((D $t44.macro_f1_mean) - (D (Row $INT).macro_f1)).ToString("0.000", $inv)
if ($fit.best_params.max_depth -ne $null -or $fit.best_params.min_samples_leaf -ne 1) { throw "most-often-chosen statement not true" }

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
$global:S20 = @{}; $global:S21 = @{}
. (Join-Path $sp "report_entries_20.ps1")
. (Join-Path $sp "report_entries_21.ps1")
. (Join-Path $sp "report_entries_22.ps1")

function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed = "12 October 2026") {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "22" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "22" "Fit the final model and predict the test sets once" "Claude Code (this chat)"
Summary ("The chosen model (Random Forest on F4) was fitted on the 439 development records and saved before any test record was used. The three test sets were then predicted once. First-look macro-F1: internal test " + $S22.int + " (cross-validation estimate " + (F3 $t44.macro_f1_mean) + "), IEC TC 10 power transformers " + $S22.iec + ", Li 2019 " + $S22.li + ". Scores fall as the test data move further from the training source - the usual pattern for a model tested on other laboratories' data. Formal confidence intervals and the comparison with the conventional methods follow in Steps 28-30.")
H1N "Purpose of this step"
Body "This step gives the first honest measure of how the final model performs on records it has never seen in any form: the internal test set from the same source, the inspection-confirmed IEC TC 10 benchmark, and the Li 2019 set from another publication."
MethodSection "22"
H1N "What was done, step by step"
NumItem "1" "Recorded the remaining details as decision D19 (final tuning, saving before testing, run-once rule, evaluation sets) before running anything."
NumItem "2" "Wrote step22_final_fit.py and checked its scoring part on made-up predictions in a temporary folder (no test record and no model involved)."
NumItem "3" ("Ran the step once. The access log shows: final pipeline fitted and saved (" + $logL[1].Substring(0, 19) + "), test sets opened and predicted (" + $opened[0].Substring(0, 19) + "), predictions written with their fingerprint.")
NumItem "4" "Re-computed the scores from the saved predictions to add the confusion-matrix file (the fingerprint of the predictions did not change), and confirmed that a second full run is refused."
H1N "What we found"
H2 "Final setting chosen on all development records"
Body ("Best setting: " + $S22.best + "; inner-loop macro-F1 " + (F3 ("" + $fit.inner_macro_f1)) + "; fit time " + $fit.fit_seconds + " s; " + $fit.warnings + " warnings. This is also the setting chosen most often in the 50 outer folds of Step 20 (Step 21 report).")
H2 "First-look scores on the test sets"
$rows = @()
foreach ($r in $fl) { $rows += , @($r.evaluation_set, $(if ($r.primary -eq "True") { "primary" } else { "sensitivity" }), $r.n, (F3 $r.macro_f1), (F3 $r.accuracy), (F3 $r.balanced_accuracy), (F3 $r.kappa), $r.n_predicted_normal) }
AddTable @("Evaluation set", "Role", "Records", "Macro-F1", "Accuracy", "Balanced accuracy", "Kappa", "Called Normal") $rows @(112, 62, 52, 50, 56, 58, 45, 55)
Body ("For comparison, the cross-validation estimate on the development data was macro-F1 " + (F3 $t44.macro_f1_mean) + " (SD " + (F3 $t44.macro_f1_sd) + "). The model always gives a diagnosis, so its coverage is 100 % and its strict and conditional accuracy are equal. 'Called Normal' counts fault records that the model called Normal; on IEC TC 10 and Li 2019 every such answer is wrong, because these sets contain only faulty units.")
foreach ($set in $INT, $IEC, $LI) {
  H2 ("Confusion matrix - " + $set + " (rows: true class; columns: predicted class)")
  $labs = @($cmL | Where-Object { $_.evaluation_set -eq $set } | ForEach-Object { $_.true } | Select-Object -Unique)
  $rows = @()
  foreach ($t in $labs) { $line = @($t); foreach ($p in $labs) { $line += ("" + (Cell $set $t $p)) }; $rows += , $line }
  $hdr = @("True \ predicted") + $labs
  $w = @(95) + @(1..$labs.Count | ForEach-Object { [int](360 / $labs.Count) })
  AddTable $hdr $rows $w
}
H2 "What the errors show"
$offInt = $cmL | Where-Object { $_.evaluation_set -eq $INT -and $_.true -ne $_.predicted -and [int]$_.count -gt 0 } | Sort-Object { -[int]$_.count }
$nErr = ($offInt | ForEach-Object { [int]$_.count } | Measure-Object -Sum).Sum
$topInt = ($offInt | Where-Object { [int]$_.count -ge 2 } | ForEach-Object { $_.true + " called " + $_.predicted + " (" + $_.count + ")" }) -join ", "
Bullet ("Internal test (same source as the training data): macro-F1 " + $S22.int + ", " + $gapInt + " below the cross-validation estimate - about one fold-to-fold SD (" + (F3 $t44.macro_f1_sd) + "); " + $nErr + " of " + (Row $INT).n + " records were misclassified, and the only repeated errors were " + $topInt + "; every other error occurred once.")
Bullet ("IEC TC 10 power transformers: the discharge classes are recognised well (D2: " + (Cell $IEC "D2" "D2") + " of " + (RowSum $IEC "D2") + "), but D1 and D2 are confused in both directions (3 each), and only " + (Cell $IEC "T3" "T3") + " of the 12 T3 records were called T3 - 5 were called T1/T2. In this set PD has a single record, so that one record decides one fifth of the macro-F1.")
Bullet ("Li 2019: the weakest class is T1 - of 19 T1 records, 7 were recognised, 5 were called Normal and 4 PD. Low-temperature faults often produce only small amounts of gas and can look like a healthy unit or a partial discharge; a different laboratory and label mapping (Li 2019 is a sensitivity set by plan item 3) add to this.")
Body "These patterns are informative rather than surprising: the thermal-severity boundary (T2/T3) and the low-energy boundary (Normal/PD/T1) are also where the conventional methods' zones meet. Whether the model is better or worse than the conventional methods on the same records is tested formally in Steps 29-30."
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("Data version 1.0 unchanged (SHA-256 manifest)", "PASS")
  , @("Fitted pipeline saved with fingerprint before any test prediction", ("PASS - " + $fit.pipeline_sha256.Substring(0, 16) + "..."))
  , @("Log shows the test sets were opened once, in this step", ("PASS - " + $opened.Count + " opening, " + $opened[0].Substring(0, 19)))
  , @("A second full run is refused", "PASS - program stops: predictions already exist")
  , @("Predictions unchanged after re-scoring", "PASS - same SHA-256")
  , @("Every test record predicted exactly once", "PASS - 388 rows, 388 records")
) @(300, 150)
H1N "Problems and fixes"
Bullet "The first check of the scoring code on made-up data stopped on records without a class label; the real evaluation sets have none, but an explicit check was added so that the real run would stop with a clear message instead. No problem occurred in the real run."
H1N "Decisions"
Bullet "D19 (procedural, within the approved plan): final tuning on all development records with the Step 20 inner procedure; model saved before testing; one-time prediction with log and run-once guard; evaluation sets and scoring as approved (plan items 2, 3, 6, 8; decision D9)."
H1N "Files produced"
Bullet "07_Experiments/2026-10-12_final_fit/: final_pipeline.joblib, final_fit.json, inner_cv_results.csv"
Bullet "11_Results/ml/: ml_predictions.csv, ml_first_look.csv, ml_first_look_confusion.csv, test_set_access.log; 03_Data/interim/step22_report.md"
Bullet "06_Python_ML/src/ml/step22_final_fit.py"
Closing "22" 0 "Step 23: explain the fitted model with permutation importance and SHAP values (Analysis Plan Section 8.1), reporting the results as found." $global:Blocks["22"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_22_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_22_Report.docx") -Force
("SAVED Step_22_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
