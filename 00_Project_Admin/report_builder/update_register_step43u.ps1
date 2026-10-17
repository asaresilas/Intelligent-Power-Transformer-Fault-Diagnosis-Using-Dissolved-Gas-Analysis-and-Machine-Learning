# update_register_step43u.ps1 - adds the files of the dashboard master-control update (15 Oct 2026: freeze fix, explanation panel) to the register,
# the glossary and the decision log. Safe to re-run. STOPS if one of its IDs is already used by another entry (parallel sessions).
$ErrorActionPreference = "Stop"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$regFile = Join-Path $root "03_Data\provenance\data_and_source_register.csv"
$gloFile = Join-Path $root "00_Project_Admin\abbreviations_glossary.csv"
$decFile = Join-Path $root "00_Project_Admin\decisions_log.md"
$utf8 = New-Object Text.UTF8Encoding($false)
function Hsh([string]$rel) { (Get-FileHash (Join-Path $root $rel) -Algorithm SHA256).Hash }
$reg = [System.Collections.ArrayList]@(Import-Csv $regFile -Encoding UTF8)
$cols = $reg[0].PSObject.Properties.Name
$mine = @("DF86", "DF87", "DF88", "DF89", "DF90")
foreach ($x in $reg) { if ($x.id -in $mine -and $x.name -notmatch "master.control|[Ff]reeze|explanation|screenshot") { throw ("ID " + $x.id + " is already used by another entry: " + $x.name) } }
function NewRow([hashtable]$h) { $o = [ordered]@{}; foreach ($c in $cols) { $o[$c] = if ($h.ContainsKey($c)) { [string]$h[$c] } else { "" } }; [pscustomobject]$o }
function Put($row) { for ($i = $reg.Count - 1; $i -ge 0; $i--) { if ($reg[$i].id -eq $row.id) { $reg.RemoveAt($i) } }; [void]$reg.Add($row) }
$acc = "2026-10-15"; $D = "10_Dashboard_Client/"
Put (NewRow @{ id = "DF86"; category = "Derived file"; name = "Dashboard master control - checks (freeze fix, explanation panel)"
  reference = "verify_step43.m: 23 checks (400-request stress test through the detached service start, recovery from a hung service, cold start of the app, run + explanation text, click on an event, explanation text of all 388 held-out records, service stopped during use, closing the window, buttons after a failure, regression of the 19 + 13 older checks)."
  accessed = $acc; how_obtained = "Program output"; licence_terms = "Project file"; local_file = ($D + "results/step43_checks.csv"); sha256 = (Hsh ($D + "results/step43_checks.csv")); records = "23 checks"
  project_role = "Evidence that the dashboard is the master control and no longer freezes"; used_in_steps = "39, 40, Chapter 3, Chapter 4" })
Put (NewRow @{ id = "DF87"; category = "Derived file"; name = "Freeze analysis of the dashboard (15 Oct 2026)"
  reference = "step43_freeze_analysis.md: observation, reproduction (request 62 waited 248.4 s), cause (service started with system() inherited MATLAB's 4 KB output pipe), fix, second cause (cold first run 54.4 s), result after the fix."
  accessed = $acc; how_obtained = "Written in this project from measured session output"; licence_terms = "Project file"; local_file = ($D + "results/step43_freeze_analysis.md"); sha256 = (Hsh ($D + "results/step43_freeze_analysis.md")); records = "1 document"
  project_role = "Record of why the software froze and what was changed"; used_in_steps = "39, 40" })
Put (NewRow @{ id = "DF88"; category = "Derived file"; name = "Dashboard screenshot with the explanation panel"
  reference = "step43_dashboard_screenshot.png: the app after a simulated day and a click on sampling event 2 (exportapp)."
  accessed = $acc; how_obtained = "Program output"; licence_terms = "Project file"; local_file = ($D + "results/step43_dashboard_screenshot.png"); sha256 = (Hsh ($D + "results/step43_dashboard_screenshot.png")); records = "1 image"
  project_role = "Candidate replacement of Figure 4.22 (not yet used in the thesis)"; used_in_steps = "39, 40" })
Put (NewRow @{ id = "DF89"; category = "Derived file"; name = "Dashboard master-control code (manifest)"
  reference = "DGADashboard.mlapp, tools/DGADashboard_code.txt, tools/build_dashboard_mlapp.m, dashboard_explain.m, ensure_ml_service.m, stop_ml_service.m, verify_step43.m, 09_API_FastAPI/launch_service_detached.ps1, stop_service.ps1. Previous app and code: tools/backup_before_masterctl/."
  accessed = $acc; how_obtained = "Written in this project"; licence_terms = "Project file"; local_file = ($D + "code_manifest_masterctl_2026-10-15.sha256"); sha256 = (Hsh ($D + "code_manifest_masterctl_2026-10-15.sha256")); records = "9 files"
  project_role = "Fingerprints of the master-control code"; used_in_steps = "39, 40" })
