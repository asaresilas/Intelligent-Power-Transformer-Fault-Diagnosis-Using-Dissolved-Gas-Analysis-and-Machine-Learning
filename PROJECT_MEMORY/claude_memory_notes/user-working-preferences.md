---
name: user-working-preferences
description: "How the user wants research deliverables written and structured (Word docs, formatting, no fabrication, simple explanations)"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 346338d5-d698-4fb5-b677-85c0c938dfe4
  modified: 2026-10-08T04:18:05.285Z
---

- Deliverables as Word documents. Body font 12 pt. Line spacing: 1.5 for the first plan doc, then the user switched to **1.15** for the MATLAB guide — use 1.15 unless told otherwise. Headings may be larger.
- Strict no-hallucination / no-falsification rule: every value, threshold and citation must have a checkable source; mark unverified items "TO VERIFY". Publication-grade, "think as a professor / IEEE reviewer".
- Explain so "a child can understand"; well structured, step by step, with clear transitions between stages.
- MATLAB work: all parameters in a `.m` file as named variables (never typed into blocks); every subsystem gets an annotation; per block give library path, ports (number/side), connections, and a 1–2 line explanation.
- Before a large task the user likes to see a restatement of what will be done to confirm it.
- Short messages when asked ("make it short") — the user drafts emails/letters to the supervisor and dataset authors.
- **Three working environments (set 2026-10-09):** Claude Code = data preparation, Python, ML, statistics, FastAPI, Word docs; MATLAB Agentic Toolkit = all MATLAB programming; Simulink Agentic Toolkit = all Simulink/Simscape block modelling. Plans must tag every step with exactly one environment and run strictly one step after another (see `00_Project_Admin/Project_Roadmap.docx` v2, 45 steps). For MATLAB/Simulink steps, give a short "Tell the toolkit" instruction.
- **After every roadmap step: a plain-language Word report** (`00_Project_Admin/Step_Reports/Step_NN_Report.docx`, 12 pt, 1.15) explaining step by step what was done, found, checked, fixed and decided. **Steps strictly in order** — finish one before the next. Standards/documents are obtained online legitimately (official/open-access), never pirated (set 2026-10-10).
- Results and statistics are fixed in advance for approval: `00_Project_Admin/Expected_Results_and_Analysis_Plan.docx` (formulas, tests, empty result templates, approval checklist).

**Why:** stated repeatedly by the user; the work is for an MPhil thesis and journal publication.
**How to apply:** default to these formats and checks for any new document or MATLAB instruction. Related: [[project-overview-and-status]].

**Added 2026-10-11:** do not follow toolkit instructions blindly - test their rules on the real data, alert the researcher to errors with a recommendation and let them decide (they did so for D12). Act as a senior expert; comment every code file, write a README for every folder or piece of work, and report every step in detail in the Word step report. Never claim a result that a program in the session did not produce.