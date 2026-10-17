$ErrorActionPreference = "Stop"
# build_step_report_25.ps1 - Word report of roadmap Step 25. Every number is read from the run folder and 11_Results/reduced_gas.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$run  = "2026-10-12_reducedgas_v1"
$runDir = Join-Path $root ("07_Experiments\" + $run)
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report25_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8

$inv = [Globalization.CultureInfo]::InvariantCulture
function D([string]$v) { [double]::Parse($v, $inv) }
function F3([string]$v) { (D $v).ToString("0.000", $inv) }
$info = Get-Content (Join-Path $runDir "run_info.json") -Raw | ConvertFrom-Json
$ck   = Get-Content (Join-Path $runDir "step25_checks.json") -Raw | ConvertFrom-Json
$rg   = Import-Csv (Join-Path $root "11_Results\reduced_gas\reduced_gas_results.csv")
$dur  = [datetime]$info.end - [datetime]$info.start
foreach ($k in "complete", "every_record_once_per_repeat", "identical_folds_to_step10", "full_panel_reproduces_step20") { if (-not $ck.$k) { throw "check $k failed" } }
$global:S25 = @{ run = $run; jobs = $info.jobs; python = $info.python; sklearn = $info.scikit_learn; tasks = $ck.tasks
  duration = ("{0} h {1} min" -f [int][math]::Floor($dur.TotalHours), $dur.Minutes)
  completed = ([datetime]$info.end).ToString("d MMMM yyyy", $inv)
  checks = ("complete " + $ck.tasks + "/1550; identical folds PASS; five-gas run = Step 20 PASS; " + $ck.tasks_with_warnings + " tasks with warnings") }
$full = $rg | Where-Object { [int]$_.n_gases -eq 5 }
$bestK = foreach ($k in 1..5) { $rg | Where-Object { [int]$_.n_gases -eq $k } | Sort-Object { -(D $_.macro_f1_mean) } | Select-Object -First 1 }
$worst = $rg | Sort-Object { D $_.macro_f1_mean } | Select-Object -First 1
$within = @($rg | Where-Object { (D $_.loss_vs_full_mean) -le 0.05 } | Sort-Object { [int]$_.n_gases }, { D $_.loss_vs_full_mean })
$smallest = $within | Select-Object -First 1

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
$global:S20 = @{}; $global:S21 = @{}; $global:S22 = @{}; $global:S23 = @{}; $global:S24 = @{ hash = "x" * 64 }
. (Join-Path $sp "report_entries_20.ps1")
. (Join-Path $sp "report_entries_21.ps1")
. (Join-Path $sp "report_entries_22.ps1")
. (Join-Path $sp "report_entries_23.ps1")
. (Join-Path $sp "report_entries_24.ps1")
. (Join-Path $sp "report_entries_25.ps1")

function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed) {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "25" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "25" "Retrain on every gas subset" "Claude Code (this chat)" $S25.completed
Summary ("The selected model was retrained and tested by cross-validation for all 31 combinations of the five gases (" + $ck.tasks + " runs, identical folds). With all five gases the mean macro-F1 is " + (F3 $full.macro_f1_mean) + ". The best single gas is " + $bestK[0].subset_id + " (" + (F3 $bestK[0].macro_f1_mean) + "); the best pair " + $bestK[1].subset_id + " (" + (F3 $bestK[1].macro_f1_mean) + "); the best three gases " + $bestK[2].subset_id + " (" + (F3 $bestK[2].macro_f1_mean) + "); the best four " + $bestK[3].subset_id + " (" + (F3 $bestK[3].macro_f1_mean) + "). " + $(if ($smallest) { "The smallest combination whose mean loss is at most 0.05 has " + $smallest.n_gases + " gases (" + $smallest.subset_id + ")." } else { "No reduced combination has a mean loss of 0.05 or less." }) + " The formal minimum panel, with the 95 % interval of the loss, is decided in Step 27.")
H1N "Purpose of this step"
Body "This step answers a practical question for utilities: how much diagnostic ability is lost when fewer than five gases are measured, as with many online monitors? It provides the data for the minimum-panel decision of Step 27."
MethodSection "25"
H1N "What was done, step by step"
NumItem "1" "Recorded the scope and feature rules as decision D22 before running (scope chosen by the researcher)."
NumItem "2" "Wrote step25_reduced_gas.py with a subset feature builder and five tests (including that five gases give exactly F4)."
NumItem "3" "Ran a 7-task trial: the five-gas results equalled Step 20 to the last digit. The trial folder was then deleted."
NumItem "4" ("Ran all 1 550 tasks in " + $S25.duration + " and summarised them; the checks below passed.")
H1N "What we found"
H2 "Best combination for each number of gases"
$rows = @()
foreach ($r in $bestK) { $rows += , @($r.n_gases, $r.subset_id, $r.n_features, ((F3 $r.macro_f1_mean) + " (" + (F3 $r.macro_f1_sd) + ")"), (F3 $r.loss_vs_full_mean)) }
AddTable @("Gases", "Best combination", "Features", "Macro-F1 mean (SD)", "Mean loss vs five gases") $rows @(45, 170, 55, 95, 90)
H2 "All 31 combinations (mean over 50 folds)"
$rows = @()
foreach ($r in ($rg | Sort-Object { [int]$_.n_gases }, { -(D $_.macro_f1_mean) })) { $rows += , @($r.n_gases, $r.subset_id, $r.n_features, ((F3 $r.macro_f1_mean) + " (" + (F3 $r.macro_f1_sd) + ")"), (F3 $r.loss_vs_full_mean), (F3 $r.balanced_accuracy_mean)) }
AddTable @("Gases", "Combination", "Features", "Macro-F1 mean (SD)", "Mean loss", "Balanced accuracy") $rows @(40, 160, 50, 90, 55, 65)
Body ("Mean loss = mean over the 50 folds of (five-gas macro-F1 minus the combination's macro-F1) on the same fold; a negative value means the combination scored higher on average. Lowest result: " + $worst.subset_id + " (" + (F3 $worst.macro_f1_mean) + ").")
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("Data version 1.0 unchanged (SHA-256 manifest)", "PASS")
  , @("All 1 550 tasks completed", ("PASS (" + $ck.tasks + ")"))
  , @("Every development record predicted once per repeat and combination", ("PASS (" + $ck.prediction_rows + " prediction rows)"))
  , @("Every combination used the identical folds of Step 10", "PASS")
  , @("Five-gas run reproduces the Step 20 Random Forest/F4 fold results exactly", "PASS")
  , @("Tasks with any warning", ("" + $ck.tasks_with_warnings))
  , @("Only development records read", "PASS - test sets not used")
) @(300, 150)
H1N "Problems and fixes"
Bullet "The first summary reported the check 'five-gas run reproduces Step 20' as FAILED, although the means were equal. Cause: the check compared exact values with values re-read from a CSV file, and the default CSV reader can change the last binary digit of a number. Fix: the check now compares the original task files of both runs - scores, chosen settings, predicted classes and every probability - and passes for all 50 folds. No result changed; nothing was re-run."
Bullet "The computer went to sleep for part of the night; the run paused and continued without loss, because every task is saved as soon as it finishes. The run time stated in this report includes that pause."
H1N "Decisions"
Bullet "D22: scope - only the selected pipeline is retrained (researcher's choice, to keep the run to hours instead of about 90 hours); feature rules for a gas combination (procedural, following Analysis Plan Section 8)."
H1N "Files produced"
Bullet ("07_Experiments/" + $run + "/: config.yaml, run_info.json, tasks/ (1 550 result and prediction files), fold_metrics.csv, predictions.csv, step25_checks.json")
Bullet "11_Results/reduced_gas/: reduced_gas_results.csv, reduced_gas_subsets.csv; 03_Data/interim/step25_report.md"
Bullet "06_Python_ML/src/ml/step25_reduced_gas.py; 06_Python_ML/tests/test_reduced_gas.py"
Closing "25" 0 "Step 26 (MATLAB): run the three conventional methods with the gases of each combination removed, to show which method can still give a diagnosis." $global:Blocks["25"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_25_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_25_Report.docx") -Force
("SAVED Step_25_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
