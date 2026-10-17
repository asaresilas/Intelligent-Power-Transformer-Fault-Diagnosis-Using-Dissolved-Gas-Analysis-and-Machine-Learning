# report_entries_26.ps1 - "Method used" and closing entries for roadmap Step 26 (report standard 2026-10-10/11).
# Result numbers are NOT typed here: the builder fills $global:S26 from the result files before dot-sourcing.

$s = $global:S26
$global:Methods["26"] = @{
  Approach = @(
    "For each of the 31 combinations of the five gases the program pretends that only those gases were measured: the other gases are replaced by NaN, a marker that means 'not measured'. It is not the same as 0 ppm, which means 'measured and not found'.",
    "A conventional method that needs a gas that is not measured gives no diagnosis (ND) for every sample, before any ratio, zone or normality test is looked at. The IEC 60599 and Rogers methods use the ratios CH4/H2, C2H2/C2H4 and C2H4/C2H6, so they need all five gases; Duval Triangle 1 needs CH4, C2H4 and C2H2. A method that has all its gases is run exactly as in Steps 14-17.",
    "The number and share of ND answers is counted for every combination and method over all 827 records and for each data role. A second program, written independently in Python (Step 18 implementation), recomputes the whole table.")
  Why = @(
    "Many online monitors measure only some of the gases. This step shows, without guessing, for which of them a conventional method can give any diagnosis at all - the baseline against which the reduced-gas machine-learning models of Step 25 are judged.",
    "Returning ND instead of a diagnosis calculated from incomplete data is the safe choice: a ratio with a missing gas has no meaning, and a guessed value would make the conventional methods look better or worse than they are.",
    "NaN is used for a missing gas because it spreads through every calculation (a ratio or percentage that uses it is also NaN) and cannot be mistaken for a real measurement of 0 ppm (decision D8).")
  Settings = @(
    @("Gas combinations", "31 = 2^5 - 1, from reduced_gas_subsets.csv (checked: all different, none empty)"),
    @("Removed gas", "NaN (not measured), never 0 ppm"),
    @("Gases needed", "IEC 60599 and Rogers: H2, CH4, C2H6, C2H4, C2H2 (derived from R1, R2, R5); Duval: CH4, C2H4, C2H2"),
    @("Method without its gases", "ND for 100 % of the records, decided before any ratio, zone or gate test"),
    @("Method with its gases", "as Steps 14-17: decisions D11-D13, upper normality gate"),
    @("Normality gate with a gas missing", "never passed (D23 rule 4, proposed); sensitivity: gate on the measured gases only"),
    @("Records and roles", "827 records, data version 1.0; all, development, internal_test, benchmark, external_test"),
    @("Software", ("MATLAB " + $s.matlab + " (base MATLAB, no toolbox); Python " + $s.python)))
  Eqs = @(
    @{ Eq = 'A_m(S)=1  "if"  R_m⊆S,  "otherwise"  0'; Where = @(
        @('A_m(S)', 'applicability of method m to gas combination S (1 = the method can diagnose; 0 = it answers ND for every record)'),
        @('R_m', 'the set of gases that method m needs (IEC 60599 and Rogers: all five; Duval: CH4, C2H4, C2H2)'),
        @('m', 'method: IEC 60599, Rogers or Duval Triangle 1'),
        @('S', 'the set of gases that are measured, one of the 31 combinations')) },
    @{ Eq = 's_"ND"=n_"ND"/n'; Where = @(
        @('s_"ND"', 'share of records with no diagnosis (0 to 1)'),
        @('n_"ND"', 'number of records for which the method answers ND after the normality gate'),
        @('n', 'number of records in the data role (all = 827)')) })
  Tools = @("04_MATLAB_Conventional/reduced_gas_diagnosis.m (the rule), run_reduced_gas_applicability.m (31 x 3 x 5 table and 10 checks)",
            "04_MATLAB_Conventional/tests/TestReducedGas.m (26 tests); the 67 tests of Step 15 were run again (93 tests in all)",
            "06_Python_ML/src/conventional/step26_crosscheck.py and tests/test_step26_crosscheck.py (independent check, 4 tests)",
            "00_Project_Admin/report_builder/update_register_step26.ps1 (register, glossary)")
  Refs = @("ST1", "ST5", "M9")
}

$global:Closings["26"] = @{
  Achieved = @(
    ("The table conventional_applicability.csv has " + $s.rows + " rows (31 gas combinations x 3 methods x 5 data roles) and passed all " + $s.nchecks + " automatic checks."),
    ("IEC 60599 and Rogers can give a diagnosis in " + $s.appIec + " of the 31 combinations (all five gases); Duval Triangle 1 in " + $s.appDuval + " (those that keep CH4, C2H4 and C2H2)."),
    "Where a method needs a gas that is not measured it answers ND for 100 % of the records - never a guess - and the five-gas row reproduces the counts of Steps 14-17 exactly.",
    ("The independent Python implementation reproduced all " + $s.rows + " rows; " + $s.mlTests + " MATLAB tests and the Python tests pass."))
  Record = @(
    @("Step", "26 - Conventional methods with gases removed"), @("Environment", "Claude Code (this chat) through the MATLAB MCP connection (D14)"),
    @("Completed", $s.completed), @("Status", "Done (rule 4 of D23 awaits the researcher's confirmation)"),
    @("Main inputs", "dga_master.csv (data version 1.0, verified); reduced_gas_subsets.csv (Step 25); the functions of Steps 14-17"),
    @("Main outputs", "11_Results/conventional/conventional_applicability.csv and conventional_applicability_checks.csv; 08_Statistical_Analysis/cross_language_check_step26.csv"),
    @("Checks", $s.checks),
    @("Decisions", "D23 (rules 1-3 closed; rule 4, the normality gate on incomplete data, proposed)"))
  Helps = @(
    "Step 27 compares the reduced-gas machine-learning models with the conventional methods: a method that is not applicable to a gas combination counts as ND there, and the table gives the shares directly.",
    ("The smallest panel that loses at most 0.05 macro-F1 in Step 25 (" + $s.mlPanel + ") is not usable by any conventional method (" + $s.mlPanelText + "); this is a central argument of the thesis for machine learning with reduced gases.")
  )
  Open = @(
    "D23 rule 4 (the normality gate is never passed when a gas is missing) is Claude's recommendation and is awaiting the researcher's confirmation. The alternative is reported in the column n_nd_gate_measured; it changes only the Duval counts (a few samples with all measured gases low become Normal instead of ND).",
    "The roadmap check 'Duval ND equals the five-gas Duval ND' holds against the count before the gate (2 records), not after it (1 record): with a gas missing the gate cannot declare Normal, so the one record that the five-gas gate turned into Normal stays ND. Reported openly, not hidden.",
    "The standards limits behind the three methods are still TO VERIFY against licensed sources (see Steps 12 and 14); a correction would create data version 1.1 and this table would be re-run.",
    "11_Results/manifest.csv lists only some of the results (not kept up to date after Step 17); it must be completed.",
    "The Simulink start-up callbacks were changed earlier in this session (path fix); the exact error the researcher saw has still not been supplied, so it is not confirmed that this was the error.",
    "The counts per data role use all records of the role; the primary benchmark subset (58 power transformers) is not separated here.",
    "Which gas combinations correspond to real online monitors is still to be taken from published sources (TO VERIFY).")
  Exclude = @()
}

$global:StepSources["26"] = @("DF2", "DF6", "DF8", "DF10", "DF28", "DF29", "DF30", "DF31", "DF32", "ST1", "ST5", "M9", "SW1", "SW2")
