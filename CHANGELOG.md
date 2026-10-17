# Changelog

## 2026-09-30
- Project structure created; READMEs written for every folder.
- Original documents moved to `00_Project_Admin/`.
- Master plan saved as `PROJECT_PLAN.md`.
- Added `00_Project_Admin/Project_Methodology_Plan.docx` (methodology plan v1.0, unified objectives).

## 2026-10-03
- Added `00_Project_Admin/MATLAB_Build_Guide.docx` (Parts A–C: MATLAB code, Simscape transformer model, App Designer dashboard).
- Added verified MATLAB code: `project_setup.m`; `05_Simulink_Model/params_transformer.m`, `run_transformer_simulation.m`;
  `04_MATLAB_Conventional/gas_ratios.m`, `duval_xy.m`, `conventional_diagnosis.m`, `plot_duval_triangle.m`;
  `10_Dashboard_Client/load_dga_record.m`, `ml_diagnose.m`, `DGADashboard_reference.m`.
- Added `05_Simulink_Model/reference_build/` (script that builds the model, verification scripts, log and figures).
  Verification: Simscape model vs IEC 60076-7 equations, max difference 0.061 K (rated load) and 0.031 K (load step).

## 2026-10-08
- Added `PROJECT_MEMORY/` (session summary, Claude memory notes, full chat export) and root `CLAUDE.md` for moving the project to another SSD.
- Installed AWS CLI (v2.37.10) via winget to download IEEE DataPort datasets over S3.
- Downloaded IEEE DataPort dataset (S3 id 1375187) to `03_Data/raw/ieee_dataport_1375187/`:
  `DGA_train.xlsx` (31,092 B), `DGA_test_unseen.xlsx` (11,414 B), `IEC_TC_10_data.xlsx` (10,988 B);
  local sizes verified against S3; SHA-256 recorded. Note: original access key was rejected and had to be regenerated.
- Added provenance card `03_Data/provenance/data_card_ieee_dataport_1375187.md` (verified facts + TO VERIFY items:
  DOI mapping, licence, label origin, gases/units, per-class counts, IEC TC 10 overlap, benchmark eligibility).
- Downloaded IEEE DataPort dataset (S3 id 7226) to `03_Data/raw/ieee_dataport_7226/`:
  `DGA dataset.xlsx` (19,071 B, S3 timestamp 2019-01-14); size verified, SHA-256 recorded.
  Added provenance card `03_Data/provenance/data_card_ieee_dataport_7226.md`.
- Read and verified contents of all downloaded files; CONFIRMED dataset identities against DataPort pages:
  - S3 1375187 = Dissanayake "DGA dataset" 2026, DOI 10.21227/27vy-h479 (train 584 / test 70 / IEC 49; classes 0–6 = Normal,PD,D1,D2,T1,T2,T3; exact file + count match).
  - S3 7226 = Enwen Li "Dissolved gas data in transformer oil" 2019, DOI 10.21227/h8g0-8z59 (201 records, text Type labels; file-size match 18.62 KB).
  - Flag: Li set label provenance unclear ("Membership Degree" title) → benchmark eligibility doubtful; different fault taxonomy. Dissanayake IEC_TC_10_data.xlsx is a 49-record subset, not the full IEC TC 10 database.
- Transcribed the FULL IEC TC 10 faulty-equipment database from the user's PDF of Duval & dePablo (2001), Annex 1 Tables 2–6,
  to `03_Data/raw/iec_tc10_duval2001_full/iec_tc10_faulty_equipment.csv` — 117 inspection-confirmed cases
  (PD 9, D1 26, D2 48, T1/T2 16, T3 18), 7 gases incl. CO/CO2. Added provenance card `data_card_iec_tc10_duval2001_full.md`.
  Caveats: T1/T2 not separable from Annex 1; mixed equipment types; units assumed ppm.
- Cross-checked the IEC TC 10 transcription cell-by-cell against the PDF — all 117 rows verified correct; the one ambiguous
  undashed cell (first D1 row) confirmed by user as CO2=784 / CO blank. Transcription marked FULLY VERIFIED in the data card.
- Added `00_Project_Admin/Project_Roadmap.docx` (Times New Roman 12 pt, 1.15 spacing, 7 pages) — start-to-finish plan:
  10 phases (0 Setup → 9 Writing), integrated-architecture table, measured-DGA playback principle, agentic MATLAB/Simulink
  working mode, MATLAB↔Python "in sync" contract, sequence/dependencies, risks, next actions, deliverables by folder.
  Generated via Word COM automation (no Python/pandoc on machine). Note recorded: MATLAB MCP offline this session.
- Updated `Project_Roadmap.docx` to reference the existing planning/modelling documents: added a "Planning and modelling
  documents already written" section (Project_Overview_and_Objectives, Project_Methodology_Plan, MATLAB_Build_Guide,
  Project_Roadmap) and pointed Phase 6/7 and the agentic working mode to MATLAB_Build_Guide.docx (Parts A/B/C) and the
  reference_build scripts. Now 7 pages / ~2458 words.

## 2026-10-09
- Replaced `00_Project_Admin/Project_Roadmap.docx` with **Version 2** (15 pages, 12 pt, 1.15 spacing) at the user's request:
  45 strictly sequential steps, each tagged with ONE working environment — Claude Code (data prep, Python, ML, statistics,
  FastAPI, documents; 28 steps), MATLAB Agentic Toolkit (MATLAB programming; 8 steps), Simulink Agentic Toolkit
  (Simulink/Simscape block modelling; 7 steps), approval gates (2 steps). Each step gives Input / Do / Output / Check, and
  a "Tell the toolkit" instruction for MATLAB/Simulink steps. Includes hand-over-file table (how the environments sync)
  and where the Build Guide parts A–D are used.
- Added `00_Project_Admin/Expected_Results_and_Analysis_Plan.docx` (for supervisor approval; contains NO results):
  research questions → tests → result tables; hypothesis decision rule; data roles and threats to validity (incl. IEC 60599
  limits having been refined on the IEC TC 10 data — Duval & dePablo 2001, p. 32); 46 numbered Word equations (DGA
  ratios, Duval coordinates, ND/coverage, normality gate, boundary distance, preprocessing, metrics incl. macro-F1, kappa,
  MCC, Wilson and bootstrap CIs, Kruskal–Wallis, Friedman/Nemenyi, corrected resampled t, Cochran's Q, McNemar exact,
  Holm, logistic regression, reduced-gas rule, permutation/SHAP importance, IEC 60076-7 thermal and ageing equations,
  verification measures, API fidelity); empty result templates (Tables 4.5, 4.6, 4.9); Simulink baseline copied from
  verification_log_2026-10-03.txt; 16-item approval checklist; references (to be logged/checked before thesis use).
- Note: Word's PDF export hung on this machine; documents were checked by rendering page images instead.

## 2026-10-10
- `Expected_Results_and_Analysis_Plan.docx` → Version 2 (≈31 pages), after user feedback that symbols were not defined
  and graphs were not described:
  - Every one of the 47 numbered equations now has a "where:" list giving the meaning and unit of each symbol.
  - Clashing symbols renamed: precision/recall → Prec_c/Rec_c; MCC written with n_correct and N; bootstrap statistic ψ̂;
    Friedman folds n_f; Cochran row totals a_i; fidelity F = n_match/N. A note explains standard symbols reused across
    unrelated sections (K, H). Added Spearman rank correlation (Eq. 25) for the gas-correlation figure.
  - Added DT-zone scoring rule for Duval Triangle 1 (Section 4.3; approval item 17).
  - New Section 12.2–12.4: figure rules (script-made, data CSV beside each figure, 300 dpi PNG + PDF, one y-axis per
    plot, 95 % CIs, log axes for gases/ageing), fixed colour + marker table (plot_style.csv shared by Python and MATLAB),
    list of 26 figures (3.1–3.4, 4.1–4.22) with chart type / environment / roadmap step, and a per-figure description
    (type, axes and units, colours/panels, data source, where made, how to read). Approval item 18 added.
- `Project_Roadmap.docx` (v2) updated: step outputs now name the figures each step produces; `plot_style.csv` added to the
  hand-over files (written in Step 13, read by MATLAB/Simulink/Python).
- **Roadmap Step 1 DONE [Claude Code] — Python environment.** Python 3.12.10 installed (winget, python.org installer, hash
  verified, user scope: `%LOCALAPPDATA%\Programs\Python\Python312`). Virtual environment `06_Python_ML/.venv`.
  Libraries: numpy 2.5.3, pandas 3.0.6, scipy 1.18.1, scikit-learn 1.9.1, xgboost 3.4.1, statsmodels 0.15.0,
  shap 0.53.0, matplotlib 3.11.2, openpyxl 3.1.5, pyyaml 6.0.3, joblib 1.6.0, fastapi 0.143.0, uvicorn 0.54.0,
  pydantic 2.14.0, httpx 0.28.1 (FastAPI test client), pytest 9.1.1. Full pinned list: `06_Python_ML/requirements.txt`.
  Check: `06_Python_ML/src/check_environment.py` → all 16 imports OK (exit 0).
- **Roadmap Step 4 recorded** — researcher approved the plan and the 18 analysis-plan items (decisions_log.md rewritten:
  D1–D4, D6 CLOSED; D6 fifth classifier = multinomial logistic regression; D5 OPEN, not blocking; D7 rule closed,
  investigation open). Supervisor sign-off not recorded.
