$ErrorActionPreference = "Stop"
# build_step_report_27.ps1 - Word report of roadmap Step 27. Every number is read from Table 4.9 and minimum_panel.json.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report27_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8

$inv = [Globalization.CultureInfo]::InvariantCulture
function D([string]$v) { [double]::Parse($v, $inv) }
function F3([string]$v) { (D $v).ToString("0.000", $inv) }
$t49 = Import-Csv (Join-Path $root "11_Results\tables\T4_9_reduced_gas.csv")
$mp  = Get-Content (Join-Path $root "11_Results\reduced_gas\minimum_panel.json") -Raw | ConvertFrom-Json
$fig = Join-Path $root "11_Results\figures"
$m   = $t49 | Where-Object { $_.subset_id -eq $mp.minimum_panel.subset }
$full = $t49 | Where-Object { [int]$_.n_gases -eq 5 }
if ($mp.minimum_panel_t_sensitivity -ne $mp.minimum_panel.subset) { throw "t-sensitivity statement not true" }
if ($m.conventional_usable -ne "none") { throw "no-conventional-method statement not true" }
$noC2H6 = $t49 | Where-Object { $_.subset_id -eq "H2+CH4+C2H4+C2H2" }
if ($noC2H6.conventional_usable -ne "Duval" -or $noC2H6.within_tolerance -ne "False") { throw "Duval-panel statement not true" }
$global:S27 = @{ B = $mp.B; n = $mp.n_records; panel = $mp.minimum_panel.subset; loss = (F3 $m.loss)
  lossci = ("[" + (F3 $m.loss_ci_low) + ", " + (F3 $m.loss_ci_high) + "]") }

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
. (Join-Path $sp "report_entries_27.ps1")

