# report_entries_14_17.ps1 - "Method used" and closing-section content for the reports of roadmap Steps 14-17.
# Dot-source AFTER helpers.ps1, report_closings.ps1 and report_methods.ps1; it adds entries "14".."17" to
# $global:Methods, $global:Closings and $global:StepSources (same structure as the entries of Steps 1-13).
# Every number below was checked against the saved outputs of 11 October 2026 (see the build script for the
# tables, which are read from the output files and not typed).

$global:Methods["14"] = @{
  Approach = @(
    "Table-driven programming: the MATLAB code contains no decision limit. A loader (load_standards) reads the limits from the frozen CSV files in 02_Standards, and the diagnosis functions only interpret those tables. Changing a limit therefore means changing a CSV file and creating a new data version, never editing code.",
    "Three methods, two engines. The IEC 60599 ratio method and the Rogers ratio method use one ratio-table engine: a class matches when every ratio the table uses for that class is defined and lies inside its interval; no match gives ND (no diagnosis); several matches are returned together (only D1/D2 occurs). Duval Triangle 1 applies its 10 rules in order and the first match wins.",
    "Normality gate: a sample is called Normal when every gas is at or below the upper end of its IEC 60599 typical-value range (the lower end is kept as a sensitivity). The same gate is used for all three methods; the method's own answer is kept separately as the raw result.",
    "Distance to the nearest decision boundary: for the ratio methods, in decades of the ratio (Analysis Plan Eq. 9); for the Duval Triangle, in percentage points to the nearest edge that separates two different zones (Eq. 10 with decision D12). The Duval zones are first turned into polygons (polygon clipping), and the edges between different zones are found by looking a tiny distance to each side of every polygon edge.",
    "Audit: a program lists every numeric literal left in the decision code (comments and text removed) and fails if any is not on a short list of bookkeeping numbers.")
  Why = @(
    "Reading limits from the standards tables keeps one source of truth, so the MATLAB and the later Python implementation (Step 18) can be compared on the same limits, and every limit can be traced to a clause and page.",
    "One shared engine for the IEC and Rogers tables means both methods obey exactly the same rules for strict and inclusive limits and for undefined ratios, which is required for a fair comparison.",
    "Keeping the raw result next to the gated result lets the thesis report the conventional methods with and without the normality gate, and lets the unit tests check the methods against published examples that were never gated.",
    "A decision-boundary distance that ignores the triangle sides and the seams inside one zone measures what the boundary hypothesis (RQ2) is about: how close a sample is to a line where the diagnosis would change.",
    "An automatic audit is more reliable than reading the code by eye: it makes the rule 'no limit typed in code' testable.")
  Settings = @(
    @("Data version", "1.0, checked at the start of every program (16 files, SHA-256)"),
    @("Gas columns", "H2, CH4, C2H6, C2H4, C2H2 in ppm; not detected = 0 ppm (decision D8)"),
    @("Ratios", "R1 = CH4/H2, R2 = C2H2/C2H4, R5 = C2H4/C2H6; a zero denominator makes the ratio undefined (NaN)"),
    @("Interval rules (D11)", "< and > strict; printed ranges 'a - b' include both end points; 'NS' (not significant) entries are not used"),
    @("Undefined ratio (D12)", "ND only when a ratio the class uses is undefined; an undefined NS ratio does not stop a class from matching"),
    @("Several IEC classes match", "joined with '/': only D1/D2 occurs (D11); PD/T1 was removed by D13"),
    @("T1 condition (D13)", "the printed 'CH4/H2 > 1 but NS' is used as R1 > 1 (strict), so PD (R1 < 0.1) and T1 never overlap"),
    @("Rogers cases to classes (D11)", "0 Normal, 1 PD, 2 D2, 3 T1, 4 T2, 5 T3 (Rogers has no D1 case)"),
    @("Duval rules (D11)", "applied in rule_order, first match wins; lower limit inclusive (>=), upper limit exclusive (<); DT is a valid zone"),
    @("Normality gate (D11)", "upper end of IEC Table A.2 (primary), lower end (sensitivity); C2H2 uses the communicating-OLTC range only for equipment code U"),
    @("Boundary distance (Eq. 9, Eq. 10, D12)", "ratio methods: decades, a ratio of 0 gives Inf; Duval: percentage points in a triangle of side 100, decision edges only"),
    @("Numerical constants in code", "100 (percentages add up to 100) and 1e-6 percentage points (probe offset); both in conv_config.m"))
  Eqs = @(
    @{ Eq = "R_1=CH_4/H_2"; Where = @(
        @("R_1", "first ratio (dimensionless)"), @("CH_4", "methane concentration [ppm]"), @("H_2", "hydrogen concentration [ppm]"),
        @("", "R2 = C2H2/C2H4 and R5 = C2H4/C2H6 are calculated in the same way (acetylene/ethylene and ethylene/ethane). A zero denominator makes the ratio undefined.")) }
    @{ Eq = "p_X=100⋅X/(CH_4+C_2 H_4+C_2 H_2 )"; Where = @(
        @("p_X", "percentage of gas X in the three-gas total [%]"), @("X", "concentration of one of the gases CH4, C2H4 or C2H2 [ppm]"),
        @("", "The three percentages add up to 100 and fix one point in Duval Triangle 1 (Analysis Plan Eq. 4).")) }
    @{ Eq = "x=p_(C_2 H_4 )+p_(CH_4 )/2"; Where = @(
        @("x", "horizontal position of the sample in the triangle [percentage points]"),
        @("p_(C_2 H_4 ), p_(CH_4 )", "percentages of ethylene and methane [%]"),
        @("", "The vertical position is y = (√3/2)·p(CH4). In this plane the side of the triangle is 100 units long, so one unit is one percentage point along a side.")) }
    @{ Eq = "d_R=min_(j,l) |log_10 R_j-log_10 L_(j,l) |"; Where = @(
        @("d_R", "distance of the sample to the nearest ratio limit [decades]"), @("j", "index of the ratio (R1, R2 or R5)"),
        @("l", "index of a limit of ratio j in the code table"), @("R_j", "value of ratio j for the sample (dimensionless)"),
        @("L_(j,l)", "limit l of ratio j read from 02_Standards (dimensionless)")) }
    @{ Eq = "d_D=min_(e∈E) dist(P,e)"; Where = @(
        @("d_D", "distance of the sample to the nearest decision edge [percentage points]"),
        @("P", "the sample point in the plane of the triangle"),
        @("E", "the set of edges that separate two different zones (decision D12)"),
        @("dist(P,e)", "shortest distance from P to the segment e [percentage points]")) })
  Tools = @("MATLAB R2025b (25.2.0.2998904), base MATLAB only. Program files in 04_MATLAB_Conventional: conv_config, verify_data_version, load_standards, gas_ratios, duval_xy, bound_test, diagnose_ratio_method, diagnose_duval, normality_gate, boundary_distance_ratio, duval_zone_polygons, duval_decision_edges, boundary_distance_duval, conventional_diagnosis, run_conventional_batch, check_no_typed_limits, impact_of_rules.",
    "Code Analyzer (checkcode) run on every file; SHA-256 through java.security.MessageDigest; readtable with explicit column types.")
  Refs = @("ST1", "ST2", "ST5", "P3", "P4", "M8", "M9")
}

