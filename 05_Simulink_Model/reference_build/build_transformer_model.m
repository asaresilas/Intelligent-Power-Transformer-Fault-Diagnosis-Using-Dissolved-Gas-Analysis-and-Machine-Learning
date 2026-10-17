function build_transformer_model(mdl, eqForm)
% Build the transformer operating model exactly as described in the guide,
% so that the written procedure is verified against MATLAB R2025b.
if nargin < 1, mdl = 'Transformer_Operating_Model'; end
if nargin < 2, eqForm = 'NE_FREQUENCY_TIME_EF'; end
load_system('fl_lib'); load_system('ee_lib'); load_system('nesl_utility');
if bdIsLoaded(mdl), close_system(mdl, 0); end
if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
new_system(mdl); open_system(mdl);
set_param(mdl, 'InitFcn', 'params_transformer;', 'PreLoadFcn', 'params_transformer;');
set_param(mdl, 'Solver', 'ode23t', 'StopTime', 't_stop', 'MaxStep', 't_step_max', ...
    'SaveOutput', 'on', 'ReturnWorkspaceOutputs', 'on');

L.vsrc  = 'ee_lib/Sources/Voltage Source (Three-Phase)';
L.xfmr  = 'ee_lib/Passive/Transformers/Two-Winding Transformer (Three-Phase)';
L.isens = 'ee_lib/Sensors & Transducers/Current Sensor (Three-Phase)';
L.load  = 'ee_lib/Passive/RLC Assemblies/Wye-Connected Variable Load';
L.eref  = 'ee_lib/Connectors & References/Electrical Reference';
L.solv  = 'nesl_utility/Solver Configuration';
L.s2ps  = 'nesl_utility/Simulink-PS Converter';
L.ps2s  = 'nesl_utility/PS-Simulink Converter';
L.cport = 'nesl_utility/Connection Port';
L.dot   = 'fl_lib/Physical Signals/Functions/PS Dot Product';
L.gain  = 'fl_lib/Physical Signals/Functions/PS Gain';
L.bias  = 'fl_lib/Physical Signals/Functions/PS Bias';
L.math  = 'fl_lib/Physical Signals/Functions/PS Math Function';
L.mass  = 'fl_lib/Thermal/Thermal Elements/Thermal Mass';
L.tres  = 'fl_lib/Thermal/Thermal Elements/Thermal Resistance';
L.tref  = 'fl_lib/Thermal/Thermal Elements/Thermal Reference';
L.chf   = 'fl_lib/Thermal/Thermal Sources/Controlled Heat Flow Rate Source';
L.tsrc  = 'fl_lib/Thermal/Thermal Sources/Temperature Source';
L.tsens = 'fl_lib/Thermal/Thermal Sensors/Temperature Sensor';

%% Top-level subsystems
ss = {'SS1_Grid_Supply', 'SS2_Power_Transformer', 'SS3_LV_Measurement', 'SS4_Variable_Load', ...
      'SS5_Losses_to_Heat', 'SS6_Thermal_Network', 'SS7_Outputs_and_Ageing'};
pos = [40 100; 220 100; 400 100; 580 100; 400 300; 580 300; 760 300];
for k = 1:numel(ss)
    add_block('built-in/Subsystem', [mdl '/' ss{k}], 'Position', [pos(k,:) pos(k,:)+[120 90]]);
    delete_line_all([mdl '/' ss{k}]);
end

%% SS1 Grid supply
s = [mdl '/SS1_Grid_Supply'];
b_src = addb(L.vsrc, [s '/Grid_Source'], [60 60 140 120], ...
    'vline_rms', 'V_HV', 'vline_rms_unit', 'V', 'freq', 'f_rated', 'freq_unit', 'Hz', 'shift', 'phase_shift_deg', 'shift_unit', 'deg');
setImpedanceNone(b_src);
b_ref = addb(L.eref, [s '/Ground'], [70 180 110 220]);
b_sol = addb(L.solv, [s '/Solver_Configuration'], [160 170 220 210]);
setp(b_sol, 'EquationFormulation', eqForm);
p_hv = cport(s, 'HV_out', 'Right', 1, [320 80 350 100]);
conn(s, ph(b_src, 'LConn', 1), ph(b_ref, 'LConn', 1));        % n -> ground
conn(s, ph(b_sol, 'RConn', 1), ph(b_ref, 'LConn', 1));        % solver -> ground node
conn(s, ph(b_src, 'RConn', 1), p_hv);                         % ~ -> HV_out
note(s, ['SS1 GRID SUPPLY. Ideal three-phase source (infinite bus) at V_HV, f_rated. ' ...
    'Output: HV_out (three-phase, composite). Parameters: V_HV, f_rated (params_transformer.m). ' ...
    'Solver Configuration sets the equation formulation for the whole network.'], [20 250]);

