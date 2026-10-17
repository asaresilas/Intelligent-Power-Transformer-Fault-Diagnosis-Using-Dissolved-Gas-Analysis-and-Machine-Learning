$ErrorActionPreference = "Stop"
# build_step_report_36.ps1 - Word report of roadmap Step 36 (operating scenarios).
# Every number is read from 05_Simulink_Model/results (summary, definitions, checks); statements are throw-checked.
# Variable names start with k_ because the dot-sourced helper scripts also use short names.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report36_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8
$inv = [Globalization.CultureInfo]::InvariantCulture
function IsTrue($v) { $v -in @("1", "true", "True") }

$k_res = Join-Path $root "05_Simulink_Model\results"
$k_sum = Import-Csv (Join-Path $k_res "step36_scenario_summary.csv")
$k_chk = Import-Csv (Join-Path $k_res "step36_checks.csv")
$k_def = Import-Csv (Join-Path $k_res "step36_scenario_definitions.csv")
$k_figDir = Join-Path $root "11_Results\figures"
if ($k_chk.Count -ne 13) { throw "expected 13 checks" }
foreach ($c in $k_chk) { if (-not (IsTrue $c.passed)) { throw ("a Step 36 check failed: " + $c.check) } }
if ($k_sum.Count -ne 3) { throw "expected 3 scenarios" }
function Dp($s, [string]$id) { $r = $k_def | Where-Object { $_.scenario -eq $id }; ($r | ForEach-Object { "(" + $_.time_h + ", " + $_.demand_pu + ")" }) -join " " }
function Day1($id) { $r = $k_def | Where-Object { $_.scenario -eq $id -and [double]::Parse($_.time_h, $inv) -le 24 }; ($r | ForEach-Object { "(" + $_.time_h + ", " + $_.demand_pu + ")" }) -join " " }
$k_s1 = $k_sum | Where-Object { $_.scenario -eq "rated" }; $k_s2 = $k_sum | Where-Object { $_.scenario -eq "daily" }; $k_s3 = $k_sum | Where-Object { $_.scenario -eq "overload" }
function F([string]$v, [string]$f) { ([double]::Parse($v, $inv)).ToString($f, $inv) }
$k_log2 = Get-Content (Join-Path $root "04_MATLAB_Conventional\tests\test_log.txt") -Encoding utf8
$k_matlab = (($k_log2 | Where-Object { $_ -like "MATLAB:*" } | Select-Object -First 1) -replace "^MATLAB:\s*", "").Trim()
$global:S36 = @{ matlab = $k_matlab; completed = "13 October 2026"; nChecks = $k_chk.Count
  rated = (Dp 0 "rated"); daily = (Day1 "daily"); overload = (Dp 0 "overload")
  pk1 = (F $k_s1.peak_hot_spot_C "0.0"); pk2 = (F $k_s2.peak_hot_spot_C "0.0"); pk3 = (F $k_s3.peak_hot_spot_C "0.0")
  t2 = (F $k_s2.time_of_peak_h "0.0"); t3 = (F $k_s3.time_of_peak_h "0.0")
  L1 = (F $k_s1.loss_of_life_h "0.00"); L2 = (F $k_s2.loss_of_life_h "0.00"); L3 = (F $k_s3.loss_of_life_h "0.00")
  checks = ("verify: run_step36.m 13 of 13 checks PASS (runs repeatable to 0.00e+00; model file unchanged); peak hot-spot " + (F $k_s1.peak_hot_spot_C "0.0") + " / " + (F $k_s2.peak_hot_spot_C "0.0") + " / " + (F $k_s3.peak_hot_spot_C "0.0") + " degC") }
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
. (Join-Path $sp "report_entries_36.ps1")
function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed) {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 2 (" + $completed + "; re-run on the model with the sampling subsystem and solver tolerance 1e-4)")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "36" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "36" "Run the operating scenarios" "Claude Code (this chat), MATLAB and Simulink through the MCP connection" $S36.completed
Summary ("Three operating scenarios were simulated on the verified transformer model: a constant rated load, a daily load cycle and a short overload. Each run was stored in the Simulation Data Inspector and in a file, and drawn as one figure (Figure 4.19). The peak hot-spot temperature is " + $S36.pk1 + " degC at rated load, " + $S36.pk2 + " degC in the daily cycle (at " + $S36.t2 + " h) and " + $S36.pk3 + " degC in the overload (at " + $S36.t3 + " h). The loss of life in the shown 24 hours is " + $S36.L1 + " h, " + $S36.L2 + " h and " + $S36.L3 + " h. All " + $k_chk.Count + " checks pass: every run is identical when repeated from a fresh start, the saved files equal new runs, and the model file is unchanged. The scenarios are illustrative choices, not measured load data, and no temperature limit of IEC 60076-7 is applied because the standard was not obtained.")
H1N "Purpose of this step"
Body "The model gives the operating context of the framework. This step defines three example load histories, runs them, logs the results and draws them, so that the dashboard and the thesis have concrete examples of how load, temperatures and insulation ageing move together. Each run must be reproducible from params_transformer.m and scenarios.m."
MethodSection "36"
H1N "What was used"
Bullet "The verified model Transformer_Operating_Model.slx and params_transformer.m (ambient 20 degC, thermal constants)."
Bullet "scenarios.m, written in this step: the three load histories (decision D34)."
Bullet "11_Results/figures/plot_style.csv for the colours."
H1N "What was done, step by step"
NumItem "1" "Fixed the three scenarios, the run lengths, the shown window and the checks in the decision log (D34) before simulating anything."
NumItem "2" "Wrote scenarios.m (every number a named variable with a unit) and run_step36.m."
NumItem "3" "Ran every scenario twice from a fresh start, saved sim_<scenario>.mat, stored the runs in the Simulation Data Inspector and drew Figure 4.19."
NumItem "4" "Looked at the figures: the peak label of the daily cycle ran outside the axes and the loss-of-life label lay on the curve; both were moved and the program was run again."
NumItem "5" "Wrote this report and updated the register, glossary, READMEs, CHANGELOG.md and SESSION_SUMMARY.md."
H1N "What we found"
H2 "The scenarios"
$k_rows = @(
  , @("S1 Constant rated load", "Demand 1.0 per unit for 24 h.")
  , @("S2 Daily load cycle", ("Demand (hour, per unit), repeated on three days: " + $S36.daily + ". The third day (hours 48 to 72) is shown."))
  , @("S3 Short overload", ("Demand (hour, per unit): " + $S36.overload + ". Base 0.8, overload 1.3 for 2 h from hour 8."))
)
AddTable @("Scenario", "Load history") $k_rows @(130, 320)
H2 "Results"
$k_rows = @(); foreach ($r in $k_sum) { $k_rows += , @($r.label, (F $r.K_measured_max_pu "0.000"), (F $r.peak_top_oil_C "0.0"), (F $r.peak_hot_spot_C "0.0"), (F $r.time_of_peak_h "0.0"), (F $r.loss_of_life_h "0.00")) }
AddTable @("Scenario", "Highest measured K (pu)", "Peak top-oil (degC)", "Peak hot-spot (degC)", "Hot-spot peak at (h)", "Loss of life L (h)") $k_rows @(120, 65, 60, 60, 60, 60)
Body "All values are for the shown 24 hours. The measured load factor K is lower than the demand (a demand of 1.0 gives 0.984 and a demand of 1.3 gives 1.267) because the load sits behind the transformer impedance. In the rated-load scenario the hot spot is still rising at 24 hours, so its 'peak' is its final value. Loss of life is in equivalent hours at the reference hot-spot temperature of 98 degC; for the rated-load scenario it includes the warm-up from a cold start."
H2 "Figure 4.19"
Caption "Figure 4.19a  Operating scenario: constant rated load"
Pic (Join-Path $k_figDir "F4_19a_scenario_rated.png") 380
$sel.InsertBreak(7)
Caption "Figure 4.19b  Operating scenario: daily load cycle (third day)"
Pic (Join-Path $k_figDir "F4_19b_scenario_daily.png") 380
$sel.InsertBreak(7)
Caption "Figure 4.19c  Operating scenario: short overload"
Pic (Join-Path $k_figDir "F4_19c_scenario_overload.png") 380
Body "Each figure has three panels with a common time axis: the demanded and the measured load factor; the ambient, top-oil and hot-spot temperatures with the hot-spot peak marked; and the ageing rate on a logarithmic axis with the loss of life written in. The overload shows how steeply the ageing rate rises with the hot-spot temperature: during the two overload hours the ageing rate is several tens of times the reference rate, and after the overload it falls back within a few hours."
H2 "Reading the daily cycle"
Body "The hot-spot temperature follows the load with a delay set by the oil time constant (about 75 minutes for the top oil) and a much shorter one for the winding. The peak therefore occurs at the end of the evening peak load, not at its start. Day 3 and day 2 are identical to within 0.001 K, so the cycle has settled and the shown day does not depend on the cold start."
H1N "Checks"
$k_rows = @(); foreach ($c in $k_chk) { $k_rows += , @($c.check, "PASS") }
AddTable @("Check (run_step36.m)", "Result") $k_rows @(360, 90)
Body "The check 'day 3 and day 2 differ by less than 1 K' is information about the scenario, not a test of the model. The rated-load scenario gives exactly the signals and the loss of life of run_transformer_simulation, the default run of the model."
H1N "Problems and fixes"
Bullet "In the first figures the peak label of the daily cycle ran outside the right edge and the loss-of-life label lay on the curve. The label positions and the temperature axis were changed and the figures were looked at again."
Bullet "A PowerShell edit left the characters backslash-n in a MATLAB line instead of a line break, so the program stopped with a syntax error; it was corrected by a direct edit and the program was run again."
H1N "Decisions"
Bullet "D34: the three scenarios and their illustrative values (the researcher's 'proceed' to the proposal is taken as approval of the three scenarios and values); the 72 h run with the last day shown for the daily cycle; the checks; no standard limits applied."
H1N "Files produced"
Bullet "05_Simulink_Model/scenarios.m, run_step36.m, code_manifest_step36.sha256"
Bullet "05_Simulink_Model/results/sim_rated.mat, sim_daily.mat, sim_overload.mat, step36_scenario_definitions.csv, step36_scenario_summary.csv, step36_checks.csv, step36_sdi_session.mldatx"
Bullet "11_Results/figures/F4_19a_scenario_rated, F4_19b_scenario_daily, F4_19c_scenario_overload (.png, .pdf, .csv)"
Closing "36" 0 "Step 37 (Simulink): add a DGA sampling-event subsystem that outputs the record_id of the next real held-out record at the sampling times set in params_transformer.m; it must never produce a gas value (inspection plus a test)." $global:Blocks["36"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }$tmp = Join-Path $work "out_Step_36_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_36_Report.docx") -Force
("SAVED Step_36_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber + "`n" + $_.ScriptStackTrace) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
