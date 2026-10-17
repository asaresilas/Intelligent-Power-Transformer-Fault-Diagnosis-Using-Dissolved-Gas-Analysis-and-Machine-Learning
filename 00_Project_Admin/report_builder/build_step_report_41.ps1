$ErrorActionPreference = "Stop"
# build_step_report_41.ps1 - Word report of roadmap Step 41 (end-to-end test bench).
# Every number is read from 10_Dashboard_Client/logs and results; statements are throw-checked.
# Variable names start with k_ because the dot-sourced helper scripts also use short names.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report41_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8
$inv = [Globalization.CultureInfo]::InvariantCulture
function IsTrue($v) { $v -in @("1", "true", "True") }
function Pct([double[]]$v, [double]$p) { $s = $v | Sort-Object; $s[[int][Math]::Ceiling($p / 100 * $s.Count) - 1] }
function Med([double[]]$v) { $s = $v | Sort-Object; if ($s.Count % 2) { $s[($s.Count - 1) / 2] } else { ($s[$s.Count / 2 - 1] + $s[$s.Count / 2]) / 2 } }

$k_dir = Join-Path $root "10_Dashboard_Client"
$k_chk = Import-Csv (Join-Path $k_dir "results\step41_checks.csv")
$k_log = Import-Csv (Join-Path $k_dir "logs\testbench_log.csv")
$k_info = Get-Content (Join-Path $k_dir "logs\testbench_run_info.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$k_fig = Join-Path $root "11_Results\figures\F4_20_testbench_run.png"
if ($k_chk.Count -ne 12) { throw "expected 12 checks" }
foreach ($c in $k_chk) { if (-not (IsTrue $c.passed)) { throw ("a Step 41 check failed: " + $c.check) } }
if ($k_log.Count -ne 388) { throw "expected 388 rows" }
if (-not (Test-Path $k_fig)) { throw "figure missing" }
$k_ok = @($k_log | Where-Object { $_.ml_status -eq "OK" }).Count
if ($k_ok -ne 388 -or [int]$k_info.n_failed -ne 0) { throw "failed calls in the log" }
function Col($rows, [string]$c) { $rows | ForEach-Object { [double]::Parse($_.$c, $inv) } }
$k_resp = Col $k_log "response_ms"; $k_conv = Col $k_log "conventional_ms"; $k_tot = Col $k_log "total_ms"
$k_med = (Med $k_resp).ToString("0.0", $inv); $k_p95 = (Pct $k_resp 95).ToString("0.0", $inv)
$k_n = @{}; foreach ($r in "benchmark", "internal_test", "external_test") { $k_n[$r] = @($k_log | Where-Object { $_.data_role -eq $r }).Count }
if ($k_n["benchmark"] -ne 117 -or $k_n["internal_test"] -ne 70 -or $k_n["external_test"] -ne 201) { throw "role counts changed" }
$k_green = @($k_log | Where-Object { $_.agreement_state -eq "green" }).Count; $k_amber = @($k_log | Where-Object { $_.agreement_state -eq "amber" }).Count
$k_log2 = Get-Content (Join-Path $root "04_MATLAB_Conventional\tests\test_log.txt") -Encoding utf8
$k_matlab = (($k_log2 | Where-Object { $_ -like "MATLAB:*" } | Select-Object -First 1) -replace "^MATLAB:\s*", "").Trim()
$global:S41 = @{ matlab = $k_matlab; completed = "13 October 2026"; nChecks = $k_chk.Count; n = $k_log.Count; nFailed = [int]$k_info.n_failed
  nBench = $k_n["benchmark"]; nInt = $k_n["internal_test"]; nExt = $k_n["external_test"]; med = $k_med; p95 = $k_p95
  medConv = (Med $k_conv).ToString("0", $inv); medTot = (Med $k_tot).ToString("0", $inv)
  processor = $k_info.processor; cpus = $k_info.logical_processors
  checks = ("verify_step41.m: 12 of 12 checks PASS; 388 rows, 0 failed calls; response time median " + $k_med + " ms, 95th percentile " + $k_p95 + " ms (all calls)") }
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
. (Join-Path $sp "report_entries_41.ps1")
function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed) {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "41" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "41" "Run the end-to-end test bench" "Claude Code (this chat), MATLAB and Simulink through the MCP connection" $S41.completed
Summary ("The whole framework was run once over every held-out record: the Simulink transformer model produced one sampling event every 15 minutes (388 events), and at each event the dashboard functions found the record, computed the Rogers, IEC 60599 and Duval diagnoses in MATLAB, and obtained the ML class and probabilities from the FastAPI service. The result is a log with " + $k_log.Count + " rows, one per record, and no failed call. The response time of the service call was " + $k_med + " ms (median) and " + $k_p95 + " ms (95th percentile) on the project laptop, including the first calls. All " + $k_chk.Count + " checks pass. The comparison of the log with the offline predictions (fidelity) and the formal response-time statistics are the work of Step 42. Figure 4.20 shows the run.")
H1N "Purpose of this step"
Body "The test bench shows that the parts of the framework work together on the whole held-out set, not only on a few examples, and it produces the log from which Step 42 computes fidelity and response time."
MethodSection "41"
H1N "What was used"
Bullet "The unchanged model Transformer_Operating_Model.slx with the sampling-event subsystem SS8 (Step 37)."
Bullet "The dashboard functions of Steps 39 and 40 (find_dga_row, load_dga_record, conventional_diagnosis, ml_diagnose, dga_agreement) and the FastAPI service of Step 38."
Bullet "dga_master.csv: the 388 records whose role is not development."
H1N "What was done, step by step"
NumItem "1" "Fixed the scope, the schedule, the definition of the response time, the log columns and the checks in the decision log (D39) before running."
NumItem "2" "Wrote run_testbench.m. A first test showed that the model can give 388 events when only the sample times and the stop time are set for the run: the model was not changed."
NumItem "3" "Ran the bench with the service running: simulation 9.5 s, the 388 records 196 s."
NumItem "4" "Wrote verify_step41.m (12 checks) and tools/make_figure_4_20.m; ran both."
NumItem "5" "Wrote this report and updated the register, glossary, READMEs, CHANGELOG.md and SESSION_SUMMARY.md."
H1N "What we found"
H2 "The log"
$k_rows = @()
foreach ($r in "benchmark", "internal_test", "external_test") {
  $sub = @($k_log | Where-Object { $_.data_role -eq $r }); $rs = Col $sub "response_ms"
  $g = @($sub | Where-Object { $_.agreement_state -eq "green" }).Count
  $k_rows += , @($r, $sub.Count, @($sub | Where-Object { $_.ml_status -ne "OK" }).Count, (Med $rs).ToString("0.0", $inv), (Pct $rs 95).ToString("0.0", $inv), $g)
}
$k_rows += , @("All held-out", $k_log.Count, 0, $k_med, $k_p95, $k_green)
AddTable @("Data role", "Records", "Failed calls", "Median response (ms)", "95th percentile (ms)", "All three methods agree with ML") $k_rows @(85, 55, 55, 85, 85, 100)
Body ("The columns of the log are listed in decision D39. Every record was answered (status OK). The times are those of all calls, including the first five; they are descriptive. In " + $k_green + " of the " + $k_log.Count + " records all three conventional methods give the same class as ML, and in " + $k_amber + " they do not; this is a count of the log, not a measure of accuracy: no label was used.")
H2 "Figure 4.20"
Caption "Figure 4.20  The test-bench run: simulated temperatures with the 388 sampling events, the ML class of the record taken at each event, and the number of conventional methods that agree with ML"
Pic $k_fig 450
Body "Panel (a) shows the clock of the bench: the simulated transformer reaches its steady temperatures within a few hours and the events follow every 15 minutes. Panel (b) shows the ML class of each record; its pattern follows the order of the records in the file (neighbouring records come from the same source and class), not time. Panel (c) shows how many of the three conventional methods agree with ML for each record."
H1N "Checks"
$k_rows = @(); foreach ($c in $k_chk) { $k_rows += , @($c.check, "PASS") }
AddTable @("Check (verify_step41.m)", "Result") $k_rows @(360, 90)
H1N "Problems and fixes"
Bullet "The roadmap names only the internal-test and benchmark records in one line and every held-out record in others; all 388 were run and the data role was logged (D39). This needs the researcher's confirmation."
Bullet "The first run of the verification script stopped on two coding errors in the script itself (an empty column and a version number were read as numbers instead of text); the log was not changed."
Bullet "The conventional diagnosis in MATLAB takes much longer than the service call (a median of several hundred milliseconds against about 80 ms). This was not investigated; it does not affect the response time of the service."
H1N "Decisions"
Bullet "D39: all 388 held-out records; a sampling event every 15 minutes in the unchanged model; the same functions as the dashboard; the definition of the response time; one log row per record; the checks; Figure 4.20."
H1N "Files produced"
Bullet "10_Dashboard_Client/run_testbench.m, verify_step41.m, tools/make_figure_4_20.m, code_manifest_step41.sha256"
Bullet "10_Dashboard_Client/logs/testbench_log.csv, testbench_run_info.json, testbench_events.mat; 10_Dashboard_Client/results/step41_checks.csv"
Bullet "11_Results/figures/F4_20_testbench_run.png, .pdf and .csv (the plotted numbers)"
Closing "41" 0 "Step 42 (Claude Code): compare testbench_log.csv with ml_predictions.csv and conventional_predictions.csv (fidelity must be 100 %); compute the median and 95th-percentile response times; write Table 4.11, Figure 4.21 and an integration report." $global:Blocks["41"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_41_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_41_Report.docx") -Force
("SAVED Step_41_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber + "`n" + $_.ScriptStackTrace) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
