function build_Transformer_Operating_Model(mdl)
%BUILD_TRANSFORMER_OPERATING_MODEL  Build Transformer_Operating_Model.slx from MATLAB Build Guide Part B (Roadmap Step 33).
%
%   build_Transformer_Operating_Model()            builds 05_Simulink_Model/Transformer_Operating_Model.slx
%   build_Transformer_Operating_Model(modelName)   builds a model of another name in the same folder (used for tests)
%
%   PURPOSE
%     Operating-context model of the 40 MVA, 110/20 kV transformer: electrical power path (Simscape Electrical),
%     loss calculation (Simulink), thermal network (Simscape Foundation thermal) and ageing outputs (Simulink).
%     The model NEVER generates a gas concentration (decision D4); gases always come from measured records.
%
%   RULES FOLLOWED (Build Guide, "Three rules")
%     1. No number is typed into a block. Every value is a variable of params_transformer.m. The only literals are
%        mathematical constants of the equations (1/3 for three phases, the exponent selector, log(2), inf).
%     2. Every subsystem has an annotation (what it does, inputs, outputs, parameters) and a block Description.
%     3. No gas values are simulated.
%
%   MODEL LAYOUT (Guide B1)
%     SS1_Grid_Supply -> SS2_Power_Transformer -> SS3_LV_Measurement -> SS4_Variable_Load   (electrical network)
%     SS3 (K_pu) -> SS5_Losses_to_Heat -> SS6_Thermal_Network -> SS7_Outputs_and_Ageing      (thermal chain)
%     The arithmetic (square root, powers, products) is done with Simulink blocks between converter blocks because the
%     electrical network uses the "Frequency and time" equation formulation, which accepts only switched-linear
%     equations (Guide B1 and B13). The electrical and thermal parts are two separate physical networks, each with its
%     own Solver Configuration.
%
%   DIFFERENCES FROM THE GUIDE (all recorded in the Step 33 report)
%     a. The callbacks PreLoadFcn and InitFcn do not only call params_transformer; they first put the model folder on
%        the MATLAB path if the script is not found, so the model opens from any folder (same weakness as found in the
%        rerun model on 2026-10-12).
%     b. The 0 degC offset 273.15 K is the variable T_zero_C_in_K of params_transformer.m (the guide typed 273.15).
%     c. Extra annotations inside the subsystems (units, assumptions, equations) and a Description on every subsystem.
%     d. Step 34 (Model Advisor): Sqrt block instead of the deprecated Math Function 'sqrt'; diagnostics for Inf/NaN,
%        unconnected ports/lines, duplicate data stores and bus-as-vector set to error; block name of Exp shown.
%     e. Step 37: SS8_Sampling_Events (decision D35), a subsystem that is not connected to SS1-SS7.
%
%   REQUIRES  MATLAB R2025b, Simulink, Simscape, Simscape Electrical. params_transformer.m in this folder.
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 33 (Simulink Agentic Toolkit role, run through the MATLAB MCP, D14).

if nargin < 1, mdl = 'Transformer_Operating_Model'; end
global STEP33_LOG
STEP33_LOG = cell(0, 3);                          % log of every block setting made below
here = fileparts(mfilename('fullpath'));
cd(here);
addpath(here);
run(fullfile(here, 'params_transformer.m'));     %#ok<RUN>  makes the variables exist for the checks below
load_system('fl_lib'); load_system('ee_lib'); load_system('nesl_utility');
if bdIsLoaded(mdl), close_system(mdl, 0); end
file = fullfile(here, [mdl '.slx']);
if exist(file, 'file'), delete(file); end
new_system(mdl); open_system(mdl);

%% B2. Model settings: callbacks, solver, description ---------------------------------------------------
cb = ['if exist(''params_transformer'',''file'')~=2, addpath(fileparts(get_param(bdroot,''FileName''))); end; ' ...
      'params_transformer;'];
set_param(mdl, 'PreLoadFcn', cb, 'InitFcn', cb);
set_param(mdl, 'Solver', 'ode23t', 'StopTime', 't_stop', 'MaxStep', 't_step_max', 'RelTol', 'solver_reltol', ...
    'SaveOutput', 'on', 'ReturnWorkspaceOutputs', 'on');
% Step 34 (Model Advisor): diagnostics at the recommended level, so a bad value or an open connection stops the run
% instead of passing silently (checks mathworks.maab.jc_0021, mathworks.design.DataStoreMemoryBlkIssue, BusTreatedAsVector).
set_param(mdl, 'SignalInfNanChecking', 'error', 'UnconnectedInputMsg', 'error', 'UnconnectedOutputMsg', 'error', ...
    'UnconnectedLineMsg', 'error', 'UniqueDataStoreMsg', 'error', 'StrictBusMsg', 'ErrorOnBusTreatedAsVector');
set_param(mdl, 'Description', ['Transformer operating model (40 MVA, 110/20 kV): electrical network, losses, thermal network and ' ...
    'ageing. Operating context only: no gas value is generated. Parameters: params_transformer.m. ' ...
    'Built by build_Transformer_Operating_Model.m (MPhil project, Roadmap Step 33).']);

