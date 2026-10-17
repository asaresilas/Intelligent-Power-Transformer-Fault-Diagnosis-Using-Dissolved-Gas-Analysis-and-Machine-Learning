# update_register_step40.ps1 - adds the files of roadmap Step 40 (model linked to the dashboard) to the register and glossary. Safe to re-run.
$ErrorActionPreference = "Stop"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$regFile = Join-Path $root "03_Data\provenance\data_and_source_register.csv"
$gloFile = Join-Path $root "00_Project_Admin\abbreviations_glossary.csv"
$utf8 = New-Object Text.UTF8Encoding($false)
function Hsh([string]$rel) { (Get-FileHash (Join-Path $root $rel) -Algorithm SHA256).Hash }
$reg = [System.Collections.ArrayList]@(Import-Csv $regFile -Encoding UTF8)
$cols = $reg[0].PSObject.Properties.Name
function NewRow([hashtable]$h) { $o = [ordered]@{}; foreach ($c in $cols) { $o[$c] = if ($h.ContainsKey($c)) { [string]$h[$c] } else { "" } }; [pscustomobject]$o }
function Put($row) { for ($i = $reg.Count - 1; $i -ge 0; $i--) { if ($reg[$i].id -eq $row.id) { $reg.RemoveAt($i) } }; [void]$reg.Add($row) }
$acc = "2026-10-13"; $R = "10_Dashboard_Client/results/"
Put (NewRow @{ id = "DF74"; category = "Derived file"; name = "Test-bench link results (Step 40)"
  reference = "step40_checks.csv (13 checks of verify_step40.m) and step40_event_run.csv (the four sampling events of the full simulated day as the dashboard shows them: time, record_id, ML class, conventional methods agreeing, simulated hot-spot temperature)."
  accessed = $acc; how_obtained = ($R + "step40_checks.csv"); licence_terms = "Project file"; local_file = ($R + "step40_checks.csv"); sha256 = (Hsh ($R + "step40_checks.csv")); records = "13 checks; 4 events"
  project_role = "Evidence for the Step 40 check: a full simulated day runs from the app"; used_in_steps = "40"
  notes = ("step40_event_run.csv SHA-256 " + (Hsh ($R + "step40_event_run.csv")) + ". The record_ids come from the model (SS8, D35); the gases from DF2.") })
Put (NewRow @{ id = "DF75"; category = "Derived file"; name = "Step 40 code (manifest)"
  reference = "DGADashboard.mlapp (with the event link), find_dga_row.m, verify_step40.m, tools/build_dashboard_mlapp.m, tools/DGADashboard_code.txt, 05_Simulink_Model/run_transformer_simulation.m."; accessed = $acc; how_obtained = "Written in this project"; licence_terms = "Project file"
  local_file = "10_Dashboard_Client/code_manifest_step40.sha256"; sha256 = (Hsh "10_Dashboard_Client/code_manifest_step40.sha256"); records = "6 files"; project_role = "Fingerprints of the Step 40 code"; used_in_steps = "40" })
$f = "11_Results/figures/F4_22_dashboard_annotated.png"
foreach ($x in $reg) { if ($x.id -eq "DF72") { $x.sha256 = (Hsh $f); $x.notes = ("Regenerated in Step 40 to show the final app with the event table. F4_22_dashboard_raw.png (no labels) SHA-256 " + (Hsh "11_Results/figures/F4_22_dashboard_raw.png")); $x.used_in_steps = "39, 40" } }
foreach ($x in $reg) { if ($x.id -in @("SW2", "SW5", "DF2", "DF48", "DF52") -and $x.used_in_steps -notmatch "40") { $x.used_in_steps = ($x.used_in_steps.TrimEnd() + ", 40") } }
[IO.File]::WriteAllLines($regFile, ($reg | ConvertTo-Csv -NoTypeInformation), $utf8)
"register rows: " + $reg.Count
$glo = [System.Collections.ArrayList]@(Import-Csv $gloFile -Encoding UTF8)
$gcols = $glo[0].PSObject.Properties.Name
function G($grp, $term, $meaning, $plain, $pattern) { $o = [ordered]@{}; foreach ($c in $gcols) { $o[$c] = "" }; $o.group = $grp; $o.term = $term; $o.meaning = $meaning; $o.plain_explanation = $plain; $o.pattern = $pattern; [pscustomobject]$o }
foreach ($g in $glo) { if ($g.term -like "D1-D*(decisions)") { $g.term = "D1-D38 (decisions)"; $g.pattern = '[Dd]ecision D|\bD[3-9]\b|\bD[12][0-9]\b|\bD3[0-8]\b' } }
$new = @(
  (G "Dashboard" "Event table" "List of the sampling events of a simulated run in the dashboard" "One row per sampling event: time, record, ML class, how many conventional methods agree, and the simulated hot-spot temperature at that time." '[Ee]vent table'),
  (G "Dashboard" "Playback" "Showing the sampling events of a finished run one after the other" "The dashboard steps through the events in time order and diagnoses the record of each." '[Pp]layback'))
foreach ($n in $new) { for ($i = $glo.Count - 1; $i -ge 0; $i--) { if ($glo[$i].term -eq $n.term) { $glo.RemoveAt($i) } }; [void]$glo.Add($n) }
[IO.File]::WriteAllLines($gloFile, ($glo | ConvertTo-Csv -NoTypeInformation), $utf8)
"glossary rows: " + $glo.Count