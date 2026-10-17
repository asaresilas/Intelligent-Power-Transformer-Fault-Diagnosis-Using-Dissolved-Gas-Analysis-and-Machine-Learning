# Step report standard (set by the researcher, 10-11 October 2026) — applies to ALL reports

Format: Word (.docx), body 12 pt, line spacing 1.15, plain language a non-specialist can follow, saved as
`00_Project_Admin/Step_Reports/Step_NN_Report.docx`. Section numbers are generated automatically (H1N).
Builder scripts: `00_Project_Admin/report_builder/` (see its README).

Sections, in this order:
1. Header (step, title, environment, date completed, report version, thesis title), "In short" summary box, and a note
   that abbreviations are explained at the end.
2. **Purpose of this step.**
3. **Method used** — sub-sections: Approach (the technique in plain words); Why this method (why it is standard research
   practice / the rationale); Settings and rules (table: tolerances, seeds, folds, tests, thresholds); Equations (numbered,
   each with a "where:" list of symbols and units) when the step uses formulas; Tools and programs (program files,
   functions, library versions); Method references (verified, from the register IDs M*; unverified -> TO VERIFY).
4. Step-specific body, as applicable: what was used; what was done, step by step; the rules; what we found (tables,
   figures); checks and their results; problems and fixes; decisions (decision-log number); files produced.
5. **What was achieved.**
6. **Record of this step** (table: step, environment, date completed, status, main inputs, main outputs, checks, decisions).
7. **Data and sources used in this step** — full reference, use, link, DOI, local file and SHA-256, generated from
   `03_Data/provenance/data_and_source_register.csv` (add every new dataset, standard, paper, method reference or
   derived file there first).
8. **How this helps the next steps** (starts with the next step).
9. **Open items and limitations** (TO VERIFY items, corrections recorded openly).
10. **Abbreviations and terms used in this report** — selected automatically from
    `00_Project_Admin/abbreviations_glossary.csv` (add new terms there; fault types per IEC 60599 clause 5.2).

Rules: no invented values or citations; every number comes from a program output or a cited source and is re-checked
against the output files before the report is built; render the pages and look at them before sending; after each
report update CHANGELOG.md, PROJECT_MEMORY/SESSION_SUMMARY.md and the Data and Source Register
(`00_Project_Admin/Step_Reports/Data_and_Source_Register.docx`).
