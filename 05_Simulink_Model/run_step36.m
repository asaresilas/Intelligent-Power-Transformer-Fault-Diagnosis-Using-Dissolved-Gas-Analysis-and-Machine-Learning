function [chk, summ] = run_step36()
%RUN_STEP36  Roadmap Step 36: run the three operating scenarios of scenarios.m and log them (decision D34).
%
%   [chk, summ] = run_step36()
%
%   For each scenario: simulate Transformer_Operating_Model with the scenario's load profile (nothing else is changed), simulate
%   it a second time from a fresh start, save results/sim_<id>.mat, store the run in the Simulation Data Inspector, draw
%   Figure 4.19 (one per scenario) and summarise the window that is shown (peak hot-spot and its time, loss of life L).
%   CHECKS (D34 clause 5): runs reproducible (two fresh runs identical; saved file equals a new run); model file unchanged
%   (SHA-256); S1 equals run_transformer_simulation of the default profile; hot-spot >= top-oil >= ambient and V > 0.
%
%   OUTPUT  results/sim_rated.mat, sim_daily.mat, sim_overload.mat, results/step36_checks.csv, results/step36_scenario_summary.csv,
%           results/step36_sdi_session.mldatx, 11_Results/figures/F4_19a|b|c_scenario_*.(png|pdf|csv)
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 36.   MATLAB R2025b.

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
mdl  = 'Transformer_Operating_Model';
mdlFile = fullfile(here, [mdl '.slx']);
resDir = fullfile(here, 'results');  figDir = fullfile(root, '11_Results', 'figures');
warning('off', 'all');
bdclose all;  addpath(here);
evalin('base', 'params_transformer;');
theta_amb_C = evalin('base', 'theta_amb_C');
hash0 = file_hash(mdlFile);
S = scenarios();
chk = table('Size', [0 3], 'VariableTypes', {'string', 'logical', 'string'}, 'VariableNames', {'check', 'passed', 'detail'});
summ = table();
load_system(mdlFile);

for q = 1:numel(S)
    sc = S(q);
    r1 = simulate(mdl, sc);
    bdclose all;  load_system(mdlFile);             % fresh start for the second run
    r2 = simulate(mdl, sc);
    dRep = max([maxabs(r1.K_pu, r2.K_pu), maxabs(r1.theta_oil_C, r2.theta_oil_C), maxabs(r1.theta_hs_C, r2.theta_hs_C), maxabs(r1.ageing_V, r2.ageing_V)]);
    chk = add(chk, sprintf('%s: two fresh runs are identical', sc.id), dRep == 0, sprintf('largest difference %.2e', dRep));

    run = r1;  run.id = sc.id;  run.label = sc.label;  run.theta_amb_C = theta_amb_C * ones(size(run.t_s));
    run.K_demand_pu = interp1(sc.profile.Time, squeeze(sc.profile.Data), run.t_s, 'linear', 'extrap');
    w = run.t_s >= sc.show_from_s;                  % window that is shown (the last 24 h)
    tw = run.t_s(w) - sc.show_from_s;               % [s] time within the window
    run.window = w;  run.show_from_s = sc.show_from_s;
    run.L_h = trapz(tw, run.ageing_V(w)) / 3600;    % [h] loss of life in the window (equivalent hours at the reference temperature)
    [pk, ip] = max(run.theta_hs_C(w));
    run.peak_hs_C = pk;  run.t_peak_h = tw(ip) / 3600;
    run.peak_oil_C = max(run.theta_oil_C(w));
    run.model_sha256 = hash0;  run.matlab = version;
    run.scenario = struct('t_stop_s', sc.t_stop_s, 'show_from_s', sc.show_from_s, 'profile_time_s', sc.profile.Time, 'profile_K_pu', squeeze(sc.profile.Data));
    save(fullfile(resDir, ['sim_' sc.id '.mat']), 'run');

    % physical sanity
    okPhys = all(run.theta_hs_C >= run.theta_oil_C - 1e-6) && all(run.theta_oil_C >= theta_amb_C - 1e-6) && all(run.ageing_V > 0);
    chk = add(chk, sprintf('%s: hot-spot >= top-oil >= ambient and V > 0 at all times', sc.id), okPhys, ...
        sprintf('min(hot-spot - top-oil) %.3f K; min(top-oil - ambient) %.3f K; min V %.3g', min(run.theta_hs_C - run.theta_oil_C), min(run.theta_oil_C - theta_amb_C), min(run.ageing_V)));

    row = table(string(sc.id), string(sc.label), sc.t_stop_s / 3600, sc.show_from_s / 3600, min(run.K_demand_pu(w)), max(run.K_demand_pu(w)), ...
        max(run.K_pu(w)), run.peak_oil_C, run.peak_hs_C, run.t_peak_h, run.L_h, run.ageing_V(end), ...
        'VariableNames', {'scenario', 'label', 'run_hours', 'window_starts_h', 'demand_min_pu', 'demand_max_pu', 'K_measured_max_pu', ...
        'peak_top_oil_C', 'peak_hot_spot_C', 'time_of_peak_h', 'loss_of_life_h', 'V_end'});
    summ = [summ; row]; %#ok<AGROW>
    results{q} = run; %#ok<AGROW>
    figure_for(run, sc, figDir, q);