% Library paths (names checked against R2025b by the reference build)
L.vsrc  = 'ee_lib/Sources/Voltage Source (Three-Phase)';
L.xfmr  = 'ee_lib/Passive/Transformers/Two-Winding Transformer (Three-Phase)';
L.isens = 'ee_lib/Sensors & Transducers/Current Sensor (Three-Phase)';
L.load  = 'ee_lib/Passive/RLC Assemblies/Wye-Connected Variable Load';
L.eref  = 'ee_lib/Connectors & References/Electrical Reference';
L.solv  = 'nesl_utility/Solver Configuration';
L.s2ps  = 'nesl_utility/Simulink-PS Converter';
L.ps2s  = 'nesl_utility/PS-Simulink Converter';
L.cport = 'nesl_utility/Connection Port';
L.mass  = 'fl_lib/Thermal/Thermal Elements/Thermal Mass';
L.tres  = 'fl_lib/Thermal/Thermal Elements/Thermal Resistance';
L.tref  = 'fl_lib/Thermal/Thermal Elements/Thermal Reference';
L.chf   = 'fl_lib/Thermal/Thermal Sources/Controlled Heat Flow Rate Source';
L.tsrc  = 'fl_lib/Thermal/Thermal Sources/Temperature Source';
L.tsens = 'fl_lib/Thermal/Thermal Sensors/Temperature Sensor';

%% B1/B3. The seven subsystems ---------------------------------------------------------------------------
ss = {'SS1_Grid_Supply', 'SS2_Power_Transformer', 'SS3_LV_Measurement', 'SS4_Variable_Load', ...
      'SS5_Losses_to_Heat', 'SS6_Thermal_Network', 'SS7_Outputs_and_Ageing', 'SS8_Sampling_Events'};
pos = [40 100; 220 100; 400 100; 580 100; 400 300; 580 300; 760 300; 760 100];
colour = {'[0.80 0.90 1.00]', '[0.80 0.90 1.00]', '[0.80 0.90 1.00]', '[0.80 0.90 1.00]', ...   % electrical (Simscape Electrical)
          '[0.85 1.00 0.85]', '[1.00 0.88 0.72]', '[0.85 1.00 0.85]', '[0.90 0.85 1.00]'};       % loss calc / thermal / outputs / sampling events
desc = { ...
  'Simscape Electrical. Ideal 110 kV, 50 Hz three-phase source (infinite bus). Output HV_out.', ...
  'Simscape Electrical. 40 MVA Delta/grounded-Wye transformer with winding resistance, leakage and magnetising branch. HV_in -> LV_out.', ...
  'Simscape Electrical sensor + Simulink arithmetic. Measures the LV currents and outputs the load factor K_pu. LV_in -> LV_out, K_pu.', ...
  'Simscape Electrical + Simulink. Resistive three-phase load, P = K(t)*S_rated, from load_profile. Input LV_in.', ...
  'Simulink. Heat inputs Q_oil, Q_h1, Q_h2 [W] from K_pu (IEC 60076-7 differential-equation model).', ...
  'Simscape Foundation thermal. Three R-C circuits: top oil, hot-spot rise 1 and 2. Own Solver Configuration.', ...
  'Simulink. Hot-spot temperature, relative ageing rate, and logging of K_pu, theta_oil_C, theta_hs_C, ageing_rate_V.', ...
  'Simulink. DGA sampling events (Step 37): from the clock and t_sample_s it outputs record_index (row in heldout_record_ids) and sampling_event. Never a gas value; not connected to SS1-SS7.'};
for k = 1:numel(ss)
    add_block('built-in/Subsystem', [mdl '/' ss{k}], 'Position', [pos(k, :) pos(k, :) + [120 90]]);
    delete_default_content([mdl '/' ss{k}]);
    set_param([mdl '/' ss{k}], 'BackgroundColor', colour{k}, 'Description', desc{k});
end

%% B4. SS1_Grid_Supply ---------------------------------------------------------------------------------
s = [mdl '/SS1_Grid_Supply'];
b_src = addb(L.vsrc, [s '/Grid_Source'], [60 60 140 120], ...
    'vline_rms', 'V_HV', 'vline_rms_unit', 'V', 'freq', 'f_rated', 'freq_unit', 'Hz', ...
    'shift', 'phase_shift_deg', 'shift_unit', 'deg');
