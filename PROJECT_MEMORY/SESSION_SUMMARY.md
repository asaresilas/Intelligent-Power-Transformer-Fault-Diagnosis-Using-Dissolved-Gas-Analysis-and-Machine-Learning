# Session Summary — Work Done with Claude (30 Sep – 8 Oct 2026)

Readable record of the whole chat session, so the work can continue on another computer or SSD.
The full original chat is in `chat_transcript/chat_session_2026-09-30_to_2026-10-08.zip`.

## 1. Project in one paragraph
MPhil thesis, University of Mines and Technology (UMaT), Tarkwa; supervisor Prof. John Annan.
Title: "Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning:
An Integrated MATLAB/Simulink–Python Framework". Conventional DGA methods (Rogers Ratio, IEC 60599 ratio,
Duval Triangle) are compared with machine-learning classifiers on real measured DGA data with independently
confirmed faults. The study also tests accuracy with fewer gases and statistically tests where the two
approaches disagree. A Simulink/Simscape transformer model (operating context only, it never generates gas
values), a FastAPI service and a MATLAB dashboard tie it together.

## 2. Chronology
| Date | Request | Result |
|---|---|---|
| 30 Sep | Review the two Word documents, plan the project, create folders with READMEs, find datasets | Folders 00–13 with READMEs; `PROJECT_PLAN.md`; `00_Project_Admin/decisions_log.md` (7 open decisions) |
| 30 Sep | Detailed methodology in Word (12 pt, 1.5 spacing), MATLAB/ML roles, novelty, beneficiaries | `00_Project_Admin/Project_Methodology_Plan.docx` (23 pages) |
| 1–2 Oct | Download links for datasets; user found them paid | Explained IEEE DataPort "Standard" datasets need a subscription (free for IEEE Society members); found free Mendeley alternatives |
| 2 Oct | Letter to Prof. Annan asking for the 3 datasets, with links | `00_Project_Admin/Dataset_Request_Letter_Prof_Annan.docx` |
| 3 Oct | MATLAB build guide (12 pt, 1.15 spacing): MATLAB code, Simulink with pure Simscape blocks, App Designer; parameters in .m; annotations; R2025b | `00_Project_Admin/MATLAB_Build_Guide.docx` (29 pages) + tested code (see Section 4) |
| 7 Oct | Short access-request messages to the two DataPort authors | Texts in Section 6 below |
| 8 Oct | Memory for the project; then this portable memory folder | Claude memory notes + this folder |

## 3. Key decisions (proposed; confirm with supervisor — see decisions_log.md)
- Thesis Chapter 1 objectives govern; the reduced-gas study from the overview brief is added. The six unified objectives are in the methodology plan.
- Five gases (H2, CH4, C2H6, C2H4, C2H2), because the public datasets have no CO/CO2. Six IEC fault classes; Normal class only if the data support it.
- Simulink models electrical + thermal operating behaviour only; gas values always come from real records ("measured-DGA playback").
- Only data with method-independent labels enter the ML-vs-conventional benchmark.
- Open: author name and degree differ between the two original documents (BSc "Justice" vs MPhil "Jacob Addo Tagoe"); 5th classifier (XGBoost vs Gradient Boosting).

## 4. MATLAB work (verified in MATLAB R2025b on 3 Oct 2026)
- Model: 7 subsystems — SS1 110 kV grid, SS2 40 MVA 110/20 kV transformer, SS3 current and load factor K, SS4 variable load, SS5 losses to heat, SS6 Simscape thermal network (IEC 60076-7 equations as R-C circuits), SS7 outputs and ageing.
- Parameter sources: pandapower standard type "40 MVA 110/20 kV" (electrical); Alliander transformer-thermal-model ONAF defaults (thermal; check against IEC 60076-7 when obtained); IntechOpen chapter Table 1 (ageing rate).
- Verification: Simscape model vs independent solution of the IEC equations — max difference 0.061 K (rated load), 0.031 K (load step 0.6 → 1.2 pu). Rated load from 20 °C ambient: top-oil 78.64 °C, hot-spot 100.28 °C, top-oil time constant 75 min.
- Code files: `project_setup.m`; `05_Simulink_Model/params_transformer.m`, `run_transformer_simulation.m`, `reference_build/*`; `04_MATLAB_Conventional/gas_ratios.m`, `duval_xy.m`, `conventional_diagnosis.m`, `plot_duval_triangle.m`; `10_Dashboard_Client/load_dga_record.m`, `ml_diagnose.m`, `DGADashboard_reference.m`.
- Lessons: Specialized Power Systems is missing in R2025b General Release; "Frequency and time" solver needs linear equations (math in Simulink blocks); one Solver Configuration per physical network; thermal masses must start above 0 K; Connection Port numbers are unique across both sides; when drive C: was full, MATLAB stopped recording results.

## 5. Datasets
| Dataset | Link | Status |
|---|---|---|
| IEC TC 10 (Duval & dePablo 2001, IEEE EIM 17(2):31–41) | https://ieeexplore.ieee.org/document/917529 | Paywalled; requested via Prof. Annan |
| IEEE DataPort "DGA dataset" (Dissanayake 2026), DOI 10.21227/27vy-h479 | https://ieee-dataport.org/documents/dga-dataset | Paywalled; message to author drafted |
| IEEE DataPort "Dissolved gas data in transformer oil" (Li 2019), DOI 10.21227/h8g0-8z59 | https://ieee-dataport.org/documents/dissolved-gas-data-transformer-oil-fault-diagnosis-power-transformers-membership-degree | Paywalled; message to author drafted |
| Mendeley: Power transformer data for fault diagnosis (Costa Rica), DOI 10.17632/98f4z3f8tx.2 | https://data.mendeley.com/datasets/98f4z3f8tx/2 | Free (CC BY 4.0); label origin still to check |
| Mendeley: DGA results for 25 transformers (Ukraine), DOI 10.17632/x22y4s9fks.1 | https://data.mendeley.com/datasets/x22y4s9fks/1 | Free (CC BY 4.0); small external test set |
| Mendeley: DGA Method Fusion, DOI 10.17632/phs5wyfbph.2 | https://data.mendeley.com/datasets/phs5wyfbph/2 | Labels come from conventional methods, so not usable for the benchmark |

## 6. Messages drafted
**To Dissanayake** — Subject: Request for Access to "DGA dataset" (DOI 10.21227/27vy-h479) for MPhil Research.
Asks for access (no DataPort subscription), academic use only, full citation, no redistribution, and asks how the
labels were established and how the training file was balanced.

**To Enwen Li** — Subject: Request for Access to "Dissolved gas data in transformer oil" (DOI 10.21227/h8g0-8z59)
for MPhil Research. Same structure; asks how fault types were confirmed.

## 7. Data obtained (8 Oct 2026)
Downloaded one IEEE DataPort dataset over S3 (AWS CLI installed via winget; user supplied DataPort AWS key —
first key rejected, regenerated). Stored under the verifiable S3 id, not a guessed DOI:
`03_Data/raw/ieee_dataport_1375187/` — `DGA_train.xlsx` (31,092 B), `DGA_test_unseen.xlsx` (11,414 B),
`IEC_TC_10_data.xlsx` (10,988 B). Sizes verified vs S3; SHA-256 in `03_Data/provenance/data_card_ieee_dataport_1375187.md`.
S3 source: `s3://ieee-dataport/data/1375187/101218/`. TO VERIFY: which DataPort DOI this id maps to (guessed Dissanayake,
unconfirmed), licence, label origin, gases/units, per-class counts, train/test↔IEC TC 10 overlap, benchmark eligibility.

