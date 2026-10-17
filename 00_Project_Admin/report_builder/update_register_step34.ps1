# update_register_step34.ps1 - adds the sources and files of roadmap Step 34 (model checks) to
#   03_Data/provenance/data_and_source_register.csv and the new terms to 00_Project_Admin/abbreviations_glossary.csv.
#   Run after the Step 34 outputs exist (13 October 2026). Safe to re-run: rows with the same ID are replaced.
#   SHA-256 values are read from the files. Rows DF48, DF50 and DF52 of Step 33 are updated to the files as they are
#   after Step 34 (the Step 33 model is kept as DF58).
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
$acc = "2026-10-13"
$mdl  = "05_Simulink_Model/Transformer_Operating_Model.slx"
$old  = "05_Simulink_Model/checks/Transformer_Operating_Model_before_step34.slx"
$rep  = "05_Simulink_Model/checks/model_advisor_report.html"
$res  = "05_Simulink_Model/checks/model_advisor_results.csv"
$acp  = "05_Simulink_Model/checks/model_advisor_accepted.csv"
$d1   = "05_Simulink_Model/checks/step34_checklist_D1.csv"
$cm   = "05_Simulink_Model/code_manifest_step34.sha256"

# --- rows of Step 33 that Step 34 changed ---------------------------------------------------------------
foreach ($r in $reg) {
  if ($r.id -eq "DF48") { $r.sha256 = (Hsh $mdl); $r.notes = "Updated in Step 34 (13 Oct 2026, decision D32): Sqrt block, diagnostics at error level, Exp name shown, variable X0_pu. Hash = file after Step 34; the Step 33 version is DF58. Logged results unchanged (0.00e+00 difference)." }
  if ($r.id -eq "DF50") { $f = "05_Simulink_Model/results/step33_checks.csv"; $r.sha256 = (Hsh $f); $r.notes = "Re-run in Step 34 after the model changes: 9 of 9 checks pass, 7 expected differences from the reference build (was 5 in Step 33: Sqrt block type and algorithm, X0_pu). Other results/step33_*.csv rewritten by the same run." }
  if ($r.id -eq "DF51") { $r.notes = "Fingerprints as of Step 33. Three of the files (build_Transformer_Operating_Model.m, verify_step33.m, params_transformer.m) were changed in Step 34; current fingerprints are in DF57." }
  if ($r.id -eq "DF52") { $r.sha256 = (Hsh "05_Simulink_Model/params_transformer.m"); $r.notes = "Step 34 added X0_pu (0.5 pu, Simscape Electrical block default; TO VERIFY) and source tags on the ageing constants (A4, ref T2); thermal constants remain TO VERIFY against IEC 60076-7 (ST6). Hash = file after Step 34." }
}

Put (NewRow @{ id = "SW5"; category = "Software"; name = "Simulink Model Advisor (Simulink Check), MATLAB R2025b"
  reference = "The MathWorks, Inc. Simulink Check / Model Advisor, MATLAB R2025b (25.2.0.2998904). Function ModelAdvisor.run; check groups mathworks.design, mathworks.simscape, mathworks.simulink, mathworks.sl, mathworks.maab (132 checks)."
  link = "https://www.mathworks.com/help/slcheck/ref/modeladvisor.run.html"; accessed = $acc
  how_obtained = "Installed with MATLAB R2025b (Simulink Check licence on this computer); documentation read through MATLAB help ModelAdvisor.run"
  licence_terms = "Commercial MathWorks licence"; project_role = "Static model checks of Transformer_Operating_Model.slx (Step 34)"; used_in_steps = "34"
  notes = "Check titles and recommended values are MathWorks' own; the MAAB checks are style rules for control models and are not requirements of this project (decision D32)." })
Put (NewRow @{ id = "DF54"; category = "Derived file"; name = "Model Advisor report of the transformer operating model (Step 34)"
  reference = "model_advisor_report.html written by ModelAdvisor.run on Transformer_Operating_Model.slx (132 checks: 120 passed, 11 warnings, 1 incomplete, 0 failed)."
  accessed = $acc; how_obtained = $rep; licence_terms = "Project file"; local_file = $rep; sha256 = (Hsh $rep)
  records = "132 checks"; project_role = "Roadmap output of Step 34 (05_Simulink_Model/checks/model_advisor_report)"; used_in_steps = "34"
  notes = "Self-contained HTML; the matlab: links work only inside MATLAB. Result table: DF55." })
Put (NewRow @{ id = "DF55"; category = "Derived file"; name = "Model Advisor results and accepted warnings (Step 34)"
  reference = "model_advisor_results.csv (one row per check: id, name, status) and model_advisor_accepted.csv (the 12 non-passed checks with the number of flagged blocks and the written reason for accepting each; decision D32)."
  accessed = $acc; how_obtained = $res; licence_terms = "Project file"; local_file = $res; sha256 = (Hsh $res)
  records = "132 checks; 12 not passed"; project_role = "Evidence for the Step 34 check 'no unresolved errors remain'"; used_in_steps = "34"
  notes = ("model_advisor_accepted.csv SHA-256 " + (Hsh $acp)) })
