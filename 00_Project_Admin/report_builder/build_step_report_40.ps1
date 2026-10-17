$ErrorActionPreference = "Stop"
# build_step_report_40.ps1 - Word report of roadmap Step 40 (Simulink model linked to the dashboard).
# Every number is read from 10_Dashboard_Client/results and params_transformer.m; statements are throw-checked.
# Variable names start with k_ because the dot-sourced helper scripts also use short names.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report40_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8
$inv = [Globalization.CultureInfo]::InvariantCulture
function IsTrue($v) { $v -in @("1", "true", "True") }

$k_res = Join-Path $root "10_Dashboard_Client\results"
$k_chk = Import-Csv (Join-Path $k_res "step40_checks.csv")
$k_ev  = Import-Csv (Join-Path $k_res "step40_event_run.csv")
$k_par = Get-Content (Join-Path $root "05_Simulink_Model\params_transformer.m") -Encoding UTF8
$k_fig = Join-Path $root "11_Results\figures\F4_22_dashboard_annotated.png"
if ($k_chk.Count -ne 13) { throw "expected 13 checks" }
foreach ($c in $k_chk) { if (-not (IsTrue $c.passed)) { throw ("a Step 40 check failed: " + $c.check) } }
if ($k_ev.Count -ne 4) { throw "expected 4 events" }
if (-not (Test-Path $k_fig)) { throw "figure missing" }
$m = [regex]::Match(($k_par -join "`n"), 't_sample_h\s*=\s*\[([0-9 ]+)\]'); if (-not $m.Success) { throw "t_sample_h not found" }
$k_times = (($m.Groups[1].Value.Trim() -split "\s+") -join ", ")
$m = [regex]::Match(($k_chk | Where-Object { $_.check -like "a full simulated day*" }).detail, '\| ([0-9.]+) s \|'); if (-not $m.Success) { throw "run time not found" }
$k_trun = $m.Groups[1].Value
$k_log2 = Get-Content (Join-Path $root "04_MATLAB_Conventional\tests\test_log.txt") -Encoding utf8
$k_matlab = (($k_log2 | Where-Object { $_ -like "MATLAB:*" } | Select-Object -First 1) -replace "^MATLAB:\s*", "").Trim()
$global:S40 = @{ matlab = $k_matlab; completed = "13 October 2026"; nChecks = $k_chk.Count; times = $k_times; n = $k_ev.Count; tRun = $k_trun
  checks = ("verify_step40.m: 13 of 13 checks PASS; full 24 h day from the app in " + $k_trun + " s; 4 sampling events diagnosed, equal to the offline results; Step 39 checks (19) still pass") }
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
. (Join-Path $sp "report_entries_40.ps1")
function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed) {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "40" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "40" "Link the Simulink model to the dashboard" "Claude Code (this chat), MATLAB and Simulink through the MCP connection" $S40.completed
Summary ("The Run Simulation button of the dashboard now runs the Simulink transformer model for a full simulated day (24 hours, " + $k_trun + " s) and plays back the " + $k_ev.Count + " sampling events of subsystem SS8 at " + $k_times + " hours: at each event the dashboard looks up the record with the given record_id in the DGA file, diagnoses it with the three conventional methods and the ML service, and lists it in an event table together with the simulated hot-spot temperature of that moment. The model was not changed. All " + $k_chk.Count + " checks pass: the events equal those of Step 37, every diagnosis equals the offline result, no gas value comes from the model, and the run also completes without the service, without a loaded file, and with a file that lacks some of the records. The 19 checks of Step 39 still pass.")
H1N "Purpose of this step"
Body "This step turns the dashboard and the model into one test bench: the simulated transformer decides when a sample is taken (the sampling events), and the dashboard diagnoses the measured record that belongs to that moment. The check of the roadmap is that a full simulated day runs from the app without error."
MethodSection "40"
H1N "What was used"
Bullet "Transformer_Operating_Model.slx with the sampling-event subsystem SS8 (Step 37), unchanged."
Bullet "DGADashboard.mlapp and its helper functions (Step 39); the FastAPI service (Step 38)."
Bullet "get_sampling_events.m (look-up of the record_id from the logged index) and the held-out list of params_transformer.m."
H1N "What was done, step by step"
NumItem "1" "Fixed the design in the decision log (D38) before changing anything: the model stays unchanged, what the dashboard does with the events, what happens without a file, and the checks."
NumItem "2" "Extended run_transformer_simulation.m to return the sampling events, and wrote find_dga_row.m (row of a record_id in the file; reads only that column)."
NumItem "3" "Changed the dashboard: the diagnosis was moved into one function used by the Diagnose button and by the events; the Run Simulation callback marks the events on the plot and plays them back; a new event table lists them. The .mlapp was written again."
NumItem "4" "Wrote verify_step40.m (13 checks, including the 19 checks of Step 39) and ran it with the service running."
NumItem "5" "Produced the event listing of the full day (results/step40_event_run.csv) and regenerated Figure 4.22 so that it shows the final app."
NumItem "6" "Wrote this report and updated the register, glossary, READMEs, CHANGELOG.md and SESSION_SUMMARY.md."
H1N "What we found"
H2 "The simulated day"
$k_rows = @(); foreach ($e in $k_ev) { $k_rows += , @($e.event, ([double]::Parse($e.time_h, $inv)).ToString("0.0", $inv), $e.record_id, $e.ml_class, $e.conventional_agreeing, ([double]::Parse($e.hot_spot_C, $inv)).ToString("0.00", $inv)) }
AddTable @("Event", "Time (h)", "Record", "ML class", "Conventional methods agreeing (of 3)", "Simulated hot-spot (degC)") $k_rows @(40, 55, 95, 60, 130, 90)
Body "The record identifiers are those of the first four held-out records (Step 37). The hot-spot temperature is the simulated operating condition at the time of the event; it is displayed beside the record and has no part in its diagnosis. At 6 hours the hot spot is still rising, later it is close to its final value of about 100.3 degC."
H2 "Figure 4.22 (regenerated)"
Caption "Figure 4.22  The diagnostic dashboard after a simulated day and the diagnosis of record IECTC10_0001 (annotated)"
Pic $k_fig 450
Body "The temperature plot shows the numbered sampling events as dotted lines; the event table at the right lists the four records diagnosed during the run."
H1N "Checks"
$k_rows = @(); foreach ($c in $k_chk) { $k_rows += , @($c.check, "PASS") }
AddTable @("Check (verify_step40.m)", "Result") $k_rows @(360, 90)
H1N "Problems and fixes"
Bullet "The tests found a fault in the app: the dotted event lines are hidden from the legend, and a hidden object is not removed when the plot is redrawn, so a second run showed eight lines instead of four. The old lines are now deleted before each plot; the test of the repeated run passes."
Bullet "The first test run also failed on the event markers because the test searched with a function that does not see hidden objects; the test was corrected, not the app."
Bullet "The first screenshot with the event table showed that the window is cut to about 750 pixels in height on this computer: the temperature plot was squeezed and the table was cut off. The layout was redesigned (event table in the bottom row, model label and agreement flag at the bottom right) and the screenshot, which first showed record 4 instead of the chosen record, was corrected and made again. Figure 4.22 of Step 39 no longer matched the app, so the report of Step 39 was rebuilt as version 2."
H1N "Decisions"
Bullet "D38: the model unchanged; events returned by run_transformer_simulation; playback and one diagnosis function; default file; checks."
H1N "Files produced"
Bullet "10_Dashboard_Client/DGADashboard.mlapp (updated), find_dga_row.m, verify_step40.m, tools/build_dashboard_mlapp.m, tools/DGADashboard_code.txt, code_manifest_step40.sha256"
Bullet "05_Simulink_Model/run_transformer_simulation.m (updated)"
Bullet "10_Dashboard_Client/results/step40_checks.csv, step40_event_run.csv"
Bullet "11_Results/figures/F4_22_dashboard_annotated.png (regenerated)"
Closing "40" 0 "Step 41 (MATLAB Agentic Toolkit): run the integrated system over every held-out record of role internal test or benchmark and log each diagnosis and its response time in 10_Dashboard_Client/logs/testbench_log.csv (Figure 4.20)." $global:Blocks["40"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_40_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_40_Report.docx") -Force
("SAVED Step_40_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber + "`n" + $_.ScriptStackTrace) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
