# Step 13 report - data version 1.0 frozen

Run date: 2026-10-11. Script: `06_Python_ML/src/data_prep/step13_freeze.py`.

Frozen files: 16 (raw data, processed tables, standards tables, plot_style.csv). Manifest: `03_Data/data_version_1.0.sha256` (sha256sum format).

Re-verification of the manifest: PASS - 0 differences.

## Frozen files

| file | bytes | sha256 |
|---|---|---|
| 03_Data/raw/iec_tc10_duval2001_full/iec_tc10_faulty_equipment.csv | 8572 | EF9F6B542821264AD89F1DA1D11DA9D6DBD5B79D66BE5159C263E8361EF77A6B |
| 03_Data/raw/ieee_dataport_1375187/DGA_test_unseen.xlsx | 11414 | 23513C428C52F3BDB0508859CFB72CCC6E7639EF9BAF2165B6E03531945C2EAA |
| 03_Data/raw/ieee_dataport_1375187/DGA_train.xlsx | 31092 | C1C376718D72A747B72CFF127839D5DF488913127CA096B911CC5586DFCEDBBF |
| 03_Data/raw/ieee_dataport_1375187/IEC_TC_10_data.xlsx | 10988 | 2B5B128ABF38533E83E021D923328A7E879AF73034CFBF1428BDBCBD9F791C3F |
| 03_Data/raw/ieee_dataport_7226/DGA dataset.xlsx | 19071 | B797638252DB69C02FC86AE834FA7752DCAF1EBE4AA32E8CBBB457915322CAC3 |
| 03_Data/processed/dga_master.csv | 211209 | AE9E6C0C84CF71807012E276582E63E28F110F25C434FDEF3ED69AC70E426BBE |
| 03_Data/processed/folds.csv | 21935 | 0CE7D9AF3C7CE9F65FE3CD3C52C7B609E2BB8B18B5BA65E3075F7199F49D9A44 |
| 03_Data/processed/label_map.csv | 5988 | F66465BFB7BFB4459A6EAA673736A19C389777203BB2506950EA4419A5DE7399 |
| 02_Standards/duval_triangle_zones.csv | 3146 | A8CE9CE85A012CD6845ABC7041855110747CBF6A4FEE322B48E9339DC4F68EBF |
| 02_Standards/iec_ratio_table.csv | 8134 | 92BC70362EAC36541E8E42ACE93D8678631DAA0F82C323CF4BAA9531FAB6D217 |
| 02_Standards/iec_typical_values.csv | 2968 | 88D0D57E2EEB473743CE590565D98466C93AE67CFE162950A230A0ACD8D88FC8 |
| 02_Standards/ieee_condition1_limits.csv | 1914 | 4A4523269A91B89F7D4745F942A30437CF64A80B72DC1C89E6B4CE193589AFE7 |
| 02_Standards/rogers_ratio_table.csv | 4551 | 0F7427C7E77AA1B2BB86642ED713AA47B541FDBFE482A26D9ED7647B8C4BB7CA |
| 02_Standards/rogers_secondary_versions.csv | 2778 | 798EE67752CD4C8B923848A141D543AD99A84C2C2A4117A1924EA6BBE104FA68 |
| 02_Standards/worked_examples.csv | 4996 | 12ADBA9AEE570B61501015C29985CB403A2696D8C11EAE85D83BCA9A8F4477FB |
| 11_Results/figures/plot_style.csv | 1012 | 041FE94B9DB6D78AA2741D34C82F84CFC7045D5A5C4C903A8B85D16D480601B1 |

## Figure 3.2 counts

| stage | item | records |
|---|---|---|
| raw | IECTC10 | 117 |
| raw | DISTRAIN | 584 |
| raw | DISTEST | 70 |
| raw | DISIEC | 49 |
| raw | LI2019 | 201 |
| step9_removed | leakage | 139 |
| step9_removed | exact copy | 2 |
| step9_removed | label conflict | 4 |
| master | all | 827 |
| role | development | 439 |
| role | development complete cases | 262 |
| role | internal_test | 70 |
| role | internal_test independent | 61 |
| role | benchmark | 117 |
| role | benchmark power transformers | 58 |
| role | external_test | 201 |
| role | external_test independent | 86 |
| folds | 5 folds x 10 repeats | 439 |

Figure files: 11_Results/figures/F3_2_data_preparation_flow.png, 11_Results/figures/F3_2_data_preparation_flow.pdf, 11_Results/figures/F3_2_data_preparation_flow.csv
