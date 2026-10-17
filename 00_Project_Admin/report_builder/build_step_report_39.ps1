$ErrorActionPreference = "Stop"
# build_step_report_39.ps1 - Word report of roadmap Step 39 (App Designer dashboard).
# Every number is read from 10_Dashboard_Client/results and 11_Results/figures; statements are throw-checked.
# Variable names start with k_ because the dot-sourced helper scripts also use short names.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report39_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8
$inv = [Globalization.CultureInfo]::InvariantCulture
function IsTrue($v) { $v -in @("1", "true", "True") }

$k_res = Join-Path $root "10_Dashboard_Client\results"
$k_chk = Import-Csv (Join-Path $k_res "step39_checks.csv")
$k_three = Import-Csv (Join-Path $k_res "step39_three_records.csv")
$k_held = Import-Csv (Join-Path $k_res "step39_held_out_comparison.csv")
$k_leg = Import-Csv (Join-Path $root "11_Results\figures\F4_22_dashboard_annotated_legend.csv")
$k_fig = Join-Path $root "11_Results\figures\F4_22_dashboard_annotated.png"
if ($k_chk.Count -ne 19) { throw "expected 19 checks" }
foreach ($c in $k_chk) { if (-not (IsTrue $c.passed)) { throw ("a Step 39 check failed: " + $c.check) } }
if ($k_three.Count -ne 3) { throw "expected 3 records" }
if ($k_held.Count -ne 388) { throw "expected 388 held-out records" }
if (-not (Test-Path $k_fig)) { throw "figure missing" }
$k_pd = ($k_held | ForEach-Object { [double]::Parse($_.max_probability_difference, $inv) } | Measure-Object -Maximum).Maximum
foreach ($col in "rogers_equal", "iec_equal", "duval_equal") { if (@($k_held | Where-Object { -not (IsTrue $_.$col) }).Count -ne 0) { throw "held-out mismatch in $col" } }
foreach ($h in $k_held) { if ($h.ml_class_app -ne $h.ml_class_offline) { throw "ML class mismatch" } }
$k_lat = ($k_held | ForEach-Object { [double]::Parse($_.latency_s, $inv) } | Sort-Object)[194]   # median of 388 (the 195th value)
$k_log2 = Get-Content (Join-Path $root "04_MATLAB_Conventional\tests\test_log.txt") -Encoding utf8
$k_matlab = (($k_log2 | Where-Object { $_ -like "MATLAB:*" } | Select-Object -First 1) -replace "^MATLAB:\s*", "").Trim()
$k_rows = ($k_three | ForEach-Object { $_.row }) -join ", "
$global:S39 = @{ matlab = $k_matlab; completed = "13 October 2026"; nChecks = $k_chk.Count; rows = $k_rows; nHeld = $k_held.Count; pdiff = $k_pd.ToString("0.0e+0", $inv)
  checks = ("verify_step39.m: 19 of 19 checks PASS; 3 known records and all 388 held-out records equal the offline results (largest probability difference " + $k_pd.ToString("0.0e+0", $inv) + ")") }
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
. (Join-Path $sp "report_entries_39.ps1")
function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed) {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 2 (" + $completed + "; layout and Figure 4.22 updated in Step 40)")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "39" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "39" "Build the App Designer dashboard" "Claude Code (this chat), MATLAB through the MCP connection" $S39.completed
Summary ("The engineer's dashboard, DGADashboard.mlapp, was built. It loads a measured record, computes the Rogers, IEC 60599 and Duval Triangle 1 diagnoses in MATLAB, asks the FastAPI service of Step 38 for the machine-learning class and probabilities, draws the sample in the Duval Triangle, shows an agreement lamp and shows the simulated operating temperatures as context. The roadmap check was passed: three known records (one per fault family) give the same answers as the offline results, and so do all " + $k_held.Count + " held-out records (largest probability difference " + $S39.pdiff + "). All " + $k_chk.Count + " checks pass, including the cases where the service is not reachable or the gas values are invalid: the app shows a message and does not stop. The file was written with an internal MathWorks serializer and should be opened once in App Designer.")
H1N "Purpose of this step"
Body "The dashboard is the engineer's screen of the framework (Objective 4). It must show the conventional and the machine-learning diagnoses side by side for the same measured record, and it must give the same answers as the offline results, because the thesis compares those answers."
MethodSection "39"
H1N "What was used"
Bullet "MATLAB_Build_Guide Part C (components C2, callbacks C4) and the programmatic reference DGADashboard_reference.m."
Bullet "The FastAPI service of Step 38 and its description 09_API_FastAPI/openapi.json (POST /diagnose)."
Bullet "The conventional functions of 04_MATLAB_Conventional, the Duval zones of 02_Standards, and the Simulink model of Steps 33 to 37 (run_transformer_simulation)."
Bullet "The offline results to compare with: 11_Results/conventional/conventional_predictions.csv and 11_Results/ml/ml_predictions.csv."
H1N "What was done, step by step"
NumItem "1" "Fixed the design in the decision log (D37) before building: components, agreement rule, how the three records are chosen, how failures are shown, how the .mlapp is produced, Figure 4.22."
NumItem "2" "Wrote the helper functions: ml_diagnose.m (webwrite client, never stops), dga_agreement.m (agreement rule), and extended load_dga_record.m (record_id, equipment_type)."
NumItem "3" "Wrote the app: component list and callbacks in tools/build_dashboard_mlapp.m and tools/DGADashboard_code.txt; produced DGADashboard.mlapp with the serializer; read it back with App Designer's reader and ran it from the file."
NumItem "4" "Wrote verify_step39.m (19 checks) and ran it with the service running."
NumItem "5" "Produced Figure 4.22. The first screenshot showed that the results table was too short (the ML row was hidden behind a scroll bar) and that some labels covered text; the layout and the labels were corrected and the checks were run again."
NumItem "6" "Wrote this report and updated the register, glossary, READMEs, CHANGELOG.md and SESSION_SUMMARY.md."
H1N "What we found"
H2 "The three known records"
$k_rows2 = @(); foreach ($r in $k_three) { $k_rows2 += , @($r.row, $r.record_id, $r.family, $r.true_class, $r.rogers_iec_duval, $r.ml_class, $r.agreement) }
AddTable @("Row", "Record", "Family", "True class", "Rogers / IEC / Duval", "ML", "Lamp") $k_rows2 @(30, 85, 90, 45, 100, 35, 45)
Body ("Each record is the first held-out, in-scope record in file order of its class (decision D37). The answers shown in the app were taken from the Diagnose button and equal the offline results; the ML probabilities differ from the offline file by at most " + $S39.pdiff + ". The record of the thermal family has the true class T3, but both the conventional methods and the model give T2: the check is identity with the offline results, not correctness.")
H2 "All held-out records"
Body ("The same functions that the Diagnose button calls (load_dga_record, conventional_diagnosis, ml_diagnose) were applied to all " + $k_held.Count + " held-out records: the three conventional answers, the ML class and the seven probabilities equal the offline results in every case (" + $k_held.Count + " of " + $k_held.Count + "). The median time of a service call was " + ($k_lat * 1000).ToString("0", $inv) + " ms; this is preliminary, the formal response time is measured in Step 42.")
H2 "Figure 4.22"
Caption "Figure 4.22  The diagnostic dashboard after a simulation run and the diagnosis of record IECTC10_0001 (annotated)"
Pic $k_fig 450
$k_rows3 = @(); foreach ($l in $k_leg) { $k_rows3 += , @($l.number, $l.tag, $l.shows) }
AddTable @("No.", "Component", "What it shows") $k_rows3 @(30, 110, 310)
H1N "Checks"
$k_rows = @(); foreach ($c in $k_chk) { $k_rows += , @($c.check, "PASS") }
AddTable @("Check (verify_step39.m)", "Result") $k_rows @(360, 90)
H1N "Problems and fixes"
Bullet "App Designer cannot be driven from code, so the .mlapp was written with an internal serializer. A first file lost the component names because the helper used by MATLAB at run time marks them as transient; the names are now added as App Designer adds them, and the file was read back to show that all 20 components keep their names, code and callbacks."
Bullet "The first screenshot of the app showed only two of the four rows of the results table (the ML row was hidden) and numbered labels that covered text. The row heights of the layout were changed and the labels moved; the checks were run again on the final file."
Bullet "In Step 40 the layout was made compact (the window is cut to about 750 pixels in height on this computer) and an event table was added; Figure 4.22 and its legend were made again, and the agreement text was shortened to fit. The 19 checks of this step were run again on the final file and pass."
Bullet "A first version of the test compared an empty text string with isempty, which is false for strings; the test now sets the property empty."
H1N "Decisions"
Bullet "D37: the components, the agreement rule (D1/D2 agrees with D1 or D2; DT and ND never agree), the rule for the three records, the status texts for failures, the production of the .mlapp, and Figure 4.22."
H1N "Files produced"
Bullet "10_Dashboard_Client/DGADashboard.mlapp, dga_agreement.m, ml_diagnose.m, load_dga_record.m, verify_step39.m, tools/build_dashboard_mlapp.m, tools/DGADashboard_code.txt, tools/make_figure_4_22.m, code_manifest_step39.sha256"
Bullet "10_Dashboard_Client/results/step39_checks.csv, step39_three_records.csv, step39_held_out_comparison.csv"
Bullet "11_Results/figures/F4_22_dashboard_annotated.png, .pdf, F4_22_dashboard_annotated_legend.csv, F4_22_dashboard_raw.png"
Closing "39" 0 "Step 40 (Simulink Agentic Toolkit): let the dashboard run the Simulink model with a Run Simulation button and use the sampling events of SS8 to trigger the diagnosis of the next record." $global:Blocks["39"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_39_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_39_Report.docx") -Force
("SAVED Step_39_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber + "`n" + $_.ScriptStackTrace) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