foreach ($x in $reg) { if ($x.id -in @("DF71", "DF74") -and $x.notes -notmatch "master-control") { $x.notes = ($x.notes + " Dashboard app rebuilt 15 Oct 2026 (master control, explanation panel); checks repeated in verify_step43 (DF86).").Trim() } }
[IO.File]::WriteAllLines($regFile, ($reg | ConvertTo-Csv -NoTypeInformation), $utf8)
"register rows: " + $reg.Count

$glo = [System.Collections.ArrayList]@(Import-Csv $gloFile -Encoding UTF8)
$gcols = $glo[0].PSObject.Properties.Name
function G($grp, $term, $meaning, $plain, $src, $pattern) { $o = [ordered]@{}; foreach ($c in $gcols) { $o[$c] = "" }; $o.group = $grp; $o.term = $term; $o.meaning = $meaning; $o.plain_explanation = $plain; $o.source = $src; $o.pattern = $pattern; [pscustomobject]$o }
foreach ($g in $glo) { if ($g.term -like "D1-D*(decisions)") { $g.term = "D1-D42 (decisions)"; $g.pattern = '[Dd]ecision D|\bD[3-9]\b|\bD[12][0-9]\b|\bD3[0-9]\b|\bD4[0-2]\b' } }
$new = @(
  (G "Software" "Master control" "one program that starts and supervises the others" "The dashboard starts the ML service, prepares the Simulink model, checks that the service answers before each diagnosis, and stops the service when the dashboard is closed." "" '[Mm]aster control'),
  (G "Software" "Detached start" "starting a program so that it shares no connection with the program that started it" "The ML service is started in a way that leaves MATLAB's own output channel unused; if they were shared, a full channel could stop the service and freeze MATLAB." "" '[Dd]etached'),
  (G "Software" "Access log" "a line written by a web service for every request it answers" "It was the lines of this log that filled a small buffer and stopped the service in the old start method." "" '[Aa]ccess log'))
foreach ($n in $new) { for ($i = $glo.Count - 1; $i -ge 0; $i--) { if ($glo[$i].term -eq $n.term) { $glo.RemoveAt($i) } }; [void]$glo.Add($n) }
[IO.File]::WriteAllLines($gloFile, ($glo | ConvertTo-Csv -NoTypeInformation), $utf8)
"glossary rows: " + $glo.Count

$dec = [IO.File]::ReadAllText($decFile, [Text.Encoding]::UTF8)
if ($dec -notmatch '\| D42 \|') {
  $row = "| D42 | Dashboard master control, freeze fix and explanation panel (15 Oct 2026). **Fixed after the freeze analysis, before the checks of verify_step43 were run.** | (1) CAUSE of the freeze, measured: the ML service started with system() shared MATLAB's output pipe; after about 60 requests the 4 KB pipe was full, the service blocked and MATLAB waited for it (request 62 waited 248.4 s). (2) The service is started detached (WMI Win32_Process.Create, output to 09_API_FastAPI/logs/service.log, access log off); a service that owns port 8000 but does not answer is stopped and replaced; the dashboard checks /health before every diagnosis and restarts the service if needed. (3) The first simulation in a MATLAB session takes about 50 s (model compile): it is done at start-up behind a progress window. (4) Buttons are disabled while a step runs; a Restart ML service button is added; closing the window stops a service that THIS app started and leaves one that it did not start (the researcher asked on 2026-10-15 that the dashboard be the master control). (5) A panel 'How to read this result' explains in plain words the simulation, the three conventional answers, the ML class and probability, the agreement lamp, the fault types and how much to trust the answer; the text is built by dashboard_explain.m from the program values only; fixed wording follows IEC 60599 (fault types, typical values) and D11, D25, D37; the statement that ML was not shown to be better than the conventional methods on IEC TC 10 follows the Step 31 verdict. The reading aid 'a class with more than half of the probability is a clear majority' is a display rule, not a validated limit. (6) Checks: verify_step43.m, 23 checks, including the 19 of Step 39 and the 13 of Step 40. | PROPOSED - to be confirmed by the researcher |"
  [IO.File]::WriteAllText($decFile, $dec.TrimEnd() + "`r`n`r`n" + $row + "`r`n", $utf8)
  "decision D42 added"
} else { "decision D42 already present" }
