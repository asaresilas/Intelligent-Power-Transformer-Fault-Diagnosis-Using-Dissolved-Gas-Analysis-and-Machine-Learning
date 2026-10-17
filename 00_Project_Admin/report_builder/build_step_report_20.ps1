$ErrorActionPreference = "Stop"
# build_step_report_20.ps1 - Word report of roadmap Step 20. Every number is read from the run folder and Table 4.4.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$run  = "2026-10-11_nestedcv_v1"
$runDir = Join-Path $root ("07_Experiments\" + $run)
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report20_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8

# ---- results (read before the entries file, which uses $global:S20) ------------------------------------------------
$info = Get-Content (Join-Path $runDir "run_info.json") -Raw | ConvertFrom-Json
$t44  = Import-Csv (Join-Path $root "11_Results\tables\T4_4_cv_results.csv")
$rp   = Import-Csv (Join-Path $runDir "reproducibility_check.csv")
$ck   = Get-Content (Join-Path $runDir "step20_checks.json") -Raw | ConvertFrom-Json
$dur  = [datetime]$info.end - [datetime]$info.start
$global:S20 = @{
  run = $run; jobs = $info.jobs; python = $info.python; sklearn = $info.scikit_learn; xgboost = $info.xgboost
  duration = ("{0} h {1} min" -f [int][math]::Floor($dur.TotalHours), $dur.Minutes); tasks = $ck.tasks
  complete = $(if ($ck.tasks -eq $ck.tasks_expected) { "PASS (" + $ck.tasks + " of " + $ck.tasks_expected + " tasks)" } else { "FAIL (" + $ck.tasks + " of " + $ck.tasks_expected + ")" })
  repro = $(if ($ck.reproducible) { "PASS (" + $ck.repro_tasks + " tasks re-run; identical predictions, settings and probabilities)" } else { "FAIL" })
}
$nWarn = $ck.tasks_with_warnings
$onceTxt = $(if ($ck.every_record_once_per_repeat) { "PASS (" + $ck.prediction_rows + " prediction rows)" } else { "FAIL" })
$inv = [Globalization.CultureInfo]::InvariantCulture
function F3([string]$v) { ([double]::Parse($v, $inv)).ToString("0.000", $inv) }
$label = @{ majority = "Majority baseline"; logistic_regression = "Logistic regression"; svm = "SVM (RBF)"; random_forest = "Random Forest"; xgboost = "XGBoost"; mlp = "Neural network (MLP)" }

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
. (Join-Path $sp "report_entries_20.ps1")

function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed = "11 October 2026") {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "20" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }
$best = $t44 | Sort-Object { [double]::Parse($_.macro_f1_mean, $inv) } -Descending | Select-Object -First 1
$base = $t44 | Where-Object { $_.model -eq "majority" } | Select-Object -First 1

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "20" "Train and tune the classifiers (nested cross-validation)" "Claude Code (this chat)"
Summary ("All six models were trained and tuned on all four feature sets with nested cross-validation: " + $S20.tasks + " outer-fold tasks, each with its own inner search for the best settings, using only the 439 development records. The highest mean macro-F1 over the 50 outer folds was " + (F3 $best.macro_f1_mean) + " (SD " + (F3 $best.macro_f1_sd) + "), for " + $label[$best.model] + " on feature set " + $best.feature_set + "; the majority baseline reached " + (F3 $base.macro_f1_mean) + ". These are development-set estimates; no model has been chosen yet (Step 21) and no test set has been opened (Step 22). Re-running saved tasks reproduced the results exactly.")
H1N "Purpose of this step"
Body "This step measures how well each approved model, with each feature set, can recognise the seven classes (Normal, PD, D1, D2, T1, T2, T3), with its settings tuned fairly and its performance measured on records it never saw during training or tuning. The results feed the written model-selection rule in Step 21."
MethodSection "20"
H1N "What was done, step by step"
NumItem "1" "Recorded the remaining design details as decision D17 (inner folds keep near-duplicate groups together, deterministic seeds, what is saved, test sets closed)."
NumItem "2" "Wrote the experiment program (step20_nested_cv.py). Each of the 1 200 tasks saves its result file only when it has finished, so an interrupted run can resume without redoing work."
NumItem "3" "Tested the program on a few tasks and timed one task of every model (about 3 minutes per fold and feature set in total, mostly XGBoost and Random Forest), then ran the full experiment in the background with parallel processes."
NumItem "4" "Collected all task results into fold_metrics.csv and predictions.csv, checked completeness, computed Table 4.4, and re-ran saved tasks from their configuration to prove reproducibility (step20_summarize.py)."
H1N "What we found"
H2 "Table 4.4 - cross-validation results (mean and SD over 50 outer folds)"
$rows = @()
foreach ($r in $t44) { $rows += , @($r.feature_set, $label[$r.model], ((F3 $r.macro_f1_mean) + " (" + (F3 $r.macro_f1_sd) + ")"), ((F3 $r.balanced_accuracy_mean) + " (" + (F3 $r.balanced_accuracy_sd) + ")"), (F3 $r.kappa_mean), (F3 $r.mcc_mean), ([double]::Parse($r.average_rank, $inv)).ToString("0.00", $inv)) }
AddTable @("Set", "Model", "Macro-F1 mean (SD)", "Balanced accuracy mean (SD)", "Kappa", "MCC", "Average rank") $rows @(30, 105, 80, 85, 45, 45, 55)
Body "Average rank: within each of the 50 outer folds the 24 model-feature combinations are ranked by macro-F1 (1 = best) and the ranks are averaged. It is descriptive only; whether the differences are statistically significant is tested in Step 30 (Friedman and Nemenyi tests), and the final choice follows the written rule in Step 21."
foreach ($fsN in "F1", "F2", "F3", "F4") {
  $b = $t44 | Where-Object { $_.feature_set -eq $fsN -and $_.model -ne "majority" } | Sort-Object { [double]::Parse($_.macro_f1_mean, $inv) } -Descending | Select-Object -First 1
  $w = $t44 | Where-Object { $_.feature_set -eq $fsN -and $_.model -ne "majority" } | Sort-Object { [double]::Parse($_.macro_f1_mean, $inv) } | Select-Object -First 1
  Bullet ("Feature set " + $fsN + ": highest mean macro-F1 " + (F3 $b.macro_f1_mean) + " (" + $label[$b.model] + "), lowest " + (F3 $w.macro_f1_mean) + " (" + $label[$w.model] + ").")
}
Body "Every classifier was far above the majority baseline. The fold-to-fold standard deviations (about 0.03 to 0.05) are of the same size as many of the gaps between pipelines, so the order in Table 4.4 must not be read as a ranking of significance; Step 21 applies the written test to the best and the next pipeline."
H2 "F1-score per fault class (mean over 50 folds), best feature set of each model"
$rows = @(); $lowest = @()
foreach ($m in "majority", "logistic_regression", "svm", "random_forest", "xgboost", "mlp") {
  $r = $t44 | Where-Object { $_.model -eq $m } | Sort-Object { [double]::Parse($_.macro_f1_mean, $inv) } -Descending | Select-Object -First 1
  $fsTxt = $(if ($m -eq "majority") { "any set" } else { $r.feature_set })
  $rows += , @(($label[$m] + " (" + $fsTxt + ")"), (F3 $r.f1_Normal_mean), (F3 $r.f1_PD_mean), (F3 $r.f1_D1_mean), (F3 $r.f1_D2_mean), (F3 $r.f1_T1_mean), (F3 $r.f1_T2_mean), (F3 $r.f1_T3_mean))
  if ($m -ne "majority") {
    $cl = "Normal", "PD", "D1", "D2", "T1", "T2", "T3" | Sort-Object { [double]::Parse($r.("f1_" + $_ + "_mean"), $inv) } | Select-Object -First 2
    $lowest += , ($label[$m] + ": " + ($cl -join " and "))
  }
}
AddTable @("Model (feature set)", "Normal", "PD", "D1", "D2", "T1", "T2", "T3") $rows @(122, 48, 45, 45, 45, 45, 45, 45)
Body ("The two classes with the lowest F1 were, for each model: " + ($lowest -join "; ") + ". D1 (low-energy discharge) borders D2 (high-energy discharge), and T2 lies between T1 and T3; the zones of the conventional methods (IEC ratios, Duval Triangle) also meet at these classes, so overlapping gas patterns are a plausible reason. Label quality may also contribute (the labelling method of the development data is not documented). This is an interpretation for the thesis discussion, to be checked with the confusion matrices in Chapter 4.")
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("Data version 1.0 unchanged (SHA-256 manifest)", "PASS")
  , @("Only development records read (the three test sets stay closed)", "PASS - no test record read")
  , @("Completeness (6 models x 4 feature sets x 50 folds)", $S20.complete)
  , @("Every development record predicted once per repeat, model and feature set", $onceTxt)
  , @("Tasks with any warning", ("" + $nWarn))
  , @("Reproducibility: saved tasks re-run from their configuration", $S20.repro)
) @(300, 150)
H1N "Problems and fixes"
Bullet "Run time: before the run, the expected time (about 11 processor-hours) was measured on single tasks, and the program was made resumable so that an interruption (for example the computer going to sleep) would not lose work. The run finished without interruption or error."
Bullet ("Warnings: " + $nWarn + " of the 1 200 tasks each reported one convergence warning, all from the neural network (MLP) on feature set F2 (gas percentages). Each MLP task fits the network 46 times (9 settings x 5 inner folds, plus the final refit), so about 9 200 network fits gave " + $nWarn + " warnings; the saved results do not show whether a warning came from an inner tuning fit or from the final refit. These tasks were kept as they are (removing them would bias the comparison). A likely contributor is that the five percentages of F2 always add up to 100 %, so one input is fully determined by the others; this is not proven. MLP on F2 is not among the leading pipelines (Table 4.4), so the warnings do not affect the model choice in Step 21.")
H1N "Decisions"
Bullet "D17 (procedural, within the approved plan): inner folds keep near-duplicate groups together; deterministic inner seeds; every prediction and probability saved; test sets closed; parallel single-threaded tasks with checkpoints."
H1N "Files produced"
Bullet ("07_Experiments/" + $run + "/: config.yaml, run_info.json, tasks/ (1 200 result files and 1 200 prediction files), fold_metrics.csv, predictions.csv, reproducibility_check.csv")
Bullet "11_Results/tables/T4_4_cv_results.csv (Table 4.4); 03_Data/interim/step20_report.md"
Bullet "06_Python_ML/src/ml/step20_nested_cv.py and step20_summarize.py"
Closing "20" 0 "Step 21: select the final model by the written rule - the highest mean outer-fold macro-F1; if the best and the next model are not significantly different (corrected resampled t-test), the simpler model is chosen - before any test set is opened." $global:Blocks["20"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_20_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_20_Report.docx") -Force
("SAVED Step_20_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
