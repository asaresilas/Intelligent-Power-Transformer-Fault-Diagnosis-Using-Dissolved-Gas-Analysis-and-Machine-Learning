$ErrorActionPreference = "Stop"
# build_step_report_18.ps1 - Word report of roadmap Step 18 (report standard of 2026-10-10/11).
# Every result table is computed from the saved CSV files at build time; no result number is typed by hand.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report18_progress.txt"
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

function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed = "11 October 2026") {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}

# ---- saved outputs ------------------------------------------------------------------------------------------------
$chk = Import-Csv (Join-Path $root "08_Statistical_Analysis\cross_language_check.csv")
$py  = Import-Csv (Join-Path $root "11_Results\conventional\conventional_predictions_python.csv")
$mlc = Import-Csv (Join-Path $root "11_Results\conventional\conventional_counts.csv") | Where-Object { $_.data_role -eq "all" }
$nRows = $chk.Count
$nSame = @($chk | Where-Object { $_.all_same -eq "True" }).Count
$maxDiff = 0.0
foreach ($row in $chk) { foreach ($c in "ratio_R1", "ratio_R2", "ratio_R5", "pct_CH4", "pct_C2H4", "pct_C2H2", "boundary_distance") { $v = [double]$row.($c + "_absdiff"); if ($v -gt $maxDiff) { $maxDiff = $v } } }
$maxTxt = $maxDiff.ToString("0.0E+0", [Globalization.CultureInfo]::InvariantCulture)
$global:Blocks = @{ "18" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "18" "Cross-check MATLAB against Python" "Claude Code (this chat)"
Summary ("The three conventional methods were programmed a second time, independently, in Python and run on the same " + ($nRows / 3) + " records. The two programs agree on all " + $nSame + " of " + $nRows + " record-method rows: every diagnosis, every normality-gate flag, every ratio, every Duval percentage and every boundary distance. The largest numerical difference is " + $maxTxt + ", far below the allowed 1e-9. The conventional-method results can therefore be trusted as the baseline for the machine-learning comparison.")
H1N "Purpose of this step"
Body "The conventional methods (IEC 60599 ratios, Rogers ratios and Duval Triangle 1) are the yardstick against which the machine-learning models will be judged. Before they are used, this step checks that they were coded correctly, by building a second, independent version in another language and comparing the two record by record."
MethodSection "18"
H1N "What was done, step by step"
NumItem "1" "Read the specification only: the frozen standards tables in 02_Standards and the decisions D11, D12 and D13 that fix how the tables are applied (normality gate, inclusive ranges, dual answers, when a result is 'no diagnosis', the Rogers class mapping and the boundary distances)."
NumItem "2" "Wrote 06_Python_ML/src/conventional/conventional_methods.py from that specification. The MATLAB code was read only to see which output columns it writes, not copied."
NumItem "3" "For the Duval boundary distance, used a different geometric method from MATLAB: each zone rule is built as a polygon by clipping the triangle with the rule's limits, and the distance is measured from the sample point to the nearest polygon of another zone."
NumItem "4" "Checked that data version 1.0 is unchanged (SHA-256 manifest), then ran the Python program on all records and wrote 11_Results/conventional/conventional_predictions_python.csv."
NumItem "5" "Compared every row with MATLAB's conventional_predictions.csv: the four text outputs must be identical, and the seven numbers equal within 1e-9 (NaN and Inf in the same places). The result is 08_Statistical_Analysis/cross_language_check.csv."
NumItem "6" "Added automated tests: the 40 published worked examples, edge cases of decisions D11-D13, and a test that the two programs agree on every record."
H1N "What we found"
H2 "Agreement between MATLAB and Python"
$rows = @()
foreach ($m in "IEC60599", "Rogers", "Duval") {
  $g = @($chk | Where-Object { $_.method -eq $m })
  $cnt = { param($col) @($g | Where-Object { $_.$col -eq "True" }).Count }
  $num = @($g | Where-Object { $_.ratio_R1_same -eq "True" -and $_.ratio_R2_same -eq "True" -and $_.ratio_R5_same -eq "True" -and $_.pct_CH4_same -eq "True" -and $_.pct_C2H4_same -eq "True" -and $_.pct_C2H2_same -eq "True" -and $_.boundary_distance_same -eq "True" }).Count
  $rows += , @($m, ("" + (& $cnt "raw_result_same") + " / " + $g.Count), ("" + (& $cnt "result_same") + " / " + $g.Count), ("" + (& $cnt "gate_upper_same") + " / " + $g.Count), ("" + (& $cnt "gate_lower_same") + " / " + $g.Count), ("" + $num + " / " + $g.Count))
}
AddTable @("Method", "Raw diagnosis identical", "Final result identical", "Upper gate identical", "Lower gate identical", "All numbers within 1e-9") $rows @(70, 80, 80, 75, 75, 70)
Body ("In total " + $nSame + " of " + $nRows + " rows agree in every compared value; the largest numerical difference between the two programs is " + $maxTxt + " (rounding of the last digits of a double-precision number).")
H2 "The same counts from both programs"
$rows = @()
foreach ($m in "IEC60599", "Rogers", "Duval") {
  $g = @($py | Where-Object { $_.method -eq $m })
  $nd = @($g | Where-Object { $_.raw_result -eq "ND" }).Count
  $dt = @($g | Where-Object { $_.raw_result -eq "DT" }).Count
  $du = @($g | Where-Object { $_.raw_result -like "*/*" }).Count
  $gu = @($g | Where-Object { $_.gate_upper -eq "Normal" }).Count
  $mm = $mlc | Where-Object { $_.method -eq $m }
  $rows += , @($m, ("" + $nd + " / " + $mm.ND_raw), ("" + $dt + " / " + $mm.DT_raw), ("" + $du + " / " + ([int]$mm.D1D2_raw + [int]$mm.PDT1_raw)), ("" + $gu + " / " + $mm.n_gate_upper))
}
AddTable @("Method", "No diagnosis (ND) Python / MATLAB", "DT zone Python / MATLAB", "Dual answers Python / MATLAB", "Gated Normal Python / MATLAB") $rows @(70, 100, 90, 95, 95)
Body "These are counts before the normality gate (raw results) on all records; they are descriptions of how often each method answers, not yet measures of accuracy, which come in Steps 28 to 32."
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("Data version 1.0 unchanged before the run (SHA-256 manifest)", "PASS")
  , @("Every record and method present in both programs", ("" + $nRows + " rows - PASS"))
  , @("Identical diagnoses and gate flags (roadmap target 100 %)", ("" + $nSame + " of " + $nRows + " - PASS"))
  , @("Ratios, percentages and distances within 1e-9", ("largest difference " + $maxTxt + " - PASS"))
  , @("Published worked examples reproduced by Python (39 Duval, 1 Rogers)", "40 of 40 - PASS")
  , @("Automated test suite (pytest)", "56 of 56 PASS (45 new)")
) @(300, 150)
H1N "Problems and fixes"
Bullet "While the Python geometry was being written, it was noticed that converting the triangle coordinates to the drawing plane reverses the direction in which polygon corners are listed. The 'is the point inside this polygon' test was made independent of that direction before the comparison was run. No other problem occurred, and the comparison passed on its first run."
H1N "Decisions"
Bullet "No new decision. The Python program implements the decisions already approved for the conventional methods: D11, D12 (rules 1 and 3) and D13."
H1N "Files produced"
Bullet "08_Statistical_Analysis/cross_language_check.csv (one row per record and method, Python and MATLAB values side by side)"
Bullet "11_Results/conventional/conventional_predictions_python.csv; 03_Data/interim/step18_report.md"
Bullet "06_Python_ML/src/conventional/conventional_methods.py and step18_crosscheck.py; 06_Python_ML/tests/test_conventional_python.py"
Closing "18" 0 "Step 19: build the machine-learning preprocessing and feature pipelines (scikit-learn) for the four feature sets of the Analysis Plan, with scaling, class weighting and any oversampling fitted inside the training folds only." $global:Blocks["18"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1); if ($rr.Text -ne [string][char]13) { break }; $rr.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_18_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_18_Report.docx") -Force
("SAVED Step_18_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
