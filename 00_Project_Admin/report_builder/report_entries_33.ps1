# report_entries_33.ps1 - "Method used" and closing entries for roadmap Step 33 (report standard 2026-10-10/11).
# Result numbers are NOT typed here: the builder fills $global:S33 from the result files before dot-sourcing.

$s = $global:S33
$global:Methods["33"] = @{
  Approach = @(
    "The model is built by a MATLAB program (build_Transformer_Operating_Model.m) that follows Part B of the MATLAB Build Guide block by block: it creates the seven subsystems, places every block, sets its parameters and draws every connection. Because the whole model is written as code, every block, setting and line can be read, checked and rebuilt at any time.",
    "The model has two physical networks. The electrical network (SS1 grid, SS2 transformer, SS3 measurement, SS4 load) is built from Simscape Electrical blocks. The thermal network (SS6) is built from Simscape Foundation thermal blocks as three heat-flow circuits (top oil and two hot-spot components), like electrical circuits with heat flow instead of current and temperature instead of voltage. The loss calculation (SS5) and the outputs and ageing (SS7) are ordinary Simulink arithmetic blocks.",
    "The model is then checked against a reference: the model that was built and verified earlier from the same guide (reference_build). A program compares the two block by block (names, types, parameters, connections) and compares the simulation results; a separate calculation of the steady state of the IEC 60076-7 equations is used as an independent check of the numbers.")
  Why = @(
    "Building the model from a script, not by hand, gives a model that anyone can reproduce and that can be compared automatically with the reference; this is standard practice in model-based design.",
    "The arithmetic (square root, powers, products) is done in Simulink blocks, not in physical-signal blocks, because the electrical network uses the 'Frequency and time' equation formulation. That formulation lets a 24-hour, 50 Hz simulation run in seconds instead of hours, but accepts only switched-linear equations (the Build Guide documents the error that a nonlinear physical block causes).",
    "Every value is a variable of params_transformer.m, never a number typed into a block, so the model can be changed in one place and every number has a unit and a source.")
  Settings = @(
    @("Model", ("Transformer_Operating_Model.slx: 7 subsystems, " + $s.nBlocks + " blocks, 2 physical networks")),
    @("Solver", "variable step, ode23t, stop time t_stop, maximum step t_step_max (variables)"),
    @("Electrical network", "Frequency and time equation formulation; ideal source (no source impedance); Delta 1 o'clock / grounded Wye transformer, linear (no saturation)"),
    @("Load", "resistive, unity power factor, P = K(t) x S_rated from load_profile; minimum power P_load_min"),
    @("Thermal network", "three first-order circuits; mass = heat capacity in J/K (cp_unit = 1); initial temperature = ambient"),
    @("Callbacks", "PreLoadFcn and InitFcn: put the model folder on the path if needed, then run params_transformer (D31)"),
    @("Tolerance for checks", "0.1 K (approved, Analysis Plan Section 9; proposed in the roadmap for Step 35)"),
    @("Software", ("MATLAB " + $s.matlab + " with Simulink, Simscape and Simscape Electrical; run through the MATLAB MCP connection (D30)")))
  Eqs = @(
    @{ Eq = 'K=√((i_a^2+i_b^2+i_c^2)/3)/I_"LV,r"'; Where = @(
        @('K', 'load factor, per unit (1 = rated current)'),
        @('i_a, i_b, i_c', 'instantaneous phase currents on the low-voltage side, A'),
        @('I_"LV,r"', 'rated low-voltage line current, A (I_LV_rated)')) },
    @{ Eq = 'Q_"oil"=P_"tot,r"·[(P_0+P_k·K^2)/P_"tot,r"]^x'; Where = @(
        @('Q_"oil"', 'equivalent heat input of the oil circuit, W'),
        @('P_0, P_k', 'no-load loss and load loss at rated current, W'),
        @('P_"tot,r"', 'total loss at rated load, W (the sum of P0 and Pk)'),
        @('x', 'oil exponent (x_oil), dimensionless')) },
    @{ Eq = 'Q_"h1"=(k_21·Δθ_"hr"·K^y)/R_"th,h",   Q_"h2"=((k_21-1)·Δθ_"hr"·K^y)/R_"th,h"'; Where = @(
        @('Q_"h1", Q_"h2"', 'heat inputs of the two hot-spot circuits, W'),
        @('k_21', 'thermal model constant (k21)'),
        @('Δθ_"hr"', 'rated hot-spot-to-top-oil gradient, K'),
        @('y', 'winding exponent (y_wdg)'),
        @('R_"th,h"', 'analogue thermal resistance of the hot-spot circuits, K/W (a scaling choice, 1 K/W)')) },
    @{ Eq = 'C (dθ)/(dt)=Q-(θ-θ_"amb")/R'; Where = @(
        @('C', 'thermal capacity of the circuit, J/K'),
        @('θ', 'temperature of the circuit node, K'),
        @('Q', 'heat input, W'),
        @('θ_"amb"', 'ambient temperature, K'),
        @('R', 'thermal resistance to ambient, K/W')) },
    @{ Eq = 'θ_"hs"=θ_"oil"+Δθ_"h1"-Δθ_"h2"'; Where = @(
        @('θ_"hs"', 'hot-spot temperature, °C'),
        @('θ_"oil"', 'top-oil temperature, °C'),
        @('Δθ_"h1", Δθ_"h2"', 'the two hot-spot rise components, K')) },
    @{ Eq = 'V=2^[(θ_"hs"-θ_"ref")/Δθ_"d"]'; Where = @(
        @('V', 'relative ageing rate of the insulation (1 = normal)'),
        @('θ_"ref"', 'hot-spot temperature at which V = 1, °C (98 °C)'),
        @('Δθ_"d"', 'temperature rise that doubles the ageing rate, K (6 K)')) })
  Tools = @("05_Simulink_Model/build_Transformer_Operating_Model.m (builder), verify_step33.m (9 checks), params_transformer.m, run_transformer_simulation.m",
            "Simulink, Simscape, Simscape Electrical, Simscape Foundation library (nesl_utility, ee_lib, fl_lib blocks)",
            "00_Project_Admin/report_builder/update_register_step33.ps1 (register, glossary)")
  Refs = @("ST6", "SW4", "SW3")
}

