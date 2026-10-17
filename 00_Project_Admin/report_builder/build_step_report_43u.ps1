$ErrorActionPreference = "Stop"
# build_step_report_43u.ps1 - Word report "Dashboard master control, freeze fix and explanation panel" (update of Steps 39-40, 15 Oct 2026, D42).
# Numbers come from 10_Dashboard_Client/results (step43_checks.csv, step43_freeze_analysis.md, step43_example_explanation.txt); statements are throw-checked.
# Variable names start with k_ because the dot-sourced helper scripts also use short names. ASCII only.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report43u_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8
function IsTrue($v) { $v -in @("1", "true", "True") }

$k_res = Join-Path $root "10_Dashboard_Client\results"
$k_chk = Import-Csv (Join-Path $k_res "step43_checks.csv")
if ($k_chk.Count -ne 23) { throw "expected 23 checks" }
foreach ($c in $k_chk) { if (-not (IsTrue $c.passed)) { throw ("a check failed: " + $c.check) } }
$k_fa = [IO.File]::ReadAllText((Join-Path $k_res "step43_freeze_analysis.md"), [Text.Encoding]::UTF8)
foreach ($s in @("248.4", "54.4", "12.4", "3.3 s", "requests 1-61")) { if ($k_fa -notmatch [regex]::Escape($s)) { throw ("freeze analysis lacks " + $s) } }
$k_ex = [IO.File]::ReadAllLines((Join-Path $k_res "step43_example_explanation.txt"), [Text.Encoding]::UTF8)
$k_a2 = ($k_chk | Where-Object { $_.check -like "A2*" }).detail
if ($k_a2 -notmatch '^(\d+) requests, (\d+) failed, ([0-9.]+) s, median (\d+) ms, slowest (\d+) ms') { throw "A2 detail not parsed: $k_a2" }
$k_nreq = $Matches[1]; $k_nfail = $Matches[2]; $k_tsec = $Matches[3]; $k_med = $Matches[4]; $k_slow = $Matches[5]
if ($k_nreq -ne "400" -or $k_nfail -ne "0") { throw "stress test result differs from the text" }
$k_b = ($k_chk | Where-Object { $_.check -like "B *" }).detail
if ($k_b -notmatch 'hung state created: 1') { throw "hung state was not created: $k_b" }
$k_btime = [regex]::Match($k_b, '\((\d+) s\)\s*$').Groups[1].Value
$k_c1 = ($k_chk | Where-Object { $_.check -like "C1*" }).detail
$k_f = ($k_chk | Where-Object { $_.check -like "F *" }).detail
if ($k_f -notmatch '^388 records, 0 bad') { throw "F detail differs: $k_f" }
$k_amber = [regex]::Match($k_f, '(\d+) amber').Groups[1].Value
$k_shot = Join-Path $k_res "step43_dashboard_screenshot.png"
if (-not (Test-Path $k_shot)) { throw "screenshot missing" }
$k_man = Join-Path $root "10_Dashboard_Client\code_manifest_masterctl_2026-10-15.sha256"
if (-not (Test-Path $k_man)) { throw "manifest missing" }
$k_matlab = ((Get-Content (Join-Path $root "04_MATLAB_Conventional\tests\test_log.txt") -Encoding utf8 | Where-Object { $_ -like "MATLAB:*" } | Select-Object -First 1) -replace "^MATLAB:\s*", "").Trim()
$global:S43 = @{ matlab = $k_matlab; completed = "15 October 2026"; n = $k_chk.Count; med = $k_med; tsec = $k_tsec; slow = $k_slow }

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
$global:Methods["43U"] = @{
  Approach = @(
    "The dashboard froze, so the first step was to find the cause by measurement, not by guessing. The ML service was started again in the old way and called 400 times in a row from MATLAB while the time of every call was recorded. The service answered requests 1 to 61; request 62 waited 248.4 seconds and MATLAB did not react in that time. The cause is how the service was started: MATLAB's system() command gives the program it starts MATLAB's own output channel (a pipe with a small buffer of about 4 KB). The service writes one log line per request; after about 60 requests the buffer was full, nobody read it, the service stopped while writing the next line and MATLAB waited for the service.",
    "Three more causes of a window that looks frozen were found and removed: a hung service still occupies the network port, so a new one could never start and the old code waited 90 seconds in vain; the first simulation in a MATLAB session compiles the Simulink model and took 54.4 seconds without any message; and nothing stopped a second click on a button while a step was still running.",
    "The dashboard was then made the master control. It starts the service itself (detached from MATLAB, output to a log file), checks that the service answers before every diagnosis and restarts it when it does not, prepares the Simulink model behind a progress window at start-up, switches the buttons off while a step runs, offers a Restart ML service button, and stops the service when it is closed (only if it started it). A new text panel explains every result in plain words for the person who looks at the screen. Finally 23 automatic checks were written and run until all passed (verify_step43.m)."
    )
  Why = @(
    "A fault of this kind cannot be repaired reliably by adding waits or timeouts: the measured wait of 248.4 s happened although a time limit of 10 s was set on the call. The cause had to be removed at its source (the shared output channel).",
    "Starting a service through the Windows management service (WMI) gives the new program no handles of the caller; this is the standard way to start a background program that must outlive, and not depend on, the program that starts it.",
    "A panel that explains each result serves a viewer who is not a DGA specialist: it names the fault types, says what the three classical methods and the ML model answered, how sure the model is, whether the methods agree and how far the answer should be trusted. The wording is fixed in one file (dashboard_explain.m) and only the numbers come from the program, so the text cannot contradict the screen.",
    "Running every check again after each change until all pass (the loop) and re-running the 19 checks of Step 39 and the 13 checks of Step 40 shows that the repair did not break earlier results.")
  Settings = @(
    @("Service start", "09_API_FastAPI/launch_service_detached.ps1: WMI Win32_Process.Create, output to 09_API_FastAPI/logs/service.log, per-request access log off, log level warning"),
    @("Health check", "GET /health with a time limit of 2 s, before every diagnosis; failure leads to stop and restart (waits at most 60 s, reports every 0.5 s)"),
    @("Start-up", "service check/start, then one run of the Simulink model (warm-up, result not kept)"),
    @("Window", "1350 x 690 pixels (the screen of the project laptop is 1366 x 768)"),
    @("Reading aid in the text", "'clear majority' = ML class with more than half of the probability (a display rule, not a validated limit)"),
    @("Checks", ("verify_step43.m: " + $k_chk.Count + " checks; stress test " + $k_nreq + " requests")),
    @("Software", ("MATLAB " + $k_matlab + ", App Designer file written by the internal serializer; FastAPI service of Step 38")))
  Eqs = @()
  Tools = @("09_API_FastAPI/launch_service_detached.ps1, stop_service.ps1",
            "10_Dashboard_Client/ensure_ml_service.m, stop_ml_service.m, dashboard_explain.m, verify_step43.m",
            "10_Dashboard_Client/tools/DGADashboard_code.txt and build_dashboard_mlapp.m (write DGADashboard.mlapp)",
            "00_Project_Admin/report_builder/update_register_step43u.ps1 (register, glossary, decision D42)")
  Refs = @("SW2", "SW6")
}
$global:Closings["43U"] = @{
  Achieved = @(
    ("The cause of the freeze was found by reproduction and removed: the service is started detached from MATLAB. The same stress test that stopped the old start at request 62 now passes: " + $k_nreq + " of " + $k_nreq + " requests answered, none failed, median " + $k_med + " ms."),
    ("A service that is stuck (holds the port, does not answer) is detected, stopped and replaced by a working one in " + $k_btime + " s."),
    "The dashboard is the master control: running DGADashboard is enough (it starts the service, prepares the model, restarts the service when needed and stops it on close).",
    "A new panel explains each result in plain words (simulation, the three classical methods, the ML class and probability, agreement, fault types, how much to trust it); its text was built without error for all 388 held-out records.",
    ("All " + $k_chk.Count + " checks pass, including the 19 checks of Step 39 and the 13 checks of Step 40."))
  Record = @(
    @("Step", "Update of Steps 39-40: dashboard freeze fix, master control and explanation panel (decision D42)"), @("Environment", "Claude Code (this chat) through the MATLAB MCP connection"),
    @("Completed", "15 October 2026"), @("Status", "Done (D42 proposed, to be confirmed by the researcher)"),
    @("Main inputs", "DGADashboard.mlapp of Steps 39-40; the FastAPI service of Step 38; the model of Step 33; dga_master.csv"),
    @("Main outputs", "DGADashboard.mlapp (rebuilt), dashboard_explain.m, ensure_ml_service.m, stop_ml_service.m, launch_service_detached.ps1, stop_service.ps1, verify_step43.m, results/step43_checks.csv, step43_freeze_analysis.md, step43_dashboard_screenshot.png"),
    @("Checks", ("verify_step43.m: " + $k_chk.Count + " of " + $k_chk.Count + " PASS")),
    @("Decisions", "D42"))
  Helps = @(
    "Step 43 (the thesis) can describe the dashboard as a self-starting master control and show the new screenshot (results/step43_dashboard_screenshot.png) instead of the earlier Figure 4.22.",
    "The demonstration for the supervisor needs one command (DGADashboard); the how-to README (section 5) was rewritten accordingly.",
    "The explanation text gives the viewer the interpretation that the thesis Chapter 4 gives in writing.")
  Open = @(
    "Figure 4.22 of the thesis and the Step 39 and 40 reports still show the layout before this update; the new screenshot is a candidate replacement (not yet used).",
    "Not tested on a second computer. The explanation text assumes the project folders as delivered.",
    "The statement in the panel that the ML model was not shown to be better than the classical methods on IEC TC 10 repeats the final verdict of Step 31; it must be kept in line with the thesis.",
    "The reference values for the ageing text (98 degC and 6 K) are those of params_transformer.m and are still marked TO VERIFY against IEC 60076-7.",
    "The service is stopped on close only when the dashboard started it; a service started by hand stays running.",
    "dashboard_explain.m: the number format of the gas values was changed after the last full run of verify_step43 (checked on one record).",
    "The full verification takes about 20 minutes because it also repeats the 388-record checks of Steps 39 and 40.")
  Exclude = @()
}
$global:StepSources["43U"] = @("DF86", "DF87", "DF88", "DF89", "DF71", "DF74", "SW2", "SW6")
function ReportHeader43([string]$name, [string]$env, [string]$completed) {
  $global:sec = 0; $global:eqn = 0
  Title "Dashboard Update Report" 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "43U" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader43 "Dashboard master control, freeze fix and explanation panel (update of Steps 39 and 40)" "Claude Code (this chat), MATLAB through the MCP connection" $S43.completed
Summary ("The dashboard no longer freezes, and running it is enough. The freeze was reproduced and its cause found: the ML service had been started in a way that tied it to MATLAB's own output channel, and after about 60 requests the service stopped and MATLAB waited for it (request 62 waited 248.4 seconds). The service is now started detached from MATLAB; a stuck service is replaced automatically; the Simulink model is prepared behind a progress window at start-up; the buttons are switched off while a step runs; and the service is stopped when the dashboard is closed. A new panel, How to read this result, explains every result in plain words for the viewer. All " + $k_chk.Count + " automatic checks pass, including the stress test that stopped the old version (" + $k_nreq + " of " + $k_nreq + " requests answered, none failed) and the 19 + 13 checks of Steps 39 and 40.")
H1N "Purpose of this update"
Body "The researcher reported that the software froze, and asked that the dashboard be the master control (running the app should be enough and everything should work), that the app show an explanation text so that a viewer can interpret each result, that every step be reported, and that the work not stop before everything works. This report describes how the cause was found, what was changed, what the explanation panel says and how it was checked."
MethodSection "43U"
H1N "Why the software froze (measured)"
AddTable @("What was measured", "Result") @(
  , @("State at the start of the session", "A service process held port 8000 but did not answer: the health request timed out after 3 s")
  , @("Reproduction with the old start method: requests answered", "1 to 61")
  , @("Request 62", "waited 248.4 s, until the service processes were stopped from outside; MATLAB itself did not respond meanwhile")
  , @("First simulation of a fresh MATLAB session (whole run)", "54.4 s with no message (a repeated run: 12.4 s; the simulation alone: 3.3 s)")
  , @("Same stress test after the fix", ($k_nreq + " requests in " + $k_tsec + " s, " + $k_nfail + " failed, median " + $k_med + " ms, slowest " + $k_slow + " ms"))
) @(250, 200)
Body "The full analysis, with the table of changed files, is in 10_Dashboard_Client/results/step43_freeze_analysis.md. In plain words: the old start gave the service MATLAB's output pipe; a pipe holds only about 4 KB; the service writes a line for every request; when the pipe was full, the service waited for someone to read it, and MATLAB waited for the service."
H1N "What was done, step by step"
NumItem "1" "Read the project memory (session summary, working preferences, plan) and the dashboard code. Found that the app waited up to 90 s in start-up with no message, and that the service could be started in a hidden window by system()."
NumItem "2" "Checked the running system: the service process was alive but did not answer. Stopped it and restarted it, then reproduced the freeze with a loop of 400 calls (result above)."
NumItem "3" "Wrote the repair: a start script that uses the Windows management service (09_API_FastAPI/launch_service_detached.ps1), a safe stop script, and a new ensure_ml_service.m that also replaces a stuck service. Repeated the 400-call test: all answered."
NumItem "4" "Rebuilt the dashboard: health check before each diagnosis, busy lock on the buttons, progress windows, model warm-up at start, Restart ML service button, click on an event row, stop of the own service on close, and a fourth column with the explanation panel. The window was made 1350 x 690 pixels for the 1366 x 768 screen of the project laptop."
NumItem "5" "Wrote dashboard_explain.m, the program that writes the explanation text, and checked its output on a screenshot of the app."
NumItem "6" ("Wrote verify_step43.m (" + $k_chk.Count + " checks) and ran it until every check passed (see Problems and fixes).")
NumItem "7" "Updated the how-to README (section 5), the dashboard README, the register (DF86-DF89), the glossary, the decision log (D42), CHANGELOG.md, SESSION_SUMMARY.md and the memory notes."
H1N "How the dashboard works now"
AddTable @("When", "What the dashboard does by itself") @(
  , @("It is started (DGADashboard)", "Finds the project folders; loads params_transformer; checks the ML service and starts it detached if needed; runs the Simulink model once (warm-up); shows the welcome text. A window 'Starting the dashboard' shows each of these steps (about 25 s with a warm model, up to about 1 min on the first start).")
  , @("Run transformer simulation", "Switches the buttons off, shows a progress window, runs the model for 24 h, plots top-oil and hot-spot temperature, marks the sampling events, then diagnoses the record of each event and explains the run.")
  , @("Diagnose selected record", "Reads the five gases of the chosen row, computes Rogers, IEC 60599 and Duval in MATLAB, checks that the service answers (restarts it if not), asks the ML service, shows the tables, the Duval Triangle, the agreement lamp and the explanation.")
  , @("A row of the event table is clicked", "Shows that event's record, results and explanation again.")
  , @("Restart ML service is pressed", "Stops the service (also a stuck one) and starts it again.")
  , @("The window is closed", "Stops the ML service if this dashboard started it; leaves one that was started by hand.")
) @(140, 310)
H1N "The explanation panel"
Body "The panel at the right edge is called How to read this result. At the start it explains what the dashboard does, what to press, which information comes from where (temperatures from the simulated transformer; gas values only from measured records) and what the fault types mean. After a diagnosis it explains that record; after a simulated day it first summarises the day (the sampling events and the simulation) and then the last record. Every number in it is taken from the program output; the fixed wording follows IEC 60599 (fault types, typical values) and the project decisions on agreement (D11, D25, D37)."
AddTable @("Part of the text", "What it tells the viewer") @(
  , @("Gas level", "Whether every gas is at or below the IEC 60599 typical value (the classical methods then say Normal), with the warning that typical values are not fault limits")
  , @("Classical methods", "Rogers, IEC 60599 and Duval answers, each with the fault type in words; ND (no diagnosis), DT (mixed fault) and D1 or D2 are explained")
  , @("Machine learning", "Most probable class, its probability, the next two classes, whether one class has more than half of the probability, and a note when the model names a fault although all gases are within typical values")
  , @("Agreement", "What the lamp colour means and which method differs from the ML answer")
  , @("How much to trust it", "Decision support, not a verdict; on the IEC TC 10 cases of this study the ML model was not shown to be better than the classical methods; confirm with a repeat sample, the gas trend and an inspection")
  , @("Simulation", "Peak and final temperatures, load, the ageing rule (98 degC = rate 1, 6 K doubles it, TO VERIFY) and the loss of life of the run, with the reminder that the simulation is context and not the cause of the gases")
) @(120, 330)
H2 "Example of the text (record IECTC10_0002 and the simulated day)"
Ital "The lines below were written by the program (results/step43_example_explanation.txt); nothing was edited."
foreach ($ln in $k_ex) { if ($ln.Trim() -ne "") { Body $ln } }
Caption "Figure  The dashboard after a simulated day and a click on sampling event 2 (program screenshot)"
Pic $k_shot 450
H1N "Checks"
$k_rows = @(); foreach ($c in $k_chk) { $k_rows += , @($c.check, "PASS") }
AddTable @("Check (verify_step43.m)", "Result") $k_rows @(360, 90)
Body ("Check F built the explanation of all 388 held-out records (" + $k_amber + " of them with amber agreement) without error and without any NaN in the text, named the three classical answers and the ML class in each, and checked that the agreement text matches the lamp colour.")
H1N "Problems and fixes"
Bullet "The first full run of the checks stopped at check C3 because the test helper put buttons of different types into one array (a fault in the test, not in the app); corrected."
Bullet "The second run failed at check D because the test read a private property of the app (SimResult); the property was made public so that the check can compare the plotted values with the program values."
Bullet "Check B (a stuck service is replaced) failed twice at its set-up, not in the app: the stuck-service stand-in could not be created, first because the default execution policy of PowerShell blocks script files, then because the MATLAB temp folder name contains a space. The stand-in was first created by hand and the real recovery code was run against it (the stuck service was stopped and replaced in about 15 s); the test was then corrected and the whole verification repeated."
Bullet "One earlier idea was not used: a longer or shorter time limit on the call. The measured wait (248.4 s) happened with a 10 s limit set, so a limit does not protect against this fault; the health check before each call and the detached start do."
Bullet "The old ensure_ml_service.m and stop_ml_service.m were overwritten before the backup copy was made; the backup folder tools/backup_before_masterctl therefore holds the new versions of these two files (the old version is described in the freeze analysis). The old app and its code are in the backup."
H1N "Decisions"
Bullet "D42 (proposed): the cause and the repair of the freeze; the start of the service detached from MATLAB; the health check before each diagnosis; the busy lock, progress windows and warm-up; the Restart button; stop on close only for a service that the app started; the explanation panel and its rules; the checks. The reading aid 'more than half of the probability = clear majority' is a display rule."
H1N "Files produced"
Bullet "09_API_FastAPI/launch_service_detached.ps1, stop_service.ps1 (new); logs/service.log (written when the service runs)"
Bullet "10_Dashboard_Client/DGADashboard.mlapp (rebuilt), dashboard_explain.m (new), ensure_ml_service.m, stop_ml_service.m (rewritten), verify_step43.m (new), tools/DGADashboard_code.txt and build_dashboard_mlapp.m (updated), tools/backup_before_masterctl/ (previous app and code)"
Bullet "10_Dashboard_Client/results/step43_checks.csv, step43_freeze_analysis.md, step43_example_explanation.txt, step43_dashboard_screenshot.png; code_manifest_masterctl_2026-10-15.sha256"
Closing "43U" 0 "Step 43 (thesis writing, already drafted as 12_Thesis/Thesis_Draft_v2.docx): replace the dashboard figure by the new screenshot and describe the master control and the explanation panel in the dashboard section; the supervisor demonstration can start from the single command DGADashboard." $global:Blocks["43U"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Dashboard_MasterControl_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Dashboard_MasterControl_Report.docx") -Force
("SAVED Dashboard_MasterControl_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber + "`n" + $_.ScriptStackTrace) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
