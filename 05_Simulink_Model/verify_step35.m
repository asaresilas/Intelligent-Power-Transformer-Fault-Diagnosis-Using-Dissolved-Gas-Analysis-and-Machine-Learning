function [chk, T410] = verify_step35()
%VERIFY_STEP35  Roadmap Step 35: verify Transformer_Operating_Model.slx against the IEC 60076-7 equations (decision D33).
%
%   [chk, T410] = verify_step35()
%
%   TESTS (24 h each, ambient from params_transformer.m)
%     Test 1  rated demand (load_profile of params_transformer.m) from a cold start (all temperatures = ambient).
%     Test 2  load demand 0.6 pu, stepping to 1.2 pu after 6 h (1 s ramp).
%   REFERENCES (independent of the Simscape model)
%     A  the IEC 60076-7 differential equations (oil: k11*tau_o, hot-spot components: k22*tau_w and tau_o/k22), solved with
%        ode15s (RelTol/AbsTol 1e-8, MaxStep 30 s), driven by the load factor K(t) that the model measured in SS3.
%     B  (Test 1 only) closed-form solution of the same equations for constant K (no ODE solver involved).
%   MEASURES (Analysis Plan Eq. 45, 46) over the time points after 10 min:  e_max = max|model - reference|, RMSE.
%   PASS RULE  e_max <= 0.1 K (top-oil and hot-spot, both tests); top-oil 63 % rise time within 1 min of k11*tau_o;
%              further checks listed in D33 (clause 6).
%   The reference is driven by the model's own K: this verifies the thermal and ageing chain, not the electrical network.
%
%   OUTPUT  results/step35_verification_log_<date>.txt, results/step35_checks.csv, results/step35_sdi_session.mldatx,
%           11_Results/tables/T4_10_simulink_verification.csv, 11_Results/figures/F4_18_simulink_verification.(png|pdf|csv)
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 35.   MATLAB R2025b.

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
mdl  = 'Transformer_Operating_Model';
day  = char(datetime('now', 'Format', 'yyyy-MM-dd'));
tolK = 0.1;                                         % K, approved tolerance (Analysis Plan Section 9)
tolRise_min = 1;                                    % min, D33 clause 5
tolRef_K = 0.001;                                   % K, D33 clause 6 (reference accuracy)
tolV = 2^(tolK / 6) - 1;                            % relative, ageing rate equivalent to 0.1 K (6 K doubles V)
tSkip = 600;                                        % s, compare after 10 min (as in the 3 October baseline)
warning('off', 'all');
bdclose all; addpath(here);
evalin('base', 'params_transformer;');
P = struct();
for n = {'Pk', 'P0', 'dTheta_or', 'dTheta_hr', 'x_oil', 'y_wdg', 'k11', 'k21', 'k22', 'tau_o_min', 'tau_w_min', ...
         'theta_amb_C', 't_stop', 'theta_ref_age', 'dT_double_age', 'K_load'}
    P.(n{1}) = evalin('base', n{1});
end
logFile = fullfile(here, 'results', ['step35_verification_log_' day '.txt']);
fid = fopen(logFile, 'w');  closeLog = onCleanup(@() fclose(fid));
lg = @(varargin) fprintf(fid, varargin{:});
lg('Step 35 verification of %s against IEC 60076-7 equations, %s, MATLAB %s\n', mdl, day, version);
lg('Tolerance %.2f K; compared after %d s; D33.\n\n', tolK, tSkip);

load_system(fullfile(here, [mdl '.slx']));
%% simulations ---------------------------------------------------------------------------------------------------
in1 = Simulink.SimulationInput(mdl);                % Test 1: the load profile of params_transformer.m (rated demand)
o1 = sim(in1);
tStep = 6 * 3600;
lp2 = timeseries([0.6; 0.6; 1.2; 1.2], [0; tStep; tStep + 1; P.t_stop]);
in2 = Simulink.SimulationInput(mdl);                % Test 2: load step
in2 = in2.setVariable('load_profile', lp2);
o2 = sim(in2);
tests = {o1, o2};  names = {'Test 1 rated load', 'Test 2 load step'};

