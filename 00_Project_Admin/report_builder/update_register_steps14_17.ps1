# update_register_steps14_17.ps1 - adds the sources and files of roadmap Steps 14-17 to
#   03_Data/provenance/data_and_source_register.csv and the new terms to 00_Project_Admin/abbreviations_glossary.csv.
# Run once after the Step 14-17 outputs exist (11 October 2026). Safe to re-run: existing IDs are replaced, not duplicated.
# Also repairs DF5, whose sha256 field had been stored as "System.Object[]" (a PowerShell array written to CSV by mistake).
$ErrorActionPreference = "Stop"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$regFile = Join-Path $root "03_Data\provenance\data_and_source_register.csv"
$gloFile = Join-Path $root "00_Project_Admin\abbreviations_glossary.csv"
$utf8 = New-Object Text.UTF8Encoding($false)
# The function is not called "H": H is a built-in alias of Get-History and would win over a function.
function Hsh([string]$rel) { (Get-FileHash (Join-Path $root $rel) -Algorithm SHA256).Hash }

$reg = [System.Collections.ArrayList]@(Import-Csv $regFile -Encoding UTF8)
$cols = $reg[0].PSObject.Properties.Name
function NewRow([hashtable]$h) { $o = [ordered]@{}; foreach ($c in $cols) { $o[$c] = if ($h.ContainsKey($c)) { [string]$h[$c] } else { "" } }; [pscustomobject]$o }
function Put($row) {
  for ($i = $reg.Count - 1; $i -ge 0; $i--) { if ($reg[$i].id -eq $row.id) { $reg.RemoveAt($i) } }
  [void]$reg.Add($row)
}

# --- repair DF5: fingerprints of the seven standards tables, read from the frozen manifest -------------------
$man = Get-Content (Join-Path $root "03_Data\data_version_1.0.sha256") | Where-Object { $_ -match "02_Standards" }
$df5 = ($man | ForEach-Object { $p = $_ -split "  ", 2; (Split-Path $p[1] -Leaf) + "=" + $p[0].ToUpper() }) -join "; "
foreach ($r in $reg) { if ($r.id -eq "DF5") { $r.sha256 = $df5 } }

# --- extend used_in_steps for the sources that Steps 14-17 use ----------------------------------------------
foreach ($r in $reg) {
  if ($r.id -in @("ST1", "ST2", "ST5", "P2", "P3", "P4", "DF2", "DF4", "DF5", "DF6") -and $r.used_in_steps -notmatch "14-17") {
    $r.used_in_steps = ($r.used_in_steps.TrimEnd() + ", 14-17")
  }
}

$acc = "2026-10-11"
Put (NewRow @{ id = "SW2"; category = "Software"; name = "MATLAB R2025b"
  reference = "MATLAB R2025b, version 25.2.0.2998904, The MathWorks, Inc., Natick, MA, USA."
  link = "https://www.mathworks.com/products/matlab.html"; accessed = $acc
  how_obtained = "Installed on the researcher's computer; driven from Claude Code through the MATLAB MCP connection"
  licence_terms = "Commercial software; licence details are not recorded in the project"
  project_role = "Runs the conventional-method functions, unit tests, batch run and Duval figures (Steps 14-17)"
  used_in_steps = "14-17"; notes = "Base MATLAB only: matlab.codetools.requiredFilesAndProducts lists no toolbox for any entry point" })
