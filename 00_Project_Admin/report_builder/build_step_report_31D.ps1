$ErrorActionPreference = "Stop"
# build_step_report_31D.ps1 - Word report of roadmap Step 31D (Study 2 measures). Every number from 08_Statistical_Analysis/study2.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report31D_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8
$inv = [Globalization.CultureInfo]::InvariantCulture
function D([string]$v) { $o = 0.0; if (-not [double]::TryParse($v, [Globalization.NumberStyles]::Float, $inv, [ref]$o)) { throw ("cannot read number '" + $v + "'") }; $o }
function F3([string]$v) { (D $v).ToString("0.000", $inv) }
function PV([string]$v) { $x = D $v; if ($x -lt 0.001) { "< 0.001" } else { $x.ToString("0.000", $inv) } }
$d2 = Join-Path $root "08_Statistical_Analysis\study2"
$fig = Join-Path $root "11_Results\figures"
$MEAS = Import-Csv (Join-Path $d2 "measures.csv") | Where-Object variant -eq "primary"
$CON = Import-Csv (Join-Path $d2 "contrasts.csv") | Where-Object variant -eq "primary"
$REJ = Import-Csv (Join-Path $d2 "reject_option.csv") | Where-Object { $_.variant -eq "primary" -and $_.model -eq "C" }
$SRC = "DISTRAIN", "DISTEST", "IECTC10", "LI2019"
$SN = @{ DISTRAIN = "Dissanayake training"; DISTEST = "Dissanayake unseen"; IECTC10 = "IEC TC 10"; LI2019 = "Li 2019" }
$MN = @{ A = "A released"; B = "B pooled"; C = "C hybrid"; IEC60599 = "IEC 60599"; Rogers = "Rogers"; Duval = "Duval" }
function Mm([string]$s, [string]$m) { $MEAS | Where-Object { $_.held_out -eq $s -and $_.model -eq $m } }
$iecA = Mm "IECTC10" "A"; $iecC = Mm "IECTC10" "C"; $iecD = Mm "IECTC10" "Duval"
$testOut = & (Join-Path $root "06_Python_ML\.venv\Scripts\python.exe") -I -m pytest (Join-Path $root "06_Python_ML\tests") -q -p no:cacheprovider 2>&1 | Select-Object -Last 1
if ("$testOut" -notmatch '^(\d+) passed') { throw "tests failed: $testOut" }
$nT = $Matches[1]

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
$global:Methods["31D"] = @{
  Approach = @(
    "From the saved Study 2 predictions only, each model and each conventional method was scored on every held-out source: macro-F1 over the classes present in that source (primary), strict and balanced accuracy, and coverage and conditional accuracy for the conventional methods (with the approved normality gate and the D1/D2 rule of D25).",
    "Uncertainty: Wilson intervals for proportions and a stratified bootstrap (2000 resamples within each class, the same resample for every model - paired) for macro-F1 and for the differences B - A, C - B and C - best conventional method; McNemar with Holm correction on correctness.",
    "Reject option (Chow, 1970): the threshold tau was set, from model C's probabilities only, so that C answers as many records as IEC 60599 (or Rogers) does on that source; C's accuracy on the answered records was then compared with the method's conditional accuracy. Decision D29 recorded, before any number was computed, which model the rule uses and how tau is kept fixed in the bootstrap.")
  Why = @(
    "Comparing at equal coverage is the fair way to judge a model that may decline to answer against methods that sometimes give no diagnosis.",
    "Paired bootstrap differences use the same records for both models, so they show whether a gain is larger than the uncertainty.")
  Settings = @(
    @("Records", "held-out sources of Step 31C (primary variant): Dissanayake training 439, Dissanayake unseen 61, IEC TC 10 58, Li 2019 85"),
    @("Scoring", "six classes; macro-F1 over the classes present; D1/D2 correct for D1 or D2; upper normality gate; ND wrong in strict accuracy"),
    @("Intervals", "Wilson; stratified paired bootstrap B = 2000, seed 20261012"),
    @("Contrasts", "B - A (external sources), C - B, C - best conventional (highest strict accuracy, D29); McNemar with Holm per source"),
    @("Reject option", "model C (D29); tau from probabilities only, fixed in the bootstrap"))
  Eqs = @(@{ Eq = '"Coverage"(τ)=1/N ∑_(i=1)^N▒1[max_k p_ik≥τ]'; Where = @(@('τ', 'threshold chosen so that the model covers as many records as the conventional method'), @('p_ik', 'probability of class k for record i')) })
  Tools = @("06_Python_ML/src/study2/step31d_measures.py (measures, contrasts, reject option, Tables 4.12-4.13, Figures 4.23-4.24)")
  Refs = @("M32", "M20", "M29", "M30", "M21")
}
$global:Closings["31D"] = @{
  Achieved = @("All Study 2 measures, contrasts and reject-option comparisons are computed with intervals, for the primary analysis and both sensitivity variants.", "Tables 4.12-4.13 and Figures 4.23-4.24 are produced with their data files.")
  Record = @(
    @("Step", "31D - Measures, paired contrasts and reject option (Study 2)"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "12 October 2026"), @("Status", "Done - EXPLORATORY"),
    @("Main inputs", "07_Experiments/2026-10-12_study2_loso/predictions.csv; 03_Data/study2/study2_pooled.csv"),
    @("Main outputs", "08_Statistical_Analysis/study2/ (measures, contrasts, reject_option, risk_coverage); Tables T4_12, T4_13; Figures F4_23, F4_24"),
    @("Checks", ("manifest verified; adding model A to one sensitivity variant left the primary results identical; " + $nT + " of " + $nT + " tests pass")),
    @("Decisions", "D29 (clarification of the protocol, before computing)"))
  Helps = @("Step 31E applies the three pre-registered decision rules to these results.")
  Open = @(
    "All Study 2 results are exploratory: IEC TC 10 and Li 2019 had already been seen. A positive result needs confirmation on fresh data (Step 31F).",
    "Many intervals are wide (58-85 records per external source); several lower limits sit exactly at 0, where only one or two records differ between the models.")
  Exclude = @()
}
$global:StepSources["31D"] = @("DF42", "DF41", "DF43", "DF44", "DF40", "SW1")
function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed = "12 October 2026") {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "31D" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }
$PAGEW = 453

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "31D" "Measures, paired contrasts and reject option (Study 2)" "Claude Code (this chat)"
Summary ("Exploratory results. On the three outside sources, training on several sources (B) and adding the conventional answers (C) raise macro-F1 a little in most cases - on IEC TC 10 from " + (F3 $iecA.macro_f1) + " (released model) to " + (F3 $iecC.macro_f1) + " (hybrid), against " + (F3 $iecD.macro_f1) + " for Duval - but the gains are within their uncertainty. The clearest result is the reject option: when the hybrid model answers as many records as IEC 60599 does, it is more accurate on every source (on IEC TC 10 the interval of the gain includes 0). Step 31E applies the pre-registered decision rules.")
H1N "Purpose of this step"
Body "This step measures how well the Study 2 models perform on data sources they never saw, and whether the three remedies improve on the released model and on the conventional methods."
MethodSection "31D"
H1N "What was done, step by step"
NumItem "1" "Recorded decision D29 (which model the reject-option rule uses; how the best conventional method is chosen; tau fixed in the bootstrap) before computing any value."
NumItem "2" "Wrote step31d_measures.py and ran it (about 1.5 minutes)."
NumItem "3" "For the equal-source-weight variant, model A's predictions were taken from the primary variant (model A does not depend on training weights); re-running confirmed that the primary results did not change."
H1N "What we found"
H2 "Table 4.12 - results by held-out source (primary; exploratory)"
foreach ($s in $SRC) {
  $rows = @()
  foreach ($m in "A", "B", "C", "IEC60599", "Rogers", "Duval") { $r = Mm $s $m; if ($r) { $rows += , @($MN[$m], ((F3 $r.macro_f1) + " [" + (F3 $r.macro_f1_lo) + ", " + (F3 $r.macro_f1_hi) + "]"), ((F3 $r.strict_accuracy) + " [" + (F3 $r.strict_lo) + ", " + (F3 $r.strict_hi) + "]"), (F3 $r.balanced_accuracy), (F3 $r.coverage)) } }
  H3 ($SN[$s] + " held out (n = " + (Mm $s "B").n + "; classes " + ((((Mm $s "B").classes -split "/") | ForEach-Object { $_ -replace "^T12$", "T1/T2" }) -join ", ") + ")")
  AddTable @("Model / method", "Macro-F1 [95 % CI]", "Strict accuracy [95 % CI]", "Balanced accuracy", "Coverage") $rows @(95, 115, 115, 70, 60)
}
Caption "Figure 4.23  Study 2: macro-F1 with 95 % bootstrap interval by held-out source (exploratory)"
Pic (Join-Path $fig "F4_23_study2_macro_f1.png") $PAGEW
H2 "Table 4.13 - paired contrasts (primary; exploratory)"
$rows = @(); foreach ($c in $CON) { $rows += , @($SN[$c.held_out], ($c.contrast -replace "IEC60599", "IEC 60599"), ((F3 $c.macro_f1_diff) + " [" + (F3 $c.diff_lo) + ", " + (F3 $c.diff_hi) + "]"), $c.b, $c.c, (PV $c.p), (PV $c.p_holm)) }
AddTable @("Held out", "Contrast", "Macro-F1 difference [95 % CI]", "b", "c", "p", "p (Holm)") $rows @(90, 85, 125, 30, 30, 45, 50)
Body "b: first model right and second wrong; c: the reverse. The best conventional method was Duval on every source. When the Dissanayake training set is held out, only 204 records remain for training, and the hybrid model is worse than the pooled one there."
H2 "Reject option: hybrid model C at the coverage of IEC 60599 and Rogers"
$rows = @(); foreach ($r in $REJ) { $rows += , @($SN[$r.held_out], ($r.method -replace "IEC60599", "IEC 60599"), (F3 $r.method_coverage), (F3 $r.selective_accuracy), (F3 $r.method_conditional_accuracy), ((F3 $r.diff) + " [" + (F3 $r.diff_lo) + ", " + (F3 $r.diff_hi) + "]")) }
AddTable @("Held out", "Compared with", "Coverage", "C: accuracy on answered", "Method: conditional accuracy", "Difference [95 % CI]") $rows @(90, 70, 55, 75, 85, 105)
Caption "Figure 4.24  Accuracy on answered records against coverage (models: lines; conventional methods: points)"
Pic (Join-Path $fig "F4_24_study2_accuracy_coverage.png") $PAGEW
Body "A model line above a method's point means the model is more accurate when it answers as many records as that method. The hybrid model's line (C) lies above every conventional point on all four sources; the released model (A) lies below Duval on IEC TC 10 when it answers every record."
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("Study 2 data manifest verified; predictions from Step 31C only", "PASS")
  , @("Primary results unchanged after adding model A to the equal-weight variant", "PASS")
  , @("Scoring functions shared with the confirmatory Step 29 (tested against scikit-learn)", "PASS")
  , @("Full automated test suite", ("PASS - " + $nT + " of " + $nT))
) @(300, 150)
H1N "Problems and fixes"
Bullet "The equal-source-weight variant had no model A predictions (Step 31C does not refit model A); they were taken from the primary variant for the same records, after which the decision step ran. Primary results were confirmed unchanged."
H1N "Decisions"
Bullet "D29 (clarification, fixed before computing): rule 3 uses model C; the best conventional method is chosen by strict accuracy; tau fixed in the bootstrap."
H1N "Files produced"
Bullet "08_Statistical_Analysis/study2/: measures.csv, contrasts.csv, reject_option.csv, risk_coverage.csv"
Bullet "11_Results/tables/T4_12_study2_results.csv, T4_13_study2_contrasts.csv; 11_Results/figures/F4_23_study2_macro_f1, F4_24_study2_accuracy_coverage"
Bullet "06_Python_ML/src/study2/step31d_measures.py; 03_Data/interim/step31d_report.md"
Closing "31D" 0 "Step 31E: apply the three pre-registered decision rules exactly as written and state what Study 2 shows and does not show." $global:Blocks["31D"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $r2 = $doc.Content; $r2.SetRange($r2.End - 2, $r2.End - 1); if ($r2.Text -ne [string][char]13) { break }; $r2.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_31D_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_31D_Report.docx") -Force
("SAVED Step_31D_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " | " + $_.ScriptStackTrace) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
