function make_figure_4_22()
%MAKE_FIGURE_4_22  Figure 4.22: annotated screenshot of DGADashboard (roadmap Step 39, decision D37 clause 9).
%
%   Starts the app, runs the transformer simulation (the sampling events are played back, Step 40), diagnoses the first of the three known records of
%   verify_step39 for which the methods disagree (the most informative screen; the first record if none disagrees),
%   exports the window with exportapp and writes numbered labels at the positions of the components.
%   The service must be running (09_API_FastAPI\run_service.ps1).
%
%   OUTPUT  11_Results/figures/F4_22_dashboard_annotated.png (.pdf), F4_22_dashboard_annotated_legend.csv (number, component, what it shows)
%           11_Results/figures/F4_22_dashboard_raw.png (the window without labels)
%   The labels are black discs with white numbers: they mark components, they are not data (plot_style.csv is for data).
%   Written 13 Oct 2026 for MATLAB R2025b.

here = fileparts(mfilename('fullpath'));  clientDir = fileparts(here);  root = fileparts(clientDir);
addpath(clientDir);  addpath(fullfile(root, '04_MATLAB_Conventional'));  addpath(fullfile(root, '05_Simulink_Model'));
figDir = fullfile(root, '11_Results', 'figures');
three = readtable(fullfile(clientDir, 'results', 'step39_three_records.csv'), 'TextType', 'string');
k = find(three.agreement ~= "green", 1);  if isempty(k), k = 1; end
row = three.row(k);

app = DGADashboard;  cleanApp = onCleanup(@() delete(app));  app.PlaybackPause = 0;
app.UIFigure.Position = [60 60 1280 740];  app.UIFigure.Theme = 'light';  drawnow;
app.DGAFile = fullfile(root, '03_Data', 'processed', 'dga_master.csv');
app.RecordSpinner.Limits = [1 827];  app.RecordSpinner.Value = row;
app.RunSimulationButton.ButtonPushedFcn(app.RunSimulationButton, []);   % plays the four sampling events back (Step 40)
app.RecordSpinner.Value = row;   % the playback leaves the last event selected: choose the record again
app.DiagnoseButton.ButtonPushedFcn(app.DiagnoseButton, []);
drawnow;  pause(1);
raw = fullfile(figDir, 'F4_22_dashboard_raw.png');
exportapp(app.UIFigure, raw);
img = imread(raw);  [ih, iw, ~] = size(img);
fp = app.UIFigure.Position;  s = iw / fp(3);                        % image pixels per figure pixel

% number, component, anchor on the component (fraction of its width, height from the top), text
L = { ...
 1, app.RunSimulationButton,  [0 0], 'Run transformer simulation: plots the operating temperatures (context only)'; ...
 2, app.LoadDGAFileButton,    [0 0], 'Load measured DGA file; the record number is chosen with the spinner below it'; ...
 3, app.DiagnoseButton,       [0 0], 'Diagnose selected record: conventional methods in MATLAB, ML through the service'; ...
 4, app.GasTable,             [1 0], 'The five measured gases of the record (ppm), unchanged from the file'; ...
 5, app.UIAxesTemperature,    [0.97 0.12], 'Operating condition: top-oil and hot-spot temperature from the Simulink model'; ...
 6, app.UIAxesDuval,          [0.1 0.1], 'Duval Triangle 1 with the measured sample'; ...
 7, app.ResultsTable,         [1 0], 'Rogers, IEC 60599, Duval and ML diagnoses, and whether each agrees with ML'; ...
 8, app.ProbabilityTable,     [1 0], 'ML class probabilities from the service'; ...
 9, app.EventTable,           [1 0], 'Sampling events of the simulated day (dotted lines in 5): record, ML class, agreement, hot-spot temperature'; ...
 10, app.ModelLabel,          [0.99 0.3], 'Model name, version, hash, confidence and response time'; ...
 11, app.AgreementLabel,      [0.99 0.5], 'Agreement flag: green all agree, amber disagree, grey ML not available'};

f = figure('Visible', 'off', 'Color', 'w', 'Units', 'pixels', 'Position', [50 50 iw ih]);
ax = axes(f, 'Units', 'normalized', 'Position', [0 0 1 1]);
image(ax, img);  axis(ax, 'image');  axis(ax, 'off');  hold(ax, 'on');
r = 0.014 * iw;                                                      % disc radius, image pixels
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
names = ["RunSimulationButton" "LoadDGAFileButton" "DiagnoseButton" "GasTable" "UIAxesTemperature" "UIAxesDuval" "ResultsTable" "ProbabilityTable" "EventTable" "ModelLabel" "AgreementLabel"];
legend_tbl.tag = names(:);
exportgraphics(f, fullfile(figDir, 'F4_22_dashboard_annotated.png'), 'Resolution', 150);
exportgraphics(f, fullfile(figDir, 'F4_22_dashboard_annotated.pdf'), 'ContentType', 'image');
writetable(legend_tbl, fullfile(figDir, 'F4_22_dashboard_annotated_legend.csv'));
close(f);
fprintf('Figure 4.22 written (record row %d, %s).\n', row, three.record_id(k));
end
