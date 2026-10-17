function T = verify_step44()
%VERIFY_STEP44  Checks of the dashboard redesign of 17 Oct 2026 (decision D43): scenarios, sample sets, record picker, verdict banner,
%   method cards, charts, step-by-step text.
%
%   T = verify_step44        starts the dashboard (it starts the ML service itself), takes about 10 minutes.
%   OUTPUT  results/step44_checks.csv, results/step44_mixed_run.csv (the table of the mixed run), results/step44_*.png (screens)
%   Written 17 Oct 2026 for MATLAB R2025b. No value in this file is a model or diagnosis parameter.

here = fileparts(mfilename('fullpath'));  root = fileparts(here);
addpath(here);  addpath(fullfile(root, '04_MATLAB_Conventional'));  addpath(fullfile(root, '05_Simulink_Model'));
resDir = fullfile(here, 'results');
chk = struct('check', {}, 'passed', {}, 'detail', {});
add = @(c, name, ok, det) [c, struct('check', name, 'passed', logical(ok), 'detail', char(det))];
warning('off', 'all');
classes = ["Normal" "PD" "D1" "D2" "T1" "T2" "T3"];

app = DGADashboard;  cleanApp = onCleanup(@() delete(app));  app.PlaybackPause = 0;  drawnow;
app.UIFigure.Position = [30 30 1380 740];  app.UIFigure.Theme = 'light';  drawnow;
exportapp(app.UIFigure, fullfile(resDir, 'step44_screen0_start.png'));
chk = add(chk, 'start screen: banner says it is waiting, cards are empty, the welcome text names the colours', ...
    startsWith(app.VerdictLabel.Text, 'WAITING') && app.RogersAnswer.Text == "-" && any(contains(string(app.ExplainArea.Value), "GREEN = healthy")), app.VerdictLabel.Text);

%% 1 mixed run, constant rated load ----------------------------------------------------------------------------------------------
app.ScenarioDropDown.Value = 'rated';  app.SampleSetDropDown.Value = 'mixed';
S = dashboard_samples('mixed', fullfile(root, '03_Data', 'processed', 'dga_master.csv'), 'Seed', app.SampleSeed);
err = "";  tic;
try, app.RunSimulationButton.ButtonPushedFcn(app.RunSimulationButton, []); catch ME, err = string(ME.message); end
tRun = toc;  drawnow;
ER = app.EventResults;  tb = app.EventTable.Data;
chk = add(chk, 'mixed run: 7 sampling events, no error, all diagnosed', err == "" && numel(ER) == 7 && height(tb) == 7 && contains(app.StatusLabel.Text, '7 of 7'), sprintf('%s | %.0f s | %s', char(err), tRun, app.StatusLabel.Text));
chk = add(chk, 'mixed run: the 7 records are the healthy sample and one of each fault type, in the order Normal PD D1 D2 T1 T2 T3', ...
    isequal(string({ER.record_id}), S.record_id') && isequal(string(tb.("Known label"))', classes), strjoin(string(tb.Record), ' '));
