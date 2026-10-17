# Step 31B report - Study 2 pooled data set

Checks: {"exact_copies_left_across_sources": 0, "records_removed": 125, "label_conflicts": 1, "pooled_records": 702, "primary_scope_records": 643, "near_duplicate_groups_multi": 10, "cross_source_groups": 0, "data_version_1_0_unchanged": true}

## Exact copies removed (kept copy's source by priority)

| removed_source | kept_source | records |
|---|---|---|
| DISTEST | IECTC10 | 9 |
| LI2019 | DISTEST | 1 |
| LI2019 | IECTC10 | 115 |

## Records per source and class (primary scope)

| source_id | Normal | PD | D1 | D2 | T12 | T3 | All |
|---|---|---|---|---|---|---|---|
| DISTEST | 10 | 7 | 7 | 8 | 20 | 9 | 61 |
| DISTRAIN | 75 | 37 | 53 | 85 | 119 | 70 | 439 |
| IECTC10 | 0 | 1 | 10 | 27 | 8 | 12 | 58 |
| LI2019 | 0 | 8 | 22 | 7 | 28 | 20 | 85 |
| All | 85 | 53 | 92 | 127 | 175 | 111 | 643 |

## Leave-one-source-out sizes

| held_out | n_test | n_train_before | n_train_removed_near_copies | n_train_used |
|---|---|---|---|---|
| IECTC10 | 58 | 585 | 0 | 585 |
| DISTRAIN | 439 | 204 | 0 | 204 |
| DISTEST | 61 | 582 | 0 | 582 |
| LI2019 | 85 | 558 | 0 | 558 |
