$ErrorActionPreference = "Stop"
$sp = "C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$figDir = Join-Path $root "11_Results\figures"
$prog = Join-Path $sp "report13_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
$global:Blocks = @{ "13" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }
$manifest = Get-Content (Join-Path $root "03_Data\data_version_1.0.sha256")
$counts = Import-Csv (Join-Path $figDir "F3_2_data_preparation_flow.csv")
function N([string]$item) { ($counts | Where-Object { $_.item -eq $item } | Select-Object -First 1).records }
try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "13" "Freeze the data (version 1.0)" "Claude Code (this chat)" "11 October 2026"
$global:sec = 0
Summary ("All data and standards tables that later steps depend on are now frozen as data version 1.0: the digital fingerprints of " + $manifest.Count + " files are recorded, and every later step must check them before reading the data. Figure 3.2 shows, with counts, how the " + (N "IECTC10") + " + " + (N "DISTRAIN") + " + " + (N "DISTEST") + " + " + (N "DISIEC") + " + " + (N "LI2019") + " raw records became the " + (N "all") + " records of the master table. While building this figure, an automatic count check found an error in Table 4.1b of Step 11, which was corrected before the freeze.")
H1N "Purpose of this step"
Body "From this point the project moves from preparing the data to using it. Freezing the data means that every later result - conventional methods, machine learning, statistics - can be traced to exactly the same files. Any change after this point must be made openly, as a new data version."
MethodSection "13"
H1N "What was done, step by step"
NumItem "1" "Listed every file that later steps depend on: the five raw data files, the three processed tables (master table, folds, label map), the seven standards tables and the figure-style file."
NumItem "2" "Calculated the SHA-256 fingerprint of each file and wrote them into 03_Data/data_version_1.0.sha256 and into the CHANGELOG."
NumItem "3" "Added a check function (verify_data_version) that recalculates every fingerprint and reports any file that has changed or is missing, and an automated test that runs it."
NumItem "4" "Drew Figure 3.2 from the files, with built-in checks that the counts add up."
NumItem "5" "The count check failed on the first run. The cause was traced to Table 4.1b of Step 11 (see Problems and fixes); the table was corrected, and the step was run again until every check passed."
H1N "What we found"
H2 "Frozen files (data version 1.0)"
$rows = @()
foreach ($l in $manifest) { $parts = $l -split "  ", 2; $rows += , @($parts[1], ($parts[0].Substring(0, 16).ToUpper() + "...")) }
AddTable @("File", "SHA-256 fingerprint (first 16 characters)") $rows @(300, 150)
Body "The full 64-character fingerprints are in 03_Data/data_version_1.0.sha256 and in the CHANGELOG."
H2 "Figure 3.2 - how the data were prepared"
Caption "Figure 3.2 - Data-preparation flow with record counts (Steps 5 to 13)"
Pic (Join-Path $figDir "F3_2_data_preparation_flow.png") 440
Body ("Reading the figure from top to bottom: the five raw files hold " + ((N "IECTC10") -as [int]) + ", " + (N "DISTRAIN") + ", " + (N "DISTEST") + ", " + (N "DISIEC") + " and " + (N "LI2019") + " records. Steps 5 to 8 changed no record count. Step 9 removed " + (N "leakage") + " training records that match a test record, " + (N "exact copy") + " exact copies and " + (N "label conflict") + " records with conflicting labels, and did not use the 49-record IEC subset. The master table has " + (N "all") + " records: development " + (N "development") + ", internal test " + (N "internal_test") + ", benchmark " + (N "benchmark") + " and external test " + (N "external_test") + ".")
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("Manifest re-verified (every fingerprint recalculated)", "0 differences - PASS")
  , @("Development = training file - removed records", ((N "development") + " = " + (N "DISTRAIN") + " - " + (N "leakage") + " - " + (N "exact copy") + " - " + (N "label conflict") + " - PASS"))
  , @("Master table = sum of the four data roles", ((N "all") + " - PASS"))
  , @("Folds cover exactly the development set", ((N "5 folds x 10 repeats") + " records - PASS"))
  , @("Automated test suite (pytest)", "11 of 11 PASS (2 new tests for the frozen version)")
) @(300, 150)
H1N "Problems and fixes"
Bullet "Table 4.1b of Step 11 (records removed in Step 9) was wrong. The program counted the 'record_id' column of the duplicate report; but in a leakage row that column sometimes holds the matched test record, not the removed training record. The table therefore showed 137 leakage removals instead of 139, and listed 96 IEC TC 10 benchmark records as 'removed' although they were never removed. The new count check in this step exposed the error. The program now counts the training records that are missing from the master table; the corrected table shows 2 exact copies, 4 conflicting labels and 139 leakage removals, exactly as in the Step 9 report. No other table, figure or data file changed. The Step 11 report records this correction."
Bullet "The first version of Figure 3.2 had text touching the box edges; the lines were wrapped and the boxes widened, and the figure was checked again."
H1N "Decisions"
Bullet "Decision D10 (Rogers) was closed in Step 12 before the freeze, so the Rogers table is part of data version 1.0."
Bullet "Decision D11 (approved by the researcher on 11 October 2026): the implementation rules for Steps 14-17 - normality gate at the upper end of the IEC Table A.2 ranges (lower end as sensitivity); C2H2 range by tap-changer type; printed ranges include their end points; IEC dual D1/D2 answers counted as correct for D1 or D2 and reported separately; Rogers cases 0-5 mapped to Normal, PD, D2, T1, T2, T3; one common normality gate for all three methods."
H1N "Files produced"
Bullet "03_Data/data_version_1.0.sha256 (the manifest); 03_Data/interim/step13_report.md"
Bullet "11_Results/figures/F3_2_data_preparation_flow.png, .pdf and .csv (Figure 3.2 and its numbers)"
Bullet "06_Python_ML/src/data_prep/step13_freeze.py; verify_data_version() in common.py; 06_Python_ML/tests/test_data_version.py"
Bullet "Corrected: 11_Results/tables/T4_1b_records_removed.csv (Step 11)"
Closing "13" 0 "Steps 14 to 17 in the MATLAB Agentic Toolkit - complete the conventional-method functions so that they read every limit from 02_Standards, unit-test them with worked_examples.csv, run them on every record, and plot the Duval Triangles. The instructions for the toolkit are in 00_Project_Admin/Toolkit_Instructions/Steps_14-17_MATLAB.md." $global:Blocks["13"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }; $doc.SaveAs2('C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Step_13_Report.docx', 16); $pg = $doc.ComputeStatistics(2); $doc.Close($false); Copy-Item 'C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Step_13_Report.docx' (Join-Path $outDir 'Step_13_Report.docx') -Force; ('SAVED Step_13_Report.docx (' + $pg + ' pages) ' + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
