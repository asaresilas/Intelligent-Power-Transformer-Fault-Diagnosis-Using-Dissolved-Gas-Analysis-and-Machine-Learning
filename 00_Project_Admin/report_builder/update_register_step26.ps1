# update_register_step26.ps1 - adds the files of roadmap Step 26 to 03_Data/provenance/data_and_source_register.csv and the new
#   terms to 00_Project_Admin/abbreviations_glossary.csv. Run after the Step 26 outputs exist (12 October 2026).
#   Safe to re-run: rows with the same ID are replaced, not duplicated. The SHA-256 values are read from the files.
$ErrorActionPreference = "Stop"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$regFile = Join-Path $root "03_Data\provenance\data_and_source_register.csv"
$gloFile = Join-Path $root "00_Project_Admin\abbreviations_glossary.csv"
$utf8 = New-Object Text.UTF8Encoding($false)
function Hsh([string]$rel) { (Get-FileHash (Join-Path $root $rel) -Algorithm SHA256).Hash }   # not "H": alias of Get-History

$reg = [System.Collections.ArrayList]@(Import-Csv $regFile -Encoding UTF8)
$cols = $reg[0].PSObject.Properties.Name
function NewRow([hashtable]$h) { $o = [ordered]@{}; foreach ($c in $cols) { $o[$c] = if ($h.ContainsKey($c)) { [string]$h[$c] } else { "" } }; [pscustomobject]$o }
function Put($row) {
  for ($i = $reg.Count - 1; $i -ge 0; $i--) { if ($reg[$i].id -eq $row.id) { $reg.RemoveAt($i) } }
  [void]$reg.Add($row)
}
$acc = "2026-10-12"
$app = "11_Results/conventional/conventional_applicability.csv"
$chk = "11_Results/conventional/conventional_applicability_checks.csv"
$xl  = "08_Statistical_Analysis/cross_language_check_step26.csv"
$cm  = "04_MATLAB_Conventional/code_manifest_step26.sha256"

Put (NewRow @{ id = "DF29"; category = "Derived file"; name = "Conventional methods with gases removed (Step 26)"
  reference = "Produced in Step 26 by run_reduced_gas_applicability.m (decision D23): share of ND per gas combination, method and data role."
  accessed = $acc; how_obtained = $app; licence_terms = "Project file"; local_file = $app; sha256 = (Hsh $app)
  records = "465 rows = 31 gas combinations x 3 methods x 5 data roles"
  project_role = "Shows which conventional method can still give a diagnosis when gases are not measured; input of Step 27 comparison"
  used_in_steps = "26-27"
  notes = "Inputs: dga_master.csv (DF2) and reduced_gas_subsets.csv (DF28); n_nd is after the normality gate; n_nd_gate_measured is the sensitivity of decision D23 rule 4" })
Put (NewRow @{ id = "DF30"; category = "Derived file"; name = "Automatic checks of Step 26"
  reference = "Produced in Step 26 by run_reduced_gas_applicability.m: the 10 checks of the roadmap and of the input file."
  accessed = $acc; how_obtained = $chk; licence_terms = "Project file"; local_file = $chk; sha256 = (Hsh $chk)
  records = "10 checks"; project_role = "Evidence that the table is correct (five-gas row = Steps 14-17, ND = 100 % where a gas is needed)"
  used_in_steps = "26" })
Put (NewRow @{ id = "DF31"; category = "Derived file"; name = "MATLAB-Python agreement for Step 26"
  reference = "Produced in Step 26 by step26_crosscheck.py: every row of DF29 recomputed with the independent Python implementation of Step 18."
  accessed = $acc; how_obtained = $xl; licence_terms = "Project file"; local_file = $xl; sha256 = (Hsh $xl)
  records = "465 rows"; project_role = "Independent check of DF29 (identical on 465 of 465 rows)"; used_in_steps = "26" })