Second DataPort dataset (S3 id 7226): `03_Data/raw/ieee_dataport_7226/DGA dataset.xlsx` (19,071 B, S3 timestamp 2019-01-14).
Size verified; SHA-256 in `03_Data/provenance/data_card_ieee_dataport_7226.md`. S3 source `s3://ieee-dataport/data/7226/DGA dataset.xlsx`.

IDENTITIES CONFIRMED (8 Oct 2026, verified file contents vs DataPort pages):
- S3 1375187 = **Dissanayake, "DGA dataset," 2026, DOI 10.21227/27vy-h479.** Three files, 5 gases (H2,CH4,C2H6,C2H4,C2H2),
  numeric Fault class 0–6 = Normal, PD, D1, D2, T1, T2, T3. Counts: train 584 (imbalanced), test 70 (10/class, balanced),
  IEC_TC_10 49 (a subset, NOT the full IEC TC 10 database).
- S3 7226 = **Enwen Li, "Dissolved gas data in transformer oil," 2019, DOI 10.21227/h8g0-8z59.** 201 records,
  columns NM,H2,CH4,C2H6,C2H4,C2H2,Type; TEXT labels (Arc/Spark discharge, PD, High/Middle/Low-temp overheating).
  CONCERN: "Membership Degree" title suggests method-derived labels → benchmark eligibility doubtful (TO VERIFY); taxonomy
  differs from the IEC 0–6 scheme (needs a documented mapping before combining).

So the "main three" = Dissanayake DGA dataset (incl. its IEC TC 10 subset) + Li 2019. All physically downloaded and identified.

FULL IEC TC 10 database obtained separately (8 Oct 2026): the IEC TC 10 is NOT a DataPort/S3 dataset — it is Annex 1 of the
Duval & dePablo 2001 paper. User provided the PDF; transcribed Annex 1 Tables 2–6 to
`03_Data/raw/iec_tc10_duval2001_full/iec_tc10_faulty_equipment.csv` — 117 inspection-confirmed cases (PD 9, D1 26, D2 48,
T1/T2 16, T3 18), 7 gases incl. CO/CO2, labels by visual inspection (method-independent → good for the benchmark).
Caveats: MANUAL transcription (now cross-checked cell-by-cell and FULLY VERIFIED, incl. user confirming the one undashed
cell = CO2 784 / CO blank); T1 vs T2 not separable from Annex 1; mixed equipment types (filter to P/U for power
transformers); units assumed ppm. The Dissanayake 49-row IEC file is likely a reduced subset of this.
Data card: `03_Data/provenance/data_card_iec_tc10_duval2001_full.md`.

PROJECT ROADMAP v2 (9 Oct 2026, replaces v1 of the same day): `00_Project_Admin/Project_Roadmap.docx` — 45 strictly
sequential steps, each tagged with ONE environment: Claude Code (data prep, Python, ML, stats, FastAPI, docs — 28 steps),
MATLAB Agentic Toolkit (all MATLAB programming — 8), Simulink Agentic Toolkit (all Simulink/Simscape blocks — 7),
approval gates (Steps 4 and 45). Stages: A setup (1–4), B data prep (5–13), C conventional methods in MATLAB (14–17),
D ML (18–24), E reduced-gas (25–27), F statistics (28–32), G Simulink model (33–37), H integration (38–42), I writing (43–45).
Environments sync only via hand-over files (record_id; gases H2,CH4,C2H6,C2H4,C2H2 in ppm; class codes 0–6).

EXPECTED RESULTS AND ANALYSIS PLAN (9 Oct 2026): `00_Project_Admin/Expected_Results_and_Analysis_Plan.docx` — for
approval at Step 4; no results. Fixes primary measure (macro-F1), main benchmark (IEC TC 10 scored on 5 merged classes),
data roles, missing-value rule, tests (Cochran's Q → McNemar + Holm; Friedman/Nemenyi + corrected resampled t; kappa;
logistic regression of disagreement on boundary distance), CIs (Wilson; bootstrap B = 2000), reduced-gas tolerance
δ = 0.05, Simulink tolerance 0.1 K, API fidelity 100 % / p95 < 1 s — all PROPOSED, awaiting approval (16-item checklist).
Key caveat recorded: IEC 60599 ratio limits were refined using the IEC TC 10 data (Duval & dePablo 2001, p. 32) →
conventional methods have a "home advantage" on that benchmark.
Version 2 (10 Oct 2026): every one of the 47 equations has a "where:" symbol list with units; 26 figures specified
(Figs 3.1–3.4, 4.1–4.22: chart type, axes/units, colours, data file, environment + roadmap step, how to read);
fixed colours/markers in a shared `11_Results/figures/plot_style.csv` (written Step 13, read by Python and MATLAB);
Duval DT-zone rule (counts as wrong, reported separately) added for approval. Roadmap step outputs now cite figure numbers.

## 8. Next steps (follow Project_Roadmap.docx v2)
1. ~~Step 1 [Claude Code]~~ DONE 10 Oct 2026: Python 3.12.10, venv `06_Python_ML/.venv`, pinned `requirements.txt`,
   check script `06_Python_ML/src/check_environment.py` passes (16/16 libraries).
2. Steps 2–3 [MATLAB / Simulink Agentic Toolkits]: PENDING (instructions given to the user 10 Oct).
3. ~~Step 4~~ recorded 10 Oct: researcher approved the plan (supervisor sign-off not recorded). Later decisions D8
   (not available = 0 ppm, replaces item 4) and D9 (test records duplicating benchmark cases flagged) — see decisions_log.md.
4. ~~Steps 5–11~~ DONE 10 Oct (see CHANGELOG): master table 827 records (development 439, internal test 70 [61 independent],
   IEC TC 10 benchmark 117 [58 power transformers = primary], Li external 201 [86 independent]); folds.csv (5×10, seed
   20261010, near-duplicate groups kept together); 9/9 pytest checks pass; Tables 4.1–4.2, Figures 4.1–4.3 made.
   Key findings: Dissanayake 0.0001 placeholders; Dissanayake train contained 96 IEC TC 10 cases (removed); Li 2019 =
   115 IEC TC 10 cases + 86 others; Dissanayake labels contradict inspection on 4 IEC T1/T2 cases (D7 closed).
