# update_register_step42.ps1 - adds the files of roadmap Step 42 (integration evaluation) to the register and glossary. Safe to re-run.
$ErrorActionPreference = "Stop"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$regFile = Join-Path $root "03_Data\provenance\data_and_source_register.csv"
$gloFile = Join-Path $root "00_Project_Admin\abbreviations_glossary.csv"
$utf8 = New-Object Text.UTF8Encoding($false)
function Hsh([string]$rel) { (Get-FileHash (Join-Path $root $rel) -Algorithm SHA256).Hash }
$reg = [System.Collections.ArrayList]@(Import-Csv $regFile -Encoding UTF8)
$cols = $reg[0].PSObject.Properties.Name
foreach ($x in $reg) { if ($x.id -in @("DF82", "DF83", "DF84", "DF85") -and $x.used_in_steps -notmatch "\b42\b") { throw ("ID " + $x.id + " is already used by another step: " + $x.name) } }
function NewRow([hashtable]$h) { $o = [ordered]@{}; foreach ($c in $cols) { $o[$c] = if ($h.ContainsKey($c)) { [string]$h[$c] } else { "" } }; [pscustomobject]$o }
function Put($row) { for ($i = $reg.Count - 1; $i -ge 0; $i--) { if ($reg[$i].id -eq $row.id) { $reg.RemoveAt($i) } }; [void]$reg.Add($row) }
$acc = "2026-10-13"; $I = "11_Results/integration/"
Put (NewRow @{ id = "DF82"; category = "Derived file"; name = "Table 4.11 - Integration fidelity and response time (Step 42)"
  reference = "Produced by 06_Python_ML/src/analysis/step42_integration.py from DF76 (test-bench log), DF25 (ML predictions) and DF9 (conventional predictions, column result); decision D40."
  accessed = $acc; how_obtained = "Program output"; licence_terms = "Project file"; local_file = "11_Results/tables/T4_11_integration.csv"; sha256 = (Hsh "11_Results/tables/T4_11_integration.csv"); records = "19 rows"
  project_role = "Table 4.11 of the thesis (research question on the integrated framework)"; used_in_steps = "42, Chapter 4" })
Put (NewRow @{ id = "DF83"; category = "Derived file"; name = "Figure 4.21 - Response times of the test bench (Step 42)"
  reference = "Two panels: (a) response time of every request in run order with median, 95th percentile and warm-up calls; (b) cumulative distribution with the 1000 ms target. .pdf and .csv (plotted numbers) beside the .png."
  accessed = $acc; how_obtained = "Program output"; licence_terms = "Project file"; local_file = "11_Results/figures/F4_21_response_times.png"; sha256 = (Hsh "11_Results/figures/F4_21_response_times.png"); records = "388 requests"
  project_role = "Figure 4.21 of the thesis"; used_in_steps = "42, Chapter 4"
  notes = ("F4_21_response_times.csv SHA-256 " + (Hsh "11_Results/figures/F4_21_response_times.csv")) })
Put (NewRow @{ id = "DF84"; category = "Derived file"; name = "Integration comparison and checks (Step 42)"
  reference = "integration_checks.json (fidelity counts, time statistics, pass flag), integration_comparison.csv (one row per held-out record: offline and logged answers, match flags, response time), integration_mismatches.csv (records that differ; header only when none)."
  accessed = $acc; how_obtained = "Program output"; licence_terms = "Project file"; local_file = ($I + "integration_checks.json"); sha256 = (Hsh ($I + "integration_checks.json")); records = "388 records; 0 mismatches"
  project_role = "Evidence for the 100 % fidelity requirement (Analysis Plan Section 10)"; used_in_steps = "42"
  notes = ("integration_comparison.csv SHA-256 " + (Hsh ($I + "integration_comparison.csv")) + "; integration_mismatches.csv SHA-256 " + (Hsh ($I + "integration_mismatches.csv")) + ". True labels not read.") })
Put (NewRow @{ id = "DF85"; category = "Derived file"; name = "Step 42 code (manifest)"
  reference = "06_Python_ML/src/analysis/step42_integration.py, 06_Python_ML/tests/test_integration.py and make_chapter4.py (Step 42 added to the one-command rebuild; MATLAB outputs protected)."
  accessed = $acc; how_obtained = "Written in this project"; licence_terms = "Project file"; local_file = ($I + "code_manifest_step42.sha256"); sha256 = (Hsh ($I + "code_manifest_step42.sha256")); records = "3 files"
  project_role = "Fingerprints of the Step 42 code"; used_in_steps = "42" })
foreach ($x in $reg) {
  if ($x.id -eq "DF47") { $x.sha256 = (Hsh "11_Results/chapter4_manifest.sha256"); $x.records = "83 files"
    $x.notes = "Updated in Step 42: 83 files (Table 4.11 and Figure 4.21 added; Table 4.10 and Figures 4.18-4.20, 4.22 are made in MATLAB and are not part of the Python rebuild). Rebuild check identical (11_Results/chapter4_check.txt)." }
  if ($x.id -in @("SW1", "DF9", "DF25", "DF47", "DF76") -and $x.used_in_steps -notmatch "\b42\b") { $x.used_in_steps = ($x.used_in_steps.TrimEnd() + ", 42") }
}
[IO.File]::WriteAllLines($regFile, ($reg | ConvertTo-Csv -NoTypeInformation), $utf8)
"register rows: " + $reg.Count
$glo = [System.Collections.ArrayList]@(Import-Csv $gloFile -Encoding UTF8)
$gcols = $glo[0].PSObject.Properties.Name
function G($grp, $term, $meaning, $plain, $src, $pattern) { $o = [ordered]@{}; foreach ($c in $gcols) { $o[$c] = "" }; $o.group = $grp; $o.term = $term; $o.meaning = $meaning; $o.plain_explanation = $plain; $o.source = $src; $o.pattern = $pattern; [pscustomobject]$o }
foreach ($g in $glo) { if ($g.term -like "D1-D*(decisions)") { $g.term = "D1-D40 (decisions)"; $g.pattern = '[Dd]ecision D|\bD[3-9]\b|\bD[12][0-9]\b|\bD3[0-9]\b|\bD40\b' } }
$new = @(
  (G "Statistics" "Cumulative distribution" "share of measurements at or below each value" "Read across from a time on the horizontal axis to see what percentage of requests were answered at least that fast." "" '[Cc]umulative distribution'),
  (G "Methods" "Test bench" "the integrated system run over every held-out record" "Simulink model, MATLAB dashboard functions and the Python service working together, with every answer and its time written to a log (Step 41)." "" '[Tt]est[- ]bench'))
foreach ($n in $new) { for ($i = $glo.Count - 1; $i -ge 0; $i--) { if ($glo[$i].term -eq $n.term) { $glo.RemoveAt($i) } }; [void]$glo.Add($n) }
[IO.File]::WriteAllLines($gloFile, ($glo | ConvertTo-Csv -NoTypeInformation), $utf8)
"glossary rows: " + $glo.Count
