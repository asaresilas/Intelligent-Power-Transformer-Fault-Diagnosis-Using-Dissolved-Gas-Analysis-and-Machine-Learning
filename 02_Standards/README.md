# 02 — Standards and Conventional-Method Definitions

**Purpose.** Be the single, cited source of every ratio limit, code table and Duval Triangle zone boundary used by the MATLAB, Simulink and Python implementations.

**Inputs (obtain legitimate copies via library or purchase)**
- IEC 60599 (current edition) — IEC ratio method, fault definitions PD/D1/D2/T1/T2/T3.
- IEEE C57.104-2019 — gas interpretation guide.
- Duval (2002), IEEE Electrical Insulation Magazine 18(3), 8–17 — Duval Triangle.
- The original Rogers ratio publication (exact reference TO VERIFY in Phase 2).

**Outputs**
- `iec_ratio_table.csv`, `rogers_ratio_table.csv`, `duval_triangle_zones.csv` — each row with source document, clause/table/figure and page.
- `worked_examples.csv` — sample gas values with the diagnosis printed in the source (used as unit-test cases in folder 04).
- `transcription_check.md` — record of the second, independent check of every table.

**Procedure.** Transcribe directly from the source document; never from memory, websites or secondary papers. A second pass re-reads every value against the source. Differences between editions are noted, and the edition used is stated.

**Acceptance criteria.** Every numeric value has a source reference; double-check recorded; code in 04/06 reads these files rather than hard-coding values.

**Feeds thesis.** Chapter 2 (conventional methods), Chapter 3 (implementation of conventional layer).

**Note.** Standards are copyrighted: keep only the transcribed limits needed for implementation, not copies of the documents for redistribution.