5. Step 12 (10 Oct) — standards tables, from legitimate online sources only (`02_Standards/sources.md`):
   - IEC ratio table (Ed. 2.1 Table 2, p.11) + simplified Table 3 + Table A.2 (AMD1:2007): PRIMARY, from official iTeh
     previews; 2015 change list excludes 5.4 and A.2.4, 2022 changed only A.3/A.5 → used as current, TO VERIFY vs 2022 text.
   - Duval Triangle 1: SECONDARY (Moser 2025 HV Assets Table 1 citing IEEE C57.104-2019 §6.2.3 + Manisha et al. 2022 IOP
     CC BY Fig. 2 labels) — 10 rules, cover the triangle with 0 gaps/0 overlaps, reproduce 39/39 printed diagnoses.
   - Rogers: two secondary versions DISAGREE (Rangel Bessa 2023 T4 vs Aciu 2021 T3) → D10 OPEN: obtain IEEE C57.104 or drop.
   - Files: `iec_ratio_table.csv`, `iec_typical_values.csv`, `duval_triangle_zones.csv`, `rogers_ratio_table.csv`,
     `worked_examples.csv`, `transcription_check.md` (all 6 checks PASS), script `06_Python_ML/src/standards/step12_check_tables.py`.
   - Step reports for Steps 1, 4–11 built (`00_Project_Admin/Step_Reports/`); Step 12 report written.
     Word quirk: SaveAs2 hangs when called inside a PowerShell function — inline it (see memory note).
   - Reports extended on request: each now ends with What was achieved / Record of this step / How this helps the next
     steps / Open items / Abbreviations (from `00_Project_Admin/abbreviations_glossary.csv` — reuse for the thesis List
     of Abbreviations). label_map.csv has 33 rows (earlier "25" was wrong; corrected).
   - DATA AND SOURCE REGISTER (10 Oct): `03_Data/provenance/data_and_source_register.csv` (IDs DS1–DS5, ST1–ST5,
     P1–P5, SW1, DF1–DF5) + `Step_Reports/Data_and_Source_Register.docx`; every step report has a "Data and sources
     used in this step" section. Reproducibility test: Steps 5–12 re-run → 36/36 tables identical; pytest 9/9.
     Keep the register updated whenever a new source/file is used (e.g. IEEE C57.104 → ST5 accessed date, Step 13 hashes).
   - 11 Oct: all step reports rewritten (version 2) to `PROJECT_MEMORY/claude_memory_notes/report_standard.md` — new
     "Method used" section (approach, why, settings, equations, tools+versions, method refs M1–M7 in the register);
     builders saved in `00_Project_Admin/report_builder/`. Every future report must follow this standard.
   - 11 Oct: Rogers transcribed from IEEE C57.104-2008 Table 6 (+ Table 1 Condition 1, Figure 2 example) from a copy the
     researcher supplied that is licensed to another organisation ("Not for Resale") — file NOT stored; values TO VERIFY
     vs a licensed copy (UMaT library). D10 CLOSED. Both secondary Rogers tables had an error.
   - 11 Oct: CORRECTION Table 4.1b (Step 11) — was 137 leakage + 96 IEC "removed"; true 139 leakage, IEC none. Fixed.
7. Step 13 DONE 11 Oct: data version 1.0 frozen — `03_Data/data_version_1.0.sha256` (16 files), Figure 3.2
   `F3_2_data_preparation_flow`, `common.verify_data_version()` (call it at the start of every later step),
   `tests/test_data_version.py`; pytest 11/11. NEXT: Steps 14–17 in the MATLAB Agentic Toolkit (instructions in
   `00_Project_Admin/Toolkit_Instructions/Steps_14-17_MATLAB.md`); Steps 2–3 also still pending there. Then Step 18 (Claude Code).
8. (old) D10 answered 10 Oct: KEEP Rogers — researcher will obtain IEEE Std C57.104 (2008 and/or 2019) via UMaT library /
   IEEE Xplore. NEXT: when the PDF arrives, transcribe the Rogers table (and confirm Duval Triangle 1 from 2019 §6.2.3),
   re-run step12_check_tables.py, update the Step 12 report; only then Step 13 freeze (hashes incl. plot_style.csv and
   02_Standards CSVs). Pending batch edit of Analysis Plan/Roadmap: D8, D9, IEC edition, Rogers source.

9. Simulink reference re-run (`05_Simulink_Model/reference_build/rerun_2026-10-11/`) - STATUS UNCLEAR, corrected 11 Oct: the folder holds a rebuilt model and logs from an
   earlier session; the logs show OK results, but they were not re-run by me, and the researcher reports errors when running the model in Simulink (cause not
   diagnosed; purpose of the rerun not recorded - TO CLARIFY). Not part of the roadmap steps done on 11 Oct.

10. **Steps 14-17 DONE 11 Oct 2026** (MATLAB R2025b via the MATLAB MCP connection of Claude Code; toolkit Steps 2-3 replaced for MATLAB by decision D14).
   - Code: `04_MATLAB_Conventional/` (20 functions, README, `tests/`, `code_manifest.sha256`). Results: `11_Results/conventional/` (README there lists the columns).
   - **Decisions D12-D14** (researcher, 11 Oct): D12 (1) ND only if a ratio the class uses is undefined, (3) Duval boundary distance = nearest edge between two different zones, in percentage points;
     **D13** (replaces D12 (2)) T1 requires CH4/H2 > 1 so PD and T1 never overlap and IEC can answer PD alone; **D14** MATLAB steps may run through the MATLAB MCP (Steps 2-3 replaced for MATLAB). Steps 14-17 were re-run after D13.
   - Key numbers (827 records, final rules): 99 have a zero denominator; IEC ND 319 raw / 200 final (204 raw at the time of D12, 239 under D11 as first written); IEC D1/D2 90 raw, PD alone 27 raw / 23 final; Rogers ND 424 raw / 296 final;
     Duval ND 2 raw / 1 final, DT 27 raw / 22 final; upper gate calls 242 records Normal, 160 of them true faults; lower gate 91.
   - Tests: 67/67 pass. Plausibility only (not a result): raw agreement on the 117 IEC TC 10 records - Duval 88 %, IEC 69 %, Rogers 47 % (with the simple scoring in `sanity_check_vs_truth.m`).
   - Reports written: `Step_14_Report.docx` to `Step_17_Report.docx`. Register: SW2, M8, M9, DF8-DF14; DF5 sha256 repaired. Glossary +9 terms.
   - M8 DOI could not be confirmed and was removed (venue, volume, pages, year confirmed online); M9 details confirmed online.
   - NEXT: Step 18 [Claude Code] - re-implement the three methods in Python from the same tables (incl. D12, D13) and compare with `conventional_predictions.csv` (100 % agreement expected).

11. **Step 18 DONE 11 Oct 2026** (Claude Code): independent Python implementation `06_Python_ML/src/conventional/conventional_methods.py`
   (from 02_Standards + D11-D13, not translated; Duval distance via nearest other-zone polygon, half-plane clipping). `step18_crosscheck.py`
   -> `08_Statistical_Analysis/cross_language_check.csv`: **2481/2481 rows identical** (diagnoses, gates; numbers within 1e-9, max diff 3.4e-13).
   Python predictions `11_Results/conventional/conventional_predictions_python.csv`. Tests `tests/test_conventional_python.py` (45); pytest 56/56.
   Register DF15-DF17; `Step_18_Report.docx`. Reuse `conventional_methods.py` for Step 38 (service) and the statistics.
   NEXT: Step 19 [Claude Code] - scikit-learn preprocessing/feature pipelines for the four feature sets of Analysis Plan Section 5.1;
   scaling/class weights/oversampling fitted inside training folds only; leakage test that the scaler sees training rows only.
   Every script must call `verify_data_version()` first. Simulink item 9 still needs the researcher's error text.