%% references and measures ----------------------------------------------------------------------------------------
% PRIMARY measure (D33 amendment): the references are evaluated at the model's own logged time points, so the comparison needs no
% interpolation of the model. LEGACY measure (D33 as first written): the model is interpolated linearly onto the points of the
% reference solver; it contains the interpolation error of the coarse logged grid and is reported as information.
R = P.Pk / P.P0;
odeOpt = odeset('RelTol', 1e-8, 'AbsTol', 1e-8, 'MaxStep', 30);
res = cell(1, 2);  rows = {};                       % rows of Table 4.10
for q = 1:2
    o = tests{q};
    K = squeeze(o.K_pu.Data);  tK = o.K_pu.Time;
    Kf = @(t) interp1(tK, K, t, 'linear', 'extrap');
    f = @(t, z) [ (P.dTheta_or * ((1 + Kf(t)^2 * R) / (1 + R))^P.x_oil - z(1)) / (P.k11 * P.tau_o_min * 60);
                  (P.k21 * P.dTheta_hr * Kf(t)^P.y_wdg - z(2)) / (P.k22 * P.tau_w_min * 60);
                  ((P.k21 - 1) * P.dTheta_hr * Kf(t)^P.y_wdg - z(3)) / (P.tau_o_min * 60 / P.k22) ];
    % reference on its own fine grid (used for the plot and for the legacy measure)
    [tr, zr] = ode15s(f, [0 P.t_stop], [0 0 0], odeOpt);
    oilR = P.theta_amb_C + zr(:, 1);  hsR = oilR + zr(:, 2) - zr(:, 3);
    % model signals at their logged time points (duplicate times removed)
    [tm, iu] = unique(o.theta_oil_C.Time);
    oilMm = squeeze(o.theta_oil_C.Data);  oilMm = oilMm(iu);
    hsMm  = squeeze(o.theta_hs_C.Data);   hsMm  = hsMm(iu);
    VMm   = squeeze(o.ageing_rate_V.Data);  VMm = VMm(iu);
    [~, zm] = ode15s(f, tm, [0 0 0], odeOpt);       % reference evaluated AT the model's points
    oilRm = P.theta_amb_C + zm(:, 1);  hsRm = oilRm + zm(:, 2) - zm(:, 3);
    selm = tm > tSkip;
    eOm = oilMm - oilRm;  eHm = hsMm - hsRm;
    s = struct('t', tr, 'oilR', oilR, 'hsR', hsR, 'tm', tm, 'oilMm', oilMm, 'hsMm', hsMm, 'oilRm', oilRm, 'hsRm', hsRm, 'eO', eOm, 'eH', eHm);
    s.emaxO = max(abs(eOm(selm)));  s.emaxH = max(abs(eHm(selm)));
    s.rmseO = sqrt(mean(eOm(selm).^2));  s.rmseH = sqrt(mean(eHm(selm).^2));
    s.emaxO_all = max(abs(eOm));  s.emaxH_all = max(abs(eHm));
    s.finalO = oilMm(end);  s.finalH = hsMm(end);  s.peakH = max(hsMm);
    s.refFinalO = oilRm(end);  s.refFinalH = hsRm(end);
    s.M = nnz(selm);
    % legacy measure and the interpolation error of the logged grid itself (information)
    sel = tr > tSkip;
    oilMi = interp1(tm, oilMm, tr);  hsMi = interp1(tm, hsMm, tr);
    s.legO = max(abs(oilMi(sel) - oilR(sel)));  s.legH = max(abs(hsMi(sel) - hsR(sel)));
    oilRi = interp1(tm, oilRm, tr);  hsRi = interp1(tm, hsRm, tr);          % exact reference, interpolated between the model's points
    s.gridO = max(abs(oilRi(sel) - oilR(sel)));  s.gridH = max(abs(hsRi(sel) - hsR(sel)));
    % ageing rate: model V against the formula applied to the reference hot-spot temperature
    VR = 2.^((hsRm - P.theta_ref_age) / P.dT_double_age);
    s.dV = max(abs(VMm(selm) ./ VR(selm) - 1));
    s.Kbefore = Kf(tStep - 60);  s.Kafter = Kf(P.t_stop);
    % start-up transient (information): when is the whole-run maximum, and when does |difference| last exceed the tolerance
    [~, iO] = max(abs(eOm));  [~, iH] = max(abs(eHm));
    lastO = tm(find(abs(eOm) > tolK, 1, 'last'));  lastH = tm(find(abs(eHm) > tolK, 1, 'last'));
    s.tmaxO = tm(iO);  s.tmaxH = tm(iH);  s.lastExO = ifelse(isempty(lastO), NaN, lastO);  s.lastExH = ifelse(isempty(lastH), NaN, lastH);
    res{q} = s;
    lg('%s: K(24 h) = %.4f; M = %d logged model points after 10 min (of %d)\n', names{q}, K(end), s.M, numel(tm));
    lg('  top-oil : e_max %.4f K (whole run %.4f), RMSE %.4f K, final model %.3f / reference %.3f degC\n', s.emaxO, s.emaxO_all, s.rmseO, s.finalO, s.refFinalO);
    lg('  hot-spot: e_max %.4f K (whole run %.4f), RMSE %.4f K, final model %.3f / reference %.3f degC, peak %.3f degC\n', s.emaxH, s.emaxH_all, s.rmseH, s.finalH, s.refFinalH, s.peakH);
    lg('  legacy measure (model interpolated onto reference points): oil %.4f K, hot-spot %.4f K; interpolation error of the logged grid itself: oil %.4f K, hot-spot %.4f K\n', s.legO, s.legH, s.gridO, s.gridH);
    lg('  start-up: whole-run maximum at %.0f s (oil) and %.0f s (hot-spot); last time above %.2f K: oil %.0f s, hot-spot %.0f s (NaN = never)\n', ...
        s.tmaxO, s.tmaxH, tolK, s.lastExO, s.lastExH);
    lg('  ageing rate V: largest relative difference to the formula on the reference hot-spot %.5f (limit %.5f)\n', s.dV, tolV);
    rows(end + 1:end + 12, :) = { ...
        names{q}, 'top-oil temperature', 'e_max (after 10 min)', s.emaxO, 'K', tolK; ...
        names{q}, 'hot-spot temperature', 'e_max (after 10 min)', s.emaxH, 'K', tolK; ...
        names{q}, 'top-oil temperature', 'RMSE (after 10 min)', s.rmseO, 'K', NaN; ...
        names{q}, 'hot-spot temperature', 'RMSE (after 10 min)', s.rmseH, 'K', NaN; ...
        names{q}, 'top-oil temperature', 'final value, model', s.finalO, 'degC', NaN; ...
        names{q}, 'hot-spot temperature', 'final value, model', s.finalH, 'degC', NaN; ...
        names{q}, 'hot-spot temperature', 'peak value, model', s.peakH, 'degC', NaN; ...
        names{q}, 'ageing rate V', 'largest relative difference', s.dV, '-', tolV; ...
        names{q}, 'top-oil temperature', 'legacy measure (information)', s.legO, 'K', NaN; ...
        names{q}, 'hot-spot temperature', 'legacy measure (information)', s.legH, 'K', NaN; ...
        names{q}, 'top-oil temperature', 'interpolation error of the logged grid (information)', s.gridO, 'K', NaN; ...
        names{q}, 'hot-spot temperature', 'interpolation error of the logged grid (information)', s.gridH, 'K', NaN}; %#ok<AGROW>
