# Step 31C report - Study 2 leave-one-source-out runs

| variant | held_out | model | n_train | n_test | inner_macro_f1 | n_features | seconds | warnings |
|---|---|---|---|---|---|---|---|---|
| primary | DISTRAIN | B | 204 | 439 | 0.768 | 18 | 303.5 | 0 |
| primary | DISTRAIN | C | 204 | 439 | 0.81 | 49 | 120.4 | 0 |
| primary | DISTEST | B | 582 | 61 | 0.862 | 18 | 140.9 | 0 |
| primary | DISTEST | C | 582 | 61 | 0.867 | 49 | 130.9 | 0 |
| primary | IECTC10 | B | 585 | 58 | 0.866 | 18 | 141.8 | 0 |
| primary | IECTC10 | C | 585 | 58 | 0.862 | 49 | 242.1 | 0 |
| primary | LI2019 | B | 558 | 85 | 0.881 | 18 | 12843.5 | 0 |
| primary | LI2019 | C | 558 | 85 | 0.888 | 49 | 18.8 | 0 |
| equal_source_weight | DISTRAIN | B | 204 | 439 | 0.771 | 18 | 15.8 | 0 |
| equal_source_weight | DISTRAIN | C | 204 | 439 | 0.794 | 49 | 14.1 | 0 |
| equal_source_weight | DISTEST | B | 582 | 61 | 0.818 | 18 | 25.5 | 0 |
| equal_source_weight | DISTEST | C | 582 | 61 | 0.831 | 49 | 19.8 | 0 |
| equal_source_weight | IECTC10 | B | 585 | 58 | 0.861 | 18 | 17.8 | 0 |
| equal_source_weight | IECTC10 | C | 585 | 58 | 0.857 | 49 | 16.5 | 0 |
| equal_source_weight | LI2019 | B | 558 | 85 | 0.861 | 18 | 15.9 | 0 |
| equal_source_weight | LI2019 | C | 558 | 85 | 0.87 | 49 | 16.0 | 0 |
| iec_all | DISTRAIN | B | 263 | 439 | 0.8 | 18 | 16.6 | 0 |
| iec_all | DISTRAIN | C | 263 | 439 | 0.764 | 49 | 18.1 | 0 |
| iec_all | DISTEST | B | 641 | 61 | 0.851 | 18 | 22.1 | 0 |
| iec_all | DISTEST | C | 641 | 61 | 0.859 | 49 | 22.1 | 0 |
| iec_all | IECTC10 | B | 585 | 117 | 0.866 | 18 | 21.8 | 0 |
| iec_all | IECTC10 | C | 585 | 117 | 0.862 | 49 | 21.7 | 0 |
| iec_all | LI2019 | B | 617 | 85 | 0.87 | 18 | 23.9 | 0 |
| iec_all | LI2019 | C | 617 | 85 | 0.886 | 49 | 22.4 | 0 |

Rerun check: [{"task": "primary/DISTEST/B", "same_predictions": true, "max_probability_difference": 0.0}, {"task": "primary/IECTC10/C", "same_predictions": true, "max_probability_difference": 0.0}]
