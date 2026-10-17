# 03 — Data

**Purpose.** Acquire, document and prepare DGA data whose fault labels are independent of the conventional methods being benchmarked.

## Datasets

| Dataset | Link | Notes |
|---|---|---|
| IEC TC 10 database — Duval & dePablo (2001), IEEE Electrical Insulation Magazine 17(2), 31–41 | https://doi.org/10.1109/57.917529 (DOI TO VERIFY on first access) | Primary benchmark. Faults confirmed by inspection of the equipment. Tables transcribed from the paper. |
| IEEE DataPort "DGA dataset" (Dissanayake, 2026), DOI 10.21227/27vy-h479 | https://ieee-dataport.org/documents/dga-dataset | `DGA_train.xlsx` 584, `DGA_test_unseen.xlsx` 70, `IEC_TC_10_data.xlsx` 49 records; 5 gases; labels 0–6. Label origin and balancing method undocumented — see decision D7. |
| IEEE DataPort "Dissolved gas data in transformer oil" (Li, 2019), DOI 10.21227/h8g0-8z59 | https://ieee-dataport.org/documents/dissolved-gas-data-transformer-oil-fault-diagnosis-power-transformers-membership-degree | Fault-state samples with fault type; 5 gases; PDF documentation on the page. |

IEEE DataPort downloads require a free IEEE account (sign in yourself).

## Subfolders
- `raw/` — downloads exactly as received, plus `checksums.sha256`. Never edited.
- `interim/` — merged, unit-harmonised, de-duplicated table with a `source` column.
- `processed/` — final modelling table and `folds.csv` (fixed fold assignment used by every experiment).
- `provenance/` — one data card per dataset (template provided).

## Procedure
1. Download to `raw/`; compute SHA-256; record download date.
2. Transcribe IEC TC 10 tables from the paper; a second pass re-checks every value.
3. Write data cards: source, licence/terms, how labels were established, gases, units, class counts, known problems.
4. Harmonise column names and units; flag zeros / below-detection-limit values (do not silently replace).
5. Detect exact and near duplicates across all files; keep one copy; log removals.
6. Define the **benchmark set** (method-independent labels only) and the **supplementary set** (everything else).
7. Freeze `processed/` and `folds.csv`; record the hash.

**Acceptance criteria.** Data card for every source; no duplicate sample across folds; class-count table produced; benchmark set contains only samples whose label origin is documented.

**Feeds thesis.** Chapter 3 (data description, preprocessing), Chapter 1 limitations.
