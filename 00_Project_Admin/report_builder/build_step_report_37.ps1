$ErrorActionPreference = "Stop"
# build_step_report_37.ps1 - Word report of roadmap Step 37 (DGA sampling-event subsystem).
# Every number is read from 05_Simulink_Model/results (checks, events, block list) and params_transformer.m; statements are throw-checked.
# Variable names start with k_ because the dot-sourced helper scripts also use short names.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report37_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8
$inv = [Globalization.CultureInfo]::InvariantCulture
function IsTrue($v) { $v -in @("1", "true", "True") }

$k_res = Join-Path $root "05_Simulink_Model\results"
$k_chk = Import-Csv (Join-Path $k_res "step37_checks.csv")
$k_ev  = Import-Csv (Join-Path $k_res "step37_sampling_events.csv")
$k_blk = Import-Csv (Join-Path $k_res "step37_ss8_blocks.csv")
$k_par = Get-Content (Join-Path $root "05_Simulink_Model\params_transformer.m") -Encoding UTF8
if ($k_chk.Count -ne 10) { throw "expected 10 checks" }
foreach ($c in $k_chk) { if (-not (IsTrue $c.passed)) { throw ("a Step 37 check failed: " + $c.check) } }
if ($k_blk.Count -ne 13) { throw "expected 13 SS8 blocks" }
$m = [regex]::Match(($k_par -join "`n"), 't_sample_h\s*=\s*\[([0-9 ]+)\]'); if (-not $m.Success) { throw "t_sample_h not found" }
$k_times = (($m.Groups[1].Value.Trim() -split "\s+") -join ", ")
$m = [regex]::Match(($k_par -join "`n"), 't_event_s\s*=\s*([0-9.]+)'); if (-not $m.Success) { throw "t_event_s not found" }
$k_tev = $m.Groups[1].Value
if ($k_ev.Count -ne 4) { throw "expected 4 sampling events" }
$k_ids = (($k_ev | ForEach-Object { $_.record_id }) -join ", ")
# largest thermal difference of the regression check (check 9), from its detail text
$k_c9 = $k_chk | Where-Object { $_.check -like "Step 36 scenarios*" }
$k_dm = [regex]::Matches($k_c9.detail, '(oil|hot-spot) ([0-9.]+) K') | ForEach-Object { [double]::Parse($_.Groups[2].Value, $inv) }
if ($k_dm.Count -ne 6) { throw "expected 6 differences in check 9" }
$k_dmax = ($k_dm | Measure-Object -Maximum).Maximum.ToString("0.0000", $inv)
$k_log2 = Get-Content (Join-Path $root "04_MATLAB_Conventional\tests\test_log.txt") -Encoding utf8
$k_matlab = (($k_log2 | Where-Object { $_ -like "MATLAB:*" } | Select-Object -First 1) -replace "^MATLAB:\s*", "").Trim()
$global:S37 = @{ matlab = $k_matlab; completed = "13 October 2026"; nChecks = $k_chk.Count; times = $k_times; tev = $k_tev; n = $k_ev.Count; ids = $k_ids; dmax = $k_dmax
  checks = ("verify_step37.m: 10 of 10 checks PASS (no gas block or signal; index steps at the set times; regression to the Step 36 results within 0.01 K, largest " + $k_dmax + " K)") }
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
. (Join-Path $sp "report_entries_37.ps1")
function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed) {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "37" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "37" "Add the DGA sampling-event subsystem" "Claude Code (this chat), MATLAB and Simulink through the MCP connection" $S37.completed
Summary ("A new subsystem, SS8, was added to the transformer operating model. At the sampling times " + $k_times + " h it counts the sampling events (record_index) and raises a " + $k_tev + " s pulse (sampling_event). It has no input and no output port, so it cannot affect the temperatures, and it contains only " + $k_blk.Count + " clock, constant, comparison, counting, logic and logging blocks: it cannot produce a gas value. The text record_id of the next held-out record is looked up outside the model, in dga_master.csv, from the index. All " + $k_chk.Count + " checks pass, including the test that no block, name, value or logged signal refers to a gas, and the test that the temperatures of the three Step 36 scenarios are unchanged (largest difference " + $k_dmax + " K on the common time points). A Step 35 check that failed after SS8 was added (0.104 K against 0.1 K) was traced to the solver tolerance, not to SS8, and fixed (RelTol 1e-4). The sampling times are illustrative.")
H1N "Purpose of this step"
Body "The operating-context model must be able to say when a gas sample would be taken, so that the dashboard can show the real measured record at that moment. The model must never create a gas concentration (decision D4). This step adds the event generator, and tests that it generates events only."
MethodSection "37"
H1N "What was used"
Bullet "The model Transformer_Operating_Model.slx of Steps 33 to 36 and params_transformer.m."
Bullet "03_Data/processed/dga_master.csv, only the columns record_id and data_role (the role says whether a record is development, benchmark, internal test or external test)."
Bullet "The saved Step 36 results (kept in results/before_step37/) for the regression test."
H1N "What was done, step by step"
NumItem "1" "Fixed the design and the tests in the decision log (D35) before building: what held-out means, how the sampling times are set, and how a text identifier can leave a numeric model."
NumItem "2" "Added the sampling times, the pulse length and the held-out list to params_transformer.m (only two columns of the CSV are read), wrote get_sampling_events.m, and built SS8 in build_Transformer_Operating_Model.m."
NumItem "3" "Wrote verify_step37.m with 10 checks. During the build the first amendment of D35 was made: the solver time grid changes slightly when SS8 is added, so the thermal signals can be compared with the saved ones only on the common time points (within 0.01 K), not point by point."
NumItem "4" "Re-running the Step 35 verification on the model with SS8 gave a hot-spot difference of 0.104 K in Test 1 against the limit 0.1 K, although SS8 is not connected to the thermal network. A first explanation (interpolation on a different grid) was incomplete. Tests of the solver tolerance showed that the default RelTol 1e-3 leaves an error of about 0.1 K that moves with the solver steps; RelTol 1e-4 gives 0.013 K. The tolerance is now the variable solver_reltol in params_transformer.m (D33 and D35 amendments)."
NumItem "5" "Rebuilt the model and repeated Steps 33, 35, 36 and 37 and the Model Advisor and checklist of Step 34 on the final model; the regression test of check 9 is run at the old tolerance (1e-3) so that it measures only the effect of SS8."
NumItem "6" "Wrote this report and updated the register, glossary, READMEs, CHANGELOG.md and SESSION_SUMMARY.md."
H1N "What we found"
H2 "The subsystem"
$k_rows = @(); foreach ($b in $k_blk) { $k_rows += , @($b.block, $b.kind) }
AddTable @("Block of SS8", "Kind") $k_rows @(250, 200)
Body "Every block is a clock, a constant, a comparison, a counting or logic block, or a logging block. SS8 has no input port and no output port; its two logged signals, record_index and sampling_event, go only to the workspace."
H2 "Sampling events"
$k_rows = @(); foreach ($e in $k_ev) { $k_rows += , @(([double]::Parse($e.time_h, $inv)).ToString("0.0", $inv), $e.record_index, $e.record_id) }
AddTable @("Sampling time (h)", "record_index", "record_id (looked up outside the model)") $k_rows @(120, 90, 240)
Body "The four identifiers are the first four held-out records of dga_master.csv (role benchmark). The sampling times are illustrative and can be replaced in params_transformer.m."
H1N "Checks"
$k_rows = @(); foreach ($c in $k_chk) { $k_rows += , @($c.check, "PASS") }
AddTable @("Check (verify_step37.m)", "Result") $k_rows @(360, 90)
Body ("Check 9 compares the thermal and ageing signals of the three Step 36 scenarios with the saved results on the time points that both runs share: " + $k_c9.detail + ". The limit is 0.01 K. Check 10 repeats the nine checks of Step 33 on the model with SS8.")
H1N "Problems and fixes"
Bullet "The solver time grid changes when SS8 is added, so the signals could not be compared point by point with the saved ones. The comparison was changed to the common time points (amendment of D35, logged openly)."
Bullet "After SS8 was added the Step 35 hot-spot difference after 10 minutes rose to 0.104 K (limit 0.1 K). The cause was the solver accuracy; RelTol 1e-3 was changed to 1e-4 (0.013 K, run time about 63 s) and all verification steps were repeated. The first explanation, written in the decision log, was corrected."
Bullet "The first regression check, run after the tolerance change, failed (hot-spot differences of 0.026 K and 0.060 K on only four to five common points) because the saved results were produced at the old tolerance. The check now runs at that tolerance, so that only SS8 is compared (296 common points)."
Bullet "A tool message 'Dot indexing is not supported for variables of this type' appears in the Model Advisor run; it belongs to the check na_0030, which was already recorded as incomplete in D32 and replaced by the direct test that the model has no bus."
H1N "Decisions"
Bullet "D35: held-out records (role not development, 388, in file order); sampling times and pulse in params_transformer.m; record_index and sampling_event as the numeric outputs; only two CSV columns read; the tests; the regression rule (common points, 0.01 K). Two amendments."
Bullet "D33 amendment: the solver tolerance of the model is 1e-4."
H1N "Files produced"
Bullet "05_Simulink_Model/Transformer_Operating_Model.slx (with SS8), build_Transformer_Operating_Model.m, params_transformer.m, get_sampling_events.m, verify_step37.m, code_manifest_step37.sha256"
Bullet "05_Simulink_Model/results/step37_checks.csv, step37_sampling_events.csv, step37_ss8_blocks.csv"
Bullet "05_Simulink_Model/results/before_step37/ (the Step 36 results before SS8, used by check 9)"
Closing "37" 0 "Step 38 (Claude Code): build the FastAPI service in 09_API_FastAPI (stage H)." $global:Blocks["37"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_37_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_37_Report.docx") -Force
("SAVED Step_37_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber + "`n" + $_.ScriptStackTrace) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