%% SS2 Power transformer
s = [mdl '/SS2_Power_Transformer'];
p_in  = cport(s, 'HV_in', 'Left', 1, [20 80 50 100]);
b_tx  = addb(L.xfmr, [s '/Two_Winding_Transformer'], [140 60 240 120], ...
    'SRated', 'S_rated', 'SRated_unit', 'V*A', 'FRated', 'f_rated', 'FRated_unit', 'Hz', ...
    'VRated1', 'V_HV', 'VRated1_unit', 'V', 'VRated2', 'V_LV', 'VRated2_unit', 'V', ...
    'Winding1Connection', 'ee.enum.windingconnection.delta1', ...
    'Winding2Connection', 'ee.enum.windingconnection.Yg', ...
    'pu_Rw1', 'Rw1_pu', 'pu_Rw2', 'Rw2_pu', ...
    'leakage_reactance_option', 'ee.enum.transformer_leakage.include', 'pu_Xl1', 'Xl1_pu', 'pu_Xl2', 'Xl2_pu', ...
    'magnetizing_resistance_option', 'ee.enum.transformer_magnetizingResistance.include', 'pu_Rm', 'Rm_pu', ...
    'magnetizing_reactance_option', 'ee.enum.transformer_magnetizingReactance.include', 'pu_Xm', 'Xm_pu');
p_out = cport(s, 'LV_out', 'Right', 1, [330 80 360 100]);
conn(s, p_in, ph(b_tx, 'LConn', 1));
conn(s, ph(b_tx, 'RConn', 1), p_out);
note(s, ['SS2 POWER TRANSFORMER. Two-winding three-phase transformer, Delta (HV) / grounded Wye (LV). ' ...
    'Input: HV_in. Output: LV_out. Parameters: S_rated, V_HV, V_LV, Rw1_pu, Rw2_pu, Xl1_pu, Xl2_pu, Rm_pu, Xm_pu.'], [20 160]);

%% SS3 LV measurement  (Simscape sensor; arithmetic in Simulink so the
%  electrical network stays linear for the frequency-and-time solver)
s = [mdl '/SS3_LV_Measurement'];
p_in  = cport(s, 'LV_in', 'Left', 1, [20 80 50 100]);
b_is  = addb(L.isens, [s '/Current_Sensor_3ph'], [120 60 200 120]);
p_out = cport(s, 'LV_out', 'Right', 1, [520 60 550 80]);
b_cv  = addb(L.ps2s, [s '/PS_to_Simulink_I'], [140 180 170 200], 'Unit', 'A');
addb('simulink/Math Operations/Dot Product', [s '/Sum_of_Squares'], [210 175 250 215]);
addb('simulink/Math Operations/Gain', [s '/Divide_by_3'], [280 180 320 210], 'Gain', '1/3');
addb('simulink/Math Operations/Math Function', [s '/Square_Root'], [350 180 390 210], 'Operator', 'sqrt');
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
note(s, ['SS3 LV MEASUREMENT. Current Sensor (Three-Phase) measures ia, ib, ic on the LV side. ' ...
    'K = sqrt((ia^2+ib^2+ic^2)/3)/I_LV_rated is the load factor (exact RMS for a balanced set). ' ...
    'Input: LV_in. Outputs: LV_out (pass-through), K_pu (Simulink signal, per unit). Parameter: I_LV_rated.'], [20 260]);

%% SS4 Variable load
s = [mdl '/SS4_Variable_Load'];
p_in  = cport(s, 'LV_in', 'Left', 1, [20 80 50 100]);
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
note(s, ['SS4 VARIABLE LOAD. Resistive three-phase load whose real power follows the load profile: ' ...
    'P = K(t)*S_rated (unity power factor, assumption). Input: LV_in. Parameters: load_profile, S_rated, V_LV, P_load_min.'], [20 260]);

%% SS5 Losses to heat (Simulink arithmetic)
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
note(s, ['SS5 LOSSES TO HEAT. Total loss P0 + Pk*K^2; equivalent oil heat input ' ...
    'Q_oil = P_tot_r*((P0+Pk*K^2)/P_tot_r)^x; hot-spot drives Q_h1 = k21*dTheta_hr*K^y/R_th_h and ' ...
    'Q_h2 = (k21-1)*dTheta_hr*K^y/R_th_h (IEC 60076-7 differential-equation model). Outputs in W.'], [20 270]);