- **Roadmap Step 5 DONE [Claude Code] — load and standardise.** Script `06_Python_ML/src/data_prep/step05_standardise.py`
  (+ `common.py` source registry). Outputs: `03_Data/interim/{IECTC10,DISTRAIN,DISTEST,DISIEC,LI2019}_standardised.csv`,
  `03_Data/interim/step05_report.md`, `03_Data/raw/checksums.sha256`. Check PASSED: all hashes match the data cards
  (IEC TC 10 transcription hash recorded for the first time), counts 117 / 584 / 70 / 49 / 201; IEC column re-ordering
  verified cell by cell (0 mismatches in 585 cells); Li Sheet2/Sheet3 confirmed empty.
  Findings (recorded in data cards): Dissanayake files use **0.0001 ppm as a placeholder** (train 257 cells, test 34);
  DGA_train contains **IEC TC 10 cases, some duplicated** (benchmark leakage risk → Step 9); the Dissanayake
  IEC_TC_10_data.xlsx is not purely Annex 1 (15 Normal records, non-integer values).
- **Roadmap Step 6 DONE — missing values.** `step06_missing_values.py`; outputs `*_step06.csv` (per-record flags),
  `missing_values_report.csv`, `missing_values_impact_by_class.csv`, `step06_report.md`. Not-available cells: IEC 23
  blanks; Dissanayake 0.0001 placeholders (train 257, test 34). Missingness is informative (C2H2 not detected mainly in
  T1/T2/T3/PD, never D1/D2); complete-case would leave 14/96 T1 train and 0/10 T1 test records → **decision D8**:
  primary = not available treated as 0 ppm (not detected), flags kept; complete records = sensitivity. Replaces plan item 4.
- **Roadmap Step 7 DONE — label harmonisation.** `step07_label_map.py` → `03_Data/processed/label_map.csv` (33 rows [corrected 10 Oct from 25], each
  with reason + evidence), `*_step07.csv` (class_code, class_name, class_merged), `step07_report.md`. All labels mapped;
  counts match data cards. T1/T2 not separable for IEC TC 10 (16) and Li Low/Middle (16) → merged class T12.
- **Roadmap Step 8 DONE — scope filter.** `step08_scope_filter.py` → `*_step08.csv` (in_scope_primary, scope_reason),
  `exclusion_log.csv`, `step08_report.md`. IEC TC 10 primary (P, U) = 58 of 117 (excluded: R 32, I 12, S 7, B 5, C 2,
  blank 1). Primary benchmark per class: PD 1, D1 10, D2 27, T12 8, T3 12 → PD not evaluable on the primary benchmark
  (evaluated on the internal test set and the all-equipment sensitivity analysis). Dissanayake/Li have no equipment type
  (limitation). Fixed a reporting bug (blank equipment type dropped by groupby) before closing the step.
- **Roadmap Step 9 DONE — duplicates and leakage.** `step09_dedup_leakage.py` → `03_Data/processed/dga_master.csv`
  (827 records: development 439, internal test 70, benchmark 117, external test 201; gases harmonised per D8 with the
  original values kept as orig_*), `duplicate_report.csv`, `label_agreement_iec.csv`, `step09_report.md`.
  Removed: 139 development records for leakage (96 match IEC TC 10, 35 Li 2019, 8 internal test), 2 exact copies,
  4 + 2 identical-gas/conflicting-label records. Findings: Li 2019 = 115 IEC TC 10 cases + 86 others (labels agree
  115/115); Dissanayake labels contradict inspection on 4 copied T1/T2 cases → D7 closed; test sets flagged for benchmark
  overlap → D9. Check: `06_Python_ML/tests/test_no_leakage.py` — 5/5 passed. Two more groupby-NaN reporting slips
  (blank keys dropped) found and fixed before closing.
- **Roadmap Step 10 DONE — data roles and folds.** `step10_folds.py` → `03_Data/processed/folds.csv` (record_id,
  group_id, rep01–rep10), `step10_report.md`. Repeated stratified **group** k-fold, 5 × 10, seed 20261010 (+ repeat);
  9 near-duplicate groups (26 records) inside development kept within one fold; worst class-share deviation 0.9 pp.
  Analysis subsets: benchmark primary 58 / all 117; internal test independent 61 / 70; external independent 86 / 201;
  development complete-case 262 / 439. Check: `tests/test_folds.py` added — full suite 9/9 passed.
- **Roadmap Step 11 DONE — describe the data.** `06_Python_ML/src/analysis/step11_describe.py` + shared style module
  `analysis/plotstyle.py`; `11_Results/figures/plot_style.csv` written now (needed by the first figures; hash to be
  recorded at Step 13). Outputs: Tables 4.1, 4.1b, 4.2 and appendix A4.2 (`11_Results/tables/`), Figures 4.1–4.3
  (PNG 300 dpi + PDF + data CSV), `03_Data/interim/step11_report.md`. Kruskal–Wallis on the development set (n = 439,
  7 classes, df 6): H2 H = 164.5, CH4 153.8, C2H6 191.0, C2H4 263.9, C2H2 311.3; all p < 1e-29; ε²_R 0.35–0.71
  (largest for C2H2). Figure 4.2 plots concentration + 1 ppm on a log axis because not-detected values are 0 ppm (D8);
  first render had overlapping titles/labels — fixed and re-checked. Check PASSED (Table 4.1 totals = master).

- **Step reports for Steps 1 and 4–11** written (`00_Project_Admin/Step_Reports/Step_NN_Report.docx`, 12 pt, 1.15).
  Builder fix: Word `SaveAs2` hung when called from inside a PowerShell function; the save is now written inline.
  (A leftover test file `Step_Reports/zz_savetest.docx` can be deleted by hand.)
- **Roadmap Step 12 DONE (with one open item) — standards tables.** Sources obtained online legitimately only
  (official iTeh previews; CC BY papers): `02_Standards/sources.md`. Outputs: `iec_ratio_table.csv` (IEC 60599
  Ed. 2.1 Table 2 + Table 3, PRIMARY), `iec_typical_values.csv` (Table A.2, AMD1:2007, PRIMARY), `duval_triangle_zones.csv`
  (10 rules, SECONDARY, TO VERIFY), `rogers_ratio_table.csv` (two conflicting secondary versions), `worked_examples.csv`
  (39 Duval examples), `transcription_check.md`. Check script `06_Python_ML/src/standards/step12_check_tables.py`:
  second entry 21/21, 8/8, 10/10 agree; Duval zones cover the triangle with 0 gaps/0 overlaps; 39/39 printed diagnoses
  reproduced; 35/35 example gas values found in our IEC TC 10 file — all PASS. Decision D10 (OPEN): Rogers source.
- **Step reports extended (researcher request).** Every step report (1, 4–12) now ends with: What was achieved; Record of
  this step (table: step, environment, date, status, inputs, outputs, checks, decisions); How this helps the next steps;
  Open items and limitations; Abbreviations and terms used in this report (auto-selected from the new project glossary
  `00_Project_Admin/abbreviations_glossary.csv`, 83 terms; fault types defined per IEC 60599 cl. 5.2).
  Correction found while doing this: `label_map.csv` has 33 rows, not 25 (Step 7 report and this changelog corrected).
- **Data and Source Register (reproducibility record).** `03_Data/provenance/data_and_source_register.csv` (21 entries:
  datasets DS1–DS5, standards ST1–ST5, papers P1–P5, software SW1, derived files DF1–DF5 — each with full reference,
  link, DOI, access date, how obtained, licence/terms, local file, SHA-256, records, role, steps) and the Word report
  `00_Project_Admin/Step_Reports/Data_and_Source_Register.docx` (13 pages, incl. how-to-reproduce and reference list).
  Every step report now has a "Data and sources used in this step" section drawn from the register.
  Checked online 2026-10-10: DS1 DOI 10.1109/57.917529 (IEEE Xplore); DataPort pages state no licence and no units
  (TO VERIFY); Li page offers an unread documentation file "DGA dataset.pdf". Data cards updated.
  **Reproducibility test:** all eight programs (Steps 5–12) re-run from the raw files → 36 of 36 output tables
  byte-identical; pytest 9/9 passed.

## 2026-10-11
- **Step reports rewritten to the report standard** (`PROJECT_MEMORY/claude_memory_notes/report_standard.md`, researcher
  request): every report (Steps 1, 4–12, version 2) now has a "Method used" section after the Purpose — approach, why the
  method is standard practice, settings table, numbered equations with symbol lists (Steps 9, 11, 12), tools with library
  versions, method references — and auto-numbered sections in the standard order.
- Method references added to the register as M1–M7 (FIPS 180-4; Kapoor & Narayanan 2023 [checked online]; Pedregosa et
  al. 2011; Kruskal & Wallis 1952; Tomczak & Tomczak 2014 [formula TO VERIFY]; Spearman 1904; Virtanen et al. 2020).
  Register now 28 entries; Data_and_Source_Register.docx version 2 (15 pages).
- Report builder scripts preserved in `00_Project_Admin/report_builder/` (were only in the temporary session folder).

- **Rogers table added (Step 12 completed).** IEEE Std C57.104-2008 Table 6 -> `02_Standards/rogers_ratio_table.csv`; Table 1
  Condition 1 -> `ieee_condition1_limits.csv`; Figure 2 worked example added (40 examples). Copy supplied by the researcher is
  licensed to another organisation ('Not for Resale') - file NOT stored; values TO VERIFY against a licensed copy. Both
  secondary Rogers tables contained an error (kept as `rogers_secondary_versions.csv`). step12 checks: 8/8 PASS. D10 closed.
- **Correction - Table 4.1b (Step 11).** It counted removed records from the `record_id` column of duplicate_report.csv, where a
  leakage row can list the matched test record: it showed 137 leakage removals (true: 139) and listed 96 IEC TC 10 benchmark
  records as removed (they were not). Fixed in step11_describe.py (removed = training records missing from the master table);
  T4_1b now: 2 copies, 4 conflicting labels, 139 leakage. No other output changed. Found by the new Step 13 consistency check.
