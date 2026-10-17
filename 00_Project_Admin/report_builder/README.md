# Report builder (Word step reports) - copied from the session scratchpad on 2026-10-11

These PowerShell scripts build the step reports and the Data and Source Register through Word COM, following
PROJECT_MEMORY/claude_memory_notes/report_standard.md.

- helpers.ps1            - formatting helpers (H1N auto-numbered headings, Body, Bullet, AddTable, Eq + WhereList, ReportHeader)
- report_methods.ps1     - "Method used" content per step ($global:Methods) and MethodSection
- report_closings.ps1    - Achieved / Record / Data and sources / Helps / Open items / Abbreviations ($global:Closings, StepSources, Closing)
- build_step_reports_01_11.ps1, build_step_report_12.ps1, build_register.ps1 - the documents
- run_reports.ps1        - runs the Steps 1-11 builder with a log; render_pages.ps1 - page images for visual checks

Before reuse: change the $sp path at the top of each script to this folder (scripts were written for the scratchpad).
Known Word quirks: call $doc.SaveAs2 inline at script level (it hangs inside a function); save to a temp folder and
Copy-Item into the project; scripts with non-ASCII text must be saved as UTF-8 with BOM.
For a new step: add its entries to $global:Methods, $global:Closings and $global:StepSources, add new sources to
03_Data/provenance/data_and_source_register.csv and new terms to 00_Project_Admin/abbreviations_glossary.csv.
## Added 11 October 2026 (Steps 14-17)
- report_entries_14_17.ps1        - "Method used" and closing-section entries for Steps 14-17 (adds to $global:Methods, $global:Closings, $global:StepSources;
                                    dot-source it after helpers.ps1, report_closings.ps1 and report_methods.ps1)
- build_step_reports_14_17.ps1    - builds Step_14_Report.docx ... Step_17_Report.docx; every table is read from the saved output files
                                    (11_Results/conventional, 11_Results/figures, 02_Standards), nothing is typed by hand. Paths are the project paths;
                                    temporary files go to %TEMP%\dga_scratch. Run time is long (about 20-30 minutes) because Word builds every equation.
- update_register_steps14_17.ps1  - adds SW2, M8, M9, DF8-DF14 to the data and source register, repairs the DF5 fingerprints, adds 9 glossary terms and
                                    extends the decision pattern to D12. Safe to run again (rows are replaced, not duplicated). Re-run it after any output file changes,
                                    because it records the SHA-256 of the output files.
Word quirk: the function name H is a PowerShell alias (Get-History); use another name for helper functions.
## Added 11 October 2026 (Step 18)
- report_entries_18.ps1      - "Method used" and closing entries for Step 18 (dot-source after report_entries_14_17.ps1)
- build_step_report_18.ps1   - builds Step_18_Report.docx; tables computed from cross_language_check.csv and the prediction files

## Added 11 October 2026 (Step 19)
- report_entries_19.ps1, build_step_report_19.ps1 - Step 19 report; tables read from 06_Python_ML/configs/pipeline_catalog.csv

## Added 11 October 2026 (Steps 20-21)
- report_entries_20.ps1, build_step_report_20.ps1 - Step 20 report; sets $global:S20 from run_info.json and step20_checks.json, tables from T4_4_cv_results.csv
- report_entries_21.ps1, build_step_report_21.ps1 - Step 21 report; sets $global:S21, tables from 07_Experiments/model_selection_tests.csv
- report_entries_22.ps1, build_step_report_22.ps1 - Step 22 report; sets $global:S22; reads 11_Results/ml (first look, confusion, log) and final_fit.json; text statements verified by throw-checks
- report_entries_23.ps1, build_step_report_23.ps1 - Step 23 report; reads 11_Results/explain and inserts Figures 4.14-4.15 (Pic); IEC rules read from 02_Standards/iec_ratio_table.csv. Note: do not name a function Dir (PowerShell alias wins)
- report_entries_24.ps1, build_step_report_24.ps1 - Step 24 report; reads 06_Python_ML/models (meta, reload check, model card) and runs the test suite
- report_entries_25.ps1, build_step_report_25.ps1 - Step 25 report; reads the reduced-gas run folder and 11_Results/reduced_gas

## Added 12 October 2026 (Step 26)
- report_entries_26.ps1, build_step_report_26.ps1 - Step 26 report; reads conventional_applicability(.csv, _checks.csv), conventional_counts.csv, reduced_gas_results.csv, the Python cross-check CSV and test_log.txt; runs the new pytest file; statements are throw-checked
- update_register_step26.ps1 - adds DF29-DF32 to the register and 3 glossary terms (extends the decision pattern to D23). Safe to re-run.
- report_entries_27.ps1, build_step_report_27.ps1 - Step 27 report; reads Table 4.9 and minimum_panel.json, inserts Figures 4.16-4.17; dot-sources only its own entries file
- report_entries_28.ps1, build_step_report_28.ps1 - Step 28 report; reads merged_predictions.csv and merge_checks.json; runs the test suite
- report_entries_29.ps1, build_step_report_29.ps1 - Step 29 report; reads performance_measures.csv, differences.csv; inserts Figures 4.5a-c and 4.8; statements throw-checked
- report_entries_30.ps1, build_step_report_30.ps1 - Step 30 report; reads 08_Statistical_Analysis test outputs and hypothesis_criteria.json; statements throw-checked
- report_entries_31.ps1, build_step_report_31.ps1 - Step 31 report; reads boundary_regression.csv and hypothesis_criteria.json; final verdict table

