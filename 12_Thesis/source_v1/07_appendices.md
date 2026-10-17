# APPENDICES

# APPENDIX A Diagrams of the Simulink Subsystems {#app:simulink}

The diagrams below were exported from the final Simulink model (MATLAB R2025b) by a read-only script; the SHA-256 fingerprint of the model file was the same before and after the export. The annotation bars of each subsystem are omitted; their content is summarised in the captions.

![SS1 Grid Supply: three-phase 110 kV source with its electrical reference and solver configuration](12_Thesis/figures/simulink_SS1_Grid_Supply_crop.png){#fig:ss1 width=11}

![SS2 Power Transformer: two-winding 40 MVA, 110/20 kV transformer (Simscape Electrical); impedance and losses from the parameter file](12_Thesis/figures/simulink_SS2_Power_Transformer_crop.png){#fig:ss2 width=12}

![SS3 LV Measurement: three-phase current sensor; the load factor K is the RMS current divided by the rated current](12_Thesis/figures/simulink_SS3_LV_Measurement_crop.png){#fig:ss3 width=14}

![SS4 Variable Load: the load profile (per unit) drives a wye-connected variable load](12_Thesis/figures/simulink_SS4_Variable_Load_crop.png){#fig:ss4 width=14}

![SS5 Losses to Heat: load and no-load losses converted into the heat inputs of the oil and hot-spot circuits (Simulink arithmetic)](12_Thesis/figures/simulink_SS5_Losses_to_Heat_crop.png){#fig:ss5 width=14}

![SS7 Outputs and Ageing: hot-spot temperature, relative ageing rate and logged signals](12_Thesis/figures/simulink_SS7_Outputs_and_Ageing_crop.png){#fig:ss7 width=14}

![SS8 Sampling Events: clock, sampling times and logic that output the record index and the sampling pulse; no block carries a gas value](12_Thesis/figures/simulink_SS8_Sampling_Events_crop.png){#fig:ss8 width=15}

# APPENDIX B Additional Results {#app:extra}

[[TABLE:cv_full]] {#tab:cvfull}

[[TABLE:per_class_cv]] {#tab:perclass}

[[TABLE:gas_stats benchmark]] {#tab:gasbench}

![Duval Triangle 1 with the development records, coloured by class](11_Results/figures/duval_development.png){#fig:duv-dev width=12.5}

![Duval Triangle 1 with the internal test records](11_Results/figures/duval_internal_test.png){#fig:duv-int width=12.5}

![Duval Triangle 1 with the Li (2019) records](11_Results/figures/duval_external_test.png){#fig:duv-li width=12.5}

![Confusion matrices of the conventional methods on the internal test set (n = 61)](11_Results/figures/F4_5a_confusion_conventional_internal.png){#fig:conf-int width=15.5}

![Confusion matrices of the conventional methods on the Li (2019) set (n = 86)](11_Results/figures/F4_5c_confusion_conventional_li2019.png){#fig:conf-li width=15.5}

![Constant rated-load scenario: load factor, temperatures, and ageing rate with the loss of life](11_Results/figures/F4_19a_scenario_rated.png){#fig:scen-rated width=14.5}

# APPENDIX C Key Methodological Decisions

Table: Key Decisions Recorded during the Research {#tab:decisions} {widths=8,92}
| No. | Decision |
|---|---|
| D2 | Five gases (H2, CH4, C2H6, C2H4, C2H2); CO and CO2 not used in modelling |
| D3 | Normal kept as a class where present; a normality gate lets the conventional methods answer Normal; IEC TC 10 scored on five merged classes |
| D4 | The Simulink model represents the operating context only and never generates gas values |
| D6 | Five classifiers: SVM, random forest, XGBoost, MLP and multinomial logistic regression, plus a majority-class baseline |
| D7 | Dissanayake labels of undocumented origin: development data only; the inspection-labelled IEC TC 10 set is the main benchmark |
| D8 | A gas value that is not available is treated as not detected (0 ppm), with flags; complete records as sensitivity analysis |
| D9 | Test records that duplicate a benchmark case are flagged; independent records used for separate evidence |
| D11–D13 | Implementation rules of the conventional methods (gate, dual answers, end points, T1 condition) |
| D15 | Log-ratios with a 1 ppm offset; fold-local median imputation and class weights; no over-sampling |
| D17–D18 | Nested cross-validation details and the model-selection rule, fixed before the results were read |
| D19 | Final fit and one-time prediction of the test sets, logged; evaluation sets fixed |
| D22–D24 | Reduced-gas study: feature rules, conventional applicability, bootstrap loss and minimum-panel rule |
| D25–D27 | Scoring, significance tests and boundary analysis, fixed before computation |
| D28–D29 | Exploratory Study 2, pre-registered |
| D31–D35 | Simulink build, model checks, verification, scenarios and sampling events |
| D36–D40 | Diagnosis service, dashboard, Simulink link, test bench and integration evaluation |
Source: project decision log (00_Project_Admin/decisions_log.md).