- **Roadmap Step 13 DONE - data version 1.0 frozen.** `06_Python_ML/src/data_prep/step13_freeze.py` -> manifest
  `03_Data/data_version_1.0.sha256` (16 files), Figure 3.2 `11_Results/figures/F3_2_data_preparation_flow` (PNG/PDF/CSV),
  `03_Data/interim/step13_report.md`; `common.verify_data_version()` added - every later step calls it; test
  `tests/test_data_version.py` (suite 11/11 PASS). From now on these files change only through a new recorded version.
  Data version 1.0 fingerprints (SHA-256):

  ```
  ef9f6b542821264ad89f1da1d11da9d6dbd5b79d66be5159c263e8361ef77a6b  03_Data/raw/iec_tc10_duval2001_full/iec_tc10_faulty_equipment.csv
  23513c428c52f3bdb0508859cfb72ccc6e7639ef9baf2165b6e03531945c2eaa  03_Data/raw/ieee_dataport_1375187/DGA_test_unseen.xlsx
  c1c376718d72a747b72cff127839d5df488913127ca096b911cc5586dfcedbbf  03_Data/raw/ieee_dataport_1375187/DGA_train.xlsx
  2b5b128abf38533e83e021d923328a7e879af73034cfbf1428bdbcbd9f791c3f  03_Data/raw/ieee_dataport_1375187/IEC_TC_10_data.xlsx
  b797638252db69c02fc86ae834fa7752dcaf1ebe4aa32e8cbbb457915322cac3  03_Data/raw/ieee_dataport_7226/DGA dataset.xlsx
  ae9e6c0c84cf71807012e276582e63e28f110f25c434fdef3ed69ac70e426bbe  03_Data/processed/dga_master.csv
  0ce7d9af3c7ce9f65fe3cd3c52c7b609e2bb8b18b5ba65e3075f7199f49d9a44  03_Data/processed/folds.csv
  f66465bfb7bfb4459a6eaa673736a19c389777203bb2506950ea4419a5de7399  03_Data/processed/label_map.csv
  a8ce9ce85a012cd6845abc7041855110747cbf6a4fee322b48e9339dc4f68ebf  02_Standards/duval_triangle_zones.csv
  92bc70362eac36541e8e42ace93d8678631daa0f82c323cf4baa9531fab6d217  02_Standards/iec_ratio_table.csv
  88d0d57e2eeb473743ce590565d98466c93ae67cfe162950a230a0acd8d88fc8  02_Standards/iec_typical_values.csv
  4a4523269a91b89f7d4745f942a30437cf64a80b72dc1c89e6b4ce193589afe7  02_Standards/ieee_condition1_limits.csv
  0f7427c7e77aa1b2bb86642ed713aa47b541fdbfe482a26d9ed7647b8c4bb7ca  02_Standards/rogers_ratio_table.csv
  798ee67752cd4c8b923848a141d543ad99a84c2c2a4117a1924ea6bbe104fa68  02_Standards/rogers_secondary_versions.csv
  12adba9aee570b61501015c29985cb403a2696d8c11eae85d83bca9a8f4477fb  02_Standards/worked_examples.csv
  041fe94b9db6d78aa2741d34c82f84cfc7045d5a5c4c903a8b85d16d480601b1  11_Results/figures/plot_style.csv
  ```

- **Decision D11 approved (researcher, 2026-10-11)** - implementation rules for the conventional methods (normality gate at the
  upper end of IEC Table A.2 ranges, lower end as sensitivity; C2H2 range by OLTC type; inclusive printed ranges; IEC dual D1/D2
  scoring; Rogers case mapping; one common gate). Toolkit instructions for Steps 14-17 written:
  `00_Project_Admin/Toolkit_Instructions/Steps_14-17_MATLAB.md`. Step 13 report written; Steps 11-12 reports and the register updated.

- **Simulink reference build re-run (2026-10-11) - CORRECTED.** The folder `05_Simulink_Model/reference_build/rerun_2026-10-11/` holds a rebuilt
  `Transformer_Operating_Model.slx` and the logs `verify_log.txt` / `verify_log2.txt`, left by an earlier session. A first version of this entry said that
  the verification had been re-run and was identical to 3 Oct; that was only read from the logs and was NOT re-run or confirmed. The researcher reports
  errors when running the model in Simulink; the cause is not yet diagnosed (one reproduced problem: the model InitFcn runs `params_transformer;`, which
  fails when `05_Simulink_Model` is not on the MATLAB path - the researcher says the path is not the problem). The purpose of the rerun is not recorded
  in the project notes (TO CLARIFY). Simulink work belongs to roadmap Stage G (Steps 33-37).


- **Roadmap Steps 14-17 DONE (2026-10-11) - conventional methods in MATLAB R2025b** (run from Claude Code through the MATLAB MCP connection; toolkit
  Steps 2-3 still unchecked). Code in `04_MATLAB_Conventional/` (20 functions + `tests/`; fingerprints in `code_manifest.sha256`); results in `11_Results/conventional/`.
  - **Step 14**: IEC 60599 ratio, Rogers and Duval Triangle 1 read every limit from `02_Standards` (audit `check_no_typed_limits.m`: 0 typed limits);
    normality gate (D11); boundary distances (Analysis Plan Eq. 9 and 10). Running D11 on the data found three gaps, settled by the researcher as
    **decision D12**: (1) ND only if a ratio the class uses is undefined (IEC ND 239 -> 204 of 827); (2) dual answer PD/T1 (27 records);
    (3) Duval boundary distance = nearest edge between two different zones, percentage points. Open consequence: IEC "PD" can only appear as PD/T1.
    Old stubs (`gas_ratios`, `duval_xy`, `conventional_diagnosis`, `plot_duval_triangle`) rewritten; dashboard calls kept.
  - **Step 15**: `tests/TestConventionalMethods.m` - 66 tests, 66 pass (39 Duval examples + 1 Rogers example reproduced); log `tests/test_log.txt`.
    One failing test was my own wrong expected value (code was right); one audit failure (literal 7 in a new program) fixed in the code.
  - **Step 16**: `conventional_predictions.csv` (2481 = 827 x 3 rows), `conventional_counts.csv`, `impact_of_rules.csv`, `gate_by_class.csv`,
    `sanity_agreement_benchmark.csv` (plausibility only). Upper gate calls 242 records Normal, 160 of them true faults.
  - **Step 17**: Figure 4.4 `duval_<role>.png/.pdf/.csv` for the four data roles (825 of 827 records plotted).
  - Register: SW2, M8, M9, DF8-DF14 added; DF5 sha256 field repaired (was "System.Object[]"); glossary +9 terms; decisions_log D12.
  - Reports: `Step_14_Report.docx` ... `Step_17_Report.docx`; builders `build_step_reports_14_17.ps1`, `report_entries_14_17.ps1`,
    `update_register_steps14_17.ps1` in `00_Project_Admin/report_builder/`.

- **Corrections after the Steps 14-17 review (2026-10-11).** Decision **D13** (researcher): IEC T1 requires CH4/H2 > 1 (printed ">1 but NS" used as a
  condition), replacing the dual answer PD/T1 of D12 (2); **D14**: MATLAB steps may run through the MATLAB MCP (Steps 2-3 replaced for MATLAB).
  Code changed in `load_standards.m`, `bound_test.m` (and help texts); tests 66 -> **67 (all pass)**; Steps 14-17 outputs, code manifest, register and
  the four step reports were regenerated. Effects (827 records): IEC raw ND 204 -> 319 (200 after the gate); IEC PD alone 27 raw / 23 final; PD/T1 = 0.
  `impact_of_rules.csv` keeps the D12-stage figures (`*_before_D13`). Register: M8 DOI removed (not confirmable; venue/volume/pages/year confirmed online),
  M9 confirmed online. Simulink `rerun_2026-10-11` model loads/updates/simulates without error in MATLAB here; the error the researcher saw is still undiagnosed
  (needs the exact message).
## 2026-10-11 (continued)
- **Roadmap Step 18 DONE - MATLAB versus Python cross-check.** Independent Python implementation written from the 02_Standards
  tables and decisions D11-D13 (not translated from MATLAB): `06_Python_ML/src/conventional/conventional_methods.py`; Duval
  boundary distance by a different geometric method (distance to the nearest polygon of another zone, half-plane clipping).
  `step18_crosscheck.py` -> `08_Statistical_Analysis/cross_language_check.csv` (2481 rows), `11_Results/conventional/
  conventional_predictions_python.csv`, `03_Data/interim/step18_report.md`. Result: 2481/2481 rows identical (diagnoses, gate
  flags; ratios, percentages, distances within 1e-9; largest difference 3.4e-13) - PASS. New tests
  `tests/test_conventional_python.py` (45); suite 56/56. Register: DF15-DF17. `Step_18_Report.docx` written
  (builder `00_Project_Admin/report_builder/build_step_report_18.ps1` + `report_entries_18.ps1`).