12. **Step 19 DONE 11 Oct 2026**: `06_Python_ML/configs/ml_config.yaml` (single source of ML settings); `src/ml/features.py`
   (F1-F4), `src/ml/pipelines.py` (`make_pipeline(feature_set, model, params)`, `param_grid(model)`, `balanced_weights`,
   `BalancedClassifier` (fold-local weights, label encoding), `PlattSVC`), `step19_build_pipelines.py` -> `configs/pipeline_catalog.csv`.
   Decisions **D15** (researcher: +1 ppm log-ratios; fold-median imputation; fold-local class weights; no SMOTE) and **D16**
   (procedural: SVM via CalibratedClassifierCV; MLP L-BFGS max_iter 5000). Leakage tests pass; pytest 87/87. Register DF18-20, M10-12.
   NEXT: Step 20 - nested CV: outer = folds.csv rep01-rep10 (50 folds), inner = StratifiedKFold(5, seed) GridSearchCV by f1_macro,
   for 6 models x 4 feature sets; save every run (config, seed, metrics, fold predictions) in 07_Experiments/<date>_<run>/;
   check that re-running a saved configuration reproduces the numbers. Cite Varma & Simon 2006 (nested CV) - add to register.
     Simulink: the `rerun_2026-10-11` model loads, updates and simulates without error in MATLAB here; the researcher reported errors - the exact error text is needed to diagnose (item 9).

13. **Steps 20-21 DONE 11 Oct 2026** (Claude Code). Step 20 nested CV run `07_Experiments/2026-10-11_nestedcv_v1` (1200 tasks,
   reproducible; Table 4.4 in `11_Results/tables/T4_4_cv_results.csv`). Decision **D17** (inner StratifiedGroupKFold, seeds, saving,
   test sets closed). Step 21: decision **D18** fixed BEFORE results were read; `07_Experiments/model_selection.md` ->
   **final pipeline = Random Forest on F4** (macro-F1 0.850 vs XGBoost F4 0.842, corrected resampled t p = 0.621; RF simpler).
   Supporting: 7 pipelines not significantly worse than the best, incl. logistic regression F3 (0.821, p = 0.100) - discuss in Ch. 4.
   Lowest per-class F1 for the leading models: D1 and T2. pytest 91/91. Register M13, M14, DF21-DF23; glossary 120 terms.
   NEXT: Step 22 - tune (GridSearchCV, StratifiedGroupKFold(5), groups, seed 20261010) and fit RF/F4 on all 439 development
   records; open the three test sets ONCE (log it); predict internal test (61 independent of 70), IEC TC 10 (117; 58 P = primary,
   merged 5 classes), Li 2019 (86 independent of 201) -> `11_Results/ml/ml_predictions.csv`. Then Steps 23 (permutation + SHAP)
   and 24 (dga_model_v1.joblib + model card). Step 21 program refuses to run once ml_predictions.csv exists.

14. **Step 22 DONE 12 Oct 2026** - TEST SETS HAVE BEEN OPENED (once, 00:11:35, logged in `11_Results/ml/test_set_access.log`; never
   re-predict - `step22_final_fit.py` refuses). Final model = `07_Experiments/2026-10-12_final_fit/final_pipeline.joblib`
   (RF/F4, max_depth None, min_samples_leaf 1; decision D19). First-look macro-F1: internal 0.812, IEC TC 10 PT 0.731, Li 0.595
   (CV 0.850). Earlier plausibility check (Steps 14-17, simple scoring, raw): Duval agreed 88 % on the 117 IEC TC 10 records ->
   expect Duval to be competitive on the benchmark (home advantage); report as found.
   NEXT: Step 23 permutation importance + SHAP (Analysis Plan 8.1; Figures 4.14-4.15); Step 24 versioned model
   `06_Python_ML/models/dga_model_v1.joblib` + model_card.md, reload must reproduce ml_predictions.csv exactly.

15. **Step 23 DONE 12 Oct 2026** (D20): permutation importance (gas + feature level) and exact TreeSHAP; Figures 4.14-4.15;
   results in `11_Results/explain/`. Model reasoning consistent with key gases (6/6) and IEC 60599 Table 2 directions;
   C2H6 importance negative on IEC TC 10 (discuss). M16 Lundberg & Lee 2017 pages TO VERIFY.
   NEXT: Step 24 - save `06_Python_ML/models/dga_model_v1.joblib` (copy of the Step 22 pipeline, NOT refitted) + SHA-256 +
   `model_card.md` (data version, settings, metrics incl. first-look test scores, explanations); check that reloading reproduces
   `11_Results/ml/ml_predictions.csv` exactly (predicted class and probabilities).

16. **Step 24 DONE 12 Oct 2026** (D21): released model `06_Python_ML/models/dga_model_v1.joblib` + model card; load ONLY via
   `model_io.load_model()`; reload reproduces Step 22 exactly; pytest 94/94. Stage D complete.
   NEXT: Stage E - Step 25 [Claude Code]: retrain the SAME pipeline (RF/F4? - note: the roadmap says "repeat Steps 19 and 20 with
   gases removed", i.e. nested CV on the identical folds for all 31 non-empty gas subsets; feature sets must be rebuilt from the
   available gases only - decide how F4 features are defined for a subset, record as D22 BEFORE running; monitor panels from the
   literature still to be listed - TO VERIFY sources). Then Step 26 (MATLAB: conventional methods with gases removed), Step 27
   (minimum panel, tolerance delta = 0.05 approved).

17. **Step 25 DONE 12 Oct 2026** (D22): reduced-gas nested CV for 31 subsets (RF/F4-restricted). Only H2+C2H6+C2H4+C2H2 has mean
   loss <= 0.05 (0.017); best 3-gas loss 0.117. Results `11_Results/reduced_gas/reduced_gas_results.csv`, subsets file for MATLAB
   `reduced_gas_subsets.csv` (column monitor_panel empty - monitor panels TO VERIFY from literature).
   NEXT: Step 26 [MATLAB toolkit / MATLAB MCP per D14]: for each subset set removed gases to NaN, run the three conventional methods,
   save share of ND per method -> `11_Results/conventional/conventional_applicability.csv` (expected: IEC/Rogers need all 5; Duval needs
   CH4, C2H4, C2H2). MATLAB MCP connection failed at the start of 12 Oct session - may need the researcher to restart it.
   Then Step 27: loss with 95 % bootstrap CI, delta = 0.05 (approved), Table 4.9, Figures 4.16-4.17.

18. **Step 26 DONE 12 Oct 2026** (D23, MATLAB through the MCP connection per D14): the three conventional methods with gases removed.
   Removed gas = NaN (not 0 ppm); a method that needs a removed gas gives ND for 100 % of records (IEC 60599 and Rogers need all five
   gases, Duval needs CH4, C2H4, C2H2); the gate is never passed with a gas missing. Result `11_Results/conventional/conventional_applicability.csv`
   (465 rows = 31 x 3 x 5) + `_checks.csv` (10 checks PASS). IEC and Rogers can diagnose 1 of 31 combinations (all five gases), Duval 4 of 31.
   The only reduced panel within 0.05 loss in Step 25 (H2+C2H6+C2H4+C2H2) cannot be diagnosed by any conventional method. Five-gas row =
   conventional_counts.csv exactly. Independent Python check (`step26_crosscheck.py`) identical on 465 of 465 rows. MATLAB tests 93/93
   (67 + 26 new `TestReducedGas`); pytest 4 new. Report `Step_26_Report.docx`; register DF29-DF32, glossary +3 terms.
   OPEN FOR THE RESEARCHER: D23 rule 4 (gate on incomplete data) is my recommendation, status PROPOSED; the roadmap check "Duval ND =
   five-gas Duval ND" holds against the count BEFORE the gate (2), not after it (1) - flagged in the report. Alternative in column
   `n_nd_gate_measured`. 11_Results/manifest.csv rows of the Duval figures had unquoted commas (repaired); the manifest lists only
   some results (not maintained since Step 17 - to be completed).
   NEXT: Step 27 [Claude Code]: loss with 95 % bootstrap CI (Eq. 36-37), delta = 0.05, minimum panel, Table 4.9, Figures 4.16-4.17.
