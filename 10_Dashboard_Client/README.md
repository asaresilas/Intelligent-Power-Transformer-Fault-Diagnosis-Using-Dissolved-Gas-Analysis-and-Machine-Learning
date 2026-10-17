# 10 — Diagnostic Dashboard (MATLAB Client)

**Purpose.** Objective 4: show the conventional and ML diagnoses side by side to an engineer.

**Status.** Built and checked in roadmap Step 39 (13 Oct 2026), design fixed in decision D37. The conventional diagnoses
(Rogers, IEC 60599, Duval) are computed here in MATLAB (folder 04); the ML diagnosis comes from the FastAPI service
(folder 09, Step 38) through `webwrite`. This replaces the 30 Sep plan in this README (`apiClient.m`, conventional results from the API).

**Inputs.** Running service on 127.0.0.1:8000 (`09_API_FastAPI\run_service.ps1`); `03_Data/processed/dga_master.csv` (or any file with
the columns H2, CH4, C2H6, C2H4, C2H2 [ppm], optional `record_id`, `equipment_type`); `02_Standards/duval_triangle_zones.csv`;
the Simulink model (`run_transformer_simulation`).

**Start.** `project_setup` (project root) then `DGADashboard` in the MATLAB Command Window. Start the service first if you want the ML row.

| File | What it is |
|---|---|
| `DGADashboard.mlapp` | The app (App Designer file). Components and callbacks as in MATLAB_Build_Guide Part C, plus `ProbabilityTable`, `ModelLabel` (D37). |
| `dga_agreement.m` | The agreement flag: green all three conventional methods agree with ML, amber at least one does not, grey ML not available. D1/D2 agrees with D1 or D2; DT and ND never agree (D11, D25, D37). |
| `ml_diagnose.m` | Client of `POST /diagnose`: checks the five gases locally, calls `webwrite`, returns status `OK`, `NOT_CONNECTED`, `INVALID_INPUT: ...` or `ERROR: ...`; never stops the program. |
| `load_dga_record.m` | Reads one record of a DGA file as it is (also `record_id` and `equipment_type` if present). Never creates or changes a gas value. |
| `find_dga_row.m`, `verify_step40.m` | Step 40 (D38): row of a record_id in a DGA file; checks of the model-to-dashboard link (13 checks, includes the 19 of Step 39). Run Simulation now plays the sampling events of the model back and diagnoses the record of each. |
| `verify_step39.m` | The Step 39 checks (writes `results/step39_*.csv`). Needs the service running. |
| `tools/build_dashboard_mlapp.m`, `tools/DGADashboard_code.txt` | Writes `DGADashboard.mlapp` from the component list and the hand-written code (App Designer cannot be driven from code; internal serializer of R2025b). Open the .mlapp once in App Designer to confirm and to save it with the editor. |
| `run_testbench.m`, `verify_step41.m`, `tools/make_figure_4_20.m` | Step 41 (D39): runs model + dashboard functions + service over all 388 held-out records and writes `logs/testbench_log.csv` (one row per record: answers, probabilities, three times); 12 checks; Figure 4.20. Needs the service running. |
| `tools/make_figure_4_22.m` | Figure 4.22, the annotated screenshot (`11_Results/figures/F4_22_*`). |
| `DGADashboard_reference.m` | The programmatic reference version of the Build Guide (unchanged). |

**What the app never does.** Show a diagnosis that was not computed; generate or alter gas values; present the simulated operating
temperature as the cause of the measured gases (the simulation is context only). When the service is down or the values are invalid
it shows a status text and keeps the conventional answers.

**Feeds thesis.** Chapter 3 (dashboard design), Chapter 4 (demonstration, Figure 4.22), Appendix (user guide).

**Update 15 Oct 2026.** The app no longer needs `project_setup` first: at start-up it searches upwards from the app file (then from the current folder) for `project_setup.m`, adds folders 04, 05 and 10 to the path and loads `params_transformer`. See `code_manifest_autopath_2026-10-15.sha256`; the previous app is in `tools/backup_before_autopath/`.

