# Step 7 report - harmonised fault labels

Run date: 2026-10-10. Script: `06_Python_ML/src/data_prep/step07_label_map.py`.

Fine scheme: 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3. Merged scheme: T1 and T2 combined as T12 (used to score the IEC TC 10 benchmark and the Li 2019 records that do not separate T1 from T2).

## Label map (`03_Data/processed/label_map.csv`)

| source_id | original_label | class_code | class_name | class_merged | reason | evidence |
|---|---|---|---|---|---|---|
| DISTRAIN | 0 | 0 | Normal | Normal | Dataset code 0 = Normal, used as given | IEEE DataPort 'DGA dataset' page (DOI 10.21227/27vy-h479): 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3 |
| DISTRAIN | 1 | 1 | PD | PD | Dataset code 1 = PD, used as given | IEEE DataPort 'DGA dataset' page (DOI 10.21227/27vy-h479): 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3 |
| DISTRAIN | 2 | 2 | D1 | D1 | Dataset code 2 = D1, used as given | IEEE DataPort 'DGA dataset' page (DOI 10.21227/27vy-h479): 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3 |
| DISTRAIN | 3 | 3 | D2 | D2 | Dataset code 3 = D2, used as given | IEEE DataPort 'DGA dataset' page (DOI 10.21227/27vy-h479): 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3 |
| DISTRAIN | 4 | 4 | T1 | T12 | Dataset code 4 = T1, used as given | IEEE DataPort 'DGA dataset' page (DOI 10.21227/27vy-h479): 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3 |
| DISTRAIN | 5 | 5 | T2 | T12 | Dataset code 5 = T2, used as given | IEEE DataPort 'DGA dataset' page (DOI 10.21227/27vy-h479): 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3 |
| DISTRAIN | 6 | 6 | T3 | T3 | Dataset code 6 = T3, used as given | IEEE DataPort 'DGA dataset' page (DOI 10.21227/27vy-h479): 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3 |
| DISTEST | 0 | 0 | Normal | Normal | Dataset code 0 = Normal, used as given | IEEE DataPort 'DGA dataset' page (DOI 10.21227/27vy-h479): 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3 |
| DISTEST | 1 | 1 | PD | PD | Dataset code 1 = PD, used as given | IEEE DataPort 'DGA dataset' page (DOI 10.21227/27vy-h479): 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3 |
| DISTEST | 2 | 2 | D1 | D1 | Dataset code 2 = D1, used as given | IEEE DataPort 'DGA dataset' page (DOI 10.21227/27vy-h479): 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3 |
| DISTEST | 3 | 3 | D2 | D2 | Dataset code 3 = D2, used as given | IEEE DataPort 'DGA dataset' page (DOI 10.21227/27vy-h479): 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3 |
| DISTEST | 4 | 4 | T1 | T12 | Dataset code 4 = T1, used as given | IEEE DataPort 'DGA dataset' page (DOI 10.21227/27vy-h479): 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3 |
| DISTEST | 5 | 5 | T2 | T12 | Dataset code 5 = T2, used as given | IEEE DataPort 'DGA dataset' page (DOI 10.21227/27vy-h479): 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3 |
| DISTEST | 6 | 6 | T3 | T3 | Dataset code 6 = T3, used as given | IEEE DataPort 'DGA dataset' page (DOI 10.21227/27vy-h479): 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3 |
| DISIEC | 0 | 0 | Normal | Normal | Dataset code 0 = Normal, used as given | IEEE DataPort 'DGA dataset' page (DOI 10.21227/27vy-h479): 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3 |
| DISIEC | 1 | 1 | PD | PD | Dataset code 1 = PD, used as given | IEEE DataPort 'DGA dataset' page (DOI 10.21227/27vy-h479): 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3 |
| DISIEC | 2 | 2 | D1 | D1 | Dataset code 2 = D1, used as given | IEEE DataPort 'DGA dataset' page (DOI 10.21227/27vy-h479): 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3 |
| DISIEC | 3 | 3 | D2 | D2 | Dataset code 3 = D2, used as given | IEEE DataPort 'DGA dataset' page (DOI 10.21227/27vy-h479): 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3 |
| DISIEC | 4 | 4 | T1 | T12 | Dataset code 4 = T1, used as given | IEEE DataPort 'DGA dataset' page (DOI 10.21227/27vy-h479): 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3 |
| DISIEC | 5 | 5 | T2 | T12 | Dataset code 5 = T2, used as given | IEEE DataPort 'DGA dataset' page (DOI 10.21227/27vy-h479): 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3 |
| DISIEC | 6 | 6 | T3 | T3 | Dataset code 6 = T3, used as given | IEEE DataPort 'DGA dataset' page (DOI 10.21227/27vy-h479): 0 Normal, 1 PD, 2 D1, 3 D2, 4 T1, 5 T2, 6 T3 |
| IECTC10 | PD | 1 | PD | PD | Partial discharges identified by inspection (Table 2) | Duval & dePablo (2001), Annex 1 Tables 2-6 (faults identified by inspection) |
| IECTC10 | D1 | 2 | D1 | D1 | Low-energy discharges identified by inspection (Table 3) | Duval & dePablo (2001), Annex 1 Tables 2-6 (faults identified by inspection) |
| IECTC10 | D2 | 3 | D2 | D2 | High-energy discharges identified by inspection (Table 4) | Duval & dePablo (2001), Annex 1 Tables 2-6 (faults identified by inspection) |
| IECTC10 | T1/T2 |  |  | T12 | Table 5 combines T1 and T2 (< 700 C) and does not say which row is which; merged class T12 (plan item 6) | Duval & dePablo (2001), Annex 1 Tables 2-6 (faults identified by inspection) |
| IECTC10 | T3 | 6 | T3 | T3 | Thermal faults > 700 C identified by inspection (Table 6) | Duval & dePablo (2001), Annex 1 Tables 2-6 (faults identified by inspection) |
| LI2019 | Partial discharge | 1 | PD | PD | Same fault type | Li (2019) label text; analysis-plan item 7; Duval & dePablo (2001) Annex 1 puts sparking cases in D1 (Table 3) and arcing cases in D2 (Table 4) |
| LI2019 | Spark discharge | 2 | D1 | D1 | Sparking = low-energy discharge (D1) | Li (2019) label text; analysis-plan item 7; Duval & dePablo (2001) Annex 1 puts sparking cases in D1 (Table 3) and arcing cases in D2 (Table 4) |
| LI2019 | Arc discharge | 3 | D2 | D2 | Arcing = high-energy discharge (D2) | Li (2019) label text; analysis-plan item 7; Duval & dePablo (2001) Annex 1 puts sparking cases in D1 (Table 3) and arcing cases in D2 (Table 4) |
| LI2019 | Low-temperature overheating | 4 | T1 | T12 | Low-temperature thermal fault = T1; Li's temperature bands TO VERIFY | Li (2019) label text; analysis-plan item 7; Duval & dePablo (2001) Annex 1 puts sparking cases in D1 (Table 3) and arcing cases in D2 (Table 4) |
| LI2019 | Middle-temperature overheating | 5 | T2 | T12 | Middle-temperature thermal fault = T2; Li's temperature bands TO VERIFY | Li (2019) label text; analysis-plan item 7; Duval & dePablo (2001) Annex 1 puts sparking cases in D1 (Table 3) and arcing cases in D2 (Table 4) |
| LI2019 | High-temperature overheating | 6 | T3 | T3 | High-temperature thermal fault = T3; Li's temperature bands TO VERIFY | Li (2019) label text; analysis-plan item 7; Duval & dePablo (2001) Annex 1 puts sparking cases in D1 (Table 3) and arcing cases in D2 (Table 4) |
| LI2019 | Low/Middle-temperature overheating |  |  | T12 | Spans T1 and T2; merged class T12 (plan item 7) | Li (2019) label text; analysis-plan item 7; Duval & dePablo (2001) Annex 1 puts sparking cases in D1 (Table 3) and arcing cases in D2 (Table 4) |

## Records per class after mapping

Columns Normal to T3 use the merged scheme; T1 and T2 give the split where the source provides it.

| source_id | records | Normal | PD | D1 | D2 | T12 | T3 | T1 | T2 | fine_label_missing |
|---|---|---|---|---|---|---|---|---|---|---|
| IECTC10 | 117 | 0 | 9 | 26 | 48 | 16 | 18 | 0 | 0 | 16 |
| DISTRAIN | 584 | 85 | 59 | 76 | 134 | 141 | 89 | 96 | 45 | 0 |
| DISTEST | 70 | 10 | 10 | 10 | 10 | 20 | 10 | 10 | 10 | 0 |
| DISIEC | 49 | 15 | 1 | 7 | 15 | 3 | 8 | 1 | 2 | 0 |
| LI2019 | 201 | 0 | 16 | 49 | 54 | 44 | 38 | 19 | 9 | 16 |

Check: every original label maps to exactly one row - PASS.
