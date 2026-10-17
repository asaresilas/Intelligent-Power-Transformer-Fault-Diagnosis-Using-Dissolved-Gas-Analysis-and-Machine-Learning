param([string[]]$Steps = @("14", "15", "16", "17"))   # e.g. -Steps 15,16 builds only those reports
$Steps = @($Steps | ForEach-Object { $_ -split "[, ]+" } | Where-Object { $_ })   # powershell -File passes "15,16" as one string
$ErrorActionPreference = "Stop"
# build_step_reports_14_17.ps1 - Word reports of roadmap Steps 14, 15, 16 and 17 (report standard of 2026-10-10/11).
# Tables are read from the saved output files, so no result number is typed by hand.
# Word quirk: $doc.SaveAs2 must be called at script level (not inside a function).
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$figDir = Join-Path $root "11_Results\figures"
$resDir = Join-Path $root "11_Results\conventional"
$prog = Join-Path $work "report14_17_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
. (Join-Path $sp "report_entries_14_17.ps1")

# These are first versions of the Step 14-17 reports, so the header says version 1 (the shared helper says version 2,
# which is right only for the rewritten reports of Steps 1-13).
function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed = "11 October 2026") {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 1 (" + $completed + ")")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}

# ---- saved outputs used by the tables ---------------------------------------------------------------------------
$impact  = Import-Csv (Join-Path $resDir "impact_of_rules.csv")
$gate    = Import-Csv (Join-Path $resDir "gate_by_class.csv")
$counts  = Import-Csv (Join-Path $resDir "conventional_counts.csv")
$pred    = Import-Csv (Join-Path $resDir "conventional_predictions.csv")
$sanity  = Import-Csv (Join-Path $resDir "sanity_agreement_benchmark.csv")
$examples = Import-Csv (Join-Path $root "02_Standards\worked_examples.csv")
$testLog = [IO.File]::ReadAllText((Join-Path $root "04_MATLAB_Conventional\tests\test_log.txt"))
$summaryLine = ([regex]::Match($testLog, "SUMMARY:[^\r\n]*")).Value
function IV([string]$k) { [string](($impact | Where-Object { $_.item -eq $k }).value) }
function Rows([object]$t, [string[]]$cols) { $r = @(); foreach ($x in $t) { $r += , @($cols | ForEach-Object { [string]$x.$_ }) }; return , $r }
$roles = "development", "internal_test", "benchmark", "external_test"
$roleName = @{ development = "Development"; internal_test = "Internal test"; benchmark = "IEC TC 10 benchmark"; external_test = "External test (Li 2019)" }

# =====================================================================================================================
# STEP 14
# =====================================================================================================================
$b14 = {
ReportHeader "14" "Complete the conventional-method functions" "MATLAB (run from Claude Code through the MATLAB MCP connection)" "11 October 2026"
$global:sec = 0
Summary ("The IEC 60599 ratio method, the Rogers ratio method and Duval Triangle 1 are now complete MATLAB functions. Every decision limit is read from the frozen tables in 02_Standards; an automatic audit found no limit typed in the code. Before the code was trusted, the written rules were run on all " + (IV "n_records") + " records. They exposed three gaps - " + (IV "n_any_undefined_ratio") + " records have a zero denominator, " + (IV "iec_PD_T1_overlap_if_T1_ignores_R1") + " records would match both PD and T1, and the Duval boundary distance was ambiguous - which the researcher settled as decision D12 before any result was produced. A further point found in Step 16 (IEC could then never answer PD alone) was settled as decision D13 (T1 requires CH4/H2 > 1), and Steps 14 to 17 were run again. The normality gate and the boundary distances of the Analysis Plan (Equations 9 and 10) are implemented.")
H1N "Purpose of this step"
Body "The conventional methods are the yardstick against which machine learning is judged. This step turns the three methods into reliable, annotated functions that give one answer for one sample or for thousands, that never contain a hand-typed limit, and that also measure how close each sample lies to a line where the diagnosis would change (needed to test the boundary hypothesis, research question RQ2)."
MethodSection "14"
H1N "What was used"
AddTable @("Input", "Content and source", "Status") @(
  , @("02_Standards/iec_ratio_table.csv", "IEC 60599:1999+A1:2007 (Ed. 2.1) Table 2, page 11: 18 rows (6 classes x 3 ratios); the 'simplified scheme' rows (Table 3) are not used. [ST1]", "PRIMARY preview; TO VERIFY against the 2022 text")
  , @("02_Standards/iec_typical_values.csv", "IEC 60599 AMD1:2007 Table A.2: typical values of the five gases (normality gate). [ST2]", "PRIMARY preview; TO VERIFY for 2015/2022")
  , @("02_Standards/rogers_ratio_table.csv", "IEEE Std C57.104-2008 Table 6: Rogers cases 0 to 5 (18 rows). [ST5]", "TO VERIFY against a licensed copy")
  , @("02_Standards/duval_triangle_zones.csv", "Duval Triangle 1: 10 rules (Moser 2025; Manisha et al. 2022). [P4, P3]", "SECONDARY; TO VERIFY")
  , @("03_Data/processed/dga_master.csv", "827 records, five gases in ppm, data version 1.0. [DF2]", "frozen")
  , @("03_Data/data_version_1.0.sha256", "Fingerprints of the 16 frozen files, checked at the start of every program. [DF6]", "frozen")
  , @("Decision D11 and Analysis Plan Section 4.5", "Implementation rules and the definition of the boundary distance (Equations 9 and 10).", "approved 11 Oct 2026")
) @(130, 230, 90)
H1N "Reading the instructions critically before coding"
Body "The toolkit instructions were not followed blindly. Before any code was written, the rules of decision D11 were tried on the real data with a short scratch program, and the existing code stubs and the CSV tables were compared. Eight points were found; four needed the researcher's decision and were put to the researcher with a recommendation each (the fourth, on PD and T1, after Step 16)."
AddTable @("Finding", "Evidence", "Action") @(
  , @("1. A zero denominator gave ND even when the ratio is not needed", ((IV "n_any_undefined_ratio") + " of " + (IV "n_records") + " records have a zero denominator. Example: the first IEC TC 10 record (a partial discharge) has C2H4 = 0 and C2H2 = 0, so R2 = 0/0, although the IEC table marks R2 as not significant for PD and T1. D11 as written gave ND for " + (IV "iec_nd_rule_D11_strict_before_D13") + " records; ND only when a needed ratio is undefined gives " + (IV "iec_nd_rule_D12_before_D13") + " (figures at the time of decision D12)."), ("Researcher chose: ND only when a ratio that the class uses is undefined (" + (IV "iec_recovered_by_D12_before_D13") + " records diagnosed instead of ND at that time). Decision D12 (1)."))
  , @("2. PD and T1 can match together", ((IV "iec_PD_T1_overlap_if_T1_ignores_R1") + " records satisfy both PD and T1 when T1 ignores CH4/H2 (printed NS). D11 only covers D1/D2 (" + (IV "iec_match_D1_and_D2") + " records)."), "Researcher first chose the dual answer PD/T1 (D12 (2)); replaced by D13 after Step 16 (finding 4).")
  , @("3. Equation 10 read literally counts non-decision lines", "'The nearest zone edge' would include the three sides of the triangle and seams between rules of the same zone (for example the two D2 rules). Crossing them never changes the diagnosis.", "Researcher chose: only edges that separate two different zones, distance in percentage points. Decision D12 (3).")
  , @("4. Consequence of finding 2", ("If T1 ignores CH4/H2, PD (R1 < 0.1 and R5 < 0.2) always satisfies T1 (R5 < 1), so IEC could never answer PD alone, only PD/T1. Found in Step 16."), "Researcher chose: the printed 'CH4/H2 > 1' of T1 is used as a condition (decision D13). PD and T1 no longer overlap; PD alone now occurs for " + (IV "iec_match_PD_alone") + " records (raw).")
  , @("5. The old code stubs do not fit the real tables", "gas_ratios, conventional_diagnosis and plot_duval_triangle expected a 'wide' ratio table and polygon vertices; the real CSV files are 'long' ratio tables with bound types and a rule table. The README listed other file names.", "Rewritten; the old function names and the dashboard calls (d.rogers, d.iec, d.duval, plot_duval_triangle) were kept.")
  , @("6. Published examples were never gated", "Worked examples MAN-22 and MAN-23 print T1, but all their gases are below the normality gate.", "The Step 15 tests compare the raw method result, before the gate.")
  , @("7. Toolkit set-up not finished", "The instructions say Steps 2 and 3 (toolkit set-up) must be finished first. They are not.", "The MATLAB MCP connection of Claude Code was used. Accepted by the researcher (decision D14).")
  , @("8. Side effect of decision D13", ("Using the printed '> 1' as a condition for T1 raises IEC ND from " + (IV "iec_nd_rule_D12_before_D13") + " to " + (IV "iec_nd_rule_D12") + " records (T1 records with CH4/H2 of 1 or less, or undefined, no longer match)."), "Reported to the researcher; to be justified in the thesis.")
) @(120, 210, 120)
H1N "What was done, step by step"
NumItem "1" "Read the instructions, the Analysis Plan (Section 4.5), decision D11, the five standards tables and the old code. Tried the D11 rules on all 827 records (see the findings above) and put the three open questions to the researcher; the answers became decision D12. After Step 16 two further questions (PD and T1; the toolkit set-up) were put and answered as decisions D13 and D14, and Steps 14 to 17 were run again."
NumItem "2" "Wrote conv_config.m (paths, names, the Rogers case mapping, two numerical constants) and verify_data_version.m (SHA-256 of the 16 frozen files with java.security.MessageDigest)."
NumItem "3" "Wrote load_standards.m, which reads the IEC Table 2 rows (18), the Rogers rows (18), the 10 Duval rules and the 8 typical-value rows, with every column read as text or as a number explicitly."
NumItem "4" "Wrote gas_ratios.m (R1, R2, R5 and the Duval percentages; zero denominator gives NaN), duval_xy.m, bound_test.m (the D11 interval rules), diagnose_ratio_method.m (IEC and Rogers engine), diagnose_duval.m (10 rules, first match wins) and normality_gate.m."
NumItem "5" ("Wrote the Duval geometry: duval_zone_polygons.m turns every rule into a polygon; duval_decision_edges.m keeps the edge pieces with a different zone on each side; boundary_distance_duval.m measures the distance. Checked: the ten polygons have a total area of " + (IV "duval_polygon_area_sum") + " (the triangle has 5000), there are " + (IV "duval_decision_edge_pieces") + " decision-edge pieces, and a point at 19.9 % C2H4 lies 0.1 x (sqrt 3)/2 = 0.0866 percentage points from the T1/T2 edge.")
NumItem "6" "Wrote boundary_distance_ratio.m (Equation 9; a ratio of 0 gives Inf, an undefined ratio does not count)."
NumItem "7" "Wrote conventional_diagnosis.m (one call for one or many samples) and run_conventional_batch.m (data-version check, master table, three methods, output files)."
NumItem "8" "Wrote check_no_typed_limits.m and ran it; wrote impact_of_rules.m so that the numbers behind decision D12 are saved files; ran the Code Analyzer on every file."
NumItem "9" "Added a help text (purpose, inputs, outputs, rules, sources) to every file, and rewrote the README of 04_MATLAB_Conventional."
H1N "The rules as implemented"
AddTable @("Rule", "Source", "Where in the code") @(
  , @("Limits are read from 02_Standards, never typed", "Toolkit instructions, rule 1", "load_standards.m; audit in check_no_typed_limits.m")
  , @("< and > strict; printed ranges include both end points; NS entries not used", "D11 rule 3", "bound_test.m; the 'ignored' flag in load_standards.m")
  , @("A class matches only if every ratio it uses is defined and inside its interval; otherwise ND", "D11 rule 7 as amended by D12 (1)", "diagnose_ratio_method.m")
  , @("Several IEC classes match: answer with all of them (only D1/D2 occurs)", "D11 rule 4", "diagnose_ratio_method.m")
  , @("T1 needs CH4/H2 > 1 (the printed '> 1 but NS' is used as a condition)", "D13", "load_standards.m; bound_test.m")
  , @("Rogers cases 0 to 5 are Normal, PD, D2, T1, T2, T3", "D11 rule 5", "conv_config.m; load_standards.m")
  , @("Duval rules in rule_order; lower limit inclusive, upper exclusive; DT valid", "D11 (Duval rule)", "diagnose_duval.m")
  , @("Normality gate: upper end primary, lower end sensitivity; same gate for all methods; C2H2 range by equipment code U", "D11 rules 1, 2, 6", "normality_gate.m; conventional_diagnosis.m")
  , @("Ratio boundary distance in decades; Duval distance in percentage points to edges between different zones", "Analysis Plan Eq. 9; Eq. 10 with D12 (3)", "boundary_distance_ratio.m; duval_decision_edges.m; boundary_distance_duval.m")
) @(190, 120, 140)
H1N "What we found"
H2 "Effect of decisions D12 and D13 (saved in impact_of_rules.csv)"
AddTable @("Item", "Records") @(
  , @("Records in the master table", (IV "n_records"))
  , @("Records with at least one zero denominator (R1, R2 or R5)", (IV "n_any_undefined_ratio"))
  , @("At the time of D12 (T1 still ignoring CH4/H2): IEC ND if any undefined ratio gives ND (D11 as first written)", (IV "iec_nd_rule_D11_strict_before_D13"))
  , @("At the time of D12: IEC ND if only a ratio the class uses is undefined", (IV "iec_nd_rule_D12_before_D13"))
  , @("At the time of D12: records diagnosed under D12 but ND under D11 as first written", (IV "iec_recovered_by_D12_before_D13"))
  , @("Records that would match both PD and T1 if T1 ignored CH4/H2", (IV "iec_PD_T1_overlap_if_T1_ignores_R1"))
  , @("Final rules (D12 and D13): IEC ND, any undefined ratio gives ND", (IV "iec_nd_rule_D11_strict"))
  , @("Final rules: IEC ND, only a used ratio undefined (raw, before the gate)", (IV "iec_nd_rule_D12"))
  , @("Final rules: records matching both D1 and D2 (dual answer D1/D2)", (IV "iec_match_D1_and_D2"))
  , @("Final rules: records matching both PD and T1", (IV "iec_match_PD_and_T1"))
  , @("Final rules: IEC result PD alone (raw)", (IV "iec_match_PD_alone"))
  , @("Rogers ND before the gate (unchanged by D12 and D13: every Rogers case uses all three ratios)", (IV "rogers_nd"))
) @(380, 70)
H2 "What the normality gate does (saved in gate_by_class.csv)"
$gr = @()
foreach ($rl in $roles) {
  $g = $gate | Where-Object { $_.data_role -eq $rl }
  $n = ($g | Measure-Object n -Sum).Sum
  $gu = ($g | Measure-Object n_gate_upper -Sum).Sum
  $gl = ($g | Measure-Object n_gate_lower -Sum).Sum
  $gn = (($g | Where-Object { $_.true_class -eq "Normal" }) | Measure-Object n_gate_upper -Sum).Sum
  if ($null -eq $gn) { $gn = 0 }
  $gr += , @($roleName[$rl], [string]$n, [string]$gu, [string]($gu - $gn), [string]$gl)
}
$tn = ($gate | Measure-Object n -Sum).Sum; $tu = ($gate | Measure-Object n_gate_upper -Sum).Sum; $tl = ($gate | Measure-Object n_gate_lower -Sum).Sum
$tnn = (($gate | Where-Object { $_.true_class -eq "Normal" }) | Measure-Object n_gate_upper -Sum).Sum
$gr += , @("All records", [string]$tn, [string]$tu, [string]($tu - $tnn), [string]$tl)
AddTable @("Data role", "Records", "Called Normal by the upper gate", "of which true faults", "Called Normal by the lower gate") $gr @(120, 55, 95, 90, 90)
Body ("The gate is the researcher's approved design (decision D11). It matters: " + ($tu - $tnn) + " of the " + $tu + " records that the upper gate calls Normal are true faults with low gas levels. For those records the three conventional methods are bound to be wrong, whatever their ratios. The lower gate (sensitivity) calls " + $tl + " records Normal. IEC 60599 Annex A states that the typical values are 90 % observation ranges and not fault limits; this is recorded as a limitation.")
H2 "Geometry of Duval Triangle 1"
Body ("The ten rules give ten convex polygons with a total area of " + (IV "duval_polygon_area_sum") + " in (%C2H4, %C2H2) coordinates, which equals the area of the triangle (100 x 100 / 2): the rules leave no gap and do not overlap. " + (IV "duval_decision_edge_pieces") + " edge pieces separate two different zones; the triangle sides and the seams between rules of the same zone are not counted.")
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("No decision limit typed in the code (check_no_typed_limits, 17 files audited)", "0 disallowed numeric literals - PASS")
  , @("Data version 1.0 verified at the start of the batch run (16 files)", "0 differences - PASS")
  , @("Duval polygons cover the triangle exactly once", ((IV "duval_polygon_area_sum") + " of 5000 - PASS"))
  , @("Hand checks of the Duval boundary distance (points 60 %, 19.9 % and 20 % C2H4 at 1 % C2H2)", "8.66, 0.0866 and 0 percentage points, as calculated by hand - PASS")
  , @("All 827 records processed in one call", "about 1.3 s - PASS")
  , @("Code Analyzer on every file", "no warning in the decision code; three informational notes reviewed (see Open items)")
) @(300, 150)
H1N "Problems and fixes"
Bullet "The first run of the audit reported 27 numeric literals. They were the column numbers of the five gases (4 and 5), the 0.5 of the triangle geometry and cosmetic numbers (axis ranges, font sizes, colours) of the two plotting files. The audit was refined, not the code: the numbers 0 to 5 are allowed as indices, 0.5 only in duval_xy.m, 100 and 1e-6 only in conv_config.m, and plotting files are not audited because they take no part in any decision. The decision code now passes with 0 literals."
Bullet "The first version of the CSV reader failed because a text option was set on numeric columns; the options are now set per column type. MATLAB also warns that the first Rogers column is called 'case', a MATLAB keyword; the column is read by position and the warning is switched off for that read only."
Bullet "The existing stubs could not read the real tables (finding 5). They were replaced, keeping the names used by the dashboard."
Bullet "After Step 16 showed that IEC could never answer PD alone, decision D13 changed the T1 rule. The code (load_standards, bound_test), the tests, the evidence file impact_of_rules.csv (which now keeps the figures of the D12 stage next to the final ones) and every output of Steps 14 to 17 were updated and run again; the figures of this report are from the final run."
H1N "Decisions"
Bullet "Decision D12 (researcher, 11 October 2026): (1) ND only when a ratio that the class uses is undefined; (2) dual answer PD/T1 treated like D1/D2 (later replaced by D13); (3) Duval boundary distance = distance to the nearest edge that separates two different zones, in percentage points."
Bullet "Decision D13 (researcher, 11 October 2026, after Step 16): the printed 'CH4/H2 > 1 but NS' of T1 is used as the condition CH4/H2 > 1 (strict). PD and T1 no longer overlap and IEC can answer PD alone. This departs slightly from the printed table; IEC ND rises from 204 to 319 records (raw)."
Bullet "Decision D14 (researcher, 11 October 2026): the MATLAB steps may be run through the MATLAB MCP connection; Steps 2-3 are recorded as replaced for MATLAB."
H1N "Files produced"
Bullet "04_MATLAB_Conventional: conv_config.m, verify_data_version.m, load_standards.m, gas_ratios.m, duval_xy.m, bound_test.m, diagnose_ratio_method.m, diagnose_duval.m, normality_gate.m, boundary_distance_ratio.m, duval_zone_polygons.m, duval_decision_edges.m, boundary_distance_duval.m, conventional_diagnosis.m, run_conventional_batch.m, check_no_typed_limits.m, impact_of_rules.m, README.md, code_manifest.sha256 (fingerprints of the 22 code files)."
Bullet "11_Results/conventional: impact_of_rules.csv, gate_by_class.csv, no_typed_limits_audit.csv."
Bullet "00_Project_Admin/decisions_log.md (D12, D13, D14); data and source register (SW2, M8, M9, DF8, DF11); abbreviations glossary."
Closing "14" 0 "Step 15 [MATLAB] - unit-test the conventional methods with the 40 published worked examples, the zero-denominator rules, the boundary rules of D11 to D13 and the normality gate, and save the test log." ($b14.ToString())
}

