%% params_transformer.m
% Parameters for the Simscape transformer operating model.
% Every value has a unit and a source. Blocks in the model use ONLY these
% variable names; no number is typed into a block dialog.

%% 1. Electrical rating  (Source E1: pandapower standard type "40 MVA 110/20 kV")
S_rated   = 40e6;     % [VA]  rated apparent power                      (E1: sn_mva = 40)
V_HV      = 110e3;    % [V]   primary rated line-to-line RMS voltage     (E1: vn_hv_kv = 110)
V_LV      = 20e3;     % [V]   secondary rated line-to-line RMS voltage   (E1: vn_lv_kv = 20)
f_rated   = 50;       % [Hz]  rated frequency                            (E1: standard types are for 50 Hz)
uk_pct    = 16.2;     % [%]   short-circuit impedance voltage            (E1: vk_percent)
ukr_pct   = 0.34;     % [%]   resistive part of uk                       (E1: vkr_percent)
P0        = 18e3;     % [W]   no-load (core) loss                        (E1: pfe_kw = 18)
i0_pct    = 0.05;     % [%]   no-load current                            (E1: i0_percent)
phase_shift_deg = 0;  % [deg] grid source phase angle (reference phasor, by definition 0)
X0_pu     = 0.5;      % [pu]  zero-sequence reactance (Simscape Electrical block default, not from E1; no effect for a balanced load; TO VERIFY if unbalanced cases are added; Step 34)

%% 2. Derived electrical quantities  (standard per-unit relations; see guide Section A3)
Pk        = ukr_pct/100 * S_rated;                 % [W]  load (copper) loss at rated current
R_pu_tot  = ukr_pct/100;                           % [pu] total series resistance
X_pu_tot  = sqrt(uk_pct^2 - ukr_pct^2)/100;        % [pu] total leakage reactance
Rw1_pu    = R_pu_tot/2;   Rw2_pu = R_pu_tot/2;     % [pu] equal split between windings (assumption A1)
Xl1_pu    = X_pu_tot/2;   Xl2_pu = X_pu_tot/2;     % [pu] equal split between windings (assumption A1)
Rm_pu     = S_rated/P0;                            % [pu] magnetising resistance from no-load loss
Xm_pu     = 1/sqrt((i0_pct/100)^2 - (1/Rm_pu)^2);  % [pu] magnetising reactance from no-load current
I_LV_rated = S_rated/(sqrt(3)*V_LV);               % [A]  rated secondary RMS line current

%% 3. Thermal model constants  (Source T1: Alliander transformer-thermal-model,
%     PowerTransformer ONAF defaults, an implementation of IEC 60076-7.
%     Replace with IEC 60076-7 / transformer test-report values when available.)
dTheta_or = 60;       % [K]   top-oil temperature rise at rated load     (T1: top_oil_temp_rise)
g_r       = 17;       % [K]   average winding-to-oil gradient            (T1: winding_oil_gradient)
H_hs      = 1.3;      % [-]   hot-spot factor                            (T1: hot_spot_fac)
tau_o_min = 150;      % [min] oil time constant                          (T1: time_const_oil)
tau_w_min = 7;        % [min] winding time constant                      (T1: time_const_windings)
k11       = 0.5;      % [-]   thermal model constant                     (T1: oil_const_k11)
k21       = 2;        % [-]   thermal model constant                     (T1: winding_const_k21)
k22       = 2;        % [-]   thermal model constant                     (T1: winding_const_k22)
x_oil     = 0.8;      % [-]   oil exponent                               (T1: oil_exp_x)
y_wdg     = 1.3;      % [-]   winding exponent                           (T1: winding_exp_y)