## 2026-10-12 - Simulink rerun: callback path fix
- Reproduced a load/update/sim error with MATLAB's path cleared of 05_Simulink_Model: "Error evaluating 'InitFcn' callback ... Unrecognized function or variable 'params_transformer'". The model's PreLoadFcn and InitFcn only called `params_transformer;`, and the only copy of that script is two folders above the model (05_Simulink_Model/params_transformer.m).
- Fix: both callbacks now add that folder (model folder/../..) to the path when the script is not found, then run it. Model re-saved; backup kept as `reference_build/rerun_2026-10-11/Transformer_Operating_Model_backup_before_callback_fix.slx`. With the path cleared the model now updates and simulates. With the path set it behaved the same as before.
- NOT confirmed: that this is the exact error the researcher saw (their message was not supplied). If a different error appears, send its exact text.

18. **Steps 26-27 DONE 12 Oct 2026.** Step 26 done by the researcher's MATLAB session (D23; rule (4) gate-with-missing-gas still PROPOSED,
   awaiting the researcher's confirmation; register DF29-DF32). Step 27 (D24): minimum panel H2+C2H6+C2H4+C2H2 (loss 0.017 [-0.006, 0.038]);
   no conventional method usable without CH4. Stage E complete. pytest: see CHANGELOG.
   NEXT: Stage F - Step 28: merge true classes + conventional_predictions.csv + ml_predictions.csv on record_id ->
   `08_Statistical_Analysis/merged_predictions.csv` (no record lost or duplicated). Then Step 29 (measures + Wilson/bootstrap CIs,
   Tables 4.3-4.5, Figs 4.5, 4.8), Step 30 (Friedman/Nemenyi; Cochran Q + McNemar/Holm; kappa), Step 31 (boundary hypothesis), Step 32.

19. **Step 28 DONE 12 Oct 2026**: `08_Statistical_Analysis/merged_predictions.csv` (388 rows; DF34). NEXT: Step 29 - measures with CIs from this
   file only: strict/conditional accuracy + coverage (Wilson), per-class P/R/F1, macro-F1, balanced accuracy, kappa, MCC (stratified bootstrap
   B = 2000); scoring: D11 rule 4 (IEC D1/D2 dual correct for true D1 or D2; sensitivity wrong), DT wrong (plan item 17), ND wrong in strict;
   IEC TC 10 on 5 merged classes, Normal = wrong; evaluation sets of D19 (primary + sensitivity); gate sensitivity (lower gate, raw).
   Tables 4.3-4.5, Figures 4.5 and 4.8. Write the scoring details as D25 BEFORE computing.

20. **Step 29 DONE 12 Oct 2026** (D25). Mixed result: ML clearly best on internal test; on IEC TC 10 Duval nominally best (not significant vs ML);
   on Li ML best with gate, Duval best without gate. Criterion 2 preview: for Rogers/IEC conditional gap < strict gap on all 3 sets.
   NEXT: Step 30 - Friedman + Nemenyi on CV results (Fig 4.7 CD diagram, Table 4.4 ranks); Cochran's Q then McNemar exact/continuity +
   Holm on each primary test set (Table 4.6; ND = wrong); kappa between all method pairs (Table 4.7, Fig 4.11); judge hypothesis
   criteria 1-3 (criterion 3 needs Step 31). Fix test details (exact vs chi-square McNemar per plan Section 7.3) as D26 BEFORE computing.
   Open: D23 rule 4 confirmation; Duval-zones-tuned-on-TC10 question TO VERIFY.

21. **Step 30 DONE 12 Oct 2026** (D26; D23 rule 4 confirmed). Hypothesis NOT SUPPORTED on the main benchmark (criterion 1 fails: ML not
   significantly better than IEC 60599 or Duval on IEC TC 10); partial support on internal and Li sets. RF ~ XGB (Nemenyi).
   NEXT: Step 31 - logistic regression of disagreement (ML != method) on standardised boundary distance per conventional method
   (Eq. 33-34; Firth if separation); records with no distance excluded and counted; Table 4.8, Fig 4.12. Then final verdict incl.
   criterion 3. Fix details as D27 BEFORE computing (which records: primary test sets pooled or per set; Inf distances).
   Open TO VERIFY: Duval 2002 full text (zones tuned on TC 10?), Cochran 1950 DOI, Nemenyi thesis, Efron book edition.

22. **Step 31 DONE 12 Oct 2026** (D27): criterion 3 not met (pooled, with gate); Duval boundary effect appears without the gate.
   FINAL HYPOTHESIS VERDICT: NOT SUPPORTED on the main benchmark (IEC TC 10); partly supported on internal and Li sets.
   NEXT: Step 32 - one script rebuilds ALL Chapter 4 tables and figures from saved files (incl. new Figs 4.6 box plots of CV folds,
   4.9 dot-whisker main comparison, 4.10 per-class F1 with CIs, 4.13 Duval-triangle disagreements); check: delete 11_Results, rerun,
   identical files (beware: figures/plot_style.csv is a frozen data-version file - must NOT be deleted; PNG/PDF byte-identity may need
   fixed metadata, e.g. matplotlib metadata={'CreationDate': None}). Figures 4.1-4.4 come from Steps 11/13/17 (MATLAB Fig 4.4).

23. **STUDY 2 (exploratory improvement) started 12 Oct 2026 - Step 31A DONE** (D28). Protocol `00_Project_Admin/Study2_Protocol.docx`
   (SHA-256 in `03_Data/study2/study2_protocol.sha256`, registered 16:24:48 before any Study 2 model) - FOLLOW IT EXACTLY; any change
   = a dated, logged amendment. Roadmap is now Version 3 (Steps 31A-31F between 31 and 32). Confirmatory results (Steps 22-31) never
   change. Known overlaps: Li 2019 has 115 IEC TC 10 copies (106 IEC+Li, 9 IEC+DISTEST+Li), plus 1 DISTEST+Li copy.
   NEXT: Step 31B - build `03_Data/study2/study2_pooled.csv` (+ manifest): dedup by priority, near-dup groups (Step 10 rule, 1 %/1 ppm)
   over all pooled records, merged 6 classes, IEC primary scope P/U (all 117 = sensitivity), hybrid inputs from conventional_predictions.csv
   (raw answers one-hot, gate flags, 3 boundary distances; Inf/NaN -> median + flag at training time). Then 31C (LOSO runs), 31D, 31E, 31F.

24. **Step 31B DONE 12 Oct 2026**: `03_Data/study2/study2_pooled.csv` (702; 643 primary). LOSO sizes: IECTC10 test 58/train 585;
   DISTRAIN 439/204; DISTEST 61/582; LI2019 85/558. NEXT: Step 31C - LOSO runs per protocol: model A = dga_model_v1 (merge T1/T2 -> T12;
   not for DISTRAIN held out); B = RF/F4 pooled, C = hybrid (F4 + one-hot raw answers of IEC/Rogers/Duval incl ND/DT/D1-D2 + gate flags
   + 3 distances with inf/NaN -> training median + missing flag); GridSearchCV 9-grid, StratifiedGroupKFold(5) groups=group_id, macro-F1,
   balanced class weights (BalancedClassifier), seed 20261012 + index; sensitivity: equal source weights; also IEC all-117 sensitivity.
   Save predictions + probabilities per held-out source in 07_Experiments/2026-10-12_study2_loso/. Check: rerun of a saved task identical.

