# APPENDICES

# APPENDIX A Diagrams of the Simulink Subsystems {#app:simulink}

The diagrams below were exported from the final Simulink model (MATLAB R2025b) by a read-only script; the SHA-256 fingerprint of the model file was the same before and after the export. The explanatory annotation bars of each subsystem are omitted; their content is summarised in the captions. Subsystem SS6 is shown in Chapter 8 (@fig:ss6).

![SS1 Grid supply: three-phase 110 kV source with its electrical reference and solver configuration](12_Thesis/figures/simulink_SS1_Grid_Supply_crop.png){#fig:ss1 width=11}

![SS2 Power transformer: two-winding 40 MVA, 110/20 kV transformer (Simscape Electrical); impedance and losses from the parameter script](12_Thesis/figures/simulink_SS2_Power_Transformer_crop.png){#fig:ss2 width=12}

![SS3 LV measurement: three-phase current sensor; the load factor K is the RMS current divided by the rated current](12_Thesis/figures/simulink_SS3_LV_Measurement_crop.png){#fig:ss3 width=14}

![SS4 Variable load: the load profile (per unit) drives a wye-connected variable load](12_Thesis/figures/simulink_SS4_Variable_Load_crop.png){#fig:ss4 width=14}

![SS5 Losses to heat: load and no-load losses converted into the heat inputs of the oil and hot-spot circuits (Simulink arithmetic)](12_Thesis/figures/simulink_SS5_Losses_to_Heat_crop.png){#fig:ss5 width=14}

![SS7 Outputs and ageing: hot-spot temperature, relative ageing rate and logged signals](12_Thesis/figures/simulink_SS7_Outputs_and_Ageing_crop.png){#fig:ss7 width=14}

![SS8 Sampling events: clock, sampling times and logic that output the record index and the sampling pulse; no block carries a gas value](12_Thesis/figures/simulink_SS8_Sampling_Events_crop.png){#fig:ss8 width=15}

# APPENDIX B Additional Results {#app:extra}

[[TABLE:cv_full]] {#tab:cvfull}

[[TABLE:per_class_cv]] {#tab:perclass}

[[TABLE:gas_stats benchmark]] {#tab:gasbench}

![Development records in the Duval Triangle 1, coloured by the true fault class](12_Thesis/figures/thesis/duval_development.png){#fig:duv-dev width=13}

![Internal test records in the Duval Triangle 1](12_Thesis/figures/thesis/duval_internal.png){#fig:duv-int width=13}

![Li (2019) records in the Duval Triangle 1](12_Thesis/figures/thesis/duval_external.png){#fig:duv-li width=13}

![Confusion matrices of the conventional methods on the internal test set (n = 61)](12_Thesis/figures/thesis/conf_conv_internal.png){#fig:conf-int width=15.5}

![Confusion matrices of the conventional methods on the Li (2019) set (n = 86)](12_Thesis/figures/thesis/conf_conv_li.png){#fig:conf-li width=15.5}

![Constant rated-load scenario: load factor, temperatures, and relative ageing rate with the loss of life](12_Thesis/figures/thesis/scenario_rated.png){#fig:scen-rated width=15}