- **Roadmap Step 19 DONE - preprocessing and feature pipelines.** `06_Python_ML/configs/ml_config.yaml` (all settings, traced to
  Analysis Plan 5.1-5.4 and decisions); `src/ml/features.py` (F1 log gases, F2 percentages, F3 log-ratios R1-R5 + Duval %, F4 all;
  stateless), `src/ml/pipelines.py` (FeatureBuilder -> median imputer -> StandardScaler -> BalancedClassifier with fold-local class
  weights Eq. 14; PlattSVC), `step19_build_pipelines.py` -> `configs/pipeline_catalog.csv` (24 pipelines, all run; no scores by design).
  **D15** (researcher): +1 ppm log-ratios, fold-median imputation of 2 undefined Duval percentages, fold-local class weights, no SMOTE.
  **D16** (procedural): SVM probabilities via CalibratedClassifierCV (SVC(probability=True) deprecated in scikit-learn 1.9);
  MLP solver L-BFGS (Adam did not converge; L-BFGS converged in 144/144 test fits). Tests `tests/test_pipelines.py` (31, incl.
  leakage tests: imputer/scaler/class weights see training rows only, also inside GridSearchCV inner folds); suite 87/87.
  Register M10-M12, DF18-DF20; glossary +13 terms. `Step_19_Report.docx` written.
- **Roadmap Step 20 DONE - nested cross-validation.** `06_Python_ML/src/ml/step20_nested_cv.py` (resumable, parallel; inner
  StratifiedGroupKFold(5) by group_id, seed 20261010 + 1000 x rep + fold; GridSearchCV f1_macro) - run
  `07_Experiments/2026-10-11_nestedcv_v1` (21:01-23:44, 6 workers): 1200/1200 tasks, every development record predicted once
  per repeat/model/feature set (105 360 rows), test sets not opened. `step20_summarize.py` -> Table 4.4
  `11_Results/tables/T4_4_cv_results.csv` (+ per-class F1), `reproducibility_check.csv` (4 tasks re-run: identical), `step20_checks.json`.
  Best mean macro-F1: Random Forest F4 0.850 (SD 0.038); XGBoost F4 0.842; majority baseline 0.046. 5 tasks with one
  ConvergenceWarning each (MLP on F2), kept and reported. **D17** (procedural). Register M13, DF21, DF22; glossary +11 terms
  (now 120). `Step_20_Report.docx` written.
- **Roadmap Step 21 DONE - model selection.** **D18** fixed at 21:55 (before any Step 20 result was read): 20 candidates
  (5 classifiers x 4 feature sets), corrected resampled t-test (Eq. 28, 49 df, n_test/n_train = 0.25), simplicity order
  LR < SVM < RF < XGBoost < MLP then fewer features. `src/ml/step21_select_model.py` -> `07_Experiments/model_selection.md`,
  `model_selection_tests.csv`. Best RF F4 vs next XGBoost F4: difference 0.008, t = 0.497, p = 0.621 (not significant); RF is
  the simpler -> **final pipeline: Random Forest on F4**. 12 of 19 other pipelines significantly worse (all F1/F2 ones).
  Tests `tests/test_model_selection.py` (4); suite 91/91. Register M14 (Nadeau & Bengio 2003, doi 10.1023/A:1024068626366),
  DF23. `Step_21_Report.docx` written.

## 2026-10-12
- **Roadmap Step 22 DONE - final fit and one-time test prediction.** **D19** (procedural, fixed before running). `06_Python_ML/src/ml/step22_final_fit.py`:
  RF/F4 tuned on all 439 development records (StratifiedGroupKFold(5), groups, seed 20261010) -> max_depth None, min_samples_leaf 1,
  inner macro-F1 0.864; pipeline saved `07_Experiments/2026-10-12_final_fit/final_pipeline.joblib` (SHA-256 1C46D103...) BEFORE testing;
  388 test records predicted once at 00:11:35 -> `11_Results/ml/ml_predictions.csv`; access log `11_Results/ml/test_set_access.log`;
  run-once guard verified; `--score-only` re-scores from saved predictions (hash unchanged). First look (`ml_first_look.csv`,
  `ml_first_look_confusion.csv`): macro-F1 internal test 0.812 (61 independent), IEC TC 10 power transformers 0.731 (58, merged
  classes), Li 2019 0.595 (86 independent); sensitivity sets 0.831 / 0.745 / 0.714. Main errors: IEC T3 -> T1/T2 (5 of 12), D1<->D2;
  Li T1 -> Normal (5) / PD (4). Register DF24, DF25; glossary +4 (124). `Step_22_Report.docx` written.
- **Roadmap Step 23 DONE - explaining the model.** **D20** (fixed before computing). `06_Python_ML/src/ml/step23_explain.py`:
  permutation importance (Eq. 38, R = 30, seed 20261010) on the three primary test sets at gas level (main ranking; correlated
  F4 features, Strobl et al. 2008) and feature level; exact TreeSHAP (shap 0.53) on 439 development + 388 test records
  (additivity error < 1e-12; dev-vs-test rank agreement Spearman 0.961). Gas ranking: internal C2H4 > C2H2 > H2/C2H6 > CH4;
  IEC TC 10 C2H2 > H2 > C2H4 > CH4 > C2H6 (C2H6 -0.033: does not transfer); Li C2H4 > C2H2 > H2 > C2H6 > CH4. SHAP top 3:
  Duval % C2H2, log R1, log R5. Engineering check 6/6 classes consistent; directions agree with IEC 60599 Table 2 (PD low
  CH4/H2; T1 low C2H4/C2H6; T2 middle band; T3 high C2H4/C2H6 and low C2H2/C2H4; D1/D2 high C2H2 share). Caveat: labels may
  be partly method-derived (D7) -> plausibility, not independent discovery. Figures F4_14, F4_15; `11_Results/explain/`.
  Register M15-M18 (Breiman 2001, Lundberg & Lee 2017 [pages TO VERIFY], Lundberg et al. 2020, Strobl et al. 2008), DF26;
  glossary +5 (129). `Step_23_Report.docx` written.
- **Roadmap Step 24 DONE - versioned model.** **D21**. `06_Python_ML/models/dga_model_v1.joblib` = byte copy of the Step 22 fit
  (SHA-256 1C46D103...; `.sha256`, `_meta.json`); loader `src/ml/model_io.py` (`load_model()` refuses a changed file); reload in a
  fresh process reproduced 388/388 test predictions, probability difference 0.0 (`reload_check.json`); `model_card.md` generated from
  result files (Mitchell et al. 2019). Tests `tests/test_model_v1.py` (3); suite 94/94. Register M19 (pages TO VERIFY), DF27;
  glossary +1 (130). `Step_24_Report.docx` written. **Stage D (Steps 19-24) complete.**
- **Roadmap Step 25 DONE - reduced-gas study.** **D22** (scope: researcher - selected pipeline only). `06_Python_ML/src/ml/step25_reduced_gas.py`
  (SubsetFeatureBuilder: F4 restricted to available gases; ratio only with both gases; Duval % only with CH4, C2H4, C2H2): 31 subsets x 50
  folds = 1550 nested RF tasks, run `07_Experiments/2026-10-12_reducedgas_v1` (00:54-09:32 incl. a sleep pause; 7 workers); identical folds;
  five-gas run = Step 20 exactly (after fixing the check: CSV re-read changed last bits; now compares task files). Best per size (macro-F1):
  1 gas C2H4 0.384; 2 C2H6+C2H4 0.584; 3 C2H6+C2H4+C2H2 0.733; 4 H2+C2H6+C2H4+C2H2 0.833 (mean loss 0.017 - CH4 dispensable, agrees with
  Step 23); 5 gases 0.850. Outputs `11_Results/reduced_gas/`. Tests `tests/test_reduced_gas.py` (5). Register DF28; glossary +3.
  `Step_25_Report.docx` written.

## 2026-10-12 - Simulink rerun: callback path fix
- Reproduced a load/update/sim error with MATLAB's path cleared of 05_Simulink_Model: "Error evaluating 'InitFcn' callback ... Unrecognized function or variable 'params_transformer'". The model's PreLoadFcn and InitFcn only called `params_transformer;`, and the only copy of that script is two folders above the model (05_Simulink_Model/params_transformer.m).
- Fix: both callbacks now add that folder (model folder/../..) to the path when the script is not found, then run it. Model re-saved; backup kept as `reference_build/rerun_2026-10-11/Transformer_Operating_Model_backup_before_callback_fix.slx`. With the path cleared the model now updates and simulates. With the path set it behaved the same as before.
- NOT confirmed: that this is the exact error the researcher saw (their message was not supplied). If a different error appears, send its exact text.

## 2026-10-12 - Step 26 (conventional methods with gases removed)
- Decision D23 added (rules 1-3 closed; rule 4, normality gate on incomplete data, PROPOSED - to be confirmed by the researcher).
- New: `04_MATLAB_Conventional/reduced_gas_diagnosis.m`, `run_reduced_gas_applicability.m`, `tests/TestReducedGas.m` (26 tests); `conv_config.m` got the fields `duvalGas`, `requiredGas`, `roles` (no rule changed); `tests/run_tests_and_log.m` runs both test classes (93 tests PASS); `code_manifest_step26.sha256` (the Steps 14-17 manifest stays unchanged).
- New: `06_Python_ML/src/conventional/step26_crosscheck.py`, `tests/test_step26_crosscheck.py` (4 tests): independent recomputation, identical on 465 of 465 rows.
- Results: `11_Results/conventional/conventional_applicability.csv` (465 rows), `conventional_applicability_checks.csv` (10 checks PASS), `08_Statistical_Analysis/cross_language_check_step26.csv`.
- Report `00_Project_Admin/Step_Reports/Step_26_Report.docx` (builder `report_entries_26.ps1`, `build_step_report_26.ps1`); register DF29-DF32 (`update_register_step26.ps1`), glossary +3 terms and decision pattern D1-D23.
- READMEs updated (04_MATLAB_Conventional, its tests, 11_Results/conventional); `11_Results/manifest.csv`: 3 rows added and the quoting of the four Duval figure rows repaired.
-  0_Project_Admin/Step_Reports/Data_and_Source_Register.docx rebuilt as version 4 (uild_register_v4.ps1): it had not been updated since Step 17 and now lists the files of Steps 18-26; the wrong test count '66 of 66' of version 3 corrected (67 of 67; 93 of 93 after Step 26). DF13 (unit-test log) fingerprint refreshed: the Step 26 run overwrote the 67-test log with the 93-test log.
- **Roadmap Step 27 DONE - minimum gas panel.** **D24** (fixed before computing). `06_Python_ML/src/ml/step27_minimum_panel.py`: macro-F1 per
  subset = mean over 10 repeats of out-of-fold macro-F1 (439 records); paired stratified percentile bootstrap B = 2000 (seed 20261010);
  delta = 0.05 (approved). **Minimum panel = H2+C2H6+C2H4+C2H2 (no CH4)**: macro-F1 0.834 [0.801, 0.867] vs 0.851 [0.819, 0.881]; loss
  0.017 [-0.006, 0.038]; only qualifying reduced subset; corrected-t sensitivity agrees (upper 0.0497, borderline). No conventional method
  usable with this panel (all need CH4). Best Duval-usable reduced panel (no C2H6) loses 0.076 [0.052, 0.103]. Table 4.9
  `11_Results/tables/T4_9_reduced_gas.csv`; Figures F4_16, F4_17. Tests `tests/test_minimum_panel.py` (2). Register M20, DF33 (DF29 was
  taken by Step 26); glossary +3. `Step_27_Report.docx`. **Stage E complete.**