# =====================================================================================================================
# STEP 15
# =====================================================================================================================
$b15 = {
ReportHeader "15" "Unit-test the conventional methods" "MATLAB (run from Claude Code through the MATLAB MCP connection)" "11 October 2026"
$global:sec = 0
Summary ("A test class with 67 automatic tests was written and run. All 67 pass. They reproduce all 39 Duval Triangle 1 worked examples and the Rogers worked example of IEEE Std C57.104-2008, and they fix in code the rules of decisions D11 to D13 for zero denominators, for samples exactly on a limit and for the normality gate. The log of the run is saved. One test failed on the way because the author had written a wrong expected value; the code was right.")
H1N "Purpose of this step"
Body "A method that has not been tested against known answers cannot be trusted in a thesis. This step shows that the MATLAB functions of Step 14 give the published answers, that the rules agreed with the researcher are applied exactly, and that the code stays correct when it is changed later."
MethodSection "15"
H1N "What was used"
AddTable @("Input", "Content") @(
  , @("04_MATLAB_Conventional functions", "The functions written in Step 14 (data version 1.0 standards tables).")
  , @("02_Standards/worked_examples.csv", "40 worked examples: 3 from Aciu et al. 2021 and 36 from Manisha et al. 2022 (all 39 for Duval Triangle 1), and 1 Rogers example from IEEE Std C57.104-2008 Figure 2. Blank gas = 0 ppm. [P2, P3, ST5]")
  , @("Decisions D11 to D13", "The boundary, zero-denominator and T1 rules the tests must enforce.")
) @(150, 300)
H1N "What was done, step by step"
NumItem "1" "Wrote TestConventionalMethods.m as a matlab.unittest class. The 40 worked examples are loaded from worked_examples.csv and each becomes one test (a parameterised test), so adding an example to the CSV adds a test."
NumItem "2" "Wrote the zero-denominator tests (undefined ratio, zero numerator, Rogers and IEC with a needed ratio undefined, the D12 case of an undefined NS ratio, Duval with all three gases at 0 ppm)."
NumItem "3" "Built boundary samples whose ratio or percentage equals a limit exactly, and wrote the expected answer from the rule of D11/D12 for each (table below)."
NumItem "4" "Wrote the gate tests: upper end, lower end, the tap-changer rule for C2H2, one common gate for the three methods. The limits used to build the samples are read from iec_typical_values.csv, not typed."
NumItem "5" "Wrote the structure tests: polygons cover the triangle once; every grid point has a Duval zone; no two Rogers cases overlap (dense logarithmic grid that includes every printed limit and values just above and below); the only IEC overlap is D1/D2; boundary-distance values; data version; batch size; no typed limits."
NumItem "6" "Wrote run_tests_and_log.m, which runs the class with runtests and writes tests/test_log.txt (date, MATLAB version, full output, one line per test) and stops with an error if any test fails."
NumItem "7" "Ran the tests, found and settled the problems described below, and ran them again until all passed."
H1N "What the tests check"
AddTable @("Group", "Tests", "What is checked") @(
  , @("(a) Worked examples", "41", "40 tests, one per row of worked_examples.csv (39 Duval Triangle 1, 1 Rogers), plus a test that the file really has 39 + 1 rows. The raw method result is compared with the printed diagnosis.")
  , @("(b) Zero denominators", "6", "Undefined ratio is NaN; zero numerator is a valid 0; Rogers and IEC give ND when a needed ratio is undefined; an undefined NS ratio still lets PD match (D12); Duval gives ND when CH4 = C2H4 = C2H2 = 0.")
  , @("(c) Samples on a limit", "7", "Strict < and > ; printed ranges include both end points; Duval lower limit inclusive, upper exclusive; T1 needs CH4/H2 > 1 (D13); the interval function itself.")
  , @("(d) Normality gate", "3", "Upper end, lower end, C2H2 range by equipment code U, one gate for all methods.")
  , @("(e) Structure", "10", "Polygon coverage; every point has a zone; Rogers cases never overlap; the only IEC overlap is D1/D2; ratio and Duval boundary distances; triangle sides and seams not counted; data version; batch size; no typed limits.")
) @(100, 40, 310)
H1N "What we found"
H2 "Result of the run"
Body ("The saved log (tests/test_log.txt) ends with: " + $summaryLine + ".")
H2 "The worked examples"
$g = $examples | Group-Object method, diagnosis_printed | Sort-Object Name
$er = @(); foreach ($x in $g) { $p = $x.Name -split ", "; $er += , @($p[0], $p[1], [string]$x.Count) }
AddTable @("Method", "Printed diagnosis", "Number of examples (all reproduced)") $er @(130, 200, 120)
Body "All 39 Duval Triangle 1 examples and the Rogers example give exactly the printed diagnosis. For the Rogers example the ratios R2 = 5/17, R1 = 190/270 and R5 = 17/4 also agree with the printed 0.29, 0.70 and 4.25 and the case is Case 2 (mapped to D2)."
H2 "Boundary samples tested (decisions D11 to D13)"
AddTable @("Sample (gases in ppm)", "What it tests", "Expected and obtained") @(
  , @("H2 100, CH4 10, C2H6 100, C2H4 1, C2H2 0 (R1 = 0.1)", "PD needs R1 < 0.1 (strict); T1 needs R1 > 1 (D13)", "IEC: ND")
  , @("H2 10000, CH4 999, C2H6 100, C2H4 1, C2H2 0 (R1 = 0.0999)", "just below the limit", "IEC: PD only")
  , @("H2 10, CH4 20, C2H6 10, C2H4 5, C2H2 0 (R1 = 2, R5 = 0.5); and the same with CH4 10 (R1 = 1)", "T1 needs CH4/H2 > 1 (strict), decision D13", "IEC: T1; with R1 = 1: ND")
  , @("H2 10, CH4 5, C2H6 2, C2H4 10, C2H2 20 (R1 = 0.5)", "printed range 0.1 - 0.5 includes 0.5", "IEC: D1/D2")
  , @("H2 100, CH4 10, same other gases (R1 = 0.1)", "printed range includes 0.1", "IEC: D1/D2")
  , @("H2 100, CH4 9.99, same other gases (R1 = 0.0999)", "just below 0.1", "IEC: ND")
  , @("H2 10, CH4 20, C2H6 10, C2H4 40, C2H2 0 (R5 = 4)", "T2 range 1 - 4 includes 4; T3 needs R5 > 4", "IEC: T2 only")
  , @("same with C2H4 41 (R5 = 4.1)", "just above 4", "IEC: T3")
  , @("H2 10, CH4 10, C2H6 5, C2H4 10, C2H2 0.5 (R1 = 1, R2 = 0.05, R5 = 2)", "Rogers: cases 0 and 3 need R1 < 1, cases 4 and 5 need R1 > 1", "Rogers: ND")
  , @("H2 10, CH4 10, C2H6 5, C2H4 20, C2H2 10 (R1 = 1, R2 = 0.5, R5 = 4)", "Case 2 prints R1 as 0.1 to 1.0 (included)", "Rogers: Case 2 = D2")
  , @("CH4 79, C2H4 20, C2H2 1 (%C2H4 = 20)", "Duval lower limit included", "Duval: T2")
  , @("CH4 79.5, C2H4 19.5, C2H2 1 (%C2H4 = 19.5)", "just below 20", "Duval: T1")
  , @("CH4 49, C2H4 50, C2H2 1 (%C2H4 = 50)", "T2 needs < 50 (upper excluded)", "Duval: T3")
  , @("CH4 98, C2H4 1, C2H2 1 (%CH4 = 98)", "PD needs >= 98", "Duval: PD")
  , @("CH4 76, C2H4 20, C2H2 4 (%C2H2 = 4)", "T zones need %C2H2 < 4", "Duval: DT")
) @(210, 130, 110)
Body "Each of these samples is built so that the ratio or percentage is exactly equal to the limit. Because a division in IEEE 754 arithmetic is correctly rounded, a quotient that is exactly equal to a printed limit (for example 3/30 and 0.1) gives exactly the number of the limit, so the strict and inclusive rules decide the boundary case as intended [M9]."
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("runtests on TestConventionalMethods", ($summaryLine.Replace("SUMMARY: ", "")))
  , @("All 40 worked examples reproduced", "40 of 40 - PASS")
  , @("Polygon area equals the triangle area", "5000 of 5000 - PASS")
  , @("Test log saved with date and MATLAB version", "04_MATLAB_Conventional/tests/test_log.txt")
) @(280, 170)
H1N "Problems and fixes"
Bullet "The first run could not create the test suite: the parameters of the worked-example tests are built before the class setup puts the code folder on the path. The parameter function now adds the folder to the path itself."
Bullet "One test failed: the distance from the point (35 %, 0 %) to the nearest Duval decision edge. The author had expected 15 x (sqrt 3)/2, forgetting the T2/DT limit at %C2H2 = 4. A hand calculation gives 4 x (sqrt 3)/2 = 3.464, which is what the code returned. The expected value in the test was wrong, not the code, and was corrected."
Bullet "After the sanity-check program of Step 16 was added, the 'no typed limits' test failed once because that program contained the number 7 (the number of columns of a table). The program was changed to count its columns; the audit was not loosened. The log in the project is from the final run: 67 of 67 pass."
Bullet "Decision D13 (T1 requires CH4/H2 > 1) changed the expected answers of three tests (PD/T1 became PD or ND), turned the overlap test into a test of the single overlap D1/D2, and added one test for the T1 rule (66 tests became 67). The log in the project is from the run after these changes."
H1N "Decisions"
Bullet "None new. The tests enforce decisions D11, D12 and D13."
H1N "Files produced"
Bullet "04_MATLAB_Conventional/tests: TestConventionalMethods.m, run_tests_and_log.m, test_log.txt, README.md."
Closing "15" 0 "Step 16 [MATLAB] - run the three methods on all 827 records and write conventional_predictions.csv with one row per record and method; report the number of ND, DT and dual results per method and data role." ($b15.ToString())
}

