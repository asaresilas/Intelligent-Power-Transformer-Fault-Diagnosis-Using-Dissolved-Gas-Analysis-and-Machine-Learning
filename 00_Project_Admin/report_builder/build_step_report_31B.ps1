$ErrorActionPreference = "Stop"
# build_step_report_31B.ps1 - Word report of roadmap Step 31B (Study 2 pooled data set). Values read from 03_Data/study2.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report31B_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8

$s2 = Join-Path $root "03_Data\study2"
$ck = Get-Content (Join-Path $s2 "study2_checks.json") -Raw | ConvertFrom-Json
$cnt = Import-Csv (Join-Path $s2 "study2_counts.csv")
$lo = Import-Csv (Join-Path $s2 "study2_loso_sizes.csv")
$dl = Import-Csv (Join-Path $s2 "study2_dedup_log.csv")
$conf = @($dl | Where-Object label_conflict -eq "True")
if ($ck.exact_copies_left_across_sources -ne 0) { throw "copies left" }
foreach ($line in Get-Content (Join-Path $s2 "study2_data.sha256")) { $h, $f = $line -split "  "; if ((Get-FileHash (Join-Path $root $f)).Hash -ne $h) { throw "manifest mismatch $f" } }
$testOut = & (Join-Path $root "06_Python_ML\.venv\Scripts\python.exe") -I -m pytest (Join-Path $root "06_Python_ML\tests") -q -p no:cacheprovider 2>&1 | Select-Object -Last 1
if ("$testOut" -notmatch '^(\d+) passed') { throw "tests failed: $testOut" }
$nT = $Matches[1]
$NAMES = @{ DISTRAIN = "Dissanayake training"; DISTEST = "Dissanayake unseen"; IECTC10 = "IEC TC 10 (power transformers)"; LI2019 = "Li 2019"; All = "All" }

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
$global:Methods["31B"] = @{
  Approach = @(
    "The four data sources were pooled into one table by the rules fixed in the Study 2 protocol. Records that appear in more than one source with identical gas values were kept only once, in the source of highest priority (IEC TC 10, then Dissanayake training, Dissanayake unseen, Li 2019); every removed copy and any label conflict was logged.",
    "Near-duplicate groups were then formed over all remaining records with exactly the Step 10 rule (the same program function), so that near-copies can be kept out of training whenever one of them is held out. T1 and T2 were merged into one class, and the conventional methods' raw answers, gate flags and boundary distances were attached as the hybrid model's inputs.")
  Why = @(
    "Without deduplication, Li 2019's copies of the IEC TC 10 cases would put the same transformer in both the training and the test part of a leave-one-source-out split, and the results would be too optimistic.",
    "Reusing the Step 10 function guarantees the same near-duplicate definition as in the main study.",
    "The priority order keeps the inspection-confirmed IEC TC 10 copy whenever there is a choice.")
  Settings = @(
    @("Priority for exact copies", "IEC TC 10 > Dissanayake training > Dissanayake unseen > Li 2019"),
    @("Near-duplicate rule", "every gas within 1 % or 1 ppm, linked transitively (step10_folds.near_groups)"),
    @("Classes", "Normal, PD, D1, D2, T1/T2 merged, T3"),
    @("Scope", "IEC TC 10 power transformers (codes P, U) in the primary analysis; all 117 IEC TC 10 records kept with a flag for the sensitivity analysis"),
    @("Hybrid inputs", "raw answer of IEC 60599, Rogers, Duval; upper and lower gate flags; three boundary distances"))
  Eqs = @()
  Tools = @("06_Python_ML/src/study2/step31b_pooled.py", "tests/test_study2_pooled.py (5 tests: no copies, priority, Step 10 groups kept, scope and classes, hybrid inputs)")
  Refs = @()
}
$global:Closings["31B"] = @{
  Achieved = @(
    ("The Study 2 data set is built: " + $ck.pooled_records + " records, " + $ck.primary_scope_records + " in the primary scope, with groups, six classes and hybrid inputs."),
    ("No exact copy remains across sources (" + $ck.records_removed + " copies removed); the one label conflict is listed."),
    "Every file has a SHA-256 in its own manifest; data version 1.0 is unchanged.")
  Record = @(
    @("Step", "31B - Build the pooled, deduplicated data set (Study 2)"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "12 October 2026"), @("Status", "Done"),
    @("Main inputs", "dga_master.csv; conventional_predictions.csv; Study 2 protocol (fingerprint checked)"),
    @("Main outputs", "03_Data/study2/: study2_pooled.csv, study2_dedup_log.csv, study2_counts.csv, study2_loso_sizes.csv, study2_checks.json, study2_data.sha256"),
    @("Checks", ("no copies left; Step 10 groups preserved; manifest verified; " + $nT + " of " + $nT + " tests pass")),
    @("Decisions", "none new (rules of D28)"))
  Helps = @("Step 31C trains and tests models A, B and C by holding out each source in turn, using this file only.")
  Open = @(
    "The one label conflict (PD in the Dissanayake unseen file, spark discharge = D1 in Li 2019) is resolved by the priority rule; neither label is inspection-confirmed.",
    "The IEC TC 10 power-transformer set is small (58 records) and has only one PD record, so results when it is held out will be uncertain.",
    "Normal records come from the Dissanayake files only; when both are held out in turn, the model still learns Normal from the other.")
  Exclude = @()
}
$global:StepSources["31B"] = @("DF2", "DF9", "DF40", "DF41", "DF3", "SW1")