Put (NewRow @{ id = "DF32"; category = "Derived file"; name = "Step 26 code (manifest)"
  reference = "Code written or changed in Step 26: reduced_gas_diagnosis.m, run_reduced_gas_applicability.m, tests/TestReducedGas.m, conv_config.m (new fields only), tests/run_tests_and_log.m, step26_crosscheck.py, test_step26_crosscheck.py."
  accessed = $acc; how_obtained = "Written in this project; fingerprints of the 7 files listed in the manifest"; licence_terms = "Project file"
  local_file = $cm; sha256 = (Hsh $cm); records = "7 files"
  project_role = "Fingerprints of the Step 26 code; code_manifest.sha256 (DF8) stays the record of Steps 14-17"; used_in_steps = "26"
  notes = "conv_config.m and tests/run_tests_and_log.m are also listed in DF8 with their Step 14-17 fingerprints; only fields and the test list were added, no rule changed" })

foreach ($r in $reg) {
  if ($r.id -in @("ST1", "ST5", "M9", "DF2", "DF6", "DF8", "DF10", "DF28", "SW1", "SW2") -and $r.used_in_steps -notmatch "(^|, )26") { $r.used_in_steps = ($r.used_in_steps.TrimEnd() + ", 26") }
}

# DF13 (unit-test log): the Step 26 run of run_tests_and_log.m overwrote the Step 15 log (67 tests) with the log of both test classes (93 tests = 67 + 26).
foreach ($r in $reg) { if ($r.id -eq "DF13") {
  $r.sha256 = (Hsh "04_MATLAB_Conventional/tests/test_log.txt")
  if ($r.notes -notmatch "Step 26") { $r.notes = ($r.notes.TrimEnd() + " Overwritten in Step 26 by the run of both test classes: 93 tests (67 of Step 15 + 26 of TestReducedGas), all passed; the 67-test log of Step 15 is not kept.").Trim() }
  if ($r.used_in_steps -notmatch "(^|, )26") { $r.used_in_steps = ($r.used_in_steps.TrimEnd() + ", 26") } } }[IO.File]::WriteAllLines($regFile, ($reg | ConvertTo-Csv -NoTypeInformation), $utf8)
"register rows: " + $reg.Count

$glo = [System.Collections.ArrayList]@(Import-Csv $gloFile -Encoding UTF8)
$gcols = $glo[0].PSObject.Properties.Name
function G($grp, $term, $meaning, $plain, $pattern) { $o = [ordered]@{}; foreach ($c in $gcols) { $o[$c] = "" }; $o.group = $grp; $o.term = $term; $o.meaning = $meaning; $o.plain_explanation = $plain; $o.pattern = $pattern; [pscustomobject]$o }
foreach ($g in $glo) { if ($g.term -like "D1-D*(decisions)") { $g.term = "D1-D23 (decisions)"; $g.pattern = '[Dd]ecision D|\bD[3-9]\b|\bD1[0-9]\b|\bD2[0-3]\b' } }
$new = @(
  (G "Methods" "NaN (not measured)" "Not a Number, used here for a gas that was not measured" "A marker for a missing value. It is different from 0 ppm: 0 ppm means the gas was measured and not found, NaN means nobody measured it, so no ratio or percentage can be calculated from it." '\bNaN\b|not measured'),
  (G "Methods" "Applicable (method)" "A method that has all the gases it needs" "A method is applicable to a gas combination when every gas it uses is measured. IEC 60599 and Rogers need all five gases; Duval Triangle 1 needs CH4, C2H4 and C2H2. If a method is not applicable it answers ND for every sample." '[Aa]pplicab'),
  (G "Methods" "Gas combination (subset)" "A choice of the gases that are measured" "One of the 31 ways to keep at least one of the five gases, as with an online monitor that measures only some gases." '[Gg]as combination|gas subset')
)
foreach ($n in $new) { for ($i = $glo.Count - 1; $i -ge 0; $i--) { if ($glo[$i].term -eq $n.term) { $glo.RemoveAt($i) } }; [void]$glo.Add($n) }
[IO.File]::WriteAllLines($gloFile, ($glo | ConvertTo-Csv -NoTypeInformation), $utf8)
"glossary rows: " + $glo.Count
