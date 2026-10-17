# update_register_step33.ps1 - adds the sources and files of roadmap Step 33 (Simulink operating model) to
#   03_Data/provenance/data_and_source_register.csv and the new terms to 00_Project_Admin/abbreviations_glossary.csv.
#   Run after the Step 33 outputs exist (12 October 2026). Safe to re-run: rows with the same ID are replaced.
#   SHA-256 values are read from the files. Source details (pandapower, Alliander, IEC 60076-7) are those of the
#   MATLAB Build Guide, Section A4; they were not accessed again in Step 33.
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
$mdl = "05_Simulink_Model/Transformer_Operating_Model.slx"
$fig = "05_Simulink_Model/figures/Figure_3_4_top_level.png"
$chk = "05_Simulink_Model/results/step33_checks.csv"
$cm  = "05_Simulink_Model/code_manifest_step33.sha256"

Put (NewRow @{ id = "ST6"; category = "Standard"; name = "IEC 60076-7:2018, Loading guide for mineral-oil-immersed power transformers"
  reference = "IEC 60076-7:2018, Power transformers - Part 7: Loading guide for mineral-oil-immersed power transformers (Edition 2.0). The full text was NOT obtained; details TO VERIFY."
  accessed = "not accessed"; how_obtained = "Named as the basis of the thermal equations in the MATLAB Build Guide (Section A3/A4); not read in this project"
  licence_terms = "Copyright IEC; not stored in the project"; project_role = "Basis of the top-oil and hot-spot differential equations in SS5-SS7; the thermal constants of params_transformer.m must be checked against it (TO VERIFY)"
  used_in_steps = "33-35"; notes = "The thermal constants currently come from the Alliander implementation (SW4) default values, not from the standard itself." })
Put (NewRow @{ id = "SW3"; category = "Software"; name = "pandapower standard types (transformer 40 MVA 110/20 kV)"
  reference = "pandapower documentation, 'Basic Standard Types', transformer type '40 MVA 110/20 kV' (source code E1 of the MATLAB Build Guide, Section A4; accessed 3 Oct 2026 according to the guide)."
  link = "https://pandapower.readthedocs.io/en/latest/std_types/basic.html"; accessed = "2026-10-03 (per Build Guide)"
  how_obtained = "Cited from the Build Guide A4; not accessed again in Step 33"; licence_terms = "Documentation of an open-source package; licence not recorded here (TO VERIFY)"
  project_role = "Electrical rating of the transformer: S_rated, V_HV, V_LV, uk, ukr, P0, i0 (published typical data; replace with a real nameplate when a utility provides one)"
  used_in_steps = "33"; notes = "The page states that the types are for 50 Hz systems. pandapower lists a 150 degree vector group; the Simscape block offers only Delta 1 o'clock or 11 o'clock (decision D31)." })
Put (NewRow @{ id = "SW4"; category = "Software"; name = "Alliander transformer-thermal-model"
  reference = "Alliander N.V., transformer-thermal-model (IEC 60076-7 implementation, MPL-2.0), file transformer_thermal_model/transformer/power.py, class PowerTransformer, ONAF default specifications (source T1 of the Build Guide)."
  link = "https://github.com/alliander-opensource/transformer-thermal-model"; accessed = "2026-10-03 (per Build Guide)"
  how_obtained = "Cited from the Build Guide A4; not accessed again in Step 33"; licence_terms = "MPL-2.0 (per Build Guide)"
  project_role = "Default thermal constants of params_transformer.m (dTheta_or, g_r, H, tau_o, tau_w, k11, k21, k22, x, y) and the form of the thermal differential equations"
  used_in_steps = "33-35"; notes = "Default values, to be checked against IEC 60076-7:2018 (ST6) when the standard is obtained: TO VERIFY." })
