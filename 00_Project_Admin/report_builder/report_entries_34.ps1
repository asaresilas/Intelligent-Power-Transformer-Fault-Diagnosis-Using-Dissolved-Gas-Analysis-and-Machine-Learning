# report_entries_34.ps1 - "Method used" and closing entries for roadmap Step 34 (report standard 2026-10-10/11).
# Result numbers are NOT typed here: the builder fills $global:S34 from the result files before dot-sourcing.
# ASCII only (Windows PowerShell 5.1 reads scripts without a byte-order mark in the ANSI code page).

$s = $global:S34
$global:Methods["34"] = @{
  Approach = @(
    ("Static model checking in two parts. Part 1 is the Model Advisor of Simulink Check: a MathWorks tool that opens the model without running a simulation and applies a list of rules (settings, unconnected ports and lines, deprecated blocks, units, style rules). A MATLAB program (step34_run_model_advisor.m) starts it with a fixed list of " + $s.nChecks + " checks and saves the report. Part 2 is the checklist of Part D1 of the MATLAB Build Guide, written as a MATLAB function (step34_checklist_D1.m) so that it can be repeated at any time."),
    "Every result that is not 'passed' was read and then handled in one of two ways, as the roadmap requires: fixed, or accepted with a written reason. A fix is never made by hand in the model file; it is made in the building program (build_Transformer_Operating_Model.m), the model is rebuilt, and all earlier checks (the nine checks of Step 33) are run again. An acceptance is written into a table by a program that stops if a non-passed check has no reason.",
    ("The checklist item 'no number typed into a block' was tested more strictly than in Step 33: the program reads every dialog field of every one of the " + $s.nBlocks + " blocks (not only the settings that the builder made), picks out the values that contain a digit and sorts them by rule into harmless categories or into 'parameter number'. The item passes only if the category 'parameter number' is empty."))
  Why = @(
    "Checking a model before it is used is standard practice in model-based design; the Model Advisor is the tool MathWorks provides for it, and 'fix it or justify it' is the same logic as the justification feature of the Model Advisor itself.",
    "Fixing in the building program keeps the model reproducible: anyone who runs the program gets the corrected model, and nothing exists only in a hand-edited file.",
    "Re-running all earlier checks after every change shows that a fix did not change the physics (here the logged signals stay identical to the reference run, difference 0.00e+00).",
    "A strict scan of all dialog fields is the only way to find numbers that a person would not see at first glance (hidden or default fields); it found one real case that Step 33 had missed.")
  Settings = @(
    @("Model Advisor check set", ("" + $s.nChecks + " checks: groups design, simscape, simulink, sl, maab (modelling and Simscape checks). Left out: code generation, AUTOSAR, DO-178, MISRA, PLC, HISM, JMAAB - no code is generated from this model (decision D32).")),
    @("Result classes", "Passed, Warning, Failed, Incomplete (Model Advisor terms)"),
    @("Report", "HTML, 05_Simulink_Model/checks/model_advisor_report.html"),
    @("Tolerance for the 24 h run", "0.1 K against the Build Guide Section B12 values (K = 0.9839; top oil 78.638 degC; hot spot 100.276 degC); approved tolerance of the Analysis Plan, Section 9"),
    @("Categories of dialog values", "interface code (port number, inherited sample time -1, latency, unit selector, normalisation value, logging option); hidden field (the block mask hides it); library tuning (tolerances and filter settings of Solver Configuration and converter blocks); option selector (0 = None); parameter number (anything else = fail)"),
    @("Diagnostics set to error", "Inf/NaN output, unconnected input, output and line, duplicate data store names, bus signal treated as vector"),
    @("Software", ("MATLAB " + $s.matlab + ", Simulink, Simscape, Simscape Electrical, Simulink Check")))
  Tools = @("05_Simulink_Model/checks/step34_run_model_advisor.m (runs the checks, writes report and result table)",
            "05_Simulink_Model/checks/step34_write_accepted.m (reasons for the non-passed checks), step34_checklist_D1.m (checklist)",
            "05_Simulink_Model/build_Transformer_Operating_Model.m, verify_step33.m, params_transformer.m (changed in this step)",
            "00_Project_Admin/report_builder/update_register_step34.ps1 (register, glossary)")
  Refs = @("SW5", "SW2", "ST6")
}

