# Step 5 report - load and standardise the raw datasets

Run date: 2026-10-10. Script: `06_Python_ML/src/data_prep/step05_standardise.py`.

Gas order and unit for every output file: H2, CH4, C2H6, C2H4, C2H2 in ppm. Units are not stated inside the Dissanayake and Li files; ppm (µL/L) is the DGA convention and is recorded as an assumption (TO VERIFY against the dataset pages).

Blank cells are kept as missing (never replaced by zero). Zeros are counted, not changed.

Raw-file checksums written to `03_Data/raw/checksums.sha256`.

## Summary

| Source | File | Hash | Rows (expected) | Complete records | Exact duplicate rows | Result |
|---|---|---|---|---|---|---|
| IECTC10 | `03_Data/raw/iec_tc10_duval2001_full/iec_tc10_faulty_equipment.csv` | recorded now (no value in the data card yet) | 117 (117) | 99 | 0 | PASS |
| DISTRAIN | `03_Data/raw/ieee_dataport_1375187/DGA_train.xlsx` | matches data card | 584 (584) | 584 | 2 | PASS |
| DISTEST | `03_Data/raw/ieee_dataport_1375187/DGA_test_unseen.xlsx` | matches data card | 70 (70) | 70 | 0 | PASS |
| DISIEC | `03_Data/raw/ieee_dataport_1375187/IEC_TC_10_data.xlsx` | matches data card | 49 (49) | 49 | 0 | PASS |
| LI2019 | `03_Data/raw/ieee_dataport_7226/DGA dataset.xlsx` | matches data card | 201 (201) | 201 | 0 | PASS |

## IECTC10

- SHA-256: `EF9F6B542821264AD89F1DA1D11DA9D6DBD5B79D66BE5159C263E8361EF77A6B` (recorded now (no value in the data card yet))
- Columns in file: ['fault_class', 'equipment_type', 'inspection', 'H2', 'CH4', 'C2H2', 'C2H4', 'C2H6', 'CO', 'CO2', 'ref']

| Gas | Missing | Zero | Negative | Non-numeric text |
|---|---|---|---|---|
| H2 | 1 | 0 | 0 | - |
| CH4 | 1 | 0 | 0 | - |
| C2H6 | 7 | 0 | 0 | - |
| C2H4 | 3 | 0 | 0 | - |
| C2H2 | 11 | 0 | 0 | - |

Original labels (count): D1: 26, D2: 48, PD: 9, T1/T2: 16, T3: 18

## DISTRAIN

- SHA-256: `C1C376718D72A747B72CFF127839D5DF488913127CA096B911CC5586DFCEDBBF` (matches data card)
- Columns in file: ['H2', 'CH4', 'C2H6', 'C2H4', 'C2H2', 'Fault class']

| Gas | Missing | Zero | Negative | Non-numeric text |
|---|---|---|---|---|
| H2 | 0 | 1 | 0 | - |
| CH4 | 0 | 2 | 0 | - |
| C2H6 | 0 | 13 | 0 | - |
| C2H4 | 0 | 7 | 0 | - |
| C2H2 | 0 | 77 | 0 | - |

Original labels (count): 0: 85, 1: 59, 2: 76, 3: 134, 4: 96, 5: 45, 6: 89

## DISTEST

- SHA-256: `23513C428C52F3BDB0508859CFB72CCC6E7639EF9BAF2165B6E03531945C2EAA` (matches data card)
- Columns in file: ['H2', 'CH4', 'C2H6', 'C2H4', 'C2H2', 'Fault class']

| Gas | Missing | Zero | Negative | Non-numeric text |
|---|---|---|---|---|
| H2 | 0 | 0 | 0 | - |
| CH4 | 0 | 0 | 0 | - |
| C2H6 | 0 | 0 | 0 | - |
| C2H4 | 0 | 0 | 0 | - |
| C2H2 | 0 | 5 | 0 | - |

Original labels (count): 0: 10, 1: 10, 2: 10, 3: 10, 4: 10, 5: 10, 6: 10

## DISIEC

- SHA-256: `2B5B128ABF38533E83E021D923328A7E879AF73034CFBF1428BDBCBD9F791C3F` (matches data card)
- Columns in file: ['H2', 'CH4', 'C2H6', 'C2H4', 'C2H2', 'Fault class']

| Gas | Missing | Zero | Negative | Non-numeric text |
|---|---|---|---|---|
| H2 | 0 | 0 | 0 | - |
| CH4 | 0 | 2 | 0 | - |
| C2H6 | 0 | 8 | 0 | - |
| C2H4 | 0 | 5 | 0 | - |
| C2H2 | 0 | 15 | 0 | - |

Original labels (count): 0: 15, 1: 1, 2: 7, 3: 15, 4: 1, 5: 2, 6: 8

## LI2019

- SHA-256: `B797638252DB69C02FC86AE834FA7752DCAF1EBE4AA32E8CBBB457915322CAC3` (matches data card)
- Columns in file: ['NM', 'H2', 'CH4', 'C2H6', 'C2H4', 'C2H2', 'Type']
- Note: workbook has 3 sheets ['Sheet1', 'Sheet2', 'Sheet3']; only the first was read

| Gas | Missing | Zero | Negative | Non-numeric text |
|---|---|---|---|---|
| H2 | 0 | 3 | 0 | - |
| CH4 | 0 | 1 | 0 | - |
| C2H6 | 0 | 12 | 0 | - |
| C2H4 | 0 | 7 | 0 | - |
| C2H2 | 0 | 40 | 0 | - |

Original labels (count): Arc discharge: 54, High-temperature overheating: 38, Low-temperature overheating: 19, Low/Middle-temperature overheating: 16, Middle-temperature overheating: 9, Partial discharge: 16, Spark discharge: 49
