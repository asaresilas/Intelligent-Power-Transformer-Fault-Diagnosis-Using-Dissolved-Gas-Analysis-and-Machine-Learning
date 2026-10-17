# report_entries_35.ps1 - "Method used" and closing entries for roadmap Step 35 (report standard 2026-10-10/11).
# Result numbers are NOT typed here: the builder fills $global:S35 from the result files before dot-sourcing.
# Saved as UTF-8 with byte-order mark (equations contain Greek letters).

$s = $global:S35
$global:Methods["35"] = @{
  Approach = @(
    "Verification means asking: does the model solve the equations it claims to solve? The model was run for 24 hours in two tests, and its top-oil and hot-spot temperatures were compared, point by point, with calculations that do not use the Simscape model at all.",
    "Reference A solves the IEC 60076-7 differential equations (Equations 1 to 4 below) with a numerical solver (ode15s, very tight tolerances), using the load factor K(t) that the model itself measured. Reference B (rated-load test only) uses the exact formula that the same equations give for a constant load (Equation 5), so it needs no solver at all. Reference A was also compared with reference B, to show that the reference itself is accurate.",
    "Test 1 is rated load from a cold start (all temperatures equal to the ambient 20 degC). Test 2 is a load step from 0.6 to 1.2 per unit after 6 hours. Two further checks were made: the time for the top-oil rise to reach 63.2 % must equal k11 times the oil time constant (75 minutes), and the ageing rate V must follow its formula for the reference hot-spot temperature. The numbers of the 3 October reference build were reproduced as a baseline.")
  Why = @(
    "Comparing a model with an independent solution of its own equations is the standard way to verify (not validate) a simulation model: it shows that the blocks were assembled correctly and that the numerical settings are adequate.",
    "Two independent references, one numerical and one exact, protect against a mistake in either of them: they agree to better than a billionth of a kelvin for the top oil, so any difference to the model is the model's.",
    "Excluding the first 10 minutes follows the approved Analysis Plan (Equation 45) and the 3 October baseline; the start-up transient is reported separately and openly.",
    "The 63 % rise time is a sharp test of the oil time constant, because it depends only on k11 and tau_o and on the thermal capacity and resistance chosen in the model.")
  Settings = @(
    @("Tests", "Test 1: rated demand, cold start, 24 h. Test 2: demand 0.6 pu, then 1.2 pu after 6 h (1 s ramp), 24 h"),
    @("Reference A", "ode15s, relative and absolute tolerance 1e-8, maximum step 30 s, driven by the model's measured K(t)"),
    @("Reference B", "closed form for constant K (Test 1 only; K = mean of the logged K after 1 h)"),
    @("Solver", "ode23t, RelTol 1e-4 (variable solver_reltol), maximum step 60 s"),
    @("Compared points", ("the model's own logged time points after 600 s (10 min), reference evaluated there: " + $s.M1 + " in Test 1, " + $s.M2 + " in Test 2")),
    @("Tolerance", "e_max <= 0.1 K for top-oil and hot-spot temperature in both tests (approved, Analysis Plan Section 9)"),
    @("Rise-time criterion", "63.2 % (1 - 1/e) of the analytic steady-state oil rise; within 1 min of k11 x tau_o (decision D33)"),
    @("Ageing-rate criterion", "relative difference <= 2^(0.1/6) - 1 = 1.16 % (the ageing rate that 0.1 K causes; D33)"),
    @("Software", ("MATLAB " + $s.matlab + ", Simulink, Simscape, Simscape Electrical")))
  Eqs = @(
    @{ Eq = 'k_11 τ_o (dθ_o)/(dt)=[(1+K^2 R)/(1+R)]^x Δθ_"or"-(θ_o-θ_a)'; Where = @(
        @('θ_o', 'top-oil temperature, °C'),
        @('θ_a', 'ambient temperature, °C (20 °C)'),
        @('t', 'time, s (the equation holds in any consistent time unit)'),
        @('k_11, τ_o', 'oil thermal-model constant (0.5) and oil time constant (150 min)'),
        @('K', 'load factor, per unit'),
        @('R', 'ratio of load loss at rated current to no-load loss (P_k / P_0), dimensionless'),
        @('x', 'oil exponent (0.8)'),
        @('Δθ_"or"', 'top-oil rise above ambient at rated load, K (60 K)')) },
    @{ Eq = 'k_22 τ_w (dΔθ_"h1")/(dt)=k_21 Δθ_"hr" K^y-Δθ_"h1"'; Where = @(
        @('Δθ_"h1"', 'first component of the hot-spot-to-top-oil gradient, K'),
        @('k_21, k_22', 'winding thermal-model constants (both 2)'),
        @('τ_w', 'winding time constant (7 min)'),
        @('Δθ_"hr"', 'hot-spot-to-top-oil gradient at rated load, K (hot-spot factor times winding gradient)'),
        @('y', 'winding exponent (1.3)')) },
    @{ Eq = '(τ_o)/(k_22) (dΔθ_"h2")/(dt)=(k_21-1) Δθ_"hr" K^y-Δθ_"h2"'; Where = @(
        @('Δθ_"h2"', 'second component of the hot-spot-to-top-oil gradient, K'),
        @('', 'all other symbols as in the two equations above.')) },
    @{ Eq = 'θ_h=θ_o+Δθ_"h1"-Δθ_"h2"'; Where = @(
        @('θ_h', 'hot-spot temperature, °C')) },
    @{ Eq = 'θ_o (t)=θ_a+Δθ_"o,∞" (1-e^(-t/(k_11 τ_o)))'; Where = @(
        @('Δθ_"o,∞"', 'steady-state top-oil rise for the constant K, K = [(1+K^2 R)/(1+R)]^x Δθ_"or"'),
        @('', 'the two winding components follow the same exponential form with their own time constants k_22 τ_w and τ_o / k_22 (closed form B).')) },
    @{ Eq = 'e_"max"=max_t |θ_"sim" (t)-θ_"ref" (t)|,    "RMSE"=√(1/M ∑_(m=1)^M (θ_"sim" (t_m)-θ_"ref" (t_m))^2)'; Where = @(
        @('e_"max"', 'largest absolute difference between model and reference, K'),
        @('θ_"sim", θ_"ref"', 'temperature from the Simulink model and from the reference, °C'),
        @('t_m, M', 'the compared time points (after 10 min) and their number'),
        @('RMSE', 'root-mean-square difference, K')) })
  Tools = @("05_Simulink_Model/verify_step35.m (runs both tests, both references, 15 checks, Table 4.10, Figure 4.18, SDI session)",
            "MATLAB ode15s; Simulink.SimulationInput; Simulink.sdi (Simulation Data Inspector); exportgraphics",
            "Colours and line styles read from 11_Results/figures/plot_style.csv (never typed)",
            "00_Project_Admin/report_builder/update_register_step35.ps1 (register, glossary)")
  Refs = @("ST6", "SW4", "DF53")
}

