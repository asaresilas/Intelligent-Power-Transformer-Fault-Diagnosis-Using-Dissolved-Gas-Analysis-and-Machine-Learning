# Master Plan — Intelligent Power Transformer Fault Diagnosis (DGA + ML, MATLAB/Simulink–Python)

## 1. Context

The project folder holds two Word documents and nothing else:

- `DGA Chpater 1.docx` — MPhil thesis Chapter 1 (UMaT, J. A. Tagoe, supervisor Prof. J. Annan). Chapters 2–5 are empty headings.
- `Project_Overview_and_Objectives.docx` — an earlier project brief.

This plan turns them into a phased, publication-grade work programme, a folder structure with a README per folder, and a verified dataset list. Nothing is built yet; on approval, Phase 0 creates the folders and READMEs.

### 1.1 Issues found in the documents (must be settled, they affect the method)

| # | Finding | Proposed resolution |
|---|---|---|
| 1 | The two documents state **different objectives**. Chapter 1: integrated framework + conventional-vs-ML **disagreement analysis** (5 objectives). Overview: **reduced-gas-subset ablation** + benchmark (8 objectives). | Chapter 1 governs (it is the thesis). Keep the reduced-gas ablation as an added study — it is the strongest novelty and costs little once the pipeline exists. |
| 2 | Chapter 1 promises **seven gases** (incl. CO, CO2). The IEEE DataPort datasets it names contain **five** (H2, CH4, C2H6, C2H4, C2H2) — verified on the dataset pages. | Core study on the five hydrocarbon gases + H2. CO/CO2 only where the original IEC TC10 tables supply them. Reword Ch. 1 scope/limitations accordingly. |
| 3 | Chapter 1 says **six fault classes**; datasets label PD, D1, D2, T1, T2, T3 **plus Normal** (7 labels). | Six fault classes for diagnosis; Normal handled as a separate, stated decision (include as 7th class only if sample count supports it). |
| 4 | Overview forbids using Simulink to generate gas data; Chapter 1 calls the Simulink layer "physically grounded". | Simulink layer = conventional-diagnosis logic fed by **measured** gas data. No simulated gas concentrations. Say so explicitly in Ch. 3. |
| 5 | Author/degree differ between documents (BSc "Justice" vs MPhil "Jacob Addo Tagoe"); title page typos ("PHILOSOHPY", "DISSOLVE"). | Confirm with you; fix in thesis template. |
| 6 | Ch. 1 objective lists "XGBoost … and Gradient Boosting" as two of five classifiers — near-duplicates. | Keep both only if distinct (XGBoost vs scikit-learn HistGradientBoosting), or replace one with k-NN/Logistic Regression as a simple baseline. |

## 2. Datasets (verified links)

| Dataset | What it is | Link | Status |
|---|---|---|---|
| **IEC TC 10 database** (primary, internationally recognised) | Faults in service equipment **confirmed by visual inspection** — labels independent of the ratio methods, which avoids circular validation. Published in Duval & dePablo (2001), *IEEE Electrical Insulation Magazine* 17(2), 31–41. | https://doi.org/10.1109/57.917529 | Citation confirmed; DOI and exact case counts to be checked against the paper itself in Phase 1. Tables must be transcribed from the paper (needs IEEE Xplore access). |
| **IEEE DataPort "DGA dataset"** (Dissanayake, 2026) | 3 files: `DGA_train.xlsx` 584 records (class-balanced), `DGA_test_unseen.xlsx` 70, `IEC_TC_10_data.xlsx` 49. 5 gases + label 0–6 (Normal, PD, D1, D2, T1, T2, T3). | https://ieee-dataport.org/documents/dga-dataset (DOI 10.21227/27vy-h479) | Page verified. Free IEEE login needed to download. |
| **IEEE DataPort "Dissolved gas data in transformer oil"** (Li, 2019) | Fault-state DGA with fault type, 5 gases; has accompanying PDF documentation. | https://ieee-dataport.org/documents/dissolved-gas-data-transformer-oil-fault-diagnosis-power-transformers-membership-degree (DOI 10.21227/h8g0-8z59) | Page verified. Free IEEE login needed. |

**Caveats to resolve in Phase 1 (not assumed):**
- How the Dissanayake training file was "balanced" (real samples vs synthetic oversampling) and where its labels come from is **not stated** on the page. If labels were produced by a ratio method or samples are synthetic, that file cannot be used for the ML-vs-conventional benchmark — only for supplementary training. Ask the author via DataPort if undocumented.
- Its IEC TC10 file has 49 records, fewer than the original publication — treat the 2001 paper as the authoritative source.
- The datasets overlap (several derive from IEC TC10). De-duplicate across all files before any split.
- You download the files (login is yours); I do not create accounts or enter credentials.

