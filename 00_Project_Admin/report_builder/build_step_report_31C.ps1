$ErrorActionPreference = "Stop"
# build_step_report_31C.ps1 - Word report of roadmap Step 31C (Study 2 leave-one-source-out runs). Values from the run folder.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report31C_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8
$inv = [Globalization.CultureInfo]::InvariantCulture
$run = Join-Path $root "07_Experiments\2026-10-12_study2_loso"
$fits = Get-Content (Join-Path $run "fits.json") -Raw | ConvertFrom-Json
$cfg = Get-Content (Join-Path $run "config.json") -Raw | ConvertFrom-Json
$rr = Get-Content (Join-Path $run "rerun_check.json") -Raw | ConvertFrom-Json
foreach ($c in $rr) { if (-not $c.same_predictions -or $c.max_probability_difference -ne 0) { throw "rerun check failed" } }
$pred = Import-Csv (Join-Path $run "predictions.csv")
$testOut = & (Join-Path $root "06_Python_ML\.venv\Scripts\python.exe") -I -m pytest (Join-Path $root "06_Python_ML\tests") -q -p no:cacheprovider 2>&1 | Select-Object -Last 1
if ("$testOut" -notmatch '^(\d+) passed') { throw "tests failed: $testOut" }
$nT = $Matches[1]
$NAMES = @{ DISTRAIN = "Dissanayake training"; DISTEST = "Dissanayake unseen"; IECTC10 = "IEC TC 10"; LI2019 = "Li 2019" }
$VN = @{ primary = "primary"; equal_source_weight = "equal source weight"; iec_all = "IEC TC 10 all 117" }

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
$global:Methods["31C"] = @{
  Approach = @(
    "Leave-one-source-out: each of the four sources was held out in turn. Models B (pooled Random Forest on the 18 gas features) and C (hybrid: the same plus the conventional methods' answers, gate flags and boundary distances, 49 inputs) were tuned and fitted on the other three sources only, then predicted the held-out source once. The released model A was applied unchanged to the three external sources.",
    "Tuning repeated the Step 20 procedure inside the training sources: the same 9-point grid, 5-fold grouped cross-validation that keeps near-copies together, macro-F1. Two sensitivity variants were run: equal total weight for each training source, and all 117 IEC TC 10 records instead of the 58 power transformers.")
  Why = @(
    "Holding out a whole source shows how a model performs on data from a laboratory or database it has never seen - the situation of a utility using the model in practice.",
    "Re-using the Step 20 tuning procedure means the only differences from the main study are the training sources and, for model C, the extra inputs.")
  Settings = @(
    @("Held-out sources", "Dissanayake training, Dissanayake unseen, IEC TC 10 (58 power transformers), Li 2019"),
    @("Models", "A released (unchanged, T1/T2 merged); B pooled RF/F4 (18 inputs); C hybrid (49 inputs)"),
    @("Tuning", "GridSearchCV, Step 20 grid (9 settings), StratifiedGroupKFold(5) with pooled near-duplicate groups, macro-F1; balanced class weights"),
    @("Seeds", ("" + $cfg.seed + " + index of the held-out source")),
    @("Variants", "primary; equal source weight; IEC TC 10 all 117 records"),
    @("Software", ("scikit-learn " + $cfg.scikit_learn)))
  Eqs = @()
  Tools = @("06_Python_ML/src/study2/study2_models.py (hybrid features, weighted classifier)", "06_Python_ML/src/study2/step31c_loso.py (splits, tuning, predictions, rerun check)", "tests/test_study2_models.py (5 tests incl. leakage-free splits)")
  Refs = @("M15", "M13")
}
$global:Closings["31C"] = @{
  Achieved = @(
    ("All " + @($fits).Count + " tuned fits finished; " + $pred.Count + " predictions with class probabilities are saved."),
    "No held-out record or near-copy entered any training set (checked in the program and by tests).",
    "Two tasks re-fitted from scratch gave identical predictions and probabilities.")
  Record = @(
    @("Step", "31C - Leave-one-source-out training and prediction (Study 2)"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "12 October 2026"), @("Status", "Done"),
    @("Main inputs", "03_Data/study2/study2_pooled.csv (manifest checked); ml_config.yaml; dga_model_v1"),
    @("Main outputs", "07_Experiments/2026-10-12_study2_loso/ (config.json, fits.json, predictions.csv, rerun_check.json)"),
    @("Checks", ("leakage-free splits; rerun identical; " + $nT + " of " + $nT + " tests pass")),
    @("Decisions", "none new (protocol D28)"))
  Helps = @("Step 31D computes the measures, the paired contrasts and the reject option from these predictions only.")
  Open = @(
    "The inner-loop scores below are tuning scores on the training sources; they are not results. The held-out results follow in Step 31D.",
    "The computer slept during the run; the time recorded for one fit (Li 2019, model B, primary) includes that pause and is not a computing time.")
  Exclude = @()
}
$global:StepSources["31C"] = @("DF41", "DF27", "DF40", "DF42", "SW1")