setp(b_src, 'impedance_option', '0');       % 0 = 'None': ideal source, probed in R2025b (reference build)
b_ref = addb(L.eref, [s '/Ground'], [70 180 110 220]);
b_sol = addb(L.solv, [s '/Solver_Configuration'], [160 170 220 210]);
setp(b_sol, 'EquationFormulation', 'NE_FREQUENCY_TIME_EF');     % Frequency and time
p_hv  = cport(s, 'HV_out', 'Right', [320 80 350 100]);
conn(s, ph(b_src, 'LConn', 1), ph(b_ref, 'LConn', 1));              % star point n -> ground
conn(s, ph(b_sol, 'RConn', 1), ph(b_ref, 'LConn', 1));              % solver attached to the network
conn(s, ph(b_src, 'RConn', 1), p_hv);                               % three-phase terminal -> HV_out
note(s, ['SS1 GRID SUPPLY. Ideal three-phase source (infinite bus) at V_HV, f_rated. Output: HV_out (three-phase, composite). ' ...
    'Parameters: V_HV, f_rated, phase_shift_deg. Solver Configuration sets the equation formulation for the electrical network.'], [20 250]);
note(s, 'Source impedance = None, so the source voltage stays balanced whatever current flows. The star point n is tied to the Electrical Reference (0 V).', [20 300]);

%% B5. SS2_Power_Transformer ---------------------------------------------------------------------------
s = [mdl '/SS2_Power_Transformer'];
p_in  = cport(s, 'HV_in', 'Left', [20 80 50 100]);
b_tx  = addb(L.xfmr, [s '/Two_Winding_Transformer'], [140 60 240 120], ...
    'SRated', 'S_rated', 'SRated_unit', 'V*A', 'FRated', 'f_rated', 'FRated_unit', 'Hz', ...
    'VRated1', 'V_HV', 'VRated1_unit', 'V', 'VRated2', 'V_LV', 'VRated2_unit', 'V', ...
    'Winding1Connection', 'ee.enum.windingconnection.delta1', ...
    'Winding2Connection', 'ee.enum.windingconnection.Yg', ...
    'pu_Rw1', 'Rw1_pu', 'pu_Rw2', 'Rw2_pu', ...
    'leakage_reactance_option', 'ee.enum.transformer_leakage.include', 'pu_Xl1', 'Xl1_pu', 'pu_Xl2', 'Xl2_pu', ...
    'magnetizing_resistance_option', 'ee.enum.transformer_magnetizingResistance.include', 'pu_Rm', 'Rm_pu', ...
    'magnetizing_reactance_option', 'ee.enum.transformer_magnetizingReactance.include', 'pu_Xm', 'Xm_pu', ...
    'pu_X0', 'X0_pu');                    % Step 34: zero-sequence reactance was the block default 0.5 typed in the dialog
p_out = cport(s, 'LV_out', 'Right', [330 80 360 100]);
conn(s, p_in, ph(b_tx, 'LConn', 1));
conn(s, ph(b_tx, 'RConn', 1), p_out);
note(s, ['SS2 POWER TRANSFORMER. Two-winding three-phase transformer, Delta (HV), grounded Wye (LV). Input: HV_in. Output: LV_out. ' ...
    'Parameters: S_rated, V_HV, V_LV, Rw1_pu, Rw2_pu, Xl1_pu, Xl2_pu, Rm_pu, Xm_pu, X0_pu.'], [20 160]);
note(s, ['Vector group: pandapower lists this type with a 150 degree phase shift; the block offers only Delta 1 o''clock or Delta 11 o''clock, ' ...
    'so Delta 1 o''clock / grounded Wye is used. The phase displacement does not change current magnitudes, losses or temperatures.'], [20 210]);
note(s, 'Per-unit values are on the transformer rating (S_rated, V_HV, V_LV). Magnetic saturation is not modelled (linear transformer).', [20 260]);

%% B6. SS3_LV_Measurement ------------------------------------------------------------------------------
s = [mdl '/SS3_LV_Measurement'];
p_in  = cport(s, 'LV_in', 'Left', [20 80 50 100]);
b_is  = addb(L.isens, [s '/Current_Sensor_3ph'], [120 60 200 120]);
p_out = cport(s, 'LV_out', 'Right', [520 60 550 80]);
b_cv  = addb(L.ps2s, [s '/PS_to_Simulink_I'], [140 180 170 200], 'Unit', 'A');
addb('simulink/Math Operations/Dot Product', [s '/Sum_of_Squares'], [210 175 250 215]);
addb('simulink/Math Operations/Gain', [s '/Divide_by_3'], [280 180 320 210], 'Gain', '1/3');
% Step 34: the Sqrt block replaces the Math Function block with Operator 'sqrt' (deprecated, Model Advisor check
% mathworks.design.UpdateRequireCompile). Same result for the non-negative input used here (mean of squares).
addb('simulink/Math Operations/Sqrt', [s '/Square_Root'], [350 180 390 210], 'Operator', 'sqrt');
addb('simulink/Math Operations/Gain', [s '/Per_Unit'], [420 180 460 210], 'Gain', '1/I_LV_rated');
addb('simulink/Sinks/Out1', [s '/K_pu'], [520 185 550 205]);
conn(s, p_in, ph(b_is, 'LConn', 1));
conn(s, ph(b_is, 'RConn', 2), p_out);
conn(s, ph(b_is, 'RConn', 1), ph(b_cv, 'LConn', 1));
add_line(s, 'PS_to_Simulink_I/1', 'Sum_of_Squares/1', 'autorouting', 'smart');
add_line(s, 'PS_to_Simulink_I/1', 'Sum_of_Squares/2', 'autorouting', 'smart');
add_line(s, 'Sum_of_Squares/1', 'Divide_by_3/1');
add_line(s, 'Divide_by_3/1', 'Square_Root/1');
add_line(s, 'Square_Root/1', 'Per_Unit/1');
add_line(s, 'Per_Unit/1', 'K_pu/1');
note(s, ['SS3 LV MEASUREMENT. Current Sensor (Three-Phase) measures ia, ib, ic on the LV side. K = sqrt((ia^2+ib^2+ic^2)/3)/I_LV_rated ' ...
    '(exact RMS for a balanced set). Input: LV_in. Outputs: LV_out (pass-through), K_pu (Simulink signal, per unit). Parameter: I_LV_rated.'], [20 260]);
