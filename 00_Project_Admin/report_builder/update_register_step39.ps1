# update_register_step39.ps1 - adds the files of roadmap Step 39 (dashboard) to the register and glossary. Safe to re-run.
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
Put (NewRow @{ id = "DF71"; category = "Derived file"; name = "Dashboard checks and comparison with the offline results (Step 39)"
  reference = "step39_checks.csv (19 checks of verify_step39.m), step39_three_records.csv (the three known records), step39_held_out_comparison.csv (388 held-out records: app answers against offline results)."
  accessed = $acc; how_obtained = ($R + "step39_checks.csv"); licence_terms = "Project file"; local_file = ($R + "step39_checks.csv"); sha256 = (Hsh ($R + "step39_checks.csv")); records = "19 checks; 3 + 388 records"
  project_role = "Evidence for the Step 39 check: known records give the offline answers"; used_in_steps = "39"
  notes = ("step39_three_records.csv SHA-256 " + (Hsh ($R + "step39_three_records.csv")) + "; step39_held_out_comparison.csv SHA-256 " + (Hsh ($R + "step39_held_out_comparison.csv")) + ". Compared with DF2-based offline files conventional_predictions.csv and ml_predictions.csv.") })
$f = "11_Results/figures/F4_22_dashboard_annotated.png"
Put (NewRow @{ id = "DF72"; category = "Derived file"; name = "Figure 4.22 - Annotated screenshot of the dashboard"
  reference = "Screenshot of DGADashboard after a simulation run and the diagnosis of record IECTC10_0001 (exportapp), with numbered labels; .pdf and legend .csv beside it."
  accessed = $acc; how_obtained = $f; licence_terms = "Project file"; local_file = $f; sha256 = (Hsh $f); records = "1 figure"
  project_role = "Figure 4.22 of the thesis"; used_in_steps = "39"; notes = ("F4_22_dashboard_raw.png (no labels) SHA-256 " + (Hsh "11_Results/figures/F4_22_dashboard_raw.png")) })
Put (NewRow @{ id = "DF73"; category = "Derived file"; name = "Step 39 code (manifest)"
  reference = "DGADashboard.mlapp, dga_agreement.m, ml_diagnose.m, load_dga_record.m, verify_step39.m, tools/build_dashboard_mlapp.m, tools/DGADashboard_code.txt, tools/make_figure_4_22.m."; accessed = $acc; how_obtained = "Written in this project"; licence_terms = "Project file"
  local_file = "10_Dashboard_Client/code_manifest_step39.sha256"; sha256 = (Hsh "10_Dashboard_Client/code_manifest_step39.sha256"); records = "8 files"; project_role = "Fingerprints of the Step 39 code"; used_in_steps = "39" })
foreach ($x in $reg) { if ($x.id -in @("SW2", "SW5", "DF2", "DF48", "DF52") -and $x.used_in_steps -notmatch "39") { $x.used_in_steps = ($x.used_in_steps.TrimEnd() + ", 39") } }
[IO.File]::WriteAllLines($regFile, ($reg | ConvertTo-Csv -NoTypeInformation), $utf8)
"register rows: " + $reg.Count
$glo = [System.Collections.ArrayList]@(Import-Csv $gloFile -Encoding UTF8)
$gcols = $glo[0].PSObject.Properties.Name
function G($grp, $term, $meaning, $plain, $pattern) { $o = [ordered]@{}; foreach ($c in $gcols) { $o[$c] = "" }; $o.group = $grp; $o.term = $term; $o.meaning = $meaning; $o.plain_explanation = $plain; $o.pattern = $pattern; [pscustomobject]$o }
foreach ($g in $glo) { if ($g.term -like "D1-D*(decisions)") { $g.term = "D1-D37 (decisions)"; $g.pattern = '[Dd]ecision D|\bD[3-9]\b|\bD[12][0-9]\b|\bD3[0-7]\b' } }
$new = @(
  (G "Dashboard" "Agreement flag" "Lamp that says whether the conventional methods agree with the ML diagnosis" "Green: all three conventional methods give the same class as ML. Amber: at least one does not. Grey: no ML answer." '[Aa]greement (flag|lamp)'),
  (G "Dashboard" "webwrite" "MATLAB function that sends data to a web service" "How the dashboard sends the five gas values to the FastAPI service and receives the ML class." 'webwrite'),
  (G "Dashboard" "App Designer" "MATLAB tool for building apps (.mlapp files)" "The program in which DGADashboard.mlapp is edited; the file can also be run without opening it." 'App Designer'))
foreach ($n in $new) { for ($i = $glo.Count - 1; $i -ge 0; $i--) { if ($glo[$i].term -eq $n.term) { $glo.RemoveAt($i) } }; [void]$glo.Add($n) }
[IO.File]::WriteAllLines($gloFile, ($glo | ConvertTo-Csv -NoTypeInformation), $utf8)
"glossary rows: " + $glo.Count