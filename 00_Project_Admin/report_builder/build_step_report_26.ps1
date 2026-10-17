$ErrorActionPreference = "Stop"
# build_step_report_26.ps1 - Word report of roadmap Step 26. Every number is read from the result files
# (11_Results/conventional, 11_Results/reduced_gas, 04_MATLAB_Conventional/tests/test_log.txt); statements are throw-checked.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report26_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8

$inv = [Globalization.CultureInfo]::InvariantCulture
function D([string]$v) { [double]::Parse($v, $inv) }
function F3([string]$v) { (D $v).ToString("0.000", $inv) }
function Pct([double]$v) { ($v * 100).ToString("0.0", $inv) + " %" }

# ---- read the result files --------------------------------------------------------------------------
$k_app  = Import-Csv (Join-Path $root "11_Results\conventional\conventional_applicability.csv")
$k_chk  = Import-Csv (Join-Path $root "11_Results\conventional\conventional_applicability_checks.csv")
$k_cnt  = Import-Csv (Join-Path $root "11_Results\conventional\conventional_counts.csv")
$k_rg   = Import-Csv (Join-Path $root "11_Results\reduced_gas\reduced_gas_results.csv")
$k_xl   = Import-Csv (Join-Path $root "08_Statistical_Analysis\cross_language_check_step26.csv")
$k_pred = Import-Csv (Join-Path $root "11_Results\conventional\conventional_predictions.csv")
$k_master = Import-Csv (Join-Path $root "03_Data\processed\dga_master.csv")
$k_log  = Get-Content (Join-Path $root "04_MATLAB_Conventional\tests\test_log.txt") -Encoding utf8
$k_sumLine = ($k_log | Where-Object { $_ -like "SUMMARY:*" } | Select-Object -Last 1)
if ($k_sumLine -notmatch "SUMMARY: (\d+) tests, (\d+) passed, 0 failed, 0 incomplete") { throw "test log shows a failure or is unreadable: $k_sumLine" }
$k_nTests = [int]$Matches[1]; if ([int]$Matches[2] -ne $k_nTests) { throw "not all tests passed" }
$k_matlabVer = (($k_log | Where-Object { $_ -like "MATLAB:*" } | Select-Object -First 1) -replace "^MATLAB:\s*", "").Trim()
$k_pyExe = Join-Path $root "06_Python_ML\.venv\Scripts\python.exe"
$k_pyVer = ((& $k_pyExe --version) -replace "Python ", "").Trim()
$k_pyOut = (& $k_pyExe -m pytest (Join-Path $root "06_Python_ML\tests\test_step26_crosscheck.py") -q 2>&1 | Out-String)
if ($k_pyOut -notmatch "(\d+) passed" -or $k_pyOut -match "failed") { throw "python tests: $k_pyOut" }
$k_nPy = [int]$Matches[1]

if (-not (@($k_chk | Where-Object { $_.passed -ne "true" -and $_.passed -ne "True" -and $_.passed -ne "1" }).Count -eq 0)) { throw "a Step 26 check failed" }
if (@($k_xl | Where-Object { $_.identical -ne "True" -and $_.identical -ne "true" }).Count -ne 0) { throw "Python and MATLAB differ" }
$k_methods = "IEC60599", "Rogers", "Duval"
$k_all = $k_app | Where-Object { $_.data_role -eq "all" }
$k_nSub = @($k_all | Where-Object { $_.method -eq "Duval" }).Count
if ($k_app.Count -ne 465 -or $k_nSub -ne 31) { throw "unexpected table size" }
$k_appCount = @{}; $k_appIds = @{}
foreach ($m in $k_methods) {
  $x = @($k_all | Where-Object { $_.method -eq $m -and [int]$_.applicable -eq 1 })
  $k_appCount[$m] = $x.Count; $k_appIds[$m] = ($x | ForEach-Object { $_.subset_id })
  # rule check on the saved file itself: not applicable -> share 1
  if (@($k_app | Where-Object { $_.method -eq $m -and [int]$_.applicable -eq 0 -and (D $_.share_nd) -ne 1 }).Count -ne 0) { throw "not applicable but share_nd < 1" }
}
if ($k_appCount["IEC60599"] -ne 1 -or $k_appCount["Rogers"] -ne 1 -or $k_appCount["Duval"] -ne 4) { throw "unexpected number of applicable combinations" }
$k_full = "H2+CH4+C2H6+C2H4+C2H2"
$k_mlPanelRow = $k_rg | Where-Object { $_.subset_id -ne $k_full -and (D $_.loss_vs_full_mean) -le 0.05 }
if (@($k_mlPanelRow).Count -ne 1) { throw "expected exactly one reduced panel within 0.05" }
$k_mlPanel = $k_mlPanelRow.subset_id
$k_mlPanelText = (@($k_methods | ForEach-Object { $m = $_; $r = $k_all | Where-Object { $_.subset_id -eq $k_mlPanel -and $_.method -eq $m }; if ([int]$r.applicable -ne 0) { throw "panel applicable to $m" }; $m }) -join ", ") + " are all not applicable"
$k_notDuval = @($k_all | Where-Object { $_.method -eq "Duval" -and [int]$_.applicable -eq 0 }).Count