end

% reproducibility of the saved files and of the model file
for q = 1:numel(S)
    L = load(fullfile(resDir, ['sim_' S(q).id '.mat']));  rr = simulate(mdl, S(q));
    d = max([maxabs(L.run.theta_oil_C, rr.theta_oil_C), maxabs(L.run.theta_hs_C, rr.theta_hs_C), maxabs(L.run.ageing_V, rr.ageing_V)]);
    chk = add(chk, sprintf('%s: saved sim_%s.mat equals a new run', S(q).id, S(q).id), d == 0, sprintf('largest difference %.2e', d));
end
chk = add(chk, 'model file unchanged by the runs (SHA-256)', strcmp(hash0, file_hash(mdlFile)), char(hash0));

% S1 against the default run of the model (run_transformer_simulation) and its loss of life
bdclose all;  ref = run_transformer_simulation();
r = results{1};
dRef = max([maxabs(r.theta_oil_C, ref.theta_oil_C), maxabs(r.theta_hs_C, ref.theta_hs_C), maxabs(r.ageing_V, ref.ageing_V)]);
chk = add(chk, 'rated: equals run_transformer_simulation of the default profile', dRef == 0, sprintf('largest difference %.2e; L %.4f h vs %.4f h', dRef, r.L_h, ref.loss_of_life_h));
chk = add(chk, 'rated: loss of life equals run_transformer_simulation (1e-9 h)', abs(r.L_h - ref.loss_of_life_h) < 1e-9, sprintf('%.6f h', r.L_h));

% daily cycle: how periodic is the last day? (information) - difference between day 3 and day 2 on the same clock time
d3 = results{2};  tt = d3.t_s;  hs = d3.theta_hs_C;
grid = (0:60:24 * 3600).';
hs2 = interp1(tt, hs, 24 * 3600 + grid);  hs3 = interp1(tt, hs, 48 * 3600 + grid);
dPer = max(abs(hs3 - hs2));
chk = add(chk, 'daily: day 3 and day 2 differ by less than 1 K in hot-spot temperature (cycle has settled; information)', dPer < 1, sprintf('largest difference %.3f K', dPer));
summ.daily_day3_minus_day2_hs_K = [NaN; dPer; NaN];

writetable(chk, fullfile(resDir, 'step36_checks.csv'));
writetable(summ, fullfile(resDir, 'step36_scenario_summary.csv'));
defs = table();                                     % the demand profile of every scenario (breakpoints), for the report
for q = 1:numel(S)
    p = S(q).profile;
    defs = [defs; table(repmat(string(S(q).id), numel(p.Time), 1), p.Time / 3600, squeeze(p.Data), 'VariableNames', {'scenario', 'time_h', 'demand_pu'})]; %#ok<AGROW>
end
writetable(defs, fullfile(resDir, 'step36_scenario_definitions.csv'));

% Simulation Data Inspector
try
    Simulink.sdi.clear;
    for q = 1:numel(S)
        rr = results{q};
        ts = @(x, n) setname(timeseries(x, rr.t_s), n);
        Simulink.sdi.createRun(['Step36_' S(q).id], 'vars', ts(rr.K_pu, 'K_pu'), ts(rr.theta_oil_C, 'theta_oil_C'), ts(rr.theta_hs_C, 'theta_hs_C'), ts(rr.ageing_V, 'ageing_rate_V'));
    end
    Simulink.sdi.save(fullfile(resDir, 'step36_sdi_session.mldatx'));
catch ME
    chk = add(chk, 'Simulation Data Inspector session saved', false, ME.message);
    writetable(chk, fullfile(resDir, 'step36_checks.csv'));
end
disp(chk);  disp(summ);
fprintf('%d of %d checks passed.\n', nnz(chk.passed), height(chk));
bdclose all;
end

%% ----------------------------------------------------------------------------------------------------------------------
function r = simulate(mdl, sc)
% One run of the model with the scenario's load profile and stop time (nothing else changed).
in = Simulink.SimulationInput(mdl);
in = in.setVariable('load_profile', sc.profile);
in = in.setModelParameter('StopTime', num2str(sc.t_stop_s));
o = sim(in);
r.t_s = o.theta_oil_C.Time;
r.K_pu = squeeze(o.K_pu.Data);  r.theta_oil_C = squeeze(o.theta_oil_C.Data);
r.theta_hs_C = squeeze(o.theta_hs_C.Data);  r.ageing_V = squeeze(o.ageing_rate_V.Data);
% all logged signals share the time vector of the oil temperature (checked)
assert(isequal(o.K_pu.Time, r.t_s) && isequal(o.theta_hs_C.Time, r.t_s) && isequal(o.ageing_rate_V.Time, r.t_s), 'logged signals have different time vectors');
end

function d = maxabs(a, b)
if numel(a) ~= numel(b), d = Inf; else, d = max(abs(a(:) - b(:))); end
end