%% SS6 Thermal network (separate physical network, own Solver Configuration)
s = [mdl '/SS6_Thermal_Network'];
names = {'Oil', 'HS1', 'HS2'}; caps = {'C_th_oil', 'C_th_h1', 'C_th_h2'};
ress = {'R_th_oil', 'R_th_h', 'R_th_h'}; T0 = {'theta_amb_C + 273.15', 'theta_amb_C + 273.15', 'theta_amb_C + 273.15'};
inn = {'Q_oil', 'Q_h1', 'Q_h2'}; outn = {'theta_oil_C', 'dTheta_h1', 'dTheta_h2'};
outu = {'degC', 'K', 'K'};
% One common Thermal Reference joins the three circuits into ONE physical network
b_ref = addb(L.tref, [s '/Thermal_Reference'], [130 500 170 530]);
% One ambient temperature source shared by all three circuits
b_amb = addb(L.tsrc, [s '/Ambient_Temperature'], [380 500 420 540], ...
    'temperature', 'theta_amb_C + 273.15', 'temperature_unit', 'K');
for k = 1:3
    y0 = 40 + (k-1)*150;
    addb('simulink/Sources/In1', sprintf('%s/%s', s, inn{k}), [20 y0+5 50 y0+25]);
    b_cs  = addb(L.s2ps, sprintf('%s/Heat_to_PS_%s', s, names{k}), [70 y0 100 y0+30], 'Unit', 'W');
    b_src = addb(L.chf, sprintf('%s/Heat_Source_%s', s, names{k}), [130 y0 170 y0+40]);
    b_rA  = b_ref;
    b_m   = addb(L.mass, sprintf('%s/Thermal_Mass_%s', s, names{k}), [220 y0-20 260 y0+10], ...
        'mass', caps{k}, 'mass_unit', 'kg', 'sp_heat', 'cp_unit', 'sp_heat_unit', 'J/(kg*K)', ...
        'T_specify', 'on', 'T_priority', 'High', 'T', T0{k}, 'T_unit', 'K');
    b_r   = addb(L.tres, sprintf('%s/Thermal_Resistance_%s', s, names{k}), [300 y0 340 y0+30], ...
        'resistance', ress{k}, 'resistance_unit', 'K/W');
    b_end = b_amb;
    if k == 1, meas = 'absolute'; else, meas = 'difference'; end
    b_ts  = addb(L.tsens, sprintf('%s/Temperature_Sensor_%s', s, names{k}), [300 y0+60 340 y0+90], ...
        'temperature_measure', ['foundation.enum.MeasurementReference.' meas]);
    b_co  = addb(L.ps2s, sprintf('%s/PS_to_Simulink_%s', s, names{k}), [380 y0+65 410 y0+85], 'Unit', outu{k});
    if k == 1, setp(b_co, 'AffineConversion', 'on'); end
    addb('simulink/Sinks/Out1', sprintf('%s/%s', s, outn{k}), [460 y0+65 490 y0+85]);
    add_line(s, [inn{k} '/1'], sprintf('Heat_to_PS_%s/1', names{k}));
    conn(s, ph(b_cs, 'RConn', 1), ph(b_src, 'RConn', 1));     % PS -> S
    conn(s, ph(b_src, 'RConn', 2), ph(b_rA, 'LConn', 1));     % A -> reference
    conn(s, ph(b_src, 'LConn', 1), ph(b_m, 'LConn', 1));      % B -> mass node
    conn(s, ph(b_m, 'LConn', 1), ph(b_r, 'LConn', 1));
    conn(s, ph(b_r, 'RConn', 1), ph(b_end, 'LConn', 1));
    conn(s, ph(b_m, 'LConn', 1), ph(b_ts, 'LConn', 1));
    q = get_param(b_ts, 'PortHandles');
    if k > 1, conn(s, q.RConn(1), ph(b_amb, 'LConn', 1)); end   % B -> ambient (difference mode)
    conn(s, q.RConn(end), ph(b_co, 'LConn', 1));
    add_line(s, sprintf('PS_to_Simulink_%s/1', names{k}), [outn{k} '/1']);
end
b_sol2 = addb(L.solv, [s '/Solver_Configuration_Thermal'], [200 500 260 540]);
conn(s, ph(b_sol2, 'RConn', 1), ph(b_ref, 'LConn', 1));
note(s, ['SS6 THERMAL NETWORK. Three first-order thermal R-C circuits. Oil: C_th_oil, R_th_oil to ambient; ' ...
    'top-oil time constant R*C = k11*tau_o. HS1, HS2: analogue circuits whose node temperatures equal the ' ...
    'hot-spot rise components dTheta_h1, dTheta_h2 above ambient (R*C = k22*tau_w and tau_o/k22). ' ...
    'This is a separate physical network and needs its own Solver Configuration.'], [20 600]);

