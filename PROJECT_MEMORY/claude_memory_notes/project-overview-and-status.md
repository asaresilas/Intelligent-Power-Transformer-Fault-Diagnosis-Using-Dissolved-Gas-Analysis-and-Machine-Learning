---
name: project-overview-and-status
description: "MPhil DGA transformer fault diagnosis project — goal, unified objectives, what is done and what is pending (as of 2026-10-08)"
metadata:
  node_type: memory
  type: project
  originSessionId: 346338d5-d698-4fb5-b677-85c0c938dfe4
  modified: 2026-10-08T04:17:59.363Z
---

MPhil thesis (UMaT Tarkwa, supervisor Prof. John Annan): "Intelligent Power Transformer Fault Diagnosis Using DGA and Machine Learning: An Integrated MATLAB/Simulink–Python Framework". Thesis Chapter 1 governs; the reduced-gas ablation from the older overview brief was merged in as an extra study (six unified objectives in `00_Project_Admin/Project_Methodology_Plan.docx`).

Done (2026-09-30 to 2026-10-08): portable memory folder `PROJECT_MEMORY/` (session summary, these notes, full chat export) + root `CLAUDE.md`; folder structure 00–13 with READMEs; methodology plan docx; MATLAB_Build_Guide docx (Parts A–C); verified MATLAB code and Simscape reference build; dataset request letter to Prof. Annan; short access-request messages drafted for the two IEEE DataPort authors (Dissanayake; Enwen Li).

Pending: team hand-builds `Transformer_Operating_Model.slx` and `DGADashboard.mlapp` from the guide; datasets not yet obtained (see [[dataset-access-status]]); standards not yet obtained, so Rogers/IEC/Duval threshold CSVs in `02_Standards` are empty and diagnoses show PENDING_STANDARD; FastAPI/ML phases not started; seven open decisions in `00_Project_Admin/decisions_log.md` (author name/degree conflict between the two source docs, 5 vs 7 gases, Normal class, 5th classifier).

`DGA Chpater 1.docx` is still in the project root (was locked in Word; user asked to move it).

**Why:** lets a new session pick up the phase plan without re-reading everything.
**How to apply:** check this before starting work; update the Done/Pending lists when phases move. Related: [[user-working-preferences]], [[matlab-environment-facts]], [[simscape-model-design]].

**Update 2026-10-11:** roadmap Steps 1 and 4-17 are done. Steps 14-17 (conventional methods in MATLAB) were run from Claude Code through the MATLAB MCP connection (toolkit Steps 2-3 still unchecked). Decision D12 amended three D11 rules; open point: IEC "PD" can only appear as "PD/T1". Next: Step 18 (Python re-implementation, 100 % agreement with `11_Results/conventional/conventional_predictions.csv`). Full detail: `PROJECT_MEMORY/SESSION_SUMMARY.md` item 10. The purpose and status of `05_Simulink_Model/reference_build/rerun_2026-10-11/` are unclear (the researcher reports errors when running the model).