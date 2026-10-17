# Step 31 report - boundary hypothesis

## Table 4.8 (pooled primary test records, answers after the gate)

| method_label | n | n_excluded_no_distance | n_disagree | beta1 | se | or | or_lo | or_hi | p | method_used | criterion3_met |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Rogers Ratio | 204 | 1 | 133 | -0.2221 | 0.1494 | 0.8008 | 0.5975 | 1.0733 | 0.1371 | maximum likelihood | False |
| IEC 60599 ratio | 204 | 1 | 97 | 0.0098 | 0.1405 | 1.0098 | 0.7668 | 1.3298 | 0.9445 | maximum likelihood | False |
| Duval Triangle 1 | 205 | 0 | 103 | -0.1973 | 0.1417 | 0.8209 | 0.6219 | 1.0836 | 0.1636 | maximum likelihood | False |

## All fits

| method | variant | analysis | n | n_disagree | n_excluded_no_distance | beta1 | or | or_lo | or_hi | p | method_used | criterion3_met |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Rogers | primary | pooled (main) | 204 | 133 | 1 | -0.2221 | 0.8008 | 0.5975 | 1.0733 | 0.1371 | maximum likelihood | False |
| Rogers | primary | pooled + test-set indicators | 204 | 133 | 1 | -0.2425 | 0.7846 | 0.5843 | 1.0537 | 0.1069 | maximum likelihood | False |
| Rogers | primary | set: Internal test | 61 | 43 | 0 | 0.2536 | 1.2887 | 0.6321 | 2.6274 | 0.4852 | maximum likelihood | False |
| Rogers | primary | set: IEC TC 10 (power transformers) | 58 | 29 | 0 | -1.01 | 0.3642 | 0.1871 | 0.709 | 0.003 | maximum likelihood | True |
| Rogers | primary | set: Li 2019 | 85 | 61 | 1 | -0.4361 | 0.6465 | 0.4052 | 1.0317 | 0.0674 | maximum likelihood | False |
| Rogers | no_gate | pooled (main) | 204 | 121 | 1 | -0.1611 | 0.8512 | 0.6401 | 1.132 | 0.268 | maximum likelihood | False |
| Rogers | no_gate | pooled + test-set indicators | 204 | 121 | 1 | -0.1745 | 0.8399 | 0.6309 | 1.118 | 0.2319 | maximum likelihood | False |
| Rogers | no_gate | set: Internal test | 61 | 39 | 0 | 0.2171 | 1.2425 | 0.6638 | 2.3258 | 0.4972 | maximum likelihood | False |
| Rogers | no_gate | set: IEC TC 10 (power transformers) | 58 | 27 | 0 | -1.2764 | 0.279 | 0.1311 | 0.5938 | 0.0009 | maximum likelihood | True |
| Rogers | no_gate | set: Li 2019 | 85 | 55 | 1 | -0.1683 | 0.8451 | 0.5441 | 1.3127 | 0.4539 | maximum likelihood | False |
| IEC60599 | primary | pooled (main) | 204 | 97 | 1 | 0.0098 | 1.0098 | 0.7668 | 1.3298 | 0.9445 | maximum likelihood | False |
| IEC60599 | primary | pooled + test-set indicators | 204 | 97 | 1 | -0.0587 | 0.943 | 0.7113 | 1.2501 | 0.6832 | maximum likelihood | False |
| IEC60599 | primary | set: Internal test | 61 | 34 | 0 | 0.2866 | 1.3318 | 0.6983 | 2.5403 | 0.3844 | maximum likelihood | False |
| IEC60599 | primary | set: IEC TC 10 (power transformers) | 58 | 15 | 0 | -0.3677 | 0.6923 | 0.3572 | 1.3419 | 0.2762 | maximum likelihood | False |
| IEC60599 | primary | set: Li 2019 | 85 | 48 | 1 | -0.3082 | 0.7348 | 0.4642 | 1.163 | 0.1883 | maximum likelihood | False |
| IEC60599 | no_gate | pooled (main) | 204 | 87 | 1 | -0.0256 | 0.9747 | 0.736 | 1.2907 | 0.858 | maximum likelihood | False |
| IEC60599 | no_gate | pooled + test-set indicators | 204 | 87 | 1 | -0.1051 | 0.9003 | 0.6749 | 1.201 | 0.4749 | maximum likelihood | False |
| IEC60599 | no_gate | set: Internal test | 61 | 34 | 0 | 0.135 | 1.1445 | 0.6607 | 1.9825 | 0.6302 | maximum likelihood | False |
| IEC60599 | no_gate | set: IEC TC 10 (power transformers) | 58 | 13 | 0 | -0.3892 | 0.6776 | 0.3343 | 1.3733 | 0.2802 | maximum likelihood | False |
| IEC60599 | no_gate | set: Li 2019 | 85 | 40 | 1 | -0.3265 | 0.7214 | 0.443 | 1.175 | 0.1895 | maximum likelihood | False |
| Duval | primary | pooled (main) | 205 | 103 | 0 | -0.1973 | 0.8209 | 0.6219 | 1.0836 | 0.1636 | maximum likelihood | False |
| Duval | primary | pooled + test-set indicators | 205 | 103 | 0 | -0.1939 | 0.8237 | 0.6204 | 1.0937 | 0.18 | maximum likelihood | False |
| Duval | primary | set: Internal test | 61 | 33 | 0 | 0.0436 | 1.0445 | 0.6279 | 1.7377 | 0.8667 | maximum likelihood | False |
| Duval | primary | set: IEC TC 10 (power transformers) | 58 | 19 | 0 | -0.3948 | 0.6738 | 0.3694 | 1.2292 | 0.198 | maximum likelihood | False |
| Duval | primary | set: Li 2019 | 86 | 51 | 0 | -0.2583 | 0.7724 | 0.5008 | 1.1913 | 0.2427 | maximum likelihood | False |
| Duval | no_gate | pooled (main) | 205 | 77 | 0 | -0.7221 | 0.4857 | 0.3416 | 0.6907 | 0.0001 | maximum likelihood | True |
| Duval | no_gate | pooled + test-set indicators | 205 | 77 | 0 | -0.7284 | 0.4827 | 0.3387 | 0.6879 | 0.0001 | maximum likelihood | True |
| Duval | no_gate | set: Internal test | 61 | 29 | 0 | -0.4113 | 0.6628 | 0.3862 | 1.1373 | 0.1354 | maximum likelihood | False |
| Duval | no_gate | set: IEC TC 10 (power transformers) | 58 | 17 | 0 | -0.5561 | 0.5735 | 0.2956 | 1.1124 | 0.1 | maximum likelihood | False |
| Duval | no_gate | set: Li 2019 | 86 | 31 | 0 | -1.2426 | 0.2886 | 0.1406 | 0.5926 | 0.0007 | maximum likelihood | True |

## Hypothesis

```
{
 "verdict_main_benchmark": "NOT SUPPORTED",
 "pooled_primary_sets": {
  "criterion3_beta1_negative_ci_excludes_0": {
   "Rogers": false,
   "IEC60599": false,
   "Duval": false
  },
  "criterion3_met": false
 }
}
```
