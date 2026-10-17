$ErrorActionPreference = "Stop"
# build_step_report_24.ps1 - Word report of roadmap Step 24. Values are read from 06_Python_ML/models.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report24_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8

$md   = Join-Path $root "06_Python_ML\models"
$meta = Get-Content (Join-Path $md "dga_model_v1_meta.json") -Raw | ConvertFrom-Json
$chk  = Get-Content (Join-Path $md "reload_check.json") -Raw | ConvertFrom-Json
$fit  = Get-Content (Join-Path $root "07_Experiments\2026-10-12_final_fit\final_fit.json") -Raw | ConvertFrom-Json
$fileHash = (Get-FileHash (Join-Path $md "dga_model_v1.joblib")).Hash
if ($fileHash -ne $meta.sha256 -or $fileHash -ne $fit.pipeline_sha256) { throw "fingerprint mismatch" }
if (-not $chk.pass) { throw "reload check did not pass" }
$testOut = & (Join-Path $root "06_Python_ML\.venv\Scripts\python.exe") -I -m pytest (Join-Path $root "06_Python_ML\tests") -q -p no:cacheprovider 2>&1 | Select-Object -Last 1
if ("$testOut" -notmatch '^(\d+) passed') { throw "test suite did not pass: $testOut" }
$nTests = $Matches[1]
$card = Get-Content (Join-Path $md "model_card.md")
$global:S24 = @{ hash = $fileHash; python = $meta.python; sklearn = $meta.scikit_learn; records = $chk.records
  maxdiff = ("" + $chk.max_abs_probability_difference); pass = "PASS"; tests = ($nTests + " of " + $nTests + " tests pass") }

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
$global:S20 = @{}; $global:S21 = @{}; $global:S22 = @{}; $global:S23 = @{}
. (Join-Path $sp "report_entries_20.ps1")
. (Join-Path $sp "report_entries_21.ps1")
. (Join-Path $sp "report_entries_22.ps1")
. (Join-Path $sp "report_entries_23.ps1")
. (Join-Path $sp "report_entries_24.ps1")

function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed = "12 October 2026") {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "24" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "24" "Save the versioned model" "Claude Code (this chat)"
Summary ("The final model is saved as dga_model_v1.joblib - preprocessing and Random Forest in one file - with its SHA-256 fingerprint, a metadata file and a model card. Reloaded in a fresh Python process, it reproduced all " + $chk.records + " test predictions exactly (same classes; largest probability difference " + $chk.max_abs_probability_difference + "). A damaged or changed file is refused. This completes the machine-learning stage (Steps 19-24).")
H1N "Purpose of this step"
Body "This step turns the evaluated model into a fixed, documented release that the comparison steps, the dashboard and any reader can use - and proves that the saved file is exactly the model whose results are reported."
MethodSection "24"
H1N "What was done, step by step"
NumItem "1" "Recorded the procedure as decision D21 (copy, do not refit; load only with a fingerprint check; reload check in a fresh process; generated model card)."
NumItem "2" "Wrote model_io.py (loader with fingerprint check) and step24_save_model.py (copy, fingerprint, metadata, reload check, model card)."
NumItem "3" "Ran the step and added three automated tests: the fingerprint equals the Step 22 fit, reloading reproduces the Step 22 predictions, and a tampered file is refused."
H1N "What we found"
H2 "The released model"
AddTable @("Item", "Value") @(
  , @("File", "06_Python_ML/models/dga_model_v1.joblib")
  , @("SHA-256", $fileHash)
  , @("Same as the Step 22 fit", $(if ($fileHash -eq $fit.pipeline_sha256) { "yes" } else { "no" }))
  , @("Model", ("Random Forest on " + $meta.feature_set + "; " + (($meta.best_params.PSObject.Properties | ForEach-Object { $_.Name + " = " + $(if ($null -eq $_.Value) { "None" } else { $_.Value }) }) -join ", ")))
  , @("Inputs", (($meta.inputs -join ", ") + " in " + $meta.input_unit + "; a gas not detected: " + $meta.not_detected))
  , @("Outputs", ("one of " + (($meta.classes) -join ", ") + ", with a probability for each"))
  , @("Data version / software", ("data " + $meta.data_version + "; Python " + $meta.python + ", scikit-learn " + $meta.scikit_learn))
) @(130, 325)
H2 "Reload check"
AddTable @("Check", "Result") @(
  , @("Test records predicted again", ("" + $chk.records))
  , @("Same predicted classes", $(if ($chk.same_classes) { "yes" } else { "no" }))
  , @("Largest difference in any class probability", ("" + $chk.max_abs_probability_difference))
  , @("Verdict", "PASS")
) @(300, 150)
H2 "Model card"
Body "The model card (06_Python_ML/models/model_card.md) is generated by the program from the saved result files, so every number in it traces to a file. Its sections:"
foreach ($h in ($card | Where-Object { $_ -match '^## ' })) { Bullet ($h.Substring(3)) }
Body "Key statements of the card: the model is decision support for mineral-oil power transformers, not a replacement for an engineer, the IEC 60599 / IEEE C57.104 procedures, gas-rate trending or inspection; it always gives an answer and has no warning for unusual samples; its performance falls on data from other sources."
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("Data version 1.0 unchanged (SHA-256 manifest)", "PASS")
  , @("Fingerprint of the released file equals the Step 22 fit", "PASS")
  , @("Reload in a fresh process reproduces all test predictions exactly", "PASS")
  , @("Changed file refused by the loader (automated test)", "PASS")
  , @("Full automated test suite", ($nTests + " of " + $nTests + " pass"))
) @(300, 150)
H1N "Problems and fixes"
Bullet "None."
H1N "Decisions"
Bullet "D21 (procedural, within the approved plan): byte copy of the Step 22 fit; loading only through model_io.load_model() with fingerprint check; reload check in a fresh Python process; model card generated from the result files."
H1N "Files produced"
Bullet "06_Python_ML/models/: dga_model_v1.joblib, dga_model_v1.sha256, dga_model_v1_meta.json, model_card.md, reload_check.json"
Bullet "06_Python_ML/src/ml/model_io.py, step24_save_model.py; 06_Python_ML/tests/test_model_v1.py; 03_Data/interim/step24_report.md"
Closing "24" 0 "Stage E - Step 25: retrain the same pipeline on every subset of the five gases (31 subsets) with the identical folds, to find how few gases still give a reliable diagnosis." $global:Blocks["24"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_24_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_24_Report.docx") -Force
("SAVED Step_24_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
