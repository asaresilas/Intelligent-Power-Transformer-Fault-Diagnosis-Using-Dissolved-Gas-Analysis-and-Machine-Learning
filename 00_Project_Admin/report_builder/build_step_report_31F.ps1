$ErrorActionPreference = "Stop"
# build_step_report_31F.ps1 - Word report of roadmap Step 31F (search for a fresh confirmation data set).
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report31F_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
$global:Methods["31F"] = @{
  Approach = @(
    "A structured search of legitimate sources - open data repositories (Mendeley Data, Zenodo), IEEE DataPort, open-access journals and preprint servers, and the CIGRE publication catalogue - for DGA cases whose fault was confirmed by inspection and that have not been used in this project.",
    "Each candidate was judged on its own landing page against four requirements: a stated licence, a documented inspection-based labelling method, enough records for a confirmation test, and the possibility of checking overlap with the 827 records already used. No file was downloaded.")
  Why = @("Study 2's positive result (the reject option) is exploratory because IEC TC 10 and Li 2019 had already been seen; only an untouched, inspection-confirmed data set can confirm it.", "Only legitimately licensed data may be used (project rule); pirated or unlicensed copies are excluded.")
  Settings = @(
    @("Sources searched", "Mendeley Data, Zenodo, IEEE DataPort, PubMed Central / open-access journals, engrXiv, CIGRE e-cigre catalogue"),
    @("Requirements", "licence; inspection-confirmed labels with method; adequate size; overlap checkable"),
    @("Excluded", "data already used (Dissanayake files, IEC TC 10, Li 2019); unlicensed copies"))
  Eqs = @()
  Tools = @("Web search and the data sets' landing pages; record in 03_Data/provenance/study2_confirmation_search.md")
  Refs = @()
}
$global:Closings["31F"] = @{
  Achieved = @("Seven candidate sources were assessed and recorded with citation, licence and suitability.", "A practical route to a genuine confirmation set is identified (Ghanaian utility inspection records through the supervisor; contact with two data-set authors).", "Study 2 (Steps 31A-31F) is complete.")
  Record = @(
    @("Step", "31F - Search for a fresh confirmation data set (Study 2)"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "12 October 2026"), @("Status", "Done - no suitable data set available yet"),
    @("Main inputs", "Study 2 protocol (S2-Q4); data card rules"),
    @("Main outputs", "03_Data/provenance/study2_confirmation_search.md; register entries C1-C3, DF46"),
    @("Checks", "every candidate cited with its licence; no file downloaded; no unlicensed source used"),
    @("Decisions", "none new; data collection from utilities needs the researcher's and supervisor's decision"))
  Helps = @("If inspection-confirmed records are obtained, they can confirm (or refute) the reject-option result under a new, pre-registered plan.", "Step 32 now rebuilds all Chapter 4 tables and figures, including the Study 2 section.")
  Open = @(
    "S2-Q4 is answered 'not yet': no openly licensed, inspection-confirmed, independent data set was found.",
    "Contacting authors and utilities, data-sharing agreements and ethics approval are decisions for the researcher and the supervisor.",
    "The size of the CIGRE TB 771 data collection is taken from an industry summary and is TO VERIFY in the brochure itself.")
  Exclude = @()
}
$global:StepSources["31F"] = @("C1", "C2", "C3", "DF46", "DF40")
function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed = "12 October 2026") {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "31F" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "31F" "Search for a fresh confirmation data set (Study 2)" "Claude Code (this chat)"
Summary "No openly licensed set of inspection-confirmed DGA cases that is independent of the data already used could be found. Seven candidates were assessed: two openly licensed Mendeley data sets lack a documented labelling method (one has only 25 records), a Ghanaian study (KNUST, 589 'field-verified' records) does not state its source or availability, and the remaining candidates are subscription-only, compiled from the literature, or not per-case data. The strongest route is to obtain inspection records from Ghanaian utilities through the supervisor."
H1N "Purpose of this step"
Body "This step looks for the one thing that can turn Study 2's exploratory reject-option result into a confirmed one: a fresh, legitimately licensed set of DGA cases with inspection-confirmed faults."
MethodSection "31F"
H1N "Candidates assessed"
AddTable @("Candidate", "Licence / access", "Size", "Labels", "Assessment") @(
  , @("Shutenko and Kulyk 2023, Mendeley Data (Ukraine)", "CC BY 4.0", "25", "'identified fault type', method not stated", "small; ask authors about labelling")
  , @("Montero Jimenez and Gomez-Ramirez 2026, Mendeley Data (Costa Rica)", "CC BY 4.0", "not stated", "not described", "check the files")
  , @("Adu-Gyamfi 2026, engrXiv (KNUST, Ghana)", "paper CC BY; data not stated", "589", "'field-verified', method not stated", "most promising; contact author")
  , @("Li, IEEE DataPort", "subscription", "not stated", "not documented", "not suitable")
  , @("Liu / Abdo, IEEE DataPort", "subscription", "177", "from the literature", "not suitable (overlap likely)")
  , @("Arias Velasquez 2024, Heliyon", "CC BY 4.0", "totals only", "no per-case table", "not suitable")
  , @("CIGRE TB 771 (2019)", "brochure; data not released", "-", "-", "reference only")
) @(135, 75, 55, 95, 100)
H1N "Recommended route"
NumItem "1" "Local inspection records (strongest): request DGA results of transformers whose fault was later confirmed by inspection or repair from Ghanaian utilities (for example GRIDCo, ECG, VRA) through Prof. J. Annan, under a data-sharing agreement and ethics approval; the draft request letter already exists (00_Project_Admin/Dataset_Request_Letter_Prof_Annan.docx)."
NumItem "2" "Contact the KNUST author about the source, verification method, licence and overlap of the 589 records."
NumItem "3" "Contact the Ukrainian authors about how the fault types were identified; if by inspection, use the 25 records only as a small supplementary check."
Body "Any new data set must pass the project's checks before use: licence in the register, SHA-256, exact and near-duplicate overlap check against the 827 records already used, label mapping, and a written plan fixed before the model is applied."
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("Every candidate recorded with citation, link and licence", "PASS")
  , @("No file downloaded; no unlicensed or pirated source used", "PASS")
  , @("Data already used excluded from the search", "PASS")
) @(300, 150)
H1N "Problems and fixes"
Bullet "Several pages give no labelling method; these were recorded as unknown rather than guessed."
H1N "Decisions"
Bullet "No new decision. Whether to request utility data or contact authors is for the researcher and the supervisor."
H1N "Files produced"
Bullet "03_Data/provenance/study2_confirmation_search.md; register entries C1-C3 and DF46"
Closing "31F" 0 "Step 32: one script rebuilds every Chapter 4 table and figure from the saved files, including the Study 2 section (labelled exploratory)." $global:Blocks["31F"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $r2 = $doc.Content; $r2.SetRange($r2.End - 2, $r2.End - 1); if ($r2.Text -ne [string][char]13) { break }; $r2.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_31F_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_31F_Report.docx") -Force
("SAVED Step_31F_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " | " + $_.ScriptStackTrace) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