function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed = "12 October 2026") {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "31C" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "31C" "Leave-one-source-out training and prediction (Study 2)" "Claude Code (this chat)"
Summary ("All Study 2 models were trained and applied exactly as the protocol specifies: each source held out in turn, models B and C tuned on the other sources only, model A applied unchanged; " + @($fits).Count + " tuned fits in three variants and " + $pred.Count + " saved predictions. No held-out record or near-copy entered any training set, and re-fitting two tasks from scratch reproduced them exactly. The performance results are computed in Step 31D.")
H1N "Purpose of this step"
Body "This step produces the Study 2 predictions: for every held-out record, what models A, B and C would have said, with the probability of each class."
MethodSection "31C"
H1N "What was done, step by step"
NumItem "1" "Wrote study2_models.py (hybrid inputs over fixed answer categories; a class-weighted classifier that can also take source weights) and step31c_loso.py; five tests, including one that checks every split for leakage."
NumItem "2" "Checked the protocol fingerprint and the Study 2 data manifest at the start of the run, then ran all splits and variants."
NumItem "3" "Re-fitted two saved tasks from scratch and compared them with the saved predictions."
H1N "What was run"
$rows = @()
foreach ($f in $fits) { $rows += , @($VN[$f.variant], $NAMES[$f.held_out], $f.model, ("" + $f.n_train), ("" + $f.n_test), ("" + $f.n_features), ([double]$f.inner_macro_f1).ToString("0.000", $inv), (($f.best_params.PSObject.Properties | ForEach-Object { $_.Name.Replace("min_samples_leaf", "leaf").Replace("max_depth", "depth") + "=" + $(if ($null -eq $_.Value) { "None" } else { $_.Value }) }) -join ", ")) }
AddTable @("Variant", "Held out", "Model", "Train", "Test", "Inputs", "Inner macro-F1", "Chosen setting") $rows @(68, 72, 44, 42, 36, 45, 50, 100)
Body "Inner macro-F1 = tuning score on the training sources (not a result). Model A needs no tuning; it is the released model of Step 24."
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("Protocol fingerprint and Study 2 data manifest unchanged", "PASS")
  , @("No held-out record or near-copy in any training set", "PASS")
  , @("Re-fit of two saved tasks gives identical predictions and probabilities", "PASS")
  , @("Warnings during fitting", "none")
  , @("Full automated test suite", ("PASS - " + $nT + " of " + $nT))
) @(300, 150)
H1N "Problems and fixes"
Bullet "The run took longer than first estimated, and the computer slept for part of it; the run continued without loss and the results are unaffected (seeded and checked by re-fitting)."
H1N "Decisions"
Bullet "No new decision; protocol D28 applied as written."
H1N "Files produced"
Bullet "07_Experiments/2026-10-12_study2_loso/: config.json, fits.json, predictions.csv, rerun_check.json"
Bullet "06_Python_ML/src/study2/study2_models.py, step31c_loso.py; 06_Python_ML/tests/test_study2_models.py; 03_Data/interim/step31c_report.md"
Closing "31C" 0 "Step 31D: measures with 95 % intervals, the paired contrasts B-A, C-B and C against the best conventional method, and the reject option (Tables 4.12-4.13, Figures 4.23-4.24)." $global:Blocks["31C"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $r2 = $doc.Content; $r2.SetRange($r2.End - 2, $r2.End - 1); if ($r2.Text -ne [string][char]13) { break }; $r2.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_31C_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_31C_Report.docx") -Force
("SAVED Step_31C_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
