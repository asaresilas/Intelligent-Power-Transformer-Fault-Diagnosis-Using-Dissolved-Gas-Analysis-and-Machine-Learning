# Step 28 report - merged predictions

Checks: {"test_records_in_master": 388, "rows_merged": 388, "unique_record_ids": 388, "no_record_lost": true, "no_record_duplicated": true, "no_development_record": true, "ml_records_all_used": true, "conventional_rows_per_test_record": 3, "gate_same_for_all_methods": true, "no_missing_prediction": true, "per_role": {"external_test": 201, "benchmark": 117, "internal_test": 70}, "ml_predictions_sha256": "D103E8CA1B21C49A78E2F5A8795D0C423D46E6303856DAD1081928BAFACCF142", "conventional_predictions_sha256": "30DDD34EEF12AEF67F695C2FCE387E759DD7AFEC03CF71E2635660875D063A1A", "merged_sha256": "EDB799A2CDA41A69CFD3A90320DC2EFDD683E9BF99495E6D65C8474BBB67BB14"}

Overall: PASS

## Answers per method (all 388 test records; conventional after the upper gate)

| answer | IEC60599 | Rogers | Duval | ML |
|---|---|---|---|---|
| ND | 85 | 139 | 0 | 0 |
| Normal | 78 | 82 | 78 | 16 |
| D1/D2 | 60 | 0 | 0 | 0 |
| D1 | 43 | 0 | 65 | 72 |
| T3 | 37 | 44 | 56 | 56 |
| D2 | 30 | 97 | 115 | 137 |
| T2 | 28 | 19 | 22 | 35 |
| PD | 14 | 5 | 29 | 37 |
| T1 | 13 | 2 | 16 | 35 |
| DT | 0 | 0 | 7 | 0 |

Columns (51): record_id, source_id, data_role, class_code, class_name, class_merged, in_scope_primary, independent_of_benchmark, benchmark_duplicate_of, equipment_type, H2, CH4, C2H6, C2H4, C2H2, ml_pred, ml_pred_merged, ml_p_Normal, ml_p_PD, ml_p_D1, ml_p_D2, ml_p_T1, ml_p_T2, ml_p_T3, gate_upper_normal, gate_lower_normal, IEC60599_raw, IEC60599_result, IEC60599_result_lower_gate, IEC60599_result_merged, IEC60599_result_lower_gate_merged, IEC60599_boundary_distance, Rogers_raw, Rogers_result, Rogers_result_lower_gate, Rogers_result_merged, Rogers_result_lower_gate_merged, Rogers_boundary_distance, Duval_raw, Duval_result, Duval_result_lower_gate, Duval_result_merged, Duval_result_lower_gate_merged, Duval_boundary_distance, ratio_R1, ratio_R2, ratio_R5, duval_pct_CH4, duval_pct_C2H4, duval_pct_C2H2, data_version