# =====================================================================================================================
# STEP 16
# =====================================================================================================================
$b16 = {
ReportHeader "16" "Run the three methods on every record" "MATLAB (run from Claude Code through the MATLAB MCP connection)" "11 October 2026"
$global:sec = 0
$all = $counts | Where-Object { $_.data_role -eq "all" }
$cI = $all | Where-Object { $_.method -eq "IEC60599" }; $cR = $all | Where-Object { $_.method -eq "Rogers" }; $cD = $all | Where-Object { $_.method -eq "Duval" }
Summary ("The three methods were applied to all 827 records of data version 1.0; the file conventional_predictions.csv has 2481 rows (one per record and method) and keeps every ND, DT and dual answer. After the upper normality gate, " + $cI.n_gate_upper + " records are called Normal. The remaining results contain ND for " + $cI.ND_final + " records (IEC), " + $cR.ND_final + " (Rogers) and " + $cD.ND_final + " (Duval). These counts are descriptive; nothing is concluded yet about which method is better.")
H1N "Purpose of this step"
Body "This step produces the conventional answers that every later comparison needs: agreement with the Python re-implementation (Step 18), comparison with machine learning, the tests of disagreement, and the boundary-distance analysis. It also reports how often each method gives no diagnosis, a Duval DT or a dual IEC answer."
MethodSection "16"
H1N "What was used"
AddTable @("Input", "Content") @(
  , @("03_Data/processed/dga_master.csv", "827 records: development 439, internal test 70, IEC TC 10 benchmark 117, external test 201. [DF2]")
  , @("04_MATLAB_Conventional", "The functions of Step 14, tested in Step 15 (code fingerprints in code_manifest.sha256). [DF8]")
  , @("02_Standards", "The frozen limit tables. [DF5]")
) @(150, 300)
H1N "What was done, step by step"
NumItem "1" "Ran run_conventional_batch, which first verified the SHA-256 fingerprints of all 16 frozen files (0 differences), read the master table and called conventional_diagnosis on all records at once (about 1.3 s)."
NumItem "2" "Built the output with one row per record and method, in record order (IEC60599, Rogers, Duval), with the gate columns, raw_result, result, the ratios or Duval percentages, the boundary distance and the data version."
NumItem "3" "Counted the results per method and data role, before and after the gate, and saved the counts."
NumItem "4" "Read the file again in Python (pandas) to confirm 2481 rows, 827 unique records in master-table order, the columns, and that the result equals Normal exactly where the upper gate is passed and equals raw_result elsewhere."
NumItem "5" "Ran the plausibility check against the IEC TC 10 benchmark (see below) and the impact check of Step 14, and wrote the README of 11_Results/conventional."
H1N "What we found"
H2 "Results of the three methods on all 827 records (after the upper normality gate)"
$vals = "Normal", "PD", "D1", "D2", "T1", "T2", "T3", "D1/D2", "PD/T1", "DT", "ND"
$tr = @()
foreach ($v in $vals) {
  $row = @($v)
  foreach ($m in "IEC60599", "Rogers", "Duval") { $row += [string](@($pred | Where-Object { $_.method -eq $m -and $_.result -eq $v }).Count) }
  $tr += , $row
}
$tr += , @("Total", "827", "827", "827")
AddTable @("Result", "IEC 60599 ratio", "Rogers ratio", "Duval Triangle 1") $tr @(130, 110, 110, 100)
Body "Reading the table: a zero means that the method never gives that answer. Rogers has no D1 case (a limitation of the table); the PD/T1 row is 0 since decision D13; DT is a Duval zone only. IEC ND is high (T1 now needs CH4/H2 > 1)."
H2 "ND, DT and dual answers per method and data role"
# NB: PowerShell variable names are not case-sensitive, so this array must not be called $cr ($cR holds the Rogers counts).
$cntRows = @()
foreach ($m in "IEC60599", "Rogers", "Duval") { foreach ($rl in (@("all") + $roles)) {
  $cc = $counts | Where-Object { $_.method -eq $m -and $_.data_role -eq $rl }
  $cntRows += , @($m, $rl, $cc.n, $cc.n_gate_upper, $cc.ND_final, $cc.DT_final, $cc.D1D2_final, $cc.PDT1_final, $cc.ND_raw)
} }
AddTable @("Method", "Data role", "n", "Normal by gate", "ND", "DT", "D1/D2", "PD/T1", "ND before gate") $cntRows @(65, 80, 30, 50, 35, 30, 40, 40, 50)
Body "ND, DT and the dual answers are counted after the upper gate (a gated record is Normal, so it is not counted); the last column gives ND before the gate. The complete table, including the same counts before the gate, is in conventional_counts.csv."
H2 "What the gate does to the true faults"
$tu = ($gate | Measure-Object n_gate_upper -Sum).Sum; $tl = ($gate | Measure-Object n_gate_lower -Sum).Sum
$tnn = (($gate | Where-Object { $_.true_class -eq "Normal" }) | Measure-Object n_gate_upper -Sum).Sum
Body ("The upper gate calls " + $tu + " records Normal; " + ($tu - $tnn) + " of them are true faults (gate_by_class.csv). The lower gate calls " + $tl + " records Normal. Because the same gate is used for all three methods, these records are counted as Normal for every method; the raw_result column keeps what each method alone would have said.")
H2 "Plausibility check against the IEC TC 10 benchmark (not a result)"
$sr = @(); foreach ($x in $sanity) { $sr += , @($x.method, $x.n_scored, $x.n_correct, ("{0:P1}" -f [double]$x.share_correct), $x.n_ND, $x.n_DT, $x.n_dual) }
AddTable @("Method", "Records", "Correct", "Share", "ND", "DT", "Dual answers") $sr @(80, 55, 55, 55, 50, 45, 70)
Body "This check uses the raw answers (before the gate) on the 117 inspection-confirmed benchmark records with the classes merged to PD, D1, D2, T12 and T3; a dual answer counts as correct if either part is right, and DT and ND count as wrong. It only shows that the three implementations behave sensibly: the Duval triangle is clearly the most accurate on this data set, the IEC ratio method is intermediate with many dual and ND answers, and the Rogers method leaves many records without diagnosis. The formal evaluation (macro-F1, confidence intervals, the primary 58-record subset, the gate, the scoring of dual answers) is done in later steps and may give different figures. Nothing here should be quoted as a result."
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("Rows in conventional_predictions.csv", "2481 = 827 x 3 - PASS")
  , @("Unique records and order", "827; same order as dga_master.csv - PASS")
  , @("ND rows kept", ("yes: IEC " + $cI.ND_final + ", Rogers " + $cR.ND_final + ", Duval " + $cD.ND_final + " - PASS"))
  , @("result equals Normal where the upper gate is passed, raw_result elsewhere", "all 2481 rows - PASS (checked in Python)")
  , @("Data version 1.0 verified before the run", "16 files, 0 differences - PASS")
  , @("Audit of typed limits after adding the new programs", "0 disallowed literals - PASS")
) @(300, 150)
H1N "Problems and fixes"
Bullet "The first version of the plausibility program contained the number 7 for the number of table columns; the audit test flagged it (see Step 15). The program was changed, and all programs and figures were run again, so that every saved file comes from the final code."
Bullet "Undefined ratios and distances are stored as NaN and infinite distances as Inf (the file has 14 Inf and 4 NaN boundary distances); Python reads both correctly."
H1N "Decisions"
Bullet "None new. Decisions D8, D11, D12 and D13 were applied."
H1N "Files produced"
Bullet "11_Results/conventional: conventional_predictions.csv, conventional_counts.csv, sanity_agreement_benchmark.csv, impact_of_rules.csv, gate_by_class.csv, README.md."
Bullet "04_MATLAB_Conventional: run_conventional_batch.m, sanity_check_vs_truth.m."
Closing "16" 0 "Step 17 [MATLAB] - draw Duval Triangle 1 for each data role, coloured by true class (Figure 4.4)." ($b16.ToString())
}

