$ErrorActionPreference = "Stop"
# build_step_report_23.ps1 - Word report of roadmap Step 23. Every number is read from 11_Results/explain and the figures folder.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report23_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8

# ---- results (read before the entries file, which uses $global:S23) ------------------------------------------------
$inv = [Globalization.CultureInfo]::InvariantCulture
function D([string]$v) { [double]::Parse($v, $inv) }
function F3([string]$v) { (D $v).ToString("0.000", $inv) }
$ex  = Join-Path $root "11_Results\explain"
$fig = Join-Path $root "11_Results\figures"
$pi  = Import-Csv (Join-Path $ex "permutation_importance.csv")
$si  = Import-Csv (Join-Path $ex "shap_importance.csv")
$ec  = Import-Csv (Join-Path $ex "engineering_check.csv")
$dir = Import-Csv (Join-Path $ex "shap_direction.csv")
$sm  = Get-Content (Join-Path $ex "step23_summary.json") -Raw | ConvertFrom-Json
$iec = Import-Csv (Join-Path $root "02_Standards\iec_ratio_table.csv") | Where-Object { $_.source_table -eq "Table 2" }
$nCons = @($ec | Where-Object { $_.consistent -eq "True" }).Count
$addMax = [math]::Max([double]$sm.additivity_error.development, [double]$sm.additivity_error.test)
$global:S23 = @{ shapver = $sm.shap; consistent = $nCons; rho = ([double]$sm.spearman_dev_test).ToString("0.000", $inv)
  adderr = ("below " + $(if ($addMax -lt 1e-12) { "1e-12" } else { $addMax.ToString("0.0e0", $inv) })) }
$SETS = "Internal test", "IEC TC 10 (power transformers)", "Li 2019"
function Pretty([string]$f) {
  $R = @{ R1 = "CH4/H2"; R2 = "C2H2/C2H4"; R3 = "C2H2/CH4"; R4 = "C2H6/C2H2"; R5 = "C2H4/C2H6" }
  if ($f -match '^log_(R\d)$') { return ("log " + $Matches[1] + " (" + $R[$Matches[1]] + ")") }
  if ($f -match '^duval_pct_(.+)$') { return ("Duval % " + $Matches[1]) }
  if ($f -match '^pct_(.+)$') { return ("% " + $Matches[1]) }
  if ($f -match '^log_(.+)$') { return ("log " + $Matches[1]) }
  return $f
}
function GasRank([string]$set) { $pi | Where-Object { $_.evaluation_set -eq $set -and $_.level -eq "gas" } | Sort-Object { -(D $_.importance_mean) } }
function ShapDir([string]$c, [string]$f) { $dir | Where-Object { $_.class -eq $c -and $_.feature -eq $f } }
function IecRule([string]$c, [string]$ratio) { ($iec | Where-Object { $_.fault_code -eq $c -and $_.ratio -eq $ratio }).as_printed }

# statements made in the text below - verified against the saved results
foreach ($s in $SETS) {
  $g = @(GasRank $s | ForEach-Object { $_.feature })
  if ($g[0..1] -notcontains "C2H2") { throw "C2H2-in-top-two statement not true for $s" }
  if ($g[3..4] -notcontains "CH4") { throw "CH4-among-two-least statement not true for $s" }
}
$c2h6Iec = $pi | Where-Object { $_.evaluation_set -eq "IEC TC 10 (power transformers)" -and $_.level -eq "gas" -and $_.feature -eq "C2H6" }
if ((D $c2h6Iec.importance_mean) -ge 0) { throw "C2H6 negative statement not true" }
$featInt = @($pi | Where-Object { $_.evaluation_set -eq "Internal test" -and $_.level -eq "feature" })
$nSpan0 = @($featInt | Where-Object { (D $_.ci_low) -le 0 -and (D $_.ci_high) -ge 0 }).Count
$top3 = @($si | Where-Object { $_.records -eq "development" -and $_.class -eq "all classes" } | Sort-Object { -(D $_.mean_abs_shap) } | Select-Object -First 3 | ForEach-Object { $_.feature })
if (($top3 -join ",") -ne "duval_pct_C2H2,log_R1,log_R5") { throw "SHAP top-3 statement not true" }
# direction checks against IEC 60599 Table 2 (sign of Spearman between feature value and SHAP value)
$cmp = @(
  @("PD", "log_R1", "CH4/H2", -1), @("T1", "log_R5", "C2H4/C2H6", -1), @("T2", "log_R5", "C2H4/C2H6", 0),
  @("T3", "log_R5", "C2H4/C2H6", 1), @("T3", "log_R2", "C2H2/C2H4", -1), @("D1", "duval_pct_C2H2", "C2H2/C2H4", 1),
  @("D2", "duval_pct_C2H2", "C2H2/C2H4", 1))