25. **Step 31C DONE 12 Oct 2026**: Study 2 predictions `07_Experiments/2026-10-12_study2_loso/predictions.csv` (variant, held_out, model A/B/C,
   record_id, y_true, y_pred, p_Normal..p_T3). NEXT: Step 31D - from these + study2_pooled.csv conventional raw answers & gate (result = Normal
   if gate_upper_normal else raw; merged T1/T2 -> T12; D1/D2 dual correct for D1/D2): macro-F1 over classes present in held-out source,
   strict/balanced accuracy, Wilson + stratified paired bootstrap B=2000 (seed 20261012); contrasts B-A, C-B, C vs best conventional (by strict
   accuracy) with McNemar + Holm per source; reject option: tau so coverage = IEC (and Rogers) coverage on that source, compare selective
   accuracy vs method conditional accuracy (bootstrap CI of difference); risk-coverage curves; Tables 4.12-4.13, Figs 4.23-4.24. Then 31E rules.

26. **Steps 31D-31E DONE 12 Oct 2026** (Study 2, exploratory; D29): pooling NOT shown, hybrid NOT shown, reject option competitive
   (C at IEC coverage more accurate than IEC 60599 on all sources; CI excludes 0 except IEC TC 10). Practical message: "confident or refer".
   NEXT: Step 31F - search legitimate sources (journals with open data, standards bodies, open repositories with stated licence) for
   inspection-confirmed DGA cases NOT already used (not IEC TC 10 / Li 2019 / Dissanayake); record citation, licence, size, classes, overlap
   -> `03_Data/provenance/study2_confirmation_search.md` + Step 31F report. No pirated copies. Then Step 32.
   NOTE for report builders: never name a data variable like a loop/param variable differing only in case ($M/$m, $C/$c, $R/$r).

27. **Step 31F DONE - STUDY 2 COMPLETE (12 Oct 2026).** No fresh confirmation set available; leads recorded
   (`03_Data/provenance/study2_confirmation_search.md`). Researcher/supervisor decision pending: request Ghanaian utility inspection records
   (GRIDCo/ECG/VRA) via Prof. Annan; contact KNUST author (Adu-Gyamfi 2026, 589 records) and Shutenko & Kulyk (25 records).
   NEXT: Step 32 - one script rebuilding ALL Chapter 4 tables and figures (+ new Figs 4.6, 4.9, 4.10, 4.13 and the Study 2 section);
   check: delete 11_Results outputs (NOT plot_style.csv - frozen file) and rerun -> identical files (fix PNG/PDF metadata for byte identity).

28. **Step 32 DONE 12 Oct 2026 - STAGE F COMPLETE.** Rebuild all Chapter 4 outputs: `python -I 06_Python_ML/src/analysis/make_chapter4.py`
   (`--check` = rebuild from scratch and compare; passed 79/79). Not rebuilt there: plot_style.csv, Fig 3.2, Fig 4.4 (MATLAB).
   NEXT: Stage G (Steps 33-37) - Simulink Agentic Toolkit: rebuild Transformer_Operating_Model.slx (pure Simscape; params_transformer.m;
   annotate every subsystem; Simulink never generates gas values). Needs the Simulink toolkit or the MATLAB MCP connection (it failed to
   connect on 12 Oct). Open item 9: researcher's Simulink error text still needed. Also open: utility inspection data (Step 31F).

29. **Step 33 DONE 12 Oct 2026** (D30 proposed, D31): `05_Simulink_Model/Transformer_Operating_Model.slx` built by `build_Transformer_Operating_Model.m` from Build
   Guide Part B (MATLAB MCP, R2025b; Simscape Electrical present). `verify_step33.m`: 9/9 checks (clean-path update+run, no warning, annotations,
   no typed number, no gas block, 1 solver per network, structure = reference build 84 blocks, analytic steady state, = reference result).
   Results: K 0.9839, oil 78.638 degC, hot-spot 100.276 degC. Figure 3.4 + subsystem diagrams in `05_Simulink_Model/figures`. Report `Step_33_Report.docx`.
   REVIEW FINDINGS: guide typed 273.15 (fixed: T_zero_C_in_K); callbacks path-fragile (fixed); SS3/SS5/SS7 arithmetic is Simulink, so the model is
   "Simscape networks + Simulink arithmetic", not pure Simscape (D31 clause 4 - researcher to confirm); thermal constants are Alliander defaults and
   IEC 60076-7:2018 was never obtained -> TO VERIFY; electrical data are pandapower typical values, not a nameplate.
   NOTE: decision numbers after D29 go on from D30. Do not name PowerShell helpers R, Rp, H (aliases).
   NEXT: Step 34 - Model Advisor + Build Guide Part D1 checks, report in `05_Simulink_Model/checks/model_advisor_report`; then 35 (verify vs independent
   IEC 60076-7 solution, Table 4.10, Figure 4.18, 63 % rise time = k11*tau_o = 75 min, tolerance 0.1 K), 36 (scenarios.m, 3 scenarios, SDI, Fig 4.19), 37 (sampling-event subsystem, no gas value).

30. **Step 34 DONE 13 Oct 2026** (D32): Model Advisor 132 checks -> 120 passed / 11 warnings / 1 incomplete / 0 failed (first run 115/16/1); 5 groups fixed in the builder
   (Sqrt block, 6 diagnostics to error, Exp name, `X0_pu` variable found by the all-dialog-field scan), 12 non-passed checks accepted with written reasons
   (`05_Simulink_Model/checks/model_advisor_accepted.csv`; acceptance PROPOSED, researcher to confirm). Part D1: 13/14 rows pass; D1.6 app not applicable yet; D1.7 (second person) OPEN.
   verify_step33 9/9 with 7 expected differences; results identical to reference. Step 33 model kept as `checks/Transformer_Operating_Model_before_step34.slx` (DF58).
   NOTE: Step 33 report is NOT rewritten (it shows the 12 Oct state). MATLAB regex `\b` = backspace (use look-arounds). PowerShell: `int + string` inside @() needs `"" + ...`; scripts ASCII-only.
   NEXT: Step 35 - verify vs independent IEC 60076-7 solution (rated load and load step 0.6->1.2 pu), Table 4.10, Figure 4.18, 63 % rise time = k11*tau_o = 75 min, tolerance 0.1 K.
   Then 36 (scenarios.m, SDI, Fig 4.19), 37 (sampling-event subsystem, no gas value).