# =====================================================================================================================
# STEP 17
# =====================================================================================================================
$b17 = {
ReportHeader "17" "Plot the Duval Triangles" "MATLAB (run from Claude Code through the MATLAB MCP connection)" "11 October 2026"
$global:sec = 0
Summary "Duval Triangle 1 was drawn for each of the four data roles, with the zones taken from the ten rules of duval_triangle_zones.csv and every record placed by its gas percentages and coloured and shaped by its true class (Figure 4.4). Each figure is saved as a 300 dpi PNG, a vector PDF and a CSV of the plotted points. 825 of the 827 records have a position in the triangle; two development records have no CH4, C2H4 or C2H2 and are listed as not plotted."
H1N "Purpose of this step"
Body "The Duval Triangle is a picture-based method. Before any accuracy is calculated, these figures show where the true classes of each data set fall in the triangle and how close they lie to the zone lines. They are also the Figure 4.4 of Chapter 4."
MethodSection "17"
H1N "What was used"
AddTable @("Input", "Content") @(
  , @("03_Data/processed/dga_master.csv", "827 records and their true class (data version 1.0). [DF2]")
  , @("02_Standards/duval_triangle_zones.csv", "The 10 rules that define the zones. [DF5]")
  , @("11_Results/figures/plot_style.csv", "Colour and marker of each class. [DF4]")
) @(170, 280)
H1N "What was done, step by step"
NumItem "1" "Rewrote plot_duval_triangle.m: it now builds the zones from the rules (duval_zone_polygons), draws the decision edges (duval_decision_edges), the 20 % grid, the scales and the zone names, and plots points by class. The old call used by the dashboard still works."
NumItem "2" "Wrote plot_duval_by_role.m: for each data role it selects the records, takes the true class (class_name, or T12 for the inspected T1/T2 cases), draws the figure, and saves PNG (300 dpi), PDF (vector) and the CSV of plotted points."
NumItem "3" "Looked at every PNG. Three faults were found in the first version and fixed (see Problems and fixes); the figures were made again."
H1N "What we found"
Body "How to read a figure: each corner is a pure gas (100 % CH4 at the top, 100 % C2H2 at the bottom left, 100 % C2H4 at the bottom right). A point near a corner is dominated by that gas. The coloured areas are the zones PD, T1, T2, T3, D1, D2 and DT; the grey lines are the lines where the diagnosis changes. The colour and shape of a marker is the TRUE class, so a marker lying in a zone of another colour is a case the Duval Triangle would get wrong."
$figNo = 0
foreach ($rl in $roles) {
  $figNo++
  $csv = Import-Csv (Join-Path $figDir ("duval_" + $rl + ".csv"))
  H2 ("Figure 4.4" + [char](96 + $figNo) + " - " + $roleName[$rl])
  Caption ("Figure 4.4" + [char](96 + $figNo) + " - Duval Triangle 1: " + $roleName[$rl] + " (" + $csv.Count + " records plotted), coloured by true class")
  Pic (Join-Path $figDir ("duval_" + $rl + ".png")) 400
  $cls = $csv | Group-Object true_class | Sort-Object Name
  $rows = @(); foreach ($c in $cls) { $rows += , @($c.Name, [string]$c.Count) }
  AddTable @("True class", "Records plotted") $rows @(150, 120)
}
H2 "Records without a position"
$mm = Import-Csv (Join-Path $root "03_Data\processed\dga_master.csv")
$dev = $mm | Where-Object { $_.data_role -eq "development" }
$nop = $dev | Where-Object { ([double]$_.CH4 + [double]$_.C2H4 + [double]$_.C2H2) -eq 0 }
Body ("Two development records, " + (($nop | ForEach-Object { $_.record_id }) -join " and ") + ", have CH4, C2H4 and C2H2 all equal to 0 ppm; their percentages are undefined and the Duval method gives ND. They are not plotted. All other records of all roles are plotted (development 437 of 439; internal test 70 of 70; benchmark 117 of 117; external test 201 of 201).")
H1N "Checks"
AddTable @("Check", "Result") @(
  , @("Figures made by script from the CSV rules and the master table", "plot_duval_by_role.m - PASS")
  , @("Zone lines match the 10 rules", "polygons cover the triangle: area 5000 of 5000 (test in Step 15) - PASS")
  , @("Files saved for each role", "PNG 300 dpi, PDF, CSV (12 files) - PASS")
  , @("Plotted points", "825 of 827 (2 undefined) - PASS")
  , @("Every PNG looked at", "yes; three faults found and fixed")
) @(280, 170)
H1N "Problems and fixes"
Bullet "Title and legend text was almost invisible: the MATLAB desktop uses a dark theme and the invisible figure inherited light text. The figure is now set to the light theme and the title and legend use the text colour of plot_style.csv."
Bullet "The markers of the merged T1/T2 class (an 'x') were invisible, because line markers cannot be filled and had a white edge. They are now drawn in the class colour."
Bullet "The names of the thin zones PD, T1 and T2 were hidden under the points that lie along the right side. They are now written outside the triangle with a short leader line."
H1N "Decisions"
Bullet "None new."
H1N "Files produced"
Bullet "11_Results/figures: duval_development, duval_internal_test, duval_benchmark, duval_external_test, each as .png (300 dpi), .pdf (vector) and .csv (plotted points)."
Bullet "04_MATLAB_Conventional: plot_duval_triangle.m, plot_duval_by_role.m."
Closing "17" 0 "Step 18 [Claude Code] - re-implement the three methods in Python from the same tables and check that MATLAB and Python agree on 100 % of the 2481 prediction rows." ($b17.ToString())
}