$global:Closings["33"] = @{
  Achieved = @(
    ("Transformer_Operating_Model.slx was built from the Build Guide, Part B, in 05_Simulink_Model: 7 subsystems, " + $s.nBlocks + " blocks, " + $s.nNotes + " annotations; Figure 3.4 and one diagram per subsystem were exported."),
    ("The model updates and simulates without any error or warning from a clean MATLAB path; all " + $s.nChecks + " automatic checks pass."),
    ("Its structure equals the reference build: " + $s.nCompared + " blocks compared, 0 unexpected differences; the only difference is the 273.15 K offset, which is now a named variable."),
    ("The 24-hour run at rated demand gives K = " + $s.k + ", final top-oil " + $s.oil + " °C and hot-spot " + $s.hs + " °C, equal to the analytic steady state of the IEC 60076-7 equations and to the reference model."))
  Record = @(
    @("Step", "33 - Rebuild the transformer operating model"), @("Environment", "Claude Code (this chat) through the MATLAB MCP connection (roadmap role: Simulink Agentic Toolkit; D30)"),
    @("Completed", $s.completed), @("Status", "Done (D30 and clause 4 of D31 await the researcher's confirmation)"),
    @("Main inputs", "MATLAB Build Guide Part B; params_transformer.m; the reference build (rerun 2026-10-11)"),
    @("Main outputs", "05_Simulink_Model/Transformer_Operating_Model.slx; figures/Figure_3_4_top_level.png; results/step33_checks.csv"),
    @("Checks", $s.checks),
    @("Decisions", "D30 (tool route, proposed); D31 (build details; clause 4 proposed)"))
  Helps = @(
    "Step 34 runs Model Advisor on this model and the checks of Build Guide Part D1; the model is built so that every block is named and annotated, which makes the report easy to read.",
    "Step 35 verifies the model against an independent solution of the IEC 60076-7 equations at rated load and in a load step from 0.6 to 1.2 per unit (the result of this step is only the steady-state check and the reproduction of the reference model).",
    "Step 36 adds the operating scenarios and Step 37 the DGA sampling-event subsystem (which must not produce any gas value; check 6 of verify_step33.m is the test for that).")
  Open = @(
    "The thermal constants (top-oil rise 60 K, winding gradient 17 K, hot-spot factor 1.3, time constants 150 and 7 min, exponents 0.8 and 1.3, constants k11, k21, k22) are default values of an open-source implementation (Alliander), not values from IEC 60076-7:2018 or a test report: TO VERIFY. The standard was not obtained.",
    "The electrical data (40 MVA, 110/20 kV, 16.2 % impedance, 18 kW no-load loss) are published typical values of the pandapower standard type, not a real nameplate; replace them if a utility provides one. The model is therefore an illustration of operating behaviour, not a model of a particular transformer.",
    "The model is linear (no magnetic saturation), the load has unity power factor and the vector group (Delta 1 o'clock) differs from the 150 degree group listed by pandapower; none changes current magnitudes, losses or temperatures. State these assumptions in the thesis.",
    "D30 (the Simulink steps are run through the MATLAB MCP connection and not the Simulink Agentic Toolkit) and clause 4 of D31 (Simulink arithmetic blocks in SS3, SS5 and SS7, so the model is 'Simscape networks with Simulink arithmetic' and not 'pure Simscape') are proposed and need the researcher's confirmation.",
    "The dynamic accuracy (comparison with an independent solution of the differential equations in a load step, and the 63 % rise time) is verified formally in Step 35; this step checked the steady state and the equality with the reference model, which was verified in the same way earlier.",
    "The exact error text that the researcher saw in the earlier Simulink rerun has still not been supplied (the path fix of 12 October is not confirmed to be that error).")
  Exclude = @()
}

$global:StepSources["33"] = @("DF48", "DF49", "DF50", "DF51", "DF52", "DF53", "SW2", "SW3", "SW4", "ST6")