- **Roadmap Step 28 DONE - merged predictions.** `06_Python_ML/src/stats/step28_merge_predictions.py` -> `08_Statistical_Analysis/merged_predictions.csv`
  (388 test records x 51 columns: true class + flags, ML class/merged/7 probabilities, per method raw / upper-gate / lower-gate answers and merged
  versions, boundary distances, ratios, Duval %) + `merge_checks.json`: none lost or duplicated, gate identical across methods. Upper gate calls
  78 test records Normal (internal 24 [10 truly Normal], IEC TC 10 10, Li 44 - all faults). Tests `tests/test_merged_predictions.py` (4);
  suite 109/109. Register DF34. `Step_28_Report.docx`.
- **Roadmap Step 29 DONE - measures with 95 % CIs.** **D25** (scoring, fixed before computing). `06_Python_ML/src/stats/step29_measures.py`
  (from merged_predictions.csv only): strict/conditional accuracy + coverage (Wilson), macro-F1, balanced accuracy, kappa, MCC, differences
  (paired stratified bootstrap B = 2000), per-class, confusion; sensitivity: lower gate, no gate, dual wrong. Strict accuracy (primary):
  internal ML 0.820 vs Duval 0.557 / IEC 0.475 / Rogers 0.328 (all gaps > 0); IEC TC 10 PT Duval 0.776, ML 0.724, IEC 0.638, Rogers 0.483
  (ML-Duval -0.052 [-0.172, 0.069], ML-IEC CI incl. 0); Li ML 0.628 vs Duval 0.453 (gap [0.035, 0.314]) but Duval no-gate 0.744 > ML.
  Gate strongly affects conventional scores. Tables T4_3, T4_5; Figures F4_5a-c, F4_8. Tests `tests/test_measures.py` (3); suite 112/112.
  Register M21-M23 (Gorodkin DOI TO VERIFY), DF35-DF36; glossary +5. `Step_29_Report.docx`.
- **Roadmap Step 30 DONE - significance tests.** D23 rule (4) CONFIRMED by the researcher. Online verification (Crossref): Gorodkin DOI
  10.1016/j.compbiolchem.2004.09.006, Mitchell pp. 220-229, Wilson 1927, Lundberg & Lee pp. 4765-4774 (DBLP); Duval 2002 (M24) added - full
  text not accessed; whether Duval zones were tuned on IEC TC 10 remains TO VERIFY. **D26**. `06_Python_ML/src/stats/step30_tests.py`:
  Friedman (6 models, F4, 50 folds) chi2 158.06, p < 0.001, CD 1.066 - RF (1.76) ~ XGB (2.28), RF > LR/SVM/MLP/baseline. Cochran's Q
  significant on all sets. McNemar+Holm (gate): internal ML > all 3; IEC TC 10 ML > Rogers only (vs IEC p_holm 0.453; vs Duval b=6 c=9,
  p 0.607); Li ML > all 3 (vs Duval p 0.033); no gate: IEC none significant, Li vs Duval not significant (Duval nominally better).
  Hypothesis: criterion 1 NOT MET on the main benchmark -> NOT SUPPORTED there; met on internal and Li (gate); criterion 2 met vs Rogers/IEC,
  not vs Duval (always answers). Tables T4_6, T4_7; Figures F4_7, F4_11. Tests `tests/test_significance.py` (5); suite 117/117. Register
  M25-M30, DF37-DF38; glossary +5. `Step_30_Report.docx`.
- **Roadmap Step 31 DONE - boundary hypothesis.** **D27**. `06_Python_ML/src/stats/step31_boundary.py`: logistic regression of ML-method
  disagreement on standardised boundary distance, 205 primary test records pooled (1 record excluded for IEC/Rogers: infinite distance).
  With gate: OR/SD Rogers 0.80 [0.60, 1.07], IEC 1.01 [0.77, 1.33], Duval 0.82 [0.62, 1.08] -> criterion 3 NOT MET. No gate: Duval 0.49
  [0.34, 0.69] (gate masks the boundary pattern). IEC TC 10 alone: Rogers significant, IEC/Duval not. No separation (Firth not needed).
  **Final verdict: hypothesis NOT SUPPORTED on the main benchmark**; partly supported on internal and Li sets. Table T4_8; Figure F4_12;
  `hypothesis_criteria.json` completed. Tests `tests/test_boundary.py` (3); suite 120/120. Register M31 (Firth 1993), DF39; glossary +2.
  `Step_31_Report.docx`.
- **Study 2 started - Roadmap Step 31A DONE (pre-registration).** Researcher asked for an improvement study. **D28**. Protocol
  `00_Project_Admin/Study2_Protocol.docx` (leave-one-source-out over DISTRAIN, DISTEST, IECTC10 power transformers, LI2019; dedup priority
  IECTC10 > DISTRAIN > DISTEST > LI2019; near-duplicate groups across sources; 6 classes (T1/T2 merged); models A released / B pooled RF-F4 /
  C hybrid with conventional inputs; macro-F1 primary; bootstrap + McNemar/Holm; reject option at IEC/Rogers coverage (Chow 1970); three
  pre-specified decision rules; exploratory label) fingerprinted 2026-10-12T16:24:48 before any Study 2 model
  (`03_Data/study2/study2_protocol.sha256`). **Roadmap Version 3**: Steps 31A-31F added (overview table + Stage F), Step 32 extended; v2
  archived in `00_Project_Admin/archive/`. PROJECT_PLAN.md Phase 6b. Register M32 (Chow 1970), DF40; glossary +6. Confirmatory outputs
  verified unchanged. `Step_31A_Report.docx`.
- **Roadmap Step 31B DONE - Study 2 pooled data set.** `06_Python_ML/src/study2/step31b_pooled.py` (protocol fingerprint checked;
  near-duplicate rule imported from step10_folds): 125 exact cross-source copies removed (LI2019->IECTC10 115, DISTEST->IECTC10 9,
  LI2019->DISTEST 1); 1 label conflict (LI2019_0158 D1 vs DISTEST_0002 PD; kept PD by priority); 702 records, 643 primary scope
  (DISTRAIN 439, DISTEST 61, IECTC10 58, LI2019 85); no cross-source near-duplicate group -> no training removal in any LOSO split;
  Step 10 groups preserved. Files `03_Data/study2/` + manifest `study2_data.sha256`. Tests `tests/test_study2_pooled.py` (5); suite 125/125.
  Register DF41. `Step_31B_Report.docx`.
- **Roadmap Step 31C DONE - Study 2 leave-one-source-out runs.** `src/study2/study2_models.py` (HybridFeatures: F4 + one-hot raw answers over
  fixed categories + gate flags + distances with missing flags = 49 inputs; WeightedBalancedClassifier), `src/study2/step31c_loso.py`:
  3 variants (primary, equal_source_weight, iec_all) x 4 held-out sources x models B and C = 24 tuned fits (Step 20 grid, grouped inner CV,
  seed 20261012+i) + model A (dga_model_v1) on external sources; 4443 predictions in `07_Experiments/2026-10-12_study2_loso/`; rerun of 2 tasks
  identical; leakage-free splits tested. Computer slept mid-run (one fit time includes the pause). Tests `tests/test_study2_models.py` (5);
  suite 130/130. Register DF42. `Step_31C_Report.docx`.
- **Roadmap Steps 31D-31E DONE - Study 2 results and decisions (EXPLORATORY).** **D29** (clarification before computing: rule 3 uses model
  C; best conventional by strict accuracy; tau fixed in bootstrap). `src/study2/step31d_measures.py`: macro-F1 (primary) IEC TC 10 held out
  A 0.731 / B 0.782 / C 0.821 vs Duval 0.752, IEC 0.731; Li 2019 A 0.628 / C 0.654 vs Duval 0.626; contrasts B-A and C-B mostly positive
  but CIs include 0; C-B significantly negative with DISTRAIN held out (-0.050). Reject option (C at IEC coverage): +0.090 / +0.295 /
  +0.098 [-0.008, 0.212] / +0.343 over IEC conditional accuracy (DISTRAIN/DISTEST/IECTC10/LI2019). `step31e_decisions.py`: rule 1 NOT MET
  (0/3), rule 2 NOT MET (0/4), rule 3 MET (strict 2/3, lenient 3/3; readings agree); iec_all sensitivity meets rule 1 (fragile).
  Tables T4_12, T4_13; Figures F4_23, F4_24. Fix: model A reused for equal-weight variant (primary unchanged). Report-builder lesson:
  PowerShell variable names are case-insensitive ($M vs $m, $C vs $c clash). Register DF43-DF45; glossary +2. Step_31D/31E reports.