# =====================================================================================================================
# build the four documents
# =====================================================================================================================
# Remove empty paragraphs at the end of the document. Bounded: Word cannot delete an empty paragraph that follows a table,
# and an unbounded loop there never ends (this happened on the first run).
function Trim-End {
  for ($k = 0; $k -lt 5; $k++) {
    if ($doc.Paragraphs.Count -le 1 -or $doc.Paragraphs.Last.Range.Text.Trim() -ne "") { break }
    $before = $doc.Paragraphs.Count
    $rr = $doc.Content; $rr.SetRange($rr.End - 2, $rr.End - 1)
    if ($rr.Text -ne [string][char]13) { break }
    $rr.Delete() | Out-Null
    if ($doc.Paragraphs.Count -eq $before) { break }
  }
}
$blocks = @{ "14" = $b14; "15" = $b15; "16" = $b16; "17" = $b17 }
foreach ($n in $Steps) {
  try {
    $doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
    & $blocks[$n]
    ("content built " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
    Trim-End
    ("trimmed " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
    $tmp = Join-Path $work ("out_Step_" + $n + "_Report.docx")
    # SaveAs2 called directly spins the PowerShell COM binder on this machine (seen 11 Oct 2026); InvokeMember does not.
    [void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
    ("saved to temp " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
    $pg = $doc.ComputeStatistics(2)
    $doc.Close($false)
    Copy-Item $tmp (Join-Path $outDir ("Step_" + $n + "_Report.docx")) -Force
    ("SAVED Step_" + $n + "_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
  } catch {
    ("ERROR step " + $n + ": " + $_.Exception.Message + " at line " + $_.InvocationInfo.ScriptLineNumber) | Out-File $prog -Append -Encoding utf8
    try { $doc.Close($false) } catch {}
  }
}
$word.Quit()
"done " + (Get-Date -Format T) | Out-File $prog -Append -Encoding utf8
