$ErrorActionPreference = "Stop"
# build_step_report_34.ps1 - Word report of roadmap Step 34 (model checks). Every number is read from
# 05_Simulink_Model/checks and 05_Simulink_Model/results; statements are throw-checked. The only typed numbers are those of the
# FIRST Model Advisor run (its raw file was overwritten by the later runs): they are program output of 13 October 2026.
# Variable names start with k_ because the dot-sourced helper scripts also use short names.
# ASCII only (Windows PowerShell 5.1 reads scripts without a byte-order mark in the ANSI code page).
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report34_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8

$k_dir  = Join-Path $root "05_Simulink_Model\checks"
$k_ma   = Import-Csv (Join-Path $k_dir "model_advisor_results.csv")
$k_acc  = Import-Csv (Join-Path $k_dir "model_advisor_accepted.csv")
$k_d1   = Import-Csv (Join-Path $k_dir "step34_checklist_D1.csv")
$k_bn   = Import-Csv (Join-Path $k_dir "step34_block_numbers.csv")
$k_pl   = Import-Csv (Join-Path $k_dir "step34_param_lines.csv")
$k_c33  = Import-Csv (Join-Path $root "05_Simulink_Model\results\step33_checks.csv")
$k_nSet = (Import-Csv (Join-Path $root "05_Simulink_Model\results\step33_block_settings.csv")).Count
function IsTrue($v) { $v -in @("1", "true", "True") }

# --- Model Advisor summary ------------------------------------------------------------------------------------
$k_n = $k_ma.Count
$k_pass = @($k_ma | Where-Object { $_.status -eq "Passed" }).Count
$k_warn = @($k_ma | Where-Object { $_.status -eq "Warning" }).Count
$k_fail = @($k_ma | Where-Object { $_.status -eq "Failed" }).Count
$k_inc  = @($k_ma | Where-Object { $_.status -eq "Incomplete" }).Count
if ($k_n -ne 132) { throw "expected 132 checks" }
if ($k_pass + $k_warn + $k_fail + $k_inc -ne $k_n) { throw "status classes do not add up" }
if ($k_fail -ne 0) { throw "a Model Advisor check failed" }
if ($k_acc.Count -ne $k_warn + $k_inc) { throw "accepted table does not cover every non-passed check" }
foreach ($a in $k_acc) { if (-not $a.reason_accepted) { throw ("no reason for " + $a.check_id) } }
$k_firstSummary = "115 passed, 16 warnings, 1 incomplete, 0 failed"
$k_finalSummary = "$k_pass passed, $k_warn warnings, $k_inc incomplete, $k_fail failed"

# --- checklist ------------------------------------------------------------------------------------------------
if ($k_d1.Count -ne 14) { throw "expected 14 checklist rows" }
$k_open = @($k_d1 | Where-Object { -not (IsTrue $_.passed) })
if ($k_open.Count -ne 1 -or $k_open[0].item -ne "D1.7") { throw "expected D1.7 as the only open row" }
$k_d1Pass = @($k_d1 | Where-Object { IsTrue $_.passed }).Count
$k_row2 = $k_d1 | Where-Object { $_.item -eq "D1.2" }
if ($k_row2.detail -notmatch "^(\d+) blocks; values containing a digit: (\d+) = .*typed parameter numbers: 0 ") { throw ("D1.2 text: " + $k_row2.detail) }
$k_nBlocks = $Matches[1]; $k_nFlagged = $Matches[2]
$k_t = ($k_d1 | Where-Object { $_.what -like "24 h run: load factor*" }).detail
if ($k_t -notmatch "K = ([0-9.]+)") { throw "K text" }; $k_K = $Matches[1]
$k_t = ($k_d1 | Where-Object { $_.what -like "24 h run: top-oil*" }).detail
if ($k_t -notmatch "^([0-9.]+) degC vs ([0-9.]+) degC \(diff ([0-9.]+) K\)") { throw "oil text" }; $k_oil = $Matches[1]; $k_oilD = $Matches[3]
$k_t = ($k_d1 | Where-Object { $_.what -like "24 h run: hot-spot*" }).detail
if ($k_t -notmatch "^([0-9.]+) degC vs ([0-9.]+) degC \(diff ([0-9.]+) K\)") { throw "hs text" }; $k_hs = $Matches[1]; $k_hsD = $Matches[3]
$k_cat = @{}; foreach ($g in ($k_bn | Group-Object category)) { $k_cat[$g.Name] = $g.Count }
if ($k_cat.ContainsKey("PARAMETER NUMBER")) { throw "a typed parameter number remains" }
if ($k_bn.Count -ne [int]$k_nFlagged) { throw "block-number file does not match the checklist" }
if (@($k_pl | Where-Object { -not (IsTrue $_.has_unit) -or -not (IsTrue $_.has_source_or_basis) }).Count -ne 0) { throw "parameter line without unit or source" }