$global:Methods["15"] = @{
  Approach = @(
    "Unit testing with the MATLAB testing framework (matlab.unittest): each test gives a function a known input and checks the answer. The tests are written as one class, and one command runs all of them and writes a log.",
    "Reference examples: every row of worked_examples.csv is one test - 39 Duval Triangle 1 examples printed in two open-access papers and 1 Rogers example printed in IEEE Std C57.104-2008 (Figure 2). The method's own answer, before the normality gate, must equal the printed diagnosis.",
    "Boundary construction: for the boundary tests the gas values are chosen so that a ratio or a percentage is exactly equal to a limit (for example CH4/H2 = 0.1), and the answer is compared with the rule of decision D11.",
    "Structure tests: the Duval polygons must cover the triangle exactly once; no two Rogers cases may match the same sample; the only IEC overlap allowed is D1/D2; both are checked on dense grids that include every printed limit.")
  Why = @(
    "Reproducing published, independently calculated examples shows that the implementation does what the sources say, which is the accepted way to validate a re-implementation of a standard.",
    "Boundary cases are where implementations differ (strict or inclusive limits); testing them exactly makes the choice explicit and permanent.",
    "A test log that records the MATLAB version and every test is evidence that can be shown to supervisors and examiners, and the tests catch accidental changes in later steps.")
  Settings = @(
    @("Test class", "04_MATLAB_Conventional/tests/TestConventionalMethods.m"),
    @("Number of tests", "67 (41 worked-example tests, 6 zero-denominator, 7 boundary, 3 gate, 10 structure)"),
    @("What is compared for the examples", "raw method result (before the normality gate) against the printed diagnosis"),
    @("Blank gas in an example", "0 ppm (decision D8: not detected)"),
    @("Rogers example tolerance", "ratios compared with the printed 0.29, 0.70 and 4.25 within 0.005"),
    @("Command", "run_tests_and_log (calls runtests; writes tests/test_log.txt; raises an error if any test fails)"))
  Tools = @("MATLAB R2025b matlab.unittest (runtests, TestCase, parameterised tests, verifyEqual, verifyTrue, verifyError)", "04_MATLAB_Conventional/tests/run_tests_and_log.m")
  Refs = @("P2", "P3", "ST5", "M9")
}

