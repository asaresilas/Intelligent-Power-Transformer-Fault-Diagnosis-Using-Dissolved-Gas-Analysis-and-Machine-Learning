# CLAUDE.md

MPhil research project: transformer fault diagnosis using Dissolved Gas Analysis and machine learning,
integrated MATLAB/Simulink (R2025b, pure Simscape) – Python framework.

Before starting any work, read:
1. `PROJECT_MEMORY/SESSION_SUMMARY.md` — everything done so far, decisions, datasets, next steps.
2. `PROJECT_MEMORY/claude_memory_notes/` — preferences and lessons learned.
3. `PROJECT_PLAN.md` and `00_Project_Admin/decisions_log.md`.

Working rules:
- No invented data, values or citations; every number traces to a source or a saved experiment. Mark unverified items "TO VERIFY".
- Word deliverables: body 12 pt, line spacing 1.15 (unless told otherwise), clear step-by-step structure, plain language.
- MATLAB: all parameters as variables in `05_Simulink_Model/params_transformer.m`; annotate every subsystem; Simulink never generates gas values.
- After each work session, update `PROJECT_MEMORY/SESSION_SUMMARY.md` and `CHANGELOG.md`.
- After every roadmap step, write a step report following `PROJECT_MEMORY/claude_memory_notes/report_standard.md`
  (includes "Method used", data/sources with links and SHA-256, and an abbreviations list); builder scripts in
  `00_Project_Admin/report_builder/`. Keep `03_Data/provenance/data_and_source_register.csv` updated.
