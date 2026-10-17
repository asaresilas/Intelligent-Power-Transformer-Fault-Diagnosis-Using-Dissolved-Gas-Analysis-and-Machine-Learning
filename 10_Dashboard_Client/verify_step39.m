function T = verify_step39()
%VERIFY_STEP39  Checks of roadmap Step 39 (dashboard), decision D37.
%
%   T = verify_step39        needs the FastAPI service running on 127.0.0.1:8000 (09_API_FastAPI\run_service.ps1)
%
%   INPUT   10_Dashboard_Client/DGADashboard.mlapp, the service, 03_Data/processed/dga_master.csv,
%           11_Results/conventional/conventional_predictions.csv, 11_Results/ml/ml_predictions.csv (the offline results)
%   OUTPUT  results/step39_checks.csv, results/step39_three_records.csv, results/step39_held_out_comparison.csv
%   CHECKS  A  the .mlapp is a valid App Designer file with the Build Guide components and callbacks
%           B  the three known records (D37 clause 5) give the offline answers through the real DiagnoseButton callback
%           C  all 388 held-out records give the offline answers through the same helper functions
%           D  service not reachable, invalid gas values, unreadable file: a message, no error
%           E  agreement rule (dga_agreement), simulation button, Duval plot
%   Written 13 Oct 2026 for MATLAB R2025b.  No value in this file is a model or diagnosis parameter.

here = fileparts(mfilename('fullpath'));  root = fileparts(here);
addpath(here);  addpath(fullfile(root, '04_MATLAB_Conventional'));  addpath(fullfile(root, '05_Simulink_Model'));
resDir = fullfile(here, 'results');  if ~isfolder(resDir), mkdir(resDir); end
master = fullfile(root, '03_Data', 'processed', 'dga_master.csv');
chk = struct('check', {}, 'passed', {}, 'detail', {});
add = @(c, name, ok, det) [c, struct('check', name, 'passed', logical(ok), 'detail', char(det))];
warning('off', 'all');

%% A  the file -----------------------------------------------------------------------------------------------------------------
mlapp = fullfile(here, 'DGADashboard.mlapp');
des = appdesigner.internal.serialization.DeserializerFactory.createDeserializer(mlapp);
ad = des.getAppData();  fig = ad.components.UIFigure;  cleanFig = onCleanup(@() delete(fig));
dtc = findall(fig, '-property', 'DesignTimeProperties');
codeNames = arrayfun(@(c) string(c.DesignTimeProperties.CodeName), dtc);
guide = ["ControlPanel" "RunSimulationButton" "LoadDGAFileButton" "RecordSpinnerLabel" "RecordSpinner" "DiagnoseButton" "GasTable" ...
         "StatusLabel" "UIAxesTemperature" "UIAxesDuval" "ResultsTable" "AgreementLamp" "AgreementLabel"];
cbn = string({ad.code.Callbacks.Name});
okA = all(ismember(guide, codeNames)) && all(ismember(["RunSimulationButtonPushed" "LoadDGAFileButtonPushed" "DiagnoseButtonPushed"], cbn)) ...
      && ~isempty(ad.code.StartupCallback.Code) && string(ad.code.ClassName) == "DGADashboard";
chk = add(chk, 'DGADashboard.mlapp loads with App Designer''s reader; the 13 components of Build Guide C2, 3 callbacks and startupFcn are present', okA, ...
    sprintf('%d components with design-time data; callbacks %s', numel(codeNames), strjoin(cbn, ', ')));
missingNames = setdiff(guide, codeNames);

%% B  start the app --------------------------------------------------------------------------------------------------------------
project_setup_quiet(root);
app = DGADashboard;  cleanApp = onCleanup(@() delete(app));  drawnow;
okStart = contains(app.StatusLabel.Text, 'Ready') && isequal(app.AgreementLamp.Color, [0.6 0.6 0.6]) && app.ServiceURL == "http://127.0.0.1:8000/diagnose";
chk = add(chk, 'the app starts from the file: startup text, grey lamp, service address set', okStart, app.StatusLabel.Text);

