$ErrorActionPreference = "Stop"
# build_step_report_29.ps1 - Word report of roadmap Step 29. Every number is read from 08_Statistical_Analysis and 11_Results.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report29_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8

$inv = [Globalization.CultureInfo]::InvariantCulture
function D([string]$v) { [double]::Parse($v, $inv) }
function F3([string]$v) { (D $v).ToString("0.000", $inv) }
function CI([object]$r, [string]$k) { (F3 $r.$k) + " [" + (F3 $r.($k + "_lo")) + ", " + (F3 $r.($k + "_hi")) + "]" }
$sa  = Join-Path $root "08_Statistical_Analysis"
$fig = Join-Path $root "11_Results\figures"
$pf  = Import-Csv (Join-Path $sa "performance_measures.csv")
$df  = Import-Csv (Join-Path $sa "differences.csv")
$fl  = Import-Csv (Join-Path $root "11_Results\ml\ml_first_look.csv")
$SETS = "Internal test", "IEC TC 10 (power transformers)", "Li 2019"
$LAB = @{ ML = "ML (selected model)"; Rogers = "Rogers Ratio"; IEC60599 = "IEC 60599 ratio"; Duval = "Duval Triangle 1" }
function P([string]$set, [string]$m, [string]$v = "primary") { $pf | Where-Object { $_.evaluation_set -eq $set -and $_.method -eq $m -and $_.variant -eq $v } }
function G([string]$set, [string]$m) { $df | Where-Object { $_.evaluation_set -eq $set -and $_.method -eq $m -and $_.variant -eq "primary" } }

# checks of the statements made in the text
$map = @{ "Internal test" = "Internal test - independent"; "IEC TC 10 (power transformers)" = "IEC TC 10 - power transformers"; "Li 2019" = "Li 2019 - independent" }
foreach ($s in $SETS) { $a = D (P $s "ML").macro_f1; $b = D ($fl | Where-Object { $_.evaluation_set -eq $map[$s] }).macro_f1; if ([math]::Abs($a - $b) -gt 1e-6) { throw "ML differs from Step 22 on $s" } }
foreach ($m in "Rogers", "IEC60599", "Duval") { if ((D (G "Internal test" $m).strict_gap_lo) -le 0) { throw "internal: ML not clearly above $m" } }
$gD = G "IEC TC 10 (power transformers)" "Duval"; $gI = G "IEC TC 10 (power transformers)" "IEC60599"; $gR = G "IEC TC 10 (power transformers)" "Rogers"
if (-not ((D $gD.strict_gap) -lt 0 -and (D $gD.strict_gap_lo) -lt 0 -and (D $gD.strict_gap_hi) -gt 0)) { throw "IEC Duval statement" }
if (-not ((D $gI.strict_gap_lo) -lt 0 -and (D $gR.strict_gap_lo) -gt 0)) { throw "IEC ratio statement" }
$liD = G "Li 2019" "Duval"; if ((D $liD.strict_gap_lo) -le 0) { throw "Li Duval primary statement" }
if ((D (P "Li 2019" "Duval" "no_gate").strict_accuracy) -le (D (P "Li 2019" "ML").strict_accuracy)) { throw "Li no-gate statement" }
$crit = @($df | Where-Object { $_.variant -eq "primary" -and $_.primary_set -eq "True" -and $_.method -ne "Duval" -and $_.criterion2_conditional_gap_smaller -ne "True" })
if ($crit.Count) { throw "criterion-2 preview statement" }
$testOut = & (Join-Path $root "06_Python_ML\.venv\Scripts\python.exe") -I -m pytest (Join-Path $root "06_Python_ML\tests") -q -p no:cacheprovider 2>&1 | Select-Object -Last 1
if ("$testOut" -notmatch '^(\d+) passed') { throw "tests failed: $testOut" }
$global:S29 = @{ B = 2000; tests = ($Matches[1] + " of " + $Matches[1] + " tests pass") }

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
. (Join-Path $sp "report_entries_29.ps1")

