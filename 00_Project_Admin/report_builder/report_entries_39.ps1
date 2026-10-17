# report_entries_39.ps1 - "Method used" and closing entries for roadmap Step 39 (report standard 2026-10-10/11).
# Result numbers are NOT typed here: the builder fills $global:S39 from the result files before dot-sourcing.
# Saved as UTF-8 with byte-order mark (the equation contains a Greek sum sign).

$s = $global:S39
$global:Methods["39"] = @{
  Approach = @(
    "The dashboard is a client: it holds no diagnosis rule of its own. It reads one measured record, computes the three conventional diagnoses (Rogers ratio, IEC 60599 ratio, Duval Triangle 1) with the MATLAB functions of folder 04, and asks the FastAPI service of Step 38 for the machine-learning class and the seven class probabilities. The sample is drawn in the Duval Triangle and the answers are shown side by side, with a lamp that says whether the methods agree.",
    "Agreement has to be defined because some conventional answers are not a single class. A conventional answer agrees with the ML class if it is equal to it; the IEC dual answer D1/D2 agrees if the ML class is D1 or D2; DT (Duval) and ND (no diagnosis) never agree. The lamp is green when all three conventional methods agree with ML, amber when at least one does not, and grey when the ML answer is not available (decision D37; the scoring rules of D11 and D25 are reused).",
    "The service call is made with webwrite after the five gases have been checked locally. If the service cannot be reached, if a gas is missing or negative, or if the file cannot be read, the app writes a status text and keeps the conventional answers; it never stops. The simulated operating temperature (Simulink model) is shown as context only and is never linked to the measured gases.",
    "The app file DGADashboard.mlapp is written from a component list with the internal serializer of MATLAB R2025b, because App Designer cannot be driven from code. It was read back with App Designer's own reader and run from the file."
    )
  Why = @(
    "One implementation per method: the conventional methods stay in MATLAB (folder 04) and the ML model stays in Python behind the service, so the dashboard cannot disagree with the offline results because of a second copy of the code.",
    "The roadmap check is a comparison with the offline results. It is made on the three prescribed records through the real Diagnose button, and on all 388 held-out records through the same functions, so that the test is much stronger than three examples.",
    "A dashboard that stops on an error would be useless in a test bench, and one that hides a failure would be misleading; therefore each failure gives a clear status text.")
  Settings = @(
    @("Service", "http://127.0.0.1:8000/diagnose (this computer only), timeout 10 s, JSON"),
    @("Input checks", "five gases, each one finite number >= 0 (ppm); record_id and equipment_type read from the file when present"),
    @("Three known records", ("first held-out, in-scope record in file order of class PD, D2 and T3 (rule of D37 fixed before running): rows " + $s.rows)),
    @("Agreement lamp", "green all three agree with ML; amber at least one does not; grey ML not available"),
    @("Operating context", "run_transformer_simulation, 24 h, rated load; temperatures only"),
    @("Software", ("MATLAB " + $s.matlab + ", App Designer file format, webwrite; service: FastAPI (Step 38)")))
  Eqs = @(
    @{ Eq = 'a=∑_(k=1)^3 I_k'; Where = @(
        @('a', 'number of conventional methods that agree with ML, 0 to 3'),
        @('k', 'index of the conventional method (Rogers, IEC 60599, Duval)'),
        @('I_k', 'agreement indicator of method k: 1 if the answer of method k equals the ML class, or is D1/D2 and the ML class is D1 or D2; 0 otherwise (including DT and ND)')) })
  Tools = @("10_Dashboard_Client/DGADashboard.mlapp (the app); dga_agreement.m, ml_diagnose.m, load_dga_record.m",
            "10_Dashboard_Client/tools/build_dashboard_mlapp.m, DGADashboard_code.txt (writes the .mlapp); tools/make_figure_4_22.m (Figure 4.22)",
            "10_Dashboard_Client/verify_step39.m (19 checks)",
            "00_Project_Admin/report_builder/update_register_step39.ps1 (register, glossary)")
  Refs = @("ST6", "SW4", "DF2")
}

$global:Closings["39"] = @{
  Achieved = @(
    "The App Designer dashboard DGADashboard.mlapp was built: it loads a record, shows the three conventional diagnoses computed in MATLAB, calls the service for the ML diagnosis and class probabilities, draws the sample in Duval Triangle 1, shows the agreement lamp and the simulated operating temperatures (decision D37).",
    ("All " + $s.nChecks + " checks pass. The three known records (one per fault family) give exactly the offline conventional answers, the offline ML class and the offline probabilities (largest difference " + $s.pdiff + "); the same holds for all " + $s.nHeld + " held-out records."),
    "Service not reachable, invalid gas values, an unreadable file and a missing file each give a status text and no error.",
    "Figure 4.22 (annotated screenshot) was produced.")
  Record = @(
    @("Step", "39 - Build the App Designer dashboard"), @("Environment", "Claude Code (this chat) through the MATLAB MCP connection (roadmap role: MATLAB Agentic Toolkit; D30)"),
    @("Completed", $s.completed), @("Status", "Done (the .mlapp should be opened once in App Designer by the researcher)"),
    @("Main inputs", "MATLAB_Build_Guide Part C; 09_API_FastAPI/openapi.json and the running service; dga_master.csv; the offline results of Steps 14 and 22"),
    @("Main outputs", "10_Dashboard_Client/DGADashboard.mlapp, dga_agreement.m, ml_diagnose.m, load_dga_record.m, verify_step39.m, results/step39_*.csv; 11_Results/figures/F4_22_dashboard_annotated.(png|pdf), legend csv"),
    @("Checks", $s.checks),
    @("Decisions", "D37 (dashboard design, agreement rule, record rule, .mlapp production)"))
  Helps = @(
    "Step 40 adds the Run Simulation link and uses the sampling events of SS8 to trigger the diagnosis of the next record: the dashboard already diagnoses any row of dga_master.csv, and get_sampling_events.m gives the row from record_index.",
    "Steps 41 and 42 (test bench, fidelity and response time) can call the same helper functions; the comparison of this step already shows 100 % identity with the offline results.",
    "Chapter 4 can show Figure 4.22 and the table of the three records (results/step39_three_records.csv).")
  Open = @(
    "DGADashboard.mlapp was written with an internal MathWorks serializer, not drawn in App Designer. It loads with App Designer's reader and runs, but it should be opened once in App Designer and saved there (decision D37, clause 7).",
    "The agreement definition (D1/D2 agrees with D1 or D2; DT and ND never agree) and the choice of the three records are choices of decision D37; the researcher may change them.",
    "The three known records are the first of their class in file order; the ML class of the thermal record (T2) differs from its true class T3. The check is identity with the offline results, not correctness.",
    "The service must be started before the app (09_API_FastAPI/run_service.ps1); otherwise the ML row shows NOT_CONNECTED and the lamp is grey.",
    "The response times in the app (about 75 to 100 ms per call) are preliminary; the formal response time is measured in Step 42.",
    "The researcher's error text from the earlier Simulink rerun has still not been supplied.")
  Exclude = @()
}

$global:StepSources["39"] = @("ST6", "SW4", "DF2", "DF48", "DF52", "DF71", "DF72", "DF73")