M = readtable(master, 'TextType', 'string');
convOff = readtable(fullfile(root, '11_Results', 'conventional', 'conventional_predictions.csv'), 'TextType', 'string');
mlOff   = readtable(fullfile(root, '11_Results', 'ml', 'ml_predictions.csv'), 'TextType', 'string');
mnames = unique(convOff.method).';
okMethods = all(ismember(["IEC60599" "Rogers" "Duval"], mnames));
chk = add(chk, 'the offline conventional file has the methods IEC60599, Rogers, Duval', okMethods, strjoin(mnames, ', '));
classes = ["Normal" "PD" "D1" "D2" "T1" "T2" "T3"];  pcols = "p_" + classes;
offConv = @(id) [convOff.result(convOff.record_id == id & convOff.method == "Rogers"), ...
                 convOff.result(convOff.record_id == id & convOff.method == "IEC60599"), ...
                 convOff.result(convOff.record_id == id & convOff.method == "Duval")];
offMl = @(id) mlOff(mlOff.record_id == id, :);

% the three known records, chosen by the rule of D37 clause 5 BEFORE running them
held = M.data_role ~= "development" & strcmpi(string(M.in_scope_primary), "true");
fam = ["PD" "D2" "T3"];  famName = ["partial discharge" "electrical discharge" "thermal fault"];
rows = zeros(1, 3);
for q = 1:3
    r = find(held & M.class_name == fam(q), 1, 'first');
    rows(q) = r;
end
app.DGAFile = master;  app.RecordSpinner.Limits = [1 height(M)];
three = table();
for q = 1:3
    app.RecordSpinner.Value = rows(q);
    app.DiagnoseButton.ButtonPushedFcn(app.DiagnoseButton, []);  drawnow;
    R = app.LastResult;  id = string(R.record_id);
    oc = offConv(id);  om = offMl(id);
    appConv = [string(R.conventional.rogers), string(R.conventional.iec), string(R.conventional.duval)];
    pOff = double(om{1, cellstr(pcols)});
    pdiff = max(abs(R.ml.probabilities - pOff));
    aOff = dga_agreement(struct('rogers', oc(1), 'iec', oc(2), 'duval', oc(3)), struct('status', "OK", 'fault_class', om.y_pred(1)));
    okConv = isequal(appConv, oc);
    okMl = R.ml.status == "OK" && R.ml.fault_class == om.y_pred(1) && pdiff <= 1e-9;
    okAg = R.agreement.state == aOff.state && isequal(R.agreement.agrees, aOff.agrees) && contains(app.AgreementLabel.Text, extractBefore(string(aOff.label) + " (", " ("));
    okTab = isequal(string(app.ResultsTable.Data{4, 2}), R.ml.fault_class) && height(app.ProbabilityTable.Data) == 7 ...
            && isequal(app.GasTable.Data.ppm, [M.H2(rows(q)); M.CH4(rows(q)); M.C2H6(rows(q)); M.C2H4(rows(q)); M.C2H2(rows(q))]);
    okPlot = numel(app.UIAxesDuval.Children) > 0;
    chk = add(chk, sprintf('record %d (%s, %s): conventional answers equal the offline results', rows(q), id, famName(q)), okConv, ...
        sprintf('app %s | offline %s', strjoin(appConv, '/'), strjoin(oc, '/')));
    chk = add(chk, sprintf('record %d (%s): ML class and 7 probabilities equal the offline results', rows(q), id), okMl, ...
        sprintf('app %s | offline %s; largest probability difference %.1e', R.ml.fault_class, om.y_pred(1), pdiff));
    chk = add(chk, sprintf('record %d (%s): agreement flag, gas table, probability table and Duval plot as expected', rows(q), id), okAg && okTab && okPlot, ...
        sprintf('flag %s (%d of 3); Duval objects %d', R.agreement.state, R.agreement.count, numel(app.UIAxesDuval.Children)));
    three = [three; table(rows(q), id, famName(q), M.class_name(rows(q)), strjoin(appConv, '/'), R.ml.fault_class, R.agreement.state, ...
        'VariableNames', {'row', 'record_id', 'family', 'true_class', 'rogers_iec_duval', 'ml_class', 'agreement'})]; %#ok<AGROW>