function chk = add(chk, n, p, d)
chk = [chk; table(string(n), logical(p), string(d), 'VariableNames', {'check', 'passed', 'detail'})];
end

function h = file_hash(f)
md =java.security.MessageDigest.getInstance('SHA-256');
fid = fopen(f, 'r');  b = fread(fid, Inf, '*uint8');  fclose(fid);
md.update(b);
h = string(lower(reshape(dec2hex(typecast(md.digest(), 'uint8')).', 1, [])));
end

function ts = setname(ts, n)
ts.Name = n;
end

function figure_for(run, sc, figDir, q)
% Figure 4.19: three panels (load factor; temperatures; ageing rate on a log axis with the loss of life) for the shown 24 h.
sty = readtable(fullfile(figDir, 'plot_style.csv'), 'TextType', 'string');
hexRGB = @(item) sscanf(char(extractBetween(sty.colour_hex(sty.item == item), 2, 7)), '%2x').' / 255;
cOil = hexRGB("sequential_high");  cHs = hexRGB("diverging_negative");  cInk = hexRGB("text");  cMute = hexRGB("muted");  cGrid = hexRGB("grid");
w = run.window;  t = (run.t_s(w) - run.show_from_s) / 3600;
fig = figure('Visible', 'off', 'Units', 'centimeters', 'Position', [2 2 16 14], 'Color', 'w');
try, theme(fig, 'light'); catch, end
tl = tiledlayout(fig, 3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
ax1 = nexttile(tl);  hold(ax1, 'on');
plot(ax1, t, run.K_demand_pu(w), '--', 'Color', cMute, 'LineWidth', 1.0);
plot(ax1, t, run.K_pu(w), '-', 'Color', cInk, 'LineWidth', 1.4);
ylabel(ax1, 'Load factor K (pu)');  title(ax1, run.label, 'FontWeight', 'normal');
legend(ax1, {'Demand', 'Measured K'}, 'Location', 'best', 'Box', 'off', 'FontSize', 8);
ax2 = nexttile(tl);  hold(ax2, 'on');
plot(ax2, t, run.theta_amb_C(w), ':', 'Color', cMute, 'LineWidth', 1.2);
plot(ax2, t, run.theta_oil_C(w), '-', 'Color', cOil, 'LineWidth', 1.6);
plot(ax2, t, run.theta_hs_C(w), '-', 'Color', cHs, 'LineWidth', 1.6);
plot(ax2, run.t_peak_h, run.peak_hs_C, 'o', 'Color', cHs, 'MarkerFaceColor', 'w', 'MarkerSize', 5);
ha = 'left';  if run.t_peak_h > 12, ha = 'right'; end        % keep the label inside the axes
text(ax2, run.t_peak_h, run.peak_hs_C, sprintf('  peak %.1f \\circC at %.1f h  ', run.peak_hs_C, run.t_peak_h), 'Color', cInk, 'FontSize', 8, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', ha, 'FontName', 'Arial');
ylim(ax2, [0 1.15 * run.peak_hs_C]);
ylabel(ax2, 'Temperature (\circC)');
legend(ax2, {'Ambient', 'Top-oil', 'Hot-spot'}, 'Location', 'southeast', 'Box', 'off', 'FontSize', 8);
ax3 = nexttile(tl);
semilogy(ax3, t, run.ageing_V(w), '-', 'Color', cHs, 'LineWidth', 1.6);  hold(ax3, 'on');
text(ax3, 0.02, 0.92, sprintf('Loss of life L = %.2f h', run.L_h), 'Units', 'normalized', 'VerticalAlignment', 'top', 'Color', cInk, 'FontSize', 8, 'FontName', 'Arial');
ylabel(ax3, 'Ageing rate V (-)');  xlabel(ax3, 'Time (h)');
for ax = [ax1 ax2 ax3]
    set(ax, 'Color', 'w', 'FontName', 'Arial', 'FontSize', 9, 'XColor', cMute, 'YColor', cMute, 'GridColor', cGrid, 'GridAlpha', 1, 'Box', 'off', 'TickDir', 'out', 'XLim', [0 24], 'XTick', 0:4:24);
    ax.Title.Color = cInk;  ax.XLabel.Color = cInk;  ax.YLabel.Color = cInk;  grid(ax, 'on');
end
set([ax1 ax2], 'XTickLabel', []);
base = fullfile(figDir, sprintf('F4_19%s_scenario_%s', char('a' + q - 1), run.id));
exportgraphics(fig, [base '.png'], 'Resolution', 300);
exportgraphics(fig, [base '.pdf'], 'ContentType', 'vector');
close(fig);
ix = find(w);  ix = ix(1:10:end);
D = table((run.t_s(ix) - run.show_from_s) / 3600, run.K_demand_pu(ix), run.K_pu(ix), run.theta_amb_C(ix), run.theta_oil_C(ix), run.theta_hs_C(ix), run.ageing_V(ix), ...
    'VariableNames', {'time_h', 'demand_pu', 'K_measured_pu', 'ambient_C', 'top_oil_C', 'hot_spot_C', 'ageing_rate_V'});
writetable(D, [base '.csv']);
end
