# Intelligent Power Transformer Fault Diagnosis Using DGA and Machine Learning

MPhil research project (UMaT, Tarkwa): an integrated MATLAB/Simulink–Python framework that produces conventional
(Rogers, IEC 60599, Duval Triangle) and machine-learning fault diagnoses side by side, and tests where and why they disagree.

Full plan, phases and dataset links: [PROJECT_PLAN.md](PROJECT_PLAN.md).

## Folder map

| Folder | Phase | Contents |
|---|---|---|
| [00_Project_Admin](00_Project_Admin/README.md) | 0 | Original briefs, decisions log, timeline |
| [01_Literature](01_Literature/README.md) | 2 | Reference register, review matrix, papers |
| [02_Standards](02_Standards/README.md) | 2 | Threshold tables transcribed from the standards |
| [03_Data](03_Data/README.md) | 1 | Raw, interim, processed data and data cards |
| [04_MATLAB_Conventional](04_MATLAB_Conventional/README.md) | 3 | Conventional methods as MATLAB functions + tests |
| [05_Simulink_Model](05_Simulink_Model/README.md) | 3 | Simulink model of the conventional-diagnosis layer |
| [06_Python_ML](06_Python_ML/README.md) | 4–5 | ML pipeline and reduced-gas ablation |
| [07_Experiments](07_Experiments/README.md) | 4–6 | One folder per run: config, seed, metrics |
| [08_Statistical_Analysis](08_Statistical_Analysis/README.md) | 6 | Significance tests, disagreement analysis |
| [09_API_FastAPI](09_API_FastAPI/README.md) | 7 | Diagnostic service |
| [10_Dashboard_Client](10_Dashboard_Client/README.md) | 8 | MATLAB dashboard |
| [11_Results](11_Results/README.md) | 4–8 | Script-generated figures and tables |
| [12_Thesis](12_Thesis/README.md) | 9 | Thesis chapters |
| [13_Publication](13_Publication/README.md) | 9 | Journal manuscript |

## Rules that apply everywhere

1. No citation is used until its DOI/URL has been opened and logged in `01_Literature/reference_register.csv`.
2. No threshold, zone coordinate or sample count is typed from memory; each carries a source and clause/page.
3. Every reported number traces to a run folder in `07_Experiments` (config + seed).
4. Results are reported as found; nothing is tuned on test data.
5. Anything unverified is marked `TO VERIFY` until closed.

## Current state (17 October 2026)

- Thesis draft: `12_Thesis/Thesis_Draft_v3.1.docx` (138 pages); sources in `12_Thesis/source`, build chain in `12_Thesis/builder`.
- Dashboard: `10_Dashboard_Client/DGADashboard.mlapp` (start with `DGADashboard` in MATLAB); how to run everything: `00_Project_Admin/README_HOW_TO_RUN_AND_SETUP.md`.
- The whole project in plain words: `00_Project_Admin/Project_Explained_Simply.docx`.
- Decisions: `00_Project_Admin/decisions_log.md` (latest D43, proposed). Session history: `PROJECT_MEMORY/SESSION_SUMMARY.md`, `CHANGELOG.md`.
- Checks: 154 Python tests (`06_Python_ML/tests`, `09_API_FastAPI/tests`), 93 MATLAB tests (`04_MATLAB_Conventional/tests`), dashboard checks `verify_step39`, `40`, `43`, `44`.

## Notes for the repository copy

- **Private repository recommended.** It holds unpublished thesis work. A licence for the project's own code and text has not been chosen yet (TO DECIDE by the researcher).
- **Not included in the repository:** `03_Data/raw/` (IEEE DataPort files, "not redistributed by this project", terms TO VERIFY; see `03_Data/provenance/data_card_*.md`), the Python environment `06_Python_ML/.venv` (recreate with `06_Python_ML/Setup_Python_Environment.bat`), generated Simulink caches (`slprj`, `*.slxc`), older thesis drafts, and the private chat transcript. File fingerprints of the data are in `03_Data/data_version_1.0.sha256`; the processed table `03_Data/processed/dga_master.csv` is included, so check the data terms before making the repository public.
- **Fingerprints:** `*.sha256` files next to the code are historical records of each step. Files that were deliberately changed in later steps no longer match their old fingerprint (for example the dashboard files after the redesign of 17 Oct 2026); the current ones are `10_Dashboard_Client/code_manifest_redesign_2026-10-17.sha256`. Status of every manifest: `00_Project_Admin/manifest_status_2026-10-17.csv`.
## Where the data come from, and what is not data (statement of 17 Oct 2026)

- **No gas value is created by this project's software or by the AI assistant.** Every gas value shown in the dashboard, the tests and the thesis comes from a record of `03_Data/processed/dga_master.csv` (827 records from the IEC TC 10 database of Duval and dePablo (2001), the IEEE DataPort files of Dissanayake, and the Li (2019) data set), read as it is. The Simulink model never produces a gas value. Oversampling such as SMOTE was not used. The only values not taken from a file are those a user types into the gas table, and the fixed test inputs inside `verify_step44.m`; neither is stored as data.
- **Open point (TO VERIFY):** the IEEE DataPort page of the Dissanayake files (509 of the 827 records) says "class-balanced" but its counts are not balanced; whether that data set contains synthetic or resampled records is not documented (`03_Data/provenance/data_card_ieee_dataport_*.md`, decision D7). The project treats these files as supporting data and uses the inspection-labelled IEC TC 10 records as the main benchmark. Ask the data authors before any public release.
- **Illustrative, not measured:** the operating scenarios (load profiles), the sampling times, the pairing of a record with a simulation time, and the thermal constants of the transformer model. They give context and are described as such in the dashboard and the thesis.
- **Display rules, not validated results:** the verdict vote and the recommended actions in the banner.
- **Before publishing:** the IEEE DataPort files must not be redistributed (no licence stated, terms TO VERIFY); the repository is private for this reason.