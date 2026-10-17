$ErrorActionPreference = "Stop"
$sp = "C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $sp "register_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
$reg = Import-Csv (Join-Path $root "03_Data\provenance\data_and_source_register.csv") -Encoding UTF8
$glo = Import-Csv (Join-Path $root "00_Project_Admin\abbreviations_glossary.csv") -Encoding UTF8
try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
Title "Data and Source Register" 18
Title "Every dataset, document and file used in the project - for reproducibility" 13
Center "Prepared by: Claude Code (this chat)   |   Version 2, 11 October 2026 (after Roadmap Step 12)"
Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
Ital "Abbreviations (such as DGA, PD, D1, ppm, SHA-256) are explained in the last section of this register."
Summary "The project uses five data files from three published sources, five standards documents and five open-access papers. Each is listed below with its full reference, link, DOI, access date, how it was obtained, its licence, where it is stored and its digital fingerprint (SHA-256). A reproducibility test was run on 10 October 2026: all data-preparation programs were run again from the raw files, and all 36 output tables came out exactly identical."

H1 "1. Purpose of this register"
Body "Another researcher, a supervisor or an examiner must be able to get the same data and obtain the same results. For that they need to know exactly which files were used, where to get them, and how to check that their copy is identical to ours. This register gives all of that in one place. It is kept in two forms: this report, and a table that programs can read (03_Data/provenance/data_and_source_register.csv)."
H1 "2. How to read this register"
AddTable @("ID starts with", "Meaning") @(
  , @("DS", "Dataset - gas measurements with fault labels")
  , @("ST", "Standard - IEC or IEEE document")
  , @("P", "Paper or article that was read and cited")
  , @("SW", "Software used to process the data")
  , @("DF", "Derived file - made by our programs from the sources above")
) @(110, 340)
Body "A SHA-256 fingerprint is a 64-character code calculated from a file. If even one character of the file changes, the fingerprint changes. Anyone can calculate it (in Windows PowerShell: Get-FileHash <file>) and compare it with the value printed here."

H1 "3. The datasets"
Body "Three published sources supply five data files. The overview comes first, then one record per file."
AddTable @("ID", "Dataset", "Records", "Role in the project") @(
  , @("DS1", "IEC TC 10 database (Duval and dePablo 2001, Annex 1), transcribed by us", "117", "Main benchmark - 58 power transformers (primary), all 117 (sensitivity)")
  , @("DS2", "Dissanayake DGA dataset - DGA_train.xlsx", "584", "Training (development) set - 439 after cleaning")
  , @("DS3", "Dissanayake DGA dataset - DGA_test_unseen.xlsx", "70", "Internal test set - 61 independent of the benchmark")
  , @("DS4", "Dissanayake DGA dataset - IEC_TC_10_data.xlsx", "49", "Not used in any role (replaced by DS1)")
  , @("DS5", "Li 2019 DGA dataset - DGA dataset.xlsx", "201", "External test set - 86 independent of the benchmark")
) @(35, 190, 50, 175)
$fields = @(
  @("reference", "Reference"), @("link", "Link"), @("doi", "DOI"), @("accessed", "Accessed / downloaded"),
  @("how_obtained", "How obtained"), @("licence_terms", "Licence / terms"), @("local_file", "Stored in project"),
  @("sha256", "SHA-256 fingerprint"), @("records", "Records"), @("project_role", "Role in the project"),
  @("used_in_steps", "Used in roadmap steps"), @("notes", "Notes and known problems"))
$k = 0
foreach ($e in ($reg | Where-Object { $_.id -like "DS*" })) {
  $k++
  H2 ("3." + $k + " " + $e.id + " - " + $e.name)
  $rows = @()
  foreach ($f in $fields) { $v = $e.($f[0]); if ($v) { $rows += , @($f[1], $v) } }
  AddTable @("Item", "Record") $rows @(110, 340)
}

H1 "4. How the datasets became the analysis data"
Body "The raw files are never changed. Programs read them, clean them and write new files. The table shows what each raw file became; every number was produced by the programs of Steps 5 to 10."
AddTable @("Raw file", "Records in", "Records in the master table", "Analysis sets") @(
  , @("DS1 IEC TC 10", "117", "117 (benchmark)", "Primary 58 power transformers; sensitivity 117")
  , @("DS2 DGA_train", "584", "439 (development)", "139 removed for leakage, 2 exact copies, 4 conflicting labels; complete-case subset 262")
  , @("DS3 DGA_test_unseen", "70", "70 (internal test)", "Independent of benchmark 61; all 70 as sensitivity")
  , @("DS4 IEC_TC_10_data", "49", "0", "Not used")
  , @("DS5 Li 2019", "201", "201 (external test)", "Independent of benchmark 86; all 201 as sensitivity")
  , @("Total", "1 021", "827", "Folds: 5 x 10 repeats on the 439 development records, seed 20261010")
) @(95, 60, 110, 185)

H1 "5. Standards, papers, articles and method references"
$rows = @()
foreach ($e in ($reg | Where-Object { $_.id -like "ST*" -or $_.id -like "P*" -or $_.id -like "M*" })) {
  $l = $e.link; if ($e.doi) { $l = $l + " (DOI " + $e.doi + ")" }
  $rows += , @($e.id, $e.reference, $l, ($e.project_role + " [" + $e.licence_terms + "]"))
}
AddTable @("ID", "Reference", "Link", "What it was used for [licence]") $rows @(30, 150, 130, 140)
Body "Standards are copyrighted. Only official free previews were read, no full standard is stored in the project, and only the limits needed for the work were transcribed (02_Standards). IEEE Std C57.104 (ST5) is still to be obtained (decision D10)."