foreach ($c in $cmp) {
  $rho = D (ShapDir $c[0] $c[1]).spearman_value_vs_shap
  $ok = $(if ($c[3] -gt 0) { $rho -gt 0.3 } elseif ($c[3] -lt 0) { $rho -lt -0.3 } else { [math]::Abs($rho) -le 0.3 })
  if (-not $ok) { throw ("direction statement not true for " + $c[0] + " " + $c[1]) }
}

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
. (Join-Path $sp "report_entries_14_17.ps1")
. (Join-Path $sp "report_entries_18.ps1")
. (Join-Path $sp "report_entries_19.ps1")
$global:S20 = @{}; $global:S21 = @{}; $global:S22 = @{}
. (Join-Path $sp "report_entries_20.ps1")
. (Join-Path $sp "report_entries_21.ps1")
. (Join-Path $sp "report_entries_22.ps1")
. (Join-Path $sp "report_entries_23.ps1")

function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed = "12 October 2026") {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "23" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }
$PAGEW = 453

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "23" "Explain the model" "Claude Code (this chat)"
Summary ("The final model reasons in a physically sensible way. Shuffling acetylene (C2H2) is among the two most damaging changes on all three test sets, and methane (CH4) is among the two least. For each of the six fault classes, the model's strongest evidence involves the key gas engineers would expect (" + $nCons + " of 6), and the directions of its main effects agree with the IEC 60599 ratio limits - for example, a low CH4/H2 ratio points to partial discharge and a high C2H4/C2H6 ratio to severe overheating (T3). Because the development labels may partly come from such methods, this shows plausibility rather than independent discovery.")
H1N "Purpose of this step"
Body "This step opens the 'black box': it shows which gases and gas ratios the final model relies on, and whether its reasoning matches transformer engineering knowledge (Analysis Plan Section 8.1). Results are reported as found."
MethodSection "23"
H1N "What was done, step by step"
NumItem "1" "Fixed the design as decision D20 before computing anything, including the engineering expectation for each fault class."
NumItem "2" "Wrote step23_explain.py; it checks the fingerprint of the fitted model, computes permutation importance (gas and feature level) and SHAP values, and draws Figures 4.14 and 4.15."
NumItem "3" "Added a table of the direction of each main effect (does a high or a low value push towards the class?) and ran the program again; all earlier results were reproduced exactly."
NumItem "4" "Compared the directions with the limits of IEC 60599 Table 2, read from the project's transcribed table (02_Standards/iec_ratio_table.csv)."
H1N "What we found"
H2 "Which gases matter most (permutation importance, gas level)"
$rows = @()
foreach ($g in "H2", "CH4", "C2H6", "C2H4", "C2H2") {
  $line = @($g)
  foreach ($s in $SETS) { $r = $pi | Where-Object { $_.evaluation_set -eq $s -and $_.level -eq "gas" -and $_.feature -eq $g }; $line += ((F3 $r.importance_mean) + " [" + (F3 $r.ci_low) + ", " + (F3 $r.ci_high) + "] (" + $r.rank + ")") }
  $rows += , $line
}
AddTable @("Gas shuffled", "Internal test (n = 61)", "IEC TC 10 power transformers (n = 58)", "Li 2019 (n = 86)") $rows @(70, 125, 135, 125)
Body "Each cell: mean drop in macro-F1 over 30 shuffles [2.5-97.5 percentile of the shuffles] (rank within the set, 1 = most important)."
foreach ($s in $SETS) { Bullet ($s + ": " + ((GasRank $s | ForEach-Object { $_.feature }) -join " > ")) }
Body ("Acetylene (C2H2) is among the two most important gases on every set - the gas of electrical discharges. Ethylene (C2H4), the gas of severe overheating, is the most important on the internal test and Li 2019 sets. Methane (CH4) is among the two least important gases on every set. On the IEC TC 10 benchmark, shuffling ethane (C2H6) slightly improved the score (" + (F3 $c2h6Iec.importance_mean) + "): the way the model uses ethane, learned from the development data, does not carry over to that benchmark - a finding to discuss in Chapter 4.")
Caption "Figure 4.14  Permutation importance of the final model, internal test set (n = 61)"
Pic (Join-Path $fig "F4_14_permutation_importance.png") $PAGEW
Body ("Bars: mean drop in macro-F1 over 30 shuffles; whiskers: 2.5-97.5 percentile range of the shuffles (shuffle variability only). Panel (b): " + $nSpan0 + " of the 18 single features have a range that includes zero - shuffling one feature alone is largely compensated by the related features built from the same gases, which is why the gas level (panel a) is the main ranking (decision D20).")
H2 "How the model uses each feature (SHAP)"
$rows = @()
$devAll = $si | Where-Object { $_.records -eq "development" -and $_.class -eq "all classes" } | Sort-Object { -(D $_.mean_abs_shap) } | Select-Object -First 8
foreach ($r in $devAll) { $t = $si | Where-Object { $_.records -eq "test" -and $_.class -eq "all classes" -and $_.feature -eq $r.feature }; $rows += , @($r.rank, (Pretty $r.feature), (F3 $r.mean_abs_shap), (F3 $t.mean_abs_shap)) }
AddTable @("Rank", "Feature", "Mean |SHAP|, development (n = 439)", "Mean |SHAP|, test (n = 388)") $rows @(40, 160, 130, 130)
Body ("Mean absolute SHAP value summed over the seven classes (probability units), top 8 of 18 features. The three strongest are the Duval share of acetylene and the ratios CH4/H2 (R1) and C2H4/C2H6 (R5) - the same quantities the Duval Triangle and the IEC and Rogers ratio methods use. The ranking on the test records agrees closely with that on the development records (Spearman " + $S23.rho + ").")
Caption "Figure 4.15  SHAP summary of the final model, one panel per class (439 development records)"
Pic (Join-Path $fig "F4_15_shap_summary.png") $PAGEW
Body "Each dot is one record; its horizontal position is how much that feature pushed the record towards (right) or away from (left) the class; its colour shows whether the feature value was low (light) or high (dark). The eight strongest features of each class are shown."
H2 "Does the model reason like an engineer?"
$rows = @()
foreach ($r in $ec) { $rows += , @($r.class, $r.expected_gases, (($r.top3_features -split "; " | ForEach-Object { Pretty $_ }) -join "; "), $(if ($r.consistent -eq "True") { "yes" } else { "no" })) }
AddTable @("Class", "Expected key gas (D20)", "Three strongest features (SHAP)", "Consistent?") $rows @(45, 85, 260, 65)
Body "Consistent = at least one of the three strongest features involves an expected gas (a ratio involves both of its gases). This check is generous, because ratios contain two gases; the direction check below is stricter."
$rows = @()
foreach ($c in $cmp) {
  $d = ShapDir $c[0] $c[1]
  $model = $(if ($d.direction -match "^high") { "high value -> " + $c[0] } elseif ($d.direction -match "^low") { "low value -> " + $c[0] } else { "middle values -> " + $c[0] })
  $rows += , @($c[0], (Pretty $c[1]), ($model + " (rho " + (D $d.spearman_value_vs_shap).ToString("0.00", $inv) + ")"), ($c[2] + " " + (IecRule $c[0] $c[2])))
}
AddTable @("Class", "Feature", "What the model learned", "IEC 60599 Table 2 rule") $rows @(45, 130, 150, 130)
Body "rho: Spearman correlation between the feature value and its SHAP value for that class (development records); positive means high values push towards the class. Every direction agrees with the IEC 60599 limit for that class. For T2 the effect is not one-sided, as expected for a class defined by a middle band of C2H4/C2H6 (1 to 4). For D1 and D2 the model relies mainly on the Duval share of acetylene, a related but different measure from the IEC C2H2/C2H4 ratio."
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("Data version 1.0 unchanged (SHA-256 manifest)", "PASS")
  , @("Fitted pipeline unchanged since Step 22 (SHA-256)", "PASS")
  , @("SHAP additivity (base value + SHAP values = predicted probability)", ("PASS - largest error " + $S23.adderr))
  , @("Program run twice: results identical", "PASS - same SHA-256 of both importance tables")
  , @("Engineering expectation fixed before the results (D20)", "PASS")
  , @("Text statements checked against the result files by the report builder", "PASS")
) @(300, 150)
H1N "Problems and fixes"
Bullet "None in the computation. To state the direction of each effect from numbers rather than from reading the figure, a direction table was added after the first run; the second run reproduced all earlier results exactly."
H1N "Decisions"
Bullet "D20 (procedural, within the approved plan): gas-level importance as the main ranking; feature level as Figure 4.14 panel (b); exact TreeSHAP on development and test records; engineering expectation fixed in advance and reported as found."
H1N "Files produced"
Bullet "11_Results/explain/: permutation_importance.csv, shap_importance.csv, shap_direction.csv, engineering_check.csv, shap_values_development.csv, shap_values_test.csv, step23_summary.json"
Bullet "11_Results/figures/: F4_14_permutation_importance and F4_15_shap_summary (PNG 300 dpi, PDF, CSV)"
Bullet "06_Python_ML/src/ml/step23_explain.py; 03_Data/interim/step23_report.md"
Closing "23" 0 "Step 24: save the preprocessing and the model together as dga_model_v1.joblib with its SHA-256 and a short model card, and check that reloading it reproduces the Step 22 predictions exactly." $global:Blocks["23"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_23_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_23_Report.docx") -Force
("SAVED Step_23_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