Put (NewRow @{ id = "DF48"; category = "Derived file"; name = "Transformer operating model (Step 33)"
  reference = "Transformer_Operating_Model.slx, built in Step 33 by build_Transformer_Operating_Model.m from the MATLAB Build Guide Part B (decisions D30, D31); MATLAB R2025b."
  accessed = $acc; how_obtained = $mdl; licence_terms = "Project file"; local_file = $mdl; sha256 = (Hsh $mdl)
  records = "7 subsystems, 84 blocks, 2 physical networks"; project_role = "Operating-context model: load, current, oil and hot-spot temperature, ageing. Never generates gas values (D4)."
  used_in_steps = "33-37"; notes = "Reads every value from params_transformer.m (DF52); structure equal to the reference build (rerun_2026-10-11)." })
Put (NewRow @{ id = "DF49"; category = "Derived file"; name = "Figure 3.4 - top level of the transformer operating model (Step 33)"
  reference = "Screenshot of the top level of Transformer_Operating_Model.slx, printed from Simulink at 200 dpi. The seven subsystem diagrams are in 05_Simulink_Model/figures/diag_SS*.png."
  accessed = $acc; how_obtained = $fig; licence_terms = "Project file"; local_file = $fig; sha256 = (Hsh $fig)
  records = "1 figure (+ 7 subsystem diagrams)"; project_role = "Figure 3.4 of the thesis"; used_in_steps = "33" })
Put (NewRow @{ id = "DF50"; category = "Derived file"; name = "Automatic checks of the Simulink model (Step 33)"
  reference = "Produced by verify_step33.m: 9 checks (clean-path update and run, no warning, annotations, no typed number, no gas block, one solver per network, structure equal to the reference build, analytic steady state, equal result to the reference)."
  accessed = $acc; how_obtained = $chk; licence_terms = "Project file"; local_file = $chk; sha256 = (Hsh $chk)
  records = "9 checks"; project_role = "Evidence for the Step 33 check of the roadmap"; used_in_steps = "33"
  notes = "Also results/step33_structure_differences.csv (4 expected differences) and results/step33_block_settings.csv (every block setting made by the builder)" })
Put (NewRow @{ id = "DF51"; category = "Derived file"; name = "Step 33 code (manifest)"
  reference = "Code written or changed in Step 33: build_Transformer_Operating_Model.m, verify_step33.m, params_transformer.m (new variable T_zero_C_in_K only)."
  accessed = $acc; how_obtained = "Written in this project; fingerprints of the 3 files listed in the manifest"; licence_terms = "Project file"
  local_file = $cm; sha256 = (Hsh $cm); records = "3 files"; project_role = "Fingerprints of the Step 33 code"; used_in_steps = "33" })
Put (NewRow @{ id = "DF52"; category = "Derived file"; name = "Model parameters (params_transformer.m)"
  reference = "All parameters of the transformer operating model with unit and source (E1 pandapower, T1 Alliander). Step 33 added the constant T_zero_C_in_K = 273.15 K."
  accessed = $acc; how_obtained = "05_Simulink_Model/params_transformer.m"; licence_terms = "Project file"
  local_file = "05_Simulink_Model/params_transformer.m"; sha256 = (Hsh "05_Simulink_Model/params_transformer.m")
  records = "all model variables"; project_role = "The only place where model values are defined; read by the model callbacks"; used_in_steps = "33-37"
  notes = "Thermal constants are the default values of SW4 and must be checked against IEC 60076-7 (ST6): TO VERIFY." })
Put (NewRow @{ id = "DF53"; category = "Derived file"; name = "Reference build of the operating model (rerun 2026-10-11)"
  reference = "Transformer_Operating_Model.slx built by reference_build/build_transformer_model.m and re-run on 11 October 2026; used in Step 33 as the structure and result reference. The Step 33 model is compared with it block by block."
  accessed = $acc; how_obtained = "05_Simulink_Model/reference_build/rerun_2026-10-11/Transformer_Operating_Model.slx"; licence_terms = "Project file"
  local_file = "05_Simulink_Model/reference_build/rerun_2026-10-11/Transformer_Operating_Model.slx"
  sha256 = (Hsh "05_Simulink_Model/reference_build/rerun_2026-10-11/Transformer_Operating_Model.slx"); records = "84 blocks"
  project_role = "Reference for the Step 33 structure check"; used_in_steps = "33"
  notes = "Its start-up callbacks were made path-independent on 12 October 2026 (the file hash is that after this change; backup *_backup_before_callback_fix.slx kept)." })
