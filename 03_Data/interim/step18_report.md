# Step 18 report - MATLAB versus Python cross-check

Run date: 2026-10-11. Script: `06_Python_ML/src/conventional/step18_crosscheck.py` (independent implementation `conventional_methods.py`). Data version 1.0 verified: PASS.

## Agreement per method

| method | rows | gate_upper identical | gate_lower identical | raw_result identical | result identical | numbers within 1e-9 | max abs difference |
|---|---|---|---|---|---|---|---|
| Duval | 827 | 827/827 | 827/827 | 827/827 | 827/827 | 827/827 | 6.22e-14 |
| IEC60599 | 827 | 827/827 | 827/827 | 827/827 | 827/827 | 827/827 | 3.41e-13 |
| Rogers | 827 | 827/827 | 827/827 | 827/827 | 827/827 | 827/827 | 3.41e-13 |

Rows with any difference: 0 of 2481 -> PASS.

## Python raw-result counts (827 records)

| method | ND | DT | dual | gate_upper |
|---|---|---|---|---|
| IEC60599 | 319 | 0 | 90 | 242 |
| Rogers | 424 | 0 | 0 | 242 |
| Duval | 2 | 27 | 0 | 242 |

Detail: `08_Statistical_Analysis/cross_language_check.csv`; Python predictions: `11_Results/conventional/conventional_predictions_python.csv`.
