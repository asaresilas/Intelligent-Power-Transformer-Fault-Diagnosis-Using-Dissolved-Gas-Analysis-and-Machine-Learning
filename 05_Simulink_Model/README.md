# 05 — Simulink Model

**Purpose.** Package the conventional-diagnosis layer as a Simulink model, as required by Objective 1, and provide illustrative electrical operating context.

**Scope boundary (important).** Gas concentrations are always **measured data** read from file or entered by the user. The model does **not** generate or estimate gas concentrations. The electrical subsystem (voltage, current, load, temperature) is context for demonstration and plays no part in the diagnosis or in any reported accuracy.

**Inputs.** Functions from `04_MATLAB_Conventional/`; gas vectors from `03_Data/processed/`.

**Outputs**
- `dga_conventional.slx` — gas vector in → Rogers, IEC, Duval diagnoses out (MATLAB Function blocks calling the folder-04 code).
- `electrical_context.slx` (or subsystem) — illustrative transformer operating quantities.
- `runSimulinkBatch.m` — runs the model over the dataset and saves outputs.
- Block-diagram figures exported for the thesis.

**Procedure**
1. Build the diagnosis subsystem around the verified functions (one source of truth — no re-typed logic in blocks).
2. Batch-run over the dataset; compare with `conventional_diagnoses.csv` from folder 04.
3. Build the electrical-context subsystem; label it clearly in the diagram and the thesis.

**Acceptance criteria.** Simulink output equals the folder-04 function output on 100 % of samples; model opens and runs from a clean MATLAB session.

**Requirements.** Simulink; Simscape Electrical only if the electrical-context subsystem uses it (TO CONFIRM against installed toolboxes).

**Feeds thesis.** Chapter 3 (system design, model diagrams).

---
## Step 33 (12 October 2026) - Transformer operating model, rebuilt from MATLAB Build Guide Part B

**Note.** The outline above is the early plan of this folder. The current plan is the roadmap, Stage G (Steps 33-37): the Simulink
model is the **operating-context model** (load, current, oil and hot-spot temperature, ageing). It never generates gas values (D4).
The conventional diagnosis is done by the MATLAB functions of `04_MATLAB_Conventional`, not inside this model.

| File | What it is |
|---|---|
| `Transformer_Operating_Model.slx` | The model: 7 subsystems SS1-SS7, 84 blocks, two physical networks (electrical, thermal). Opens from any folder (path-safe callbacks, D31). |
| `build_Transformer_Operating_Model.m` | Builds the model from Build Guide Part B (B2-B11) with extra annotations. Run it to recreate the .slx. Also writes `results/step33_block_settings.csv` (every block setting). |
| `verify_step33.m` | 9 automatic checks (clean-path update and run, no warning, annotations, no typed number, no gas block, one solver per network, structure = reference build, analytic steady state, result = reference). Writes `results/step33_checks.csv` and `results/step33_structure_differences.csv`. |
| `params_transformer.m` | The only place where values are defined. Step 33 added `T_zero_C_in_K` (0 degC in kelvin). Thermal constants are default values of an open-source implementation: **TO VERIFY** against IEC 60076-7:2018. |
| `run_transformer_simulation.m` | Runs the model and returns t_h, K_pu, theta_oil_C, theta_hs_C, ageing_V, loss_of_life_h (and the sampling events). Optional arguments (17 Oct 2026): a load profile and `opts.t_stop_s` / `opts.t_sample_s` for the dashboard scenarios; the saved model is not changed. |
| `figures/Figure_3_4_top_level.png` | Figure 3.4 (top level). `figures/diag_SS1...SS7_*.png`: one diagram per subsystem. |
| `code_manifest_step33.sha256` | SHA-256 of the three Step 33 code files. |
| `reference_build/` | The earlier reference build and its re-run (2026-10-11): used only to check the new model. |