- **Roadmap Step 31F DONE - confirmation-data search (Study 2 complete).** Searched Mendeley Data, Zenodo, IEEE DataPort, PMC/open journals,
  engrXiv, CIGRE: no openly licensed, inspection-confirmed, independent data set found. Candidates: Shutenko & Kulyk 2023 (Mendeley, CC BY,
  25 records, labelling unknown), Montero Jimenez & Gomez-Ramirez 2026 (Mendeley, CC BY, contents unknown), Adu-Gyamfi 2026 KNUST engrXiv
  (589 "field-verified", source/licence unknown), two subscription DataPort sets, Heliyon 2024 (no per-case data), CIGRE TB 771 (data not
  released). Recommended: Ghanaian utility inspection records via Prof. Annan (draft letter exists); contact KNUST and Ukrainian authors.
  Record `03_Data/provenance/study2_confirmation_search.md`; register C1-C3, DF46. `Step_31F_Report.docx`.
- **Roadmap Step 32 DONE - all Chapter 4 tables and figures (Stage F complete).** `06_Python_ML/src/analysis/make_chapter4.py` runs Steps 11,
  20 (--table-only, new flag), 23, 27, 29, 30, 31, 31D, 31E and new `chapter4_figures.py` (Figures 4.6 CV box plots, 4.9a-c main comparison,
  4.10 per-class F1 with bootstrap CI -> `08_Statistical_Analysis/per_class_ci.csv`, 4.13 Duval-triangle disagreements). plotstyle.save: PDF
  without CreationDate. 79 files; manifest `11_Results/chapter4_manifest.sha256`; `--check` (move aside, rebuild, compare): 79/79 identical
  (`chapter4_check.txt`); all registered result files unchanged. Register DF47. `Step_32_Report.docx`.

## 2026-10-12 - Step 33 (Simulink transformer operating model)
- Decisions D30 (Simulink steps run through the MATLAB MCP connection; proposed) and D31 (build details; clause 4 "Simulink arithmetic, not pure Simscape" proposed). First numbered D24/D25 by mistake (already used by Steps 27-31) and renumbered before registration.
- New: `05_Simulink_Model/Transformer_Operating_Model.slx` (7 subsystems, 84 blocks, 19 annotations), `build_Transformer_Operating_Model.m` (builds it from Build Guide Part B), `verify_step33.m` (9 checks, all PASS), `code_manifest_step33.sha256`, `figures/Figure_3_4_top_level.png` + 7 subsystem diagrams, `results/step33_*.csv` (checks, structure differences, block settings, block inventory, run summary).
- `params_transformer.m`: new variable `T_zero_C_in_K` (273.15 K; the guide typed it into 4 blocks). Callbacks are path-safe.
- Structure equals the reference build (84 blocks; only the 273.15 K offset differs). 24 h run: K 0.9839, oil 78.638 degC, hot-spot 100.276 degC = analytic steady state and = reference.
- Register: ST6 (IEC 60076-7:2018, not obtained), SW3 (pandapower), SW4 (Alliander), DF48-DF53; 12 glossary terms; Word register rebuilt as version 5 (`build_register_v5.ps1`).
- Report `Step_33_Report.docx` (`report_entries_33.ps1`, `build_step_report_33.ps1`); READMEs updated.

## 2026-10-13 - Step 34 (model checks)
- Decision D32 (check set; fixes; acceptance of remaining warnings PROPOSED; D1 item 7 open).
- Model Advisor on `Transformer_Operating_Model.slx`, 132 checks (groups design, simscape, simulink, sl, maab): first run 115 passed / 16 warnings / 1 incomplete; after fixes 120 / 11 / 1, 0 failed. Report `05_Simulink_Model/checks/model_advisor_report.html`; `model_advisor_accepted.csv` gives a reason for each of the 12 non-passed checks.
- Fixed in `build_Transformer_Operating_Model.m` (model rebuilt): Sqrt block replaces deprecated Math `sqrt`; Inf/NaN, unconnected input/output/line, duplicate data store and bus-as-vector diagnostics set to error; Exp block name shown; new variable `X0_pu` (0.5 pu block default, TO VERIFY) found by the all-dialog-field scan (245 values with a digit, 0 typed parameter numbers). `params_transformer.m`: units and source tags. `verify_step33.m`: 7 expected differences (Sqrt block, X0_pu); 9/9 pass; logged results identical to reference (0.00e+00); 24 h run K 0.9839, 78.638 / 100.276 degC.
- Part D1 checklist `checks/step34_checklist_D1.m`: 13 of 14 rows pass; D1.6 (app) not applicable yet, D1.7 (second person) open. Own checker bug fixed (MATLAB `\b` is backspace).
- Register: SW5, DF54-DF58 (DF48, DF50, DF52 updated to the post-Step-34 files; Step 33 model = DF58); 4 glossary terms; Word register version 6. Report `Step_34_Report.docx` (`report_entries_34.ps1`, `build_step_report_34.ps1`).

## 2026-10-13 - Step 35 (verification against IEC 60076-7)
- Decision D33 (test design and criteria, fixed before the run). New `05_Simulink_Model/verify_step35.m`: Test 1 rated load, Test 2 load step 0.6 -> 1.2 pu; reference A (ode15s on the IEC equations driven by the measured K), reference B (closed form, Test 1); 15 checks all PASS.
- Results: e_max after 10 min (version 2, solver RelTol 1e-4) top-oil 0.0014 / 0.0015 K, hot-spot 0.0129 / 0.0152 K (limit 0.1 K); RMSE <= 0.0013 K; 63.2 % rise time 75.002 min; baseline of 3 Oct reproduced. Whole-run hot-spot difference up to 0.033 K (85 s), never above 0.1 K. Version 1 (RelTol 1e-3) gave 0.0599 / 0.0315 K; after Step 37 it rose to 0.104 K (fail) - cause was the solver tolerance, fixed in Steps 35/37 (D33 amendment).
- Table 4.10 `11_Results/tables/T4_10_simulink_verification.csv`; Figure 4.18 `11_Results/figures/F4_18_simulink_verification.(png|pdf|csv)`; SDI session in results/.
- Register DF59-DF63, 5 glossary terms, Word register v7; report `Step_35_Report.docx`.