$global:Methods["16"] = @{
  Approach = @(
    "Batch application: after the data-version check, the three methods are applied to every record of the master table in one vectorised call, and the result is written as one row per record and method.",
    "Both answers are kept: raw_result is the method's own answer and result is the answer after the upper normality gate. ND, DT and dual answers are results and stay in the file; nothing is removed or filled in.",
    "Counting: the numbers of ND, DT, D1/D2 (and PD/T1, now always 0) results are counted per method and data role, after and before the gate.",
    "Plausibility check: the raw answers are compared with the inspection-confirmed class of the IEC TC 10 benchmark, on the five merged classes. This only shows that the implementations behave sensibly; the formal evaluation comes later.",
    "Read-back: the output file is read again in a different program (Python) to check its size, record order and columns.")
  Why = @(
    "A single, versioned prediction file is the input of every later comparison (agreement with Python, with machine learning, McNemar tests, boundary-distance regression), so it must contain everything those analyses need.",
    "Keeping ND and dual answers makes the unresolved share of each method visible instead of hiding it; reviewers of DGA studies ask for this.",
    "A plausibility check against known classes catches gross mistakes (for example a swapped ratio) before they spread into later steps; it is deliberately not reported as a result.")
  Settings = @(
    @("Records", "827 (all data roles of data version 1.0)"),
    @("Rows written", "827 x 3 methods = 2481, in record order: IEC60599, Rogers, Duval"),
    @("Gate columns", "gate_upper and gate_lower: 'Normal' or blank"),
    @("Boundary distance column", "decades (IEC, Rogers) or percentage points (Duval); Inf if every defined ratio is 0; NaN if undefined"),
    @("Plausibility scoring (not a result)", "classes PD, D1, D2, T12, T3; T1 and T2 count as T12; a dual answer is correct if either part is correct; DT and ND count as wrong; raw answers"),
    @("Output folder", "11_Results/conventional"))
  Tools = @("04_MATLAB_Conventional/run_conventional_batch.m, sanity_check_vs_truth.m, impact_of_rules.m", "Python 3.12.10 with pandas (read-back check, python -I)")
  Refs = @()
}

