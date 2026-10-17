# report_entries_36.ps1 - "Method used" and closing entries for roadmap Step 36 (report standard 2026-10-10/11).
# Result numbers are NOT typed here: the builder fills $global:S36 from the result files before dot-sourcing. ASCII only.

$s = $global:S36
$global:Methods["36"] = @{
  Approach = @(
    "Scenario simulation: the verified model is run with three chosen load histories (scenarios) and nothing else is changed. The load history of each scenario is the only thing that differs, and it is defined in one file, scenarios.m, in which every number is a named variable with a unit. The temperatures, the ageing rate and the loss of life are then read from the model's logged outputs.",
    "The three scenarios are: S1 a constant rated load (demand 1.0 per unit for 24 hours); S2 a daily load cycle (night load, daytime load and an evening peak; the same day is repeated three times and the last day is shown, so that the result does not depend on the cold start); S3 a short overload (a base load of 0.8 per unit, overloaded to 1.3 per unit for 2 hours, then back).",
    "Each run is stored in the Simulation Data Inspector and in a .mat file. Reproducibility is tested, not assumed: every scenario is run twice from a fresh start, the saved file is compared with a new run, and the model file is fingerprinted before and after.")
  Why = @(
    "Scenario runs show the operating context the dashboard displays: how load, temperatures and ageing move together. The model was verified against the IEC 60076-7 equations in Step 35, so these curves are the equations' answer for these loads.",
    "Keeping all scenario numbers in one file, and the model and the parameter file unchanged, makes every run reproducible from params_transformer.m and scenarios.m, which is the roadmap check.",
    "Showing the third day of the daily cycle avoids a misleading cold start: the first day is a warm-up whose temperatures depend on the starting state, not on the load cycle.")
  Settings = @(
    @("S1 constant rated load", ("demand " + $s.rated + "; 24 h")),
    @("S2 daily load cycle", ("demand (hour, pu): " + $s.daily + "; three days (72 h), last 24 h shown")),
    @("S3 short overload", ("demand (hour, pu): " + $s.overload + "; 1 s ramps; 24 h")),
    @("Ambient temperature", "20 degC (params_transformer.m), constant in all scenarios"),
    @("Start", "all temperatures equal to ambient (the model's initial state)"),
    @("Loss of life L", "integral of the ageing rate V over the shown 24 h (trapezoidal rule), in equivalent hours at the reference hot-spot temperature"),
    @("Limits from IEC 60076-7", "none applied: the standard was not obtained; peaks and L are reported only"),
    @("Software", ("MATLAB " + $s.matlab + ", Simulink, Simscape, Simscape Electrical")))
  Eqs = @(
    @{ Eq = 'L=∫_(t_1)^(t_2) V dt,    V=2^((θ_h-θ_"ref")/Δθ_d)'; Where = @(
        @('L', 'loss of life over the period, in equivalent hours at the reference hot-spot temperature, h'),
        @('V', 'relative ageing rate of the insulation, dimensionless (1 at the reference temperature)'),
        @('t_1, t_2', 'start and end of the shown 24 h, h'),
        @('θ_h', 'hot-spot temperature, °C'),
        @('θ_"ref"', 'hot-spot temperature at which V = 1, °C (98 °C)'),
        @('Δθ_d', 'temperature rise that doubles the ageing rate, K (6 K)')) })
  Tools = @("05_Simulink_Model/scenarios.m (the scenario definitions), run_step36.m (runs, checks, figures, SDI session)",
            "Simulink.SimulationInput, Simulink.sdi (Simulation Data Inspector), exportgraphics; colours from 11_Results/figures/plot_style.csv",
            "00_Project_Admin/report_builder/update_register_step36.ps1 (register, glossary)")
  Refs = @("ST6", "SW4")
}

$global:Closings["36"] = @{
  Achieved = @(
    "Three operating scenarios were written in scenarios.m (decision D34) and simulated on the verified model; each run is stored in results/sim_<scenario>.mat and in a Simulation Data Inspector session.",
    ("All " + $s.nChecks + " checks pass: every run is identical when repeated from a fresh start, the saved files equal new runs, the model file is unchanged, and the rated-load scenario equals the default run of the model."),
    ("Peak hot-spot temperatures: " + $s.pk1 + " degC (rated load), " + $s.pk2 + " degC (daily cycle, at " + $s.t2 + " h), " + $s.pk3 + " degC (overload, at " + $s.t3 + " h). Loss of life in the shown 24 h: " + $s.L1 + " h, " + $s.L2 + " h and " + $s.L3 + " h."),
    "Figure 4.19 (a, b, c) was produced, one figure per scenario.")
  Record = @(
    @("Step", "36 - Run the operating scenarios"), @("Environment", "Claude Code (this chat) through the MATLAB MCP connection (roadmap role: Simulink Agentic Toolkit; D30)"),
    @("Completed", $s.completed), @("Status", "Done"),
    @("Main inputs", "Transformer_Operating_Model.slx; params_transformer.m; scenarios.m"),
    @("Main outputs", "results/sim_rated.mat, sim_daily.mat, sim_overload.mat; step36_*.csv; step36_sdi_session.mldatx; 11_Results/figures/F4_19a|b|c_*"),
    @("Checks", $s.checks),
    @("Decisions", "D34 (the approved scenarios and how they are run and checked)"))
  Helps = @(
    "Step 37 adds the DGA sampling-event subsystem to the model. The runs of this step can be repeated afterwards (run_step36.m) to show that the temperatures and ageing did not change, and Step 37's own test must show that no block produces a gas value.",
    "The dashboard (Stage H) calls the model for an operating context; these three scenarios give it ready examples and show what it will plot.",
    "Chapter 3 can describe the operating-context model with Figure 3.4 (structure), Table 4.10 and Figure 4.18 (verification) and Figure 4.19 (scenarios).")
  Open = @(
    "The scenario values (0.5 to 1.0 per unit daily cycle; 0.8 per unit with 1.3 per unit for 2 hours) are illustrative choices of this project, not measured load data. Replace them with real utility load curves if the Ghanaian utility records requested through the supervisor arrive; only scenarios.m changes.",
    "The peak hot-spot temperature of the overload scenario is reported without a limit because IEC 60076-7:2018, which gives the permitted temperatures, was not obtained (TO VERIFY). Do not describe the overload as safe or unsafe in the thesis without that standard.",
    "The thermal constants are default values of an open-source implementation (TO VERIFY against IEC 60076-7:2018), unchanged since Step 33.",
    "The measured load factor is lower than the demanded one (for example 1.267 for a demand of 1.3) because the load sits behind the transformer impedance; the figures show both.",
    "The .mat files and the Simulation Data Inspector session are binary files whose hashes change with every save; reproducibility is tested on the signals.",
    "The researcher's error text from the earlier Simulink rerun has still not been supplied.")
  Exclude = @()
}

$global:StepSources["36"] = @("ST6", "SW4", "DF48", "DF52", "DF64", "DF65", "DF66", "DF67", "DF68")