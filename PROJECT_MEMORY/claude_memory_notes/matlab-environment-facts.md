---
name: matlab-environment-facts
description: "MATLAB R2025b on this machine — no Specialized Power Systems, C: drive full breaks logging, how to run MATLAB batch safely"
metadata:
  node_type: memory
  type: reference
  originSessionId: 346338d5-d698-4fb5-b677-85c0c938dfe4
  modified: 2026-10-08T04:18:10.670Z
---

- MATLAB R2025b General Release (25.2.0.2998904) at `C:\Program Files\MATLAB\R2025b`; Simscape, Simscape Electrical, Statistics & ML Toolbox and many others installed.
- Specialized Power Systems (powergui) library is absent in the R2025b GR (returns in Update 1). User requires pure Simscape / Simscape Electrical blocks.
- C: drive was ~100% full (90 MB free on 2026-10-03); by 2026-10-08 the user had freed it to ~17 GB. While it was full, MATLAB disabled data recording and simulations returned empty timeseries. Workaround used: run `matlab -batch` with `TMP`/`TEMP` set to a folder on D:, then delete that folder.
- Word automation (COM) works via a PowerShell `Start-Job` with a timeout; exporting PDF to the C: temp path hung once.
- No pandoc/soffice/pdftoppm; docx built with npm `docx` installed in the session scratchpad; PDF pages rendered with PyMuPDF installed to a scratchpad `pylib`.
- 2026-10-09 (machine without Python/Node): docx built via Word COM (slow, ~5 min for 15 pages). Word's PDF export then hung for every document; page previews were made instead from each page's `EnhMetaFileBits` (PNG via System.Drawing). Equations: UnicodeMath + `OMaths.Add().BuildUp()`, `#(n)` numbering; save scripts as UTF-8 with BOM.

**How to apply:** run MATLAB headless for verification with TMP on D:; remind the user to free C: space. Related: [[simscape-model-design]].


**Added 2026-10-15 (freeze lesson):** never start a long-running program from MATLAB with `system('start /B ...')`: it inherits MATLAB's output pipe (4 KB); a chatty program (uvicorn access log) then blocks and MATLAB waits without end (measured: request 62 waited 248 s). Start it detached (WMI `Win32_Process.Create` via `09_API_FastAPI/launch_service_detached.ps1`) with output in a log file. `weboptions('Timeout')` did not bound a hung `webwrite`: check `/health` (`webread`, 2 s) before the call. The first simulation of a MATLAB session compiles the model (about 50 s): do it behind a progress window. Screen is 1366 x 768 (window designed 1350 x 690). MATLAB temp path contains a space (quote paths); PowerShell `-File` needs `-ExecutionPolicy Bypass`. Check an app with `exportapp` + Read of the PNG.