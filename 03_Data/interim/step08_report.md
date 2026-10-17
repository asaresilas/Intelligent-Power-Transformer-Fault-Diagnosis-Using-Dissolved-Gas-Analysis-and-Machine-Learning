# Step 8 report - scope filter

Run date: 2026-10-10. Script: `06_Python_ML/src/data_prep/step08_scope_filter.py`.

Primary analysis: power transformers only (IEC TC 10 codes P and U). Excluded records are not deleted; they are flagged (`in_scope_primary` = False) and used in the sensitivity analysis. The Dissanayake and Li files record no equipment type, so no filter can be applied to them (reported as a limitation).

## Excluded records by equipment type

| equipment_type | reason | records |
|---|---|---|
| (blank) | equipment type not given - cannot be confirmed as a power transformer | 1 |
| B | bushing (Table 1) - not a power transformer | 5 |
| C | cable (Table 1) - not a power transformer | 2 |
| I | instrument transformer (Table 1) - not a power transformer | 12 |
| R | reactor (Table 1) - not a power transformer | 32 |
| S | selector / tap-changer compartment - code not defined in Table 1; not the main tank | 7 |

## Records per class before and after the filter

| source_id | class_merged | before | kept_primary | excluded |
|---|---|---|---|---|
| IECTC10 | PD | 9 | 1 | 8 |
| IECTC10 | D1 | 26 | 10 | 16 |
| IECTC10 | D2 | 48 | 27 | 21 |
| IECTC10 | T12 | 16 | 8 | 8 |
| IECTC10 | T3 | 18 | 12 | 6 |
| DISTRAIN | Normal | 85 | 85 | 0 |
| DISTRAIN | PD | 59 | 59 | 0 |
| DISTRAIN | D1 | 76 | 76 | 0 |
| DISTRAIN | D2 | 134 | 134 | 0 |
| DISTRAIN | T12 | 141 | 141 | 0 |
| DISTRAIN | T3 | 89 | 89 | 0 |
| DISTEST | Normal | 10 | 10 | 0 |
| DISTEST | PD | 10 | 10 | 0 |
| DISTEST | D1 | 10 | 10 | 0 |
| DISTEST | D2 | 10 | 10 | 0 |
| DISTEST | T12 | 20 | 20 | 0 |
| DISTEST | T3 | 10 | 10 | 0 |
| DISIEC | Normal | 15 | 15 | 0 |
| DISIEC | PD | 1 | 1 | 0 |
| DISIEC | D1 | 7 | 7 | 0 |
| DISIEC | D2 | 15 | 15 | 0 |
| DISIEC | T12 | 3 | 3 | 0 |
| DISIEC | T3 | 8 | 8 | 0 |
| LI2019 | PD | 16 | 16 | 0 |
| LI2019 | D1 | 49 | 49 | 0 |
| LI2019 | D2 | 54 | 54 | 0 |
| LI2019 | T12 | 44 | 44 | 0 |
| LI2019 | T3 | 38 | 38 | 0 |

Check: kept + excluded = total for every source - PASS.
