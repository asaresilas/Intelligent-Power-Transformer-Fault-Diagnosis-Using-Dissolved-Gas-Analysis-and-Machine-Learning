$ErrorActionPreference = "Stop"
# build_step_report_31A.ps1 - Word report of roadmap Step 31A (Study 2 pre-registration).
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report31A_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8

# checks: protocol fingerprint; confirmatory outputs unchanged; no Study 2 experiment exists yet
$proto = Join-Path $root "00_Project_Admin\Study2_Protocol.docx"
$line = (Get-Content (Join-Path $root "03_Data\study2\study2_protocol.sha256") -TotalCount 1)
$recHash = $line.Split(" ")[0]; $recTime = ($line -split "registered ")[1].Substring(0, 19)
if ((Get-FileHash $proto).Hash -ne $recHash) { throw "protocol changed after registration" }
$reg = Import-Csv (Join-Path $root "03_Data\provenance\data_and_source_register.csv")
$conf = @()
foreach ($id in "DF25", "DF34", "DF35", "DF37", "DF39") {
  $e = $reg | Where-Object id -eq $id
  $ok = (Get-FileHash (Join-Path $root $e.local_file)).Hash -eq $e.sha256
  if (-not $ok) { throw "confirmatory file changed: $id" }
  $conf += , @($id, $e.local_file, "unchanged")
}
if (@(Get-ChildItem (Join-Path $root "07_Experiments") -Directory | Where-Object Name -like "*study2*").Count) { throw "a Study 2 experiment already exists" }
$global:S31A = @{ hash = $recHash; time = $recTime }

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")

$global:Methods["31A"] = @{
  Approach = @(
    "Pre-registration: before any Study 2 model was trained, a protocol fixed the questions, the data rules, the three models, the measures, the statistical tests, the reject option and the decision rules. Its SHA-256 fingerprint was recorded with the time, so it can be shown later that the plan came first.",
    "The roadmap was updated to Version 3 (Steps 31A-31F) and the master plan received a Phase 6b; Version 2 of the roadmap was archived unchanged.")
  Why = @(
    "Once the test sets have been seen, any further improvement risks being fitted to them. Fixing the plan in advance, and labelling the study exploratory, keeps the work honest and publishable.",
    "Leave-one-source-out evaluation measures what matters in practice - performance on a data source the model has never seen - and addresses the dataset shift found in Steps 22-31.",
    "A reject option (Chow, 1970) lets the model be compared fairly with conventional methods that also give no diagnosis in uncertain cases.")
  Settings = @(
    @("Sources (held out in turn)", "Dissanayake training, Dissanayake unseen, IEC TC 10 power transformers, Li 2019"),
    @("Models", "A released model; B pooled Random Forest/F4; C hybrid (B + conventional answers, gate flags, boundary distances)"),
    @("Classes", "six (T1 and T2 merged, because IEC TC 10 has no separate T1/T2 labels)"),
    @("Statistics", "macro-F1 (primary); bootstrap B = 2000; McNemar with Holm; reject option at the coverage of IEC 60599 and Rogers"),
    @("Status", "exploratory; the confirmatory results of Steps 22-31 are unchanged"))
  Eqs = @()
  Tools = @("00_Project_Admin/report_builder/build_study2_protocol.ps1 (protocol), update_roadmap_v3.ps1 (roadmap Version 3)")
  Refs = @("M32", "M20", "M29", "M30")
}
$global:Closings["31A"] = @{
  Achieved = @(
    ("Study 2 is pre-registered: protocol fingerprint " + $recHash.Substring(0, 16) + "... recorded at " + $recTime + ", before any Study 2 model."),
    "The roadmap (Version 3) and the master plan include Study 2; the earlier roadmap is archived.",
    "The confirmatory result files were checked by fingerprint and are unchanged.")
  Record = @(
    @("Step", "31A - Pre-register Study 2"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "12 October 2026"), @("Status", "Done"),
    @("Main inputs", "Confirmatory results of Steps 22-31; decisions_log.md"),
    @("Main outputs", "00_Project_Admin/Study2_Protocol.docx; 03_Data/study2/study2_protocol.sha256; Project_Roadmap.docx Version 3; PROJECT_PLAN.md Phase 6b"),
    @("Checks", "protocol fingerprint matches; confirmatory outputs unchanged (5 files); no Study 2 experiment yet"),
    @("Decisions", "D28 (Study 2: scope by the researcher; design procedural)"))
  Helps = @(
    "Step 31B builds the pooled, deduplicated data set exactly by the protocol's rules.",
    "Steps 31C-31E train, measure and interpret; the decision rules are already fixed, so the interpretation cannot drift towards the results.")
  Open = @(
    "IEC TC 10 and Li 2019 have already been seen: Study 2 results on them are exploratory and need confirmation on a fresh data set (Step 31F).",
    "The protocol merges T1 and T2; Study 2 therefore says nothing about separating those two thermal classes.")
  Exclude = @()
}
$global:StepSources["31A"] = @("DF40", "DF25", "DF34", "DF35", "DF37", "DF39")