note(s, ['Units along the chain: vector of currents [A] -> sum of squares [A^2] -> mean square [A^2] -> RMS [A] -> K_pu [pu]. ' ...
    'For a balanced set ia^2+ib^2+ic^2 is constant, so no filter is needed.'], [20 310]);

%% B7. SS4_Variable_Load -------------------------------------------------------------------------------
s = [mdl '/SS4_Variable_Load'];
p_in  = cport(s, 'LV_in', 'Left', [20 80 50 100]);
addb('simulink/Sources/From Workspace', [s '/Load_Profile'], [40 170 120 200], ...
    'VariableName', 'load_profile', 'OutputAfterFinalValue', 'Holding final value');
addb('simulink/Math Operations/Gain', [s '/K_to_Power'], [150 170 200 200], 'Gain', 'S_rated');
addb('simulink/Discontinuities/Saturation', [s '/Min_Power'], [220 170 270 200], ...
    'UpperLimit', 'inf', 'LowerLimit', 'P_load_min');
b_cv  = addb(L.s2ps, [s '/Power_to_PS'], [300 175 330 195], 'Unit', 'W');
b_ld  = addb(L.load, [s '/Wye_Variable_Load'], [360 60 440 140], ...
    'VRated', 'V_LV', 'VRated_unit', 'V', 'Pmin', 'P_load_min', 'Pmin_unit', 'W');
b_er  = addb(L.eref, [s '/Ground'], [480 160 520 200]);
conn(s, p_in, ph(b_ld, 'LConn', 2));
conn(s, ph(b_ld, 'RConn', 1), ph(b_er, 'LConn', 1));
add_line(s, 'Load_Profile/1', 'K_to_Power/1');
add_line(s, 'K_to_Power/1', 'Min_Power/1');
add_line(s, 'Min_Power/1', 'Power_to_PS/1');
conn(s, ph(b_cv, 'RConn', 1), ph(b_ld, 'LConn', 1));
note(s, ['SS4 VARIABLE LOAD. Resistive three-phase load whose real power follows the load profile: P = K(t)*S_rated (unity power factor, assumption). ' ...
    'Input: LV_in. Parameters: load_profile, S_rated, V_LV, P_load_min.'], [20 260]);
note(s, ['The demanded K is a power demand at rated voltage. The load sits behind the transformer impedance, so the LV voltage drops and the ' ...
    'measured K_pu in SS3 is slightly lower (0.9839 for a demand of 1.0, Guide B12). SS3, not this block, feeds the thermal chain.'], [20 310]);
note(s, 'Min_Power keeps P above the block''s required minimum (> 0); load_profile is held at its final value after the last time stamp.', [20 360]);