31. **Step 35 DONE 13 Oct 2026** (D33, fixed before running): `05_Simulink_Model/verify_step35.m`, 15/15 checks PASS. e_max after 10 min: top-oil 0.0014 (rated) / 0.0015 (step) K, hot-spot 0.0129 / 0.0152 K (limit 0.1 K; final model, RelTol 1e-4; first version had 0.0599 / 0.0315 K at RelTol 1e-3); 63.2 % rise 75.002 min vs 75.000; 3 Oct baseline reproduced.
   OPEN/HONEST: whole-run hot-spot difference up to 0.033 K (85 s), never above 0.1 K. With the default solver RelTol 1e-3 the Test 1 hot-spot difference reached 0.104 K after Step 37 (fail); cause = solver tolerance, fixed with solver_reltol = 1e-4 (D33 amendment). Reference is driven by the model's own K (electrical part not tested here). This is verification, not validation; thermal constants still TO VERIFY vs IEC 60076-7:2018. Rise-time (1 min) and V (1.16 %) tolerances are D33 proposals.
   Outputs: results/step35_*, Table 4.10, Figure 4.18 (11_Results). Report Step_35_Report.docx; register DF59-DF63 (Word register v7).
   NEXT: Step 36 - scenarios.m (constant rated load, daily load cycle, short overload; proposed - need approval wording check in Analysis Plan 9.5), simulate each, SDI logs, Figure 4.19 (3 panels: K; ambient/top-oil/hot-spot; ageing V log scale with loss of life L), sim_*.mat. Then Step 37 (sampling-event subsystem, no gas value).

32. **Step 36 DONE 13 Oct 2026** (D34): `scenarios.m` + `run_step36.m`; 3 illustrative scenarios (rated; daily cycle 3 days, last shown; overload 1.3 pu 2 h); 13/13 checks PASS; peak hot-spot 100.3 / 99.9 / 129.0 degC; L 27.88 / 6.45 / 38.58 h; Figure 4.19a-c. Scenario values are illustrative (not data) - replace with utility load curves if received (only scenarios.m changes). No IEC limits applied (standard not obtained).
   NOTE: PowerShell edits of MATLAB files: never put \n in a replacement string (it stays literal). Report figures: insert page break before captions to avoid orphans.
   NEXT: Step 37 - sampling-event subsystem: add sampling times to params_transformer.m; subsystem outputs record_id of the next held-out record from dga_master.csv at those times; NEVER a gas value; check = inspection + test (extend verify_step33 check 6). Then Stage H (38 FastAPI ...).

33. **Step 37 DONE 13 Oct 2026** (D35, two amendments): subsystem SS8 (sampling events: ecord_index, sampling_event at 6/12/18/22 h, illustrative; no ports; never a gas value) + get_sampling_events.m + erify_step37.m 10/10 PASS. Solver tolerance fixed (solver_reltol = 1e-4, D33 amendment); Steps 33/35/36/37 and Step 34 checks re-run on the final model (Model Advisor 120 passed / 11 warnings / 1 incomplete / 0 failed = as accepted). Reports Step_35 and Step_36 v2, Step_37 v1. Register DF69-DF70.
   OPEN: checklist D1.7 (a second person checks the build) still needs a person; sampling times illustrative.
   NEXT: Stage H - Step 38 FastAPI service (09_API_FastAPI).

34. **Step 38 DONE 13 Oct 2026** (D36): FastAPI service in `09_API_FastAPI` - POST /diagnose (H2, CH4, C2H6, C2H4, C2H2 ppm + optional record_id -> fault_class, probabilities, confidence, model version/SHA, notes), GET /health, GET /version; openapi.json. Start: `powershell -ExecutionPolicy Bypass -File 09_API_FastAPI\run_service.ps1` (127.0.0.1:8000). 21 API tests; whole suite 151 pass (run with `06_Python_ML\.venv\Scripts\python.exe`; plain `python` lacks the packages).
   Service check (real server): 388/388 identical class + probabilities, 0 failures, median 55.3 ms, p95 62.1 ms (preliminary). Fixed: NaN input crashed the 422 error writer.
   NOTE for Step 39: in `10_Dashboard_Client/ml_diagnose.m` set ML_ENABLED = true (URL and field names already match); send record_id in the test bench (Step 41) so Step 42 can match records. Service has no log-in (local only) and no reject option.
   NEXT: Step 39 (MATLAB Agentic Toolkit / MATLAB MCP) - App Designer dashboard DGADashboard.mlapp (Build Guide Part C), Figure 4.22.

35. **Step 39 DONE 13 Oct 2026** (D37): 10_Dashboard_Client/DGADashboard.mlapp (written with the internal MLAPPSerializer; open once in App Designer), dga_agreement.m, ml_diagnose.m (webwrite), erify_step39.m 19/19 PASS; 3 known records (rows 1, 36, 100) and all 388 held-out records equal the offline results; failure cases handled. Figure 4.22. Report Step_39_Report.docx; register DF71-DF73.
   NOTE: PowerShell aliases R, Man are built in (do not name functions so). Start the service for tests: run_service.ps1 (background).
   NEXT: Step 40 - link Simulink to the dashboard (Run Simulation button; SS8 sampling events trigger the diagnosis of the next record via get_sampling_events).

36. **Step 40 DONE 13 Oct 2026** (D38): Run Simulation button runs the model (24 h), marks the 4 sampling events and diagnoses the record of each (EventTable, diagnoseRow); un_transformer_simulation returns es.events; model unchanged. erify_step40.m 13/13 PASS, Step 39 checks 19/19 re-run. Bug found by test: hidden xline objects survive plot() (use findall/delete). Layout compact for ~750 px window. Figure 4.22 regenerated. Reports Step_40 (new), Step_39 v2; register DF74-DF75.
   NOTE: findobj does not see HandleVisibility-off objects; use findall. The MATLAB window is clamped to ~750 px high here: design layouts for 720 px.
   NEXT: Step 41 - test bench over all held-out records of role internal_test or benchmark; log to 10_Dashboard_Client/logs/testbench_log.csv (one row per record, response time, no failed calls); Figure 4.20.

37. **Step 41 DONE 13 Oct 2026** (D39): `10_Dashboard_Client/run_testbench.m` ran the integrated system over all 388 held-out records (unchanged model, event every 15 min); `logs/testbench_log.csv` 388 rows, 0 failed; response median 78.6 / p95 95.6 ms; `verify_step41.m` 12/12 PASS. Figure 4.20. Report Step_41; register DF76-DF78.
   OPEN: researcher to confirm scope (roadmap line says internal_test + benchmark only; all 388 run, role in log). Conventional diagnosis 278 ms median per record - not investigated. Service still started by hand (run_service.ps1).
   NEXT: Step 42 - compare testbench_log.csv with ml_predictions.csv and conventional_predictions.csv (fidelity must be 100 %), median and p95 response time, Table 4.11, Figure 4.21, integration report.

38. **Step 42 DONE 13 Oct 2026 - STAGE H COMPLETE** (D40): `06_Python_ML/src/analysis/step42_integration.py` (also in make_chapter4.py, now 83 files, check identical). Fidelity 388/388 = 100 % (class, 7 probabilities, Rogers/IEC/Duval all identical; 0 failed). Service response median 78.6 ms, p95 95.4 ms (< 1 s). Total per record median 469 ms, p95 548 ms, 11 records > 1 s (information; conventional MATLAB 278 ms median). Table 4.11, Figure 4.21; report Step_42_Report.docx (= integration report).
   FIXED: register ID collision (parallel session reused DF71-DF73 for Step 39) -> Step 38 now DF79-DF81, Step 38 report v2. RULE: before adding register IDs, read the current highest DF number; update scripts should refuse IDs used by another step.
   OPEN: D39 scope (all 388 vs 187) for the researcher; service started by hand; checklist D1.7 (second person); utility inspection data; TO VERIFY citations (M24, M27, M28, M20).
   NEXT: Stage I - Step 43: write Chapters 3-5 (12 pt, 1.15) from 11_Results only; every number traceable; no TO VERIFY left.