Standards needed (purchased/library copies; thresholds are transcribed from these, never from memory or blogs): IEC 60599 (current edition), IEEE C57.104-2019, Duval (2002) for the Triangle, Rogers' original ratio paper.

## 3. Folder structure (each folder gets a `README.md`)

```
00_Project_Admin/        original .docx briefs, decisions log, timeline, supervisor notes
01_Literature/           reference register (CSV: citation, DOI, verified Y/N, where used), PDFs, review matrix
02_Standards/            IEC 60599 / IEEE C57.104 / Duval / Rogers — threshold tables transcribed with page refs
03_Data/
   raw/                  untouched downloads + SHA-256 checksums (read-only)
   interim/              merged, de-duplicated, unit-harmonised
   processed/            final modelling table + fixed fold assignments
   provenance/           data card per dataset: source, licence, label origin, gases, counts
04_MATLAB_Conventional/  Rogers, IEC ratio, Duval Triangle as MATLAB functions + unit tests
05_Simulink_Model/       Simulink model wrapping the 04 functions; illustrative electrical-context subsystem
06_Python_ML/            src/ (preprocess, features, train, evaluate, ablation), configs/, tests/, environment file
07_Experiments/          one dated folder per run: config, seed, metrics, fold predictions
08_Statistical_Analysis/ CIs, McNemar, kappa, Friedman/Nemenyi, boundary-distance analysis
09_API_FastAPI/          service, versioned pipeline artefact, schema, API tests
10_Dashboard_Client/     MATLAB App Designer client showing both diagnoses side by side
11_Results/              figures/ and tables/ generated by script only (no hand-edited numbers)
12_Thesis/               chapters 1–5, template, figures linked from 11
13_Publication/          journal manuscript, target-journal notes, cover letter, reproducibility statement
```
Root: `README.md` (map + how to reproduce), `PROJECT_PLAN.md` (this plan), `CHANGELOG.md`.

Each README states: purpose, inputs, outputs, procedure, acceptance criteria, which thesis section it feeds.

## 4. Phases

**Phase 0 — Setup (week 1).** Create folders + READMEs; move the two .docx into `00_Project_Admin`; git init; record MATLAB version and installed toolboxes (Simulink, Statistics and ML Toolbox, App Designer); Python environment pinned. Settle the six issues in §1.1.

**Phase 1 — Data acquisition and provenance (weeks 1–3).** Download datasets to `raw/`, checksum. Transcribe IEC TC10 tables from the 2001 paper with double-entry check. Write a data card per source documenting label origin. De-duplicate across sources; harmonise units (ppm / µL/L); produce class-count table. *Gate:* only samples with inspection-confirmed or otherwise method-independent labels enter the benchmark set.

**Phase 2 — Literature review and standards (weeks 1–6, parallel).** Reference register with every DOI opened and checked before citing (also re-verify the 11 references already in Chapter 1). Review matrix: study, data, label origin, validation method, leakage risk, accuracy claimed. Transcribe ratio limits, code tables and Duval zone boundaries into `02_Standards` with clause/page numbers. → Chapter 2.

**Phase 3 — Conventional methods in MATLAB/Simulink (weeks 4–7).** Objective 1.
- `rogersRatio.m`, `iecRatio.m`, `duvalTriangle.m` (point-in-polygon on the published zones), each returning class **or** "no diagnosis" (unresolved cases are a result, not an error).
- Unit tests (`matlab.unittest`) against worked examples printed in the standards/papers.
- Simulink model: MATLAB Function blocks calling the same code; input = measured gas vector; output = three diagnoses. Separate, clearly labelled electrical-context subsystem (voltage, current, load, temperature) for illustration only.
- Independent Python re-implementation; both must agree on 100 % of dataset samples (cross-language verification).
- Extra output for the hypothesis: each sample's **distance to the nearest Duval zone boundary / ratio threshold**.