function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed = "12 October 2026") {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "27" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }
$PAGEW = 453

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "27" "Find the minimum gas panel" "Claude Code (this chat)"
Summary ("The minimum gas panel is four gases: " + $mp.minimum_panel.subset + " - everything except methane (CH4). Its macro-F1 is " + (F3 $m.macro_f1) + " against " + (F3 $full.macro_f1) + " with all five gases; the loss is " + (F3 $m.loss) + " (95 % interval " + $S27.lossci + "), inside the approved tolerance of 0.05. It is the only reduced combination that qualifies, and the robustness check agrees. Notably, none of the three conventional methods can be used with this panel - each needs methane - while the ML model keeps nearly all its accuracy.")
H1N "Purpose of this step"
Body "This step turns the reduced-gas results into a clear engineering answer: what is the smallest set of gases a utility must measure for the ML diagnosis to remain reliable, and which conventional methods would still work with it?"
MethodSection "27"
H1N "What was done, step by step"
NumItem "1" "Fixed the interval and decision details as decision D24 before computing any interval."
NumItem "2" "Wrote step27_minimum_panel.py and a test that its fast macro-F1 equals scikit-learn's; ran it (about one minute)."
NumItem "3" "Improved the label position in Figure 4.16 and ran the program again: the seeded bootstrap gave an identical Table 4.9."
H1N "What we found"
H2 "Table 4.9 - reduced-gas study (cross-validation, 439 development records)"
$rows = @()
foreach ($r in $t49) {
  $tol = $(if ([int]$r.n_gases -eq 5) { "-" } elseif ($r.within_tolerance -eq "True") { "yes" } else { "no" })
  $rows += , @($r.subset_id, $r.n_gases, ((F3 $r.macro_f1) + " [" + (F3 $r.macro_f1_ci_low) + ", " + (F3 $r.macro_f1_ci_high) + "]"), $(if ([int]$r.n_gases -eq 5) { "0 (reference)" } else { (F3 $r.loss) + " [" + (F3 $r.loss_ci_low) + ", " + (F3 $r.loss_ci_high) + "]" }), $tol, $r.conventional_usable)
}
AddTable @("Gas combination", "Gases", "ML macro-F1 [95 % CI]", "Loss [95 % CI]", "Within 0.05?", "Conventional methods still usable") $rows @(118, 42, 92, 92, 52, 76)
Body "Within tolerance = upper 95 % limit of the loss at most 0.05. The last column follows from the gases each method needs (Step 26): IEC 60599 and Rogers need all five gases, Duval needs CH4, C2H4 and C2H2."
Caption "Figure 4.16  Macro-F1 against the number of gases available (439 development records, cross-validation)"
Pic (Join-Path $fig "F4_16_accuracy_vs_number_of_gases.png") $PAGEW
Body "Grey points: the 31 gas combinations; blue line and band: the best combination of each size with its 95 % bootstrap interval; dashed line: five-gas macro-F1 minus the tolerance."
Caption "Figure 4.17  Gas-subset matrix: ML macro-F1 of every combination and the conventional methods still usable"
Pic (Join-Path $fig "F4_17_gas_subset_matrix.png") $PAGEW
Body "Upper part: macro-F1 with 95 % bootstrap interval, best to worst; middle: filled dots mark the gases in each combination; lower part: a tick where a conventional method can still be used."
H2 "What this means"
Bullet ("Without methane the ML model loses only " + (F3 $m.loss) + " macro-F1 (interval " + $S27.lossci + ", which includes zero). Methane carries little information that the other four gases do not already provide - in line with Step 23, where methane was among the two least important gases on every test set.")
Bullet ("Every other reduced combination loses more than the tolerance. The best combination that keeps the Duval Triangle usable (without ethane, " + $noC2H6.subset_id + ") loses " + (F3 $noC2H6.loss) + " [" + (F3 $noC2H6.loss_ci_low) + ", " + (F3 $noC2H6.loss_ci_high) + "].")
Bullet "Single gases are poor (macro-F1 0.25 to 0.39): one gas cannot tell the seven classes apart, so with a single gas this model cannot diagnose the fault type reliably."
Bullet ("Robustness: with the corrected resampled t interval the same combination qualifies (upper limit " + (D $m.fold_loss_t_high).ToString("0.0000", $inv) + "), but only just - the conclusion should be confirmed on other data before it is used as a general rule.")
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("Data version 1.0 unchanged (SHA-256 manifest)", "PASS")
  , @("Tolerance used = the approved 0.05 (fixed in Step 4, before the results)", "PASS")
  , @("Every record predicted once per combination and repeat", "PASS (checked by the program)")
  , @("Fast macro-F1 equals scikit-learn (automated test)", "PASS")
  , @("Re-run gives an identical Table 4.9 (seeded bootstrap)", "PASS")
  , @("Robustness check (corrected t interval) gives the same minimum panel", "PASS")
) @(300, 150)
H1N "Problems and fixes"
Bullet "A label in Figure 4.16 crossed the curve; it was moved and the program run again - all numbers were identical."
Bullet "When adding this step to the source register, the number DF29 had already been used by the Step 26 session; this step's entry was renumbered DF33."
H1N "Decisions"
Bullet "D24 (procedural, within the approved plan): statistic, paired stratified bootstrap (B = 2000), decision rule when several combinations qualify, t-interval sensitivity check."
H1N "Files produced"
Bullet "11_Results/tables/T4_9_reduced_gas.csv; 11_Results/reduced_gas/minimum_panel.json"
Bullet "11_Results/figures/F4_16_accuracy_vs_number_of_gases and F4_17_gas_subset_matrix (PNG, PDF, CSV)"
Bullet "06_Python_ML/src/ml/step27_minimum_panel.py; 06_Python_ML/tests/test_minimum_panel.py; 03_Data/interim/step27_report.md"
Closing "27" 0 "Stage F - Step 28: join the true classes, the conventional predictions and the ML predictions of the test sets on record_id (merged_predictions.csv), checking that no record is lost or duplicated." $global:Blocks["27"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_27_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_27_Report.docx") -Force
("SAVED Step_27_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
