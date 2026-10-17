# Step 9 report - duplicates and leakage audit

Run date: 2026-10-10. Script: `06_Python_ML/src/data_prep/step09_dedup_leakage.py`.

Comparison: gases harmonised with decision D8 (blank and 0.0001 -> 0), exact = equal to 4 decimals, near = every gas within 1% or 1 ppm.

## Matching pairs between sources (before removal)

| source_a | source_b | match | pairs |
|---|---|---|---|
| DISIEC | LI2019 | cross_exact | 31 |
| DISIEC | LI2019 | cross_near | 1 |
| DISTEST | LI2019 | cross_exact | 10 |
| DISTRAIN | DISIEC | cross_exact | 42 |
| DISTRAIN | DISIEC | cross_near | 18 |
| DISTRAIN | DISTEST | cross_exact | 1 |
| DISTRAIN | DISTEST | cross_near | 21 |
| DISTRAIN | LI2019 | cross_exact | 125 |
| DISTRAIN | LI2019 | cross_near | 4 |
| IECTC10 | DISIEC | cross_exact | 31 |
| IECTC10 | DISTEST | cross_exact | 9 |
| IECTC10 | DISTRAIN | cross_exact | 96 |
| IECTC10 | LI2019 | cross_exact | 115 |

## Records removed

| source_id | kind | records |
|---|---|---|
| DISIEC | identical gases | 2 |
| DISTRAIN | exact duplicate | 2 |
| DISTRAIN | identical gases | 4 |
| DISTRAIN | leakage | 139 |

### Development records removed for leakage, by the test source they match

| matched source | development records removed |
|---|---|
| IECTC10 | 96 |
| LI2019 | 35 |
| DISTEST | 8 |

## Label agreement where Dissanayake or Li records copy IEC TC 10 cases

Pairs: 251 (DISTRAIN/DISTEST/LI2019: 220, DISIEC: 31). Same merged label as the inspection label: 247 of 251.

| dis_source | iec_label | dis_fine_label | pairs |
|---|---|---|---|
| DISIEC | D1 | D1 | 7 |
| DISIEC | D2 | D2 | 14 |
| DISIEC | T12 | T2 | 2 |
| DISIEC | T3 | T3 | 8 |
| DISTEST | D1 | D1 | 3 |
| DISTEST | D2 | D2 | 2 |
| DISTEST | PD | PD | 3 |
| DISTEST | T3 | T3 | 1 |
| DISTRAIN | D1 | D1 | 21 |
| DISTRAIN | D2 | D2 | 45 |
| DISTRAIN | PD | PD | 5 |
| DISTRAIN | T12 | PD | 1 |
| DISTRAIN | T12 | T1 | 4 |
| DISTRAIN | T12 | T2 | 3 |
| DISTRAIN | T12 | T3 | 3 |
| DISTRAIN | T3 | T3 | 14 |
| LI2019 | D1 | D1 | 26 |
| LI2019 | D2 | D2 | 47 |
| LI2019 | PD | PD | 8 |
| LI2019 | T12 | (merged T12) | 16 |
| LI2019 | T3 | T3 | 18 |

## Test records that duplicate benchmark cases (decision D9)

A test record that matches an IEC TC 10 case is flagged `independent_of_benchmark` = False. Results reported as separate evidence from the internal or external test set use only the independent records; the full sets are reported as a sensitivity analysis.

| data_role | records | independent of benchmark |
|---|---|---|
| external_test | 201 | 86 |
| internal_test | 70 | 61 |

## Origin of DISIEC (Dissanayake IEC_TC_10_data.xlsx)

31 of 49 rows match an IEC TC 10 Annex 1 case (exact or near); 18 do not (including its 15 Normal rows, which Annex 1 cannot contain). DISIEC is not used in any role.

## Master table (`03_Data/processed/dga_master.csv`) - records per role and class (merged scheme)

| data_role | D1 | D2 | Normal | PD | T12 | T3 |
|---|---|---|---|---|---|---|
| benchmark | 26 | 48 | 0 | 9 | 16 | 18 |
| development | 53 | 85 | 75 | 37 | 119 | 70 |
| external_test | 49 | 54 | 0 | 16 | 44 | 38 |
| internal_test | 10 | 10 | 10 | 10 | 20 | 10 |

Total records in master: 827. IEC TC 10 records in scope for the primary benchmark (P, U): 58.

Check: development records matching a test-role record (exact or near) = 0 - PASS.