end

%% closed form B for Test 1 (constant K) ----------------------------------------------------------------------------
s1 = res{1};  o = o1;
K1 = squeeze(o.K_pu.Data);  Kc = mean(K1(o.K_pu.Time > 3600));
dOss = P.dTheta_or * ((1 + Kc^2 * R) / (1 + R))^P.x_oil;                       % steady-state oil rise [K]
closed = @(tt) deal(P.theta_amb_C + dOss * (1 - exp(-tt / (P.k11 * P.tau_o_min * 60))), ...
    P.theta_amb_C + dOss * (1 - exp(-tt / (P.k11 * P.tau_o_min * 60))) + P.k21 * P.dTheta_hr * Kc^P.y_wdg * (1 - exp(-tt / (P.k22 * P.tau_w_min * 60))) ...
    - (P.k21 - 1) * P.dTheta_hr * Kc^P.y_wdg * (1 - exp(-tt / (P.tau_o_min * 60 / P.k22))));
[oilB, hsB] = closed(s1.t);                                                    % on the reference's fine grid (reference accuracy)
[oilBm, hsBm] = closed(s1.tm);                                                 % at the model's own points (model comparison)
selB = s1.t > tSkip;  selBm = s1.tm > tSkip;
dRefO = max(abs(s1.oilR(selB) - oilB(selB)));  dRefH = max(abs(s1.hsR(selB) - hsB(selB)));
eBO = max(abs(s1.oilMm(selBm) - oilBm(selBm)));    eBH = max(abs(s1.hsMm(selBm) - hsBm(selBm)));
lg('\nClosed form B (constant K = %.4f): model - B e_max oil %.4f K, hot-spot %.4f K; reference A - B oil %.5f K, hot-spot %.5f K\n', Kc, eBO, eBH, dRefO, dRefH);
rows(end + 1:end + 2, :) = { ...
    names{1}, 'top-oil temperature', 'e_max against closed form B', eBO, 'K', tolK; ...
    names{1}, 'hot-spot temperature', 'e_max against closed form B', eBH, 'K', tolK};
