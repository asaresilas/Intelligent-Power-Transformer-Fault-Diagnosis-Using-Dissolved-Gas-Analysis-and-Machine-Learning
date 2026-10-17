$ErrorActionPreference = "Stop"
# build_step_report_44.ps1 - Word report "Dashboard redesign: verdict, scenarios, sample sets, record picker" (update of Steps 39-40-43, 17 Oct 2026, D43).
# Numbers come from 10_Dashboard_Client/results (step44_checks.csv, dashboard_verdict_summary.csv, step44_mixed_run.csv); statements are throw-checked.
# Variable names start with k_ because the dot-sourced helper scripts also use short names. ASCII only.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report44_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8
function IsTrue($v) { $v -in @("1", "true", "True") }

$k_res = Join-Path $root "10_Dashboard_Client\results"
$k_chk = Import-Csv (Join-Path $k_res "step44_checks.csv")
if ($k_chk.Count -ne 18) { throw "expected 18 checks" }
foreach ($c in $k_chk) { if (-not (IsTrue $c.passed)) { throw ("a check failed: " + $c.check) } }
$k_sum = Import-Csv (Join-Path $k_res "dashboard_verdict_summary.csv")
function SumVal($name) { [int](($k_sum | Where-Object { $_.item -eq $name }).value) }
$k_known = SumVal "known faulty"; $k_called = SumVal "faulty records called fault"; $k_healthy = SumVal "faulty records called healthy"
$k_normal = SumVal "known Normal"; $k_normalok = SumVal "Normal records called healthy"; $k_fk = SumVal "fault verdict with known class"; $k_right = SumVal "fault verdict with the right class"; $k_fam = SumVal "fault verdict, family right"
if ($k_known -ne 346 -or $k_called -ne 242 -or $k_fk -ne 242 -or $k_right -ne 217 -or $k_fam -ne 240) { throw "verdict summary differs from the text" }
$k_rest = $k_known - $k_called - $k_healthy
$k_t43 = Import-Csv (Join-Path $k_res "step43_checks.csv")
if ($k_t43.Count -ne 23) { throw "expected 23 checks of step 43" }
foreach ($c in $k_t43) { if (-not (IsTrue $c.passed)) { throw ("a check of step 43 failed: " + $c.check) } }
$k_shot = Join-Path $root "11_Results\figures\F4_22_dashboard_annotated.png"
$k_man = Join-Path $root "10_Dashboard_Client\code_manifest_redesign_2026-10-17.sha256"
foreach ($f in @($k_shot, $k_man)) { if (-not (Test-Path $f)) { throw ("missing " + $f) } }
$k_matlab = ((Get-Content (Join-Path $root "04_MATLAB_Conventional\tests\test_log.txt") -Encoding utf8 | Where-Object { $_ -like "MATLAB:*" } | Select-Object -First 1) -replace "^MATLAB:\s*", "").Trim()
$global:S43 = @{ matlab = $k_matlab; completed = "17 October 2026"; n = $k_chk.Count }

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
$global:Methods["44R"] = @{
  Approach = @(
    "The researcher looked at the dashboard and said that it showed only numbers: the comparison between the methods was not visible, neither the fault state nor the healthy state was visible, there was no interpretation, and the output was always the same. The cause was measured first, from the saved test-bench log of Step 41: the first version always ran the constant rated-load scenario and always took the first four held-out records, and all four are true PD records, so the ML answer was PD every time; the thesis test bench, in contrast, ran all 388 records and produced all seven classes.",
    "The screen was then redesigned so that the answer comes first and the evidence second, in the order of the international procedure (IEC 60599 and IEEE Std C57.104-2008): compare each gas with its typical value; if all five gases are at or below the typical values the transformer is healthy; otherwise read the fault type with the three classical methods and the ML model, compare them, and give one verdict with a recommended action. The verdict rule is a vote: each of the four methods gives one vote, the IEC dual answer D1/D2 votes for both D1 and D2, DT and ND give no vote, and the class with the most votes is the verdict when it has at least two votes and no tie; otherwise the banner says CHECK.",
    "Variety was added in two ways, as the researcher asked for both: a choice of operating condition (three scenarios of Step 36) and of sample set (a mixed set with a healthy sample and one record of each fault type, a random set, and the first four records), and a record picker with a fault-type list. The sampling times and the stop time are passed to the unchanged Simulink model as values of the run; the record that belongs to each sampling event is looked up outside the model, so the model still holds no gas value.",
    "Last, the new logic was tested on its own (10 tests, all 388 held-out records), the whole app was tested through its buttons (18 checks), and the older checks of Steps 39, 40 and 43 were run again. The first run of verify_step43 after the redesign found two changes of behaviour of the Step 40 run (see Problems and fixes); they were repaired and the full verification was repeated."
    )
  Why = @(
    "A viewer needs the conclusion before the numbers. Putting the verdict in a coloured banner, the four answers on four cards with one word each (AGREES, DIFFERS), and a table with one row per sample makes the comparison of the methods visible at a glance.",
    "A vote is a simple rule that can be explained in one sentence and that uses no new threshold. It was chosen over a trained combination of the four answers because that would be a new classifier that would need its own validation. The rule is stated as a display rule, not a result of the study.",
    "The healthy state is exactly the normality gate that the study already used (decision D11, typical values of IEC 60599 Annex A). The screen therefore does not contradict the thesis tables. The gate lets some faults with very low gas levels pass as healthy; the report and the thesis say so.",
    "Choosing the sample from a fixed seed that grows after each press gives variety and still lets a result be reproduced. The 'first four' set is kept so that the checks of Steps 40 and 43 still apply unchanged."
    )
  Settings = @(
    @("Scenarios", "scenarios.m of Step 36 (constant rated load 24 h; daily cycle 3 days with the last day shown; short overload 24 h)"),
    @("Sampling times", "4 samples: 6, 12, 18, 22 h; other numbers n: n equal steps of 24/(n+1) h (7 samples: 3, 6, ... 21 h); inside the shown 24 h"),
    @("Mixed set", "one held-out record (data_role not development) of each known class Normal, PD, D1, D2, T1, T2, T3; random pick with seed 1, 2, 3 ... (seed + 1 after each press)"),
    @("Verdict rule", "one vote per method; D1/D2 votes for D1 and D2; DT, ND and a missing ML answer give no vote; at least 2 votes and no tie, otherwise CHECK"),
    @("Typical values", "IEC 60599:1999/AMD1:2007 Table A.2, read from 02_Standards/iec_typical_values.csv through load_standards (no number typed in the new code)"),
    @("Window", "1380 x 740 pixels"),
    @("Checks", ("verify_step44.m: " + $k_chk.Count + " checks; test_dashboard_verdict.m: 10 tests; verify_step43.m: 23 checks (includes verify_step39 and verify_step40)")),
    @("Software", ("MATLAB " + $k_matlab + "; App Designer file written by the internal serializer from tools/dashboard_components.m and tools/DGADashboard_code.txt")))
  Eqs = @()
  Tools = @("10_Dashboard_Client/dashboard_verdict.m, dashboard_samples.m, sim_window.m, dashboard_explain.m, test_dashboard_verdict.m, verify_step44.m",
            "10_Dashboard_Client/tools/dashboard_components.m, DGADashboard_code.txt, build_dashboard_mlapp.m, make_figure_4_22.m",
            "05_Simulink_Model/run_transformer_simulation.m (optional second argument opts)")
  Refs = @("SW2", "SW6")
}
$global:Closings["44R"] = @{
  Achieved = @(
    "The screen now gives the answer first: a green HEALTHY, red FAULT (with the type) or amber WATCH / CHECK banner with the reason and the recommended action, and four method cards that say AGREES or DIFFERS.",
    "The sample table shows, for every sample of a run, the known label, the answers of Rogers, IEC 60599, Duval and ML, the number of agreeing classical methods and the verdict: the comparison of the methods is visible.",
    "Variety: three operating conditions, three sample sets (the mixed set shows a healthy sample and every fault type in one run) and a record picker by fault type. A second press of the mixed set gives a different set.",
    "The tab 'Step by step' follows the order of IEC 60599 / IEEE C57.104 with the numbers of the sample; the tab 'Explanation in words' keeps the plain-language text.",
    ("All " + $k_chk.Count + " checks of verify_step44 pass; verify_step43 passes 23 of 23 (including the 19 checks of Step 39 and the 13 of Step 40); the 10 tests of the verdict logic pass; Python 154 tests and MATLAB 93 tests pass."),
    ("Descriptive result on the 388 held-out records: of " + $k_known + " records with a known fault the verdict was FAULT for " + $k_called + ", HEALTHY for " + $k_healthy + " and WATCH or CHECK for " + $k_rest + "; when the verdict was FAULT the exact type was right for " + $k_right + " of " + $k_fk + " and the right family for " + $k_fam + "."))
  Record = @(
    @("Step", "Update of Steps 39, 40 and 43: dashboard redesign (decision D43)"), @("Environment", "Claude Code (this chat) through the MATLAB MCP connection and batch MATLAB"),
    @("Completed", "17 October 2026"), @("Status", "Done (D43 proposed, to be confirmed by the researcher)"),
    @("Main inputs", "DGADashboard.mlapp of D42; scenarios.m; dga_master.csv; testbench_log.csv; the FastAPI service of Step 38"),
    @("Main outputs", "DGADashboard.mlapp (rebuilt), dashboard_verdict.m, dashboard_samples.m, sim_window.m, dashboard_explain.m, verify_step44.m, test_dashboard_verdict.m, results/step44_*.csv and screens, results/dashboard_verdict_*.csv, Figure 8.6 of the thesis"),
    @("Checks", ("verify_step44.m: " + $k_chk.Count + " of " + $k_chk.Count + " PASS; verify_step43.m: 23 of 23 PASS")),
    @("Decisions", "D43"))
  Helps = @(
    "The dashboard can now be shown to the supervisor with a healthy sample and every fault type in one run, and each result is explained in words and by the standard procedure.",
    "Chapter 8 of the thesis (Thesis_Draft_v3.docx) describes the new screen and gives the descriptive result of the verdict; the plain-language document Project_Explained_Simply.docx explains the whole project.")
  Open = @(
    "D43 is proposed and needs the researcher's confirmation; the vote rule is a display rule, not a validated classifier.",
    ("The typical-value check lets " + $k_healthy + " faults with very low gas levels pass as HEALTHY (typical values are not fault limits, IEC 60599 Annex A)."),
    "Not tested on a second computer; the screen was designed for a 1380 x 740 pixel window.",
    "The numbers in the sample table are shown with four decimals (a limit of the App Designer table); they are not rounded in the data.",
    "The recommended actions in the banner are general engineering practice, not requirements of IEC 60599 (TO VERIFY against the utility's own procedure).",
    "No repository licence has been chosen; the IEEE DataPort raw files are not part of the repository copy (terms TO VERIFY).")
  Exclude = @()
}
$global:StepSources["44R"] = @("DF90", "DF91", "DF92", "DF71", "DF74", "SW2", "SW6")
function ReportHeader44([string]$name, [string]$env, [string]$completed) {
  $global:sec = 0; $global:eqn = 0
  Title "Dashboard Update Report" 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "44R" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader44 "Dashboard redesign: verdict, scenarios, sample sets and record picker (update of Steps 39, 40 and 43)" "Claude Code (this chat), MATLAB through the MCP connection" $S43.completed
Summary ("The dashboard now answers first and explains second. A coloured banner says whether the sample is healthy (green), has a fault of a named type (red), or needs a closer look (amber); four cards show the answers of Rogers, IEC 60599, Duval and the ML model with the word AGREES or DIFFERS; a table lists every sample of a run with all four answers and the verdict; and a tab shows the standard procedure step by step with the numbers of the sample. The demonstration is no longer the same four PD records: three operating conditions and three sample sets can be chosen, and the mixed set shows a healthy sample and every fault type in one run. A record picker chooses a record of a given fault type. All " + $k_chk.Count + " new checks pass, the older checks of Steps 39, 40 and 43 pass (23 of 23), and on the 388 held-out records the verdict called " + $k_called + " of " + $k_known + " known faults a fault, with the exact type right in " + $k_right + " of " + $k_fk + " cases.")
H1N "Purpose of this update"
Body "The researcher reported that the app showed only numbers that could not be used: the comparison between Rogers, IEC 60599, Duval and ML was not visible, the fault and the healthy state were not visible, and there was no interpretation. The researcher asked for both varied demonstration records and a record picker, for a step-by-step layout that follows the internationally approved procedure, and for the whole project to be explained in simple terms. This report describes the cause, the redesign and its checks; the plain-language explanation is the document Project_Explained_Simply.docx."
MethodSection "44R"
H1N "Why the output was always the same (measured)"
AddTable @("What was found", "Result") @(
  , @("Scenario of every run of the first version", "constant rated load, 24 h")
  , @("Records of every run", "IECTC10_0001 to IECTC10_0004 (the first four held-out records); all four have the true class PD")
  , @("ML answer at these records", "PD every time")
  , @("Rogers answer at these records", "ND (no diagnosis) at all four")
  , @("The thesis test bench (Step 41)", "ran all 388 held-out records; every one of the seven classes appears among the ML answers")
) @(210, 240)
H1N "What was done, step by step"
NumItem "1" "Measured why the output was static (table above) and checked that the model can take more than four sampling times and other load profiles as run values: seven sampling times worked with the unchanged model."
NumItem "2" "Backed up the app, the explanation text and the checks to 10_Dashboard_Client/tools/backup_before_redesign/."
NumItem "3" "Wrote the verdict logic (dashboard_verdict.m), the sample chooser (dashboard_samples.m) and the window helper for the daily cycle (sim_window.m), and tested them on all 388 held-out records without the ML service (test_dashboard_verdict.m: 10 of 10)."
NumItem "4" "Extended run_transformer_simulation.m with optional run values (stop time, sampling times) and wrote the new component list and callbacks; rebuilt DGADashboard.mlapp (75 components)."
NumItem "5" "Wrote verify_step44.m and ran it; fixed the layout after looking at the screens (the sample table cut off rows; a label overlapped a bar)."
NumItem "6" "Ran the older checks again (verify_step43 including 39 and 40), repaired two changes of behaviour, and repeated the full verification."
NumItem "7" "Regenerated the annotated screenshot (Figure 8.6), rewrote the dashboard section of thesis Chapter 8 (Thesis_Draft_v3.docx), updated the how-to README, the dashboard README, the register (DF90-DF93), decision D43, CHANGELOG.md and SESSION_SUMMARY.md."
H1N "The new screen"
Caption "Figure  The redesigned dashboard after a simulated day with seven oil samples (program screenshot with numbered parts)"
Pic $k_shot 450
AddTable @("Part", "What it shows") @(
  , @("1 and 2 (left)", "Operating condition (rated, daily cycle, overload) and the sample set (mixed, random, first four)")
  , @("3 and 4 (left)", "Run simulation + diagnose; pick a random record of a chosen fault type")
  , @("5 Banner", "HEALTHY (green), FAULT with type (red), WATCH or CHECK (amber); the reason; what to do")
  , @("6 and 7 Cards", "Rogers, IEC 60599, Duval, ML: answer, meaning, AGREES / DIFFERS / NO ANSWER; known label of the record")
  , @("8 Sample table", "One row per sample: known label, four answers, agreement count, verdict, hot-spot temperature")
  , @("9, 10, 11 Charts", "Gas against typical value (log scale), Duval Triangle with the sample, ML probabilities")
  , @("12 Tabs", "Charts; Step by step; Explanation in words; Tables; Simulation (operating condition)")
) @(110, 340)
H1N "How the verdict is made"
AddTable @("Situation", "Banner") @(
  , @("All five gases at or below the IEC 60599 typical values and ML does not name a fault", "HEALTHY (green)")
  , @("All five gases at or below the typical values, but the ML model names a fault", "WATCH (amber)")
  , @("At least one gas above typical and one class has at least two votes (and no tie): a fault class", "FAULT with the type (red); strong if all voting methods agree, majority if more than half")
  , @("At least one gas above typical but the methods agree on Normal", "WATCH (amber)")
  , @("At least one gas above typical and no class has two votes", "CHECK (amber)")
) @(260, 190)
Body "Votes: Rogers, IEC 60599, Duval and ML give one vote each. D1/D2 (IEC) votes for D1 and for D2. DT (Duval), ND (no diagnosis) and a missing ML answer give no vote. If the ML service is not reachable the verdict is made from the three classical methods (three voters)."
H1N "How well the verdict agrees with the known classes (descriptive)"
Body ("The verdict was computed for all 388 held-out records using the ML answers saved by the test bench (a descriptive check; it is not a new statistical test and the verdict rule is not a validated classifier).")
AddTable @("Question", "Result") @(
  , @("Records with a known fault", "$k_known")
  , @("Verdict FAULT", "$k_called")
  , @("Verdict HEALTHY (faults with very low gas levels that pass the typical-value check)", "$k_healthy")
  , @("Verdict WATCH or CHECK", "$k_rest")
  , @("Known normal records called HEALTHY", "$k_normalok of $k_normal")
  , @("Fault verdicts with a known class: exact type right", "$k_right of $k_fk")
  , @("Fault verdicts with a known class: right family (electrical or thermal)", "$k_fam of $k_fk")
) @(330, 120)
H1N "Checks"
$k_rows = @(); foreach ($c in $k_chk) { $k_rows += , @($c.check, "PASS") }
AddTable @("Check (verify_step44.m)", "Result") $k_rows @(360, 90)
Body "In addition: test_dashboard_verdict.m (10 of 10), verify_step43.m (23 of 23, which includes verify_step39 with 19 and verify_step40 with 13 checks), Python tests 154 passed, MATLAB tests 93 passed, and the Simulink checks of Steps 33, 35 and 37 (9, 15 and 10 checks) pass again on the unchanged model (file checksum identical to the one recorded on 13 October 2026)."
H1N "Problems and fixes"
Bullet "The first run of verify_step44 had 16 of 18 passes. Both failures were in the test, not in the app: the test required the daily-cycle window to start at exactly 0 h (the first stored point after 48 h is at 0.003 h), and compared the overload event times exactly (they are 6.0000000001 h). The tolerances were set."
Bullet "The first run of verify_step43 after the redesign passed 22 of 23: verify_step40 passed only 11 of 13. The new run code (1) set the default DGA file before the status message was written, so the message 'using dga_master.csv' disappeared, and (2) built the sample list from the loaded file, so a file with one record gave 1 of 1 events instead of '1 of 4' with the other records reported as missing. Both behaviours of Step 40 were restored in the app (the first-four set is looked up by record_id from the project list), and the verification repeated: 23 of 23."
Bullet "In the first screenshots the sample table showed only four of the seven rows, a label overlapped a bar of the gas chart and the numbering discs covered text in Figure 8.6. Row heights and label positions were changed and the figure was regenerated."
H1N "Decisions"
Bullet "D43 (proposed): the verdict banner and its colours; the vote rule; the healthy state equal to the IEC 60599 typical-value gate of D11; the cards and the use of the known label for the right/wrong note only; scenario and sample-set choices; the seed rule; the sampling times; the descriptive check on the 388 records."
H1N "Files produced"
Bullet "10_Dashboard_Client/DGADashboard.mlapp (rebuilt), dashboard_verdict.m, dashboard_samples.m, sim_window.m, dashboard_explain.m (steps and label added), test_dashboard_verdict.m, verify_step44.m, tools/dashboard_components.m, DGADashboard_code.txt, build_dashboard_mlapp.m, make_figure_4_22.m, tools/backup_before_redesign/"
Bullet "05_Simulink_Model/run_transformer_simulation.m (optional second argument)"
Bullet "10_Dashboard_Client/results/step44_checks.csv, step44_mixed_run.csv, step44_screen*.png, dashboard_verdict_summary.csv, dashboard_verdict_check.csv, dashboard_verdict_tests.csv; code_manifest_redesign_2026-10-17.sha256"
Bullet "11_Results/figures/F4_22_dashboard_annotated.png (Figure 8.6 of the thesis), 12_Thesis/Thesis_Draft_v3.docx, 00_Project_Admin/Project_Explained_Simply.docx"
Closing "44R" 0 "Step 43 (thesis): Thesis_Draft_v3.docx already contains the new dashboard section and Figure 8.6; the researcher should read it, confirm D43, and decide the open items (author name, repository licence)." $global:Blocks["44R"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Dashboard_Redesign_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Dashboard_Redesign_Report.docx") -Force
("SAVED Dashboard_Redesign_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber + "`n" + $_.ScriptStackTrace) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