%% SS7 Outputs and ageing (Simulink)
s = [mdl '/SS7_Outputs_and_Ageing'];
inn = {'K_pu', 'theta_oil_C', 'dTheta_h1', 'dTheta_h2'};
for k = 1:4, addb('simulink/Sources/In1', [s '/' inn{k}], [20 35+(k-1)*70 50 55+(k-1)*70]); end
addb('simulink/Math Operations/Sum', [s '/Hot_Spot_Sum'], [180 160 210 230], 'Inputs', '++-');
add_line(s, 'theta_oil_C/1', 'Hot_Spot_Sum/1', 'autorouting', 'smart');
add_line(s, 'dTheta_h1/1', 'Hot_Spot_Sum/2', 'autorouting', 'smart');
add_line(s, 'dTheta_h2/1', 'Hot_Spot_Sum/3', 'autorouting', 'smart');
addb('simulink/Math Operations/Bias', [s '/Minus_Reference'], [250 300 290 330], 'Bias', '-theta_ref_age');
addb('simulink/Math Operations/Gain', [s '/Ageing_Gain'], [320 300 360 330], 'Gain', 'log(2)/dT_double_age');
addb('simulink/Math Operations/Math Function', [s '/Exp'], [390 300 430 330], 'Operator', 'exp');
add_line(s, 'Hot_Spot_Sum/1', 'Minus_Reference/1', 'autorouting', 'smart');
add_line(s, 'Minus_Reference/1', 'Ageing_Gain/1');
add_line(s, 'Ageing_Gain/1', 'Exp/1');
tw = {'K_pu', 'K_pu/1'; 'theta_oil_C', 'theta_oil_C/1'; 'theta_hs_C', 'Hot_Spot_Sum/1'; 'ageing_rate_V', 'Exp/1'};
for k = 1:size(tw, 1)
    addb('simulink/Sinks/To Workspace', [s '/Log_' tw{k, 1}], [500 30+k*60 580 60+k*60], ...
        'VariableName', tw{k, 1}, 'SaveFormat', 'Timeseries');
    add_line(s, tw{k, 2}, ['Log_' tw{k, 1} '/1'], 'autorouting', 'smart');
end
note(s, ['SS7 OUTPUTS AND AGEING. Hot-spot temperature theta_hs = theta_oil + dTheta_h1 - dTheta_h2; ' ...
    'relative ageing rate V = 2^((theta_hs - theta_ref_age)/dT_double_age). ' ...
    'Logged to the workspace: K_pu, theta_oil_C, theta_hs_C, ageing_rate_V.'], [20 420]);

%% Top-level connections
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
note(mdl, ['TRANSFORMER OPERATING MODEL (operating context only - no gas values are generated). ' ...
    'Electrical network: SS1 -> SS2 -> SS3 -> SS4. Thermal chain: SS3 (K) -> SS5 -> SS6 -> SS7. ' ...
    'All parameters are defined in params_transformer.m (run by the InitFcn callback).'], [40 30]);
save_system(mdl);
end

%% ---------- helpers ----------
function b = addb(lib, dst, p, varargin)
    b = add_block(lib, dst, 'Position', p);
    if ~isempty(varargin), setp(b, varargin{:}); end
end
function setp(b, varargin)
    for i = 1:2:numel(varargin), set_param(b, varargin{i}, varargin{i+1}); end
end
function h = ph(b, side, k)
    p = get_param(b, 'PortHandles'); h = p.(side)(k);
end
function conn(sys, h1, h2)
    add_line(sys, h1, h2, 'autorouting', 'smart');
end
function h = cport(sys, name, side, num, p)
    % Port numbers are unique across both sides of a subsystem; the order of
    % creation therefore fixes the order of ports on each side.
    n = numel(find_system(sys, 'SearchDepth', 1, 'BlockType', 'PMIOPort'));
    b = add_block('nesl_utility/Connection Port', [sys '/' name], 'Position', p, 'Side', side, 'Port', num2str(n + 1)); %#ok<NASGU>
    q = get_param(b, 'PortHandles');
    h = [q.LConn q.RConn]; h = h(1);
end
function note(sys, txt, xy)
    a = Simulink.Annotation([sys '/note_placeholder']);
    a.Text = txt;
    a.Position = [xy xy + [600 40]];
    a.FontSize = 11; a.BackgroundColor = 'lightBlue';
end
function delete_line_all(s)
    l = find_system(s, 'FindAll', 'on', 'Type', 'line'); delete_line(l);
    b = find_system(s, 'SearchDepth', 1, 'Type', 'block');
    for i = 2:numel(b), delete_block(b{i}); end
end
function setImpedanceNone(b)
    % Value 0 = 'None' (ideal source), confirmed by probing the block mask in R2025b.
    set_param(b, 'impedance_option', '0');
end
