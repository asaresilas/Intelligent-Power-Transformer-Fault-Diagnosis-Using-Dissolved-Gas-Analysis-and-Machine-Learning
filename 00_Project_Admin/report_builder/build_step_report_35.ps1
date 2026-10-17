$ErrorActionPreference = "Stop"
# build_step_report_35.ps1 - Word report of roadmap Step 35 (verification against IEC 60076-7).
# Every number is read from 05_Simulink_Model/results (log, checks) and 11_Results/tables (Table 4.10); statements are throw-checked.
# Variable names start with k_ because the dot-sourced helper scripts also use short names.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report35_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8
$inv = [Globalization.CultureInfo]::InvariantCulture
function IsTrue($v) { $v -in @("1", "true", "True") }

$k_res = Join-Path $root "05_Simulink_Model\results"
$k_log = Get-Content (Join-Path $k_res "step35_verification_log_2026-10-13.txt") -Encoding UTF8
$k_chk = Import-Csv (Join-Path $k_res "step35_checks.csv")
$k_t410 = Import-Csv (Join-Path $root "11_Results\tables\T4_10_simulink_verification.csv")
$k_fig = Join-Path $root "11_Results\figures\F4_18_simulink_verification.png"
if ($k_chk.Count -ne 15) { throw "expected 15 checks" }
foreach ($c in $k_chk) { if (-not (IsTrue $c.passed)) { throw ("a Step 35 check failed: " + $c.check) } }
if (-not (Test-Path $k_fig)) { throw "figure missing" }
$txt = $k_log -join "`n"
function Grab([string]$pat, [int]$n = 0) { $m = [regex]::Matches($txt, $pat); if ($m.Count -le $n) { throw "log pattern not found: $pat" }; $m[$n] }
$m = Grab 'K\(24 h\) = ([0-9.]+); M = (\d+) logged model points'; $k_K1 = $m.Groups[1].Value; $k_M1 = $m.Groups[2].Value
$m = Grab 'K\(24 h\) = ([0-9.]+); M = (\d+) logged model points' 1; $k_K2 = $m.Groups[1].Value; $k_M2 = $m.Groups[2].Value
$m = Grab 'top-oil : e_max ([0-9.]+) K \(whole run ([0-9.]+)\).*final model ([0-9.]+)'; $k_o1 = $m.Groups[1].Value; $k_oil = $m.Groups[3].Value
$m = Grab 'top-oil : e_max ([0-9.]+) K \(whole run ([0-9.]+)\).*final model ([0-9.]+)' 1; $k_o2 = $m.Groups[1].Value
$m = Grab 'hot-spot: e_max ([0-9.]+) K \(whole run ([0-9.]+)\).*final model ([0-9.]+)'; $k_h1 = $m.Groups[1].Value; $k_hsWhole = $m.Groups[2].Value; $k_hs = $m.Groups[3].Value
$m = Grab 'hot-spot: e_max ([0-9.]+) K \(whole run ([0-9.]+)\).*final model ([0-9.]+)' 1; $k_h2 = $m.Groups[1].Value; $k_hs2 = $m.Groups[3].Value; $k_hsWhole2 = $m.Groups[2].Value
$m = Grab 'maximum at (\d+) s \(oil\) and (\d+) s \(hot-spot\); last time above 0.10 K: oil (\w+) s, hot-spot (\w+) s'; $k_hsAt = $m.Groups[2].Value; $k_oilLast = $m.Groups[3].Value; $k_hsLast = $m.Groups[4].Value
$m = Grab 'maximum at (\d+) s \(oil\) and (\d+) s \(hot-spot\); last time above 0.10 K: oil (\w+) s, hot-spot (\w+) s' 1; $k_hsLast2 = $m.Groups[4].Value; $k_oilLast2 = $m.Groups[3].Value
if ($k_oilLast -ne "NaN" -or $k_oilLast2 -ne "NaN" -or $k_hsLast2 -ne "NaN") { throw "start-up pattern changed: re-read the log" }
$m = Grab 'model ([0-9.]+) min, expected k11\*tau_o = ([0-9.]+) min'; $k_t63 = $m.Groups[1].Value; if ($m.Groups[2].Value -ne "75.000") { throw "expected 75.000" }
$m = Grab 'Baseline 3 Oct: .*Test 2 K ([0-9.]+) -> ([0-9.]+) \(now ([0-9.]+) -> ([0-9.]+)\)'; $k_K2a = $m.Groups[3].Value; $k_K2b = $m.Groups[4].Value
$k_log2 = Get-Content (Join-Path $root "04_MATLAB_Conventional\tests\test_log.txt") -Encoding utf8
$k_matlab = (($k_log2 | Where-Object { $_ -like "MATLAB:*" } | Select-Object -First 1) -replace "^MATLAB:\s*", "").Trim()
$global:S35 = @{ matlab = $k_matlab; completed = "13 October 2026"; nChecks = $k_chk.Count; M1 = $k_M1; M2 = $k_M2
  o1 = $k_o1; h1 = $k_h1; o2 = $k_o2; h2 = $k_h2; t63 = $k_t63; K1 = $k_K1; oil = $k_oil; hs = $k_hs; hs2 = $k_hs2
  hsWhole = $k_hsWhole; hsAt = $k_hsAt; hsLast = $k_hsLast
  checks = ("verify_step35.m: 15 of 15 checks PASS; e_max after 10 min 0.1 K limit: " + $k_o1 + " / " + $k_h1 + " K (Test 1), " + $k_o2 + " / " + $k_h2 + " K (Test 2); 63 % rise time " + $k_t63 + " min") }

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
. (Join-Path $sp "report_entries_35.ps1")
function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed) {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 2 (" + $completed + "; regenerated after the solver tolerance was tightened)")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "35" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "35" "Verify against IEC 60076-7" "Claude Code (this chat), MATLAB and Simulink through the MCP connection" $S35.completed
Summary ("The transformer operating model was compared with two independent solutions of the IEC 60076-7 temperature equations: a numerical solution and an exact formula. Two 24-hour tests were run: rated load from a cold start, and a load step from 0.6 to 1.2 per unit after 6 hours. After the first 10 minutes the largest difference is " + $k_o1 + " K (top oil) and " + $k_h1 + " K (hot spot) at rated load, and " + $k_o2 + " K and " + $k_h2 + " K in the load step, against the approved limit of 0.1 K. The top-oil 63.2 % rise time is " + $k_t63 + " minutes against the expected 75 minutes. All 15 checks pass and the 3 October baseline is reproduced. Over the whole run, including the first minutes, the largest hot-spot difference is " + $k_hsWhole + " K (rated-load test), also below the limit. The solver tolerance of the model (RelTol) was tightened from 1e-3 to 1e-4 during this step, because at 1e-3 the rated-load hot-spot difference was 0.104 K, just above the limit (see Problems and fixes). This is verification: it proves that the model solves the equations with its constants, not that the constants are those of IEC 60076-7:2018, which are still TO VERIFY.")
H1N "Purpose of this step"
Body "Before the model is used for scenarios, we must know that it does what its equations say. This step runs the model in two tests and compares its temperatures with calculations that do not use the Simscape model, and it produces Table 4.10 and Figure 4.18 of the thesis."
MethodSection "35"
H1N "What was used"
Bullet "Transformer_Operating_Model.slx as after Step 34 and params_transformer.m."
Bullet "The IEC 60076-7 equations as written in the MATLAB Build Guide (Section A3.2) and the Analysis Plan (Section 9, Equations 40 to 46)."
Bullet "The numbers of the 3 October reference build (verification_log_2026-10-03.txt) as a baseline."
Bullet "11_Results/figures/plot_style.csv for the colours of Figure 4.18."
H1N "What was done, step by step"
NumItem "1" "Fixed the test design, the measures and the extra criteria in the decision log (D33) before running anything."
NumItem "2" "Wrote verify_step35.m: it runs the two tests, solves reference A and calculates reference B, measures e_max and RMSE after 10 minutes, finds the 63.2 % rise time, runs 15 checks, writes Table 4.10, draws Figure 4.18 and saves the runs in the Simulation Data Inspector."
NumItem "3" "Ran it. All checks passed at the first run; the first figure had dark axes (see Problems and fixes), and the whole-run start-up difference was added to the log."
NumItem "4" "After Step 37 added the sampling-event subsystem the program was run again on the final model. The Test 1 hot-spot difference was then 0.104 K, above the 0.1 K limit, with the model physics unchanged. The cause was found to be the solver accuracy (RelTol 1e-3); the tolerance was set to 1e-4 (variable solver_reltol in params_transformer.m), the model was rebuilt, and all verification steps were repeated (D33 amendment)."
NumItem "5" "Wrote this version of the report (version 2) and updated the register, glossary, READMEs, CHANGELOG.md and SESSION_SUMMARY.md."
H1N "What we found"
H2 "Table 4.10 - Simulink verification"
$k_rows = @()
foreach ($r in $k_t410) {
  $v = [double]::Parse($r.value, $inv)
  $fmt = if ($r.unit -eq "degC") { "0.000" } elseif ($r.unit -eq "-") { "0.0000" } else { "0.0000" }
  $lim = if ($r.limit -eq "NaN") { "-" } else { ([double]::Parse($r.limit, $inv)).ToString("0.0000", $inv) }
  $pf = if ($r.passed -eq "yes") { "pass" } else { "" }
  $k_rows += , @($r.test, ($r.quantity + ": " + $r.measure), $v.ToString($fmt, $inv), $r.unit, $lim, $pf)
}
AddTable @("Test", "Quantity and measure", "Value", "Unit", "Limit", "Result") $k_rows @(70, 170, 50, 35, 50, 45)
Body ("'After 10 min' means the " + $k_M1 + " (Test 1) and " + $k_M2 + " (Test 2) logged model time points after 600 s (the references are evaluated at the model's own time points). 'Closed form B' is the exact formula for a constant load; the rise-time row gives the difference between the model's 63.2 % time (" + $k_t63 + " min) and k11 x tau_o = 75.000 min. The ageing-rate row is the largest relative difference between the model's ageing rate and the formula applied to the reference hot-spot temperature.")
H2 "Figure 4.18"
Caption "Figure 4.18  Verification of the Simulink thermal model: temperatures (upper panels) and model minus reference (lower panels) for the rated-load test and the load-step test"
Pic $k_fig 450
Body "The solid lines (model) lie on top of the dashed lines (IEC 60076-7 equations). The lower panels show the difference in kelvin; the dotted lines are the tolerance of 0.1 K. All differences are far below the tolerance; the largest occur in the first minutes after the start."
H2 "Start-up transient"
Body ("Over the whole run, the largest hot-spot difference in Test 1 is " + $k_hsWhole + " K, at " + $k_hsAt + " s; it never exceeds 0.1 K. In Test 2 the whole-run maximum is " + $k_hsWhole2 + " K. The top-oil difference never exceeds 0.1 K in either test. The approved rule (Equation 45) compares from 10 minutes onwards, as in the 3 October baseline; the whole-run values are reported because a reader of the figure will see the early difference. They are about two to three times the values after 10 minutes, which is what a start-up transient with a changing load factor produces.")
H2 "Baseline of 3 October"
AddTable @("Quantity", "3 October baseline", "This step") @(
  , @("Test 1: load factor K", "0.9839", $k_K1)
  , @("Test 1: final top-oil temperature (degC)", "78.638", $k_oil)
  , @("Test 1: final hot-spot temperature (degC)", "100.276", $k_hs)
  , @("Test 1: top-oil 63 % rise time (min)", "75.0", $k_t63)
  , @("Test 2: load factor before / after the step", "0.5960 / 1.1733", ($k_K2a + " / " + $k_K2b))
  , @("Test 2: final hot-spot temperature (degC)", "122.70", $k_hs2)
) @(230, 110, 110)
Body "The model of Step 33/34 therefore reproduces the verified reference build, as the structure check of Step 33 already showed."
H1N "Checks"
$k_rows = @(); foreach ($c in $k_chk) { $k_rows += , @($c.check, ([double]::Parse($c.value, $inv)).ToString("0.0000E+0", $inv), ([double]::Parse($c.limit, $inv)).ToString("0.0000", $inv), "PASS") }
AddTable @("Check (verify_step35.m)", "Value", "Limit", "Result") $k_rows @(260, 70, 60, 60)
H1N "Problems and fixes"
Bullet "The first version of Figure 4.18 had black axes, apparently because the default theme of MATLAB R2025b was applied to the invisible figure. The program now forces the light theme and a white axes colour; the figure was looked at again."
Bullet "After Step 37 the Test 1 hot-spot difference after 10 minutes was 0.104 K (limit 0.1 K) although the model had not changed. A first explanation (interpolation on a changed time grid) was wrong. Tests with other solver tolerances showed that the default RelTol 1e-3 leaves an error of about 0.1 K that depends on the solver steps; RelTol 1e-4 gives 0.013 K (run time about 63 s). The model now uses 1e-4. The first wording of the D33 amendment was corrected in the decision log."
Bullet "The first run did not log when the largest difference occurs; a start-up line was added to the log before this report was written."
H1N "Decisions"
Bullet "D33: two references (numerical and closed form), two tests, e_max and RMSE after 10 minutes, the 0.1 K limit, the rise-time and ageing-rate criteria (proposals), and the use of the model's measured K for the reference. Fixed before the program was run. Amended on 13 October 2026 after the Step 37 run: the references are evaluated at the model's own logged time points, and the solver tolerance of the model is 1e-4 (the cause of the 0.104 K result)."
H1N "Files produced"
Bullet "05_Simulink_Model/verify_step35.m, code_manifest_step35.sha256"
Bullet "05_Simulink_Model/results/step35_verification_log_2026-10-13.txt, step35_checks.csv, step35_sdi_session.mldatx"
Bullet "11_Results/tables/T4_10_simulink_verification.csv"
Bullet "11_Results/figures/F4_18_simulink_verification.png, .pdf and .csv (the plotted numbers)"
Closing "35" 0 "Step 36 (Simulink): write the approved operating scenarios in scenarios.m (constant rated load, a daily load cycle, a short overload), simulate each, log load, temperatures and ageing in the Simulation Data Inspector, and draw Figure 4.19." $global:Blocks["35"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_35_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_35_Report.docx") -Force
("SAVED Step_35_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber + "`n" + $_.ScriptStackTrace) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
