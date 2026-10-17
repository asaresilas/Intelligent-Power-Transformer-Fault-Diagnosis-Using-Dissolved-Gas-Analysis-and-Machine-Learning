# update_register_step36.ps1 - adds the files of roadmap Step 36 (operating scenarios) to the register and glossary. Safe to re-run.
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
Put (NewRow @{ id = "DF64"; category = "Derived file"; name = "Simulated operating scenarios (Step 36)"
  reference = "sim_rated.mat, sim_daily.mat, sim_overload.mat written by run_step36.m from Transformer_Operating_Model.slx and scenarios.m (decision D34): time, demand, measured K, ambient, top-oil, hot-spot, ageing rate, loss of life, peak."
  accessed = $acc; how_obtained = ($R + "sim_*.mat"); licence_terms = "Project file"; local_file = ($R + "sim_rated.mat"); sha256 = (Hsh ($R + "sim_rated.mat")); records = "3 runs"
  project_role = "Operating context for the dashboard and Figure 4.19; no diagnosis use"; used_in_steps = "36"
  notes = ("sim_daily.mat SHA-256 " + (Hsh ($R + "sim_daily.mat")) + "; sim_overload.mat SHA-256 " + (Hsh ($R + "sim_overload.mat")) + ". MATLAB .mat files carry a save time, so the hash changes on every save; reproducibility is tested on the signals (identical to 0.00e+00).") })
Put (NewRow @{ id = "DF65"; category = "Derived file"; name = "Scenario definitions, summary and checks (Step 36)"
  reference = "step36_scenario_definitions.csv (demand breakpoints), step36_scenario_summary.csv (peak hot-spot and time, loss of life L), step36_checks.csv (13 checks)."
  accessed = $acc; how_obtained = ($R + "step36_scenario_summary.csv"); licence_terms = "Project file"; local_file = ($R + "step36_scenario_summary.csv"); sha256 = (Hsh ($R + "step36_scenario_summary.csv")); records = "3 scenarios; 13 checks"
  project_role = "Evidence for the Step 36 check 'each run can be reproduced'"; used_in_steps = "36"
  notes = ("step36_checks.csv SHA-256 " + (Hsh ($R + "step36_checks.csv")) + "; step36_scenario_definitions.csv SHA-256 " + (Hsh ($R + "step36_scenario_definitions.csv"))) })
$f = "11_Results/figures/F4_19a_scenario_rated.png"
Put (NewRow @{ id = "DF66"; category = "Derived file"; name = "Figure 4.19 - Operating scenarios (a rated load, b daily cycle, c overload)"
  reference = "Three panels each (load factor; ambient, top-oil and hot-spot temperature; ageing rate on a log axis with the loss of life); colours from plot_style.csv. .pdf and .csv (plotted numbers) beside each .png."
  accessed = $acc; how_obtained = $f; licence_terms = "Project file"; local_file = $f; sha256 = (Hsh $f); records = "3 figures"
  project_role = "Figure 4.19 of the thesis"; used_in_steps = "36"
  notes = ("F4_19b_scenario_daily.png SHA-256 " + (Hsh "11_Results/figures/F4_19b_scenario_daily.png") + "; F4_19c_scenario_overload.png SHA-256 " + (Hsh "11_Results/figures/F4_19c_scenario_overload.png")) })
Put (NewRow @{ id = "DF67"; category = "Derived file"; name = "Simulation Data Inspector session of the Step 36 runs"
  reference = "The three scenario runs (K_pu, theta_oil_C, theta_hs_C, ageing_rate_V) saved with Simulink.sdi.save."
  accessed = $acc; how_obtained = ($R + "step36_sdi_session.mldatx"); licence_terms = "Project file"; local_file = ($R + "step36_sdi_session.mldatx"); sha256 = (Hsh ($R + "step36_sdi_session.mldatx")); records = "3 runs"
  project_role = "SDI log required by the roadmap"; used_in_steps = "36"; notes = "Binary; hash changes with every save." })
Put (NewRow @{ id = "DF68"; category = "Derived file"; name = "Step 36 code (manifest)"
  reference = "scenarios.m (the three scenario definitions) and run_step36.m (runs, checks, figures)."; accessed = $acc; how_obtained = "Written in this project"; licence_terms = "Project file"
  local_file = "05_Simulink_Model/code_manifest_step36.sha256"; sha256 = (Hsh "05_Simulink_Model/code_manifest_step36.sha256"); records = "2 files"; project_role = "Fingerprints of the Step 36 code"; used_in_steps = "36" })
foreach ($x in $reg) { if ($x.id -in @("SW2", "SW5", "DF48", "DF52") -and $x.used_in_steps -notmatch "36") { $x.used_in_steps = ($x.used_in_steps.TrimEnd() + ", 36") } }
[IO.File]::WriteAllLines($regFile, ($reg | ConvertTo-Csv -NoTypeInformation), $utf8)
"register rows: " + $reg.Count
$glo = [System.Collections.ArrayList]@(Import-Csv $gloFile -Encoding UTF8)
$gcols = $glo[0].PSObject.Properties.Name
function G($grp, $term, $meaning, $plain, $pattern) { $o = [ordered]@{}; foreach ($c in $gcols) { $o[$c] = "" }; $o.group = $grp; $o.term = $term; $o.meaning = $meaning; $o.plain_explanation = $plain; $o.pattern = $pattern; [pscustomobject]$o }
foreach ($g in $glo) { if ($g.term -like "D1-D*(decisions)") { $g.term = "D1-D34 (decisions)"; $g.pattern = '[Dd]ecision D|\bD[3-9]\b|\bD[12][0-9]\b|\bD3[0-4]\b' } }
$new = @(
  (G "Transformer" "Loss of life (L)" "Equivalent hours of insulation ageing at the reference hot-spot temperature" "The sum of the ageing rate over time: L = 24 h would mean the insulation aged as much as in 24 hours at 98 degC." '[Ll]oss of life'),
  (G "Transformer" "Overload" "Load above rated current" "A load factor above 1.0 per unit; the hot spot heats quickly and the ageing rate rises steeply." '[Oo]verload'),
  (G "Simulink" "Operating scenario" "A chosen load history used to run the model" "An illustrative example of how the transformer is loaded over time (constant, daily cycle, overload); it is not measured data." '[Oo]perating scenario'))
foreach ($n in $new) { for ($i = $glo.Count - 1; $i -ge 0; $i--) { if ($glo[$i].term -eq $n.term) { $glo.RemoveAt($i) } }; [void]$glo.Add($n) }
[IO.File]::WriteAllLines($gloFile, ($glo | ConvertTo-Csv -NoTypeInformation), $utf8)
"glossary rows: " + $glo.Count