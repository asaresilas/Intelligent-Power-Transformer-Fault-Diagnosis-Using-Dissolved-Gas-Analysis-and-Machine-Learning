# update_register_step37.ps1 - adds the files of roadmap Step 37 (DGA sampling-event subsystem) to the register and glossary. Safe to re-run.
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
$acc = "2026-10-13"; $R = "05_Simulink_Model/results/"
Put (NewRow @{ id = "DF69"; category = "Derived file"; name = "Sampling-event subsystem results and checks (Step 37)"
  reference = "step37_checks.csv (10 checks of verify_step37.m), step37_sampling_events.csv (sampling times, record_index, record_id), step37_ss8_blocks.csv (the 13 blocks of SS8)."
  accessed = $acc; how_obtained = ($R + "step37_checks.csv"); licence_terms = "Project file"; local_file = ($R + "step37_checks.csv"); sha256 = (Hsh ($R + "step37_checks.csv")); records = "10 checks; 4 events; 13 blocks"
  project_role = "Evidence that SS8 produces events only and leaves the temperatures unchanged"; used_in_steps = "37"
  notes = ("step37_sampling_events.csv SHA-256 " + (Hsh ($R + "step37_sampling_events.csv")) + "; step37_ss8_blocks.csv SHA-256 " + (Hsh ($R + "step37_ss8_blocks.csv")) + ". Held-out record_ids come from DF2 (columns record_id and data_role only).") })
Put (NewRow @{ id = "DF70"; category = "Derived file"; name = "Step 37 code (manifest)"
  reference = "verify_step37.m, get_sampling_events.m, params_transformer.m and build_Transformer_Operating_Model.m as at the end of Step 37 (solver tolerance 1e-4)."; accessed = $acc; how_obtained = "Written in this project"; licence_terms = "Project file"
  local_file = "05_Simulink_Model/code_manifest_step37.sha256"; sha256 = (Hsh "05_Simulink_Model/code_manifest_step37.sha256"); records = "4 files"; project_role = "Fingerprints of the Step 37 code"; used_in_steps = "37" })
foreach ($x in $reg) { if ($x.id -in @("SW2", "SW5", "DF2", "DF48", "DF52") -and $x.used_in_steps -notmatch "37") { $x.used_in_steps = ($x.used_in_steps.TrimEnd() + ", 37") } }
[IO.File]::WriteAllLines($regFile, ($reg | ConvertTo-Csv -NoTypeInformation), $utf8)
"register rows: " + $reg.Count
$glo = [System.Collections.ArrayList]@(Import-Csv $gloFile -Encoding UTF8)
$gcols = $glo[0].PSObject.Properties.Name
function G($grp, $term, $meaning, $plain, $pattern) { $o = [ordered]@{}; foreach ($c in $gcols) { $o[$c] = "" }; $o.group = $grp; $o.term = $term; $o.meaning = $meaning; $o.plain_explanation = $plain; $o.pattern = $pattern; [pscustomobject]$o }
foreach ($g in $glo) { if ($g.term -like "D1-D*(decisions)") { $g.term = "D1-D35 (decisions)"; $g.pattern = '[Dd]ecision D|\bD[3-9]\b|\bD[12][0-9]\b|\bD3[0-5]\b' } }
$new = @(
  (G "Simulink" "Sampling event" "A moment in simulated time at which a gas sample would be taken" "The model only says when; the gas values come from the real measured record in the data file, never from the model." '[Ss]ampling[- ]event'),
  (G "Simulink" "Held-out record" "A record of the master table that is not used for development" "A record kept aside (benchmark, internal test or external test) so that the methods are judged on data they did not learn from." '[Hh]eld-out'),
  (G "Simulink" "Solver tolerance (RelTol)" "Relative accuracy that the variable-step solver keeps at each step" "A smaller RelTol makes the solver take smaller steps: the result is more exact and the run slower." 'RelTol'))
foreach ($n in $new) { for ($i = $glo.Count - 1; $i -ge 0; $i--) { if ($glo[$i].term -eq $n.term) { $glo.RemoveAt($i) } }; [void]$glo.Add($n) }
[IO.File]::WriteAllLines($gloFile, ($glo | ConvertTo-Csv -NoTypeInformation), $utf8)
"glossary rows: " + $glo.Count