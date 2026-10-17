# report_closings.ps1 - closing sections added to every step report:
# What was achieved / Record of this step / How this helps the next steps / Open items / Abbreviations.
# Dot-source after helpers.ps1. Never call SaveAs2 from a function (it hangs) - this file does not.

$global:GlossaryCsv = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\abbreviations_glossary.csv"

$global:Closings = @{
"1" = @{
  Achieved = @(
    "A private, working Python 3.12.10 environment for the project (06_Python_ML/.venv).",
    "All 16 libraries the roadmap needs were installed and each one was tested (16 of 16 PASS).",
    "The exact versions of all 55 installed packages were written down (requirements.txt), so the same environment can be rebuilt on any computer.",
    "A reusable check program (check_environment.py) that proves the environment works.")
  Record = @(
    @("Step", "1 - Set up the Python environment"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "10 October 2026"), @("Status", "Done"),
    @("Main inputs", "Library list in the roadmap; official Python installer (python.org via winget)"),
    @("Main outputs", "06_Python_ML/.venv; requirements.txt; src/check_environment.py"),
    @("Checks", "16 of 16 libraries import without error - PASS"), @("Decisions", "None"))
  Helps = @(
    "Every later Python step runs in this environment: data preparation (Steps 5-13), machine learning (Steps 18-24), statistics (Steps 28-32) and the diagnosis service (Step 38).",
    "Because every version is pinned, an examiner can rebuild the environment and obtain the same numbers - a basic requirement for reproducible, publishable research.")
  Open = @("Steps 2 and 3 (setting up the MATLAB and Simulink Agentic Toolkits) are done by the researcher in those toolkits; their logs are still to be checked.")
  Exclude = @()
}
"4" = @{
  Achieved = @(
    "The plan and all 18 analysis-plan items were approved before any data were analysed.",
    "Decisions D1-D4 and D6 were closed; D5 was left open because only the researcher can confirm it.",
    "One single record of every decision now exists (00_Project_Admin/decisions_log.md).")
  Record = @(
    @("Step", "4 - Approve the decisions and the analysis plan"), @("Environment", "Approval gate (researcher)"),
    @("Completed", "10 October 2026"), @("Status", "Done (researcher's approval; supervisor sign-off not yet recorded)"),
    @("Main inputs", "Project_Roadmap.docx; Expected_Results_and_Analysis_Plan.docx"),
    @("Main outputs", "00_Project_Admin/decisions_log.md"),
    @("Checks", "Every open decision has a recorded outcome"), @("Decisions", "D1-D4 and D6 closed; D5 open; D8 and D9 added later"))
  Helps = @(
    "Every later step follows rules that were fixed in advance (which data, which measures, which tests), so results cannot be shaped after seeing them. Reviewers and examiners can check this.",
    "When the data later showed that a rule had to change (missing values, D8), the change was made openly, with evidence, and recorded - instead of silently.")
  Open = @(
    "The supervisor's sign-off is not yet recorded.",
    "D5 (author name and degree differ between the two original documents) is open but does not block the work.",
    "The Analysis Plan document still has to be updated with D8, D9 and the Step 12 source facts (one combined update is planned).")
  Exclude = @("D1", "D2")
}
"5" = @{
  Achieved = @(
    "All five raw files were proven unchanged since download (fingerprints match).",
    "1 021 records (117 + 584 + 70 + 49 + 201) are now in one common layout with the same gas order and a unique, traceable identifier.",
    "Two data problems were found early: the 0.0001 placeholder values and copies of benchmark cases inside the training file.")
  Record = @(
    @("Step", "5 - Load and standardise the raw datasets"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "10 October 2026"), @("Status", "Done"),
    @("Main inputs", "The five raw files in 03_Data/raw and their data cards"),
    @("Main outputs", "03_Data/interim/*_standardised.csv; checksums.sha256; step05_report.md"),
    @("Checks", "Fingerprints, record counts, 585 re-ordered IEC cells, no impossible values - all PASS"), @("Decisions", "None (problems passed to Steps 6 and 9)"))
  Helps = @(
    "Step 6 can count missing values with one program for all sources, because all files now look the same.",
    "Step 9 uses the record identifiers and original line numbers to trace every copy back to its source.",
    "The fingerprints are the basis of the data freeze in Step 13: every later result can be traced to these exact files.")
  Open = @("None - the problems found were handled in Steps 6 and 9.")
  Exclude = @()
}
"6" = @{
  Achieved = @(
    "Every one of the 5 105 gas cells (1 021 records x 5 gases) was put into exactly one group: measured, zero, placeholder or blank.",
    "It was shown, with numbers, that missing values are not random but mean 'gas not detected'.",
    "Decision D8 was taken with this evidence, and every record carries flags so the choice can be checked or reversed.")
  Record = @(
    @("Step", "6 - Record the missing values"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "10 October 2026"), @("Status", "Done"),
    @("Main inputs", "03_Data/interim/*_standardised.csv (Step 5)"),
    @("Main outputs", "*_step06.csv with flags; missing_values_report.csv; missing_values_impact_by_class.csv; step06_report.md"),
    @("Checks", "Group counts add up to 5 x records - PASS"), @("Decisions", "D8 (researcher): not available = not detected = 0 ppm; complete records as sensitivity analysis"))
  Helps = @(
    "Step 9 compares records after applying D8, so a copy is still recognised when a dash in one file became 0.0001 in another.",
    "Step 10 uses the flags to define the complete-case sensitivity set (262 of 439 training records).",
    "The machine-learning features (logarithm of concentration + 1 ppm) and the ratio methods (a zero denominator gives no diagnosis) both rely on this rule.")
  Open = @("The complete-case sensitivity analysis is run later, in the results stage. It cannot be reported for T1 on the internal test set, because no T1 test record has all five gases.")
  Exclude = @()
}
"7" = @{
  Achieved = @(
    "Every original fault label in the five files (33 rows in the label map) was translated into one shared scheme (0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3, plus the merged class T12).",
    "Every translation has a written reason and evidence (label_map.csv).",
    "Every record received a class; the class counts equal those in the data cards.")
  Record = @(
    @("Step", "7 - Harmonise the fault labels"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "10 October 2026"), @("Status", "Done"),
    @("Main inputs", "*_step06.csv (Step 6); dataset web pages; Duval and dePablo (2001)"),
    @("Main outputs", "03_Data/processed/label_map.csv (33 rows); *_step07.csv; step07_report.md"),
    @("Checks", "Every label maps to exactly one class; no record left unlabelled - PASS"), @("Decisions", "None"))
  Helps = @(
    "All methods - conventional and machine learning - are judged against the same labels, so their scores can be compared fairly.",
    "The merged scheme (with T12) is the one used to score the IEC TC 10 benchmark, because that source does not separate T1 from T2.",
    "Step 9 later confirmed the Li 2019 mapping on 115 cases that also appear in IEC TC 10 (115 of 115 agree).")
  Open = @("Correction recorded on 10 October 2026: the first version of this report said the label map has 25 rows. Re-counting the file shows 33 rows (7 for each of the three Dissanayake files, 5 for IEC TC 10, 7 for Li 2019). The data were never affected; only the number in the text was wrong, and it is now corrected here and in the CHANGELOG.")
  Exclude = @()
}
"8" = @{
  Achieved = @(
    "The main benchmark was defined precisely: 58 IEC TC 10 cases that are power transformers.",
    "The other 59 cases were kept and flagged with a reason, for a sensitivity analysis - nothing was deleted.",
    "A limitation was found early: only 1 of the 9 PD cases is a power transformer.")
  Record = @(
    @("Step", "8 - Apply the scope filter"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "10 October 2026"), @("Status", "Done"),
    @("Main inputs", "*_step07.csv (Step 7); equipment codes from Duval and dePablo (2001), Table 1"),
    @("Main outputs", "*_step08.csv; exclusion_log.csv; step08_report.md"),
    @("Checks", "Kept + excluded = total for every source - PASS"), @("Decisions", "Applies approved plan item 8"))
  Helps = @(
    "Step 10 builds the analysis sets (primary 58, all equipment 117) directly from these flags.",
    "The thesis can state exactly what the main benchmark covers, as examiners will ask.",
    "Because PD cannot be judged on 1 case, PD is planned to be judged on the internal test set (10 PD records) and in the all-equipment analysis.")
  Open = @("The Dissanayake and Li files record no equipment type, so they cannot be filtered - stated as a limitation.")
  Exclude = @()
}
"9" = @{
  Achieved = @(
    "A clean master table of 827 records with a fixed role for each (development 439, internal test 70, benchmark 117, external test 201).",
    "No training record matches any test record, exactly or nearly - the test scores later will be honest.",
    "Evidence about label quality: Li 2019 agrees with the inspections on 115 of 115 cases; Dissanayake contradicts them on 4 cases (decision D7 closed).",
    "Test records that copy benchmark cases are flagged, giving independent subsets (61 internal, 86 external) - decision D9.")
  Record = @(
    @("Step", "9 - Remove duplicates and audit leakage"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "10 October 2026"), @("Status", "Done"),
    @("Main inputs", "*_step08.csv (Step 8)"),
    @("Main outputs", "03_Data/processed/dga_master.csv; duplicate_report.csv; label_agreement_iec.csv; step09_report.md"),
    @("Checks", "No training-test match; automated tests 5 of 5 PASS"), @("Decisions", "D7 closed with evidence; D9 added"))
  Helps = @(
    "Step 10 splits only clean training data into folds.",
    "Every score reported later (internal test, external test, benchmark) is free of leakage, which is a basic requirement for a fair and publishable evaluation.",
    "The label-quality evidence supports the choice of the inspection-based IEC TC 10 set as the main benchmark.")
  Open = @("None.")
  Exclude = @()
}
"10" = @{
  Achieved = @(
    "50 fixed train-and-test splits of the training data (5 folds x 10 repeats) with a recorded seed (20261010).",
    "Near-identical records (9 groups, 26 records) always stay in the same fold.",
    "The folds are very well balanced: no class share differs by more than 0.9 percentage points.",
    "The size of every analysis set is recorded, and the automated test suite now has 9 tests (9 of 9 PASS).")
  Record = @(
    @("Step", "10 - Assign data roles and fix the folds"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "10 October 2026"), @("Status", "Done"),
    @("Main inputs", "03_Data/processed/dga_master.csv (Step 9)"),
    @("Main outputs", "03_Data/processed/folds.csv; step10_report.md; tests/test_folds.py"),
    @("Checks", "Every record has a fold in every repeat; no group split; 9 of 9 tests PASS"), @("Decisions", "None (follows the approved plan)"))
  Helps = @(
    "In Steps 18-24 every machine-learning model is trained and tested on exactly these splits, so differences between models come from the models, not from luck in the split.",
    "Because all models share the same 50 splits, the paired statistical tests planned for Steps 28-32 (corrected resampled t-test, Friedman test) are valid.")
  Open = @("None.")
  Exclude = @()
}
"11" = @{
  Achieved = @(
    "The first thesis tables (4.1, 4.1b, 4.2 and appendix A4.2) and figures (4.1-4.3) were produced by program from the clean data.",
    "It was shown that every gas differs strongly between fault classes (effect sizes 0.35 to 0.71), most of all acetylene.",
    "The gas patterns agree with known fault physics, which is a sanity check on the data.",
    "A shared colour file (plot_style.csv) was created so that Python and MATLAB figures look the same.")
  Record = @(
    @("Step", "11 - Describe the data"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "10 October 2026"), @("Status", "Done"),
    @("Main inputs", "03_Data/processed/dga_master.csv; approved colour table"),
    @("Main outputs", "11_Results/tables (T4_1, T4_1b, T4_2, A4_2); 11_Results/figures (F4_1-F4_3, plot_style.csv)"),
    @("Checks", "Table 4.1 totals equal the master table - PASS"), @("Decisions", "None"))
  Helps = @(
    "The opening tables and figures of the results chapter are ready.",
    "The strong differences confirm that the five gases carry fault information, which supports using them as the model inputs.",
    "plot_style.csv will be used by the MATLAB figures of the conventional methods (Steps 14-17), and its fingerprint is frozen in Step 13.")
  Open = @("These results are descriptive only; nothing has yet been concluded about which diagnosis method is better.",
    "Correction recorded on 11 October 2026: Table 4.1b (records removed in Step 9) first showed 137 leakage removals and listed 96 IEC TC 10 benchmark records as removed. The program counted the wrong column of the duplicate report. The corrected table shows 2 exact copies, 4 conflicting labels and 139 leakage removals, all from the training file, matching the Step 9 report. No other table or figure changed.")
  Exclude = @()
}
"12" = @{
  Achieved = @(
    "The IEC ratio table and the typical-value table were taken from the standard itself (official previews) and checked a second time.",
    "The Duval Triangle 1 zones were taken from two agreeing secondary sources and passed every check (no gaps or overlaps; 39 of 39 printed diagnoses reproduced).",
    "39 worked examples with printed diagnoses were collected for use as automatic tests.",
    "The Rogers conflict was found and documented; on 11 October 2026 the Rogers table was transcribed from IEEE Std C57.104-2008 itself, which showed that both secondary versions contained an error (decision D10 closed, values to be confirmed against a licensed copy).")
  Record = @(
    @("Step", "12 - Transcribe the standards' decision tables"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "10 October 2026; Rogers added 11 October 2026"), @("Status", "Done - all three methods have their tables (some values TO VERIFY)"),
    @("Main inputs", "Official iTeh previews of IEC 60599 (2007, 2015, 2022); open-access papers listed in 02_Standards/sources.md"),
    @("Main outputs", "02_Standards: iec_ratio_table.csv, iec_typical_values.csv, duval_triangle_zones.csv, rogers_ratio_table.csv, ieee_condition1_limits.csv, rogers_secondary_versions.csv, worked_examples.csv (40), transcription_check.md, sources.md"),
    @("Checks", "8 of 8 checks PASS (second entries, triangle coverage, worked examples, data match)"), @("Decisions", "D10 - Rogers kept and transcribed from IEEE C57.104-2008 (closed with TO VERIFY)"))
  Helps = @(
    "In Steps 14-17 the MATLAB Agentic Toolkit implements the IEC ratio method, Duval Triangle 1 and Rogers by reading these files - no limit is typed by hand.",
    "worked_examples.csv becomes a set of automatic tests, so the MATLAB code can be shown to give the same answers as the published sources.",
    "iec_typical_values.csv provides the limits for the normality gate (decision D3).",
    "Step 13 records the fingerprints of these files, so every later result can be traced to exactly these tables.")
  Open = @(
    "Rogers table and Condition 1 limits: read from a copy of IEEE C57.104-2008 that is not licensed to the researcher - confirm against a licensed copy before submission.",
    "Duval Triangle 1 zones: to be confirmed against IEEE C57.104-2019 clause 6.2.3 or IEC 60599:2022 Figure B.3.",
    "IEC tables: to be confirmed against the full IEC 60599:2022 text.",
    "Whether the end points of ranges such as 0.1 - 0.5 are included is not stated in the standard; this will be fixed as a written rule in Step 14.")
  Exclude = @()
}
"13" = @{
  Achieved = @(
    "Data version 1.0 is frozen: the fingerprints of 16 files are recorded in 03_Data/data_version_1.0.sha256 and in the CHANGELOG.",
    "Every later step can now prove it uses exactly these files (verify_data_version, automated tests 11 of 11 PASS).",
    "Figure 3.2 shows the whole data preparation with counts, all calculated from the files.",
    "The new count check found an error in Table 4.1b of Step 11, which was corrected before the freeze.")
  Record = @(
    @("Step", "13 - Freeze the data (version 1.0)"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "11 October 2026"), @("Status", "Done"),
    @("Main inputs", "All files from Steps 5 to 12"),
    @("Main outputs", "03_Data/data_version_1.0.sha256; Figure 3.2 (F3_2_data_preparation_flow PNG/PDF/CSV); 03_Data/interim/step13_report.md"),
    @("Checks", "Manifest re-verified with 0 differences; counts add up; pytest 11 of 11 PASS"), @("Decisions", "D11 approved - implementation rules for the conventional methods (Steps 14-17)"))
  Helps = @(
    "Steps 14-17 (MATLAB Agentic Toolkit) read the frozen standards tables and dga_master.csv; the MATLAB code can check the same fingerprints.",
    "Steps 18-24 (machine learning) call verify_data_version() first, so no model can be trained on changed data by accident.",
    "If a TO VERIFY value is later corrected (e.g. after checking a licensed copy of a standard), it becomes data version 1.1 with its own record, and the affected results are re-run.")
  Open = @(
    "Values marked TO VERIFY in the standards tables (IEC against the 2022 text, Duval against IEEE C57.104-2019 or IEC 60599:2022, Rogers against a licensed copy) - any correction will create data version 1.1.",
    "Steps 2 and 3 (toolkit set-up) are still to be checked.",
    "Correction recorded on 11 October 2026: Table 4.1b of Step 11 was wrong (137 leakage removals instead of 139, and 96 IEC TC 10 benchmark records wrongly listed as removed). It was fixed; no other result changed.")
  Exclude = @()
}}