39. **Stage I started 13-14 Oct 2026 - FULL THESIS DRAFT v1** (D41; researcher asked for the full thesis instead of Step 43 Ch. 3-5 only): `12_Thesis/Thesis_Draft_v1.docx` (112 pages, UMaT format, 46 figures incl. Simulink top level + SS6 and the dashboard, 31 tables, 86 verified references). Rebuild: `python -I 12_Thesis/builder/make_references.py` then `python -I 12_Thesis/builder/build_thesis.py` (venv python) then `powershell -File 12_Thesis/builder/finish_thesis.ps1 -raw 12_Thesis/build/thesis_raw.docx -out <file>`. Text = `12_Thesis/source/*.md`; numbers = `{{facts}}` from result files (facts.py); tables from CSVs (tables.py).
   NOTE: SaveAs2 inside a try{} block hung again - finish_thesis.ps1 copies to scratch and calls Save() at script level (works in seconds). Word UnicodeMath needs U+2061 after log_10.
   OPEN for the researcher: author name on the title page (D5; draft uses Jacob Addo Tagoe), justified vs left-aligned text (D41), dedication/acknowledgement wording, D39 scope, D31(4), D32(3), D1.7, utility data. Step 43-44 step report not yet written (thesis still under review). Supervisor review = Step 45.
40. **Thesis draft v2, 14 Oct 2026** (researcher feedback on v1): `12_Thesis/Thesis_Draft_v2.docx`, 9 chapters, 137 pages; decision codes removed from the thesis (they clash with fault classes D1/D2); Chapter 3 = methods only; figures redrawn by `12_Thesis/builder/thesis_figures.py`. Rebuild order: thesis_figures.py -> make_references.py -> build_thesis.py -> finish_thesis.ps1. Source files now 01_ch1 ... 09_ch9, 10_refs (generated), 11_appendices.
   NOTE: Word UnicodeMath fails on `|log_10...|` unless there is a space before the closing bar.
41. **README for running and setting up, 15 Oct 2026**: `00_Project_Admin/README_HOW_TO_RUN_AND_SETUP.md` (dashboard, Simulink model, service, setup on another computer, presentation order). Not yet tested on a second computer - do a dry run on the presentation machine.

42. **15 Oct 2026 - dashboard auto-path fix**: DGADashboard.mlapp now finds the project folders itself (startupFcn searches for project_setup.m, addpath of 04/05/10). Rebuilt via tools/build_dashboard_mlapp.m after editing tools/DGADashboard_code.txt (backup in tools/backup_before_autopath). verify_step40 13/13 pass; new manifest code_manifest_autopath_2026-10-15.sha256. Guide: 00_Project_Admin/Simulation_and_Dashboard_Guide.docx (11 pages, Section 10 = manual connection on a new laptop). Launchers: 09_API_FastAPI/Start_ML_Service.bat (tested), 06_Python_ML/Setup_Python_Environment.bat (not run). NOT tested on a second computer.

43. **15 Oct 2026 - dashboard is master control**: DGADashboard now starts the FastAPI service itself at startup (ensure_ml_service.m; retry in diagnoseRow; stop_ml_service.m). Tested cold start: 4/4 events diagnosed. Service keeps running after the app closes. verify_step40 re-run pending/see CHANGELOG. Not tested on a second computer. Stale-copy issue: the researcher's earlier error came from an old DGADashboard (line 145 vs 138) - use `which -all DGADashboard`.

44. **15 Oct 2026 (later) - freeze fixed, explanation panel, dashboard = master control (D42, PROPOSED).** Cause (measured): ML service started by `system()` shared MATLAB's 4 KB output pipe -> after ~61 requests the service blocked and MATLAB waited 248.4 s; a hung service also kept port 8000; cold first simulation 54 s with no message. Fix: `09_API_FastAPI/launch_service_detached.ps1` (WMI, log file, no access log), `stop_service.ps1`; `ensure_ml_service.m` rewritten (replaces hung service); app: health check before each diagnosis, busy lock, progress windows, model warm-up at start, Restart ML service button, close stops own service, panel "How to read this result" (`dashboard_explain.m`), click on event row. `verify_step43.m` 23/23 (includes the 19 + 13 older checks; ~20 min). Report `Dashboard_MasterControl_Report.docx`; register DF86-DF89.
   LESSONS: never start a long-running program with `system()` from MATLAB without detaching it (WMI Win32_Process.Create) - it inherits MATLAB's pipe; weboptions Timeout did not bound a hung webwrite (use a health pre-check); PowerShell -File needs -ExecutionPolicy Bypass; MATLAB temp path contains a space (quote it).
   OPEN: Figure 4.22 / thesis still show the earlier layout (new screenshot in 10_Dashboard_Client/results); second-computer test; D42 to confirm.
45. **17 Oct 2026 - dashboard redesign (D43, PROPOSED) after the researcher's complaint that the app showed only numbers.** New screen: verdict banner (green HEALTHY / red FAULT type / amber WATCH-CHECK) with reason and action, five cards (Rogers, IEC 60599, Duval, ML, known label) marked AGREES/DIFFERS, sample table with all four answers per sample, tabs Charts / Step by step (IEC 60599 / IEEE C57.104 procedure) / Explanation / Tables / Simulation. Variety: scenario drop-down (rated, daily 3-day cycle with last day shown, overload), sample-set drop-down (MIXED = healthy + each fault type, RANDOM 7, FIRST 4 = Step 40), fault-type picker + random record. Sampling times passed to the unchanged Simulink model via `run_transformer_simulation(profile, opts)`; record lookup outside the model. Verdict rule = vote (D1/D2 votes for both, DT/ND abstain, >=2 votes). Descriptive check on 388 records: 242 of 346 known faults called FAULT (217 exact type, 240 right family), 7 called HEALTHY (low-gas faults pass the typical-value gate), 97 WATCH/CHECK. Checks: verify_step44 18/18, test_dashboard_verdict 10/10, verify_step40 13/13, verify_step39 19/19, verify_step43 22/23 before the fix of two Step 40 behaviours, then 23/23 after the fix (full rerun 17 Oct). Files: `10_Dashboard_Client/{dashboard_verdict,dashboard_samples,sim_window,test_dashboard_verdict,verify_step44}.m`, `tools/dashboard_components.m`, backups `tools/backup_before_redesign/`, manifest `code_manifest_redesign_2026-10-17.sha256`, register DF90-DF93. Layman document `00_Project_Admin/Project_Explained_Simply.docx` (builder `report_builder/build_project_explained.ps1`). Thesis: Chapter 8 dashboard section rewritten, Figure 8.6 regenerated, `Thesis_Draft_v3.docx`. Step report  0_Project_Admin/Step_Reports/Dashboard_Redesign_Report.docx (builder eport_builder/build_step_report_44.ps1). **Clean-up for GitHub, 17 Oct 2026:** .gitignore/.gitattributes written (venv, caches, slprj, old thesis drafts, IEEE raw data and chat transcript excluded); root README has a current-state and repository-notes section; manifests checked ( 0_Project_Admin/manifest_status_2026-10-17.csv); Python 154 tests, MATLAB 93 tests, Simulink verify 33/35/37 and dashboard 39/40/43/44 all pass; model checksum unchanged (DF0681C6...). Git is NOT installed on this computer and nothing has been pushed. Open: D43 awaits confirmation; install Git (and create a private GitHub repository) and push; repository licence undecided; author name (D5).