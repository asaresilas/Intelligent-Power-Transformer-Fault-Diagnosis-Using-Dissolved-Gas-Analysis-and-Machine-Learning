$ErrorActionPreference = "Stop"
$sp = "C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $sp "report12_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8
$word = New-Object -ComObject Word.Application
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
try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "12" "Transcribe the standards' decision tables" "Claude Code (this chat)"
Summary "The decision tables of the conventional methods were collected online from legitimate sources only (official free previews of the standard and open-access papers). The IEC ratio table and the IEC typical-value table were read directly from the standard (primary source). The Duval Triangle 1 zones come from two agreeing secondary sources and passed every check, but still need a final check against the standard. The Rogers table was transcribed from IEEE Std C57.104-2008 itself (added 11 October 2026); it showed that both secondary Rogers tables contained an error. The copy of that standard was supplied by the researcher and is not licensed to the researcher, so its values must be confirmed against a licensed copy before submission."
H1N "Purpose of this step"
Body "The conventional methods (IEC ratio method, Duval Triangle 1 and Rogers ratios) are fixed rule tables written in standards. Before any code uses them, every limit must be copied exactly, with the document, table and page it came from, and checked a second time. The code in later steps will read these files instead of typing numbers by hand."
MethodSection "12"
H1N "Where the tables came from"
Body "You asked me to go online and get the standards. Only legitimate copies were used: official free previews published by the standards distributor iTeh, and open-access (Creative Commons) papers. Pirated copies of the standards that appeared in the searches were not opened. No full standard is stored in the project."
AddTable @("Source", "Type", "What it gave us") @(
  , @("IEC 60599:1999+A1:2007 (Edition 2.1), official preview", "Primary", "Table 2 - the IEC ratio table (page 11); Table 3 - simplified scheme (page 12)")
  , @("IEC 60599:1999 Amendment 1:2007, official preview", "Primary", "Table A.2 - 90 % typical gas values in power transformers")
  , @("IEC 60599:2015 (Edition 3.0) redline, official preview", "Primary", "Official list of what changed in 2015; table of contents with page numbers")
  , @("IEC 60599:2022 (Edition 4.0), IEC page and preview", "Primary", "Current edition; what changed in 2022 (clauses A.3 and A.5 only)")
  , @("IEEE Std C57.104-2008 - copy supplied by the researcher (added 11 Oct 2026)", "Primary (copy not licensed to the researcher)", "Table 6 - Rogers ratios (p.16); Table 1 - Condition 1 limits (p.10); worked example (Figure 2, p.7)")
  , @("Rangel Bessa et al. 2023, Energies (CC BY)", "Secondary", "Same IEC table (agreement check); one Rogers table")
  , @("Aciu et al. 2021, Energies (CC BY)", "Secondary", "Same IEC table (agreement check); another Rogers table; 3 worked Duval examples")
  , @("Moser 2025, HV Assets article (cites IEEE C57.104-2019)", "Secondary", "Duval Triangle 1 zone limits as a table")
  , @("Manisha et al. 2022, IOP conference paper (CC BY 3.0)", "Secondary", "Duval Triangle 1 figure with zone labels; 35 worked Duval examples")
) @(190, 60, 200)
H1N "What was done, step by step"
NumItem "1" "Searched for the standards and opened only official previews and open-access papers."
NumItem "2" "Read the official preview of IEC 60599 Edition 2.1 (2007). It shows the full IEC ratio table (Table 2), its notes and the simplified scheme. These values were copied into 02_Standards/iec_ratio_table.csv, one row per fault and ratio, with the text exactly as printed."
NumItem "3" "Read the official preview of Amendment 1 (2007). It shows Table A.2, the typical gas values used to decide whether a transformer is 'normal'. Copied into 02_Standards/iec_typical_values.csv."
NumItem "4" "Checked whether these tables changed later. The official 2015 preview lists every significant technical change since 2007; the ratio table (clause 5.4) and the typical values (A.2.4) are not on that list. The 2022 edition changed only clauses A.3 and A.5. So the 2007 values are expected to be the current ones; this is marked TO VERIFY until someone reads the full 2022 text."
NumItem "5" "Compared the IEC table with two independent open-access papers: both print exactly the same values."
NumItem "6" "No primary copy of the Duval Triangle 1 limits could be obtained free. Two secondary sources were found that agree: a table citing IEEE C57.104-2019, and the labels on a triangle figure in an open-access paper. The ten zone rules were copied into 02_Standards/duval_triangle_zones.csv and marked SECONDARY - TO VERIFY."
NumItem "7" "Collected 39 worked Duval examples whose diagnosis is printed in the papers, into 02_Standards/worked_examples.csv. They will become automatic tests for the MATLAB and Python code."
NumItem "8" "Copied the two Rogers tables found in open-access papers and compared them: they disagree. On 11 October 2026 the researcher supplied a copy of IEEE Std C57.104-2008; its Table 6 (Rogers ratios) and Table 1 (Condition 1 limits) were transcribed into 02_Standards/rogers_ratio_table.csv and ieee_condition1_limits.csv, and the standard's own worked example was added to worked_examples.csv. The two secondary versions were kept, marked superseded, in rogers_secondary_versions.csv."
NumItem "9" "Second, independent check: a program (06_Python_ML/src/standards/step12_check_tables.py) holds every value typed a second time and compares it with the files, and tests the Duval rules. The record is in 02_Standards/transcription_check.md."
H1N "What we found"
H2 "IEC ratio table (IEC 60599, Table 2 of Edition 2.1 = Table 1 of later editions)"
AddTable @("Fault", "C2H2/C2H4", "CH4/H2", "C2H4/C2H6") @(
  , @("PD - partial discharges", "NS", "< 0.1", "< 0.2")
  , @("D1 - discharges of low energy", "> 1", "0.1 - 0.5", "> 1")
  , @("D2 - discharges of high energy", "0.6 - 2.5", "0.1 - 1", "> 2")
  , @("T1 - thermal fault below 300 °C", "NS", "> 1 but NS", "< 1")
  , @("T2 - thermal fault 300-700 °C", "< 0.1", "> 1", "1 - 4")
  , @("T3 - thermal fault above 700 °C", "< 0.2", "> 1", "> 4")
) @(170, 90, 90, 90)
Body "NS means 'not significant, whatever the value'. The standard says the ratios should be calculated only when at least one gas is above its typical value, and that D1 and D2 overlap, so some cases get a dual D1/D2 answer. Ranges such as 0.1 - 0.5 are printed without saying whether the end points are included; this will be fixed as a written implementation rule in Step 14."
H2 "Typical values (IEC 60599 Amendment 1:2007, Table A.2), in ppm"
AddTable @("Gas", "H2", "CH4", "C2H4", "C2H6", "C2H2 (no OLTC)", "C2H2 (OLTC)") @(
  , @("90 % typical range", "50-150", "30-130", "60-280", "20-90", "2-20", "60-280")
) @(95, 55, 55, 55, 50, 70, 70)
Body "These are not limit values. The standard says that when they are exceeded the only recommended action is to test more often. They will be used only as the 'normal or not' gate before the ratio methods, as planned."
H2 "Duval Triangle 1 zones (percent of CH4 + C2H4 + C2H2)"
AddTable @("Zone", "Rule (checked in this order)") @(
  , @("PD", "CH4 at least 98 %")
  , @("T1", "C2H4 below 20 % and C2H2 below 4 %")
  , @("T2", "C2H4 from 20 to below 50 % and C2H2 below 4 %")
  , @("T3", "C2H4 at least 50 % and C2H2 below 15 %")
  , @("DT", "three parts: C2H4 below 50 % with C2H2 4-13 %; C2H4 40-50 % with C2H2 13-29 %; C2H4 at least 50 % with C2H2 15-29 %")
  , @("D1", "C2H4 below 23 % and C2H2 at least 13 %")
  , @("D2", "two parts: C2H4 at least 23 % with C2H2 at least 29 %; C2H4 23-40 % with C2H2 13-29 %")
) @(60, 390)
H2 "Rogers ratios (IEEE Std C57.104-2008, Table 6, page 16)"
AddTable @("Case", "C2H2/C2H4 (R2)", "CH4/H2 (R1)", "C2H4/C2H6 (R5)", "Suggested fault diagnosis") @(
  , @("0", "< 0.1", "> 0.1 to < 1.0", "< 1.0", "Unit normal")
  , @("1", "< 0.1", "< 0.1", "< 1.0", "Low-energy density arcing - PD")
  , @("2", "0.1 to 3.0", "0.1 to 1.0", "> 3.0", "Arcing - high-energy discharge")
  , @("3", "< 0.1", "> 0.1 to < 1.0", "1.0 to 3.0", "Low temperature thermal")
  , @("4", "< 0.1", "> 1.0", "1.0 to 3.0", "Thermal < 700 °C")
  , @("5", "< 0.1", "> 1.0", "> 3.0", "Thermal > 700 °C")
) @(35, 70, 80, 80, 185)
Body "The standard says the Rogers method should be used only when the normal limits of the individual gases (Condition 1 of its Table 1: H2 100, CH4 120, C2H2 1, C2H4 50, C2H6 65 ppm) have been exceeded, and that some ratio combinations fit no case (no diagnosis)."
H1N "The Rogers conflict and how it was resolved"
Body "The two open-access papers printed different Rogers tables. For arcing, one gave C2H2/C2H4 between 1 and 3, the other between 0.1 and 3.0. For the two lower-temperature thermal faults, one gave C2H4/C2H6 between 1 and 3, the other between 0.1 and 3."
Body "The standard itself (IEEE Std C57.104-2008, Table 6) shows that each paper got one thing wrong: the arcing range is 0.1 to 3.0 (as in Aciu et al.), and the thermal range is 1.0 to 3.0 (as in Rangel Bessa et al.). This is a useful finding for the thesis: copying limits from secondary papers can introduce errors, which is why this project transcribes them from the standard."
Body "Important: the copy of the standard was supplied by the researcher; it is stamped as sold to another organisation and 'Not for Resale', so it is not a copy licensed to the researcher. It was used only to read the limits (facts, cited to the standard), and it is not stored in the project. Before the thesis is submitted, the values must be confirmed against a licensed copy (UMaT library or IEEE Xplore). Decision D10 is closed with this condition."
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("IEC ratio table: file vs second entry", "21 of 21 agree - PASS")
  , @("IEC typical values: file vs second entry", "8 of 8 agree - PASS")
  , @("Duval rules: file vs second entry", "10 of 10 agree - PASS")
  , @("Duval rules cover the whole triangle (501 501 test points, 0.1 % steps)", "0 gaps, 0 overlaps - PASS")
  , @("Duval rules reproduce the diagnoses printed in the papers", "39 of 39 - PASS")
  , @("Gas values of the 35 paper examples found in our own IEC TC 10 file", "35 of 35 - PASS")
  , @("Rogers table and Condition 1 limits: file vs second entry", "26 of 26 agree - PASS")
  , @("Rogers rules reproduce the standard's own worked example (Case 2)", "1 of 1 - PASS")
) @(300, 150)
Body "The last two checks give extra confidence in the secondary Duval limits: three independent works (two papers and our own transcription of the IEC TC 10 data) all fit together without a single disagreement."
H1N "Problems and fixes"
Bullet "The full IEC 60599:2022 and IEEE C57.104 texts are not free (IEC sells 60599:2022 for CHF 260). Some official previews were tried; the 2007 preview happened to include the ratio table, which solved the most important item."
Bullet "One paper describes zone T2 as 'thermal faults above 700 °C'. This is a wording error in that paper (T2 is 300-700 °C); the zone name it reports is correct and is what we test."
Bullet "One publisher's page asked for a bot check; it was not bypassed and that source was not used."
Bullet "IEEE Std C57.104 is sold only by purchase or subscription, so it could not be obtained free online. The copy later supplied by the researcher turned out to be licensed to another organisation; its limits were used (with that fact recorded) and the file was kept out of the project."
Bullet "While building the earlier step reports, Word froze when saving. The cause was found (the save command must not be called from inside a helper function) and fixed; all reports for Steps 1 and 4-11 were then produced."
H1N "Decisions"
Bullet "D10 (recorded in decisions_log.md): IEC tables from the primary 2007 previews, used as current values and marked TO VERIFY against the 2022 text; Duval Triangle 1 from agreeing secondary sources, usable and marked TO VERIFY; Rogers kept (researcher's choice) and transcribed from IEEE Std C57.104-2008 on 11 October 2026 - closed, with the condition that the values are confirmed against a licensed copy before submission."
H1N "Files produced"
Bullet "02_Standards: iec_ratio_table.csv, iec_typical_values.csv, duval_triangle_zones.csv, rogers_ratio_table.csv, ieee_condition1_limits.csv, rogers_secondary_versions.csv, worked_examples.csv, transcription_check.md, sources.md"
Bullet "06_Python_ML/src/standards/step12_check_tables.py (the checking program)"
H1N "What you can do to close the open items"
NumItem "1" "Ask the UMaT library or Prof. Annan for access to IEEE Xplore standards (IEEE C57.104-2008 and 2019) and to IEC 60599:2022, to confirm the transcribed values from licensed copies."
NumItem "2" "Do not share the IEEE file found in Downloads; it is licensed to another organisation."
Closing "12" 11 "Step 13: freeze data version 1.0 - record the fingerprints (hashes) of the processed data, these standards tables and plot_style.csv, so that every later result can be traced to exactly these files." $global:Blocks["12"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }; $doc.SaveAs2('C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Step_12_Report.docx', 16); $pg = $doc.ComputeStatistics(2); $doc.Close($false); Copy-Item 'C:\Users\SILASA~1\AppData\Local\Temp\claude\D--Research-WORK-Intelligent-Power-Transformer-Fault-Diagnosis-Using-Dissolved-Gas-Analysis-and-Machine-Learning\bf8c86e6-c609-4535-98cd-f3e94b512622\scratchpad\out_Step_12_Report.docx' (Join-Path $outDir 'Step_12_Report.docx') -Force; ('SAVED Step_12_Report.docx (' + $pg + ' pages) ' + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