foreach ($r in $reg) { if ($r.id -in @("SW2", "DF2") -and $r.used_in_steps -notmatch "(^|, |-)33") { $r.used_in_steps = ($r.used_in_steps.TrimEnd() + ", 33") } }
[IO.File]::WriteAllLines($regFile, ($reg | ConvertTo-Csv -NoTypeInformation), $utf8)
"register rows: " + $reg.Count

$glo = [System.Collections.ArrayList]@(Import-Csv $gloFile -Encoding UTF8)
$gcols = $glo[0].PSObject.Properties.Name
function G($grp, $term, $meaning, $plain, $pattern) { $o = [ordered]@{}; foreach ($c in $gcols) { $o[$c] = "" }; $o.group = $grp; $o.term = $term; $o.meaning = $meaning; $o.plain_explanation = $plain; $o.pattern = $pattern; [pscustomobject]$o }
foreach ($g in $glo) { if ($g.term -like "D1-D*(decisions)") { $g.term = "D1-D31 (decisions)"; $g.pattern = '[Dd]ecision D|\bD[3-9]\b|\bD[12][0-9]\b|\bD3[01]\b' } }
$new = @(
  (G "Simulink" "Simulink" "MathWorks block-diagram simulation environment" "Software in which the model is drawn as blocks and lines and simulated over time." '\bSimulink\b'),
  (G "Simulink" "Simscape" "Physical modelling extension of Simulink" "Blocks that follow physical laws (electrical, thermal) and connect like real components, not like signals." '\bSimscape\b'),
  (G "Simulink" "Subsystem (SS1-SS7)" "A group of blocks shown as one block" "The model is split into seven subsystems: grid, transformer, measurement, load, losses to heat, thermal network, outputs and ageing." '[Ss]ubsystem|\bSS[1-7]\b'),
  (G "Simulink" "Solver Configuration" "Block that sets the numerical solver of a physical network" "Every physical network (the electrical one and the thermal one) needs exactly one of these blocks." 'Solver Configuration'),
  (G "Simulink" "Annotation" "Text note placed on a model diagram" "A short description of what a subsystem does, its inputs, outputs and parameters, written on the diagram so that a reader does not need the code." '[Aa]nnotation'),
  (G "Transformer" "Top-oil temperature" "Temperature of the oil at the top of the tank" "The oil temperature used in the thermal model; it rises with load and falls back towards ambient." '[Tt]op.oil'),
  (G "Transformer" "Hot-spot temperature" "Temperature of the hottest part of the winding" "The winding temperature that mostly decides how fast the paper insulation ages; it is the top-oil temperature plus a load-dependent rise." '[Hh]ot.spot'),
  (G "Transformer" "Load factor K" "Load current divided by rated current" "K = 1 means the transformer carries its rated current; K = 0.5 means half of it." 'load factor|\bK_pu\b'),
  (G "Transformer" "Relative ageing rate V" "How many times faster than normal the paper ages" "V = 1 at the reference hot-spot temperature (98 degC); every 6 K more doubles it. The loss of life is the sum of V over time." 'ageing rate|[Aa]geing'),
  (G "Transformer" "per unit (pu)" "Value divided by its rated value" "A way of writing quantities so that 1.0 means rated, e.g. a current of 1.0 pu is the rated current." '\bpu\b|per.unit'),
  (G "Transformer" "IEC 60076-7" "IEC loading guide for oil-immersed power transformers" "The standard that gives the equations for oil and hot-spot temperature and for ageing under a changing load." 'IEC 60076-7'),
  (G "Simulink" "Frequency and time (equation formulation)" "Fast solver setting for power networks" "Lets a 50 Hz network be simulated with large time steps; it accepts only linear equations, which is why the arithmetic is done outside the physical network." 'Frequency and time')
)
foreach ($n in $new) { for ($i = $glo.Count - 1; $i -ge 0; $i--) { if ($glo[$i].term -eq $n.term) { $glo.RemoveAt($i) } }; [void]$glo.Add($n) }
[IO.File]::WriteAllLines($gloFile, ($glo | ConvertTo-Csv -NoTypeInformation), $utf8)
"glossary rows: " + $glo.Count