$global:Methods["17"] = @{
  Approach = @(
    "Drawing from the rules: the 10 Duval rules are converted into polygons, filled with a light tint of the class colour, and the lines between different zones are drawn on top. The zone names, the 20 % grid and the three scales are added.",
    "Plotting the data: each record is placed in the triangle by its three percentages (equation below) and drawn with the colour and marker of its TRUE class, both read from plot_style.csv. One figure is made for each data role, with a PNG (300 dpi), a vector PDF and a CSV of the plotted points.",
    "Visual check: every PNG was opened and looked at; problems found were fixed and the figures made again.")
  Why = @(
    "The Duval Triangle is a picture-based method; showing where the true classes of each data set fall explains where the method can and cannot work, before any number is calculated.",
    "Colours and markers come from one shared file (plot_style.csv, written in Step 11) so that Python and MATLAB figures look the same across the thesis.",
    "Saving the plotted points as CSV lets a reader redraw or check the figure without MATLAB.")
  Settings = @(
    @("Figure", "Figure 4.4 (one panel per data role)"),
    @("Data roles", "development, internal_test, benchmark, external_test"),
    @("Class of each point", "class_name; where it is empty (32 inspected T1/T2 cases) class_merged = T12 is used"),
    @("Position", "percentages from the raw gas values, WITHOUT the normality gate"),
    @("Resolution and formats", "PNG 300 dpi, vector PDF, CSV"),
    @("Style file", "11_Results/figures/plot_style.csv"))
  Eqs = @(
    @{ Eq = "y=(√3/2)⋅p_(CH_4 )"; Where = @(
        @("y", "vertical position of the sample in the triangle [percentage points]"),
        @("p_(CH_4 )", "percentage of methane [%]"),
        @("", "The horizontal position is x = p(C2H4) + p(CH4)/2. The triangle has its 100 % C2H2 corner at (0, 0), its 100 % C2H4 corner at (100, 0) and its 100 % CH4 corner at the top.")) })
  Tools = @("04_MATLAB_Conventional/plot_duval_triangle.m and plot_duval_by_role.m (MATLAB R2025b, exportgraphics)")
  Refs = @("P3", "P4", "M8")
}

$global:Closings["14"] = @{
  Achieved = @(
    "The three conventional methods now read every limit from the frozen standards tables; the audit found 0 typed limits in the decision code.",
    "Running the written rules on the real data exposed three gaps; they were reported to the researcher and settled as decision D12 before any result was produced. A fourth point found in Step 16 (IEC could never answer PD alone) was settled as decision D13 and Steps 14 to 17 were run again.",
    "Boundary distances (Analysis Plan Eq. 9 and Eq. 10) are implemented and tested.",
    "A batch function reads the master table after verifying the SHA-256 fingerprints of all 16 frozen files.")
  Record = @(
    @("Step", "14 - Complete the conventional-method functions"), @("Environment", "MATLAB, run from Claude Code through the MATLAB MCP connection (toolkit Steps 2-3 not yet checked)"),
    @("Completed", "11 October 2026"), @("Status", "Done"),
    @("Main inputs", "02_Standards CSV files, 03_Data/processed/dga_master.csv (data version 1.0), decision D11, Analysis Plan Section 4.5"),
    @("Main outputs", "20 MATLAB files in 04_MATLAB_Conventional; impact_of_rules.csv and gate_by_class.csv in 11_Results/conventional"),
    @("Checks", "no typed limits (audit PASS); Code Analyzer reviewed; data version verified; polygons cover the triangle exactly"), @("Decisions", "D12 - three amendments found while implementing D11; D13 - T1 requires CH4/H2 > 1; D14 - MATLAB steps through the MCP connection (all closed by the researcher)"))
  Helps = @(
    "Step 15 tests these functions against the 40 published worked examples and the D11/D12 boundary rules.",
    "Step 16 runs run_conventional_batch on all 827 records.",
    "Step 17 draws the Duval Triangle from duval_zone_polygons and duval_decision_edges.",
    "Step 18 re-implements the methods in Python from the same tables and compares the two outputs record by record.")
  Open = @(
    "The IEC and Rogers tables and the Duval limits are still TO VERIFY against primary sources (IEC 60599:2022, a licensed IEEE C57.104).",
    "Decision D13 uses the printed 'CH4/H2 > 1 but NS' of T1 as a condition. This departs slightly from the printed table (which marks the entry NS) and raises IEC ND from 204 to 319 of 827 records (raw). It should be justified in the thesis.",
    "The normality gate is the researcher's approved design; IEC 60599 Annex A says typical values are not fault limits. 160 of the 242 gated records are true faults (see the findings).",
    "Steps 2 and 3 (toolkit set-up) were not done; the MATLAB MCP connection of Claude Code was used instead. The researcher accepted this for MATLAB (decision D14); the Simulink toolkit set-up is still to be decided before Stage G.",
    "Code Analyzer messages that were reviewed and left: the unused compatibility argument zoneFile in plot_duval_triangle, an axes call inside a loop in plot_duval_by_role, and notes in the test files about variable names that equal property names.")
  Exclude = @()
}