# --- Step 33 checks re-run ---------------------------------------------------------------------------------------
foreach ($c in $k_c33) { if (-not (IsTrue $c.passed)) { throw ("a Step 33 check failed: " + $c.check) } }
if ($k_c33.Count -ne 9) { throw "expected 9 checks" }
$k_cmp = ($k_c33 | Where-Object { $_.check -like "structure equals*" }).detail
if ($k_cmp -notmatch "(\d+) blocks compared; (\d+) expected differences .*; 0 unexpected") { throw ("structure text: " + $k_cmp) }
$k_nExp = $Matches[2]
$k_log = Get-Content (Join-Path $root "04_MATLAB_Conventional\tests\test_log.txt") -Encoding utf8
$k_matlab = (($k_log | Where-Object { $_ -like "MATLAB:*" } | Select-Object -First 1) -replace "^MATLAB:\s*", "").Trim()

$global:S34 = @{ nChecks = $k_n; nBlocks = $k_nBlocks; nFlagged = $k_nFlagged; matlab = $k_matlab; completed = "13 October 2026"
  firstSummary = $k_firstSummary; finalSummary = $k_finalSummary; nAccepted = $k_acc.Count; nWarn = $k_warn; nIncomplete = $k_inc
  d1Pass = $k_d1Pass; d1Rows = $k_d1.Count; k = $k_K; oil = $k_oil; hs = $k_hs
  checks = ("Model Advisor: " + $k_finalSummary + "; Part D1: " + $k_d1Pass + " of " + $k_d1.Count + " rows pass (D1.7 open); verify_step33.m: 9 of 9 checks PASS; no typed parameter number in " + $k_nBlocks + " blocks") }

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
. (Join-Path $sp "report_entries_34.ps1")