**Update 15 Oct 2026 - master control, freeze fix, explanation panel (D42).** Start the dashboard with `DGADashboard`; nothing else has to be started.
- *Why it froze (measured):* the ML service was started with `system()` and shared MATLAB's output pipe; after about 60 requests the 4 KB pipe was full, the service blocked and MATLAB waited for it (request 62 waited 248.4 s). The first simulation in a session also took 54 s (model compile) without any message. Details: `results/step43_freeze_analysis.md`.
- *Fix:* `ensure_ml_service.m` starts the service through `09_API_FastAPI/launch_service_detached.ps1` (no shared handles, log in `09_API_FastAPI/logs/service.log`) and replaces a service that holds port 8000 but does not answer; `stop_ml_service.m` runs `stop_service.ps1`. The app checks `/health` before every diagnosis, disables the buttons while a step runs, shows progress windows, prepares the Simulink model at start-up, has a **Restart ML service** button, and stops the service on close when it started it.
- *Explanation panel* ("How to read this result", right side): `dashboard_explain.m` writes plain-language text from the program values: the simulation (peak temperatures, ageing), each method's answer, ML class and probability, the agreement lamp, the fault types (IEC 60599) and how much to trust the result. Click an event row to see its explanation.
- *Checks:* `verify_step43` (23 checks; also runs `verify_step39` and `verify_step40`; takes about 20 min). Code fingerprints: `code_manifest_masterctl_2026-10-15.sha256`; previous app and code: `tools/backup_before_masterctl/` (its `ensure_ml_service.m` and `stop_ml_service.m` are already the new versions; the old version is described in the freeze analysis).

**Update 17 Oct 2026 - redesign: verdict, scenarios, sample sets, record picker (D43).** The researcher found that the app showed numbers only, always the same four samples (all PD), and no comparison, no healthy/fault state and no interpretation. The screen now answers first.
- *Banner:* green HEALTHY, red FAULT with the type, amber WATCH or CHECK; why, and what to do (`dashboard_verdict.m`; rule in decision D43: every method gives one vote, D1/D2 votes for both, DT and ND do not vote, the verdict needs at least two votes).
- *Five cards:* Rogers, IEC 60599, Duval Triangle 1, machine learning, and the known label of the record (when the data file has one). Each method card says AGREES / DIFFERS / NO VERDICT / NO ANSWER and, if a label is known, whether the method was right.
- *Procedure:* tab "Step by step" follows IEC 60599 / IEEE C57.104-2008 with the numbers of the sample (typical values, ratios, three rulebooks, ML, vote). Tab "Explanation in words" keeps the plain-language text of D42.
- *Variety:* drop-down 1 = operating condition (constant rated load, daily load cycle with 3 days simulated and the last day shown, short overload; `scenarios.m`); drop-down 2 = samples (MIXED = healthy + every fault type, 7 samples, a new set at each press; RANDOM 7; FIRST 4 = the Step 40 test run). "Pick random record" with a fault-type drop-down chooses one held-out record of that known class.
- *Sample table:* one row per sample with known label, the four answers, agreement count and verdict; click a row to look at it.
- *New files:* `dashboard_verdict.m`, `dashboard_samples.m`, `sim_window.m`, `test_dashboard_verdict.m`, `verify_step44.m` (18 checks), `tools/dashboard_components.m` (component list, used by `build_dashboard_mlapp.m`); `run_transformer_simulation(profile, opts)` accepts `opts.t_stop_s` and `opts.t_sample_s` (the saved Simulink model is unchanged). Previous app and code: `tools/backup_before_redesign/`.
- *Checks:* `verify_step44` (18), `test_dashboard_verdict` (10); `verify_step40` and `verify_step43` select the 4-record test run (`SampleSetDropDown.Value = 'first'`) and still apply.