%% 63 % rise time of the top-oil temperature (Test 1) -----------------------------------------------------------------
fr = 1 - exp(-1);                                   % 0.6321
tM = o1.theta_oil_C.Time;  rise = squeeze(o1.theta_oil_C.Data) - P.theta_amb_C;
level = fr * dOss;                                  % analytic steady-state rise (independent of the 24 h end value)
i = find(rise >= level, 1);
t63 = interp1(rise(i-1:i), tM(i-1:i), level) / 60;  % min, linear interpolation inside the logged step
tExp = P.k11 * P.tau_o_min;
lg('Top-oil 63.2 %% rise time: model %.3f min, expected k11*tau_o = %.3f min (difference %.3f min)\n', t63, tExp, t63 - tExp);
rows(end + 1, :) = {names{1}, 'top-oil temperature', '63.2 % rise time (difference to k11 x tau_o)', t63 - tExp, 'min', tolRise_min};

%% baseline of 3 October (Analysis Plan Section 9.4) ---------------------------------------------------------------------
base = struct('K1', 0.9839, 'oil1', 78.638, 'hs1', 100.276, 'K2a', 0.5960, 'K2b', 1.1733);
lg('Baseline 3 Oct: Test 1 final oil %.3f / hs %.3f (now %.3f / %.3f); Test 2 K %.4f -> %.4f (now %.4f -> %.4f)\n', ...
    base.oil1, base.hs1, s1.finalO, s1.finalH, base.K2a, base.K2b, res{2}.Kbefore, res{2}.Kafter);