%% B8. SS5_Losses_to_Heat ------------------------------------------------------------------------------
s = [mdl '/SS5_Losses_to_Heat'];
addb('simulink/Sources/In1', [s '/K_pu'], [20 95 50 115]);
addb('simulink/Math Operations/Math Function', [s '/K_squared'], [100 40 140 70], 'Operator', 'square');
addb('simulink/Math Operations/Gain', [s '/Load_Loss_Pk'], [170 40 210 70], 'Gain', 'Pk');
addb('simulink/Math Operations/Bias', [s '/Plus_No_Load_Loss_P0'], [240 40 280 70], 'Bias', 'P0');
addb('simulink/Math Operations/Gain', [s '/Normalise'], [310 40 350 70], 'Gain', '1/P_tot_r');
addb('simulink/Sources/Constant', [s '/Exponent_x'], [310 90 350 110], 'Value', 'x_oil');
addb('simulink/Math Operations/Math Function', [s '/Power_x'], [380 40 420 100], 'Operator', 'pow');
addb('simulink/Math Operations/Gain', [s '/Q_oil_Gain'], [450 55 490 85], 'Gain', 'P_tot_r');
addb('simulink/Sources/Constant', [s '/Exponent_y'], [100 200 140 220], 'Value', 'y_wdg');
addb('simulink/Math Operations/Math Function', [s '/K_power_y'], [170 150 210 210], 'Operator', 'pow');
addb('simulink/Math Operations/Gain', [s '/Q_h1_Gain'], [260 140 300 170], 'Gain', 'k21*dTheta_hr/R_th_h');
addb('simulink/Math Operations/Gain', [s '/Q_h2_Gain'], [260 200 300 230], 'Gain', '(k21-1)*dTheta_hr/R_th_h');
addb('simulink/Sinks/Out1', [s '/Q_oil'], [560 60 590 80]);
addb('simulink/Sinks/Out1', [s '/Q_h1'], [560 145 590 165]);
addb('simulink/Sinks/Out1', [s '/Q_h2'], [560 205 590 225]);
al = @(a, b) add_line(s, a, b, 'autorouting', 'smart');
al('K_pu/1', 'K_squared/1'); al('K_squared/1', 'Load_Loss_Pk/1'); al('Load_Loss_Pk/1', 'Plus_No_Load_Loss_P0/1');
al('Plus_No_Load_Loss_P0/1', 'Normalise/1'); al('Normalise/1', 'Power_x/1'); al('Exponent_x/1', 'Power_x/2');
al('Power_x/1', 'Q_oil_Gain/1'); al('Q_oil_Gain/1', 'Q_oil/1');
al('K_pu/1', 'K_power_y/1'); al('Exponent_y/1', 'K_power_y/2');
al('K_power_y/1', 'Q_h1_Gain/1'); al('K_power_y/1', 'Q_h2_Gain/1');
al('Q_h1_Gain/1', 'Q_h1/1'); al('Q_h2_Gain/1', 'Q_h2/1');
note(s, ['SS5 LOSSES TO HEAT. Total loss P0 + Pk*K^2; equivalent oil heat input Q_oil = P_tot_r*((P0+Pk*K^2)/P_tot_r)^x; hot-spot drives ' ...
    'Q_h1 = k21*dTheta_hr*K^y/R_th_h and Q_h2 = (k21-1)*dTheta_hr*K^y/R_th_h (IEC 60076-7 differential-equation model). Outputs in W.'], [20 270]);
note(s, ['Why these gains: at steady state the oil circuit gives dTheta_o = Q_oil*R_th_oil = dTheta_or*((P0+Pk*K^2)/P_tot_r)^x (IEC 60076-7 oil rise), ' ...
    'and the two hot-spot circuits give dTheta_h1 - dTheta_h2 = dTheta_hr*K^y (R_th_h = 1 K/W is a scaling choice, Guide A3).'], [20 320]);

%% B9. SS6_Thermal_Network -----------------------------------------------------------------------------
s = [mdl '/SS6_Thermal_Network'];
names = {'Oil', 'HS1', 'HS2'}; caps = {'C_th_oil', 'C_th_h1', 'C_th_h2'};
ress  = {'R_th_oil', 'R_th_h', 'R_th_h'};
inn   = {'Q_oil', 'Q_h1', 'Q_h2'}; outn = {'theta_oil_C', 'dTheta_h1', 'dTheta_h2'};
outu  = {'degC', 'K', 'K'};
T0 = 'theta_amb_C + T_zero_C_in_K';                                  % ambient in kelvin, from params_transformer.m
b_ref = addb(L.tref, [s '/Thermal_Reference'], [100 560 140 590]);   % joins the three circuits into ONE physical network
b_amb = addb(L.tsrc, [s '/Ambient_Temperature'], [440 560 480 600], 'temperature', T0, 'temperature_unit', 'K');
for k = 1:3
    y0 = 40 + (k - 1) * 150;
    addb('simulink/Sources/In1', sprintf('%s/%s', s, inn{k}), [20 y0+5 50 y0+25]);
    b_cs  = addb(L.s2ps, sprintf('%s/Heat_to_PS_%s', s, names{k}), [70 y0 100 y0+30], 'Unit', 'W');
    b_src = addb(L.chf, sprintf('%s/Heat_Source_%s', s, names{k}), [130 y0 170 y0+40]);
    b_m   = addb(L.mass, sprintf('%s/Thermal_Mass_%s', s, names{k}), [220 y0-20 260 y0+10], ...
        'mass', caps{k}, 'mass_unit', 'kg', 'sp_heat', 'cp_unit', 'sp_heat_unit', 'J/(kg*K)', ...
        'T_specify', 'on', 'T_priority', 'High', 'T', T0, 'T_unit', 'K');
    b_r   = addb(L.tres, sprintf('%s/Thermal_Resistance_%s', s, names{k}), [300 y0 340 y0+30], ...
        'resistance', ress{k}, 'resistance_unit', 'K/W');
    if k == 1, meas = 'absolute'; else, meas = 'difference'; end
    b_ts  = addb(L.tsens, sprintf('%s/Temperature_Sensor_%s', s, names{k}), [300 y0+60 340 y0+90], ...
        'temperature_measure', ['foundation.enum.MeasurementReference.' meas]);
    b_co  = addb(L.ps2s, sprintf('%s/PS_to_Simulink_%s', s, names{k}), [380 y0+65 410 y0+85], 'Unit', outu{k});
    if k == 1, setp(b_co, 'AffineConversion', 'on'); end      % deg C needs the 273.15 K offset
    addb('simulink/Sinks/Out1', sprintf('%s/%s', s, outn{k}), [460 y0+65 490 y0+85]);
    add_line(s, [inn{k} '/1'], sprintf('Heat_to_PS_%s/1', names{k}));
    conn(s, ph(b_cs, 'RConn', 1), ph(b_src, 'RConn', 1));          % heat command -> source S
    conn(s, ph(b_src, 'RConn', 2), ph(b_ref, 'LConn', 1));         % source A -> reference
    conn(s, ph(b_src, 'LConn', 1), ph(b_m, 'LConn', 1));           % source B -> mass node
    conn(s, ph(b_m, 'LConn', 1), ph(b_r, 'LConn', 1));             % node -> resistance A
    conn(s, ph(b_r, 'RConn', 1), ph(b_amb, 'LConn', 1));           % resistance B -> ambient
    conn(s, ph(b_m, 'LConn', 1), ph(b_ts, 'LConn', 1));            % node -> sensor A
    q = get_param(b_ts, 'PortHandles');
    if k > 1, conn(s, q.RConn(1), ph(b_amb, 'LConn', 1)); end      % sensor B -> ambient (difference mode)
    conn(s, q.RConn(end), ph(b_co, 'LConn', 1));
    add_line(s, sprintf('PS_to_Simulink_%s/1', names{k}), [outn{k} '/1']);
