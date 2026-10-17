# report_entries_18.ps1 - "Method used" and closing-section entries for roadmap Step 18 (report standard 2026-10-10/11).
# Dot-source after helpers.ps1, report_closings.ps1 and report_methods.ps1. Adds to $global:Methods, $global:Closings and
# $global:StepSources (same structure as the entries of Steps 1-17).

$global:Methods["18"] = @{
  Approach = @(
    "Independent re-implementation (also called N-version or differential testing): the three conventional methods were programmed a second time, in Python, directly from the specification - the frozen 02_Standards tables and decisions D11, D12 and D13 - and not by translating the MATLAB code. Both programs were then run on the same 827 records and every output was compared, record by record and method by method.",
    "For the Duval boundary distance a deliberately different geometric method was used. MATLAB cuts the zone edges into pieces and keeps the pieces with different zones on each side; Python builds every zone rule as a polygon by half-plane clipping (Sutherland and Hodgman) and measures the distance from the sample point to the nearest polygon of a different zone. Both definitions give the same distance in theory, so agreement checks the geometry two ways.")
  Why = @(
    "A second, independent program is the strongest practical test that the conventional methods are coded correctly: a coding error would have to be made in exactly the same way in two languages to go unnoticed.",
    "The conventional methods are the baseline against which the machine-learning models will be judged; an error in the baseline would bias every comparison in the thesis.",
    "The roadmap (Step 18) requires identical diagnoses on 100 % of records and numbers equal within 1e-9.")
  Settings = @(
    @("Records and methods", "827 records x 3 methods (IEC 60599, Rogers, Duval Triangle 1) = 2 481 rows"),
    @("Compared outputs", "gate_upper, gate_lower, raw_result, result (exact text); ratios R1, R2, R5; Duval percentages; boundary distance"),
    @("Number tolerance", "|a - b| <= 1e-9 x max(1, |a|, |b|); NaN must meet NaN and Inf must meet Inf of the same sign"),
    @("Rules", "decisions D11 (gate, ranges, dual answers, Rogers mapping), D12 (ND only for used ratios; Duval distance to decision edges), D13 (IEC T1 needs CH4/H2 > 1)"),
    @("Data", "data version 1.0, verified by its SHA-256 manifest before the run"))
  Eqs = @(
    @{ Eq = "|a-b|≤10^(-9)⋅max(1,|a|,|b|)"; Where = @(
        @("a, b", "the same number computed by Python and by MATLAB (ratio, percentage or boundary distance)"),
        @("", "Two values that are both NaN (undefined) or both infinite with the same sign also count as equal.")) },
    @{ Eq = 'd_D=min_(r∈Z(P)^c) "dist"(P,Π_r)'; Where = @(
        @("d_D", "Duval boundary distance of sample P [percentage points, triangle of side 100]"),
        @("Z(P)^c", "the rules of Duval Triangle 1 whose zone differs from the zone of P"),
        @("Π_r", "the polygon of rule r, built by clipping the triangle with the rule's limits"),
        @('"dist"(P,Π_r)', "Euclidean distance from P to the polygon (0 if P lies inside or on its edge)")) })
  Tools = @("06_Python_ML/src/conventional/conventional_methods.py (independent implementation) and step18_crosscheck.py (comparison)",
            "Python 3.12.10 with numpy 2.5.3 and pandas 3.0.6; 06_Python_ML/tests/test_conventional_python.py (pytest 9.1.1, 45 tests)")
  Refs = @("M8", "M9")
}

$global:Closings["18"] = @{
  Achieved = @(
    "An independent Python implementation of IEC 60599, Rogers and Duval Triangle 1 now exists, written from the standards tables and decisions, not from the MATLAB code.",
    "MATLAB and Python agree on all 2 481 record-method rows: every diagnosis, both normality-gate flags, every ratio, every Duval percentage and every boundary distance (largest difference 3.4e-13).",
    "The Duval boundary distance was confirmed by two different geometric methods.",
    "45 new automated tests (published worked examples, decision edge cases, MATLAB-Python agreement); the whole suite passes 56 of 56.")
  Record = @(
    @("Step", "18 - Cross-check MATLAB against Python"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "11 October 2026"), @("Status", "Done"),
    @("Main inputs", "11_Results/conventional/conventional_predictions.csv (MATLAB); 02_Standards tables; dga_master.csv (data version 1.0)"),
    @("Main outputs", "08_Statistical_Analysis/cross_language_check.csv; 11_Results/conventional/conventional_predictions_python.csv; conventional_methods.py; step18_report.md"),
    @("Checks", "2 481 of 2 481 rows identical within 1e-9 - PASS; pytest 56 of 56 PASS"), @("Decisions", "None new (implements D11, D12, D13)"))
  Helps = @(
    "The conventional-method results can now be trusted as the baseline for Steps 28-32 (McNemar and Cochran tests, Cohen's kappa, and the boundary-distance logistic regression all use these predictions and distances).",
    "The Python implementation will be reused by the diagnosis service (Step 38), so the service gives exactly the same conventional answers as MATLAB.",
    "Step 19 builds the machine-learning preprocessing and feature pipelines on the same frozen data.")
  Open = @(
    "Agreement proves that both programs apply the same rules; it does not prove that the rules are the right reading of the standards. The standards values still marked TO VERIFY (Duval Triangle 1 from secondary sources, Rogers from a copy not licensed to the researcher, IEC against the 2022 text) remain open.",
    "The approved normality gate (D11) calls 242 of the 827 records Normal, and 160 of them are true faults (from gate_by_class.csv of Step 16). This will lower the conventional methods' scores and must be discussed in the thesis; the lower-end gate is the planned sensitivity analysis.")
  Exclude = @()
}

$global:StepSources["18"] = @("DF2", "DF5", "DF6", "DF9", "DF15", "DF16", "DF17", "SW1", "SW2")