t = tb.("Time (h)");
chk = add(chk, 'mixed run: sampling times 3, 6, ... 21 h (7 samples spread over the 24 h)', all(abs(t' - (3:3:21)) < 1e-6), strjoin(string(t'), ' '));
hl = arrayfun(@(e) string(e.result.verdict.health), ER);
chk = add(chk, 'mixed run: the table shows both states - at least one HEALTHY or WATCH and at least one FAULT', any(hl == "healthy" | hl == "watch") && any(hl == "fault"), strjoin(string(tb.Verdict)', ' | '));
chk = add(chk, 'event table: columns Rogers, IEC 60599, Duval, ML and Verdict are filled for every sample (the comparison of the methods in one table)', ...
    all(strlength(string(tb.Rogers)) > 0) && all(strlength(string(tb.("IEC 60599"))) > 0) && all(strlength(string(tb.Duval)) > 0) && all(strlength(string(tb.ML)) > 0) && all(strlength(string(tb.Verdict)) > 0), '');
writetable(tb, fullfile(resDir, 'step44_mixed_run.csv'));
% click each event: banner, cards, charts follow
okClick = true;  det = strings(0, 1);
for k = 1:7
    app.EventTable.CellSelectionCallback(app.EventTable, struct('Indices', [k 1]));  drawnow;
    V = ER(k).result.verdict;
    okK = string(app.LastResult.record_id) == ER(k).record_id && startsWith(string(app.VerdictLabel.Text), extractBefore(V.title + " ", " -")) ...
        && isequal(app.VerdictPanel.BackgroundColor, V.color) && string(app.RogersAnswer.Text) == V.answers(1) && string(app.IECAnswer.Text) == V.answers(2) ...
        && string(app.DuvalAnswer.Text) == V.answers(3) && string(app.MLAnswer.Text) == V.answers(4) && numel(app.GasAxes.Children) > 0 && numel(app.ProbAxes.Children) > 0 ...
        && any(contains(string(app.StepsArea.Value), "VERDICT: ")) && any(contains(string(app.StepsArea.Value), "STEP 8"));
    okClick = okClick && okK;  det(end + 1) = V.health + "/" + V.fault_class; %#ok<AGROW>
    if k == 1, exportapp(app.UIFigure, fullfile(resDir, 'step44_screen1_healthy.png')); end
    if hl(k) == "fault" && ~isfile(fullfile(resDir, 'step44_screen2_fault.png')), exportapp(app.UIFigure, fullfile(resDir, 'step44_screen2_fault.png')); end
end
chk = add(chk, 'clicking each of the 7 samples shows its verdict banner (text, colour), the four method cards, the gas and probability charts and the step-by-step text', okClick, strjoin(det, ' | '));
% banner colour follows the health state
cols = struct('healthy', [0.10 0.55 0.25], 'fault', [0.75 0.15 0.15]);
okCol = true;
for k = 1:7
    V = ER(k).result.verdict;
    if V.health == "healthy", okCol = okCol && isequal(V.color, cols.healthy); end
    if V.health == "fault",   okCol = okCol && isequal(V.color, cols.fault);   end
end
chk = add(chk, 'banner colour: green for healthy, red for fault', okCol, '');
% cards agree with the independent computation
okC = true;
for k = 1:7
    R = ER(k).result;  d2 = conventional_diagnosis(R.gas);
    okC = okC && string(R.conventional.rogers) == string(d2.rogers) && string(R.conventional.iec) == string(d2.iec) && string(R.conventional.duval) == string(d2.duval);
end
chk = add(chk, 'the diagnoses on the cards equal a fresh run of conventional_diagnosis on the file values', okC, '');
% gas values unchanged
M = readtable(fullfile(root, '03_Data', 'processed', 'dga_master.csv'), 'TextType', 'string');
okG = true;
for k = 1:7
    r = find(M.record_id == ER(k).record_id, 1);  g = ER(k).result.gas;
    okG = okG && isequal([g.H2 g.CH4 g.C2H6 g.C2H4 g.C2H2], [M.H2(r) M.CH4(r) M.C2H6(r) M.C2H4(r) M.C2H2(r)]);
end
chk = add(chk, 'gas values used in the 7 diagnoses are those of the file (nothing comes from the model)', okG, '');
% a second press gives a new mixed set
ids1 = string({ER.record_id});
app.RunSimulationButton.ButtonPushedFcn(app.RunSimulationButton, []);  drawnow;
ids2 = string({app.EventResults.record_id});
chk = add(chk, 'a second press with "Mixed" gives a different set of 7 (new seed), again one of each class', numel(ids2) == 7 && ~isequal(ids1, ids2) && isequal(string(app.EventTable.Data.("Known label"))', classes), strjoin(ids2, ' '));

%% 2 record picker, each type --------------------------------------------------------------------------------------------------------
okP = true;  det = strings(0, 1);
for c = classes
    app.FaultFilterDropDown.Value = char(c);
    app.RandomRecordButton.ButtonPushedFcn(app.RandomRecordButton, []);  drawnow;
    R = app.LastResult;  r = find(M.record_id == R.record_id, 1);
    okP = okP && ~isempty(r) && M.class_name(r) == c && app.RecordSpinner.Value == r && ~isempty(R.verdict.title);
    det(end + 1) = c + ":" + R.record_id + ":" + R.verdict.health; %#ok<AGROW>
end
chk = add(chk, 'record picker: for each type (Normal, PD, D1, D2, T1, T2, T3) a record of that known class is chosen and diagnosed', okP, strjoin(det, ' | '));
app.FaultFilterDropDown.Value = 'All';
app.RandomRecordButton.ButtonPushedFcn(app.RandomRecordButton, []);  drawnow;
chk = add(chk, 'record picker: "Any record" works', ~isempty(app.LastResult.record_id), char(app.LastResult.record_id));
app.RecordSpinner.Value = 5;  app.DiagnoseButton.ButtonPushedFcn(app.DiagnoseButton, []);  drawnow;
chk = add(chk, 'Diagnose selected record still works for record number 5', string(app.LastResult.record_id) == M.record_id(5), char(app.LastResult.record_id));

%% 3 ML service not reachable: the verdict uses the classical methods ----------------------------------------------------------------
url0 = app.ServiceURL;  app.ServiceURL = 'http://127.0.0.1:9/diagnose';  err = "";
try, app.RecordSpinner.Value = 5;  app.DiagnoseButton.ButtonPushedFcn(app.DiagnoseButton, []); catch ME, err = string(ME.message); end
V = app.LastResult.verdict;
chk = add(chk, 'ML not reachable: no error, ML card says n/a, verdict from the 3 classical methods (3 voters)', err == "" && V.voters == 3 && app.MLAnswer.Text == "n/a" && V.judge(4) == "NO ANSWER", sprintf('%s | %s', char(err), V.title));
app.ServiceURL = url0;

%% 4 scenarios -------------------------------------------------------------------------------------------------------------------------
app.SampleSetDropDown.Value = 'first';
app.ScenarioDropDown.Value = 'overload';
app.RunSimulationButton.ButtonPushedFcn(app.RunSimulationButton, []);  drawnow;
r = app.SimResult;
chk = add(chk, 'scenario "Short overload": 4 events at 6, 12, 18, 22 h; the hot-spot rises during the overload (peak above the rated-load run)', ...
    numel(app.EventResults) == 4 && all(abs(app.SimEvents.time_h' - [6 12 18 22]) < 1e-6) && max(r.theta_hs_C) > 100.3 && contains(string(app.UIAxesTemperature.Title.String), 'Short overload'), sprintf('peak %.1f degC', max(r.theta_hs_C)));
exportapp(app.UIFigure, fullfile(resDir, 'step44_screen3_overload.png'));
app.ScenarioDropDown.Value = 'daily';  app.SampleSetDropDown.Value = 'mixed';
tic;  app.RunSimulationButton.ButtonPushedFcn(app.RunSimulationButton, []);  drawnow;  tD = toc;
r = app.SimResult;
chk = add(chk, 'scenario "Daily load cycle": 72 h simulated, the last 24 h shown, 7 events inside the shown day, all diagnosed', ...
    abs(r.t_h(end) - 24) < 1e-6 && r.t_h(1) < 0.05 && numel(app.EventResults) == 7 && all(app.SimEvents.time_h > 0 & app.SimEvents.time_h < 24), sprintf('%.0f s, hot-spot %.1f to %.1f degC', tD, min(r.theta_hs_C), max(r.theta_hs_C)));
exportapp(app.UIFigure, fullfile(resDir, 'step44_screen4_daily.png'));

%% 5 explanation text ----------------------------------------------------------------------------------------------------------------------
L = dashboard_explain('steps', app.LastResult.gas, app.LastResult.conventional, app.LastResult.ml, app.LastResult.agreement, app.LastResult.verdict);
chk = add(chk, 'step-by-step text has the 8 steps and a verdict, no NaN/Inf', all(arrayfun(@(k) any(contains(L, "STEP " + k)), 1:8)) && any(contains(L, "VERDICT:")) && ~any(contains(L, "NaN")) && ~any(contains(L, "Inf ")), sprintf('%d lines', numel(L)));

T = struct2table(chk);
writetable(T, fullfile(resDir, 'step44_checks.csv'));
disp(T(:, {'check', 'passed'}));
fprintf('%d of %d checks passed.\n', sum(T.passed), height(T));
end