%% checks ----------------------------------------------------------------------------------------------------------------
chk = table('Size', [0 4], 'VariableTypes', {'string', 'double', 'double', 'logical'}, 'VariableNames', {'check', 'value', 'limit', 'passed'});
add = @(c, name, v, lim) [c; table(string(name), v, lim, v <= lim, 'VariableNames', {'check', 'value', 'limit', 'passed'})];
chk = add(chk, 'Test 1: top-oil e_max against reference A (K)', res{1}.emaxO, tolK);
chk = add(chk, 'Test 1: hot-spot e_max against reference A (K)', res{1}.emaxH, tolK);
chk = add(chk, 'Test 2: top-oil e_max against reference A (K)', res{2}.emaxO, tolK);
chk = add(chk, 'Test 2: hot-spot e_max against reference A (K)', res{2}.emaxH, tolK);
chk = add(chk, 'Test 1: top-oil e_max against closed form B (K)', eBO, tolK);
chk = add(chk, 'Test 1: hot-spot e_max against closed form B (K)', eBH, tolK);
chk = add(chk, 'reference A equals closed form B, top-oil (K)', dRefO, tolRef_K);
chk = add(chk, 'reference A equals closed form B, hot-spot (K)', dRefH, tolRef_K);
chk = add(chk, 'top-oil 63.2 % rise time equals k11*tau_o (difference, min)', abs(t63 - tExp), tolRise_min);
chk = add(chk, 'ageing rate V equals formula on reference hot-spot, Test 1 (relative)', res{1}.dV, tolV);
chk = add(chk, 'ageing rate V equals formula on reference hot-spot, Test 2 (relative)', res{2}.dV, tolV);
chk = add(chk, 'Test 1 final top-oil equals 3 Oct baseline (K)', abs(s1.finalO - base.oil1), tolK);
chk = add(chk, 'Test 1 final hot-spot equals 3 Oct baseline (K)', abs(s1.finalH - base.hs1), tolK);
chk = add(chk, 'Test 2 load factor before the step equals baseline (pu)', abs(res{2}.Kbefore - base.K2a), 5e-4);
chk = add(chk, 'Test 2 load factor after the step equals baseline (pu)', abs(res{2}.Kafter - base.K2b), 5e-4);
for k = 1:height(chk)
    lg('%s  %-75s value %.5g  limit %.5g\n', ifelse(chk.passed(k), 'PASS', 'FAIL'), chk.check(k), chk.value(k), chk.limit(k));
end
lg('\n%d of %d checks passed.\n', nnz(chk.passed), height(chk));
writetable(chk, fullfile(here, 'results', 'step35_checks.csv'));

%% Table 4.10 ---------------------------------------------------------------------------------------------------------------
T410 = cell2table(rows, 'VariableNames', {'test', 'quantity', 'measure', 'value', 'unit', 'limit'});
T410.passed = repmat("", height(T410), 1);
for k = 1:height(T410)
    if ~isnan(T410.limit(k)), T410.passed(k) = ifelse(abs(T410.value(k)) <= T410.limit(k), "yes", "NO"); end
end
tabDir = fullfile(root, '11_Results', 'tables');  figDir = fullfile(root, '11_Results', 'figures');
writetable(T410, fullfile(tabDir, 'T4_10_simulink_verification.csv'));

