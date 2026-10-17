# update_register_step35.ps1 - adds the files of roadmap Step 35 (verification against IEC 60076-7) to the register and glossary.
#   Safe to re-run: rows with the same ID are replaced. SHA-256 values are read from the files (13 October 2026).
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
$acc = "2026-10-13"
$log = "05_Simulink_Model/results/step35_verification_log_2026-10-13.txt"
$chk = "05_Simulink_Model/results/step35_checks.csv"
$tab = "11_Results/tables/T4_10_simulink_verification.csv"
$fig = "11_Results/figures/F4_18_simulink_verification.png"
$sdi = "05_Simulink_Model/results/step35_sdi_session.mldatx"
$cm  = "05_Simulink_Model/code_manifest_step35.sha256"
Put (NewRow @{ id = "DF59"; category = "Derived file"; name = "Verification log and checks of the Simulink model (Step 35)"
  reference = "Written by verify_step35.m: two 24 h tests (rated load; load step 0.6 to 1.2 pu at 6 h) compared with the IEC 60076-7 equations (ode15s reference and closed form), 15 checks (decision D33)."
  accessed = $acc; how_obtained = $log; licence_terms = "Project file"; local_file = $log; sha256 = (Hsh $log); records = "15 checks"
  project_role = "Evidence for the Step 35 roadmap check"; used_in_steps = "35"; notes = ("Check table results/step35_checks.csv, SHA-256 " + (Hsh $chk)) })
Put (NewRow @{ id = "DF60"; category = "Derived file"; name = "Table 4.10 - Simulink verification"
  reference = "Largest difference (e_max), RMSE, final and peak values and ageing-rate difference of the model against the IEC 60076-7 equations, both tests, with the approved limits."
  accessed = $acc; how_obtained = $tab; licence_terms = "Project file"; local_file = $tab; sha256 = (Hsh $tab); records = "19 rows"
  project_role = "Table 4.10 of the thesis"; used_in_steps = "35" })
Put (NewRow @{ id = "DF61"; category = "Derived file"; name = "Figure 4.18 - Verification of the Simulink thermal model"
  reference = "Four panels (temperatures; model minus reference) for both tests; colours from 11_Results/figures/plot_style.csv. Also .pdf and the plotted numbers (.csv) in the same folder."
  accessed = $acc; how_obtained = $fig; licence_terms = "Project file"; local_file = $fig; sha256 = (Hsh $fig); records = "1 figure"
  project_role = "Figure 4.18 of the thesis"; used_in_steps = "35" })
Put (NewRow @{ id = "DF62"; category = "Derived file"; name = "Simulation Data Inspector session of the Step 35 runs"
  reference = "Both verification runs (K_pu, theta_oil_C, theta_hs_C, ageing_rate_V) saved with Simulink.sdi.save."
  accessed = $acc; how_obtained = $sdi; licence_terms = "Project file"; local_file = $sdi; sha256 = (Hsh $sdi); records = "2 runs"
  project_role = "Logged signals behind Figure 4.18 (roadmap: Simulation Data Inspector logs)"; used_in_steps = "35"; notes = "Binary MATLAB file; its hash changes on every save, so it is not part of any reproducibility test." })
Put (NewRow @{ id = "DF63"; category = "Derived file"; name = "Step 35 code (manifest)"
  reference = "verify_step35.m (new in Step 35)."; accessed = $acc; how_obtained = "Written in this project"; licence_terms = "Project file"
  local_file = $cm; sha256 = (Hsh $cm); records = "1 file"; project_role = "Fingerprint of the Step 35 code"; used_in_steps = "35" })
foreach ($r in $reg) { if ($r.id -in @("SW2", "SW5") -and $r.used_in_steps -notmatch "35") { $r.used_in_steps = ($r.used_in_steps.TrimEnd() + ", 35") }
  if ($r.id -in @("DF48", "DF52", "ST6", "SW4") -and $r.used_in_steps -notmatch "35") { $r.used_in_steps = ($r.used_in_steps.TrimEnd() + ", 35") } }
[IO.File]::WriteAllLines($regFile, ($reg | ConvertTo-Csv -NoTypeInformation), $utf8)
"register rows: " + $reg.Count
$glo = [System.Collections.ArrayList]@(Import-Csv $gloFile -Encoding UTF8)
$gcols = $glo[0].PSObject.Properties.Name
function G($grp, $term, $meaning, $plain, $pattern) { $o = [ordered]@{}; foreach ($c in $gcols) { $o[$c] = "" }; $o.group = $grp; $o.term = $term; $o.meaning = $meaning; $o.plain_explanation = $plain; $o.pattern = $pattern; [pscustomobject]$o }
foreach ($g in $glo) { if ($g.term -like "D1-D*(decisions)") { $g.term = "D1-D33 (decisions)"; $g.pattern = '[Dd]ecision D|\bD[3-9]\b|\bD[12][0-9]\b|\bD3[0-3]\b' } }
$new = @(
  (G "Simulink" "Simulation Data Inspector (SDI)" "MathWorks tool that stores and compares logged simulation signals" "A viewer in which the signals of each run are kept, so runs can be compared or saved as a session file." 'Simulation Data Inspector|\bSDI\b'),
  (G "Statistics" "e_max (largest difference)" "Largest absolute difference between model and reference over the compared time points" "The worst-case error of the model, in kelvin. It must stay within 0.1 K." 'e_max|e_\{max\}'),
  (G "Statistics" "RMSE (root-mean-square error)" "Square root of the mean of the squared differences" "A typical size of the error over the whole run, less sensitive to a single worst point than the largest difference." '\bRMSE\b'),
  (G "Simulink" "Closed-form solution" "Exact formula for the answer, with no numerical solver" "For a constant load the oil and winding temperatures follow simple exponential curves; this formula is an independent check of the model and of the numerical reference." '[Cc]losed.form'),
  (G "Transformer" "63 % rise time" "Time for a first-order quantity to reach 63.2 % (1 - 1/e) of its final change" "For the top-oil temperature this time equals the oil time constant times k11, i.e. 75 minutes here." '63 ?% rise|rise time'))
foreach ($n in $new) { for ($i = $glo.Count - 1; $i -ge 0; $i--) { if ($glo[$i].term -eq $n.term) { $glo.RemoveAt($i) } }; [void]$glo.Add($n) }
[IO.File]::WriteAllLines($gloFile, ($glo | ConvertTo-Csv -NoTypeInformation), $utf8)
"glossary rows: " + $glo.Count