function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed = "12 October 2026") {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "31B" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "31B" "Build the pooled, deduplicated data set (Study 2)" "Claude Code (this chat)"
Summary ("The four sources were pooled exactly by the Study 2 protocol. " + $ck.records_removed + " exact copies across sources were removed (mainly Li 2019's copies of IEC TC 10 cases), leaving " + $ck.pooled_records + " records, " + $ck.primary_scope_records + " of them in the primary scope. No near-copy links two different sources, so no training record has to be removed when a source is held out. One label conflict was found and logged. Data version 1.0 is unchanged.")
H1N "Purpose of this step"
Body "This step prepares the single, clean data file from which every Study 2 model is trained and tested, so that no record or near-copy can appear on both sides of a leave-one-source-out split."
MethodSection "31B"
H1N "What was done, step by step"
NumItem "1" "Checked the protocol's fingerprint, then wrote step31b_pooled.py following its rules."
NumItem "2" "Ran it; inspected the one label conflict and confirmed that the Step 10 near-duplicate groups are preserved inside the new groups."
NumItem "3" "Added five automated tests and recorded the files in a SHA-256 manifest and the source register (DF41)."
H1N "What we found"
H2 "Exact copies removed"
$rows = @(); foreach ($g in ($dl | Group-Object removed_source, kept_source)) { $a = $g.Group[0]; $rows += , @($NAMES[$a.removed_source], $NAMES[$a.kept_source], ("" + $g.Count)) }
AddTable @("Copy removed from", "Copy kept in", "Records") $rows @(170, 170, 80)
Body ("Label conflicts: " + $conf.Count + ". " + (($conf | ForEach-Object { $_.removed_record + " (" + $_.removed_label + ") duplicates " + $_.kept_record + " (" + $_.kept_label + "); the kept copy's label is used" }) -join "; ") + ".")
H2 "Records per source and class (primary scope)"
$rows = @(); foreach ($r in $cnt) { $rows += , @($NAMES[$r.source_id], $r.Normal, $r.PD, $r.D1, $r.D2, $r.T12, $r.T3, $r.All) }
AddTable @("Source", "Normal", "PD", "D1", "D2", "T1/T2", "T3", "All") $rows @(130, 45, 40, 40, 40, 45, 40, 45)
H2 "Size of each leave-one-source-out split"
$rows = @(); foreach ($r in $lo) { $rows += , @($NAMES[$r.held_out], $r.n_test, $r.n_train_before, $r.n_train_removed_near_copies, $r.n_train_used) }
AddTable @("Held-out source", "Test records", "Training records", "Removed near-copies", "Training records used") $rows @(130, 65, 75, 80, 80)
Body "No near-duplicate group spans two sources after the exact copies are removed, so no training record has to be removed in any split. The near-duplicate groups that do exist lie inside the Dissanayake files and are respected by the inner tuning folds."
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("Protocol fingerprint unchanged since registration", "PASS")
  , @("Data version 1.0 unchanged", "PASS")
  , @("No exact copy left across sources", "PASS")
  , @("Step 10 near-duplicate groups kept together", "PASS")
  , @("Every label conflict listed", ("PASS (" + $conf.Count + ")"))
  , @("SHA-256 manifest verified", "PASS")
  , @("Full automated test suite", ("PASS - " + $nT + " of " + $nT))
) @(300, 150)
H1N "Problems and fixes"
Bullet "None."
H1N "Decisions"
Bullet "No new decision; the rules of D28 and the Study 2 protocol were applied as written."
H1N "Files produced"
Bullet "03_Data/study2/: study2_pooled.csv, study2_dedup_log.csv, study2_counts.csv, study2_loso_sizes.csv, study2_checks.json, study2_data.sha256"
Bullet "06_Python_ML/src/study2/step31b_pooled.py; 06_Python_ML/tests/test_study2_pooled.py; 03_Data/interim/step31b_report.md"
Closing "31B" 0 "Step 31C: hold out each source in turn, train and tune models B and C on the other sources, apply model A unchanged, and predict the held-out source once." $global:Blocks["31B"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_31B_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_31B_Report.docx") -Force
("SAVED Step_31B_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
