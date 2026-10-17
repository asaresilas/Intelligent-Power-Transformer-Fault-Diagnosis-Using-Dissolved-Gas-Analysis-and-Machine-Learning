$ErrorActionPreference = "Stop"
$sp = "C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$figDir = Join-Path $root "11_Results\figures"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

$prog = Join-Path $sp "reports_progress.txt"; "begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8
$word = New-Object -ComObject Word.Application
"word up " + (Get-Date -Format T) | Out-File $prog -Append -Encoding utf8
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
$global:Blocks = @{}
$selfText = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8)
foreach ($m in [regex]::Matches($selfText, '(?s)# STEP (\d+)\r?\n(.*?)(?=# =====|\z)')) { $global:Blocks[$m.Groups[1].Value] = $m.Groups[2].Value }
if ($global:Blocks.Count -eq 0) { $global:Blocks["12"] = $selfText }

function SaveReport([string]$name) {
  $tmp = Join-Path $sp ("out_" + $name)
  $doc.SaveAs2($tmp, 16)
  $pages = $doc.ComputeStatistics(2)
  $doc.Close($false)
  Copy-Item $tmp (Join-Path $outDir $name) -Force
  "SAVED $name ($pages pages) " + (Get-Date -Format T) | Out-File $prog -Append -Encoding utf8
  "SAVED $name ($pages pages)"
}