function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed = "12 October 2026") {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "31A" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "31A" "Pre-register Study 2 (exploratory improvement study)" "Claude Code (this chat)"
Summary ("At the researcher's request, an exploratory improvement study (Study 2) was planned and fixed in writing before any of its models was trained. It tests three remedies for the dataset shift found in the main study: training on several sources, a hybrid model that also uses the conventional methods' answers, and a reject option. The protocol was fingerprinted at " + $recTime + "; the roadmap is now Version 3 with Steps 31A-31F. The main (confirmatory) results are unchanged and remain the thesis's main result.")
H1N "Purpose of this step"
Body "This step makes sure that Study 2 is planned before it is run, so that its results can be trusted and cannot be tuned to the test sets that were already used."
MethodSection "31A"
H1N "What was done, step by step"
NumItem "1" "Checked how the four data sources overlap (known from Step 9, decision D9: Li 2019 contains 115 of the IEC TC 10 cases; the Dissanayake unseen file contains 9) and how Step 10 defined near-duplicates, so that the pooling rules could be written correctly."
NumItem "2" "Recorded decision D28 and wrote the Study 2 protocol (5 pages): questions, data rules, models, measures, tests, reject option, decision rules, outputs."
NumItem "3" "Confirmed the reject-option reference (Chow, 1970) in Crossref and fingerprinted the protocol."
NumItem "4" "Archived roadmap Version 2 and updated the roadmap to Version 3: new Steps 31A-31F in the step overview table and in Stage F; Step 32 now also rebuilds the Study 2 tables and figures. Added Phase 6b to the master plan."
H1N "What was fixed in the protocol"
AddTable @("Item", "Fixed choice") @(
  , @("Questions", "S2-Q1 pooling; S2-Q2 hybrid; S2-Q3 reject option; S2-Q4 fresh confirmation data")
  , @("Evaluation", "leave-one-source-out over four sources; near-copies of held-out records removed from training")
  , @("Deduplication", "one copy per exact duplicate; priority IEC TC 10 > Dissanayake training > Dissanayake unseen > Li 2019")
  , @("Models", "A released (unchanged); B pooled Random Forest/F4; C hybrid (B + conventional inputs)")
  , @("Primary measure", "macro-F1 over the classes present in the held-out source")
  , @("Decision rule 1", "pooling helps if B - A > 0 (CI excluding 0) on at least 2 of 3 external sources")
  , @("Decision rule 2", "hybrid helps if C - B > 0 (CI excluding 0) on at least 2 of 4 sources")
  , @("Decision rule 3", "reject option competitive if, at IEC 60599's coverage, its accuracy is not below IEC's on at least 2 of 3 external sources")
) @(120, 340)
H1N "Checks"
$rows = @(, @("Protocol fingerprint matches the recorded value", "PASS")) + @(, @("No Study 2 experiment existed when the protocol was fixed", "PASS"))
foreach ($c in $conf) { $rows += , @(("Confirmatory output " + $c[0] + " unchanged (" + $c[1] + ")"), "PASS") }
AddTable @("Check", "Result") $rows @(330, 120)
H1N "Problems and fixes"
Bullet "The predicted-class symbol in the protocol's reject-option equation was first drawn incorrectly; the equation was corrected and the protocol rebuilt before its fingerprint was recorded."
H1N "Decisions"
Bullet "D28: Study 2 (scope chosen by the researcher; design procedural, fixed before any Study 2 model)."
H1N "Files produced"
Bullet "00_Project_Admin/Study2_Protocol.docx; 03_Data/study2/study2_protocol.sha256"
Bullet "00_Project_Admin/Project_Roadmap.docx (Version 3); 00_Project_Admin/archive/Project_Roadmap_v2_before_Study2_2026-10-12.docx; PROJECT_PLAN.md (Phase 6b)"
Bullet "00_Project_Admin/report_builder/build_study2_protocol.ps1, update_roadmap_v3.ps1"
Closing "31A" 0 "Step 31B: build the pooled, deduplicated data set with near-duplicate groups and the hybrid inputs, exactly by the protocol's rules." $global:Blocks["31A"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_31A_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_31A_Report.docx") -Force
("SAVED Step_31A_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
