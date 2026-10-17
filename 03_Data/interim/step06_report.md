# Step 6 report - missing values

Run date: 2026-10-10. Script: `06_Python_ML/src/data_prep/step06_missing_values.py`.

Cell categories: measured (positive value), zero (exactly 0), placeholder (exactly 0.0001 ppm, used by the Dissanayake files where no value was available), blank (empty cell; the dash in the IEC TC 10 tables). Blank and placeholder together are called 'not available'. Nothing was removed or replaced in this step.

## Cells by gas

| source_id | gas | measured | zero | placeholder | blank |
|---|---|---|---|---|---|
| IECTC10 | H2 | 116 | 0 | 0 | 1 |
| IECTC10 | CH4 | 116 | 0 | 0 | 1 |
| IECTC10 | C2H6 | 110 | 0 | 0 | 7 |
| IECTC10 | C2H4 | 114 | 0 | 0 | 3 |
| IECTC10 | C2H2 | 106 | 0 | 0 | 11 |
| DISTRAIN | H2 | 568 | 1 | 15 | 0 |
| DISTRAIN | CH4 | 576 | 2 | 6 | 0 |
| DISTRAIN | C2H6 | 538 | 13 | 33 | 0 |
| DISTRAIN | C2H4 | 550 | 7 | 27 | 0 |
| DISTRAIN | C2H2 | 331 | 77 | 176 | 0 |
| DISTEST | H2 | 67 | 0 | 3 | 0 |
| DISTEST | CH4 | 69 | 0 | 1 | 0 |
| DISTEST | C2H6 | 66 | 0 | 4 | 0 |
| DISTEST | C2H4 | 67 | 0 | 3 | 0 |
| DISTEST | C2H2 | 42 | 5 | 23 | 0 |
| DISIEC | H2 | 49 | 0 | 0 | 0 |
| DISIEC | CH4 | 47 | 2 | 0 | 0 |
| DISIEC | C2H6 | 41 | 8 | 0 | 0 |
| DISIEC | C2H4 | 44 | 5 | 0 | 0 |
| DISIEC | C2H2 | 34 | 15 | 0 | 0 |
| LI2019 | H2 | 198 | 3 | 0 | 0 |
| LI2019 | CH4 | 200 | 1 | 0 | 0 |
| LI2019 | C2H6 | 189 | 12 | 0 | 0 |
| LI2019 | C2H4 | 194 | 7 | 0 | 0 |
| LI2019 | C2H2 | 161 | 40 | 0 | 0 |

## Effect of each candidate rule on the records, by class

`kept_if_not_available_excluded` = records left if every record with a blank or placeholder is dropped; `kept_if_not_available_and_zero_excluded` = records left if zeros are dropped as well.

| source_id | class | records | with_blank | with_placeholder | with_zero | kept_if_not_available_excluded | kept_if_not_available_and_zero_excluded |
|---|---|---|---|---|---|---|---|
| IECTC10 | D1 | 26 | 2 | 0 | 0 | 24 | 24 |
| IECTC10 | D2 | 48 | 3 | 0 | 0 | 45 | 45 |
| IECTC10 | PD | 9 | 5 | 0 | 0 | 4 | 4 |
| IECTC10 | T1/T2 | 16 | 6 | 0 | 0 | 10 | 10 |
| IECTC10 | T3 | 18 | 2 | 0 | 0 | 16 | 16 |
| DISTRAIN | 0 | 85 | 0 | 0 | 79 | 85 | 6 |
| DISTRAIN | 1 | 59 | 0 | 35 | 0 | 24 | 24 |
| DISTRAIN | 2 | 76 | 0 | 13 | 0 | 63 | 63 |
| DISTRAIN | 3 | 134 | 0 | 14 | 0 | 120 | 120 |
| DISTRAIN | 4 | 96 | 0 | 82 | 0 | 14 | 14 |
| DISTRAIN | 5 | 45 | 0 | 23 | 0 | 22 | 22 |
| DISTRAIN | 6 | 89 | 0 | 43 | 0 | 46 | 46 |
| DISTEST | 0 | 10 | 0 | 0 | 5 | 10 | 5 |
| DISTEST | 1 | 10 | 0 | 6 | 0 | 4 | 4 |
| DISTEST | 2 | 10 | 0 | 0 | 0 | 10 | 10 |
| DISTEST | 3 | 10 | 0 | 1 | 0 | 9 | 9 |
| DISTEST | 4 | 10 | 0 | 10 | 0 | 0 | 0 |
| DISTEST | 5 | 10 | 0 | 7 | 0 | 3 | 3 |
| DISTEST | 6 | 10 | 0 | 2 | 0 | 8 | 8 |
| DISIEC | 0 | 15 | 0 | 0 | 15 | 15 | 0 |
| DISIEC | 1 | 1 | 0 | 0 | 0 | 1 | 1 |
| DISIEC | 2 | 7 | 0 | 0 | 1 | 7 | 6 |
| DISIEC | 3 | 15 | 0 | 0 | 0 | 15 | 15 |
| DISIEC | 4 | 1 | 0 | 0 | 0 | 1 | 1 |
| DISIEC | 5 | 2 | 0 | 0 | 0 | 2 | 2 |
| DISIEC | 6 | 8 | 0 | 0 | 1 | 8 | 7 |
| LI2019 | Arc discharge | 54 | 0 | 0 | 3 | 54 | 51 |
| LI2019 | High-temperature overheating | 38 | 0 | 0 | 5 | 38 | 33 |
| LI2019 | Low-temperature overheating | 19 | 0 | 0 | 18 | 19 | 1 |
| LI2019 | Low/Middle-temperature overheating | 16 | 0 | 0 | 6 | 16 | 10 |
| LI2019 | Middle-temperature overheating | 9 | 0 | 0 | 5 | 9 | 4 |
| LI2019 | Partial discharge | 16 | 0 | 0 | 9 | 16 | 7 |
| LI2019 | Spark discharge | 49 | 0 | 0 | 4 | 49 | 45 |

Check: every gas cell is in exactly one category - PASS.

## Rule applied downstream (decision D8, decisions_log.md)

The missingness is informative: C2H2 is not available mainly in T1, T2, T3 and PD records and never in D1/D2, i.e. the gas was not detected. Primary analysis: not available = 0 ppm (not detected), flags kept. Sensitivity analysis: complete records only (`all_five_reported` = True).