end
b_sol2 = addb(L.solv, [s '/Solver_Configuration_Thermal'], [190 640 250 680]);
conn(s, ph(b_sol2, 'RConn', 1), ph(b_ref, 'LConn', 1));
note(s, ['SS6 THERMAL NETWORK. Three first-order thermal R-C circuits. Oil: C_th_oil, R_th_oil to ambient; top-oil time constant R*C = k11*tau_o. ' ...
    'HS1, HS2: analogue circuits whose node temperatures equal the hot-spot rise components dTheta_h1, dTheta_h2 above ambient ' ...
    '(R*C = k22*tau_w and tau_o/k22). This is a separate physical network and needs its own Solver Configuration.'], [20 730]);
note(s, ['Circuit pattern (Oil, HS1, HS2): Q [W] -> Simulink-PS Converter -> Controlled Heat Flow Rate Source -> Thermal Mass (C, initial temperature = ambient) ' ...
    '-> Thermal Resistance R -> Ambient. The Thermal Mass "mass" is the heat capacity in J/K because cp_unit = 1 J/(kg*K).'], [20 780]);
note(s, ['Sensors: Oil = absolute temperature, converted to degC with the affine offset. HS1 and HS2 = difference to ambient, in kelvin (rise components). ' ...
    'Thermal_Reference and Ambient_Temperature are shared, so the three circuits form ONE network with ONE Solver Configuration.'], [20 830]);

%% B10. SS7_Outputs_and_Ageing -------------------------------------------------------------------------
s = [mdl '/SS7_Outputs_and_Ageing'];
inn = {'K_pu', 'theta_oil_C', 'dTheta_h1', 'dTheta_h2'};
for k = 1:4, addb('simulink/Sources/In1', [s '/' inn{k}], [20 35+(k-1)*70 50 55+(k-1)*70]); end
addb('simulink/Math Operations/Sum', [s '/Hot_Spot_Sum'], [180 160 210 230], 'Inputs', '++-');
add_line(s, 'theta_oil_C/1', 'Hot_Spot_Sum/1', 'autorouting', 'smart');
add_line(s, 'dTheta_h1/1', 'Hot_Spot_Sum/2', 'autorouting', 'smart');
add_line(s, 'dTheta_h2/1', 'Hot_Spot_Sum/3', 'autorouting', 'smart');
addb('simulink/Math Operations/Bias', [s '/Minus_Reference'], [250 300 290 330], 'Bias', '-theta_ref_age');
addb('simulink/Math Operations/Gain', [s '/Ageing_Gain'], [320 300 360 330], 'Gain', 'log(2)/dT_double_age');
addb('simulink/Math Operations/Math Function', [s '/Exp'], [390 300 430 330], 'Operator', 'exp', 'ShowName', 'on', 'HideAutomaticName', 'off');   % name shown (Step 34, check jc_0061)
add_line(s, 'Hot_Spot_Sum/1', 'Minus_Reference/1', 'autorouting', 'smart');
add_line(s, 'Minus_Reference/1', 'Ageing_Gain/1');
add_line(s, 'Ageing_Gain/1', 'Exp/1');
tw = {'K_pu', 'K_pu/1'; 'theta_oil_C', 'theta_oil_C/1'; 'theta_hs_C', 'Hot_Spot_Sum/1'; 'ageing_rate_V', 'Exp/1'};
for k = 1:size(tw, 1)
    addb('simulink/Sinks/To Workspace', [s '/Log_' tw{k, 1}], [500 30+k*60 580 60+k*60], ...
        'VariableName', tw{k, 1}, 'SaveFormat', 'Timeseries');
    add_line(s, tw{k, 2}, ['Log_' tw{k, 1} '/1'], 'autorouting', 'smart');