**Phase 4 — ML pipeline (weeks 6–11).** Objective 2.
- Features: raw gases, log-transforms, relative percentages, standard ratios (Rogers, IEC, Doernenburg, Duval %). All transforms inside a scikit-learn `Pipeline`.
- Models: SVM, Random Forest, XGBoost, ANN (MLP), + one further (see issue 6).
- Validation: repeated stratified k-fold with **nested** CV for hyper-parameters; scaler, feature selection and any oversampling (SMOTE) fitted inside training folds only; fixed fold files saved so every experiment uses identical splits.
- Metrics per class: precision, recall, F1; macro-F1, balanced accuracy, confusion matrices; bootstrap 95 % CIs.
- Explainability: permutation importance and SHAP for the best model ("key gases").
- External check: train on one source, test on another where labels allow.

**Phase 5 — Reduced-gas ablation (weeks 10–12).** Remove gases one at a time and in field-realistic combinations (e.g. without C2H6), same folds and pipeline as the full-panel baseline; report accuracy loss with CIs and the minimum panel retaining performance within a pre-declared tolerance.

**Phase 6 — Benchmark and disagreement analysis (weeks 11–14).** Objective 5 and the hypothesis.
- ML vs each conventional method on identical held-out samples: accuracy, unresolved-rate, McNemar test, Cohen's kappa, Holm correction.
- Classifier comparison: Friedman + Nemenyi.
- Hypothesis test: logistic regression of (ML ≠ conventional) on boundary distance from Phase 3; report effect size, not just p-value.

**Phase 7 — FastAPI service (weeks 13–15).** Objective 3. Versioned, serialised pipeline (model + preprocessing in one artefact, hash recorded); `/diagnose` returns ML class, probabilities, and the three conventional diagnoses; input validation; pytest suite; **fidelity test**: API output equals offline pipeline output on the whole test set; latency measured (median, p95) on the laptop.

**Phase 8 — Dashboard (weeks 15–17).** Objective 4. MATLAB App Designer client calling the API via `webread/webwrite`: gas entry, side-by-side diagnoses, Duval Triangle plot with the sample point, agreement flag, class probabilities.

**Phase 9 — Writing (continuous; consolidation weeks 16–20).** Chapter 3 drafted phase by phase from the READMEs; Chapter 4 built only from script-generated tables/figures in `11_Results`; journal manuscript extracted from Phases 4–6 (candidate journals shortlisted in Phase 2 from where the reviewed papers appeared).

**Phase 6b — Study 2: exploratory improvement study (added 12 Oct 2026, decision D28; roadmap Version 3, Steps 31A–31F).** After the
confirmatory result (hypothesis not supported on IEC TC 10), a pre-registered exploratory study (`00_Project_Admin/Study2_Protocol.docx`)
tests leave-one-source-out training on four sources, a hybrid model (gas features + conventional answers and boundary distances) and a
reject option; it is reported separately and never replaces the confirmatory results. A fresh inspection-confirmed data set is sought
for confirmation (Step 31F).

## 5. Anti-hallucination rules (apply to every phase)

1. No citation enters the thesis until its DOI/URL has been opened and logged in the reference register.
2. No threshold, zone coordinate or sample count is typed from memory — each carries a source, clause/page.
3. Every number in the thesis traces to a file in `07_Experiments` with config and seed.
4. Negative or modest results are reported as found; accuracy is not tuned on the test data.
5. Anything unverified is marked `TO VERIFY` in the text until closed.

## 6. What makes the work novel (claims to be supported by Phase 2 review, not asserted)

- Statistically tested localisation of ML/conventional disagreement near decision boundaries.
- Minimum-gas-panel result under controlled ablation.
- Label-provenance-audited benchmark (many published comparisons do not document this).
- Cross-verified MATLAB and Python implementations of the conventional methods inside one queryable service.

## 7. Verification

- MATLAB: `runtests` in `04_MATLAB_Conventional` all pass; Simulink output equals function output on the full dataset.
- Cross-language: MATLAB vs Python conventional diagnoses identical on every sample.
- Leakage audit: a test confirming no duplicate sample spans train/test folds; pipeline refit per fold.
- Reproducibility: rerun from `raw/` with the saved seed reproduces tables in `11_Results`.
- API: pytest passes; fidelity test 100 % match; latency report generated.
- Dashboard: manual run-through with three known samples (one per fault family) checked against offline results.
- Reference register: zero entries with `verified = N` before submission.

## 8. First actions on approval

1. Create the folder tree and all READMEs; write `PROJECT_PLAN.md` at the root; move the two .docx to `00_Project_Admin`.
2. You: confirm §1.1 resolutions, download the two IEEE DataPort datasets, obtain Duval & dePablo (2001) and the standards.
3. Start Phase 1 data cards and Phase 2 reference register.
