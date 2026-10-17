$ErrorActionPreference = "Stop"
# build_step_report_33.ps1 - Word report of roadmap Step 33. Every number is read from 05_Simulink_Model/results
# (checks, structure differences, block settings, block inventory, run summary); statements are throw-checked.
# Variable names start with k_ because the dot-sourced helper scripts also use short names ($app, $full, $cnt ...).
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report33_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8
$inv = [Globalization.CultureInfo]::InvariantCulture
function Num([string]$v, [string]$fmt) { ([double]::Parse($v, $inv)).ToString($fmt, $inv) }

$k_res  = Join-Path $root "05_Simulink_Model\results"
$k_chk  = Import-Csv (Join-Path $k_res "step33_checks.csv")
$k_diff = Import-Csv (Join-Path $k_res "step33_structure_differences.csv")
$k_set  = Import-Csv (Join-Path $k_res "step33_block_settings.csv")
$k_inv  = Import-Csv (Join-Path $k_res "step33_block_inventory.csv")
$k_run  = (Import-Csv (Join-Path $k_res "step33_run_summary.csv"))[0]
$k_fig  = Join-Path $root "05_Simulink_Model\figures"
foreach ($c in $k_chk) { if ($c.passed -notin @("1", "true", "True")) { throw ("a Step 33 check failed: " + $c.check) } }
if ($k_chk.Count -ne 9) { throw "expected 9 checks" }
if ($k_inv.Count -ne 7) { throw "expected 7 subsystems" }
$k_nBlocks = 7 + ($k_inv | ForEach-Object { [int]$_.n_blocks } | Measure-Object -Sum).Sum
$k_nNotesSub = ($k_inv | ForEach-Object { [int]$_.n_annotations } | Measure-Object -Sum).Sum
$k_ann = ($k_chk | Where-Object { $_.check -like "model and all 7 subsystems*" }).detail
if ($k_ann -notmatch "(\d+) annotations in all") { throw "annotation check text: $k_ann" }
$k_nNotes = [int]$Matches[1]                      # all annotations of the model (subsystems + top level)
if ($k_nNotes -ne $k_nNotesSub + 2) { throw "annotation count: expected subsystems + 2 top-level notes" }
$k_cmp = ($k_chk | Where-Object { $_.check -like "structure equals*" }).detail
if ($k_cmp -notmatch "(\d+) blocks compared; (\d+) expected differences .*; 0 unexpected") { throw "structure check text: $k_cmp" }
$k_nCompared = $Matches[1]
if ([int]$Matches[2] -ne $k_diff.Count) { throw "difference file does not match the check" }
foreach ($d in $k_diff) { if ($d.value_new -notmatch "T_zero_C_in_K" -or $d.value_ref -notmatch "273\.15") { throw "unexpected difference: $($d.item)" } }
$k_log = Get-Content (Join-Path $root "04_MATLAB_Conventional\tests\test_log.txt") -Encoding utf8
$k_matlab = (($k_log | Where-Object { $_ -like "MATLAB:*" } | Select-Object -First 1) -replace "^MATLAB:\s*", "").Trim()
$k_stat = ($k_chk | Where-Object { $_.check -like "24 h run*" }).detail
if ($k_stat -notmatch "diff 0\.000 K\); hot-spot .* \(diff 0\.000 K\)") { throw "steady-state check text: $k_stat" }

$global:S33 = @{ nBlocks = $k_nBlocks; nNotes = $k_nNotes; nChecks = $k_chk.Count; nCompared = $k_nCompared
  matlab = $k_matlab; completed = "12 October 2026"
  k = (Num $k_run.K_pu_final "0.0000"); oil = (Num $k_run.theta_oil_C_final "0.000"); hs = (Num $k_run.theta_hs_C_final "0.000")
  checks = ("" + $k_chk.Count + " of " + $k_chk.Count + " automatic checks PASS (verify_step33.m); structure = reference build (" + $k_nCompared + " blocks, 0 unexpected differences)") }

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
. (Join-Path $sp "report_entries_33.ps1")