$global:Closings["35"] = @{
  Achieved = @(
    ("The model was verified against two independent solutions of the IEC 60076-7 equations in two 24-hour tests; all " + $s.nChecks + " checks pass (decision D33)."),
    ("Largest difference after 10 minutes: top-oil " + $s.o1 + " K and hot-spot " + $s.h1 + " K at rated load; " + $s.o2 + " K and " + $s.h2 + " K in the load step; the limit is 0.1 K."),
    ("The top-oil 63.2 % rise time is " + $s.t63 + " min against k11 x tau_o = 75.000 min."),
    ("The numbers of the 3 October baseline are reproduced: K " + $s.K1 + ", final top-oil " + $s.oil + " degC and hot-spot " + $s.hs + " degC (rated load); " + $s.hs2 + " degC hot-spot after the step."),
    "Table 4.10 and Figure 4.18 were produced, and both runs were stored in a Simulation Data Inspector session.")
  Record = @(
    @("Step", "35 - Verify against IEC 60076-7"), @("Environment", "Claude Code (this chat) through the MATLAB MCP connection (roadmap role: Simulink Agentic Toolkit; D30)"),
    @("Completed", $s.completed), @("Status", "Done"),
    @("Main inputs", "Transformer_Operating_Model.slx (as after Step 34); params_transformer.m; Analysis Plan Section 9"),
    @("Main outputs", "results/step35_verification_log_2026-10-13.txt, step35_checks.csv, step35_sdi_session.mldatx; 11_Results/tables/T4_10_simulink_verification.csv; 11_Results/figures/F4_18_simulink_verification.(png|pdf|csv)"),
    @("Checks", $s.checks),
    @("Decisions", "D33 (test design, measures, additional criteria; amendment of 13 October 2026)"))
  Helps = @(
    "Step 36 runs the approved operating scenarios (constant rated load, a daily load cycle, a short overload) on a model whose thermal and ageing chain now agrees with the IEC 60076-7 equations to within 0.1 K. Its figures (Figure 4.19) can be read as the equations' answer for those loads.",
    "Step 37 added the sampling-event subsystem; the verification program was run again on the final model and passes, so the temperatures are those of the equations.",
    "Chapter 3 can state the verification result with Table 4.10 and Figure 4.18, together with the limits below.")
  Open = @(
    "The verification shows that the model solves the equations with the constants in params_transformer.m. It does not show that those constants are right: they are default values of an open-source implementation, not values from IEC 60076-7:2018 (not obtained) or a test report: TO VERIFY. No measured temperatures of a real transformer were used, so this is verification, not validation.",
    ("Over the whole run the hot-spot temperature differs from the reference by up to " + $s.hsWhole + " K (at " + $s.hsAt + " s, in the first minutes); the approved rule compares from 10 minutes onwards. The reference is driven by the logged load factor, which changes fast in the first seconds. The result depends on the solver tolerance: with RelTol 1e-3 the Test 1 difference after 10 minutes was 0.104 K, above the limit; with 1e-4 it is well below. A user who loosens the tolerance must repeat this verification."),
    "The reference is driven by the model's own measured load factor, so the electrical network that produces K is not tested here; it was compared with the reference build and with the steady-state calculation in Step 33.",
    "The tolerances for the rise time (1 min) and the ageing rate (1.16 %) are proposals of decision D33; the 0.1 K tolerance is the approved one.",
    "The Simulation Data Inspector session is a binary file whose hash changes with every save.",
    "The researcher's error text from the earlier Simulink rerun has still not been supplied.")
  Exclude = @()
}

$global:StepSources["35"] = @("ST6", "SW4", "DF48", "DF52", "DF53", "DF59", "DF60", "DF61", "DF62", "DF63")