Put (NewRow @{ id = "DF56"; category = "Derived file"; name = "Build Guide Part D1 checklist result (Step 34)"
  reference = "step34_checklist_D1.csv written by step34_checklist_D1.m: items D1.1-D1.5 (parameter file, typed numbers in all 84 blocks, annotations, update diagram and 24 h run against Section B12 within 0.1 K, run_transformer_simulation), D1.6 not applicable yet, D1.7 open, plus a bus test."
  accessed = $acc; how_obtained = $d1; licence_terms = "Project file"; local_file = $d1; sha256 = (Hsh $d1)
  records = "14 rows (13 pass, D1.7 open)"; project_role = "Evidence for the Step 34 roadmap check"; used_in_steps = "34"
  notes = ("Also step34_param_lines.csv (SHA-256 " + (Hsh "05_Simulink_Model/checks/step34_param_lines.csv") + ") and step34_block_numbers.csv (SHA-256 " + (Hsh "05_Simulink_Model/checks/step34_block_numbers.csv") + ").") })
Put (NewRow @{ id = "DF57"; category = "Derived file"; name = "Step 34 code (manifest)"
  reference = "Code written or changed in Step 34: checks/step34_run_model_advisor.m, step34_write_accepted.m, step34_checklist_D1.m; build_Transformer_Operating_Model.m, verify_step33.m, params_transformer.m (changed)."
  accessed = $acc; how_obtained = "Written in this project; fingerprints of the 6 files listed in the manifest"; licence_terms = "Project file"
  local_file = $cm; sha256 = (Hsh $cm); records = "6 files"; project_role = "Fingerprints of the Step 34 code"; used_in_steps = "34" })
Put (NewRow @{ id = "DF58"; category = "Derived file"; name = "Transformer operating model as built in Step 33 (kept for comparison)"
  reference = "Copy of Transformer_Operating_Model.slx taken before the Step 34 changes; its SHA-256 is the one that DF48 had at the end of Step 33."
  accessed = $acc; how_obtained = $old; licence_terms = "Project file"; local_file = $old; sha256 = (Hsh $old)
  records = "84 blocks"; project_role = "Shows what the Step 33 model looked like; used to document the Step 34 changes"; used_in_steps = "34" })
foreach ($r in $reg) { if ($r.id -in @("SW2") -and $r.used_in_steps -notmatch "(^|, |-)34") { $r.used_in_steps = ($r.used_in_steps.TrimEnd() + ", 34") } }
[IO.File]::WriteAllLines($regFile, ($reg | ConvertTo-Csv -NoTypeInformation), $utf8)
"register rows: " + $reg.Count

$glo = [System.Collections.ArrayList]@(Import-Csv $gloFile -Encoding UTF8)
$gcols = $glo[0].PSObject.Properties.Name
function G($grp, $term, $meaning, $plain, $pattern) { $o = [ordered]@{}; foreach ($c in $gcols) { $o[$c] = "" }; $o.group = $grp; $o.term = $term; $o.meaning = $meaning; $o.plain_explanation = $plain; $o.pattern = $pattern; [pscustomobject]$o }
foreach ($g in $glo) { if ($g.term -like "D1-D*(decisions)") { $g.term = "D1-D32 (decisions)"; $g.pattern = '[Dd]ecision D|\bD[3-9]\b|\bD[12][0-9]\b|\bD3[0-2]\b' } }
$new = @(
  (G "Simulink" "Model Advisor" "MathWorks tool that checks a Simulink model against a list of rules" "A built-in inspector. It runs many checks (settings, unconnected ports, style rules) and reports each as passed, warning or failed." 'Model Advisor'),
  (G "Simulink" "MAAB" "MathWorks Advisory Board (modelling style guidelines)" "A set of style rules for control-system models. Some of them do not suit a physical plant model and are accepted with a reason." '\bMAAB\b|\bmaab\b'),
  (G "Simulink" "Update Diagram" "Simulink command that compiles the model without running it" "Finds errors such as unconnected ports or wrong units before the simulation is run (Ctrl+D)." 'Update Diagram|update diagram'),
  (G "Transformer" "Zero-sequence reactance (X0)" "Reactance seen by currents that are equal in all three phases" "Matters only for unbalanced faults to earth; it has no effect when the three phases are loaded equally, as in this model." '[Zz]ero.sequence|\bX0_pu\b')
)
foreach ($n in $new) { for ($i = $glo.Count - 1; $i -ge 0; $i--) { if ($glo[$i].term -eq $n.term) { $glo.RemoveAt($i) } }; [void]$glo.Add($n) }
[IO.File]::WriteAllLines($gloFile, ($glo | ConvertTo-Csv -NoTypeInformation), $utf8)
"glossary rows: " + $glo.Count