$global:RegisterCsv = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\03_Data\provenance\data_and_source_register.csv"
$global:StepSources = @{
  "1"  = @("SW1")
  "4"  = @()
  "5"  = @("DS1", "DS2", "DS3", "DS4", "DS5", "SW1")
  "6"  = @("DS1", "DS2", "DS3", "DS4", "DS5", "SW1")
  "7"  = @("DS1", "DS2", "DS3", "DS4", "DS5", "DF1", "SW1")
  "8"  = @("DS1", "DS2", "DS3", "DS4", "DS5", "SW1")
  "9"  = @("DS1", "DS2", "DS3", "DS4", "DS5", "DF1", "DF2", "SW1")
  "10" = @("DF2", "DF3", "SW1")
  "11" = @("DF2", "DF4", "SW1")
  "12" = @("ST1", "ST2", "ST3", "ST4", "ST5", "P1", "P2", "P3", "P4", "P5", "DS1", "DF5", "SW1")
  "13" = @("DS1", "DS2", "DS3", "DS4", "DS5", "DF1", "DF2", "DF3", "DF4", "DF5", "DF6", "DF7", "SW1")
}

function SourceRows([string[]]$ids) {
  $reg = Import-Csv $global:RegisterCsv -Encoding UTF8
  $rows = @()
  foreach ($id in $ids) {
    $e = $reg | Where-Object { $_.id -eq $id }
    $link = @()
    if ($e.link) { $link += $e.link }
    if ($e.doi) { $link += ("DOI " + $e.doi) }
    if ($e.local_file) { $link += ("File: " + $e.local_file) }
    if ($e.sha256 -match '^[0-9A-F]{64}$') { $link += ("SHA-256 " + $e.sha256.Substring(0, 16) + "...") }
    $what = $e.reference
    if ($e.project_role) { $what += " Use: " + $e.project_role + "." }
    $rows += , @($id, $what, ($link -join "; "))
  }
  return , $rows
}