H1 "6. Software"
$e = $reg | Where-Object { $_.id -eq "SW1" }
AddTable @("Item", "Record") @(
  , @("Software", $e.reference)
  , @("Link", $e.link)
  , @("How installed", $e.how_obtained)
  , @("Version list", ($e.local_file + " - SHA-256 " + $e.sha256))
  , @("Later steps", "MATLAB R2025b with Simscape (MATLAB and Simulink Agentic Toolkits) - versions to be recorded when Steps 2-3 are checked")
) @(110, 340)

H1 "7. Files made by the project (derived files)"
Body "These files are made by our programs. Their fingerprints below are the working values of 10 October 2026; Step 13 will freeze them as data version 1.0. The 02_Standards files will change once more, when the Rogers table is added (decision D10)."
$df = @()
foreach ($e in ($reg | Where-Object { $_.id -like "DF*" -and $_.sha256 -match '^[0-9A-F]{64}$' })) { $df += , @($e.local_file, $e.how_obtained, $e.records, $e.sha256) }
foreach ($p in @("iec_ratio_table.csv", "iec_typical_values.csv", "duval_triangle_zones.csv", "rogers_ratio_table.csv", "worked_examples.csv")) {
  $full = Join-Path $root ("02_Standards\" + $p)
  $n = (Get-Content $full).Count - 1
  $df += , @(("02_Standards/" + $p), "Transcribed in Step 12; checked by step12_check_tables.py", ("" + $n), (Get-FileHash $full -Algorithm SHA256).Hash)
}
AddTable @("File", "Made by", "Rows", "SHA-256 fingerprint") $df @(115, 120, 35, 180)

H1 "8. Reproducibility test (10 October 2026)"
NumItem "1" "The fingerprints of all 36 data tables made so far (03_Data/interim, 03_Data/processed, 11_Results/tables and the figure data files) were recorded."
NumItem "2" "All eight programs of Steps 5 to 12 were run again, in order, from the raw files."
NumItem "3" "The fingerprints were calculated again and compared: 36 of 36 tables are exactly identical."
NumItem "4" "The automated checks were run again: 9 of 9 passed."
Body "In plain words: the data preparation is fully repeatable. Anyone with the same raw files and the same software versions will get exactly the same tables."

H1 "9. How someone else can reproduce the data"
NumItem "1" "Get the raw data: download DS2-DS4 from https://ieee-dataport.org/documents/dga-dataset and DS5 from the Li 2019 page (an IEEE DataPort login is needed). DS1 is our transcription in 03_Data/raw/iec_tc10_duval2001_full; it can be re-checked against the paper (DOI 10.1109/57.917529)."
NumItem "2" "Check the files: calculate their SHA-256 fingerprints and compare with section 3 or with 03_Data/raw/checksums.sha256. They must be identical."
NumItem "3" "Install Python 3.12.10, create a virtual environment in 06_Python_ML/.venv and install the exact versions: pip install -r requirements.txt."
NumItem "4" "From the folder 06_Python_ML, run in order: src/data_prep/step05_standardise.py, step06_missing_values.py, step07_label_map.py, step08_scope_filter.py, step09_dedup_leakage.py, step10_folds.py, then src/analysis/step11_describe.py and src/standards/step12_check_tables.py (each with: .venv\Scripts\python.exe -I <program>)."
NumItem "5" "Run the automated checks (python -m pytest tests) and compare the fingerprints of the processed files with section 7."

H1 "10. Open items (TO VERIFY)"
Bullet "Licence of the IEEE DataPort datasets (DS2-DS5): the pages state none; IEEE DataPort terms apply. Must be confirmed before any data are shared."
Bullet "Units of DS2-DS5 are not stated on the pages (treated as ppm, the usual unit; DS1 is stated in ppm in the same paper)."
Bullet "How the labels of DS2-DS3 and of the 86 independent DS5 records were made is not documented. The DS5 page offers a documentation file (DGA dataset.pdf) that has not yet been read."
Bullet "ST4 (IEC 60599:2022 full text) and ST5 (IEEE C57.104) are still to be obtained to confirm the standards tables and to add the Rogers table."

H1 "11. Reference list"
$i = 0
foreach ($e in ($reg | Where-Object { $_.id -like "DS*" -or $_.id -like "ST*" -or $_.id -like "P*" -or $_.id -like "M*" })) {
  if ($e.id -in @("DS3", "DS4")) { continue }
  $i++
  $l = if ($e.doi) { " doi: " + $e.doi + "." } else { " Available: " + $e.link }
  $label = if ($e.id -eq "DS2") { " (files DS2, DS3, DS4)" } else { "" }
  Ref ("[" + $i + "] " + $e.reference + $l + " Accessed " + $(if ($e.accessed) { $e.accessed } else { "- not yet obtained" }) + "." + $label)
}

H1 "12. Abbreviations and terms used in this register"
$all = ($reg | ForEach-Object { $_.PSObject.Properties.Value -join " " }) -join " "
$all += " SHA-256 Python DGA ppm benchmark training internal test external test sensitivity fingerprint leakage complete-case"
$g = @()
foreach ($t in $glo) { if ($t.always -eq "yes" -or $all -cmatch $t.pattern) { $g += , @($t.term, $t.meaning, $t.plain_explanation) } }
AddTable @("Abbreviation or term", "Meaning", "Plain explanation") $g @(95, 130, 225)

while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }; $doc.SaveAs2('C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Data_and_Source_Register.docx', 16); $pg = $doc.ComputeStatistics(2); $doc.Close($false); Copy-Item 'C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Data_and_Source_Register.docx' (Join-Path $outDir 'Data_and_Source_Register.docx') -Force; ('SAVED Data_and_Source_Register.docx (' + $pg + ' pages) ' + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
