# report_entries_37.ps1 - "Method used" and closing entries for roadmap Step 37 (report standard 2026-10-10/11).
# Result numbers are NOT typed here: the builder fills $global:S37 from the result files before dot-sourcing. ASCII only.

$s = $global:S37
$global:Methods["37"] = @{
  Approach = @(
    "Event generation without data: a sampling event is a moment in simulated time at which a laboratory sample would be taken. Subsystem SS8 knows only the list of sampling times (params_transformer.m) and the simulation clock. It counts how many sampling times have passed and raises a one-minute pulse after each of them. It has no input and no output port, so nothing can flow from it into the temperature and ageing subsystems SS1 to SS7.",
    "A Simulink signal is a number, not text. SS8 therefore outputs record_index, the number of sampling times passed (0 before the first, then 1, 2, ...). The text identifier of the record (record_id) is looked up outside the model, by get_sampling_events.m, in a list of held-out record identifiers that params_transformer.m reads from dga_master.csv. Only two columns of that file are read, record_id and data_role, so no gas value ever enters the model's workspace.",
    "Held-out means every record of dga_master.csv whose data_role is not development (benchmark, internal test and external test; 388 records), in file order: the k-th sampling event takes the k-th of them (decision D35). The requirement that no block produces a gas concentration is tested, not assumed: the test inspects every block, every name and dialog value, the logged signals and the code that reads the file."
    )
  Why = @(
    "The framework must show, in the operating context, WHEN a gas sample would be taken, so that the dashboard can pick up the real measured record at that moment. The model must never invent a gas concentration (decision D4); the records come from measurements only.",
    "Using a count of sampling times instead of text keeps the subsystem to clock, comparison, counting and logic blocks, which can be inspected completely.",
    "Because SS8 is not connected to SS1-SS7, adding it must not change the temperatures. This is tested against the saved Step 36 results. It does change the solver time grid slightly, because the solver has to stop at each sampling time; the test therefore compares the signals on the time points that both runs share.")
  Settings = @(
    @("Sampling times", ("t_sample_h = " + $s.times + " h (illustrative; params_transformer.m)")),
    @("Event pulse", ("t_event_s = " + $s.tev + " s after each sampling time")),
    @("Held-out records", "388 records of dga_master.csv with data_role not development; only the columns record_id and data_role are read"),
    @("Logged signals of SS8", "record_index (0, 1, 2, ...) and sampling_event (0 or 1)"),
    @("Solver", "ode23t, RelTol 1e-4 (variable solver_reltol), maximum step 60 s (the tolerance was tightened in Step 35, D33)"),
    @("Software", ("MATLAB " + $s.matlab + ", Simulink, Simscape, Simscape Electrical")))
  Eqs = @(
    @{ Eq = 'k(t)=∑_(j=1)^n H(t-t_j)'; Where = @(
        @('k(t)', 'record_index: the number of sampling times passed at time t, dimensionless'),
        @('H', 'unit step: 0 for a negative argument and 1 otherwise'),
        @('t_j', 'the j-th sampling time, s (t_sample_h x 3600)'),
        @('n', ('number of sampling times (' + $s.n + ')'))) })
  Tools = @("05_Simulink_Model/verify_step37.m (10 checks: inspection, timing, record ids, regression, Step 33 checks)",
            "05_Simulink_Model/get_sampling_events.m (looks up record_id from record_index); params_transformer.m (sampling times, held-out list)",
            "05_Simulink_Model/build_Transformer_Operating_Model.m (builds SS8 and sets solver_reltol)",
            "00_Project_Admin/report_builder/update_register_step37.ps1 (register, glossary)")
  Refs = @("ST6", "SW4", "DF2")
}

$global:Closings["37"] = @{
  Achieved = @(
    ("Subsystem SS8 (sampling events) was added to the model. At the sampling times " + $s.times + " h it raises record_index and a " + $s.tev + " s event pulse; it has no connection to SS1-SS7 (decision D35)."),
    ("All " + $s.nChecks + " checks of verify_step37.m pass, including: no block, name, value or logged signal refers to a gas or a concentration; params_transformer.m reads only record_id and data_role; the index steps at the set times to within 1e-6 s."),
    ("The first four held-out records are " + $s.ids + "; they exist in dga_master.csv with the role benchmark."),
    ("The thermal and ageing signals of the three Step 36 scenarios agree with the saved results on the common time points within 0.01 K (largest " + $s.dmax + " K), and the nine Step 33 checks still pass."),
    "Because a Step 35 check failed after SS8 was added (0.104 K against 0.1 K), the cause was traced to the solver tolerance and fixed (RelTol 1e-4); Steps 33 to 37 and the Step 34 checks were re-run on the final model.")
  Record = @(
    @("Step", "37 - Add the DGA sampling-event subsystem"), @("Environment", "Claude Code (this chat) through the MATLAB MCP connection (roadmap role: Simulink Agentic Toolkit; D30)"),
    @("Completed", $s.completed), @("Status", "Done"),
    @("Main inputs", "Transformer_Operating_Model.slx; params_transformer.m; 03_Data/processed/dga_master.csv (columns record_id and data_role only)"),
    @("Main outputs", "Transformer_Operating_Model.slx (SS8); get_sampling_events.m; verify_step37.m; results/step37_checks.csv, step37_sampling_events.csv, step37_ss8_blocks.csv"),
    @("Checks", $s.checks),
    @("Decisions", "D35 (design and test of the sampling-event subsystem; two amendments), D33 amendment (solver tolerance)"))
  Helps = @(
    "Step 38 (the FastAPI service) and the dashboard can call the model for an operating context and ask get_sampling_events for the record_id that belongs to each sampling event; the gases are then read from the real record in the CSV, never from the model.",
    "The solver tolerance now stored in params_transformer.m makes the verification of Step 35 pass with a wide margin (0.013 K against 0.1 K).")
  Open = @(
    "The sampling times (6, 12, 18 and 22 h) are illustrative, not a real laboratory schedule; they can be replaced in params_transformer.m.",
    "The held-out list is taken in file order; whether the dashboard should draw records at random or by class is a later design choice.",
    "The 1 min event pulse and the order of the held-out records are choices of decision D35 (researcher may change them).",
    "The regression test compares signals at the tolerance of the saved Step 36 results (RelTol 1e-3), so that only the effect of SS8 is measured; the final model runs at 1e-4 and the Step 36 results were regenerated at that tolerance.",
    "Model Advisor and checklist D1 were repeated: the same 11 warnings and 1 incomplete item as accepted in D32; item D1.7 (a second team member checks the build) still needs a person.",
    "The researcher's error text from the earlier Simulink rerun has still not been supplied.")
  Exclude = @()
}

$global:StepSources["37"] = @("ST6", "SW4", "DF2", "DF48", "DF52", "DF69", "DF70")