**How to rebuild and check (MATLAB R2025b with Simulink, Simscape, Simscape Electrical):**
```matlab
cd 05_Simulink_Model
build_Transformer_Operating_Model     % writes Transformer_Operating_Model.slx
verify_step33                         % 9 checks, all must pass
res = run_transformer_simulation();   % 24 h run, ~10 s
```
**Model in one paragraph.** SS1 ideal 110 kV source -> SS2 40 MVA Delta/grounded-Wye transformer -> SS3 current sensor (load factor K_pu) -> SS4
resistive load following `load_profile`. K_pu feeds SS5 (losses -> heat inputs Q_oil, Q_h1, Q_h2), SS6 (three thermal R-C circuits, Simscape
Foundation) and SS7 (hot-spot temperature, relative ageing rate, logging). The arithmetic sits in Simulink blocks because the electrical
network uses the 'Frequency and time' formulation, which accepts only switched-linear equations (decision D31, clause 4).

---
## Step 34 (13 October 2026) - Model checks
Model Advisor (132 checks: 120 passed, 11 warnings, 1 incomplete, 0 failed) and Build Guide Part D1 checklist; see `checks/README.md`.
Changed in this step (decision D32): `Transformer_Operating_Model.slx` (Sqrt block, diagnostics at error level, Exp name shown, variable `X0_pu`),
`build_Transformer_Operating_Model.m`, `verify_step33.m` (now 7 expected differences from the reference build; 9/9 pass), `params_transformer.m`
(new `X0_pu`, units and source tags). The Step 33 model is kept as `checks/Transformer_Operating_Model_before_step34.slx`.
Current fingerprints: `code_manifest_step34.sha256` (the Step 33 manifest is the record of 12 October).

---
## Step 35 (13 October 2026) - Verification against IEC 60076-7
`verify_step35.m` (decision D33): two 24 h tests (rated load; load step 0.6 -> 1.2 pu at 6 h) against the IEC equations solved with ode15s and against the closed form for constant K; 15 checks, all PASS. e_max after 10 min (RelTol 1e-4): top-oil 0.0014 / 0.0015 K, hot-spot 0.0129 / 0.0152 K (limit 0.1 K); 63.2 % rise time 75.002 min (expected 75.000). Whole-run hot-spot difference up to 0.033 K. (With the default RelTol 1e-3 the result was 0.104 K after Step 37 - see Step 37 below.)
Outputs: `results/step35_verification_log_2026-10-13.txt`, `results/step35_checks.csv`, `results/step35_sdi_session.mldatx`; `11_Results/tables/T4_10_simulink_verification.csv`; `11_Results/figures/F4_18_simulink_verification.(png|pdf|csv)`. Fingerprint: `code_manifest_step35.sha256`.
Run: `cd 05_Simulink_Model; verify_step35`.

---
## Step 36 (13 October 2026) - Operating scenarios
`scenarios.m` (decision D34) defines three illustrative load histories (constant rated load; daily cycle repeated 3 days, last day shown; short overload 1.3 pu for 2 h) - every number a named variable. `run_step36.m` simulates each twice from a fresh start, saves `results/sim_rated|daily|overload.mat`, a Simulation Data Inspector session, `step36_scenario_summary.csv`, `step36_scenario_definitions.csv`, `step36_checks.csv` (13/13 PASS) and Figure 4.19 (`11_Results/figures/F4_19a|b|c_*`). Peak hot-spot 100.3 / 99.9 / 129.0 degC; loss of life 27.88 / 6.45 / 38.58 h. Run: `cd 05_Simulink_Model; run_step36`. Fingerprints: `code_manifest_step36.sha256`.

---
## Step 37 (13 October 2026) - DGA sampling-event subsystem SS8
Decision D35. SS8 (13 blocks, no ports, not connected to SS1-SS7) outputs `record_index` and `sampling_event` at `t_sample_h` (6, 12, 18, 22 h; illustrative) and never a gas value; `get_sampling_events.m` looks up the held-out `record_id` from `dga_master.csv` (only columns `record_id`, `data_role`). `verify_step37.m`: 10 checks, all PASS (`results/step37_*.csv`). The model now has 8 subsystems.
**Solver tolerance.** `params_transformer.m` has `solver_reltol = 1e-4` (default RelTol 1e-3 left 0.104 K hot-spot error after SS8 was added; 1e-4 gives 0.013 K). Steps 33, 35, 36, 37 and the Step 34 checks were re-run on this model. Old Step 36 results: `results/before_step37/`. Fingerprints: `code_manifest_step37.sha256`.
Run: `cd 05_Simulink_Model; verify_step37`.