Put (NewRow @{ id = "M8"; category = "Method reference"; name = "Sutherland and Hodgman 1974 (polygon clipping)"
  reference = "I. E. Sutherland and G. W. Hodgman, `"Reentrant polygon clipping,`" Communications of the ACM, vol. 17, no. 1, pp. 32-42, Jan. 1974."
  link = "https://cacmb4.acm.org/magazines/1974/1/11767-reentrant-polygon-clipping"; doi = ""; accessed = $acc
  how_obtained = "Cited; bibliographic details checked by web search (paper not read)"; licence_terms = "ACM copyright; cited only"
  project_role = "Method used to turn each Duval rule into a polygon (duval_zone_polygons.m)"; used_in_steps = "14, 17"
  notes = "Venue, volume 17, issue 1, pages 32-42 and year 1974 confirmed from the ACM listing and a patent citation on 11 Oct 2026 (web search). The DOI could NOT be confirmed and was removed (an earlier DOI had been written from memory). TO VERIFY: add the DOI from the ACM Digital Library." })
Put (NewRow @{ id = "M9"; category = "Method reference"; name = "IEEE Std 754-2019 (floating-point arithmetic)"
  reference = "IEEE Standard for Floating-Point Arithmetic, IEEE Std 754-2019, 2019."
  link = "https://doi.org/10.1109/IEEESTD.2019.8766229"; doi = "10.1109/IEEESTD.2019.8766229"; accessed = $acc
  how_obtained = "Cited (not read in this project)"; licence_terms = "IEEE copyright; cited only"
  project_role = "Basis for comparing a ratio exactly with a printed limit: a correctly rounded quotient equal to a limit gives the same double number"
  used_in_steps = "14, 15"; notes = "Title, DOI 10.1109/IEEESTD.2019.8766229, publication date 22 July 2019 and status confirmed from reference listings (GlobalSpec, BibBase) on 11 Oct 2026 (web search). The standard text itself was not read." })

Put (NewRow @{ id = "DF8"; category = "Derived file"; name = "Conventional-method MATLAB code (manifest)"
  reference = "Made in Steps 14-17: 22 MATLAB files in 04_MATLAB_Conventional and its tests folder."
  accessed = $acc; how_obtained = "Written in this project; fingerprints of all 22 files listed in the manifest"
  licence_terms = "Project file"; local_file = "04_MATLAB_Conventional/code_manifest.sha256"; sha256 = (Hsh "04_MATLAB_Conventional\code_manifest.sha256")
  records = "22 files"; project_role = "The three conventional methods, boundary distances, tests, batch run, figures"; used_in_steps = "14-17"
  notes = "Each .m file starts with a help text (purpose, inputs, outputs, rules, sources). Step 18 re-implements the methods in Python." })
Put (NewRow @{ id = "DF9"; category = "Derived file"; name = "Conventional predictions (3 methods x 827 records)"
  reference = "Made in Step 16 by run_conventional_batch.m on data version 1.0."
  accessed = $acc; how_obtained = "Program output"; licence_terms = "Project file"
  local_file = "11_Results/conventional/conventional_predictions.csv"; sha256 = (Hsh "11_Results\conventional\conventional_predictions.csv")
  records = "2481"; project_role = "Input of the agreement analysis (Step 18 onwards) and of the boundary-distance test (RQ2)"; used_in_steps = "16"
  notes = "Columns are described in 11_Results/conventional/README.md" })
Put (NewRow @{ id = "DF10"; category = "Derived file"; name = "Counts of ND, DT and dual answers per method and data role"
  reference = "Made in Step 16 by run_conventional_batch.m."
  accessed = $acc; how_obtained = "Program output"; licence_terms = "Project file"
  local_file = "11_Results/conventional/conventional_counts.csv"; sha256 = (Hsh "11_Results\conventional\conventional_counts.csv")
  records = "15 rows"; project_role = "Table of unresolved and dual results"; used_in_steps = "16" })
Put (NewRow @{ id = "DF11"; category = "Derived file"; name = "Impact of decision D12 and of the normality gate"
  reference = "Made in Step 14 by impact_of_rules.m (impact_of_rules.csv and gate_by_class.csv)."
  accessed = $acc; how_obtained = "Program output"; licence_terms = "Project file"
  local_file = "11_Results/conventional/impact_of_rules.csv"; sha256 = (Hsh "11_Results\conventional\impact_of_rules.csv")
  records = "12 items"; project_role = "Evidence for decision D12; gate_by_class.csv SHA-256 " + (Hsh "11_Results\conventional\gate_by_class.csv"); used_in_steps = "14, 16"
  notes = "gate_by_class.csv: " + (Hsh "11_Results\conventional\gate_by_class.csv") })
Put (NewRow @{ id = "DF12"; category = "Derived file"; name = "Sanity check of the methods against the IEC TC 10 benchmark"
  reference = "Made in Step 16 by sanity_check_vs_truth.m. Plausibility check only, not a result."
  accessed = $acc; how_obtained = "Program output"; licence_terms = "Project file"
  local_file = "11_Results/conventional/sanity_agreement_benchmark.csv"; sha256 = (Hsh "11_Results\conventional\sanity_agreement_benchmark.csv")
  records = "3 rows"; project_role = "Shows the implementations behave plausibly before the formal evaluation"; used_in_steps = "16" })
Put (NewRow @{ id = "DF13"; category = "Derived file"; name = "Unit-test log of the conventional methods"
  reference = "Made in Step 15 by run_tests_and_log.m (66 tests)."
  accessed = $acc; how_obtained = "Program output"; licence_terms = "Project file"
  local_file = "04_MATLAB_Conventional/tests/test_log.txt"; sha256 = (Hsh "04_MATLAB_Conventional\tests\test_log.txt")
  records = "66 tests"; project_role = "Proof that the MATLAB code reproduces the published worked examples and the D11/D12 rules"; used_in_steps = "15" })
$figs = "development", "internal_test", "benchmark", "external_test"
$figNote = ($figs | ForEach-Object { "duval_$_.png=" + (Hsh "11_Results\figures\duval_$_.png") }) -join "; "
Put (NewRow @{ id = "DF14"; category = "Derived file"; name = "Figure 4.4 - Duval Triangle 1 by data role (4 figures)"
  reference = "Made in Step 17 by plot_duval_by_role.m (PNG 300 dpi, vector PDF and the plotted points as CSV for each role)."
  accessed = $acc; how_obtained = "Program output"; licence_terms = "Project file"
  local_file = "11_Results/figures/duval_<role>.png, .pdf, .csv"; sha256 = (Hsh "11_Results\figures\duval_development.png")
  records = "825 plotted points of 827"; project_role = "Figure 4.4 of the thesis"; used_in_steps = "17"
  notes = "SHA-256 of the PNG files: $figNote" })

$lines = $reg | ConvertTo-Csv -NoTypeInformation
[IO.File]::WriteAllLines($regFile, $lines, $utf8)
"register rows: " + $reg.Count

# --- glossary --------------------------------------------------------------------------------------------------
$glo = [System.Collections.ArrayList]@(Import-Csv $gloFile -Encoding UTF8)
$gcols = $glo[0].PSObject.Properties.Name
function G($grp, $term, $meaning, $plain, $pattern) { $o = [ordered]@{}; foreach ($c in $gcols) { $o[$c] = "" }; $o.group = $grp; $o.term = $term; $o.meaning = $meaning; $o.plain_explanation = $plain; $o.pattern = $pattern; [pscustomobject]$o }
foreach ($g in $glo) { if ($g.term -like "D1-D1[0-9]*") { $g.term = "D1-D14 (decisions)"; $g.pattern = '[Dd]ecision D|\bD[3-9]\b|\bD1[0-4]\b' } }
$new = @(
  (G "Methods" "ND (no diagnosis)" "No diagnosis" "The answer of a method when no rule applies or a ratio it needs cannot be calculated. It is a result and is never deleted." '\bND\b|no diagnosis'),
  (G "Methods" "Dual answer (D1/D2)" "Two classes returned together" "Sometimes the IEC table fits two fault types at once. The method then answers with both (D1/D2); it counts as correct if the true class is either one." 'D1/D2|PD/T1|[Dd]ual'),
  (G "Methods" "Boundary distance" "Distance to the nearest decision boundary" "How far a sample is from the line where the diagnosis would change. A small distance means a small measurement error could change the diagnosis." '[Bb]oundary distance|[Dd]ecision edge'),
  (G "Methods" "Decade (log10 unit)" "A factor of 10" "A distance of 1 decade on the ratio scale means the ratio is 10 times larger or smaller, e.g. from 0.1 to 1." '[Dd]ecades?\b'),
  (G "Methods" "Rogers case" "Rogers diagnosis code 0 to 5" "The Rogers table gives each combination of ratios a case number: 0 normal, 1 partial discharge, 2 arcing, 3 and 4 thermal below 700 degrees, 5 thermal above 700 degrees." '[Rr]ogers case|Case [0-5]'),
  (G "Methods" "Raw and final result" "Result before and after the normality gate" "raw_result is what the method itself says; result is what is left after samples with low gas levels have been called Normal by the gate." 'raw_result|[Rr]aw result|\bfinal result'),
  (G "Methods" "Polygon clipping (Sutherland-Hodgman)" "Cutting a shape with straight lines" "A standard way to find the area of the triangle that satisfies one limit after another; used to draw the Duval zones from their limits." 'Sutherland|[Cc]lipping|[Pp]olygon'),
  (G "Software" "Unit test (matlab.unittest)" "Automatic test of one small piece of code" "A test that feeds a function a known input and checks the answer, so that any later change that breaks the function is noticed at once." '[Uu]nit test|matlab\.unittest|runtests'),
  (G "Software" "IEEE 754" "Floating-point arithmetic standard" "The rule that decides how computers round decimal numbers; it makes a division that is exactly equal to a limit give exactly the limit." 'IEEE 754|correctly rounded')
)
for ($i = $glo.Count - 1; $i -ge 0; $i--) { if ($glo[$i].term -like "Dual answer*") { $glo.RemoveAt($i) } }
foreach ($n in $new) { for ($i = $glo.Count - 1; $i -ge 0; $i--) { if ($glo[$i].term -eq $n.term) { $glo.RemoveAt($i) } }; [void]$glo.Add($n) }
[IO.File]::WriteAllLines($gloFile, ($glo | ConvertTo-Csv -NoTypeInformation), $utf8)
"glossary rows: " + $glo.Count