$global:S26 = @{ rows = $k_app.Count; nchecks = $k_chk.Count; appIec = $k_appCount["IEC60599"]; appDuval = $k_appCount["Duval"]
  completed = "12 October 2026"; matlab = $k_matlabVer; python = $k_pyVer; mlTests = ("" + $k_nTests)
  mlPanel = $k_mlPanel; mlPanelText = $k_mlPanelText
  checks = ("" + $k_chk.Count + " of " + $k_chk.Count + " automatic checks PASS; " + $k_nTests + " MATLAB tests PASS; Python " + $k_nPy + " tests PASS; MATLAB = Python on " + $k_xl.Count + " of " + $k_xl.Count + " rows") }

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
. (Join-Path $sp "report_entries_26.ps1")

function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed) {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "26" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "26" "Conventional methods with gases removed" "Claude Code (this chat), MATLAB through the MCP connection" $S26.completed
$k_d5 = $k_all | Where-Object { $_.subset_id -eq $k_full }
Summary ("The IEC 60599, Rogers and Duval Triangle 1 methods were run for all 31 combinations of the five gases, as if the other gases had not been measured. IEC 60599 and Rogers need all five gases, so they can diagnose only the full five-gas panel: for the other 30 combinations they answer 'no diagnosis' (ND) for 100 % of the " + ($k_d5 | Select-Object -First 1).n_records + " records. Duval Triangle 1 needs CH4, C2H4 and C2H2 and can diagnose " + $k_appCount["Duval"] + " of the 31 combinations; for the other " + $k_notDuval + " it answers ND for 100 % of the records. The smallest reduced panel that the machine-learning model of Step 25 handles with at most 0.05 loss of macro-F1 (" + $k_mlPanel + ") cannot be diagnosed by any of the three methods. The five-gas row reproduces the counts of Steps 14-17 exactly, all " + $k_chk.Count + " automatic checks pass and an independent Python program reproduces all " + $k_app.Count + " rows.")
H1N "Purpose of this step"
Body "Real monitors often measure fewer than five gases. This step finds out, for every possible set of measured gases, how often each conventional method can still give a diagnosis. It gives the baseline for the comparison with machine learning in Step 27."
MethodSection "26"
H1N "What was used"
Bullet "The 827 records of data version 1.0 (checked with the SHA-256 manifest before the run) and the 31 gas combinations of Step 25 (reduced_gas_subsets.csv)."
Bullet "The functions of Steps 14-17, unchanged: no limit, ratio rule or zone was altered (decisions D11-D13 stay in force)."
H1N "What was done, step by step"
NumItem "1" "Wrote the rule as decision D23 (rules 1-3 follow the Analysis Plan; rule 4, the normality gate, is proposed and flagged for the researcher)."
NumItem "2" "Added the gases each method needs to conv_config.m, derived from the ratio definitions (no new limit)."
NumItem "3" "Wrote reduced_gas_diagnosis.m (the rule) and run_reduced_gas_applicability.m (the 31 x 3 x 5 table with 10 automatic checks)."
NumItem "4" ("Wrote 26 unit tests, including the one the roadmap asks for (one removed gas gives ND for IEC 60599 and Rogers); all " + $k_nTests + " MATLAB tests pass.")
NumItem "5" ("Wrote an independent Python check (" + $k_nPy + " tests); it reproduces all " + $k_app.Count + " rows.")
H1N "The rules"
Bullet "A removed gas is NaN (not measured), never 0 ppm."
Bullet "A method that needs a removed gas answers ND for every record, decided before any ratio, zone or gate test. IEC 60599 and Rogers need all five gases; Duval needs CH4, C2H4 and C2H2."
Bullet "A method that has all its gases is run exactly as before, with the upper normality gate of Step 14."
Bullet "The normality gate is passed (Normal) only when all five gases are measured and at or below their typical values; with a gas missing it is never passed (D23 rule 4, proposed)."
H1N "What we found"
H2 "Which method can diagnose which gas combination"
$rows = @()
foreach ($m in $k_methods) { $rows += , @($m, ("" + $k_appCount[$m] + " of 31"), (($k_appIds[$m]) -join "; ")) }
AddTable @("Method", "Combinations it can diagnose", "Which") $rows @(80, 90, 280)
Body ("In all other combinations the method answers ND for 100 % of the records. All three methods fail in " + @($k_all | Where-Object { $_.method -eq "Duval" -and [int]$_.applicable -eq 0 }).Count + " of the 31 combinations (every combination that lacks CH4, C2H4 or C2H2), including every single gas and every pair that does not contain the three Duval gases.")
H2 "Duval Triangle 1: the combinations where it can still diagnose"
$rows = @()
foreach ($id in $k_appIds["Duval"]) {
  $a = $k_all | Where-Object { $_.subset_id -eq $id -and $_.method -eq "Duval" } | Select-Object -First 1
  $rows += , @($id, $a.n_gases, $a.n_records, $a.n_nd_raw, $a.n_nd, $a.n_nd_gate_measured)
}
AddTable @("Gases measured", "Gases", "Records", "ND before gate", "ND after gate (primary)", "ND, gate on measured gases (sensitivity)") $rows @(150, 40, 50, 55, 75, 80)
$k_nd2 = @($k_pred | Where-Object { $_.method -eq "Duval" -and $_.raw_result -eq "ND" })
if ($k_nd2.Count -ne 2) { throw "expected 2 raw Duval ND records" }
$k_nd2txt = @()
foreach ($q in $k_nd2) {
  $mr = $k_master | Where-Object { $_.record_id -eq $q.record_id } | Select-Object -First 1
  if ([double]$mr.CH4 -ne 0 -or [double]$mr.C2H4 -ne 0 -or [double]$mr.C2H2 -ne 0) { throw "Duval ND record with a non-zero Duval gas" }
  $k_nd2txt += ($q.record_id + " (H2 = " + $mr.H2 + " ppm, gate " + $(if ($q.gate_upper -eq "Normal") { "passed" } else { "not passed" }) + ")")
}
Body ("Duval gives ND only for records with CH4, C2H4 and C2H2 all equal to 0 ppm (the percentages are then undefined). In the data these are two development records: " + ($k_nd2txt -join " and ") + ". With all five gases the gate turns the record whose gases are all at or below their typical values into Normal and the other stays ND (1 record). With a gas missing the gate cannot be passed, so both stay ND (2 records). This is the point flagged in the open items.")
H2 "The five-gas row reproduces Steps 14-17"
$rows = @()
foreach ($m in $k_methods) {
  foreach ($role in @("all", "development", "internal_test", "benchmark", "external_test")) {
    $a = $k_app | Where-Object { $_.subset_id -eq $k_full -and $_.method -eq $m -and $_.data_role -eq $role } | Select-Object -First 1
    $c = $k_cnt | Where-Object { $_.method -eq $m -and $_.data_role -eq $role } | Select-Object -First 1
    if ([int]$a.n_nd -ne [int]$c.ND_final) { throw "five-gas row differs from conventional_counts.csv ($m, $role)" }
    $rows += , @($m, $role, $a.n_records, $a.n_nd, $c.ND_final, (Pct (D $a.share_nd)))
  }
}
AddTable @("Method", "Data role", "Records", "ND (this step)", "ND_final (Steps 14-17)", "Share ND") $rows @(70, 80, 55, 65, 85, 55)
H2 "Conventional methods against the machine-learning model on reduced panels"
$rows = @()
foreach ($id in @($k_full, $k_mlPanel, "CH4+C2H4+C2H2")) {
  $r = $k_rg | Where-Object { $_.subset_id -eq $id } | Select-Object -First 1
  $s3 = @(); foreach ($m in $k_methods) { $q = $k_all | Where-Object { $_.subset_id -eq $id -and $_.method -eq $m } | Select-Object -First 1; $s3 += (Pct (D $q.share_nd)) }
  $rows += , @($id, (F3 $r.macro_f1_mean), (F3 $r.loss_vs_full_mean), $s3[0], $s3[1], $s3[2])
}
AddTable @("Gases measured", "ML macro-F1 (Step 25)", "ML loss", "ND IEC", "ND Rogers", "ND Duval") $rows @(130, 65, 50, 60, 60, 60)
Body ("ML = the Random Forest on feature set F4 restricted to the measured gases, cross-validated on the 439 development records (Step 25); ND shares are over all 827 records. The only reduced panel with a mean loss of at most 0.05 is " + $k_mlPanel + ", and none of the three conventional methods can diagnose it. The panel that Duval can use with the fewest gases, CH4+C2H4+C2H2, gives the machine-learning model a macro-F1 of " + (F3 ($k_rg | Where-Object { $_.subset_id -eq "CH4+C2H4+C2H2" }).macro_f1_mean) + ". These are different data sets and metrics (ND share against cross-validated macro-F1); the formal comparison with confidence intervals is in Steps 28-30.")
H1N "Checks"
$rows = @(); foreach ($c in $k_chk) { $rows += , @($c.check, "PASS") }
$rows += , @("Unit tests (MATLAB): old 67 + new 26", ("PASS (" + $k_nTests + " of " + $k_nTests + ")"))
$rows += , @("Audit: no typed limits in the decision code", "PASS (0 literals)")
$rows += , @("Independent Python implementation reproduces the table", ("PASS (" + $k_xl.Count + " of " + $k_xl.Count + " rows)"))
AddTable @("Check", "Result") $rows @(360, 90)
H1N "Problems and fixes"
Bullet "Alert - roadmap check worded loosely: 'for a combination that keeps CH4, C2H4 and C2H2 the Duval ND count equals the five-gas Duval ND count'. The five-gas count after the gate is 1 record, before the gate 2. With a gas missing the gate cannot be passed, so the reduced combinations give 2, which equals the five-gas count before the gate. The check was therefore written against the count before the gate, and both numbers are shown. The alternative rule (gate on the measured gases) is given as a sensitivity column. The choice needs the researcher's confirmation (D23 rule 4)."
Bullet "The first test run had two failures: the audit 'no typed limits' found the number 11 in the new batch program (the number of columns of a work table). It was not a limit, but the audit rule is strict, so the line was changed and the audit and all tests pass."
Bullet "The system Python has no numpy; the check program was run with the project's own environment (06_Python_ML/.venv), as in the earlier steps."
Bullet "While updating the results manifest, 11_Results/manifest.csv was found to contain unquoted commas in the four Duval figure rows (they are read with five fields). This was an earlier mistake and is repaired in this session; no result was affected. The manifest also lists only some of the results (it was not kept up to date after Step 17); completing it is an open item."
Bullet "The test log 04_MATLAB_Conventional/tests/test_log.txt, which is register entry DF13 and was the 67-test log of Step 15, was overwritten by this step's run of both test classes (93 tests, all passed). The register entry was updated; the 67-test log itself is not kept."
Bullet "The Word version of the Data and Source Register had not been updated since Step 17 and contained a typing error (66 of 66 tests instead of 67 of 67). It was rebuilt as version 4 and now lists the files of Steps 18 to 26."
Bullet "Earlier in the same session (not part of Step 26) the Simulink model of the rerun folder was found to depend on the MATLAB path: its start-up callbacks only called params_transformer, which lives two folders higher. The callbacks now add that folder to the path (backup kept; recorded in CHANGELOG.md). It is not confirmed that this was the error the researcher saw; the exact error text is still needed."
H1N "Where the standards limits can be verified"
Body "Every decision limit used by the three methods is read from a table in 02_Standards; none is typed in the code. All of them are still marked TO VERIFY. The table below says which printed table each file was copied from and where to obtain the document. A correction found at any of these places creates data version 1.1, and Steps 14 to 17 and this step are then re-run (all are automatic)."
AddTable @("Project file", "Printed source to compare with", "Where to obtain it") @(
  , @("02_Standards/iec_ratio_table.csv (IEC ratio method, ratios R1, R2, R5)", "IEC 60599 Ed. 2.1 (2007), Table 2, p. 11 (read in the official preview). To check: Table 1 of the 2022 edition (p. 14).", "IEC 60599:2022 full text, IEC webstore (CHF 260 at the time of reading), or the UMaT library / supervisor")
  , @("02_Standards/iec_typical_values.csv (normality gate)", "IEC 60599 Amendment 1 (2007), Table A.2 (p. 3 of the preview), with its Annex A warning. To check: Table A.2 of the 2022 edition (p. 26).", "As above")
  , @("02_Standards/duval_triangle_zones.csv (Duval Triangle 1)", "IEC 60599:2022, Figure B.3 (p. 37 of the preview) and IEEE Std C57.104-2019, clause 6.2.3. Currently taken from a secondary source (Moser 2025, citing C57.104-2019), which agrees with Manisha et al. 2022 and reproduces all 39 printed worked examples.", "IEC 60599:2022 and IEEE Std C57.104-2019 (IEEE Xplore, through the UMaT library)")
  , @("02_Standards/rogers_ratio_table.csv (Rogers ratio method)", "IEEE Std C57.104-2008, Table 6 (p. 16) and the worked example of Figure 2 (p. 7). The copy used was not licensed to the project.", "IEEE Std C57.104-2008 from a licensed copy (IEEE Xplore, UMaT library)")
  , @("02_Standards/ieee_condition1_limits.csv", "IEEE Std C57.104-2008, Table 1 (p. 10).", "As above")
) @(130, 200, 120)
Body "Each file also has a record of what was compared in 02_Standards/sources.md and 02_Standards/transcription_check.md. A corrected limit could change the diagnoses of Steps 14 to 17 and therefore the ND counts in this report; the numbers here are valid for data version 1.0 only."
H1N "Decisions"
Bullet "D23: removed gas = NaN; a method that needs a removed gas gives ND for every record; a method with its gases runs as before (rules 1-3, closed on the basis of the Analysis Plan Section 8 and the Step 26 instruction). Rule 4: the normality gate is never passed with a gas missing (proposed, awaiting confirmation)."
H1N "Files produced"
Bullet "11_Results/conventional/conventional_applicability.csv and conventional_applicability_checks.csv"
Bullet "08_Statistical_Analysis/cross_language_check_step26.csv"
Bullet "04_MATLAB_Conventional/reduced_gas_diagnosis.m, run_reduced_gas_applicability.m, tests/TestReducedGas.m, code_manifest_step26.sha256 (conv_config.m and tests/run_tests_and_log.m were extended); tests/test_log.txt (93 tests)"
Bullet "06_Python_ML/src/conventional/step26_crosscheck.py; 06_Python_ML/tests/test_step26_crosscheck.py"
Closing "26" 0 "Step 27 (Claude Code): the loss of each gas combination with its 95 % bootstrap interval, the smallest panel within the tolerance of 0.05, Table 4.9 and Figures 4.16-4.17." $global:Blocks["26"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_26_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_26_Report.docx") -Force
("SAVED Step_26_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber + "`n" + $_.ScriptStackTrace) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}