$global:Closings["34"] = @{
  Achieved = @(
    ("Model Advisor was run on Transformer_Operating_Model.slx with " + $s.nChecks + " checks. The first run (on the Step 33 model) gave " + $s.firstSummary + ". After the fixes the final run gives " + $s.finalSummary + "; no check failed."),
    ("Five groups of warnings were fixed in the building program: the deprecated sqrt block, five diagnostics set to 'none', the 'bus treated as vector' setting, a hidden block name and (found by the stricter D1 scan) the zero-sequence reactance that was typed as the block default 0.5 and is now the variable X0_pu."),
    ("The remaining " + $s.nAccepted + " results that are not 'passed' (" + $s.nWarn + " warnings and " + $s.nIncomplete + " incomplete check) are style rules for control code, code-generation options or internals of Simscape library blocks; each has a written reason in model_advisor_accepted.csv."),
    ("Build Guide Part D1: " + $s.d1Pass + " of " + $s.d1Rows + " rows pass; D1.7 (a second person checks the build) is open and D1.6 (the app) is not applicable yet. Every dialog field of all " + $s.nBlocks + " blocks was read: " + $s.nFlagged + " values contain a digit and none is a typed parameter number."),
    ("The model still passes all nine Step 33 checks after the changes, and the 24-hour run is unchanged: K = " + $s.k + ", top oil " + $s.oil + " degC, hot spot " + $s.hs + " degC."))
  Record = @(
    @("Step", "34 - Run the model checks"), @("Environment", "Claude Code (this chat) through the MATLAB MCP connection (roadmap role: Simulink Agentic Toolkit; D30)"),
    @("Completed", $s.completed), @("Status", "Done; the acceptance of the remaining warnings (D32, clause 3) awaits the researcher's confirmation; D1 item 7 is open"),
    @("Main inputs", "Transformer_Operating_Model.slx (Step 33); MATLAB Build Guide Part D1; Model Advisor of Simulink Check"),
    @("Main outputs", "05_Simulink_Model/checks/model_advisor_report.html, model_advisor_results.csv, model_advisor_accepted.csv, step34_checklist_D1.csv; corrected model and building program"),
    @("Checks", $s.checks),
    @("Decisions", "D32 (check set; fixes; accepted warnings proposed; D1 items 6 and 7)"))
  Helps = @(
    "Step 35 verifies the model formally against an independent solution of the IEC 60076-7 equations (rated load and a load step from 0.6 to 1.2 per unit). It starts from a model that has no failed check, no open diagnostic and no typed parameter number, and whose parameter file now states unit and source for every variable.",
    "Step 36 adds the operating scenarios and Step 37 the sampling-event subsystem. The checks of this step (checklist function, nine Step 33 checks, Model Advisor script) can be run again after each of them; the diagnostics now set to 'error' will stop a run that has an open connection or an Inf/NaN value.",
    "The table of accepted warnings can be reused in the thesis (Chapter 3, model verification) as the record of how the model was checked.")
  Open = @(
    ("The acceptance of the " + $s.nAccepted + " remaining results that are not 'passed' (decision D32, clause 3) is proposed and needs the researcher's confirmation. If the supervisor wants some of the MAAB style rules satisfied (signal labels, left-to-right layout, displayed parameters), they can be added to the building program, at the cost of re-exporting the figures."),
    "Build Guide D1 item 7 (a second team member checks the build against the reference script) cannot be done by a program and stays open. The automatic substitute is check 7 of verify_step33.m, which compares the model with the reference build block by block.",
    "Build Guide D1 item 6 (the app runs and shows PENDING_STANDARD / NOT_CONNECTED) is not applicable yet because the dashboard belongs to Stage H; it is tested there.",
    "The zero-sequence reactance X0_pu = 0.5 pu is the default of the Simscape Electrical block, not a value from the pandapower source: TO VERIFY if unbalanced cases are ever studied. It has no effect on the balanced load of this model.",
    "The thermal constants are still default values of an open-source implementation, not values from IEC 60076-7:2018 (the standard was not obtained): TO VERIFY, unchanged from Step 33.",
    "The Step 33 report describes the model as it was built on 12 October (5 expected differences from the reference build, 3 files with the fingerprints of that day). This step changed the model, the building program, the check program and the parameter file; the Step 33 model is kept as checks/Transformer_Operating_Model_before_step34.slx (register row DF58) and the register rows DF48, DF50 and DF52 now show the files after Step 34. The Step 33 report was not rewritten.",
    "The raw result of the first Model Advisor run was overwritten by the later runs; its summary and warning list in this report are taken from the program output of that run.",
    "The exact error text that the researcher saw in the earlier Simulink rerun has still not been supplied.")
  Exclude = @()
}

$global:StepSources["34"] = @("SW5", "SW2", "ST6", "DF48", "DF52", "DF54", "DF55", "DF56", "DF57", "DF58")