end
writetable(three, fullfile(resDir, 'step39_three_records.csv'));

%% C  all held-out records through the helper functions -------------------------------------------------------------------------
ids = mlOff.record_id;  n = numel(ids);
okC = false(n, 1);  okConvAll = false(n, 3);  pd = zeros(n, 1);  cls = strings(n, 1);  appml = strings(n, 1);  lat = zeros(n, 1);
for i = 1:n
    r = find(M.record_id == ids(i), 1);
    [g, ~] = load_dga_record(master, r);
    d = conventional_diagnosis(g);  m = ml_diagnose(g, app.ServiceURL);
    ac = [string(d.rogers), string(d.iec), string(d.duval)];
    okConvAll(i, :) = ac == offConv(ids(i));
    pOff = double(mlOff{i, cellstr(pcols)});
    if m.status == "OK", pd(i) = max(abs(m.probabilities - pOff)); else, pd(i) = Inf; end
    appml(i) = m.fault_class;  cls(i) = mlOff.y_pred(i);  lat(i) = m.latency_s;
    okC(i) = all(okConvAll(i, :)) && m.status == "OK" && m.fault_class == mlOff.y_pred(i) && pd(i) <= 1e-9;
end
writetable(table(ids, M.data_role(arrayfun(@(x) find(M.record_id == x, 1), ids)), okConvAll(:, 1), okConvAll(:, 2), okConvAll(:, 3), appml, cls, pd, lat, ...
    'VariableNames', {'record_id', 'data_role', 'rogers_equal', 'iec_equal', 'duval_equal', 'ml_class_app', 'ml_class_offline', 'max_probability_difference', 'latency_s'}), ...
    fullfile(resDir, 'step39_held_out_comparison.csv'));
chk = add(chk, sprintf('all %d held-out records: three conventional answers and the ML class and probabilities equal the offline results', n), all(okC), ...
    sprintf('%d of %d identical; Rogers %d, IEC %d, Duval %d; ML class %d; largest probability difference %.1e; median service call %.0f ms', ...
    sum(okC), n, sum(okConvAll(:, 1)), sum(okConvAll(:, 2)), sum(okConvAll(:, 3)), sum(appml == cls), max(pd), 1000 * median(lat)));

%% D  failure cases (no crash, a message) ---------------------------------------------------------------------------------------
tmpd = tempname;  mkdir(tmpd);
try
    app.ServiceURL = 'http://127.0.0.1:9/diagnose';
    app.RecordSpinner.Value = rows(1);  err = "";
    try, app.DiagnoseButton.ButtonPushedFcn(app.DiagnoseButton, []); catch ME, err = string(ME.message); end
    R = app.LastResult;
    okD1 = err == "" && R.ml.status == "NOT_CONNECTED" && isequal(app.AgreementLamp.Color, [0.6 0.6 0.6]) && contains(app.ModelLabel.Text, 'NOT_CONNECTED') ...
           && string(app.ResultsTable.Data{1, 2}) == string(R.conventional.rogers);
    chk = add(chk, 'service not reachable: status NOT_CONNECTED, grey lamp, conventional answers still shown, no error', okD1, sprintf('%s | %s', R.ml.status, app.ModelLabel.Text));
catch ME
    chk = add(chk, 'service not reachable: status NOT_CONNECTED, grey lamp, conventional answers still shown, no error', false, ME.message);