function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed) {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "34" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "34" "Run the model checks" "Claude Code (this chat), MATLAB and Simulink through the MCP connection" $S34.completed
Summary ("The transformer operating model was checked in two ways: with the Model Advisor of Simulink Check (" + $k_n + " checks) and with the checklist of Part D1 of the MATLAB Build Guide. The first Model Advisor run on the Step 33 model gave " + $k_firstSummary + "; five groups of warnings were fixed in the building program and the final run gives " + $k_finalSummary + ". Nothing failed. The " + $k_acc.Count + " results that are not 'passed' are style rules for control code, code-generation options or internals of Simscape library blocks; each has a written reason, and their acceptance is proposed to the researcher (decision D32). The stricter scan of every dialog field of all " + $k_nBlocks + " blocks found one real typed parameter number that Step 33 had missed (the transformer's zero-sequence reactance, the block default 0.5); it is now the variable X0_pu. After all changes the nine checks of Step 33 still pass and the 24-hour run is unchanged (load factor " + $k_K + ", top oil " + $k_oil + " degC, hot spot " + $k_hs + " degC). One checklist item, a second person checking the build, needs a person and stays open.")
H1N "Purpose of this step"
Body "A model that is going to be used for a thesis must be checked before it is verified against theory. This step asks the computer to inspect the model without running it: are there unconnected ports, settings that hide errors, outdated blocks, numbers typed into blocks, missing notes? Every finding must either be fixed or be accepted with a written reason. Step 35 then compares the model with the IEC 60076-7 equations."
MethodSection "34"
H1N "What was used"
Bullet "Transformer_Operating_Model.slx as built in Step 33, params_transformer.m and build_Transformer_Operating_Model.m."
Bullet "MATLAB Build Guide, Part D1 (checklist before the work is accepted) and Section B12 (expected results of the 24-hour run)."
Bullet "The Model Advisor of Simulink Check, MATLAB R2025b."
Bullet "verify_step33.m (the nine checks of Step 33), used again after every change."
H1N "What was done, step by step"
NumItem "1" "Listed the Model Advisor checks and chose the set (decision D32): all checks of the groups design, simscape, simulink, sl and maab; the code-generation groups were left out."
NumItem "2" ("Ran the " + $k_n + " checks on the Step 33 model (first run: " + $k_firstSummary + "). Read every warning and decided: fix or accept.")
NumItem "3" "Fixed five groups of warnings in the building program, rebuilt the model and ran the nine Step 33 checks again."
NumItem "4" "Wrote the checklist function for Part D1, ran it, and corrected two faults of my own checker (see Problems and fixes). The stricter scan of all dialog fields found the zero-sequence reactance typed as 0.5; it became the variable X0_pu. The model was rebuilt and all checks were run again."
NumItem "5" "Ran the Model Advisor a final time on the final model, wrote the table of accepted warnings with a reason for each, and the code fingerprints."
NumItem "6" "Wrote this report and updated the register, the glossary, the READMEs, the decision log (D32), CHANGELOG.md and SESSION_SUMMARY.md."
H1N "What we found"
H2 "Model Advisor result"
AddTable @("Run", "Passed", "Warning", "Failed", "Incomplete") @(
  , @("First run (Step 33 model)", "115", "16", "0", "1")
  , @("Final run (final model)", "$k_pass", "$k_warn", "$k_fail", "$k_inc")
) @(180, 65, 65, 65, 75)
Body ("Both runs applied the same " + $k_n + " checks. 'Warning' means that the model works but a recommended setting or style rule is not met; 'Incomplete' means that the check itself stopped before it could give a result. The report file is 05_Simulink_Model/checks/model_advisor_report.html; the result of every check is in model_advisor_results.csv.")
H2 "What the first run reported and what was done"
AddTable @("Check (identifier)", "What it said", "What was done") @(
  , @("mathworks.design.UpdateRequireCompile", "The 'sqrt' function of the Math Function block is deprecated.", "Fixed: the Sqrt block (same operator) replaces it; the logged results are identical.")
  , @("mathworks.design.DataStoreMemoryBlkIssue", "'Duplicate data store names' is not set to error.", "Fixed: set to error (the model has no data stores).")
  , @("mathworks.maab.jc_0021", "Five diagnostics are set to 'none': Inf or NaN output, unconnected input, output and line, duplicate data store names.", "Fixed: all set to error, so a bad value or an open connection stops the run.")
  , @("mathworks.design.BusTreatedAsVector", "The model is not set to detect a bus signal treated as a vector.", "Fixed: set to error (the model has no buses).")
  , @("mathworks.maab.jc_0061", "The name of the Exp block is hidden.", "Fixed: name shown (it needed 'Hide automatic name' switched off, not only 'Show name' on).")
  , @("11 other warnings and 1 incomplete check", "Style rules for control code, code-generation options, library internals, and one check that stopped with a tool fault.", "Accepted with a reason each: see the next table.")
) @(130, 170, 150)
H2 "Results accepted with a written reason"
$k_rows = @(); foreach ($a in $k_acc) { $k_rows += , @($a.check_id, $a.status, $a.n_flagged_blocks, $a.reason_accepted) }
AddTable @("Check", "Status", "Blocks flagged", "Reason") $k_rows @(110, 55, 45, 240)
Body "'Blocks flagged' is the number of model paths named in the check's text (0 when the check flags a setting or the whole model). The table is written by step34_write_accepted.m, which stops if a non-passed check has no reason. The acceptance is proposed in decision D32 and awaits the researcher's confirmation."
H2 "Build Guide Part D1"
$k_rows = @()
foreach ($c in $k_d1) {
  $res = if ($c.item -eq "D1.7") { "OPEN" } elseif ($c.item -eq "D1.6") { "Not applicable yet" } elseif (IsTrue $c.passed) { "PASS" } else { "FAIL" }
  $k_rows += , @($c.item, $c.what, $res)
}
AddTable @("Item", "What was tested", "Result") $k_rows @(40, 330, 80)
Body ("Details: the 24-hour run gives K = " + $k_K + ", top-oil temperature " + $k_oil + " degC (difference to Section B12: " + $k_oilD + " K) and hot-spot temperature " + $k_hs + " degC (difference " + $k_hsD + " K); the tolerance is 0.1 K. Item D1.6 (the app) cannot be tested because the dashboard is built in a later stage. Item D1.7 (a second team member checks the build) needs a person. The row 'extra' is a direct test for bus blocks that replaces the incomplete Model Advisor check on bus signal names.")
H2 "Every dialog field of every block"
Body ("Step 33 checked the numbers that the building program had set (" + $k_nSet + " settings). This step read every dialog field of all " + $k_nBlocks + " blocks, including fields that the program never touched. " + $k_nFlagged + " values contain a digit. They were sorted by rule, and every value with its category is in step34_block_numbers.csv.")
$k_rows = @(
  , @("Interface code", "" + $k_cat["interface code"], "Port numbers, inherited sample time (-1), latency, unit selectors, normalisation values, logging options: they select behaviour and carry no physical value.")
  , @("Hidden field", "" + $k_cat["hidden field"], "The block mask hides the field in the dialog (an inactive option or a library default).")
  , @("Library tuning", "" + $k_cat["library tuning"], "Tolerances and filter settings of the Solver Configuration and converter blocks (defaults of the MathWorks library).")
  , @("Option selector", "" + $k_cat["option selector"], "0 = None of an on/off option: no source impedance and no harmonics of the ideal grid source.")
  , @("Parameter number", "0", "A typed number that should be a variable. None remains.")
)
AddTable @("Category", "Values", "Meaning") $k_rows @(95, 45, 310)
Body "The scan found one visible and enabled physical value: the zero-sequence reactance of the transformer, pu_X0 = 0.5, which was the library default. It is now the variable X0_pu in params_transformer.m. The value is unchanged, the source is the block default and not the pandapower data (TO VERIFY), and it has no effect on a balanced load."
H2 "Parameter file"
Body ("params_transformer.m defines " + $k_pl.Count + " variables. The check requires a unit in square brackets and a source or basis for every one: a source code (E1, T1, T2, A1 to A4), an explicit basis in the comment, or a basis stated in the section heading (Sections 1 and 3 name E1 and T1; Sections 2 and 4 name the Build Guide, Section A3, for derived values; Section 5 states that its values are run settings chosen for the verification run). The check found real gaps: the load profile had no unit and the two ageing constants had no source tag. They now carry the unit and the source codes of the Build Guide (A4, reference T2: the IntechOpen chapter, marked TO VERIFY against IEC 60076-7). Only comments were changed, except for the new variable X0_pu.")
H2 "Changes made to the model and its programs"
AddTable @("Change", "Why", "Where") @(
  , @("Sqrt block instead of Math Function 'sqrt'", "Deprecated block (Model Advisor).", "build_Transformer_Operating_Model.m, SS3_LV_Measurement/Square_Root")
  , @("Six diagnostics set to error", "Silent Inf/NaN values and open connections would go unnoticed.", "build_Transformer_Operating_Model.m, model settings")
  , @("Name of the Exp block shown", "Model Advisor style check.", "SS7_Outputs_and_Ageing/Exp")
  , @("Variable X0_pu (0.5 pu) for the zero-sequence reactance", "No number typed into a block (Build Guide D1.2).", "params_transformer.m; SS2 transformer block; annotation of SS2")
  , @("Units and source tags in the parameter file", "Build Guide D1.1.", "params_transformer.m (comments)")
  , @("Expected differences extended to 7", "verify_step33.m compares the model with the reference build; the Sqrt block (type, algorithm) and X0_pu are new, documented differences. The logged results are identical to the reference.", "verify_step33.m, check 3")
) @(150, 190, 110)
H1N "Checks"
$k_rows = @(); foreach ($c in $k_c33) { $k_rows += , @($c.check, "PASS") }
AddTable @("Check (verify_step33.m, run again after the final rebuild)", "Result") $k_rows @(360, 90)
Body ("Detail of the structure check: " + $k_cmp + ". The largest difference between this model and the reference run is 0.00e+00, so the fixes did not change the physics.")
H1N "Problems and fixes"
Bullet "My first version of the parameter-file check reported that almost every variable lacked a source. The cause was my own search pattern: in MATLAB regular expressions the code \b means the backspace character, not a word boundary. The pattern now uses look-around expressions. After the repair, the lines that rely on the section heading for their basis (derived values, run settings) were still listed; the rule was widened so that a basis stated in the section heading counts, and Section 5 now states its basis."
Bullet "The first scan of the dialog fields listed 246 values, nearly all of them harmless. Instead of ignoring the list, every value was given a category by a written rule; the one real finding (pu_X0) was fixed. The classification rules are in the comments of step34_checklist_D1.m."
Bullet "After the first rebuild verify_step33.m gave 8 of 9: the Sqrt block has another block type and the algorithm label 'Exact' instead of 'Newton-Raphson'. As the logged results are identical, both were added as expected differences with the reason stated, and X0_pu was added the same way later. The check still finds every other difference."
Bullet "Two fixes did not take effect at first: the bus setting needed the value 'ErrorOnBusTreatedAsVector' (not 'ErrorLevel1'), and the Exp block name needed 'Hide automatic name' switched off. The Model Advisor, run again, showed this; both were corrected in the building program."
Bullet "The Model Advisor check on bus signal names (mathworks.maab.na_0030) stops with the message 'Dot indexing is not supported for variables of this type' inside the tool. It was replaced by a direct test (the model has no Bus Creator or Bus Selector block)."
Bullet "The raw file of the first Model Advisor run was overwritten by the later runs. Its summary and warning list come from the program output of that run."
H1N "Decisions"
Bullet "D32: check set (all modelling and Simscape checks, no code-generation checks); the fixes; the acceptance of the remaining warnings (proposed); Part D1 item 6 not applicable yet and item 7 open; the Step 33 files changed in this step."
H1N "Files produced"
Bullet "05_Simulink_Model/checks/: model_advisor_report.html, model_advisor_results.csv, model_advisor_accepted.csv, step34_checklist_D1.csv, step34_param_lines.csv, step34_block_numbers.csv, model_advisor_raw.mat, README.md, the three programs step34_*.m, and Transformer_Operating_Model_before_step34.slx"
Bullet "05_Simulink_Model/code_manifest_step34.sha256"
Bullet "Changed: Transformer_Operating_Model.slx, build_Transformer_Operating_Model.m, verify_step33.m, params_transformer.m and the files in results/ that verify_step33.m rewrites"
Closing "34" 0 "Step 35 (Simulink): verify the model against an independent solution of the IEC 60076-7 equations at rated load and in a load step from about 0.6 to 1.2 per unit; the 63 % rise time of the top-oil temperature must equal k11 times the oil time constant." $global:Blocks["34"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_34_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_34_Report.docx") -Force
("SAVED Step_34_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber + "`n" + $_.ScriptStackTrace) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