end
note(s, ['SS7 OUTPUTS AND AGEING. Hot-spot temperature theta_hs = theta_oil + dTheta_h1 - dTheta_h2; relative ageing rate ' ...
    'V = 2^((theta_hs - theta_ref_age)/dT_double_age). Logged to the workspace: K_pu, theta_oil_C, theta_hs_C, ageing_rate_V.'], [20 420]);
note(s, ['V is computed as exp(log(2)*(theta_hs - theta_ref_age)/dT_double_age), identical to 2^(...) but with the Exp block. V = 1 at theta_ref_age ' ...
    '(98 degC, normal Kraft paper); each dT_double_age kelvin doubles the ageing rate. The loss of life is the integral of V (run_transformer_simulation.m).'], [20 470]);


%% Step 37. SS8_Sampling_Events (decision D35) ------------------------------------------------------------
% Only a clock, the sampling times and comparison / counting / logic blocks. No gas value exists in this subsystem or in the model:
% record_index is the number of sampling times passed = row number of the next held-out record in heldout_record_ids (params_transformer.m).
s = [mdl '/SS8_Sampling_Events'];
addb('simulink/Sources/Clock', [s '/Time'], [20 60 50 90]);
addb('simulink/Sources/Constant', [s '/Sample_Times'], [20 140 100 170], 'Value', 't_sample_s');
addb('simulink/Logic and Bit Operations/Relational Operator', [s '/Time_Passed'], [150 60 190 100], 'Operator', '>=');
addb('simulink/Signal Attributes/Data Type Conversion', [s '/To_Double'], [220 60 270 100], 'OutDataTypeStr', 'double');
addb('simulink/Math Operations/Sum of Elements', [s '/Record_Index_Sum'], [310 60 350 100]);
addb('simulink/Math Operations/Product', [s '/Pick_Times'], [310 150 350 190], 'Inputs', '**');
addb('simulink/Math Operations/MinMax', [s '/Last_Sample_Time'], [380 150 420 190], 'Function', 'max');
addb('simulink/Math Operations/Sum', [s '/Time_Since_Sample'], [450 150 480 190], 'Inputs', '+-');
addb('simulink/Logic and Bit Operations/Compare To Constant', [s '/Within_Pulse'], [510 150 570 190], 'relop', '<', 'const', 't_event_s');
addb('simulink/Signal Attributes/Data Type Conversion', [s '/Index_to_Boolean'], [380 60 430 100], 'OutDataTypeStr', 'boolean');
addb('simulink/Logic and Bit Operations/Logical Operator', [s '/Event_AND'], [610 100 650 150], 'Operator', 'AND', 'Inputs', '2');
addb('simulink/Sinks/To Workspace', [s '/Log_record_index'], [460 40 540 70], 'VariableName', 'record_index', 'SaveFormat', 'Timeseries');
addb('simulink/Sinks/To Workspace', [s '/Log_sampling_event'], [690 100 770 130], 'VariableName', 'sampling_event', 'SaveFormat', 'Timeseries');
add_line(s, 'Time/1', 'Time_Passed/1', 'autorouting', 'smart');
add_line(s, 'Sample_Times/1', 'Time_Passed/2', 'autorouting', 'smart');
add_line(s, 'Time_Passed/1', 'To_Double/1', 'autorouting', 'smart');
add_line(s, 'To_Double/1', 'Record_Index_Sum/1', 'autorouting', 'smart');
add_line(s, 'To_Double/1', 'Pick_Times/1', 'autorouting', 'smart');
add_line(s, 'Sample_Times/1', 'Pick_Times/2', 'autorouting', 'smart');
add_line(s, 'Pick_Times/1', 'Last_Sample_Time/1', 'autorouting', 'smart');
add_line(s, 'Time/1', 'Time_Since_Sample/1', 'autorouting', 'smart');
add_line(s, 'Last_Sample_Time/1', 'Time_Since_Sample/2', 'autorouting', 'smart');
add_line(s, 'Time_Since_Sample/1', 'Within_Pulse/1', 'autorouting', 'smart');
add_line(s, 'Record_Index_Sum/1', 'Index_to_Boolean/1', 'autorouting', 'smart');
add_line(s, 'Record_Index_Sum/1', 'Log_record_index/1', 'autorouting', 'smart');
add_line(s, 'Within_Pulse/1', 'Event_AND/1', 'autorouting', 'smart');
add_line(s, 'Index_to_Boolean/1', 'Event_AND/2', 'autorouting', 'smart');
add_line(s, 'Event_AND/1', 'Log_sampling_event/1', 'autorouting', 'smart');
note(s, ['SS8 SAMPLING EVENTS (decision D35). No inputs, no connection to SS1-SS7. Outputs (logged to the workspace): record_index = number of sampling times ' ...
    't_sample_s already passed (0 before the first); sampling_event = 1 during t_event_s after each sampling time. Parameters: t_sample_s, t_event_s. ' ...
    'NEVER a gas value: record_index is the row number of the next held-out record in heldout_record_ids; the record_id and the gases are looked up outside the model.'], [20 250]);