%% Figure 4.18 ----------------------------------------------------------------------------------------------------------------
sty = readtable(fullfile(figDir, 'plot_style.csv'), 'TextType', 'string');
hexRGB = @(item) sscanf(char(extractBetween(sty.colour_hex(sty.item == item), 2, 7)), '%2x').' / 255;
cOil = hexRGB("sequential_high");  cHs = hexRGB("diverging_negative");  cInk = hexRGB("text");  cMute = hexRGB("muted");  cGrid = hexRGB("grid");
fig = figure('Visible', 'off', 'Units', 'centimeters', 'Position', [2 2 18 12], 'Color', 'w');
try, theme(fig, 'light'); catch, end                 % MATLAB R2025a+ themes: force light so the axes are white
tl = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
for q = 1:2
    s = res{q};
    ax = nexttile(tl, q);  hold(ax, 'on');
    plot(ax, s.tm / 3600, s.oilMm, '-', 'Color', cOil, 'LineWidth', 1.6);
    plot(ax, s.tm / 3600, s.hsMm, '-', 'Color', cHs, 'LineWidth', 1.6);
    plot(ax, s.t / 3600, s.oilR, '--', 'Color', cInk, 'LineWidth', 1.0);
    plot(ax, s.t / 3600, s.hsR, '--', 'Color', cInk, 'LineWidth', 1.0);
    title(ax, names{q}, 'FontWeight', 'normal');  ylabel(ax, 'Temperature (\circC)');  xlim(ax, [0 24]);
    set(ax, 'XTickLabel', []);  style_axes(ax, cInk, cMute, cGrid);
    if q == 1, legend(ax, {'Top-oil, model', 'Hot-spot, model', 'IEC 60076-7 equations'}, 'Location', 'southeast', 'Box', 'off', 'FontSize', 8); end
    ax = nexttile(tl, 2 + q);  hold(ax, 'on');
    plot(ax, s.tm / 3600, s.eO, '-', 'Color', cOil, 'LineWidth', 1.2);
    plot(ax, s.tm / 3600, s.eH, '-', 'Color', cHs, 'LineWidth', 1.2);
    yline(ax, tolK, ':', 'Color', cMute);  yline(ax, -tolK, ':', 'Color', cMute);
    xlabel(ax, 'Time (h)');  ylabel(ax, 'Model - reference (K)');  xlim(ax, [0 24]);  ylim(ax, [-0.15 0.15]);
    style_axes(ax, cInk, cMute, cGrid);
    if q == 1, legend(ax, {'Top-oil', 'Hot-spot', 'Tolerance \pm0.1 K'}, 'Location', 'northeast', 'Box', 'off', 'FontSize', 8); end
end
base_ = fullfile(figDir, 'F4_18_simulink_verification');
exportgraphics(fig, [base_ '.png'], 'Resolution', 300);
exportgraphics(fig, [base_ '.pdf'], 'ContentType', 'vector');
close(fig);
D = table();                                         % plotted numbers (every 10th reference point)
for q = 1:2
    s = res{q};  ix = (1:10:numel(s.tm)).';       % every 10th model point; the reference is evaluated at the model's own points
    D = [D; table(repmat(string(names{q}), numel(ix), 1), s.tm(ix) / 3600, s.oilMm(ix), s.oilRm(ix), s.eO(ix), s.hsMm(ix), s.hsRm(ix), s.eH(ix), ...
        'VariableNames', {'test', 'time_h', 'oil_model_C', 'oil_reference_C', 'oil_diff_K', 'hs_model_C', 'hs_reference_C', 'hs_diff_K'})]; %#ok<AGROW>
end
writetable(D, [base_ '.csv']);

%% Simulation Data Inspector ----------------------------------------------------------------------------------------------------
sdiOK = true;
try
    Simulink.sdi.clear;
    for q = 1:2
        o = tests{q};
        Simulink.sdi.createRun(char(strrep(names{q}, ' ', '_')), 'vars', o.K_pu, o.theta_oil_C, o.theta_hs_C, o.ageing_rate_V);
    end
    Simulink.sdi.save(fullfile(here, 'results', 'step35_sdi_session.mldatx'));
catch ME
    sdiOK = false;  lg('SDI session not saved: %s\n', ME.message);
end
lg('SDI session saved: %d\n', sdiOK);
bdclose all;
fprintf('%d of %d checks passed. Log: %s\n', nnz(chk.passed), height(chk), logFile);
end

function style_axes(ax, cInk, cMute, cGrid)
% Plain style shared with the other MATLAB figures: Arial 9 pt, muted axes, light grid.
set(ax, 'Color', 'w', 'FontName', 'Arial', 'FontSize', 9, 'XColor', cMute, 'YColor', cMute, 'GridColor', cGrid, 'GridAlpha', 1, 'Box', 'off', 'TickDir', 'out');
ax.Title.Color = cInk;  ax.XLabel.Color = cInk;  ax.YLabel.Color = cInk;
grid(ax, 'on');
end

function v = ifelse(c, a, b)
if c, v = a; else, v = b; end
end