function GlossaryRows([string]$text, [string[]]$exclude) {
  $rows = @()
  foreach ($g in (Import-Csv $global:GlossaryCsv -Encoding UTF8)) {
    if ($exclude -contains $g.term) { continue }
    if ($g.always -eq "yes" -or $text -cmatch $g.pattern) { $rows += , @($g.term, $g.meaning, $g.plain_explanation) }
  }
  return , $rows
}

# Writes the closing sections in the order of the report standard (numbers come from H1N).
function Closing([string]$step, [int]$n, [string]$nextText, [string]$blockText) {
  $c = $global:Closings[$step]
  H1N "What was achieved"
  foreach ($a in $c.Achieved) { Bullet $a }
  H1N "Record of this step"
  $rec = @(); foreach ($p in $c.Record) { $rec += , @($p[0], $p[1]) }
  AddTable @("Item", "Record") $rec @(110, 340)
  H1N "Data and sources used in this step"
  $ids = $global:StepSources[$step]; $srcText = ""
  if ($ids.Count -eq 0) {
    Body "No dataset or external source was used in this step. The step approved two project documents: 00_Project_Admin/Project_Roadmap.docx and 00_Project_Admin/Expected_Results_and_Analysis_Plan.docx."
  } else {
    Body "Every dataset, document and file this step used is listed below with its full reference, link and fingerprint (SHA-256, first 16 characters shown). Method references are listed in the 'Method used' section. The complete record, with access dates, licences and full fingerprints, is the Data and Source Register (00_Project_Admin/Step_Reports/Data_and_Source_Register.docx and 03_Data/provenance/data_and_source_register.csv)."
    $s = SourceRows $ids; $srcText = (($s | ForEach-Object { $_ -join " " }) -join " ")
    AddTable @("ID", "Reference and use in the project", "Link, DOI and local file") $s @(35, 245, 170)
  }
  H1N "How this helps the next steps"
  Body ("Next step: " + $nextText)
  foreach ($h in $c.Helps) { Bullet $h }
  H1N "Open items and limitations"
  foreach ($o in $c.Open) { Bullet $o }
  H1N "Abbreviations and terms used in this report"
  Body "Every abbreviation and technical term that appears in this report is explained below. The fault types follow the definitions of IEC 60599 (clause 5.2). The full list for the whole project is kept in 00_Project_Admin/abbreviations_glossary.csv."
  $m = $global:Methods[$step]
  $mText = (@($m.Approach) + @($m.Why) + @($m.Tools) + @($m.Settings | ForEach-Object { $_ -join " " })) -join " "
  $all = $blockText + " " + $mText + " " + (($c.Achieved + $c.Helps + $c.Open) -join " ") + " " + (($c.Record | ForEach-Object { $_ -join " " }) -join " ") + " " + $srcText
  $g = GlossaryRows $all $c.Exclude
  AddTable @("Abbreviation or term", "Meaning", "Plain explanation") $g @(95, 130, 225)
}