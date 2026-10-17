function T = verify_step40()
%VERIFY_STEP40  Checks of roadmap Step 40 (Simulink model linked to the dashboard), decision D38.
%
%   T = verify_step40        needs the FastAPI service running on 127.0.0.1:8000 (09_API_FastAPI\run_service.ps1)
%
%   INPUT   DGADashboard.mlapp, Transformer_Operating_Model.slx, the service, dga_master.csv,
%           05_Simulink_Model/results/step37_sampling_events.csv, the offline results of Steps 14 and 22
%   OUTPUT  results/step40_checks.csv, results/step40_event_run.csv (the events of the full simulated day as the app shows them)
%   Written 13 Oct 2026 for MATLAB R2025b.  No value in this file is a model or diagnosis parameter.

here = fileparts(mfilename('fullpath'));  root = fileparts(here);
addpath(here);  addpath(fullfile(root, '04_MATLAB_Conventional'));  addpath(fullfile(root, '05_Simulink_Model'));
evalc('params_transformer');
resDir = fullfile(here, 'results');
master = fullfile(root, '03_Data', 'processed', 'dga_master.csv');
modelFile = fullfile(root, '05_Simulink_Model', 'Transformer_Operating_Model.slx');
chk = struct('check', {}, 'passed', {}, 'detail', {});
add = @(c, name, ok, det) [c, struct('check', name, 'passed', logical(ok), 'detail', char(det))];
warning('off', 'all');
h0 = string(Simulink.getFileChecksum(modelFile));

M = readtable(master, 'TextType', 'string');
convOff = readtable(fullfile(root, '11_Results', 'conventional', 'conventional_predictions.csv'), 'TextType', 'string');
mlOff   = readtable(fullfile(root, '11_Results', 'ml', 'ml_predictions.csv'), 'TextType', 'string');
ev37 = readtable(fullfile(root, '05_Simulink_Model', 'results', 'step37_sampling_events.csv'), 'TextType', 'string');
classes = ["Normal" "PD" "D1" "D2" "T1" "T2" "T3"];  pcols = "p_" + classes;
offConv = @(id) [convOff.result(convOff.record_id == id & convOff.method == "Rogers"), convOff.result(convOff.record_id == id & convOff.method == "IEC60599"), convOff.result(convOff.record_id == id & convOff.method == "Duval")];

app = DGADashboard;  cleanApp = onCleanup(@() delete(app));  app.PlaybackPause = 0;  app.SampleSetDropDown.Value = 'first';  drawnow;   % the Step 40 run = the 4-sample test set (redesign 17 Oct 2026)

%% 1 full simulated day from the button, default file ---------------------------------------------------------------------------
err = "";  tic;
try, app.RunSimulationButton.ButtonPushedFcn(app.RunSimulationButton, []); catch ME, err = string(ME.message); end
tRun = toc;  drawnow;
lines = findobj(app.UIAxesTemperature, 'Type', 'line');
xl = findall(app.UIAxesTemperature, 'Type', 'constantline');
yd = arrayfun(@(l) numel(l.YData), lines);
okDay = err == "" && numel(lines) == 2 && all(yd > 1000) && max(lines(1).XData) == 24 && contains(app.StatusLabel.Text, 'Simulation done') && contains(app.StatusLabel.Text, '100.3');
chk = add(chk, 'a full simulated day (24 h) runs from the Run Simulation button without error and is plotted', okDay, sprintf('%s | %.1f s | %s', char(err), tRun, app.StatusLabel.Text));
okFile = contains(app.StatusLabel.Text, 'using dga_master.csv') && endsWith(string(app.DGAFile), "dga_master.csv");
chk = add(chk, 'no DGA file loaded: the app uses dga_master.csv and says so', okFile, app.StatusLabel.Text);

%% 2 the events ------------------------------------------------------------------------------------------------------------------
E = app.SimEvents;  n = height(E);
okEv = n == height(ev37) && all(abs(E.time_h - ev37.time_h) < 1e-6) && isequal(E.record_id, ev37.record_id) && isequal(E.record_index, ev37.record_index) ...
       && isequal(E.Properties.VariableNames, {'time_h', 'record_index', 'record_id'});