$global:Closings["15"] = @{
  Achieved = @(
    "67 automatic tests were written; all 67 pass on the final code (log saved).",
    "All 39 Duval Triangle 1 worked examples and the Rogers example from IEEE C57.104-2008 are reproduced exactly.",
    "The boundary rules of decision D11 and the amendments of D12 and D13 are fixed by tests.",
    "One failing test was traced to a wrong expected value written by the author, not to the code; the expected value was corrected after a hand calculation.")
  Record = @(
    @("Step", "15 - Unit-test the conventional methods"), @("Environment", "MATLAB, run from Claude Code through the MATLAB MCP connection"),
    @("Completed", "11 October 2026"), @("Status", "Done - 67 of 67 tests pass"),
    @("Main inputs", "04_MATLAB_Conventional functions; 02_Standards/worked_examples.csv"),
    @("Main outputs", "tests/TestConventionalMethods.m, tests/run_tests_and_log.m, tests/test_log.txt, tests/README.md"),
    @("Checks", "runtests 67 passed, 0 failed, 0 incomplete"), @("Decisions", "none new"))
  Helps = @(
    "Step 16 can now run the three methods on all records with confidence that they reproduce published diagnoses.",
    "Any later change to a function or to a standards table is checked by running run_tests_and_log again.",
    "Step 18 compares the Python re-implementation with the same 40 examples and with the MATLAB output.")
  Open = @(
    "The worked examples come from papers (secondary sources) and one standard. Reproducing them shows the implementation matches those sources; it does not prove that the limits themselves are correct (TO VERIFY items remain).",
    "There is only one Rogers example; the other Rogers cases are checked by boundary tests and the no-overlap test, not by published examples.",
    "The Duval limits were first checked in Step 12 with Python (39 of 39); this step repeats the check in MATLAB. The two are not yet independent of each other because they use the same CSV file.")
  Exclude = @()
}

