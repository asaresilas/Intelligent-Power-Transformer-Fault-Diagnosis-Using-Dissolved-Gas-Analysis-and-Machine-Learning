$ErrorActionPreference = "Stop"
# build_step_report_19.ps1 - Word report of roadmap Step 19. Tables are read from configs/pipeline_catalog.csv.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report19_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8
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

function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed = "11 October 2026") {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}

$cat = Import-Csv (Join-Path $root "06_Python_ML\configs\pipeline_catalog.csv")
$nPipe = $cat.Count
$nOk = @($cat | Where-Object { $_.runs -eq "yes" -and $_.finite_features -eq "True" -and $_.proba_sum_to_1 -eq "True" }).Count
$nWarn = ($cat | Measure-Object -Property warnings -Sum).Sum
$global:Blocks = @{ "19" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "19" "Build the preprocessing and feature pipelines" "Claude Code (this chat)"
Summary ("The machine-learning models are now ready to be trained. " + $nPipe + " pipelines were built - four feature sets times six models - and " + $nOk + " of " + $nPipe + " run correctly. Every step that learns from data (filling in missing values, scaling, class weights) is proven by automated tests to use only the training records, so later scores cannot be inflated by leakage. Two technical problems were fixed before any training. No performance score was computed in this step, by design.")
H1N "Purpose of this step"
Body "Before the models are trained and compared (Step 20), the way the data are turned into model inputs must be fixed, written down and tested. This step builds those 'pipelines' exactly as the approved Analysis Plan describes, and proves that they cannot leak information from the records they are tested on."
MethodSection "19"
H1N "What was done, step by step"
NumItem "1" "Wrote all settings - feature sets, preprocessing, models and their search grids - into one configuration file, configs/ml_config.yaml, each value traced to the Analysis Plan or a decision."
NumItem "2" "Found two gaps in the plan when looking at the data: zeros in gas ratios (C2H2 is 0 ppm in 300 of 827 records) and undefined Duval percentages for 2 records. Proposed rules; the researcher approved them as decision D15."
NumItem "3" "Programmed the feature builder (features.py) and the pipelines (pipelines.py), including a wrapper that computes the class weights from the training labels inside every fit."
NumItem "4" "Ran every pipeline once on the training part of repeat 1, fold 1 and checked the predictions and probabilities. The first run showed warnings from the SVM and the neural network; both were fixed (decision D16) and the run repeated without any warning."
NumItem "5" "Wrote automated tests: the feature formulas on a hand-calculated example, the class-weight formula, the leakage tests, and a test that each of the 24 pipelines fits and predicts."
H1N "What we found"
H2 "Features in each set"
$rows = @()
foreach ($row in ($cat | Sort-Object feature_set -Unique)) { $rows += , @($row.feature_set, $row.n_features, ($row.features -replace " ", ", ")) }
AddTable @("Set", "Number", "Features") $rows @(40, 50, 360)
H2 "Working check of the 24 pipelines (repeat 1, fold 1)"
$rows = @()
foreach ($row in $cat) { $rows += , @($row.feature_set, $row.model, $row.weighted, $row.grid_size, $row.runs, $row.proba_sum_to_1, $row.warnings) }
AddTable @("Set", "Model", "Class weights", "Grid size", "Runs", "Probabilities sum to 1", "Warnings") $rows @(35, 95, 55, 50, 45, 85, 55)
Body ("All " + $nPipe + " pipelines fit, predict only classes seen in training, give finite features after imputation and probabilities that sum to 1; the final run produced " + $nWarn + " warnings. 'Grid size' is the number of setting combinations that Step 20 will search for each model. No accuracy or F1 value was computed here, so that model choice cannot be influenced before the planned nested cross-validation.")
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("Data version 1.0 unchanged (SHA-256 manifest)", "PASS")
  , @("folds.csv and the master table give each record the same class", "PASS")
  , @("Feature formulas reproduce a hand-calculated example", "PASS")
  , @("Class weights follow Eq. 14 and give every class the same total weight", "PASS")
  , @("Imputer and scaler fitted on exactly the training rows of the fold", "PASS")
  , @("Class weights computed from the training labels only", "PASS")
  , @("Inside the tuning search, the scaler is refitted on each inner training part only", "PASS")
  , @(("All " + $nPipe + " pipelines run and give valid probabilities"), ("" + $nOk + " of " + $nPipe + " - PASS"))
  , @("SVM: predicted class = most probable class", "PASS")
  , @("Automated test suite (pytest)", "87 of 87 PASS (31 new)")
) @(310, 140)
H1N "Problems and fixes"
Bullet "The fold file (folds.csv) also contains the class code, so joining it to the master table first produced two class columns. The program now joins only the fold columns and checks that both files give every record the same class."
Bullet "scikit-learn 1.9.1 warned that SVC(probability=True), the usual way to get SVM probabilities, is deprecated and will be removed. It was replaced by the method scikit-learn recommends, which is the same Platt calibration (decision D16)."
Bullet "The neural network's default optimiser (Adam) did not finish converging within 2 000 iterations. The L-BFGS optimiser, which the scikit-learn documentation recommends for small data sets, converged in all 144 test fits (decision D16)."
H1N "Decisions"
Bullet "D15 (researcher, 11 October 2026): log-ratios with a +1 ppm offset; undefined Duval percentages filled with the training-fold median; class weights recomputed in every training fold for all models; no oversampling."
Bullet "D16 (procedural, within the approved plan): SVM probabilities by Platt calibration through CalibratedClassifierCV; MLP fitted with L-BFGS. The approved models and search grids are unchanged."
H1N "Files produced"
Bullet "06_Python_ML/configs/ml_config.yaml (all settings) and configs/pipeline_catalog.csv (the 24 pipelines)"
Bullet "06_Python_ML/src/ml/features.py, pipelines.py, step19_build_pipelines.py; 03_Data/interim/step19_report.md"
Bullet "06_Python_ML/tests/test_pipelines.py (31 tests, including the leakage tests)"
Closing "19" 0 "Step 20: train and tune the classifiers with nested cross-validation - the inner loop chooses the settings by macro-F1, the outer loop measures performance on the 50 fixed folds - and save every run with its configuration and seed." $global:Blocks["19"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_19_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_19_Report.docx") -Force
("SAVED Step_19_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