chk = add(chk, 'the sampling events passed to the dashboard equal those of Step 37 (times, indices, record_ids); the table holds no gas value', okEv, ...
    sprintf('%d events at %s h: %s', n, strjoin(string(E.time_h'), ', '), strjoin(E.record_id', ', ')));
okMark = numel(xl) == n && all(abs(sort([xl.Value]) - E.time_h') < 1e-9);
chk = add(chk, 'every sampling event is marked on the temperature plot at its time', okMark, sprintf('%d markers', numel(xl)));

%% 3 each event diagnosed, equal to the offline results -------------------------------------------------------------------------
ER = app.EventResults;
okN = numel(ER) == n && isequal(string({ER.record_id}), E.record_id') && issorted([ER.time_h]);
okAll = okN;  det = strings(0, 1);  okGas = true;
for k = 1:numel(ER)
    R = ER(k).result;  id = string(R.record_id);  om = mlOff(mlOff.record_id == id, :);
    ac = [string(R.conventional.rogers), string(R.conventional.iec), string(R.conventional.duval)];
    pd = max(abs(R.ml.probabilities - double(om{1, cellstr(pcols)})));
    ok = isequal(ac, offConv(id)) && R.ml.status == "OK" && R.ml.fault_class == om.y_pred(1) && pd <= 1e-9;
    r = find(M.record_id == id, 1);
    okGas = okGas && isequal([R.gas.H2 R.gas.CH4 R.gas.C2H6 R.gas.C2H4 R.gas.C2H2], [M.H2(r) M.CH4(r) M.C2H6(r) M.C2H4(r) M.C2H2(r)]);
    okAll = okAll && ok;  det(end + 1) = sprintf('%s %s/%s', id, strjoin(ac, '-'), R.ml.fault_class); %#ok<AGROW>
end
chk = add(chk, 'at each sampling event the next record is diagnosed in time order; conventional answers, ML class and probabilities equal the offline results', okAll, strjoin(det, ' | '));
chk = add(chk, 'the gas values used at the events are those of the file rows (nothing comes from the model)', okGas, sprintf('%d events', numel(ER)));

%% 4 event table and thermal context ----------------------------------------------------------------------------------------------
tb = app.EventTable.Data;  vn = tb.Properties.VariableNames;  tcol = tb.(vn{2});  hcol = tb.(vn{end});
mlcls = string(arrayfun(@(e) e.result.ml.fault_class, ER));
direct = run_transformer_simulation();
hsEv = interp1(direct.t_h, direct.theta_hs_C, E.time_h);
okTab = height(tb) == n && isequal(string(tb.Record), E.record_id) && all(abs(tcol - E.time_h) < 1e-9) && all(abs(hcol - hsEv) < 1e-9) ...
        && isequal(string(tb.ML), mlcls(:));
chk = add(chk, 'event table: time, record, ML class and the simulated hot-spot temperature at that time', okTab, strjoin(compose("%s %.2f degC", string(tb.Record), hcol), ' | '));
ys = {lines.YData};
okTh = any(cellfun(@(y) isequal(y(:), direct.theta_oil_C(:)), ys)) && any(cellfun(@(y) isequal(y(:), direct.theta_hs_C(:)), ys));
chk = add(chk, 'the temperatures plotted by the app equal run_transformer_simulation of the unchanged model', okTh, sprintf('%d points per line', numel(lines(1).YData)));
writetable(table(tb.Event, tcol, string(tb.Record), string(tb.ML), string(tb.(vn{5})), hcol, ...
    'VariableNames', {'event', 'time_h', 'record_id', 'ml_class', 'conventional_agreeing', 'hot_spot_C'}), fullfile(resDir, 'step40_event_run.csv'));

%% 5 repeat, no service, record missing from the file ----------------------------------------------------------------------------
app.RunSimulationButton.ButtonPushedFcn(app.RunSimulationButton, []);  drawnow;
E2 = app.SimEvents;
chk = add(chk, 'the same run twice gives the same events and replaces the table (4 rows, not 8)', isequal(E2, E) && height(app.EventTable.Data) == n && numel(app.EventResults) == n && numel(findall(app.UIAxesTemperature, 'Type', 'constantline')) == n, ...
    sprintf('%d rows, %d results', height(app.EventTable.Data), numel(app.EventResults)));
app.ServiceURL = 'http://127.0.0.1:9/diagnose';  err = "";
try, app.RunSimulationButton.ButtonPushedFcn(app.RunSimulationButton, []); catch ME, err = string(ME.message); end
st = string(arrayfun(@(e) e.result.ml.status, app.EventResults, 'UniformOutput', false));
chk = add(chk, 'service not reachable during the run: the day still runs, every event shows NOT_CONNECTED, no error', err == "" && numel(st) == n && all(st == "NOT_CONNECTED") && all(string(app.EventTable.Data.ML) == "NOT_CONNECTED") && contains(app.StatusLabel.Text, '4 of 4'), ...
    sprintf('%s | %s', char(err), app.StatusLabel.Text));
app.ServiceURL = 'http://127.0.0.1:8000/diagnose';
tmpd = tempname;  mkdir(tmpd);  writetable(M(M.record_id == "IECTC10_0001", :), fullfile(tmpd, 'one_record.csv'));
app.DGAFile = fullfile(tmpd, 'one_record.csv');  err = "";
try, app.RunSimulationButton.ButtonPushedFcn(app.RunSimulationButton, []); catch ME, err = string(ME.message); end
chk = add(chk, 'records of other events missing from the loaded file are skipped with a message, no error', err == "" && contains(app.StatusLabel.Text, '1 of 4 sampling events') && numel(app.EventResults) == 1, app.StatusLabel.Text);
rmdir(tmpd, 's');

%% 6 the model is unchanged; Step 39 still passes ---------------------------------------------------------------------------------
h1 = string(Simulink.getFileChecksum(modelFile));
chk = add(chk, 'the model file is unchanged by the app runs (checksum)', h0 == h1, char(h1));
delete(app);
T39 = verify_step39();
chk = add(chk, 'the 19 checks of verify_step39.m still pass with the new app', all(T39.passed) && height(T39) == 19, sprintf('%d of %d', sum(T39.passed), height(T39)));

T = struct2table(chk);
fprintf('%d of %d checks passed.\n', sum(T.passed), height(T));
writetable(T, fullfile(resDir, 'step40_checks.csv'));
end