$global:Closings["16"] = @{
  Achieved = @(
    "conventional_predictions.csv holds 2481 rows: every one of the 827 records for each of the three methods; ND, DT and dual answers are kept.",
    "Counts of ND, DT, D1/D2 and PD/T1 (0 since D13) per method and data role are saved (conventional_counts.csv).",
    "A plausibility check against the IEC TC 10 benchmark shows the three methods behave sensibly (it is not a result).",
    "The file was read back in Python and its size, record order and columns were confirmed.")
  Record = @(
    @("Step", "16 - Run the three methods on every record"), @("Environment", "MATLAB, run from Claude Code through the MATLAB MCP connection"),
    @("Completed", "11 October 2026"), @("Status", "Done"),
    @("Main inputs", "dga_master.csv (827 records, data version 1.0); 02_Standards tables"),
    @("Main outputs", "11_Results/conventional: conventional_predictions.csv, conventional_counts.csv, impact_of_rules.csv, gate_by_class.csv, sanity_agreement_benchmark.csv, README.md"),
    @("Checks", "2481 rows; 827 unique records in master order; result consistent with gate in every row; Python read-back OK"), @("Decisions", "none new"))
  Helps = @(
    "Step 17 draws the Duval Triangles.",
    "Step 18 re-implements the methods in Python and checks that MATLAB and Python agree on 100 % of the 2481 rows.",
    "Steps 19 to 24 and the statistics stage compare machine learning with these predictions; the boundary_distance column is the input of the boundary-distance regression (RQ2).")
  Open = @(
    "These counts are descriptive. Nothing here says which method is better; the evaluation measures and tests fixed in the Analysis Plan are applied in later steps.",
    "Under the upper gate, 242 of 827 records are called Normal, including 160 true faults; the gate result therefore limits what any conventional method can achieve on low-gas faults. Sensitivity with the lower gate is in the same file (91 records).",
    "IEC ND is high (319 raw, 200 after the gate) because T1 now needs CH4/H2 > 1 (D13) and many records have CH4/H2 of 1 or less or undefined; Rogers returns ND for many records because every Rogers case needs all three ratios.",
    "The plausibility check uses a simple scoring (dual answers counted correct, DT and ND wrong, raw answers); the formal scoring may differ.")
  Exclude = @()
}

$global:Closings["17"] = @{
  Achieved = @(
    "Figure 4.4 was made for each of the four data roles from the script (PNG 300 dpi, vector PDF, plotted points as CSV).",
    "The zone lines are computed from the 10 rules in duval_triangle_zones.csv, not drawn by hand.",
    "Problems found by looking at the first figures (light title text, invisible markers for the merged T1/T2 class, hidden labels of the thin zones) were fixed and the figures remade.")
  Record = @(
    @("Step", "17 - Plot the Duval Triangles"), @("Environment", "MATLAB, run from Claude Code through the MATLAB MCP connection"),
    @("Completed", "11 October 2026"), @("Status", "Done"),
    @("Main inputs", "dga_master.csv; duval_triangle_zones.csv; plot_style.csv"),
    @("Main outputs", "11_Results/figures: duval_development, duval_internal_test, duval_benchmark, duval_external_test (.png, .pdf, .csv)"),
    @("Checks", "figures made by script; zone polygons cover the triangle (area 5000 = 100 x 100 / 2); 825 of 827 records plotted, 2 have no position"), @("Decisions", "none new"))
  Helps = @(
    "Step 18 (Claude Code) re-implements the three methods in Python and checks agreement with the MATLAB predictions.",
    "The figures are Figure 4.4 of Chapter 4; the CSV of plotted points lets the Python figures in later steps use identical positions.")
  Open = @(
    "The figures show where the true classes lie; they are descriptive and do not by themselves measure accuracy.",
    "Two development records have CH4 + C2H4 + C2H2 = 0 ppm and therefore no position in the triangle; they are listed as not plotted.",
    "Duval zone limits are TO VERIFY against a primary source (see Step 12).",
    "Many thermal records lie along the C2H2 = 0 side of the triangle, so their markers overlap; the CSV lists every point.")
  Exclude = @()
}

$global:StepSources["14"] = @("ST1", "ST2", "ST5", "P3", "P4", "DF2", "DF5", "DF6", "DF8", "DF11", "SW2")
$global:StepSources["15"] = @("ST5", "P2", "P3", "DF5", "DF8", "DF13", "SW2")
$global:StepSources["16"] = @("DF2", "DF5", "DF6", "DF9", "DF10", "DF11", "DF12", "SW1", "SW2")
$global:StepSources["17"] = @("DF2", "DF4", "DF5", "DF14", "SW2")