## Added 12 October 2026 (Study 2)
- build_study2_protocol.ps1 - Study 2 protocol (pre-registration, D28)
- update_roadmap_v3.ps1 - roadmap Version 3 (Steps 31A-31F); backs up v2 to 00_Project_Admin/archive
- build_step_report_31A.ps1 - Step 31A report (self-contained Methods/Closings; checks confirmatory outputs unchanged)
- build_step_report_31B.ps1 - Step 31B report; reads 03_Data/study2 (checks, counts, LOSO sizes, dedup log) and verifies the manifest
- build_step_report_31B.ps1 / build_step_report_31C.ps1 - Study 2 data and run reports (self-contained Methods/Closings)
- build_step_report_31D.ps1 / build_step_report_31E.ps1 - Study 2 results and decisions. Lesson: PowerShell names are case-insensitive - do not use $M with a parameter $m (or $C/$c, $R/$r)
- build_step_report_31F.ps1 - Step 31F report (confirmation-data search)
- build_step_report_32.ps1 - Step 32 report; reads 11_Results/chapter4_manifest.sha256 and chapter4_check.txt

## Added 12 October 2026 (Step 33)
- report_entries_33.ps1, build_step_report_33.ps1 - Step 33 report; reads 05_Simulink_Model/results (checks, structure differences, block settings, block inventory, run summary) and inserts Figure 3.4 and the subsystem diagrams; statements are throw-checked. Variable names start with k_ (helper scripts reuse short names). Do not name helpers R, Rp, H (PowerShell aliases).
- update_register_step33.ps1 - adds ST6, SW3, SW4, DF48-DF53 to the register and 12 glossary terms (decision pattern D1-D31). Safe to re-run.
- report_entries_34.ps1, build_step_report_34.ps1 - Step 34 report (model checks); reads 05_Simulink_Model/checks (Model Advisor results, accepted warnings, Part D1 checklist, block-number scan) and results/step33_checks.csv; statements are throw-checked. The first-run Model Advisor numbers (115/16/1) are the only typed results (raw file overwritten). ASCII-only scripts; wrap `int + string` in `"" + ...`.
- update_register_step34.ps1 - adds SW5, DF54-DF58, updates DF48/DF50/DF51/DF52 and adds 4 glossary terms (decision pattern D1-D32). Safe to re-run.
- build_register_v6.ps1 - Word register version 6 (after Step 34).
- report_entries_35.ps1 (UTF-8 with BOM: Greek letters in equations), build_step_report_35.ps1 - Step 35 report; parses results/step35_verification_log_*.txt, step35_checks.csv and Table 4.10 (throw-checked), inserts Figure 4.18.
- update_register_step35.ps1 - adds DF59-DF63 to the register and 5 glossary terms (decision pattern D1-D33). build_register_v7.ps1 - Word register version 7.
- report_entries_36.ps1 (BOM), build_step_report_36.ps1 - Step 36 report (scenarios); reads results/step36_*.csv (throw-checked); a page break is inserted before Figures 4.19b and c so that captions stay with their pictures. update_register_step36.ps1 - DF64-DF68, 3 glossary terms (D1-D34). build_register_v8.ps1 - Word register version 8.

## Added 13 October 2026 (Steps 35-37)
- report_entries_35/36/37.ps1, build_step_report_35/36/37.ps1, update_register_step35/36/37.ps1 - Steps 35 (verification), 36 (scenarios), 37 (sampling-event subsystem). Step_35_Report.docx and Step_36_Report.docx are version 2 (rebuilt after the solver tolerance was set to 1e-4); Step_37_Report.docx is version 1.
- Builders read their numbers from 05_Simulink_Model/results; Step 35 parses step35_verification_log_*.txt with regular expressions, so change the log wording and the pattern together. In PowerShell, parenthesise string sums inside @(...) lists (the comma binds tighter than +); do not name a function Man (alias of help).

## Added 13 October 2026 (Step 38)
- build_step_report_38.ps1 (UTF-8 with BOM) - Step 38 report (FastAPI service); reads 09_API_FastAPI/checks/step38_service_check.json and step38_example.json and re-runs pytest (service tests and whole suite); statements are throw-checked. Self-contained Methods/Closings (no report_entries_38.ps1). Numbers are formatted with InvariantCulture.
- update_register_step38.ps1 - SW6, M33 (OpenAPI 3.1.0), M34 (RFC 9110), DF71-DF73; 9 glossary terms (API ... Fidelity; D1-D36). build_register_v9.ps1 - Word register version 9.

## Added 13 October 2026 (Step 42)
- build_step_report_42.ps1 (UTF-8 with BOM) - Step 42 report (= integration report); reads 11_Results/integration/integration_checks.json, Table 4.11, the test-bench log and run info, the Step 38 service check and chapter4_check.txt; re-runs pytest; statements throw-checked (incl. the 95.6 ms MATLAB prctile value of Step 41).
- update_register_step42.ps1 - DF82-DF85, DF47 refreshed (83 files), 2 glossary terms, decision range D1-D40. It STOPS if one of its IDs is already used by another step (parallel sessions: check the highest DF number before choosing new IDs). build_register_v10.ps1 - Word register version 10.
- update_register_step38.ps1 now writes DF79-DF81 (DF71-DF73 belong to Step 39) and no longer touches the decision-range glossary entry; build_step_report_38.ps1 gives report version 2.
