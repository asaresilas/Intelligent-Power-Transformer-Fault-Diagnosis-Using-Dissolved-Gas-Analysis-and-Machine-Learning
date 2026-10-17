# report_entries_41.ps1 - "Method used" and closing entries for roadmap Step 41 (report standard 2026-10-10/11).
# Result numbers are NOT typed here: the builder fills $global:S41 from the result files before dot-sourcing. ASCII only.

$s = $global:S41
$global:Methods["41"] = @{
  Approach = @(
    "The test bench runs the whole framework once over every held-out record. The unchanged Simulink transformer model is simulated for 98 hours with one sampling event every 15 minutes, which gives one event for each of the 388 held-out records. At each event, in time order, the bench does what the dashboard does with a record: it finds the record in the DGA file, reads the five gases, computes the three conventional diagnoses in MATLAB, sends the gases to the FastAPI service and receives the ML class and the seven class probabilities, and works out how many conventional methods agree with ML.",
    "Everything is logged, one row per record: the event time, the record, its data role, the gases as read, the three conventional answers, the ML class and probabilities, the model name, version and hash, the agreement, the simulated hot-spot temperature at the event, and three times. The response time is the time between sending the request and receiving the answer (Analysis Plan Section 10), measured around the web call on the project laptop. No true label is read or written.",
    "The bench does not compare the answers with the offline predictions and does not compute statistics: that is Step 42. Here the checks are about the run itself: one row per record, no failed call, the events at the planned times, the same model before and after, and no label in the log (decision D39)."
    )
  Why = @(
    "Step 42 needs a complete log of the integrated system to compute fidelity and response time; this step produces it under controlled conditions that are written down before the run (D39).",
    "Driving the records through the simulated sampling events keeps the model in the loop as designed in Steps 37 and 40, so the bench tests the same chain as the dashboard and not a shortcut.",
    "Logging every call, including the first five (warm-up), and every failure, means that nothing is selected after the fact.")
  Settings = @(
    @("Records", ("all " + $s.n + " held-out records of dga_master.csv in file order: benchmark " + $s.nBench + ", internal_test " + $s.nInt + ", external_test " + $s.nExt)),
    @("Sampling events", "one every 15 min from 0.25 h to 97 h; simulation stop time 98 h (set for this run only; the model is unchanged)"),
    @("Service", "http://127.0.0.1:8000/diagnose on this computer; timeout 10 s"),
    @("Response time", "tic/toc around the web call (send request to receive answer), in ms; first 5 calls flagged warmup"),
    @("Computer", ("project laptop: " + $s.processor + ", " + $s.cpus + " logical processors")),
    @("Software", ("MATLAB " + $s.matlab + ", Simulink, Simscape; service: FastAPI (Step 38)")))
  Eqs = @()
  Tools = @("10_Dashboard_Client/run_testbench.m (the bench), verify_step41.m (12 checks), tools/make_figure_4_20.m (Figure 4.20)",
            "10_Dashboard_Client/find_dga_row.m, load_dga_record.m, ml_diagnose.m, dga_agreement.m (as in the dashboard)",
            "05_Simulink_Model/get_sampling_events.m; 04_MATLAB_Conventional/conventional_diagnosis.m",
            "00_Project_Admin/report_builder/update_register_step41.ps1 (register, glossary)")
  Refs = @("ST6", "SW4", "DF2")
}

$global:Closings["41"] = @{
  Achieved = @(
    ("The integrated system was run over all " + $s.n + " held-out records: " + $s.n + " log rows, " + $s.nFailed + " failed calls (decision D39)."),
    ("All " + $s.nChecks + " checks pass: one row per record in file order, the events at the planned times, the same model hash before and after, no label in the log."),
    ("The response time of the service call was " + $s.med + " ms (median) and " + $s.p95 + " ms (95th percentile) on the project laptop, all calls included; the formal statistics and Figure 4.21 are made in Step 42."),
    "Figure 4.20 (the test-bench run) was produced; the log is 10_Dashboard_Client/logs/testbench_log.csv.")
  Record = @(
    @("Step", "41 - Run the end-to-end test bench"), @("Environment", "Claude Code (this chat) through the MATLAB MCP connection (roadmap role: MATLAB Agentic Toolkit; D30)"),
    @("Completed", $s.completed), @("Status", "Done"),
    @("Main inputs", "Transformer_Operating_Model.slx (unchanged); the running service; dga_master.csv (held-out records)"),
    @("Main outputs", "10_Dashboard_Client/logs/testbench_log.csv, testbench_run_info.json, testbench_events.mat; results/step41_checks.csv; 11_Results/figures/F4_20_testbench_run.(png|pdf|csv)"),
    @("Checks", $s.checks),
    @("Decisions", "D39 (scope, schedule, response-time definition, log columns, checks)"))
  Helps = @(
    "Step 42 compares this log with ml_predictions.csv and conventional_predictions.csv (fidelity, which must be 100 %) and computes the median and 95th-percentile response times for Table 4.11 and Figure 4.21.",
    "The log carries the data role of every record, so the internal-test and benchmark records named in the roadmap can be analysed on their own by filtering.")
  Open = @(
    "The roadmap names only the records of role internal test or benchmark in its instruction line, but asks for every held-out record in its output and check, and the Analysis Plan (Section 10) asks for all test records. All 388 were run (D39); the external-test records were already opened for the ML predictions on 12 October 2026 and no label is read. The researcher may restrict the analysis to the 187 internal-test and benchmark records by filtering data_role.",
    "The sampling schedule (15 min) is a choice of this bench; the 98-hour run is not a realistic operating period. The simulated temperature is almost constant after the first hours (rated load), so panel (a) of Figure 4.20 shows the clock of the bench rather than a load story.",
    "The pattern of classes along the time axis in Figure 4.20 (b) reflects the order of the records in the file (records of the same source and class are neighbours), not any property of time.",
    ("The response time measured here is the round trip of the web call as seen from MATLAB; it includes the conversion of the request and the answer. The whole record takes longer (median " + $s.medTot + " ms), of which the conventional diagnosis in MATLAB takes a median of " + $s.medConv + " ms and the rest is reading the file; the reason for the " + $s.medConv + " ms was not investigated. These times are logged but are not the response time of the service."),
    "The bench calls the same functions as the dashboard, without the plots; the dashboard itself was tested on four events in Step 40.",
    "The researcher's error text from the earlier Simulink rerun has still not been supplied.")
  Exclude = @()
}

$global:StepSources["41"] = @("ST6", "SW4", "DF2", "DF48", "DF52", "DF76", "DF77", "DF78")
