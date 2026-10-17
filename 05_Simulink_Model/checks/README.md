# 05_Simulink_Model/checks - Step 34 (model checks)

**Purpose.** Roadmap Step 34: run Model Advisor and the checks of MATLAB Build Guide Part D1 on
`Transformer_Operating_Model.slx`; fix every issue or record why it is accepted (decision D32).

**Result (13 October 2026, MATLAB R2025b).** 132 Model Advisor checks: 120 passed, 11 warnings, 1 incomplete, 0 failed, 0 not run.
Every warning has a written reason (`model_advisor_accepted.csv`). Part D1: items 1-5 pass (program-tested); item 6 (the app) is not
applicable yet; item 7 (a second person checks the build) is OPEN.

| File | What it is |
|---|---|
| `step34_run_model_advisor.m` | Runs the 132 checks (groups design, simscape, simulink, sl, maab) and writes the files below. |
| `model_advisor_report.html` | The Model Advisor report (open in a browser; the `matlab:` links work only inside MATLAB). **This is the roadmap output "model_advisor_report".** |
| `model_advisor_results.csv` | One row per check: id, name, status, start of the result text. |
| `model_advisor_raw.mat` | The raw result object (input of `step34_write_accepted.m`). |
| `step34_write_accepted.m` | Writes `model_advisor_accepted.csv` (every non-passed check with the number of flagged blocks and the reason it is accepted). Stops if a non-passed check has no written reason. |
| `model_advisor_accepted.csv` | The 12 non-passed checks with reasons. |
| `step34_checklist_D1.m` | The Part D1 checklist as a function; writes the three CSV files below. |
| `step34_checklist_D1.csv` | Result of each checklist item (14 rows; 13 pass, D1.7 open). |
| `step34_param_lines.csv` | One row per variable of `params_transformer.m`: has unit, has source or basis. |
| `step34_block_numbers.csv` | Every dialog value of the 84 blocks that contains a digit, with its category (interface code, hidden field, library tuning, option selector; no "PARAMETER NUMBER" remains). |
| `Transformer_Operating_Model_before_step34.slx` | The Step 33 model, kept for comparison (SHA-256 in the Step 34 report). |
| `../code_manifest_step34.sha256` | (in `05_Simulink_Model/`) Fingerprints of the code of this step: the three scripts of this folder and the three Step 33 files changed in this step. |

**How to repeat.**
```matlab
cd 05_Simulink_Model/checks
step34_run_model_advisor      % about 2-3 minutes; writes report, results and raw .mat
step34_write_accepted         % reasons for the non-passed checks
step34_checklist_D1           % Part D1 checklist
cd ..; verify_step33          % the nine Step 33 checks must still pass (9/9)
```
The Model Advisor writes a cache folder `slprj/` here; it can be deleted.

**What changed in the model during Step 34** (all in `build_Transformer_Operating_Model.m`, so the model is still rebuilt by one script):
Sqrt block instead of the deprecated Math Function "sqrt"; diagnostics for Inf/NaN, unconnected ports and lines, duplicate data stores and
bus-as-vector set to error; the name of the Exp block shown; the transformer's zero-sequence reactance is the new variable `X0_pu` (0.5 pu, the
block default, value unchanged; TO VERIFY). The logged results are identical to those of Step 33 (largest difference 0.00e+00 against the reference run).
