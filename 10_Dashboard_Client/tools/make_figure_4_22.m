function make_figure_4_22()
%MAKE_FIGURE_4_22  Figure 4.22 / thesis Figure 8.6: annotated screenshot of DGADashboard (roadmap Step 39; redesign of 17 Oct 2026, D43).
%
%   Starts the app, runs the mixed set (healthy sample + one of each fault type) at constant rated load (the sampling events are diagnosed,
%   Step 40), selects the first sample whose verdict is FAULT and whose methods do not all agree (the most informative screen; the first
%   fault if none), exports the window with exportapp and writes numbered labels at the positions of the components.
%   The service is started by the app itself.
%
%   OUTPUT  11_Results/figures/F4_22_dashboard_annotated.png (.pdf), F4_22_dashboard_annotated_legend.csv (number, component, what it shows)
%           11_Results/figures/F4_22_dashboard_raw.png (the window without labels)
%   The labels are black discs with white numbers: they mark components, they are not data (plot_style.csv is for data).
%   Written 13 Oct 2026, rewritten 17 Oct 2026 for the redesigned layout, MATLAB R2025b.

here = fileparts(mfilename('fullpath'));  clientDir = fileparts(here);  root = fileparts(clientDir);
addpath(clientDir);  addpath(fullfile(root, '04_MATLAB_Conventional'));  addpath(fullfile(root, '05_Simulink_Model'));
figDir = fullfile(root, '11_Results', 'figures');

app = DGADashboard;  cleanApp = onCleanup(@() delete(app));  app.PlaybackPause = 0;
app.UIFigure.Position = [30 30 1380 740];  app.UIFigure.Theme = 'light';  drawnow;
app.ScenarioDropDown.Value = 'rated';  app.SampleSetDropDown.Value = 'mixed';
app.RunSimulationButton.ButtonPushedFcn(app.RunSimulationButton, []);   % plays the seven sampling events back
ER = app.EventResults;
pick = 0;
for k = 1:numel(ER)
    V = ER(k).result.verdict;  a = ER(k).result.agreement;
    if V.health == "fault" && a.state == "amber", pick = k; break, end
end
if pick == 0, pick = find(arrayfun(@(e) e.result.verdict.health == "fault", ER), 1); end
if isempty(pick) || pick == 0, pick = 1; end
app.EventTable.CellSelectionCallback(app.EventTable, struct('Indices', [pick 1]));
drawnow;  pause(1);
raw = fullfile(figDir, 'F4_22_dashboard_raw.png');
exportapp(app.UIFigure, raw);
img = imread(raw);  [ih, iw, ~] = size(img);
fp = app.UIFigure.Position;  s = iw / fp(3);                        % image pixels per figure pixel

% number, component, anchor on the component (fraction of its width, height from the top), text
L = { ...
 1, app.ScenarioDropDown,     [0.97 0.5], 'Operating condition of the simulated transformer: constant rated load, daily load cycle or short overload'; ...
 2, app.SampleSetDropDown,    [0.97 0.5], 'Which oil samples to examine: mixed (healthy and every fault type), random, or the first four records'; ...
 3, app.RunSimulationButton,  [0.03 0.5], 'Run the simulation and diagnose every sample'; ...
 4, app.RandomRecordButton,   [0.03 0.5], 'Pick a random record of the chosen type (fault-type list above it) and diagnose it'; ...
 5, app.VerdictLabel,         [0.8 0.5], 'Verdict banner: HEALTHY (green), FAULT with type (red), WATCH or CHECK (amber), with the reason and the action'; ...
 6, app.RogersCard,           [0.97 0.0], 'Method cards: Rogers, IEC 60599, Duval Triangle 1 and machine learning, each marked AGREES or DIFFERS'; ...
 7, app.RefCard,              [0.9 0.12], 'Known label of the record from the data file (used only to judge the methods)'; ...
 8, app.EventTable,           [0.98 0.1], 'Sample table: one row per oil sample with the four answers and the verdict (click a row)'; ...
 9, app.GasAxes,              [0.97 0.1], 'Each gas as a multiple of its typical value (IEC 60599); red = above'; ...
 10, app.UIAxesDuval,         [0.06 0.12], 'Duval Triangle 1 with the sample'; ...
 11, app.ProbAxes,            [0.97 0.1], 'Probability that the ML model gives to each fault type'; ...
 12, app.MainTabs,            [0.97 0.0], 'Tabs: Charts, Step by step (IEC 60599 procedure), Explanation in words, Tables, Simulation'; ...
 13, app.AgreementLamp,       [0.5 0.5], 'Agreement lamp: green all three classical methods agree with ML, amber they do not'};

f = figure('Visible', 'off', 'Color', 'w', 'Units', 'pixels', 'Position', [50 50 iw ih]);
ax = axes(f, 'Units', 'normalized', 'Position', [0 0 1 1]);
image(ax, img);  axis(ax, 'image');  axis(ax, 'off');  hold(ax, 'on');
r = 0.0125 * iw;                                                     % disc radius, image pixels
legend_tbl = table();
for q = 1:size(L, 1)
    c = L{q, 2};
    p = getpixelposition(c, true);                                   % [x y w h] in the figure, origin bottom left
    x = (p(1) + L{q, 3}(1) * p(3)) * s;
    y = ih - (p(2) + p(4) - L{q, 3}(2) * p(4)) * s;                  % image rows run downwards
    rectangle(ax, 'Position', [x - r, y - r, 2 * r, 2 * r], 'Curvature', [1 1], 'FaceColor', 'k', 'EdgeColor', 'w', 'LineWidth', 1.5);
    text(ax, x, y, num2str(L{q, 1}), 'Color', 'w', 'FontWeight', 'bold', 'FontSize', 11, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    legend_tbl = [legend_tbl; table(L{q, 1}, string(c.Tag), string(class(c)), string(L{q, 4}), 'VariableNames', {'number', 'tag', 'class', 'shows'})]; %#ok<AGROW>
end
names = ["ScenarioDropDown" "SampleSetDropDown" "RunSimulationButton" "RandomRecordButton" "VerdictLabel" "RogersCard" "RefCard" "EventTable" "GasAxes" "UIAxesDuval" "ProbAxes" "MainTabs" "AgreementLamp"];
legend_tbl.tag = names(:);
exportgraphics(f, fullfile(figDir, 'F4_22_dashboard_annotated.png'), 'Resolution', 150);
exportgraphics(f, fullfile(figDir, 'F4_22_dashboard_annotated.pdf'), 'ContentType', 'image');
writetable(legend_tbl, fullfile(figDir, 'F4_22_dashboard_annotated_legend.csv'));
close(f);
fprintf('Figure 4.22 written (sampling event %d, record %s, verdict %s).\n', pick, ER(pick).record_id, ER(pick).result.verdict.title);
end