function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed) {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "33" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "33" "Rebuild the transformer operating model" "Claude Code (this chat), MATLAB and Simulink through the MCP connection" $S33.completed
Summary ("The transformer operating model (Transformer_Operating_Model.slx) was rebuilt from Part B of the MATLAB Build Guide by a MATLAB program: 7 subsystems, " + $k_nBlocks + " blocks, two physical networks (electrical and thermal), " + $k_nNotes + " annotations. The model updates and simulates without any error or warning from a clean MATLAB path, and all " + $k_chk.Count + " automatic checks pass. Its structure is identical to the reference build (" + $k_nCompared + " blocks compared; the only difference is the 273.15 K offset, which is now a named variable). A 24-hour run at rated demand gives a load factor of " + $S33.k + ", a final top-oil temperature of " + $S33.oil + " degC and a hot-spot temperature of " + $S33.hs + " degC, equal to the steady state of the IEC 60076-7 equations. The model never produces a gas value. Several points in the guide were reviewed and are listed in this report; the thermal constants are still TO VERIFY against IEC 60076-7.")
H1N "Purpose of this step"
Body "The Simulink model supplies the operating context of the framework: how load, current, oil temperature, hot-spot temperature and insulation ageing of the 40 MVA transformer change over time. It does not take part in any diagnosis and never generates gas values (decision D4). This step builds the model; Steps 34 to 37 check it, verify it, run the scenarios and add the sampling-event subsystem."
MethodSection "33"
H1N "What was used"
Bullet "MATLAB Build Guide, Part B (sections B1 to B13) and Part A4 (sources of the parameters)."
Bullet "05_Simulink_Model/params_transformer.m: every value of the model, with unit and source."
Bullet "The reference build (05_Simulink_Model/reference_build, re-run on 11 October 2026), used only to check the new model."
H1N "Review of the Build Guide (points found before building)"
Body "As asked, the guide was reviewed before it was followed. The model equations agree with the IEC 60076-7 differential-equation form (oil rise with exponent x; two hot-spot components with k21, k22 and exponent y). The following points were found; each is handled as stated."
AddTable @("#", "Point found", "What was done") @(
  , @("1", "The guide says that no number is typed into a block, but it types 273.15 (0 degC in kelvin) into four blocks.", "New variable T_zero_C_in_K in params_transformer.m; the blocks use it (D31, clause 2).")
  , @("2", "The start-up callbacks 'params_transformer;' work only if the model folder is on the MATLAB path (the same weakness as in the rerun model).", "The callbacks add the model folder to the path when the script is not found (D31, clause 1); tested from a clean path.")
  , @("3", "The roadmap and CLAUDE.md say 'pure Simscape', but the guide builds SS5, SS7 and the square root of SS3 from Simulink blocks.", "Kept, because the guide documents why (the 'Frequency and time' formulation accepts only switched-linear equations). Described as 'Simscape networks with Simulink arithmetic' (D31, clause 4, to be confirmed).")
  , @("4", "The thermal constants are default values of the Alliander open-source implementation, not values from IEC 60076-7 or a test report; the standard was not obtained.", "Unchanged and marked TO VERIFY; ST6 and SW4 added to the register.")
  , @("5", "The electrical data are the pandapower typical standard type (not a nameplate) and its 150 degree vector group cannot be built (the block offers Delta 1 or 11 o'clock).", "Delta 1 o'clock used and stated on the diagram; no effect on current magnitudes, losses or temperatures.")
  , @("6", ("At a demand of K = 1.0 the measured load factor is slightly lower (" + $S33.k + " in the run), because the load sits behind the transformer impedance (16.2 % short-circuit impedance), so the voltage at the load is a little below rated."), "Explained in an annotation in SS4; the thermal chain uses the measured K of SS3, as in the guide.")
  , @("7", "The guide's 'Simulink Agentic Toolkit' was not installed (Steps 2 and 3 were replaced for MATLAB by the MCP connection in D14).", "The same connection was used for Simulink (D30, to be confirmed).")
) @(20, 230, 200)
H1N "What was done, step by step"
NumItem "1" "Reviewed the guide and the reference build script and recorded decisions D30 and D31 before building."
NumItem "2" "Added the variable T_zero_C_in_K to params_transformer.m."
NumItem "3" "Wrote build_Transformer_Operating_Model.m (sections B2 to B11 of the guide, plus the extra annotations) and built the model."
NumItem "4" "Wrote verify_step33.m (9 checks) and ran it from a clean MATLAB path. Two of my own checks first gave false alarms and were corrected (see Problems and fixes)."
NumItem "5" "Exported Figure 3.4 and the seven subsystem diagrams, tidied the layout of SS6, rebuilt and checked again."
NumItem "6" "Wrote this report and updated the register, the glossary, the READMEs, CHANGELOG.md and SESSION_SUMMARY.md."
H1N "What we found"
H2 "The model"
Body "Colour code in the model: blue = Simscape Electrical, green = Simulink arithmetic, orange = Simscape thermal network. Blue lines are physical connections, black lines are Simulink signals."
Caption "Figure 3.4  Top level of Transformer_Operating_Model (built and simulated in MATLAB R2025b)"
Pic (Join-Path $k_fig "Figure_3_4_top_level.png") 450
$k_rows = @(); foreach ($r in $k_inv) { $k_rows += , @($r.subsystem, $r.domain, $r.n_blocks, $r.n_inputs, $r.n_outputs, $r.n_annotations) }
AddTable @("Subsystem", "Domain", "Blocks", "Inputs", "Outputs", "Annotations") $k_rows @(125, 125, 50, 45, 55, 75)
Body ("Total: " + $k_nBlocks + " blocks (the seven subsystem blocks plus the blocks inside them) and " + $k_nNotes + " annotations (" + $k_nNotesSub + " in the subsystems and 2 at the top level). Inputs and outputs count physical ports and signal ports.")
H2 "Annotations"
Body "Every subsystem carries the annotation text of the Build Guide (what it does, inputs, outputs, parameters) and further notes where a reader would otherwise have to look in the code: the units along the measurement chain (SS3), the reason why the measured K is lower than the demanded K (SS4), the meaning of the gains (SS5), the circuit pattern and the two sensor types (SS6), and the ageing formula (SS7). Each subsystem also has a Description (shown in its block properties)."
H2 "Simulation result"
$k_rows = @(
  , @("Load factor K measured in SS3 (demand 1.0)", $S33.k, "pu")
  , @("Final top-oil temperature (24 h)", $S33.oil, "degC")
  , @("Final hot-spot temperature (24 h)", $S33.hs, "degC")
  , @("Relative ageing rate at the end", (Num $k_run.ageing_rate_V_final "0.000"), "-")
  , @("Equivalent ageing in 24 h (integral of V)", (Num $k_run.loss_of_life_h_24h "0.0"), "h")
)
AddTable @("Quantity", "Value", "Unit") $k_rows @(260, 80, 60)
Body "The analytic steady state of the IEC 60076-7 equations, calculated independently from params_transformer.m and the measured K, gives the same temperatures (difference below 0.001 K). The simulation of this model and of the reference build give identical signals."
H2 "Subsystem diagrams"
$k_ids = @("SS1_Grid_Supply", "SS2_Power_Transformer", "SS3_LV_Measurement", "SS4_Variable_Load", "SS5_Losses_to_Heat", "SS6_Thermal_Network", "SS7_Outputs_and_Ageing")
foreach ($id in $k_ids) {
  Caption ("Diagram of " + $id)
  Pic (Join-Path $k_fig ("diag_" + $id + ".png")) 450
}
H1N "Checks"
$k_rows = @(); foreach ($c in $k_chk) { $k_rows += , @($c.check, "PASS") }
AddTable @("Check (verify_step33.m)", "Result") $k_rows @(360, 90)
Body ("Detail of the structure check: " + $k_cmp + ". Detail of the steady-state check: " + $k_stat + ". The block settings made by the builder (" + $k_set.Count + " settings) are listed in 05_Simulink_Model/results/step33_block_settings.csv.")
H1N "Problems and fixes"
Bullet "Decision numbers: the first draft numbered the new decisions D24 and D25, but those numbers had already been used in Steps 27 to 31. They were renumbered D30 and D31 before anything was registered."
Bullet "My structure check first loaded the reference model under the same file name as the new model, so Simulink loaded the new model twice and reported a difference of exactly zero, which proved nothing. The reference is now loaded from a renamed copy. The check was confirmed to detect differences: it finds the four expected 273.15 K differences."
Bullet "My check helper stored only the last check because it had captured an empty table; it was rewritten as a function."
Bullet "Two checks gave false alarms and were corrected: the 'no gas block' check treated Q_h2 (heat input of hot-spot circuit 2) as hydrogen, so gas formulas are now matched case-sensitively as whole words; the 'no typed number' check flagged the selector 0 of the ideal source (0 = no source impedance) and log(2) (doubling of the ageing rate), which are not values."
Bullet "In the first export of SS6 the Thermal_Reference and the solver block overlapped. The shared blocks were moved apart, the notes moved down, and the model was rebuilt and checked again."
Bullet "In PowerShell the name R is an alias of Invoke-History; a helper of that name did nothing. The edit was made directly instead."
H1N "Decisions"
Bullet "D30 (proposed): the Simulink steps 33 to 37 are run through the MATLAB MCP connection, as in D14 for MATLAB; the 'Simulink Agentic Toolkit' of the roadmap is not installed."
Bullet "D31: Step 33 build details: path-safe callbacks; T_zero_C_in_K; extra annotations and colour code; Simulink arithmetic in SS3, SS5 and SS7 as in the Build Guide (clause 4 proposed: the model is described as Simscape networks with Simulink arithmetic); the model is built by script and compared with the reference build."
H1N "Files produced"
Bullet "05_Simulink_Model/Transformer_Operating_Model.slx"
Bullet "05_Simulink_Model/figures/Figure_3_4_top_level.png and diag_SS1 ... SS7 (.png)"
Bullet "05_Simulink_Model/build_Transformer_Operating_Model.m, verify_step33.m, code_manifest_step33.sha256; params_transformer.m (one new variable)"
Bullet "05_Simulink_Model/results/: step33_checks.csv, step33_structure_differences.csv, step33_block_settings.csv, step33_block_inventory.csv, step33_run_summary.csv"
Closing "33" 0 "Step 34 (Simulink): run Model Advisor and the checks of Build Guide Part D1 on this model, fix every issue or record why it is accepted." $global:Blocks["33"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_33_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_33_Report.docx") -Force
("SAVED Step_33_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber + "`n" + $_.ScriptStackTrace) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
