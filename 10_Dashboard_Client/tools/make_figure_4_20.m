function make_figure_4_20()
%MAKE_FIGURE_4_20  Figure 4.20: the test-bench run (roadmap Step 41, decision D39 clause 6).
%
%   Reads logs/testbench_log.csv and logs/testbench_events.mat (written by run_testbench) and draws three panels over the
%   simulated run: (a) top-oil and hot-spot temperature with the 388 sampling events; (b) the ML class of the record taken at
%   each event; (c) how many of the three conventional methods agree with ML at each event.
%   OUTPUT  11_Results/figures/F4_20_testbench_run.png / .pdf / .csv (the plotted numbers)
%   Colours, markers and line colours are read from 11_Results/figures/plot_style.csv; nothing is typed here.
%   Written 13 Oct 2026 for MATLAB R2025b.

here = fileparts(mfilename('fullpath'));  clientDir = fileparts(here);  root = fileparts(clientDir);
figDir = fullfile(root, '11_Results', 'figures');
T = readtable(fullfile(clientDir, 'logs', 'testbench_log.csv'), 'TextType', 'string');
E = load(fullfile(clientDir, 'logs', 'testbench_events.mat'));
sty = readtable(fullfile(figDir, 'plot_style.csv'), 'TextType', 'string');
hexRGB = @(item) sscanf(char(extractBetween(sty.colour_hex(sty.item == item), 2, 7)), '%2x').' / 255;
cOil = hexRGB("sequential_high");  cHs = hexRGB("diverging_negative");  cInk = hexRGB("text");  cMute = hexRGB("muted");  cGrid = hexRGB("grid");
cLow = hexRGB("sequential_low");   cHigh = hexRGB("sequential_high");
classes = ["Normal" "PD" "D1" "D2" "T1" "T2" "T3"];

fig = figure('Visible', 'off', 'Units', 'centimeters', 'Position', [2 2 16 15], 'Color', 'w');
tl = tiledlayout(fig, 3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

%% (a) temperatures and sampling events ------------------------------------------------------------------------------------------
ax1 = nexttile(tl);  hold(ax1, 'on');
plot(ax1, E.tH, E.oilC, '-', 'Color', cOil, 'LineWidth', 1.4);
plot(ax1, E.tH, E.hsC, '-', 'Color', cHs, 'LineWidth', 1.4);
yl = [0 120];  ylim(ax1, yl);
tx = reshape([T.sim_time_h, T.sim_time_h, nan(height(T), 1)]', [], 1);                         % one tick per sampling event, as ONE line (NaN breaks)
ty = reshape([yl(1) * ones(height(T), 1), (yl(1) + 8) * ones(height(T), 1), nan(height(T), 1)]', [], 1);
plot(ax1, tx, ty, '-', 'Color', cInk, 'LineWidth', 0.4);
ylabel(ax1, 'Temperature (\circC)');  title(ax1, sprintf('(a) Simulated transformer, %d sampling events', height(T)), 'FontWeight', 'normal', 'Color', cInk);
legend(ax1, {'Top-oil', 'Hot-spot', 'Sampling event'}, 'Location', 'east', 'Box', 'off', 'TextColor', cInk);

%% (b) ML class at each event -------------------------------------------------------------------------------------------------------
ax2 = nexttile(tl);  hold(ax2, 'on');
yc = zeros(height(T), 1);
for q = 1:numel(classes)
    sel = T.ml_class == classes(q);  yc(sel) = q;
    if any(sel)
        plot(ax2, T.sim_time_h(sel), q * ones(nnz(sel), 1), char(sty.marker_matlab(sty.item == classes(q))), 'Color', hexRGB(classes(q)), ...
            'MarkerFaceColor', hexRGB(classes(q)), 'MarkerSize', 3.5, 'LineStyle', 'none');
    end
end
set(ax2, 'YTick', 1:numel(classes), 'YTickLabel', cellstr(classes), 'YDir', 'reverse');  ylim(ax2, [0.4 numel(classes) + 0.6]);
ylabel(ax2, 'ML class');  title(ax2, '(b) Machine-learning class of the record taken at each event', 'FontWeight', 'normal', 'Color', cInk);

%% (c) agreement ----------------------------------------------------------------------------------------------------------------------------
ax3 = nexttile(tl);  hold(ax3, 'on');
cnt = T.agreement_count;
for v = 0:3
    sel = cnt == v;  col = cLow + (cHigh - cLow) * v / 3;
    if any(sel), plot(ax3, T.sim_time_h(sel), v * ones(nnz(sel), 1), 's', 'Color', col, 'MarkerFaceColor', col, 'MarkerSize', 3.5, 'LineStyle', 'none'); end
end
set(ax3, 'YTick', 0:3);  ylim(ax3, [-0.5 3.5]);  ylabel(ax3, 'Methods agreeing (of 3)');  xlabel(ax3, 'Simulated time (h)');
title(ax3, '(c) Conventional methods that agree with ML at each event', 'FontWeight', 'normal', 'Color', cInk);

for ax = [ax1 ax2 ax3]
    set(ax, 'Color', 'w', 'XColor', cMute, 'YColor', cMute, 'GridColor', cGrid, 'Box', 'off', 'FontName', 'Arial', 'FontSize', 8, 'LineWidth', 0.6);
    grid(ax, 'on');  xlim(ax, [0 max(E.tH)]);
end
linkaxes([ax1 ax2 ax3], 'x');
base = fullfile(figDir, 'F4_20_testbench_run');
exportgraphics(fig, [base '.png'], 'Resolution', 300);
exportgraphics(fig, [base '.pdf'], 'ContentType', 'vector');
writetable(table(T.event, T.sim_time_h, T.record_id, T.data_role, T.ml_class, yc, T.agreement_count, T.hot_spot_C, ...
    'VariableNames', {'event', 'sim_time_h', 'record_id', 'data_role', 'ml_class', 'ml_class_row', 'conventional_agreeing', 'hot_spot_C'}), [base '.csv']);
close(fig);
fprintf('Figure 4.20 written (%d events).\n', height(T));
end