note(s, ['How it works: Time_Passed compares the clock with every sampling time (vector of 1 and 0); the sum of these is record_index. Pick_Times keeps the sampling times already ' ...
    'passed, Last_Sample_Time takes the largest one, Time_Since_Sample = clock - last sampling time; the event is true while that is below t_event_s and record_index is not 0.'], [20 310]);
%% B11. Top-level connections --------------------------------------------------------------------------
T = @(n) [mdl '/' n];
conn(mdl, ph(T('SS1_Grid_Supply'), 'RConn', 1), ph(T('SS2_Power_Transformer'), 'LConn', 1));
conn(mdl, ph(T('SS2_Power_Transformer'), 'RConn', 1), ph(T('SS3_LV_Measurement'), 'LConn', 1));
conn(mdl, ph(T('SS3_LV_Measurement'), 'RConn', 1), ph(T('SS4_Variable_Load'), 'LConn', 1));
add_line(mdl, 'SS3_LV_Measurement/1', 'SS5_Losses_to_Heat/1', 'autorouting', 'smart');
add_line(mdl, 'SS3_LV_Measurement/1', 'SS7_Outputs_and_Ageing/1', 'autorouting', 'smart');
for k = 1:3
    add_line(mdl, sprintf('SS5_Losses_to_Heat/%d', k), sprintf('SS6_Thermal_Network/%d', k), 'autorouting', 'smart');
    add_line(mdl, sprintf('SS6_Thermal_Network/%d', k), sprintf('SS7_Outputs_and_Ageing/%d', k+1), 'autorouting', 'smart');
end
note(mdl, ['TRANSFORMER OPERATING MODEL (operating context only - no gas values are generated). Electrical network: SS1 -> SS2 -> SS3 -> SS4. ' ...
    'Thermal chain: SS3 (K) -> SS5 -> SS6 -> SS7. SS8 = DGA sampling events (clock only, not connected). All parameters are defined in params_transformer.m (run by the InitFcn callback).'], [40 30]);
note(mdl, ['Colour code: blue = Simscape Electrical network (SS1-SS4); green = Simulink arithmetic (SS5 losses, SS7 outputs); orange = Simscape thermal network (SS6); purple = sampling events (SS8). ' ...
    'Blue lines = physical connections; black lines = Simulink signals. Gas values never appear in this model (decision D4).'], [40 440]);
save_system(mdl, file);
T = cell2table(STEP33_LOG, 'VariableNames', {'block', 'parameter', 'value'});
if ~isfolder(fullfile(here, 'results')), mkdir(fullfile(here, 'results')); end
writetable(T, fullfile(here, 'results', 'step33_block_settings.csv'));
fprintf('Built and saved %s\n', file);
end

%% ---------- helpers ----------------------------------------------------------------------------------
function b = addb(lib, dst, p, varargin)
% Add a block at position p and set its parameters (name/value pairs).
b = add_block(lib, dst, 'Position', p);
setp(b, varargin{:});
end

function setp(b, varargin)
% Set block parameters and log every setting (block, parameter, value) for the settings table and the literal check.
global STEP33_LOG
for i = 1:2:numel(varargin)
    set_param(b, varargin{i}, varargin{i+1});
    STEP33_LOG(end + 1, :) = {strrep(getfullname(b), [bdroot(b) '/'], ''), varargin{i}, varargin{i+1}}; %#ok<AGROW>
end
end

function h = ph(b, side, k)
% Port handle k of a block, side = 'LConn' or 'RConn' (physical) .
p = get_param(b, 'PortHandles'); h = p.(side)(k);
end

function conn(sys, h1, h2)
add_line(sys, h1, h2, 'autorouting', 'smart');
end

function h = cport(sys, name, side, p)
% Connection Port. Port numbers are unique across both sides of a subsystem, so the order of creation fixes the order.
n = numel(find_system(sys, 'SearchDepth', 1, 'BlockType', 'PMIOPort'));
b = add_block('nesl_utility/Connection Port', [sys '/' name], 'Position', p, 'Side', side, 'Port', num2str(n + 1));
q = get_param(b, 'PortHandles');
h = [q.LConn q.RConn]; h = h(1);
end

function note(sys, txt, xy)
% Annotation (text note) on the canvas of sys.
a = Simulink.Annotation([sys '/note_placeholder']);
a.Text = txt;
a.Position = [xy xy + [600 40]];
a.FontSize = 11; a.BackgroundColor = 'lightBlue';
end

function delete_default_content(s)
% New subsystems come with In1 -> Out1; remove them (Guide B3.1).
l = find_system(s, 'FindAll', 'on', 'Type', 'line'); delete_line(l);
b = find_system(s, 'SearchDepth', 1, 'Type', 'block');
for i = 2:numel(b), delete_block(b{i}); end
end