end
app.ServiceURL = 'http://127.0.0.1:8000/diagnose';
bad = M(rows(1), :);  bad2 = bad;  bad.H2 = -5;  bad2.CH4 = NaN;
writetable([bad; bad2], fullfile(tmpd, 'bad_values.csv'));
app.DGAFile = fullfile(tmpd, 'bad_values.csv');  app.RecordSpinner.Limits = [1 2];  st = strings(2, 1);  okD2 = true;
for q = 1:2
    app.RecordSpinner.Value = q;  err = "";
    try, app.DiagnoseButton.ButtonPushedFcn(app.DiagnoseButton, []); catch ME, err = string(ME.message); end
    st(q) = app.LastResult.ml.status;  okD2 = okD2 && err == "" && startsWith(st(q), "INVALID_INPUT") && isequal(app.AgreementLamp.Color, [0.6 0.6 0.6]);
end
chk = add(chk, 'invalid gas values (negative H2, missing CH4): INVALID_INPUT, grey lamp, no error', okD2, strjoin(st, ' | '));
writetable(table(1, 2, 'VariableNames', {'a', 'b'}), fullfile(tmpd, 'wrong_columns.csv'));
app.DGAFile = fullfile(tmpd, 'wrong_columns.csv');  app.RecordSpinner.Limits = [1 1];  app.RecordSpinner.Value = 1;  err = "";
try, app.DiagnoseButton.ButtonPushedFcn(app.DiagnoseButton, []); catch ME, err = string(ME.message); end
chk = add(chk, 'file without gas columns: a message in the status line, no error', err == "" && contains(app.StatusLabel.Text, 'Cannot read the record'), app.StatusLabel.Text);
app.DGAFile = [];  err = "";
try, app.DiagnoseButton.ButtonPushedFcn(app.DiagnoseButton, []); catch ME, err = string(ME.message); end
chk = add(chk, 'Diagnose pressed before a file is loaded: a message, no error', err == "" && contains(app.StatusLabel.Text, 'Load a DGA file first'), app.StatusLabel.Text);

%% E  agreement rule, simulation button ---------------------------------------------------------------------------------------
mk = @(r, i, d) struct('rogers', r, 'iec', i, 'duval', d);  ml = @(c) struct('status', "OK", 'fault_class', c);
a1 = dga_agreement(mk("D2", "D2", "D2"), ml("D2"));
a2 = dga_agreement(mk("D1", "D1/D2", "DT"), ml("D1"));
a3 = dga_agreement(mk("ND", "ND", "ND"), ml("Normal"));
a4 = dga_agreement(mk("T2", "T2", "T2"), struct('status', "NOT_CONNECTED", 'fault_class', ""));
a5 = dga_agreement(mk("T1", "T1", "T1"), ml("T2"));
okE = a1.state == "green" && a2.state == "amber" && isequal(a2.agrees, [true true false]) && a3.state == "amber" && a3.count == 0 ...
      && a4.state == "grey" && isnan(a4.count) && a5.state == "amber" && a5.count == 0;
chk = add(chk, 'agreement rule: equal agrees; D1/D2 agrees with D1 or D2; DT and ND never agree; no ML result gives grey', okE, ...
    sprintf('%s %s(%s) %s %s %s', a1.state, a2.state, mat2str(a2.agrees), a3.state, a4.state, a5.state));
app.RunSimulationButton.ButtonPushedFcn(app.RunSimulationButton, []);  drawnow;
lines = findobj(app.UIAxesTemperature, 'Type', 'line');
okSim = numel(lines) == 2 && contains(app.StatusLabel.Text, 'Simulation done') && contains(app.StatusLabel.Text, '100.3');
chk = add(chk, 'Run transformer simulation: temperature plot (top-oil, hot-spot) and status with final hot-spot 100.3 degC (24 h rated load)', okSim, app.StatusLabel.Text);
rmdir(tmpd, 's');

T = struct2table(chk);
fprintf('%d of %d checks passed.\n', sum(T.passed), height(T));
writetable(T, fullfile(resDir, 'step39_checks.csv'));
if ~isempty(missingNames), warning('missing components: %s', strjoin(missingNames, ', ')); end
end

function project_setup_quiet(root)
    addpath(fullfile(root, '04_MATLAB_Conventional'));  addpath(fullfile(root, '05_Simulink_Model'));  addpath(fullfile(root, '10_Dashboard_Client'));
    evalc('params_transformer');
end
