$ErrorActionPreference = "Stop"
# build_step_report_42.ps1 - Word report of roadmap Step 42 (fidelity and response time = the integration report). Reads 11_Results/integration and Table 4.11.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report42_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8
$res = Join-Path $root "11_Results"
$ic = [Globalization.CultureInfo]::InvariantCulture
function F1([double]$v) { $v.ToString("F1", $ic) }
$k_chk = [IO.File]::ReadAllText((Join-Path $res "integration\integration_checks.json")) | ConvertFrom-Json
$k_tab = Import-Csv (Join-Path $res "tables\T4_11_integration.csv") -Encoding UTF8
$k_run = [IO.File]::ReadAllText((Join-Path $root "10_Dashboard_Client\logs\testbench_run_info.json")) | ConvertFrom-Json
$k_s38 = [IO.File]::ReadAllText((Join-Path $root "09_API_FastAPI\checks\step38_service_check.json")) | ConvertFrom-Json
$k_c4 = Get-Content (Join-Path $res "chapter4_check.txt")
if (-not $k_chk.pass) { throw "integration check did not pass" }
$k_N = [int]$k_chk.fidelity_ml_class.N
if ($k_N -ne 388 -or $k_chk.fidelity_ml_class.matches -ne 388 -or $k_chk.probabilities_identical -ne 388 -or $k_chk.failed_calls -ne 0 -or $k_chk.mismatched_records -ne 0) { throw "fidelity counts differ from the text" }
foreach ($m in @("Rogers", "IEC60599", "Duval")) { if ($k_chk.conventional_identical.$m -ne 388) { throw "conventional $m differs" } }
if ($k_chk.largest_probability_difference -ne 0) { throw "probabilities differ" }
$rt = $k_chk.response_ms_all; $rw = $k_chk.response_ms_without_warmup; $ct = $k_chk.conventional_ms_all; $tt = $k_chk.total_ms_all
if ($rt.p95 -ge 1000) { throw "p95 not below 1 s" }
if ($tt.max -le 1000 -or $tt.p95 -ge 1000) { throw "total-time statements no longer hold" }
$k_lg = Import-Csv (Join-Path $root "10_Dashboard_Client\logs\testbench_log.csv")
$k_slow = @($k_lg | Where-Object { [double]::Parse($_.total_ms, $ic) -gt 1000 } | Sort-Object { [double]::Parse($_.total_ms, $ic) } -Descending)
$k_top = $k_slow[0]
if ([Math]::Abs([double]::Parse($k_top.total_ms, $ic) - [double]$tt.max) -gt 1e-3) { throw "slowest record not found" }
if ($rt.median -le $k_s38.response_ms.median) { throw "statement 'MATLAB slower than Python' no longer holds" }
if (($k_c4[0] -notmatch 'before: 83; after: 83') -or ($k_c4[3] -ne "changed: []")) { throw "rebuild check text differs" }
$py = Join-Path $root "06_Python_ML\.venv\Scripts\python.exe"
$allOut = & $py -I -m pytest (Join-Path $root "06_Python_ML\tests") (Join-Path $root "09_API_FastAPI\tests") -q -p no:cacheprovider 2>&1 | Select-Object -Last 1
if ("$allOut" -notmatch '^(\d+) passed') { throw "tests failed: $allOut" }
$nAll = $Matches[1]
# p95 by the MATLAB prctile rule (position n*p/100 + 0.5), to explain the Step 41 figure of 95.6 ms
$k_log = Import-Csv (Join-Path $root "10_Dashboard_Client\logs\testbench_log.csv")
$k_x = @($k_log | ForEach-Object { [double]::Parse($_.response_ms, $ic) } | Sort-Object)
$k_pos = $k_x.Count * 0.95 + 0.5; $k_lo = [int][Math]::Floor($k_pos); $k_fr = $k_pos - $k_lo
$p95m = $k_x[$k_lo - 1] + $k_fr * ($k_x[$k_lo] - $k_x[$k_lo - 1])
if ([Math]::Round($p95m, 1) -ne 95.6) { throw "MATLAB-rule p95 is not 95.6 ms: $p95m" }

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
$global:Methods["42"] = @{
  Approach = @(
    "The log of the end-to-end test bench (Step 41) holds, for each of the 388 held-out records, what the integrated system answered - the three conventional diagnoses computed in MATLAB, the ML class and its seven probabilities returned by the Python service - and how long the service request took. Each logged answer was compared, record by record, with the answer saved by the offline analysis (ml_predictions.csv of Step 22 and conventional_predictions.csv of Step 16).",
    "Fidelity is the share of records for which the integrated system gives exactly the offline ML class (Analysis Plan Eq. 47); a failed call or a missing record counts as a mismatch. The probabilities and the conventional answers were compared in the same way. The response time - the time between sending a request and receiving the answer - was summarised by its median and 95th percentile and judged against the approved target of 1 s.")
  Why = @(
    "An integrated tool is only trustworthy if it reproduces the analysis it is built on: the thesis's accuracy results apply to the dashboard only when its answers are identical, record by record, to the offline answers.",
    "The 95th percentile describes the slow end that a user would notice, which the mean or median alone would hide. All records, including the first five warm-up calls, are counted in the main figure, because the plan says 'over all test records' and this is the cautious choice.")
  Settings = @(
    @("Records", "all 388 held-out records (benchmark 117, internal test 70, external test 201), as run in Step 41 (D39)"),
    @("Offline answers", "ML: ml_predictions.csv (class and 7 probabilities); conventional: column result (after the upper normality gate, as shown by the dashboard)"),
    @("Match rule", "exact equality of the class, of each parsed probability and of each conventional answer; a failed call or missing record is a mismatch"),
    @("Response time", "response_ms of the log (tic/toc around webwrite in MATLAB); main: all 388 calls; sensitivity: without the 5 warm-up calls"),
    @("Percentile rule", "numpy.percentile with linear interpolation (as in Step 38)"),
    @("Requirements", "F = 1 (100 %); 95th percentile < 1000 ms (Analysis Plan item 15)"),
    @("True labels", "not read"))
  Eqs = @(
    @{ Eq = 'F=n_"match"/N'; Where = @(@('F', 'fidelity of the integrated system (fraction; required value 1)'), @('n_match', 'held-out records for which the logged ML class equals the offline class'), @('N', 'held-out records sent to the integrated system (388)')) },
    @{ Eq = 't_"p95"=Q_(0.95) (t_1,...,t_N)'; Where = @(@('t_p95', '95th percentile of the response times [ms]'), @('t_i', 'response time of request i [ms]'), @('Q_0.95', 'the 0.95 quantile with linear interpolation between ordered values')) })
  Tools = @("06_Python_ML/src/analysis/step42_integration.py (comparison, Table 4.11, Figure 4.21, integration files); tests/test_integration.py; make_chapter4.py (now also rebuilds Table 4.11 and Figure 4.21)")
  Refs = @()
}
$global:Closings["42"] = @{
  Achieved = @(
    ("Fidelity of the integrated system is 100 %: the ML class was identical to the offline result for all " + $k_N + " held-out records, and so were all seven probabilities and the Rogers, IEC 60599 and Duval answers."),
    ("The service answered within " + (F1 $rt.median) + " ms (median) and " + (F1 $rt.p95) + " ms (95th percentile), about one tenth of the 1 s target; no call failed."),
    "Table 4.11 and Figure 4.21 exist and are rebuilt by the one-command Chapter 4 script; Stage H (integration and test bench) is complete.")
  Record = @(
    @("Step", "42 - Evaluate fidelity and response time"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "13 October 2026"), @("Status", "Done (Stage H complete)"),
    @("Main inputs", "testbench_log.csv (DF76); ml_predictions.csv (DF25); conventional_predictions.csv (DF9)"),
    @("Main outputs", "Table 4.11 (DF82); Figure 4.21 (DF83); 11_Results/integration (DF84); this report = the integration report"),
    @("Checks", ("F = 1 (" + $k_N + "/" + $k_N + "); p95 " + (F1 $rt.p95) + " ms < 1000 ms; rebuild check 83/83 identical; " + $nAll + " of " + $nAll + " tests pass")),
    @("Decisions", "D40 (rules of the integration evaluation)"))
  Helps = @(
    "Chapter 4 (framework performance) can report that the dashboard gives exactly the offline answers and responds well within interactive limits, so every accuracy result of Chapter 4 also describes the integrated tool.",
    "Every planned Chapter 4 table (4.1-4.13) and figure (4.1-4.24) now exists in 11_Results; Figure 4.4, Table 4.10 and Figures 4.18-4.20 and 4.22 were made in MATLAB (Steps 17 and 35-41).")
  Open = @(
    "The times are from one run on one laptop with the service on the same computer; a utility network would add network delay. They describe this set-up, not a general product.",
    ("The conventional diagnoses in MATLAB take longer than the ML request (median " + (F1 $ct.median) + " ms against " + (F1 $rt.median) + " ms), as noted in Step 41; this was not investigated because it does not affect any result. The total per record stays below 1 s for 95 % of records, but " + $k_slow.Count + " records took longer (up to " + (F1 $tt.max) + " ms); the plan sets the 1 s target for the service request, not for the whole record."),
    "The scope is all 388 held-out records (D39); the fidelity is also given for each data role, so the 187 internal-test and benchmark records can be reported alone if the researcher prefers.",
    "The service is started by hand (run_service.ps1) before the dashboard or the test bench is used.")
  Exclude = @()
}
$global:StepSources["42"] = @("DF76", "DF25", "DF9", "DF27", "SW1", "SW6", "DF82", "DF83", "DF84", "DF85", "DF47")
function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed = "13 October 2026") {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "42" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }
$PAGEW = 453

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "42" "Evaluate fidelity and response time (integration report)" "Claude Code (this chat)"
Summary ("The integrated system - Simulink model, MATLAB dashboard functions and Python service - gave exactly the offline answers for all " + $k_N + " held-out records: the same ML class, the same seven probabilities and the same Rogers, IEC 60599 and Duval diagnoses. Fidelity is therefore 100 %, as required, with no failed call and no mismatch to trace. The service answered in " + (F1 $rt.median) + " ms (median) and " + (F1 $rt.p95) + " ms (95th percentile), far below the 1 s target. Table 4.11 and Figure 4.21 are made, and Stage H is complete.")
H1N "Purpose of this step"
Body "This step answers the integration question of the thesis: does the integrated framework give the same answers as the offline analysis, and is it fast enough for interactive use? The Analysis Plan (Section 10) requires 100 % fidelity and proposes a 95th-percentile response time below 1 s (approved item 15). This report is also the integration report named in the roadmap."
MethodSection "42"
H1N "What was done, step by step"
NumItem "1" "Read the Step 41 outputs (log, run information, checks) and confirmed that Steps 39-41 had been completed in the parallel MATLAB session."
NumItem "2" "Fixed the evaluation rules before computing anything (decision D40)."
NumItem "3" "Wrote step42_integration.py: join the log with the offline files, compare every answer, compute fidelity and time statistics, write Table 4.11, Figure 4.21 and the integration files."
NumItem "4" "Added the program to make_chapter4.py, protected the MATLAB-made tables and figures there, and ran the rebuild check."
NumItem "5" ("Wrote three tests (test_integration.py) and ran the whole suite (" + $nAll + " tests).")
H1N "Results"
H2 "Table 4.11  Integration fidelity and response time"
$k_rows = @()
foreach ($r in $k_tab) {
  $v = [double]::Parse($r.value, $ic)
  $val = if ($r.unit -eq "fraction") { ($v * 100).ToString("F1", $ic) + " %" } elseif ($r.unit -eq "count") { ([int]$v).ToString() } else { $v.ToString("F1", $ic) + " ms" }
  $req = if ($r.requirement) { $r.requirement + " - " + $r.passed } else { "" }
  $grp = @{ "Fidelity" = ""; "Response time (service request)" = "Service request: "; "Conventional diagnoses in MATLAB" = "Conventional diagnoses (MATLAB): "; "Total per record (information)" = "Total per record: " }[$r.group]
  if ($null -eq $grp) { throw ("unknown group " + $r.group) }
  $k_rows += , @(($grp + $r.measure), $r.records, $val, $req)
}
AddTable @("Measure", "Records", "Value", "Requirement - met") $k_rows @(225, 60, 70, 95)
Body "Fidelity rows first, then the times: the service request (judged against the target), the conventional diagnoses in MATLAB and the total per record (information only)."
Caption "Figure 4.21  Response times of the 388 service requests in the test bench: (a) in run order, (b) cumulative distribution"
Pic (Join-Path $res "figures\F4_21_response_times.png") $PAGEW
H2 "What the results mean"
Bullet ("Fidelity. Every one of the " + $k_N + " records got exactly the offline ML class, in each data role (benchmark, internal test and external test: 100 % each). The seven probabilities were equal digit for digit (largest difference 0), and the dashboard's Rogers, IEC 60599 and Duval answers equal the offline results for all records. There is no mismatch to trace (integration_mismatches.csv is empty).")
Bullet ("Response time. Median " + (F1 $rt.median) + " ms and 95th percentile " + (F1 $rt.p95) + " ms over all " + $rt.n + " calls (range " + (F1 $rt.min) + " to " + (F1 $rt.max) + " ms). Without the 5 warm-up calls: " + (F1 $rw.median) + " and " + (F1 $rw.p95) + " ms - the warm-up calls hardly matter. Figure 4.21a shows no drift over the run.")
Bullet ("Compared with Step 38. From Python on the same laptop the service answered in " + (F1 $k_s38.response_ms.median) + " ms (median); through MATLAB's webwrite it takes " + (F1 $rt.median) + " ms. The service and the model are the same, so the extra time is most likely on the MATLAB side of the call (webwrite and its JSON handling); it was not measured separately.")
Bullet ("Whole record. The total time per record (conventional diagnoses + service + agreement flag) has median " + (F1 $tt.median) + " ms and 95th percentile " + (F1 $tt.p95) + " ms; " + $k_slow.Count + " of " + $tt.n + " records took more than 1 s in total, the longest " + (F1 $tt.max) + " ms (request " + $k_top.event + ", " + $k_top.record_id + "). Most of the total is the MATLAB conventional diagnosis (median " + (F1 $ct.median) + " ms). The plan judges only the service request, so the total is reported for information.")
Bullet ("Percentile rule. The Step 41 report gave a 95th percentile of 95.6 ms, from MATLAB's prctile, which places the percentile at position n x 0.95 + 0.5; Table 4.11 uses linear interpolation (numpy), which gives " + (F1 $rt.p95) + " ms. Both rules describe the same 388 values; the conclusion is the same.")
H1N "Checks"
AddTable @("Check (roadmap: fidelity is 100 %; any mismatch traced and fixed before writing)", "Result") @(
  , @(("Fidelity F = 1 (" + $k_N + " of " + $k_N + " ML classes identical)"), "PASS")
  , @("Probabilities and the three conventional answers identical for every record", "PASS - largest difference 0")
  , @("Every held-out record in the log once; no extra or duplicated record; model hash identical in every row", "PASS")
  , @("No failed call", "PASS - 0 of 388")
  , @(("95th percentile of the response time below 1000 ms"), ("PASS - " + (F1 $rt.p95) + " ms"))
  , @("Chapter 4 rebuild from scratch (83 files, including Table 4.11 and Figure 4.21)", "PASS - identical")
  , @("Whole automated test suite", ("PASS - " + $nAll + " of " + $nAll))
) @(330, 120)
H1N "Problems and fixes"
Bullet "Register numbers: the parallel MATLAB session had registered its Step 39 files as DF71-DF73, the numbers the Step 38 files had been given shortly before; its update replaced the Step 38 entries. The Step 39 entries were kept, the Step 38 files were registered again as DF79-DF81, the Step 38 update script now uses those numbers, and the Step 38 report was rebuilt as version 2. The Step 42 update script stops if one of its numbers is already used by another step."
Bullet "The rerun of the Step 38 register script had set the glossary entry for the decision numbers back to D1-D36; that line was removed from the Step 38 script and the entry now reads D1-D40."
Bullet "The first version of Figure 4.21 placed the legend over the slowest request; the vertical axis was extended."
H1N "Decisions"
Bullet "D40 (closed, procedural): rules of the integration evaluation - inputs and the gated conventional answers, the fidelity and match rules, the response time over all records with the warm-up calls kept (sensitivity without), the percentile rule, no confidence interval for one run on one computer, and the outputs."
H1N "Files produced"
Bullet "06_Python_ML/src/analysis/step42_integration.py; 06_Python_ML/tests/test_integration.py; make_chapter4.py (updated)"
Bullet "11_Results/tables/T4_11_integration.csv; 11_Results/figures/F4_21_response_times (PNG, PDF, CSV); 11_Results/integration/integration_comparison.csv, integration_mismatches.csv, integration_checks.json, code_manifest_step42.sha256; 11_Results/chapter4_manifest.sha256 (83 files)"
Closing "42" 0 "Step 43 (Claude Code): write Chapters 3 to 5 in Word (12 pt, 1.15 spacing) using only the tables and figures in 11_Results; every number must trace to a saved file and nothing marked TO VERIFY may remain." $global:Blocks["42"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $r2 = $doc.Content; $r2.SetRange($r2.End - 2, $r2.End - 1); if ($r2.Text -ne [string][char]13) { break }; $r2.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_42_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_42_Report.docx") -Force
("SAVED Step_42_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " | " + $_.ScriptStackTrace) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
