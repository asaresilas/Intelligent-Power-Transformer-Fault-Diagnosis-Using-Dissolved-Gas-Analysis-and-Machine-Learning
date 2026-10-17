$ErrorActionPreference = "Stop"
# build_step_report_31.ps1 - Word report of roadmap Step 31. Every number is read from 08_Statistical_Analysis.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report31_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8

$inv = [Globalization.CultureInfo]::InvariantCulture
function D([string]$v) { [double]::Parse($v, $inv) }
function F2([string]$v) { (D $v).ToString("0.00", $inv) }
function F3([string]$v) { (D $v).ToString("0.000", $inv) }
function PV([string]$v) { $x = D $v; if ($x -lt 0.001) { "< 0.001" } else { $x.ToString("0.000", $inv) } }
$sa  = Join-Path $root "08_Statistical_Analysis"
$fig = Join-Path $root "11_Results\figures"
$br  = Import-Csv (Join-Path $sa "boundary_regression.csv")
$hc  = Get-Content (Join-Path $sa "hypothesis_criteria.json") -Raw | ConvertFrom-Json
$LAB = @{ Rogers = "Rogers Ratio"; IEC60599 = "IEC 60599 ratio"; Duval = "Duval Triangle 1" }
$SETS = "Internal test", "IEC TC 10 (power transformers)", "Li 2019"
function B([string]$m, [string]$v, [string]$a) { $br | Where-Object { $_.method -eq $m -and $_.variant -eq $v -and $_.analysis -eq $a } }
# statement checks
foreach ($m in "Rogers", "IEC60599", "Duval") { if ((B $m "primary" "pooled (main)").criterion3_met -ne "False") { throw "pooled primary $m" } }
if ((B "Duval" "no_gate" "pooled (main)").criterion3_met -ne "True") { throw "Duval no-gate" }
if ((B "Rogers" "primary" "set: IEC TC 10 (power transformers)").criterion3_met -ne "True") { throw "Rogers IEC set" }
if ($hc.verdict_main_benchmark -ne "NOT SUPPORTED") { throw "verdict" }
if (@($br | Where-Object { $_.method_used -ne "maximum likelihood" }).Count) { throw "Firth statement" }
$testOut = & (Join-Path $root "06_Python_ML\.venv\Scripts\python.exe") -I -m pytest (Join-Path $root "06_Python_ML\tests") -q -p no:cacheprovider 2>&1 | Select-Object -Last 1
if ("$testOut" -notmatch '^(\d+) passed') { throw "tests failed: $testOut" }
$global:S31 = @{ exR = (B "Rogers" "primary" "pooled (main)").n_excluded_no_distance; exI = (B "IEC60599" "primary" "pooled (main)").n_excluded_no_distance
  exD = (B "Duval" "primary" "pooled (main)").n_excluded_no_distance; tests = ($Matches[1] + " of " + $Matches[1] + " tests pass") }

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
. (Join-Path $sp "report_entries_31.ps1")