%% 4. Derived thermal-network values  (thermal-electrical analogy; guide Section A3)
dTheta_hr = H_hs * g_r;                     % [K]   rated hot-spot-to-top-oil gradient
P_tot_r   = P0 + Pk;                        % [W]   total loss at rated load
R_th_oil  = dTheta_or / P_tot_r;            % [K/W] oil-to-ambient thermal resistance
C_th_oil  = k11*tau_o_min*60 / R_th_oil;    % [J/K] oil thermal capacitance (R*C = k11*tau_o)
R_th_h    = 1;                              % [K/W] analogue resistance for hot-spot networks (scaling, see A3)
C_th_h1   = k22*tau_w_min*60 / R_th_h;      % [J/K] (R*C = k22*tau_w)
C_th_h2   = (tau_o_min/k22)*60 / R_th_h;    % [J/K] (R*C = tau_o/k22)
cp_unit   = 1;                              % [J/(kg*K)] unit specific heat so that block "mass" = capacitance

%% 5. Operating scenario  (run settings chosen for the verification run of guide B12; no external source)
T_zero_C_in_K = 273.15; % [K]   0 degC expressed in kelvin (physical constant; used by the thermal network so that no number is typed into a block, Step 33)
theta_amb_C = 20;     % [degC] ambient temperature (IEC reference ambient; replace with site data)
K_load      = 1.0;    % [pu]   constant load factor for the verification run
P_load_min  = 1e-3*S_rated;  % [W] minimum load power required by the variable-load block (> 0)
t_stop      = 24*3600;% [s]    simulation stop time
t_step_max  = 60;     % [s]    maximum solver step (well below the 7 min winding time constant)
solver_reltol = 1e-4; % [-]    solver relative tolerance (default 1e-3 gave 0.104 K hot-spot error vs the 0.1 K limit; 1e-4 gives 0.013 K)
% Load profile as a timeseries: time [s], load factor [pu]
load_profile = timeseries([K_load; K_load], [0; t_stop]);   % [pu] load factor against time [s] (constant K_load for the verification run)

%% 6. Insulation ageing (relative ageing rate, normal Kraft paper)
theta_ref_age = 98;   % [degC] hot-spot temperature giving relative ageing rate = 1     (A4, ref T2: IntechOpen chapter 61792 Table 1, from IEC 60076-7; TO VERIFY)
dT_double_age = 6;    % [K]    temperature increase that doubles the ageing rate         (A4, ref T2: same table; TO VERIFY)

%% 7. DGA sampling events  (Step 37, decision D35; run settings chosen for the demonstration, no external source)
% The model never produces a gas value. It only counts sampling times; the record_id of the held-out record is looked up
% outside the model (get_sampling_events.m) and the dashboard reads the gases from that record of dga_master.csv.
t_sample_h  = [6 12 18 22];   % [h]  sampling times within the run (illustrative; must increase and lie inside t_stop)
t_sample_s  = t_sample_h*3600;% [s]  the same in seconds (derived: guide Section A3 style unit conversion, 3600 s per hour)
t_event_s   = 60;             % [s]  length of the sampling_event pulse after each sampling time (run setting chosen)
% Held-out records = records of dga_master.csv whose data_role is not "development" (D35). ONLY the columns record_id and data_role
% are read, so no gas value enters the workspace.
master_csv  = fullfile(fileparts(fileparts(mfilename('fullpath'))), '03_Data', 'processed', 'dga_master.csv');   % [path] frozen data file (data version 1.0)
if ~isfile(master_csv), error('params_transformer:master', 'dga_master.csv not found at %s', master_csv); end
io_opts = detectImportOptions(master_csv);  io_opts.SelectedVariableNames = {'record_id', 'data_role'};   % [-] import options: only these two columns are read
io_opts = setvartype(io_opts, {'record_id', 'data_role'}, 'string');   % [-] text columns
master_ids = readtable(master_csv, io_opts);   % [-] temporary table, two text columns (derived from the frozen data file)
heldout_record_ids = master_ids.record_id(master_ids.data_role ~= "development");   % [-] text ids, file order
n_heldout   = numel(heldout_record_ids);   % [-] number of held-out records (388 in data version 1.0)
clear master_ids io_opts;
if any(diff(t_sample_h) <= 0) || t_sample_s(end) > t_stop || numel(t_sample_s) > n_heldout
    error('params_transformer:sampling', 'sampling times must increase, lie inside t_stop and not exceed the number of held-out records');
end