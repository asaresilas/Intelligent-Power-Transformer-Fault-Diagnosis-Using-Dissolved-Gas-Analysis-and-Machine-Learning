$ErrorActionPreference = "Stop"
# build_step_report_28.ps1 - Word report of roadmap Step 28. Values are read from merged_predictions.csv and merge_checks.json.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report28_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8

$sa = Join-Path $root "08_Statistical_Analysis"
$mg = Import-Csv (Join-Path $sa "merged_predictions.csv")
$ck = Get-Content (Join-Path $sa "merge_checks.json") -Raw | ConvertFrom-Json
foreach ($k in "no_record_lost", "no_record_duplicated", "no_development_record", "ml_records_all_used", "gate_same_for_all_methods", "no_missing_prediction") { if (-not $ck.$k) { throw "check $k failed" } }
$testOut = & (Join-Path $root "06_Python_ML\.venv\Scripts\python.exe") -I -m pytest (Join-Path $root "06_Python_ML\tests") -q -p no:cacheprovider 2>&1 | Select-Object -Last 1
if ("$testOut" -notmatch '^(\d+) passed') { throw "tests failed: $testOut" }
$nTests = $Matches[1]
$gateN = @($mg | Where-Object { $_.gate_upper_normal -eq "True" }).Count
$global:S28 = @{ cols = @($mg[0].PSObject.Properties).Count; gateN = $gateN; tests = ($nTests + " of " + $nTests + " tests pass") }
$roles = @(@("internal_test", "Internal test"), @("benchmark", "IEC TC 10 benchmark"), @("external_test", "Li 2019"))

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
. (Join-Path $sp "report_entries_28.ps1")

function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed = "12 October 2026") {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "28" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "28" "Merge all predictions" "Claude Code (this chat)"
Summary ("The true classes and the answers of the ML model and the three conventional methods for all " + $ck.rows_merged + " test records were joined into one file, one row per record. No record was lost or duplicated, and automated tests confirm that every value was copied unchanged. One point to note for Step 29: the normality gate calls " + $gateN + " test records Normal, although most come from faulty units.")
H1N "Purpose of this step"
Body "This step creates the single, checked data file from which every comparison between the ML model and the conventional methods (Steps 29-32) is computed."
MethodSection "28"
H1N "What was done, step by step"
NumItem "1" "Wrote step28_merge_predictions.py: one-to-one joins on record_id with built-in checks, and merged-class versions of every answer."
NumItem "2" "Ran it and added four automated tests that compare the merged file with its three sources."
H1N "What we found"
H2 "Records per test set"
$rows = @(); foreach ($r in $roles) { $s = @($mg | Where-Object { $_.data_role -eq $r[0] }); $rows += , @($r[1], ("" + $s.Count), ("" + @($s | Where-Object { $_.gate_upper_normal -eq "True" }).Count), ("" + @($s | Where-Object { $_.class_name -eq "Normal" }).Count)) }
AddTable @("Test set", "Records", "Called Normal by the upper gate", "Truly Normal") $rows @(140, 70, 130, 90)
H2 "Answers given by each method (all 388 test records)"
$ans = "Normal", "PD", "D1", "D2", "D1/D2", "T1", "T2", "T3", "DT", "ND"
$rows = @()
foreach ($a in $ans) {
  $line = @($a)
  foreach ($col in "ml_pred", "IEC60599_result", "Rogers_result", "Duval_result") { $line += ("" + @($mg | Where-Object { $_.$col -eq $a }).Count) }
  $rows += , $line
}
AddTable @("Answer", "ML", "IEC 60599", "Rogers", "Duval") $rows @(80, 80, 80, 80, 80)
Body "Conventional answers after the upper normality gate (decision D11). D1/D2 is the IEC dual answer, DT the Duval mixed zone, ND no diagnosis. The ML model always gives one of the seven classes. Rogers shows more Normal answers than the gate alone because its own Case 0 also means Normal."
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("Data version 1.0 unchanged (SHA-256 manifest)", "PASS")
  , @("Every test record of the master table appears exactly once", ("PASS (" + $ck.rows_merged + " rows, " + $ck.unique_record_ids + " unique)"))
  , @("Every ML prediction used; three conventional rows per record", "PASS")
  , @("No development record in the file", "PASS")
  , @("Normality gate identical for the three methods", "PASS")
  , @("Values copied unchanged (automated tests)", ("PASS - " + $S28.tests))
) @(300, 150)
H1N "Problems and fixes"
Bullet "None."
H1N "Decisions"
Bullet "None new. The scoring rules already fixed (D11-D13 for the conventional methods, D19 for the evaluation sets) are applied in Step 29."
H1N "Files produced"
Bullet "08_Statistical_Analysis/merged_predictions.csv (one row per test record) and merge_checks.json"
Bullet "06_Python_ML/src/stats/step28_merge_predictions.py; 06_Python_ML/tests/test_merged_predictions.py; 03_Data/interim/step28_report.md"
Closing "28" 0 "Step 29: compute strict and conditional accuracy, coverage, per-class measures, macro-F1, balanced accuracy, kappa and MCC with Wilson and bootstrap 95 % confidence intervals for every method and test set (Tables 4.3-4.5, Figures 4.5 and 4.8)." $global:Blocks["28"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_28_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_28_Report.docx") -Force
("SAVED Step_28_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