try {
# =====================================================================================
# STEP 1
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "1" "Set up the Python environment" "Claude Code (this chat)"
Summary "Python 3.12.10 and all 16 libraries the project needs were installed in a separate project environment. Every library was tested and the exact versions were written down, so anyone can rebuild the same environment later."
H1N "Purpose of this step"
Body "All data preparation, machine learning and statistics are done in Python. This step installs Python and the libraries, in an isolated environment that belongs to the project only, so that results can be reproduced exactly."
MethodSection "1"
H1N "What was used"
Bullet "This computer, which had no Python installed."
Bullet "The official Python installer from python.org, installed through the Windows package manager (winget)."
H1N "What was done, step by step"
NumItem "1" "Checked the disks: drive C: had 359 GB free and drive D: 349 GB, so space was not a problem."
NumItem "2" "Installed Python 3.12.10 for the current user. The installer's security fingerprint (hash) was verified automatically before installation."
NumItem "3" "Created a private project environment (a 'virtual environment') in 06_Python_ML/.venv, so the project's libraries cannot clash with anything else on the computer."
NumItem "4" "Installed the libraries listed in the roadmap, plus two small additions: pyyaml (the folder README plans settings files in YAML format) and httpx (needed later to test the FastAPI service)."
NumItem "5" "Wrote a check program, 06_Python_ML/src/check_environment.py, that imports every library and prints its version."
NumItem "6" "Saved the exact version of every installed package (55 packages including their dependencies) in 06_Python_ML/requirements.txt."
H1N "What we found"
AddTable @("Library", "Version", "Used for") @(
  , @("numpy / pandas", "2.5.3 / 3.0.6", "Numbers and data tables")
  , @("scipy / statsmodels", "1.18.1 / 0.15.0", "Statistical tests")
  , @("scikit-learn", "1.9.1", "Machine-learning models and cross-validation")
  , @("xgboost", "3.4.1", "XGBoost classifier")
  , @("shap", "0.53.0", "Explaining the model (SHAP values)")
  , @("matplotlib", "3.11.2", "Figures")
  , @("openpyxl / pyyaml / joblib", "3.1.5 / 6.0.3 / 1.6.0", "Excel files, settings files, saving models")
  , @("fastapi / uvicorn / pydantic / httpx", "0.143.0 / 0.54.0 / 2.14.0 / 0.28.1", "The diagnosis service (Step 38)")
  , @("pytest", "9.1.1", "Automated checks")
) @(150, 140, 160)
H1N "Checks"
Body "The check program imported all 16 libraries without any error (result: PASS)."
H1N "Problems and fixes"
Body "None."
H1N "Files produced"
Bullet "06_Python_ML/.venv (the project environment)"
Bullet "06_Python_ML/requirements.txt (exact versions)"
Bullet "06_Python_ML/src/check_environment.py (the check program)"
Closing "1" 8 "Steps 2 and 3 are done in the MATLAB and Simulink Agentic Toolkits (instructions were given in the chat). Step 4 is the approval of the plan." $global:Blocks["1"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }; $doc.SaveAs2('C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Step_01_Report.docx', 16); $pg = $doc.ComputeStatistics(2); $doc.Close($false); Copy-Item 'C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Step_01_Report.docx' (Join-Path $outDir 'Step_01_Report.docx') -Force; ('SAVED Step_01_Report.docx (' + $pg + ' pages) ' + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8

# =====================================================================================
# STEP 4
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "4" "Approve the decisions and the analysis plan" "Approval gate (researcher)"
Summary "The researcher approved the plan and all 18 items of the analysis plan on 10 October 2026, on the condition that every step follows standard research procedure. This is recorded as the researcher's approval; the supervisor's sign-off is not yet recorded."
H1N "Purpose of this step"
Body "Fixing the decisions and the analysis method before any data is analysed prevents choosing methods after seeing the results. This is a recognised safeguard for honest research."
MethodSection "4"
H1N "What was done, step by step"
NumItem "1" "The researcher reviewed the roadmap and the Expected Results and Analysis Plan and approved them."
NumItem "2" "Each open decision (D1 to D7) was closed with the proposed resolution, except D5, which is a fact only the researcher can confirm."
NumItem "3" "For decision D6 (the fifth classifier) multinomial logistic regression was chosen: it is the standard simple and explainable baseline and is a different kind of model from the other four."
NumItem "4" "Everything was written into 00_Project_Admin/decisions_log.md, which is the single record of all decisions."
H1N "The decisions"
AddTable @("No.", "Decision", "Status") @(
  , @("D1", "Thesis Chapter 1 objectives govern; the reduced-gas study is an added study.", "Closed")
  , @("D2", "Five gases (H2, CH4, C2H6, C2H4, C2H2); CO and CO2 not used.", "Closed")
  , @("D3", "Normal kept as class 0 where present; a normality gate lets conventional methods output Normal.", "Closed")
  , @("D4", "Simulink models only the operating context; it never makes gas values.", "Closed")
  , @("D5", "Author name and degree differ between the two original documents.", "Open (not blocking)")
  , @("D6", "Classifiers: SVM, Random Forest, XGBoost, MLP, logistic regression (plus a majority baseline).", "Closed")
  , @("D7", "Dissanayake training data used for training only if its labels are not inspection-based.", "Closed in Step 9 with evidence")
  , @("D8", "Not-available gas values treated as not detected (0 ppm) - added in Step 6, replaces plan item 4.", "Closed")
  , @("D9", "Test records that copy benchmark cases are flagged - added in Step 9.", "Closed")
) @(35, 330, 85)
H1N "Problems and fixes"
Body "None at this step. Two later decisions (D8 and D9) were added when the data showed they were needed; each is explained in its own step report."
H1N "Files produced"
Bullet "00_Project_Admin/decisions_log.md"
Closing "4" 6 "Step 5: load and standardise the raw datasets." $global:Blocks["4"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }; $doc.SaveAs2('C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Step_04_Report.docx', 16); $pg = $doc.ComputeStatistics(2); $doc.Close($false); Copy-Item 'C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Step_04_Report.docx' (Join-Path $outDir 'Step_04_Report.docx') -Force; ('SAVED Step_04_Report.docx (' + $pg + ' pages) ' + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8

# =====================================================================================
# STEP 5
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "5" "Load and standardise the raw datasets" "Claude Code (this chat)"
Summary "All five data files were checked against their recorded fingerprints, read without being changed, and rewritten in one common layout. All checks passed. Two important problems were discovered in the Dissanayake files: a fake value (0.0001) used where a gas value was missing, and copies of the IEC TC 10 benchmark cases inside the training file."
H1N "Purpose of this step"
Body "The datasets come from different places and use different column names and orders. Before anything else, every file must be checked to be exactly the file that was downloaded, and then put into one common layout so all later steps can treat them the same way."
MethodSection "5"
H1N "What was used"
Bullet "The five raw files in 03_Data/raw: the IEC TC 10 table transcribed from Duval and dePablo (2001), the three Dissanayake files (training, unseen test, IEC subset) and the Li (2019) file."
Bullet "The fingerprints (SHA-256 hashes) recorded in the data cards when the files were downloaded."
H1N "What was done, step by step"
NumItem "1" "Calculated the SHA-256 fingerprint of each file and compared it with the data card. A different fingerprint would mean the file had changed."
NumItem "2" "Read each file without changing it. The Li file has three sheets; the second and third were opened and confirmed to be empty."
NumItem "3" "Renamed and re-ordered the gas columns into the shared order H2, CH4, C2H6, C2H4, C2H2. The IEC table stores the gases in a different order, so every one of its 585 gas cells was compared with the original afterwards to make sure nothing was moved to the wrong column."
NumItem "4" "Gave every record a unique identifier (for example DISTRAIN_0001), and noted its source file and line number, so any record can be traced back to the original."
NumItem "5" "Kept empty cells as missing - never replaced by zero. Counted zeros, empty cells and impossible values (negative or non-numeric)."
NumItem "6" "Wrote the fingerprints of all raw files into 03_Data/raw/checksums.sha256."
H1N "What we found"
AddTable @("Source", "Records (expected)", "Fingerprint", "Records with all 5 gases", "Repeated rows") @(
  , @("IEC TC 10 (transcription)", "117 (117)", "recorded for the first time", "99", "0")
  , @("Dissanayake training", "584 (584)", "matches", "584", "2")
  , @("Dissanayake unseen test", "70 (70)", "matches", "70", "0")
  , @("Dissanayake IEC subset", "49 (49)", "matches", "49", "0")
  , @("Li 2019", "201 (201)", "matches", "201", "0")
) @(120, 75, 95, 85, 75)
Body "Further findings from a closer look at the values:"
Bullet "The value 0.0001 ppm appears 257 times in the Dissanayake training file and 34 times in its test file. Such a tiny value cannot be measured by any laboratory, so it is a stand-in for 'no value available', not a measurement."
Bullet "The two repeated rows in the Dissanayake training file are IEC TC 10 cases. For example, lines 111 and 137 are both the IEC case 'Short circuit from LV to ground, internal'; where the paper prints a dash for ethane, the file has 0.0001."
Bullet "The Dissanayake IEC subset is not purely the paper's Annex 1: it contains 15 Normal records (Annex 1 has none) and decimal values such as 0.7, while every Annex 1 value is a whole number."
Bullet "The IEC transcription has 23 empty cells (dashes in the paper): H2 1, CH4 1, C2H6 7, C2H4 3, C2H2 11."
H1N "Checks"
Bullet "All fingerprints match the data cards - PASS."
Bullet "All record counts match: 117; 584, 70 and 49; 201 - PASS."
Bullet "IEC column re-ordering: 0 mismatches in 585 gas cells - PASS."
Bullet "No negative or non-numeric gas values - PASS."
H1N "Problems and fixes"
Body "No processing problem. The data problems found (placeholder values and copied benchmark cases) were left untouched in this step - its job is to copy faithfully - and were passed to Steps 6 and 9, where they are handled. They were also written into the data cards."
H1N "Files produced"
Bullet "03_Data/interim/IECTC10_standardised.csv, DISTRAIN_, DISTEST_, DISIEC_ and LI2019_standardised.csv"
Bullet "03_Data/interim/step05_report.md and 03_Data/raw/checksums.sha256"
Bullet "Program: 06_Python_ML/src/data_prep/step05_standardise.py"
Closing "5" 8 "Step 6: record the missing values and decide how to treat them." $global:Blocks["5"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }; $doc.SaveAs2('C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Step_05_Report.docx', 16); $pg = $doc.ComputeStatistics(2); $doc.Close($false); Copy-Item 'C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Step_05_Report.docx' (Join-Path $outDir 'Step_05_Report.docx') -Force; ('SAVED Step_05_Report.docx (' + $pg + ' pages) ' + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8

# =====================================================================================
# STEP 6
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "6" "Record the missing values" "Claude Code (this chat)"
Summary "Missing gas values are not random: they occur where a fault does not produce that gas, so they really mean 'gas not detected'. Throwing those records away would have removed almost all records of the T1 fault. The researcher therefore decided (decision D8) to treat them as 0 ppm, keep a flag on each record, and also report the analysis without them."
H1N "Purpose of this step"
Body "Some gas values are missing: empty cells (the dash in the IEC tables) and the 0.0001 stand-in found in Step 5. How they are treated can change the results, so they must be counted and understood before a rule is applied."
MethodSection "6"
H1N "What was done, step by step"
NumItem "1" "Put every gas cell into one of four groups: measured (a real positive value), zero, placeholder (exactly 0.0001) or blank (empty). 'Not available' means placeholder or blank."
NumItem "2" "Counted the groups for every gas, every source and every fault class, and flagged every record (how many of its gases are not available). Nothing was deleted or changed."
NumItem "3" "Calculated how many records each fault class would lose if records with any not-available value were thrown away (the rule first approved as plan item 4)."
NumItem "4" "Looked at which gases are missing in which fault classes."
H1N "What we found"
Body "Records left in each class if every record with a not-available value were removed (Dissanayake files):"
AddTable @("Class", "Training records", "Left after removal", "Test records", "Left after removal") @(
  , @("Normal", "85", "85", "10", "10")
  , @("PD", "59", "24", "10", "4")
  , @("D1", "76", "63", "10", "10")
  , @("D2", "134", "120", "10", "9")
  , @("T1", "96", "14", "10", "0")
  , @("T2", "45", "22", "10", "3")
  , @("T3", "89", "46", "10", "8")
) @(70, 95, 95, 95, 95)
Body "Which gas is missing: acetylene (C2H2) is not available in 80 of 96 T1 training records and in all 10 T1 test records, often in T2, T3 and PD records, and never in the D1 and D2 (electrical discharge) records. The IEC dashes follow the same pattern (C2H2 dashes in 5 of 9 PD cases and 5 of 16 T1/T2 cases)."
Body "In plain words: acetylene is formed by electrical arcs and sparks and by very hot spots. Low-temperature faults and partial discharges make little or none, so the laboratory did not detect it. A missing acetylene value is therefore information ('not detected'), not an accident."
H1N "Decision D8 (taken by the researcher)"
Bullet "Primary analysis: a not-available value is treated as 'not detected' = 0 ppm, the same as a true zero. Every record keeps a flag showing which of its values were not available."
Bullet "Sensitivity analysis: the same analysis using only records with all five gases reported, shown beside the main result."
Bullet "This replaces plan item 4, because keeping only complete records would have left no T1 test record at all and would have biased every comparison."
H1N "Checks"
Body "Every gas cell fell into exactly one of the four groups, and the group counts add up to five times the number of records - PASS."
H1N "Files produced"
Bullet "03_Data/interim/<source>_step06.csv (data with flags), missing_values_report.csv, missing_values_impact_by_class.csv, step06_report.md"
Bullet "Program: 06_Python_ML/src/data_prep/step06_missing_values.py"
Closing "6" 7 "Step 7: put all fault labels on one shared scheme." $global:Blocks["6"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }; $doc.SaveAs2('C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Step_06_Report.docx', 16); $pg = $doc.ComputeStatistics(2); $doc.Close($false); Copy-Item 'C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Step_06_Report.docx' (Join-Path $outDir 'Step_06_Report.docx') -Force; ('SAVED Step_06_Report.docx (' + $pg + ' pages) ' + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8

# =====================================================================================
# STEP 7
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "7" "Harmonise the fault labels" "Claude Code (this chat)"
Summary "Every original fault label in every dataset was translated into one shared set of codes, with a written reason for each translation. All labels were translated and the counts match the data cards."
H1N "Purpose of this step"
Body "The datasets name faults differently: Dissanayake uses numbers 0 to 6, the IEC tables use PD, D1, D2, T1/T2 and T3, and Li uses words such as 'Spark discharge'. All methods must be judged against the same labels."
MethodSection "7"
H1N "What was done, step by step"
NumItem "1" "Defined the shared fine scheme: 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3."
NumItem "2" "Defined a merged scheme in which T1 and T2 are joined as T12, for records whose source does not say whether the fault was below or above 300 degrees C."
NumItem "3" "Wrote a label map with one row for every original label, its new code, the reason and the evidence."
NumItem "4" "Applied the map to every record and counted the records per class."
H1N "The label map in plain words"
Bullet "Dissanayake: codes used as given on the dataset's web page."
Bullet "IEC TC 10: PD, D1, D2 and T3 map directly; 'T1/T2' maps to the merged class T12 because the paper puts both in one table without saying which is which."
Bullet "Li 2019: partial discharge = PD; spark discharge = D1 (low energy); arc discharge = D2 (high energy); low-, middle- and high-temperature overheating = T1, T2 and T3; 'low/middle-temperature overheating' = T12. The spark/arc rule follows the IEC paper itself, which lists sparking cases under D1 and arcing cases under D2. (Step 9 later confirmed this mapping against the IEC cases.)"
H1N "What we found"
AddTable @("Source", "Records", "Normal", "PD", "D1", "D2", "T1", "T2", "T12", "T3") @(
  , @("IEC TC 10", "117", "0", "9", "26", "48", "0", "0", "16", "18")
  , @("Dissanayake training", "584", "85", "59", "76", "134", "96", "45", "0", "89")
  , @("Dissanayake test", "70", "10", "10", "10", "10", "10", "10", "0", "10")
  , @("Dissanayake IEC subset", "49", "15", "1", "7", "15", "1", "2", "0", "8")
  , @("Li 2019", "201", "0", "16", "49", "54", "19", "9", "16", "38")
) @(110, 45, 42, 35, 35, 35, 35, 35, 38, 35)
H1N "Checks"
Body "Every original label in every file maps to exactly one row of the label map; no record was left without a class - PASS. The counts equal those in the data cards."
H1N "Files produced"
Bullet "03_Data/processed/label_map.csv (33 rows: 7 for each of the three Dissanayake files, 5 for IEC TC 10, 7 for Li 2019; each with its reason and evidence)"
Bullet "03_Data/interim/<source>_step07.csv and step07_report.md; program step07_label_map.py"
Closing "7" 7 "Step 8: keep only power transformers for the main benchmark." $global:Blocks["7"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }; $doc.SaveAs2('C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Step_07_Report.docx', 16); $pg = $doc.ComputeStatistics(2); $doc.Close($false); Copy-Item 'C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Step_07_Report.docx' (Join-Path $outDir 'Step_07_Report.docx') -Force; ('SAVED Step_07_Report.docx (' + $pg + ' pages) ' + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8

# =====================================================================================
# STEP 8
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "8" "Apply the scope filter" "Claude Code (this chat)"
Summary "The thesis is about power transformers, so the main benchmark keeps only the 58 IEC TC 10 cases that are power transformers. The other 59 cases (reactors, instrument transformers, bushings, cables, tap-changer compartments) are kept for a sensitivity analysis, not deleted."
H1N "Purpose of this step"
Body "The IEC TC 10 database covers all kinds of oil-filled equipment. For a thesis on power transformers, the main comparison should use power transformers. This was approved as plan item 8."
MethodSection "8"
H1N "What was done, step by step"
NumItem "1" "Read the equipment code of each IEC TC 10 case (Table 1 of the paper)."
NumItem "2" "Kept codes P and U (power transformers, without and with an on-load tap changer) for the primary analysis."
NumItem "3" "Flagged the others with the reason: R reactor, I instrument transformer, B bushing, C cable; S (tap-changer selector compartment - used in the tables but not defined in Table 1, and not the main tank); and one case with no equipment code, which cannot be confirmed as a power transformer."
NumItem "4" "Nothing was deleted: every record received a flag 'in scope for the primary analysis' and a reason."
H1N "What we found"
AddTable @("Equipment type", "Cases flagged out of scope") @(
  , @("R - reactor", "32")
  , @("I - instrument transformer", "12")
  , @("S - selector compartment", "7")
  , @("B - bushing", "5")
  , @("C - cable", "2")
  , @("No code given", "1")
  , @("Total out of scope", "59")
) @(250, 200)
Body "The primary benchmark therefore has 58 power-transformer cases: PD 1, D1 10, D2 27, T12 8, T3 12. Only one PD case is a power transformer (eight of the nine PD cases are instrument transformers or bushings). PD will therefore be judged on the internal test set (10 PD records) and in the all-equipment sensitivity analysis (9 PD cases), and this will be stated in the thesis."
Body "The Dissanayake and Li files record no equipment type, so they cannot be filtered; this is reported as a limitation."
H1N "Checks"
Body "For every source, kept plus excluded equals the total - PASS."
H1N "Problems and fixes"
Body "The first version of the summary table showed 58 excluded cases instead of 59: the one case with no equipment code was silently left out of the table (a known behaviour of the software when grouping empty values). The flag itself was correct. The table was fixed and the step re-run before it was accepted."
H1N "Files produced"
Bullet "03_Data/interim/<source>_step08.csv, exclusion_log.csv, step08_report.md; program step08_scope_filter.py"
Closing "8" 7 "Step 9: find duplicates and make sure no test case is hidden in the training data." $global:Blocks["8"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }; $doc.SaveAs2('C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Step_08_Report.docx', 16); $pg = $doc.ComputeStatistics(2); $doc.Close($false); Copy-Item 'C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Step_08_Report.docx' (Join-Path $outDir 'Step_08_Report.docx') -Force; ('SAVED Step_08_Report.docx (' + $pg + ' pages) ' + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8

# =====================================================================================
# STEP 9
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "9" "Remove duplicates and audit leakage" "Claude Code (this chat)"
Summary "The training data contained 96 of the IEC TC 10 benchmark cases and other copies of test records; 139 such records were removed from training so that no test case can be learned in advance. The audit also showed that Li 2019 is mostly a copy of IEC TC 10, and that some Dissanayake labels contradict the inspection results. The final clean table has 827 records and passes all automated leakage checks."
H1N "Purpose of this step"
Body "If a test case also sits in the training data, the model has seen the answer and its score is falsely high - this is called leakage. This step finds every copy and near-copy and removes them from the training data."
MethodSection "9"
H1N "The rules (fixed before looking at the results)"
NumItem "1" "Gas values are compared after applying decision D8 (dash, 0.0001 and 0 all mean not detected), so that a copy is recognised even when a dash became 0.0001."
NumItem "2" "Exact copy within one file: keep the first. If identical gases carry different labels, remove all of them, because the true label cannot be known."
NumItem "3" "A training record that matches any test record exactly, or nearly (every gas within 1 percent or 1 ppm), is removed from the training data."
NumItem "4" "Overlaps between test sets are reported and flagged, not removed."
NumItem "5" "The Dissanayake IEC subset is not used, because our full transcription of the paper replaces it; its origin is still traced."
H1N "What we found"
AddTable @("Sources compared", "Exact matches", "Near matches") @(
  , @("IEC TC 10 and Dissanayake training", "96", "0")
  , @("IEC TC 10 and Li 2019", "115", "0")
  , @("IEC TC 10 and Dissanayake test", "9", "0")
  , @("Dissanayake training and Li 2019", "125", "4")
  , @("Dissanayake training and Dissanayake test", "1", "21")
  , @("Dissanayake test and Li 2019", "10", "0")
) @(250, 100, 100)
Bullet "Removed from training: 139 records for leakage (96 matching IEC TC 10, 35 matching Li 2019, 8 matching the unseen test file), 2 exact copies, and 4 records whose identical gas values carried different labels. Training data left: 439 records."
Bullet "Li 2019 contains 115 of the 117 IEC TC 10 cases, and for all 115 its labels agree with the inspection labels. Its 16 'low/middle-temperature' records are exactly the paper's 16 T1/T2 cases. This confirms the label mapping of Step 7. Only 86 Li records are independent of the benchmark."
Bullet "Where Dissanayake copied IEC cases, its label agrees with the inspection label in 132 of 136 cases. The 4 disagreements are cases the paper calls 'thermal below 700 degrees C' that Dissanayake labelled T3 (above 700 degrees C, 3 cases) or PD (1 case). These labels cannot have come from the inspection, so part of the Dissanayake labelling was done another way, probably with a ratio method."
Bullet "The Dissanayake IEC subset: 31 of its 49 rows match the paper; 18 do not, including its 15 Normal rows."
H1N "Decisions"
Bullet "D7 closed with this evidence: the Dissanayake data is used for training only; its unseen test file is supporting evidence; the inspection-labelled IEC TC 10 set remains the main benchmark."
Bullet "D9 (standard practice): test records that copy a benchmark case are flagged. Results reported as separate evidence use only independent records - 61 of 70 in the internal test and 86 of 201 in Li 2019; the full sets are reported as a sensitivity analysis."
H1N "The clean master table"
AddTable @("Data role", "Normal", "PD", "D1", "D2", "T1/T2 (T12)", "T3", "Total") @(
  , @("Development (training)", "75", "37", "53", "85", "119 (T1 80, T2 39)", "70", "439")
  , @("Internal test", "10", "10", "10", "10", "20 (T1 10, T2 10)", "10", "70")
  , @("IEC TC 10 benchmark", "0", "9", "26", "48", "16", "18", "117")
  , @("External test (Li 2019)", "0", "16", "49", "54", "44", "38", "201")
) @(110, 42, 35, 35, 35, 85, 35, 45)
H1N "Checks"
Bullet "No training record matches any test record, exactly or nearly - PASS."
Bullet "Automated test program 06_Python_ML/tests/test_no_leakage.py (5 tests: unique identifiers, valid roles and classes, complete non-negative gases, no training-test match, no copies within a role) - 5 of 5 passed."
H1N "Problems and fixes"
Body "Two summary tables again lost rows whose label was empty (the same software behaviour as in Step 8). Both were fixed and the step re-run before it was accepted; the data itself was never affected."
H1N "Files produced"
Bullet "03_Data/processed/dga_master.csv (827 records; harmonised gases plus the original values for tracing)"
Bullet "03_Data/interim/duplicate_report.csv, label_agreement_iec.csv, step09_report.md; program step09_dedup_leakage.py"
Closing "9" 9 "Step 10: fix the cross-validation folds." $global:Blocks["9"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }; $doc.SaveAs2('C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Step_09_Report.docx', 16); $pg = $doc.ComputeStatistics(2); $doc.Close($false); Copy-Item 'C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Step_09_Report.docx' (Join-Path $outDir 'Step_09_Report.docx') -Force; ('SAVED Step_09_Report.docx (' + $pg + ' pages) ' + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8

# =====================================================================================
# STEP 10
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "10" "Assign data roles and fix the folds" "Claude Code (this chat)"
Summary "The 439 training records were divided once and for all into 5 parts, 10 times over, with a recorded random seed. Near-identical records always stay in the same part, so the cross-validation cannot be fooled by near-copies. Every part has almost exactly the same mix of fault classes."
H1N "Purpose of this step"
Body "Cross-validation trains a model on four parts of the training data and tests it on the fifth, five times. Fixing the parts in advance means every model is tested on exactly the same split, so comparisons between models are fair."
MethodSection "10"
H1N "What was done, step by step"
NumItem "1" "Found groups of near-identical records inside the training data (every gas within 1 percent or 1 ppm). There were 9 such groups, holding 26 records in total (largest group 7)."
NumItem "2" "Split the training data with 'stratified group k-fold': 5 parts, each with the same mix of the 7 fault classes, and each near-identical group kept inside one part."
NumItem "3" "Repeated the split 10 times with different, recorded random seeds (seed 20261010 plus the repeat number), giving 50 test results per model later."
NumItem "4" "Counted the records in each analysis set defined by the flags of Steps 6 to 9."
H1N "What we found"
AddTable @("Analysis set", "Records") @(
  , @("Benchmark, power transformers (primary)", "58")
  , @("Benchmark, all equipment (sensitivity)", "117")
  , @("Internal test, independent of the benchmark", "61 of 70")
  , @("External test, independent of the benchmark", "86 of 201")
  , @("Training, all five gases reported (sensitivity)", "262 of 439")
) @(300, 150)
Body "Part sizes in the first repeat: 88, 87, 87, 88 and 89 records. The largest difference between a class's share in any part and its share overall is 0.9 percentage points - the parts are very well balanced."
H1N "Checks"
Bullet "Every training record has a part in every repeat, and no near-identical group is split - PASS."
Bullet "Automated test program 06_Python_ML/tests/test_folds.py added (4 tests). The full automated suite now has 9 tests - 9 of 9 passed."
H1N "Files produced"
Bullet "03_Data/processed/folds.csv (record, group, part number in each of the 10 repeats, seed)"
Bullet "03_Data/interim/step10_report.md; program step10_folds.py"
Closing "10" 6 "Step 11: describe the data with tables and figures." $global:Blocks["10"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }; $doc.SaveAs2('C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Step_10_Report.docx', 16); $pg = $doc.ComputeStatistics(2); $doc.Close($false); Copy-Item 'C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Step_10_Report.docx' (Join-Path $outDir 'Step_10_Report.docx') -Force; ('SAVED Step_10_Report.docx (' + $pg + ' pages) ' + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8

# =====================================================================================
# STEP 11
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "11" "Describe the data" "Claude Code (this chat)"
Summary "The first results tables and figures were produced from the clean data: how many records each set has, and how each gas differs between fault classes. Every gas differs very strongly between classes, most of all acetylene. The patterns agree with what is known about how faults produce gases."
H1N "Purpose of this step"
Body "Before any model is trained, the reader must see what the data contain: how many records of each fault, and how the gas levels look in each fault class (Analysis Plan, Sections 6.3 and 12)."
MethodSection "11"
H1N "What was done, step by step"
NumItem "1" "Created the shared colour file 11_Results/figures/plot_style.csv from the approved colour table, so that Python and MATLAB figures use the same colours."
NumItem "2" "Made Table 4.1 (records by data role and class) and Table 4.1b (records removed in Step 9)."
NumItem "3" "Made Table 4.2: median and quartiles of each gas in each fault class (training data), and the Kruskal-Wallis test of whether each gas differs between classes, with its effect size epsilon-squared (Equations 23 and 24)."
NumItem "4" "Drew Figures 4.1 to 4.3 following the figure rules: made by program, saved as PNG (300 dpi) and PDF, with the plotted numbers saved beside each figure."
H1N "What we found"
AddTable @("Gas", "Kruskal-Wallis H", "p-value", "Effect size (epsilon-squared)") @(
  , @("H2", "164.5", "6.7e-33", "0.38")
  , @("CH4", "153.8", "1.2e-30", "0.35")
  , @("C2H6", "191.0", "1.5e-38", "0.44")
  , @("C2H4", "263.9", "4.3e-54", "0.60")
  , @("C2H2", "311.3", "3.0e-64", "0.71")
) @(80, 120, 110, 140)
Body "Training data, n = 439 records, 7 classes (6 degrees of freedom). In plain words: every gas differs strongly between the fault classes; acetylene (C2H2) differs the most (it explains about 71 percent of the variation in ranks), and ethylene (C2H4) next."
Body "The patterns in Figure 4.2 match known fault physics, which is a useful sanity check of the data: acetylene is high only for the electrical discharges D1 and D2; ethylene rises from T1 to T2 to T3 as thermal faults get hotter; hydrogen is highest for partial discharge. These are descriptions, not yet conclusions."
Caption "Figure 4.1 - Records per fault class in each data role"
Pic (Join-Path $figDir "F4_1_records_per_class.png") 440
Caption "Figure 4.2 - Gas concentrations by fault class, training data (log scale of concentration + 1 ppm, because not-detected values are 0 ppm)"
Pic (Join-Path $figDir "F4_2_gas_by_class.png") 440
Caption "Figure 4.3 - Spearman rank correlation between the gases, training data"
Pic (Join-Path $figDir "F4_3_gas_correlation.png") 300
H1N "Checks"
Body "The totals in Table 4.1 equal the master table for every data role - PASS. All numbers come from the program; none was typed by hand."
H1N "Problems and fixes"
Bullet "The first version of Figure 4.2 had panel titles running into each other and overlapping class names on the axis. The layout was fixed (two-line titles, angled class names, one axis label per row) and the figure re-checked."
Bullet "A logarithmic axis cannot show 0 ppm. Because not-detected values are 0 ppm (decision D8), Figure 4.2 plots 'concentration + 1 ppm', the same shift used for the machine-learning features (Equation 11), and the axis label says so."
H1N "Files produced"
Bullet "11_Results/tables: T4_1, T4_1b, T4_2 and appendix A4_2 (benchmark version)"
Bullet "11_Results/figures: F4_1, F4_2, F4_3 (PNG, PDF, CSV) and plot_style.csv"
Bullet "03_Data/interim/step11_report.md; programs analysis/step11_describe.py and analysis/plotstyle.py"
Closing "11" 7 "Step 12: obtain the standards (IEC 60599, IEEE C57.104-2019, Duval Triangle 1 zones) from legitimate sources and transcribe their decision tables, twice, with clause and page." $global:Blocks["11"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }; $doc.SaveAs2('C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Step_11_Report.docx', 16); $pg = $doc.ComputeStatistics(2); $doc.Close($false); Copy-Item 'C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Step_11_Report.docx' (Join-Path $outDir 'Step_11_Report.docx') -Force; ('SAVED Step_11_Report.docx (' + $pg + ' pages) ' + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
}
finally {
  if ($doc) { try { $doc.Close($false) } catch {} }
  $word.Quit()
}
"ALL REPORTS DONE"