## 2026-10-13 - Step 36 (operating scenarios)
- Decision D34 (scenarios and checks fixed before simulation; the researcher's "proceed" taken as approval of the proposed three scenarios and their illustrative values).
- New `05_Simulink_Model/scenarios.m`, `run_step36.m`; results `sim_rated/daily/overload.mat`, `step36_*.csv`, `step36_sdi_session.mldatx`; Figure 4.19a-c in 11_Results/figures. 13/13 checks PASS (runs repeat to 0.00e+00; model file unchanged; S1 = default model run).
- Peak hot-spot 100.28 / 99.91 / 129.03 degC (rated / daily at 21.0 h / overload at 10.0 h); loss of life in the shown 24 h 27.88 / 6.45 / 38.58 h. No IEC temperature limits applied (standard not obtained).
- Register DF64-DF68, 3 glossary terms, Word register v8; report `Step_36_Report.docx`.

## 2026-10-13 - Step 37 (DGA sampling-event subsystem) and solver-tolerance fix
- Decision D35 (design and tests fixed before building; two amendments). New subsystem SS8 in `Transformer_Operating_Model.slx` (13 blocks: clock, constants, comparison, counting, logic, logging; no ports, not connected to SS1-SS7): outputs `record_index` and `sampling_event` at `t_sample_h` = 6, 12, 18, 22 h (illustrative); `get_sampling_events.m` looks up the held-out `record_id` (dga_master.csv, only columns record_id and data_role are read). New `verify_step37.m`: 10/10 checks PASS (no gas block/name/signal; index steps at the set times; ids exist, role benchmark; Step 36 signals unchanged on common points, largest 0.0021 K; Step 33 checks 9/9).
- Found: after SS8 the Step 35 Test 1 hot-spot difference was 0.104 K (> 0.1 K limit). Cause: solver tolerance (RelTol 1e-3), not SS8 and not interpolation. Fix: `solver_reltol = 1e-4` in `params_transformer.m`, used by `build_Transformer_Operating_Model.m` (hot-spot 0.0129 K, ~63 s run). D33 amendment text corrected; Steps 33, 35, 36, 37 and the Step 34 Model Advisor (132 checks: 120 passed, 11 warnings, 1 incomplete, 0 failed = same as accepted) and checklist D1 re-run on the final model.
- Reports: `Step_35_Report.docx` and `Step_36_Report.docx` rebuilt as version 2; `Step_37_Report.docx` new. Register DF69-DF70, 3 glossary terms; manifests for Steps 34, 35 refreshed, `code_manifest_step37.sha256` new. Old Step 36 results kept in `results/before_step37/`.
## 2026-10-13 - Step 38 (FastAPI service)
- Decision D36 (design fixed before coding): ML diagnosis only (conventional methods computed in MATLAB, Step 39); strict input rules (five gases in ppm, numbers, finite, >= 0, optional record_id, other fields refused with HTTP 422); answer = class, 7 unrounded probabilities, confidence, model name/version/SHA-256, data version, notes; model loaded once via model_io.load_model() (fingerprint check, refuses to start otherwise); 127.0.0.1:8000 only, no log-in.
- New `09_API_FastAPI`: `app/main.py`, `app/schemas.py`, `openapi.json` (`export_openapi.py`), `tests/test_api.py` (21 tests), `step38_service_check.py`, `example_request.py`, `run_service.ps1`, `code_manifest_step38.sha256`; README rewritten.
- Found and fixed: NaN/Infinity input caused a server error while the error message was written (JSON cannot hold NaN); now HTTP 422 naming the field.
- Real server on the project laptop (Ryzen 5 3500U, 21.9 GB RAM): 388/388 held-out records identical to ml_predictions.csv (class and probabilities), 0 failed calls; response time median 55.3 ms, p95 62.1 ms (preliminary; formal Table 4.11 / Figure 4.21 in Steps 41-42). True labels not read; run noted in test_set_access.log.
- Tests: 151 pass (130 + 21). Register SW6, M33, M34, DF71-DF73 (Word register v9); 9 glossary terms. Report `Step_38_Report.docx` (`build_step_report_38.ps1`).

## 2026-10-13 - Step 39 (App Designer dashboard)
- Decision D37 (design, agreement rule, record rule, .mlapp production; fixed before building). New in 10_Dashboard_Client: DGADashboard.mlapp (20 components, Build Guide Part C names + ProbabilityTable, ModelLabel), dga_agreement.m, rewritten ml_diagnose.m (webwrite to /diagnose; NOT_CONNECTED / INVALID_INPUT / ERROR statuses, never stops), extended load_dga_record.m (record_id, equipment_type), erify_step39.m, 	ools/build_dashboard_mlapp.m + DGADashboard_code.txt (writes the .mlapp with the internal MLAPPSerializer), 	ools/make_figure_4_22.m.
- Check: 19/19 PASS. Three known records (IECTC10_0001 PD, _0036 D2, _0100 T3 family) and all 388 held-out records give the offline conventional answers, ML class and probabilities (difference 0). Service down, invalid gas, unreadable file: status text, no error.
- Figure 4.22 (annotated screenshot) in 11_Results/figures. Register DF71-DF73; report `Step_39_Report.docx`. The .mlapp should be opened once in App Designer (written with an internal serializer).

## 2026-10-13 - Step 40 (Simulink model linked to the dashboard)
- Decision D38 (model unchanged; events returned by the run; playback; default file; checks - fixed before the change). un_transformer_simulation.m now returns es.events (time_h, record_index, record_id from get_sampling_events). DGADashboard.mlapp rebuilt (22 components): Run Simulation runs the 24 h model, marks the 4 sampling events (6, 12, 18, 22 h) on the temperature plot and diagnoses the record of each event in time order (one function diagnoseRow for the button and the events); new EventTable with the simulated hot-spot temperature at each event. New ind_dga_row.m, erify_step40.m.
- Check: 13/13 PASS (full day from the button in about 1 s; events equal Step 37; each event diagnosis equals the offline results; model file unchanged; no service / no file / records missing from the file: run completes with a message; 19 checks of Step 39 re-run and pass). Found and fixed: hidden event lines were not removed on a second run (8 lines instead of 4).
- Layout made compact (the window is cut to about 750 px high on this computer); Figure 4.22 regenerated (11 labels). Register DF74-DF75 (DF72 updated); reports Step_40_Report.docx (new), Step_39_Report.docx (version 2).

## 2026-10-13 - Step 41 (end-to-end test bench)
- Decision D39 (scope = all 388 held-out records, schedule, response-time definition, log columns, checks - fixed before the run). New in `10_Dashboard_Client`: `run_testbench.m` (simulates the unchanged model with one sampling event every 15 min, 98 h; at each event find_dga_row -> load_dga_record -> conventional_diagnosis -> ml_diagnose -> dga_agreement; logs answers and times), `verify_step41.m`, `tools/make_figure_4_20.m`; `logs/testbench_log.csv` (388 rows), `testbench_run_info.json`, `testbench_events.mat`.
- Result: 388 rows, 0 failed calls; service response median 78.6 ms, 95th percentile 95.6 ms (all calls); 12/12 checks PASS (rows = held-out ids in order; roles 117/70/201; events at k x 15 min; same model hash before/after; no label column). Fidelity against the offline predictions and Table 4.11 / Figure 4.21 are Step 42.
- Note: the roadmap line names only internal test + benchmark records; all 388 were run and data_role is logged (needs researcher confirmation). Conventional diagnosis in MATLAB takes a median 278 ms per record (not investigated).
- Figure 4.20 (`11_Results/figures/F4_20_testbench_run`). Register DF76-DF78; report `Step_41_Report.docx`.

## 2026-10-13 - Step 42 (fidelity and response time; Stage H complete)
- Decision D40 (rules fixed before computing): compare testbench_log.csv (Step 41) with ml_predictions.csv and conventional_predictions.csv (column result, after the upper gate); F = matches / 388, failed or missing = mismatch; response time = response_ms over all 388 calls incl. 5 warm-up (sensitivity without); numpy linear percentile; target p95 < 1000 ms; no CI (one run).
- New `06_Python_ML/src/analysis/step42_integration.py` -> Table 4.11 (`T4_11_integration.csv`), Figure 4.21 (`F4_21_response_times`), `11_Results/integration/` (comparison, mismatches, checks, code manifest). Added to `make_chapter4.py`; MATLAB outputs (T4_10, F4_18-F4_20, F4_22) protected there; rebuild check 83/83 identical.
- Results: fidelity 388/388 (each role 100 %), probabilities and Rogers/IEC/Duval answers identical for all records, 0 failed calls; service response median 78.6 ms, p95 95.4 ms (95.6 ms by MATLAB prctile in the Step 41 report); conventional MATLAB median 277.5 ms; total per record median 468.7 ms, p95 548.4 ms, 11 records > 1 s (max 1964.1 ms, information only).
- Register fix: a parallel session had reused DF71-DF73 (Step 39) and overwritten the Step 38 entries; Step 38 files re-registered as DF79-DF81, Step 38 report rebuilt as version 2; glossary decision range restored (now D1-D40).
- Tests 154 pass (+3 `test_integration.py`). Register DF82-DF85, DF47 updated; Word register v10. Report `Step_42_Report.docx`.

## 2026-10-13/14 - Stage I: full thesis draft (Thesis_Draft_v1.docx, 112 pages)
- Scope changed by the researcher: the FULL thesis (front matter, Chapters 1-5, references, appendices) with Simulink and app snapshots and all key graphs, following the UMaT guide and the sample UMaT thesis in 12_Thesis (decision D41).
- New builder 12_Thesis/builder/: uild_thesis.py (Markdown-like sources -> .docx, standard library only), docx_writer.py (UMaT layout), acts.py (842 values read from result files, written to uild/facts_used.csv), 	ables.py (31 tables generated from CSVs), make_references.py (UMaT Harvard list + two-way citation check), make_diagrams.py (Fig. 3.1 framework, Fig. 3.3 nested CV), crop_simulink.py, inish_thesis.ps1 (Word COM: 30 equations, page-number fields; Save() at script level).
- Sources in 12_Thesis/source/ (meta.json, 00_front.md ... 07_appendices.md). Output 12_Thesis/Thesis_Draft_v1.docx: 46 figures, 31 tables, 30 equations, 86 references (all cited, all verified against Crossref or the register).
- Literature: Consensus research threads saved as  1_Literature/consensus/thread1_ml_for_dga.*, 	hread2_dga_background.* (verbatim snippets);  1_Literature/candidate_references.csv -> crossref_verified.csv (tools/crossref_verify.py).
- Simulink snapshots re-exported read-only from the final model ( 5_Simulink_Model/tools/export_thesis_snapshots.m, model SHA-256 unchanged) to 12_Thesis/figures/; UMaT logo cropped from the sample thesis title page to 12_Thesis/assets/umat_logo.png.
- Chapter 1 draft corrected (PURC 2024 finding; unverifiable CIGRE A2.62 percentages removed; objectives aligned with the unified objectives). Register items M20, M28 (DOI 10.2307/2332378) and M8 (DOI 10.1145/360767.360802) now confirmed via Crossref.
## 2026-10-14 - Thesis draft v2 (nine chapters, reviewer-ready)
- Researcher's feedback on v1: more chapters (6-8+), Chapter 3 = methods only, remove the internal decision codes (D1-D40 clash with fault classes D1/D2 and are undefined for readers), clearer structure for external reviewers, correctly labelled figure axes.
- New structure: 1 Introduction, 2 Literature Review, 3 Methods Used (with theory and equations of every classifier, test and model), 4 Data Collection and Preparation, 5 Diagnostic Performance, 6 Statistical Comparison and Disagreement Analysis, 7 Fewer Gases and Model Improvement, 8 Integrated Framework (Simulink snapshots, dashboard, test bench), 9 Conclusions and Recommendations; Appendices A (Simulink subsystems) and B (additional results). Decision table removed; no decision code appears in the thesis.
- New 12_Thesis/builder/thesis_figures.py: 32 thesis figures redrawn from the saved figure data with full axis titles and units, gas subscripts, consistent colours; Duval triangles with correct side scales; boundary curves refitted and checked against the saved coefficients. Output 12_Thesis/figures/thesis/.
- New tables (sensitivity to the gate, full test sets, final-model performance, explanation check) and facts (sensitivity variants, gate-made Normal counts). Added in the text: without the gate Duval reaches strict accuracy 0.897 on IEC TC 10 (from performance_measures.csv).
- Output 12_Thesis/Thesis_Draft_v2.docx (137 pages, 46 figures, 35 tables, 37 equations, 90 verified references). v1 sources kept in 12_Thesis/source_v1/.
## 2026-10-15 - Run-and-setup guide for the presentation
- New `00_Project_Admin/README_HOW_TO_RUN_AND_SETUP.md`: where the dashboard (10_Dashboard_Client/DGADashboard.mlapp), the Simulink model (05_Simulink_Model/Transformer_Operating_Model.slx) and the FastAPI service (09_API_FastAPI) are; how to run each; how to set the whole project up on another computer (copy without .venv, Python 3.12 venv from requirements.txt, MATLAB R2025b with Simulink/Simscape/Simscape Electrical, `project_setup`); presentation order; honest limits.
- Written from the project files; the commands were not re-run on a second computer (TO VERIFY on the presentation machine).

- 2026-10-15: new dedicated 00_Project_Admin/README_SIMULATION_PRESENTATION.md (Simulink setup and lecturer presentation only; commands not re-run on a second computer).
- 2026-10-15: new 00_Project_Admin/Simulation_Presentation_Guide.docx (plain-language Word version of README_SIMULATION_PRESENTATION.md; 5 pages, 12 pt, 1.15 spacing).
- 2026-10-15: new 00_Project_Admin/Simulation_and_Dashboard_Guide.docx (8 pages; open-the-file-and-click-Run steps for the Simulink model and the dashboard, replaces Simulation_Presentation_Guide.docx which was open in Word and could not be overwritten). New launchers 09_API_FastAPI/Start_ML_Service.bat (tested: service started, /health ok) and 06_Python_ML/Setup_Python_Environment.bat (not run: would alter the existing venv).

## 2026-10-15 - Dashboard finds the project folders itself
- Error reported by the researcher on starting the dashboard: "params_transformer is not found ... Error in DGADashboard/startupFcn (line 145)" - the app needed project_setup to have been run first.
- Fix: the STARTUP section of 10_Dashboard_Client/tools/DGADashboard_code.txt now looks upwards from the app file (then from the current folder) for the folder holding project_setup.m, adds 04_MATLAB_Conventional, 05_Simulink_Model and 10_Dashboard_Client to the path, then loads params_transformer. If the folder is not found the status line says so and the app stops with a clear error. DGADashboard.mlapp rebuilt with tools/build_dashboard_mlapp.m (backup of the old app and code text: 10_Dashboard_Client/tools/backup_before_autopath/).
- Tested in MATLAB R2025b with the three project folders removed from the path and the base workspace without parameters: (1) current folder = 10_Dashboard_Client, (2) current folder elsewhere with only the app folder on the path (what App Designer Run does) - both start with "Ready."; Run transformer simulation then gave "4 of 4 sampling events diagnosed" with the ML service running. verify_step40.m 13/13 PASS (includes verify_step39 19/19). New fingerprints: 10_Dashboard_Client/code_manifest_autopath_2026-10-15.sha256 (the step 39/40 manifests describe the earlier app and now differ on these two files, as expected).
- Not tested: a second computer.
- Guide 00_Project_Admin/Simulation_and_Dashboard_Guide.docx extended with Section 10 (connect everything by hand on a new laptop, five links with a click-test for each).

## 2026-10-15 - Dashboard starts the ML service itself (master control)
- Researcher request: running the dashboard must be enough; it showed "ML not connected" because the FastAPI service was started by hand.
- New `10_Dashboard_Client/ensure_ml_service.m` (checks GET /health; if down, starts `09_API_FastAPI/run_service.ps1` hidden and waits up to 90 s) and `stop_ml_service.m` (stops the process listening on 127.0.0.1:8000). DGADashboard startupFcn calls ensure_ml_service; `diagnoseRow` also restarts it once if a diagnosis returns NOT_CONNECTED. Code text `tools/DGADashboard_code.txt`, app rebuilt with `tools/build_dashboard_mlapp.m`.
- Tested in MATLAB R2025b from a cold state (service stopped, project folders off the path): dashboard status "Ready. ML service connected."; Run transformer simulation -> 4 of 4 sampling events diagnosed. First attempt failed (nested quoting when launching Python from MATLAB); fixed by launching run_service.ps1.
- Service stays running after the dashboard is closed; stop it with `stop_ml_service` in MATLAB. Not tested on a second computer.

## 2026-10-15 (later) - Dashboard freeze fixed; explanation panel; verify_step43 23/23
- Researcher report: the software froze; asked for the dashboard as master control, explanation text for the viewer, a full report, and working before stopping.
- Cause found by reproduction (D42): service started by `system()` shared MATLAB's 4 KB output pipe -> service blocked after ~61 requests, MATLAB waited 248.4 s on request 62. Also: a hung service kept port 8000 (old code then waited 90 s in vain); first simulation of a session 54 s without a message.
- New: `09_API_FastAPI/launch_service_detached.ps1`, `stop_service.ps1`; rewritten `ensure_ml_service.m` (returns started flag; replaces a hung service; progress callback), `stop_ml_service.m`; new `10_Dashboard_Client/dashboard_explain.m` (explanation text); `DGADashboard.mlapp` rebuilt from `tools/DGADashboard_code.txt` + `build_dashboard_mlapp.m` (4th column "How to read this result", Restart ML service button, busy lock, progress windows, model warm-up at start, event-row click, close stops own service; window 1350 x 690 for 1366 x 768 screens). Old files: `tools/backup_before_masterctl/`.
- Checks: `verify_step43.m` 23/23 (400-request stress test, hung-service recovery, cold start, run + explanation, all 388 records' explanation text, service stopped during use, close behaviour, 19 + 13 older checks). Test-set-up bugs found and fixed in the test (temp path with a space; execution policy), not in the app.
- Report: `00_Project_Admin/Step_Reports/Dashboard_MasterControl_Report.docx`; register DF86-DF89; decision D42 (PROPOSED); README_HOW_TO_RUN_AND_SETUP.md section 5 rewritten.
- Not done / open: Figure 4.22 of the thesis still shows the earlier layout (candidate replacement: `10_Dashboard_Client/results/step43_dashboard_screenshot.png`); not tested on a second computer; `dashboard_explain.m` number format changed after the last full run (checked on one record).
## 2026-10-17 - Dashboard redesign (verdict, scenarios, sample sets, record picker); project explained simply; thesis v3
- Researcher complaint: the app showed numbers only, always the same four samples (all PD), no comparison of the methods, no healthy/fault state, no interpretation. Asked for both varied demo records and a record picker, a step-by-step standard layout, and a layman explanation of the whole project.
- New (D43, PROPOSED): `dashboard_verdict.m` (healthy/fault/watch/check by IEC 60599 typical-value gate + vote of Rogers, IEC, Duval, ML), `dashboard_samples.m`, `sim_window.m`, `dashboard_explain.m` ('steps', 'label'), `run_transformer_simulation(profile, opts)`; `DGADashboard.mlapp` rebuilt (75 components; banner, five cards, sample table, tabs Charts / Step by step / Explanation / Tables / Simulation; scenario and sample-set drop-downs; fault-type picker). Components list moved to `tools/dashboard_components.m`. Previous files: `tools/backup_before_redesign/`.
- Checks: `verify_step44` 18/18; `test_dashboard_verdict` 10/10; `verify_step43` 22/23 at first (verify_step40 11/13: default-file message and skipped missing records changed) -> fixed in the app; `verify_step40` 13/13 and `verify_step39` 19/19 after the fix.
- Descriptive result (388 held-out): of 346 known faults the verdict was FAULT for 242, HEALTHY for 7, WATCH/CHECK for 97; exact type right for 217 of 242, right family 240 of 242 (`results/dashboard_verdict_summary.csv`).
- Documents: `00_Project_Admin/Project_Explained_Simply.docx` (layman); thesis Chapter 8 dashboard section rewritten, Figure 8.6 regenerated (`make_figure_4_22.m`), `Thesis_Draft_v3.docx`. Register DF90-DF93.
- Clean-up before the GitHub backup (17 Oct): .gitignore, .gitattributes; README current-state and repository notes; how-to README section 5 rewritten for the new screen; garbled dash in decisions_log fixed;  0_Project_Admin/manifest_status_2026-10-17.csv; stray backup moved to 12_Thesis/source_backup/; all tests re-run (Python 154, MATLAB 93, Simulink verify 33/35/37, dashboard 39/40/43/44) and passed; step report Step_Reports/Dashboard_Redesign_Report.docx. Git was installed later the same day and the project was pushed to a private GitHub repository (commit e7b9794).

## 2026-10-17 (later) - Healthy state made reachable (researcher: 'the app always predicts fault, and warning, no healthy state')
- Cause measured: 346 of the 356 held-out records with a known class are faults (10 Normal); only 16 of 388 records give a green HEALTHY banner because the ML model has no normal-gas check and names a fault on 62 of the 78 records whose gases are all within typical values (amber WATCH). Not a coding error.
- New: sample set 'Healthy records only' (dashboard_samples('healthy')), editable gas table with button 'Diagnose the values typed above' (diagnoseGas), run summary 'Verdicts: n healthy, n fault, n watch/check' in the status line, welcome text. erify_step44 now 22 checks (22/22).

## 2026-10-17 (evening) - Dark-theme colours; data-origin statement
- Researcher screenshots: card texts and the Duval Triangle labels were unreadable in MATLAB's dark theme (light default text on pale tints; dark ink on a dark background). Fix: explicit dark text on the cards, the three chart areas and the simulation tab always on white with dark text (styleAxes), event labels and legend dark. Checked with screenshots in the dark theme and erify_step44.
- README: added the statement on data origin (no generated gas data; open TO VERIFY on possible resampling in the Dissanayake files; what is illustrative).