function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed = "12 October 2026") {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "29" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }
$PAGEW = 453

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "29" "Compute the performance measures with 95 % confidence intervals" "Claude Code (this chat)"
Summary ("Results are mixed and are reported as found. On the internal test set the ML model is clearly the most accurate (strict accuracy " + (F3 (P "Internal test" "ML").strict_accuracy) + " against at most " + (F3 (P "Internal test" "Duval").strict_accuracy) + "). On the IEC TC 10 benchmark of inspected power transformers, the Duval Triangle scores higher than the ML model (" + (F3 (P "IEC TC 10 (power transformers)" "Duval").strict_accuracy) + " against " + (F3 (P "IEC TC 10 (power transformers)" "ML").strict_accuracy) + "), but the difference lies within its uncertainty; the ML model is clearly better than Rogers there. On Li 2019 the ML model leads with the approved normality gate, but Duval leads when the gate is removed. The normality gate, which calls many low-gas faults Normal, strongly affects the conventional methods' scores. Significance tests follow in Step 30.")
H1N "Purpose of this step"
Body "This step measures, with honest uncertainty, how well the ML model and each conventional method diagnose the faults of the three test sets. It provides Tables 4.3 and 4.5 and Figures 4.5 and 4.8 of Chapter 4."
MethodSection "29"
H1N "What was done, step by step"
NumItem "1" "Fixed the scoring details as decision D25 before computing any conventional-method measure on the test sets."
NumItem "2" "Wrote step29_measures.py and tests that check its measures against scikit-learn and a hand-computed Wilson interval."
NumItem "3" "Ran it (about three minutes). The ML values equal the first-look values of Step 22, which confirms the scoring."
NumItem "4" "Improved the confusion-matrix colours (white for 0 % as the plan specifies) and label layout, and ran it again: all numbers identical."
H1N "What we found"
H2 "Table 4.5 - main comparison on each test set (primary scoring, 95 % CI)"
foreach ($s in $SETS) {
  $rows = @()
  foreach ($m in "ML", "Rogers", "IEC60599", "Duval") { $r = P $s $m; $rows += , @($LAB[$m], (CI $r "strict_accuracy"), (CI $r "conditional_accuracy"), (CI $r "coverage"), (CI $r "macro_f1")) }
  $n = (P $s "ML").n
  H3 ($s + " (n = " + $n + ")")
  AddTable @("Method", "Strict accuracy", "Conditional accuracy", "Coverage", "Macro-F1") $rows @(105, 90, 90, 90, 90)
  if ($s -like "IEC*") { Ital "Home-advantage caveat: the IEC 60599 ratio limits were refined using the IEC TC 10 cases (Duval and dePablo, 2001), so the conventional methods may score higher here than on new data." }
}
H2 "Table 4.3 - conventional methods: answers given (primary scoring)"
$rows = @()
foreach ($s in $SETS) { foreach ($m in "Rogers", "IEC60599", "Duval") { $r = P $s $m; $rows += , @($s, $LAB[$m], $r.n, $r.n_nd, $r.n_dt, $r.n_dual, $r.n_normal_answers) } }
AddTable @("Test set", "Method", "Records", "ND", "DT", "D1/D2", "Normal answers") $rows @(120, 95, 50, 40, 40, 50, 60)
H2 "Differences: ML minus each method (paired bootstrap 95 % CI)"
$rows = @()
foreach ($s in $SETS) { foreach ($m in "Rogers", "IEC60599", "Duval") { $g = G $s $m; $rows += , @($s, $LAB[$m], ((F3 $g.strict_gap) + " [" + (F3 $g.strict_gap_lo) + ", " + (F3 $g.strict_gap_hi) + "]"), (F3 $g.conditional_gap), ((F3 $g.macro_f1_gap) + " [" + (F3 $g.macro_f1_gap_lo) + ", " + (F3 $g.macro_f1_gap_hi) + "]")) } }
AddTable @("Test set", "Compared with", "Strict accuracy gap", "Conditional accuracy gap", "Macro-F1 gap") $rows @(115, 95, 105, 70, 105)
Body "A positive gap means the ML model scored higher. An interval that includes 0 means the data cannot tell the two apart; Step 30 adds the formal paired tests."
H2 "How much the normality gate and the dual-answer rule matter (strict accuracy)"
$rows = @()
foreach ($s in $SETS) { foreach ($m in "Rogers", "IEC60599", "Duval") { $rows += , @($s, $LAB[$m], (F3 (P $s $m).strict_accuracy), (F3 (P $s $m "lower_gate").strict_accuracy), (F3 (P $s $m "no_gate").strict_accuracy), (F3 (P $s $m "dual_wrong").strict_accuracy)) } ; $rows += , @($s, $LAB["ML"], (F3 (P $s "ML").strict_accuracy), "-", "-", "-") }
AddTable @("Test set", "Method", "Upper gate (primary)", "Lower gate", "No gate", "Dual answer wrong") $rows @(115, 95, 65, 60, 55, 65)
Body "The ML model does not use the gate (it learned its own Normal class), so its value is the same in every column."
Caption "Figure 4.5a  Confusion matrices of the conventional methods - internal test set (n = 61)"
Pic (Join-Path $fig "F4_5a_confusion_conventional_internal.png") $PAGEW
Caption "Figure 4.5b  Confusion matrices of the conventional methods - IEC TC 10 power transformers (n = 58, merged classes)"
Pic (Join-Path $fig "F4_5b_confusion_conventional_iec_tc10.png") $PAGEW
Caption "Figure 4.5c  Confusion matrices of the conventional methods - Li 2019 (n = 86)"
Pic (Join-Path $fig "F4_5c_confusion_conventional_li2019.png") $PAGEW
Caption "Figure 4.8  Confusion matrices of the ML model on the three test sets"
Pic (Join-Path $fig "F4_8_confusion_ml.png") $PAGEW
Body "Each cell: count and row percentage; white = 0 %, dark blue = 100 % of the true class. Rows: true class; columns: answer given, including Normal, D1/D2, DT and ND where they occur."
H2 "What this means"
Bullet "Internal test (same source as the training data): the ML model is clearly better than all three methods; every interval of the strict-accuracy gap lies above zero."
Bullet ("IEC TC 10 (inspected power transformers): Duval " + (F3 (P "IEC TC 10 (power transformers)" "Duval").strict_accuracy) + ", ML " + (F3 (P "IEC TC 10 (power transformers)" "ML").strict_accuracy) + ", IEC " + (F3 (P "IEC TC 10 (power transformers)" "IEC60599").strict_accuracy) + ", Rogers " + (F3 (P "IEC TC 10 (power transformers)" "Rogers").strict_accuracy) + ". The gaps to Duval and IEC lie within their uncertainty; only the gap to Rogers is clear. Without the gate Duval reaches " + (F3 (P "IEC TC 10 (power transformers)" "Duval" "no_gate").strict_accuracy) + ".")
Bullet ("Li 2019: with the approved gate the ML model is clearly ahead of all three methods, but the gate calls many of Li's low-gas faults Normal (Figure 4.5c). Without the gate, Duval scores " + (F3 (P "Li 2019" "Duval" "no_gate").strict_accuracy) + " against the ML model's " + (F3 (P "Li 2019" "ML").strict_accuracy) + ". The ML model's advantage on Li therefore depends on the gate.")
Bullet "Preview of hypothesis criterion 2: for Rogers and IEC 60599, which often give no diagnosis, the ML model's lead is smaller in conditional than in strict accuracy on all three sets - part of its advantage comes from always answering. Duval always answers, so its two gaps are equal. The formal judgement of the hypothesis is made in Step 30."
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("Data version 1.0 unchanged; merged file unchanged since Step 28 (SHA-256)", "PASS")
  , @("ML measures equal the Step 22 first-look values", "PASS")
  , @("Measure functions equal scikit-learn where comparable; Wilson hand value (automated tests)", "PASS")
  , @("Re-run after the figure changes: all numbers identical", "PASS")
  , @("Text statements checked against the result files by the report builder", "PASS")
  , @("Full automated test suite", ("PASS - " + $S29.tests))
) @(300, 150)
H1N "Problems and fixes"
Bullet "The first confusion-matrix figures used a light blue for 0 % and their column labels overlapped; the colour scale now starts at white, as the plan specifies, and the labels are rotated. Numbers were not affected."
H1N "Decisions"
Bullet "D25 (procedural, within the approved plan): evaluation sets, scoring of dual, DT, Normal and ND answers, measures on answers outside the class list, interval methods, sensitivity analyses."
H1N "Files produced"
Bullet "08_Statistical_Analysis/: performance_measures.csv, per_class_measures.csv, differences.csv, confusion_matrices.csv"
Bullet "11_Results/tables/T4_3_conventional.csv, T4_5_main_comparison.csv; 11_Results/figures/F4_5a, F4_5b, F4_5c, F4_8 (PNG, PDF, CSV)"
Bullet "06_Python_ML/src/stats/step29_measures.py; 06_Python_ML/tests/test_measures.py; 03_Data/interim/step29_report.md"
Closing "29" 0 "Step 30: Friedman and Nemenyi tests for the classifiers; Cochran's Q, then McNemar tests with Holm correction for the ML model against each conventional method; Cohen's kappa between all pairs of methods; and the judgement of the research hypothesis by its three written criteria." $global:Blocks["29"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_29_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_29_Report.docx") -Force
("SAVED Step_29_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