function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed = "12 October 2026") {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "31" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }
$PAGEW = 453

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "31" "Test the boundary hypothesis" "Claude Code (this chat)"
$rD = B "Duval" "no_gate" "pooled (main)"
Summary ("In the main analysis (205 test records, answers after the normality gate) disagreement between the ML model and a conventional method is not significantly more frequent near that method's decision boundaries: the odds ratios per standard deviation of distance are " + (F2 (B "Rogers" "primary" "pooled (main)").or) + " (Rogers), " + (F2 (B "IEC60599" "primary" "pooled (main)").or) + " (IEC 60599) and " + (F2 (B "Duval" "primary" "pooled (main)").or) + " (Duval), all with intervals that include 1. Criterion 3 is therefore not met. When the gate is removed, Duval shows a clear boundary effect (OR " + (F2 $rD.or) + ", 95 % CI " + (F2 $rD.or_lo) + "-" + (F2 $rD.or_hi) + "): the gate's Normal answers hide it. With all three criteria decided, the research hypothesis is NOT SUPPORTED on the main benchmark, exactly as the written rule requires.")
H1N "Purpose of this step"
Body "This step answers RQ2 - where do the ML model and the conventional methods disagree, and is the disagreement concentrated near the conventional decision boundaries? - and decides criterion 3, completing the judgement of the research hypothesis."
MethodSection "31"
H1N "What was done, step by step"
NumItem "1" "Fixed the details as decision D27 before fitting any model (only the number of records without a distance had been looked at: one record for each ratio method)."
NumItem "2" "Wrote step31_boundary.py with a logistic and a Firth regression, and tests comparing it with statsmodels."
NumItem "3" "Ran it; corrected the per-set count of excluded records (the first run showed each method's total in every set) and ran it again - the fitted models were unchanged."
H1N "What we found"
H2 "Table 4.8 - disagreement against boundary distance (main analysis)"
$rows = @()
foreach ($m in "Rogers", "IEC60599", "Duval") { $r = B $m "primary" "pooled (main)"; $rows += , @($LAB[$m], $r.n, $r.n_excluded_no_distance, $r.n_disagree, (F3 $r.beta1), ((F2 $r.or) + " [" + (F2 $r.or_lo) + ", " + (F2 $r.or_hi) + "]"), (PV $r.p), $(if ($r.criterion3_met -eq "True") { "yes" } else { "no" })) }
AddTable @("Method", "Records", "Excluded", "Disagree", "beta1", "OR per SD [95 % CI]", "p", "Criterion 3 met?") $rows @(95, 45, 50, 50, 45, 95, 40, 55)
Caption "Figure 4.12  Probability of disagreement against standardised boundary distance (205 primary test records)"
Pic (Join-Path $fig "F4_12_disagreement_vs_distance.png") $PAGEW
Body "Line and band: fitted logistic curve with 95 % band; points: observed disagreement rate in ten equal-sized distance groups with Wilson 95 % bars; ticks: individual records (top = disagree, bottom = agree). A curve that falls from left to right supports the boundary hypothesis."
H2 "Sensitivity analyses (odds ratio per SD [95 % CI])"
$rows = @()
foreach ($m in "Rogers", "IEC60599", "Duval") { foreach ($v in "primary", "no_gate") { foreach ($a in @("pooled (main)", "pooled + test-set indicators") + ($SETS | ForEach-Object { "set: " + $_ })) { $r = B $m $v $a; $rows += , @($LAB[$m], $(if ($v -eq "primary") { "with gate" } else { "no gate" }), ($a -replace "^set: ", ""), $r.n, ((F2 $r.or) + " [" + (F2 $r.or_lo) + ", " + (F2 $r.or_hi) + "]"), (PV $r.p), $(if ($r.criterion3_met -eq "True") { "yes" } else { "no" })) } } }
AddTable @("Method", "Gate", "Analysis", "Records", "OR per SD [95 % CI]", "p", "Crit. 3") $rows @(88, 50, 120, 50, 90, 42, 38)
H2 "What this means"
Bullet "With the approved gate, none of the three methods shows a significant boundary effect when all test records are pooled. Two methods have odds ratios below 1 (fewer disagreements far from the boundary), in the direction the hypothesis expects, but the evidence is not strong enough."
Bullet ("Without the gate, Duval shows a strong boundary effect: each standard deviation further from a zone edge roughly halves the odds of disagreement (OR " + (F2 $rD.or) + "). The gate turns many low-gas faults into Normal answers, which disagree with the ML model wherever they lie in the triangle and so mask the boundary pattern.")
Bullet "Rogers shows a significant boundary effect on the IEC TC 10 set alone, but IEC 60599 and Duval do not, so criterion 3 is not met on the main benchmark either."
H2 "Final judgement of the research hypothesis (Analysis Plan Section 2.1)"
$rows = @()
foreach ($s in $SETS) {
  $h = $hc.$s
  $c3 = ($h.criterion3_beta1_negative_ci_excludes_0.PSObject.Properties | ForEach-Object { ($_.Name -replace "IEC60599", "IEC") + " " + $(if ($_.Value) { "yes" } else { "no" }) }) -join ", "
  $rows += , @($s, $(if ($h.criterion1_met) { "met" } else { "not met" }), $(if ($h.criterion2_met) { "met" } else { "not met (Duval)" }), ($c3 + " -> " + $(if ($h.criterion3_met) { "met" } else { "not met" })))
}
AddTable @("Test set", "Criterion 1 (more accurate, significant)", "Criterion 2 (advantage from ND cases)", "Criterion 3 (boundary effect, per set)") $rows @(105, 110, 110, 135)
Bullet ("Verdict on the main benchmark (IEC TC 10 power transformers, decision D26): " + $hc.verdict_main_benchmark + ". The ML model is not significantly more accurate than IEC 60599 or Duval there, and the disagreements are not concentrated near the boundaries.")
Bullet "On the internal and Li 2019 test sets the hypothesis is partly supported: criterion 1 is met (with the approved gate) and criterion 2 is met against Rogers and IEC 60599, but criteria 2 (against Duval) and 3 are not."
Bullet "This is reported as found. It is a meaningful result: a carefully validated ML model does not clearly outperform a well-established expert method on inspection-confirmed cases, while it does on data like its training data and keeps its accuracy with fewer gases (Step 27)."
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("Data version 1.0 and merged file unchanged (SHA-256)", "PASS")
  , @("Logistic regression equals statsmodels; Firth finite under separation (automated tests)", "PASS")
  , @("No separation occurred (all fits by maximum likelihood)", "PASS")
  , @("Text statements checked against the result files by the report builder", "PASS")
  , @("Full automated test suite", ("PASS - " + $S31.tests))
) @(300, 150)
H1N "Problems and fixes"
Bullet "The first run reported each method's total number of excluded records in every per-set row; the count is now computed per set. Fitted models and conclusions did not change."
H1N "Decisions"
Bullet "D27 (procedural, within the approved plan): records, disagreement rule, gate sensitivity, distances, Firth fallback, how criterion 3 is read."
H1N "Files produced"
Bullet "08_Statistical_Analysis/boundary_regression.csv, boundary_data.csv; hypothesis_criteria.json (criterion 3 and verdict added)"
Bullet "11_Results/tables/T4_8_boundary.csv; 11_Results/figures/F4_12_disagreement_vs_distance (PNG, PDF, CSV)"
Bullet "06_Python_ML/src/stats/step31_boundary.py; 06_Python_ML/tests/test_boundary.py; 03_Data/interim/step31_report.md"
Closing "31" 0 "Step 32: one script rebuilds every Chapter 4 table and figure from the saved files (including Figures 4.6, 4.9, 4.10 and 4.13) in the style of Analysis Plan Section 12.2; deleting 11_Results and running it again must give identical files." $global:Blocks["31"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_31_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_31_Report.docx") -Force
("SAVED Step_31_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
