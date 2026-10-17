$ErrorActionPreference = "Stop"
# build_step_report_32.ps1 - Word report of roadmap Step 32 (all Chapter 4 tables and figures). Reads the manifest and check file.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report32_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8
$res = Join-Path $root "11_Results"
$man = Get-Content (Join-Path $res "chapter4_manifest.sha256")
$chk = Get-Content (Join-Path $res "chapter4_check.txt")
$nBefore = [int](($chk[0] -split "before: ")[1].Split(";")[0]); $nAfter = [int](($chk[0] -split "after: ")[1])
$okCheck = ($chk[1] -eq "missing after rebuild: []") -and ($chk[3] -eq "changed: []")
if (-not $okCheck) { throw "rebuild check did not pass" }
$testOut = & (Join-Path $root "06_Python_ML\.venv\Scripts\python.exe") -I -m pytest (Join-Path $root "06_Python_ML\tests") -q -p no:cacheprovider 2>&1 | Select-Object -Last 1
if ("$testOut" -notmatch '^(\d+) passed') { throw "tests failed: $testOut" }
$nT = $Matches[1]
$fig = Join-Path $res "figures"
$index = @(
  @("Table 4.1 / 4.1b", "Records by role and class; records removed", "Step 11"), @("Table 4.2 (+ A4.2)", "Gas medians and IQR by class, Kruskal-Wallis", "Step 11"),
  @("Table 4.3", "Conventional methods on each test set", "Step 29"), @("Table 4.4", "Classifier cross-validation results", "Step 20"),
  @("Table 4.5", "Main comparison on each test set", "Step 29"), @("Table 4.6", "McNemar tests with Holm correction", "Step 30"),
  @("Table 4.7", "Cohen's kappa between methods", "Step 30"), @("Table 4.8", "Boundary logistic regression", "Step 31"),
  @("Table 4.9", "Reduced-gas study and minimum panel", "Step 27"), @("Tables 4.10-4.11", "Simulink verification; integration (Stages G-H)", "not yet - Steps 33-42"),
  @("Tables 4.12-4.13", "Study 2 results and contrasts (exploratory)", "Step 31D"),
  @("Figures 4.1-4.3", "Records per class; gases by class; gas correlation", "Step 11"), @("Figure 4.4", "Duval triangles by data role (MATLAB)", "Step 17 (not rebuilt here)"),
  @("Figures 4.5a-c, 4.8", "Confusion matrices (conventional; ML)", "Step 29"), @("Figure 4.6", "Cross-validation box plots", "Step 32 (new)"),
  @("Figures 4.7, 4.11", "Critical-difference diagram; kappa heatmaps", "Step 30"), @("Figures 4.9a-c", "Main comparison dot-and-whisker plots", "Step 32 (new)"),
  @("Figure 4.10", "F1 per fault class with 95 % CI", "Step 32 (new)"), @("Figure 4.12", "Disagreement against boundary distance", "Step 31"),
  @("Figure 4.13", "Disagreements in the Duval Triangle", "Step 32 (new)"), @("Figures 4.14-4.15", "Permutation importance; SHAP summary", "Step 23"),
  @("Figures 4.16-4.17", "Accuracy against number of gases; gas-subset matrix", "Step 27"), @("Figures 4.18-4.22", "Simulink and integration (Stages G-H)", "not yet - Steps 33-42"),
  @("Figures 4.23-4.24", "Study 2 macro-F1; accuracy against coverage (exploratory)", "Step 31D"))

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
$global:Methods["32"] = @{
  Approach = @(
    "One command (make_chapter4.py) runs, in dependency order, every program that produces a Chapter 4 table or figure. Each program reads only saved files - fold results, saved predictions, merged predictions - so nothing is retrained and no test set is predicted again.",
    "Four figures that no earlier step had made were added (Figures 4.6, 4.9, 4.10, 4.13). The roadmap's check was then run: the current tables and figures were moved aside, everything was rebuilt from scratch, and every file was compared byte for byte with the earlier version.")
  Why = @("A thesis whose every table and figure can be rebuilt by one command from saved data is fully reproducible - examiners can verify any number.", "Moving files aside instead of deleting them keeps the check safe and reversible.")
  Settings = @(
    @("Command", "python -I 06_Python_ML/src/analysis/make_chapter4.py [--check]"),
    @("Programs run", "Steps 11, 20 (table only), 23, 27, 29, 30, 31, 31D, 31E and the new chapter4_figures.py"),
    @("Not rebuilt here", "plot_style.csv (frozen), Figure 3.2 (Step 13), Figure 4.4 (MATLAB, Step 17); Stage G-H outputs do not exist yet"),
    @("Reproducibility settings", "seeded bootstraps and shuffles; PDF files written without a creation date"))
  Eqs = @()
  Tools = @("06_Python_ML/src/analysis/make_chapter4.py; chapter4_figures.py (Figures 4.6, 4.9a-c, 4.10, 4.13)")
  Refs = @("M26", "M20")
}
$global:Closings["32"] = @{
  Achieved = @(("All " + $nAfter + " Chapter 4 table and figure files are rebuilt by one command and fingerprinted (11_Results/chapter4_manifest.sha256)."), "Rebuilding from scratch reproduced every file byte for byte (11_Results/chapter4_check.txt).", "Figures 4.6, 4.9, 4.10 and 4.13 were added; Chapter 4 now has every planned table and figure except those of the Simulink and integration stages.")
  Record = @(
    @("Step", "32 - Generate all Chapter 4 tables and figures"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "12 October 2026"), @("Status", "Done (Stage F complete)"),
    @("Main inputs", "saved result files of Steps 11-31F"),
    @("Main outputs", "11_Results/tables, 11_Results/figures, chapter4_manifest.sha256, chapter4_check.txt; 08_Statistical_Analysis/per_class_ci.csv"),
    @("Checks", ("rebuild from scratch identical (" + $nBefore + " files); registered result files unchanged; " + $nT + " of " + $nT + " tests pass")),
    @("Decisions", "none new"))
  Helps = @("Chapter 4 can be written directly from these files.", "Stage G (Steps 33-37, Simulink operating model) follows; its tables and figures (4.10-4.11, 4.18-4.22) will be added to the same command.")
  Open = @("Figure 4.4 is produced in MATLAB (Step 17) and is not part of the Python rebuild.", "Tables 4.10-4.11 and Figures 4.18-4.22 belong to Stages G-H and do not exist yet.")
  Exclude = @()
}
$global:StepSources["32"] = @("DF21", "DF34", "DF35", "DF37", "DF39", "DF43", "SW1")
function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed = "12 October 2026") {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "32" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }
$PAGEW = 453

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "32" "Generate all Chapter 4 tables and figures" "Claude Code (this chat)"
Summary ("One command now rebuilds every Chapter 4 table and figure from the saved result files - " + $nAfter + " files - without retraining any model or predicting any test set again. Rebuilding everything from scratch reproduced all files byte for byte, and every result table registered in earlier steps is unchanged. Four figures were added (4.6, 4.9, 4.10, 4.13). Stage F is complete.")
H1N "Purpose of this step"
Body "This step makes Chapter 4 fully reproducible and completes its set of tables and figures for the work done so far."
MethodSection "32"
H1N "What was done, step by step"
NumItem "1" "Added a table-only option to the Step 20 summary, fixed the PDF creation date (so re-runs give identical files), and wrote chapter4_figures.py for the four missing figures."
NumItem "2" "Wrote make_chapter4.py, which runs all producing programs in order and fingerprints every output."
NumItem "3" "Ran it once and confirmed that every result file recorded in the source register is unchanged."
NumItem "4" "Ran the roadmap check: moved all outputs aside, rebuilt from scratch, compared byte for byte."
H1N "Chapter 4 tables and figures"
$rows = @(); foreach ($i in $index) { $rows += , @($i[0], $i[1], $i[2]) }
AddTable @("Item", "Content", "Produced by") $rows @(100, 240, 120)
H2 "The four new figures"
Caption "Figure 4.6  Cross-validation macro-F1 of the six models (feature set F4, 50 outer folds)"
Pic (Join-Path $fig "F4_6_cv_boxplots.png") $PAGEW
Caption "Figure 4.9b  Main comparison on the IEC TC 10 benchmark (95 % CI; Figures 4.9a and 4.9c show the other test sets)"
Pic (Join-Path $fig "F4_9b_main_comparison_iec_tc10.png") $PAGEW
Caption "Figure 4.10  F1-score per fault class with 95 % bootstrap CI, on the three test sets"
Pic (Join-Path $fig "F4_10_f1_per_class.png") ($PAGEW * 0.85)
Caption "Figure 4.13  Disagreements between the ML model and Duval in the Duval Triangle (primary test records)"
Pic (Join-Path $fig "F4_13_duval_disagreements.png") ($PAGEW * 0.9)
Body "In Figure 4.13 many of the disagreements lie along the CH4-C2H4 edge (thermal faults and the T1/T2 boundary) and between the D1 and D2 zones, where Duval's zone lines separate neighbouring classes."
H1N "Checks"
AddTable @("Check", "Result") @(
  , @(("Rebuild from scratch: " + $nBefore + " files before, " + $nAfter + " after"), "PASS - none missing, none changed")
  , @("Registered result tables and data files unchanged by the rebuild", "PASS")
  , @("No model retrained; no test set predicted again", "PASS")
  , @("Full automated test suite", ("PASS - " + $nT + " of " + $nT))
) @(300, 150)
H1N "Problems and fixes"
Bullet "The first run stopped because the Step 11 program is in the analysis folder, not data_prep; the path was corrected."
Bullet "PDF files carried a creation date, which would make identical rebuilds differ; the date is now omitted."
H1N "Decisions"
Bullet "None new."
H1N "Files produced"
Bullet "06_Python_ML/src/analysis/make_chapter4.py, chapter4_figures.py; 11_Results/chapter4_manifest.sha256, chapter4_check.txt"
Bullet "11_Results/figures/F4_6_cv_boxplots, F4_9a-c_main_comparison_*, F4_10_f1_per_class, F4_13_duval_disagreements (PNG, PDF, CSV); 08_Statistical_Analysis/per_class_ci.csv"
Closing "32" 0 "Stage G - Step 33 (Simulink Agentic Toolkit): rebuild the transformer operating model in pure Simscape, every parameter from params_transformer.m." $global:Blocks["32"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $r2 = $doc.Content; $r2.SetRange($r2.End - 2, $r2.End - 1); if ($r2.Text -ne [string][char]13) { break }; $r2.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_32_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_32_Report.docx") -Force
("SAVED Step_32_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " | " + $_.ScriptStackTrace) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
