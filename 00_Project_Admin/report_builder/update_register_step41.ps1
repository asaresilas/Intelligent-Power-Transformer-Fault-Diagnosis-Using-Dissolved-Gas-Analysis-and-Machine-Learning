# update_register_step41.ps1 - adds the files of roadmap Step 41 (test bench) to the register and glossary. Safe to re-run.
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
$acc = "2026-10-13"; $R = "10_Dashboard_Client/"
Put (NewRow @{ id = "DF76"; category = "Derived file"; name = "Test-bench log (Step 41)"
  reference = "testbench_log.csv: one row per held-out record (388): event, simulated time, record_id, data_role, gases as read, Rogers / IEC 60599 / Duval answers, ML status, class, 7 probabilities, confidence, model name/version/hash, agreement, simulated hot-spot, response time, conventional time, total time, warm-up flag. No true label. testbench_run_info.json: run conditions (service health and model hash before/after, schedule, machine)."
  accessed = $acc; how_obtained = ($R + "logs/testbench_log.csv"); licence_terms = "Project file"; local_file = ($R + "logs/testbench_log.csv"); sha256 = (Hsh ($R + "logs/testbench_log.csv")); records = "388 rows"
  project_role = "Input of Step 42 (fidelity, response time; Table 4.11, Figure 4.21)"; used_in_steps = "41, 42"
  notes = ("testbench_run_info.json SHA-256 " + (Hsh ($R + "logs/testbench_run_info.json")) + ". Times are of the project laptop; the log changes if the bench is run again (the times differ).") })
Put (NewRow @{ id = "DF77"; category = "Derived file"; name = "Test-bench checks (Step 41)"
  reference = "step41_checks.csv (12 checks of verify_step41.m) and the events file testbench_events.mat used for Figure 4.20."
  accessed = $acc; how_obtained = ($R + "results/step41_checks.csv"); licence_terms = "Project file"; local_file = ($R + "results/step41_checks.csv"); sha256 = (Hsh ($R + "results/step41_checks.csv")); records = "12 checks"
  project_role = "Evidence for the Step 41 check: one log row per record, no failed calls"; used_in_steps = "41"
  notes = ("Figure 4.20 files: F4_20_testbench_run.png SHA-256 " + (Hsh "11_Results/figures/F4_20_testbench_run.png") + ". MATLAB .mat file carries a save time.") })
Put (NewRow @{ id = "DF78"; category = "Derived file"; name = "Step 41 code (manifest)"
  reference = "run_testbench.m, verify_step41.m, tools/make_figure_4_20.m."; accessed = $acc; how_obtained = "Written in this project"; licence_terms = "Project file"
  local_file = ($R + "code_manifest_step41.sha256"); sha256 = (Hsh ($R + "code_manifest_step41.sha256")); records = "3 files"; project_role = "Fingerprints of the Step 41 code"; used_in_steps = "41" })
foreach ($x in $reg) { if ($x.id -in @("SW2", "SW5", "DF2", "DF48", "DF52") -and $x.used_in_steps -notmatch "41") { $x.used_in_steps = ($x.used_in_steps.TrimEnd() + ", 41") } }
[IO.File]::WriteAllLines($regFile, ($reg | ConvertTo-Csv -NoTypeInformation), $utf8)
"register rows: " + $reg.Count
$glo = [System.Collections.ArrayList]@(Import-Csv $gloFile -Encoding UTF8)
$gcols = $glo[0].PSObject.Properties.Name
function G($grp, $term, $meaning, $plain, $pattern) { $o = [ordered]@{}; foreach ($c in $gcols) { $o[$c] = "" }; $o.group = $grp; $o.term = $term; $o.meaning = $meaning; $o.plain_explanation = $plain; $o.pattern = $pattern; [pscustomobject]$o }
foreach ($g in $glo) { if ($g.term -like "D1-D*(decisions)") { $g.term = "D1-D39 (decisions)"; $g.pattern = '[Dd]ecision D|\bD[3-9]\b|\bD[12][0-9]\b|\bD3[0-9]\b' } }
$new = @(
  (G "Integration" "Test bench" "A programme that runs the whole framework over many records and logs the results" "The simulated transformer, the dashboard functions and the service are run together over all held-out records; every answer and time is written to a log file." '[Tt]est[- ]bench'),
  (G "Integration" "Warm-up call" "One of the first calls to the service, which can be slower than the later ones" "The first few requests set up the connection; they are flagged in the log so that they can be excluded or kept openly." '[Ww]arm-up'),
  (G "Integration" "Response time" "Time between sending a request to the service and receiving the answer" "How long the engineer waits for the ML diagnosis; reported as the median and the 95th percentile." '[Rr]esponse time'))
foreach ($n in $new) { for ($i = $glo.Count - 1; $i -ge 0; $i--) { if ($glo[$i].term -eq $n.term) { $glo.RemoveAt($i) } }; [void]$glo.Add($n) }
[IO.File]::WriteAllLines($gloFile, ($glo | ConvertTo-Csv -NoTypeInformation), $utf8)
"glossary rows: " + $glo.Count