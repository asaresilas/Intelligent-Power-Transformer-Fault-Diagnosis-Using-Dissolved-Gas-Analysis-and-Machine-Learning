function T = verify_step43()
%VERIFY_STEP43  Checks of the dashboard master-control update of 15 Oct 2026 (freeze fix, explanation panel).
%
%   T = verify_step43      starts and stops the ML service itself (the service may be running or not before the call)
%
%   WHAT IT CHECKS (the "loop goal": the update is accepted only when every check passes)
%     A  the freeze: 400 requests in a row through a service started from MATLAB (the old start froze at request 62)
%     B  a hung service (port taken, no answer) is replaced by a working one
%     C  cold start of the app with the service stopped: it starts the service, warms the model, shows the welcome text
%     D  Run simulation: explanation of the simulation and of the sampling events; numbers equal the program output
%     E  clicking an event row shows its record and its explanation
%     F  the explanation text of all 388 held-out records: no error, no NaN, every method and the ML class named
%     G  the service stops during use: the app restarts it and the run still diagnoses every event
%     H  closing the window stops a service that the app started, and leaves one that it did not start
%     I  the buttons are enabled again after every step, also after a failure
%     J  the older checks (Step 39: 19, Step 40: 13) still pass with the new app
%   OUTPUT  results/step43_checks.csv, results/step43_dashboard_screenshot.png
%   Gas values are read from the data file only; none is created here. Written 15 Oct 2026 for MATLAB R2025b.

here = fileparts(mfilename('fullpath'));  root = fileparts(here);
addpath(here);  addpath(fullfile(root, '04_MATLAB_Conventional'));  addpath(fullfile(root, '05_Simulink_Model'));
evalc('params_transformer');
resDir = fullfile(here, 'results');
master = fullfile(root, '03_Data', 'processed', 'dga_master.csv');
chk = struct('check', {}, 'passed', {}, 'detail', {});
add = @(c, name, ok, det) [c, struct('check', name, 'passed', logical(ok), 'detail', char(det))];
warning('off', 'all');
M = readtable(master, 'TextType', 'string');
health = @() isHealthy();

%% A the freeze: 400 requests in a row -------------------------------------------------------------------------------------------
stop_ml_service();  pause(2);
[ok, msg, started] = ensure_ml_service(root, 60);
okStart = ok && started && isHealthy();
g = struct('H2', M.H2(1), 'CH4', M.CH4(1), 'C2H6', M.C2H6(1), 'C2H4', M.C2H4(1), 'C2H2', M.C2H2(1));
nReq = 400;  lat = nan(nReq, 1);  nFail = 0;  tA = tic;
for k = 1:nReq
    m = ml_diagnose(g);  lat(k) = m.latency_s;
    if m.status ~= "OK", nFail = nFail + 1; if nFail >= 3, break, end, end
end
chk = add(chk, 'A1 the service starts from MATLAB without blocking MATLAB (detached start)', okStart, msg);
chk = add(chk, 'A2 400 requests in a row through that service: none fails (the old start froze at request 62)', nFail == 0 && k == nReq, ...
    sprintf('%d requests, %d failed, %.1f s, median %.0f ms, slowest %.0f ms', k, nFail, toc(tA), 1000 * median(lat, 'omitnan'), 1000 * max(lat)));
logFile = fullfile(root, '09_API_FastAPI', 'logs', 'service.log');
chk = add(chk, 'A3 the service writes to its own log file, not to a pipe of MATLAB (log exists, no request lines)', isfile(logFile) && dir(logFile).bytes < 20000, ...
    sprintf('%d bytes', dir(logFile).bytes));

%% B a hung service is replaced -------------------------------------------------------------------------------------------------
stop_ml_service();  pause(2);
hungScript = [tempname '.ps1'];                         % a listener that accepts connections and never answers = a hung service
fid = fopen(hungScript, 'w');  fprintf(fid, '$l=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,8000);$l.Start();Start-Sleep 600\n');  fclose(fid);
[~, ~] = system(['powershell -NoProfile -NonInteractive -Command "Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine=''powershell -NoProfile -ExecutionPolicy Bypass -File \"' hungScript '\"''} | Out-Null"']);   % the temp path may contain a space: quoted
pause(5);
busy = ~isHealthy() && portListening();
tB = tic;  [ok, msg, started] = ensure_ml_service(root, 60);
chk = add(chk, 'B a service that holds the port but does not answer is stopped and replaced by a working one', busy && ok && started && isHealthy(), ...
    sprintf('hung state created: %d; %s (%.0f s)', busy, msg, toc(tB)));

%% C cold start of the app ---------------------------------------------------------------------------------------------------------
stop_ml_service();  pause(2);
tC = tic;  app = DGADashboard;  drawnow;  tStart = toc(tC);
cleanApp = onCleanup(@() safeDelete(app));
welcome = string(app.ExplainArea.Value);
chk = add(chk, 'C1 cold start with the service stopped: the app starts the service and reports Ready', isHealthy() && app.ServiceStarted && startsWith(app.StatusLabel.Text, 'Ready. ML service connected'), ...
    sprintf('%.1f s | %s', tStart, app.StatusLabel.Text));
chk = add(chk, 'C2 the explanation panel shows the welcome text (how to use, two kinds of information, fault types)', ...
    any(contains(welcome, "HOW TO READ THIS DASHBOARD")) && any(contains(welcome, "FAULT TYPES")) && any(contains(welcome, "never makes up")), sprintf('%d lines', numel(welcome)));
chk = add(chk, 'C3 all buttons are enabled after the start', allEnabled(app), '');

%% D run simulation ---------------------------------------------------------------------------------------------------------------------
app.PlaybackPause = 0;  tD = tic;
err = "";  try, app.RunSimulationButton.ButtonPushedFcn(app.RunSimulationButton, []); catch ME, err = string(ME.message); end
tRun = toc(tD);  drawnow;
txt = string(app.ExplainArea.Value);  r = app.SimResult;  ER = app.EventResults;  n = numel(ER);
hsMax = max(r.theta_hs_C);
okD1 = err == "" && n == 4 && contains(app.StatusLabel.Text, '4 of 4');
chk = add(chk, 'D1 the run completes (simulation + 4 sampling events) without error', okD1, sprintf('%s | %.1f s | %s', char(err), tRun, app.StatusLabel.Text));
okD2 = any(contains(txt, "WHAT THE SIMULATION SHOWS")) && any(contains(txt, sprintf("peaks at %.1f degC", hsMax))) ...
    && any(contains(txt, sprintf("%.1f hours at the normal rate", r.loss_of_life_h))) && any(contains(txt, sprintf("ends at %.1f degC", r.theta_oil_C(end))));
chk = add(chk, 'D2 the simulation explanation quotes the program values (peak hot-spot, final top-oil, loss of life)', okD2, sprintf('peak %.1f degC, loss of life %.1f h', hsMax, r.loss_of_life_h));
okD3 = any(contains(txt, "WHAT HAPPENED AT THE SAMPLING EVENTS")) && any(contains(txt, "4 oil samples")) && find(contains(txt, "WHAT HAPPENED")) < find(contains(txt, "WHAT THE DIAGNOSIS MEANS"));
chk = add(chk, 'D3 after a run the summary of the events comes first, then the simulation, then the last record', okD3, '');
chk = add(chk, 'D4 the explanation names the record that is shown and its three conventional answers and the ML class', ...
    any(contains(txt, "Record " + string(ER(end).result.record_id))) && explainsAll(txt, ER(end).result), string(ER(end).result.record_id));
chk = add(chk, 'D5 all buttons are enabled after the run', allEnabled(app), '');

%% E click on an event row --------------------------------------------------------------------------------------------------------------
app.EventTable.CellSelectionCallback(app.EventTable, struct('Indices', [2 1]));
txt2 = string(app.ExplainArea.Value);
chk = add(chk, 'E clicking event 2 shows its record (spinner, tables, explanation first)', ...
    string(app.LastResult.record_id) == ER(2).record_id && any(contains(txt2(1:3), "WHAT THE DIAGNOSIS MEANS")) && any(contains(txt2, "Record " + ER(2).record_id)) && app.RecordSpinner.Value == ER(2).row, ...
    char(ER(2).record_id));
exportapp(app.UIFigure, fullfile(resDir, 'step43_dashboard_screenshot.png'));

%% G service stops during use ------------------------------------------------------------------------------------------------------------
stop_ml_service();  pause(2);
chk = add(chk, 'G0 (set-up) the service is stopped', ~isHealthy(), '');
err = "";  try, app.RunSimulationButton.ButtonPushedFcn(app.RunSimulationButton, []); catch ME, err = string(ME.message); end
st = string(arrayfun(@(e) e.result.ml.status, app.EventResults, 'UniformOutput', false));
chk = add(chk, 'G the service was stopped before the run: the app restarts it and all 4 events are diagnosed by ML', err == "" && numel(st) == 4 && all(st == "OK") && isHealthy(), ...
    sprintf('%s | %s', char(err), strjoin(st, ',')));
chk = add(chk, 'I1 buttons enabled again after that run', allEnabled(app), '');

%% F explanation text for all 388 held-out records ---------------------------------------------------------------------------------------
H = M(M.data_role ~= "development", :);  nH = height(H);
gg = struct('H2', H.H2, 'CH4', H.CH4, 'C2H6', H.C2H6, 'C2H4', H.C2H4, 'C2H2', H.C2H2, 'equipment_type', H.equipment_type);
dd = conventional_diagnosis(gg);
nBad = 0;  bad = strings(0, 1);  nAmb = 0;
for k = 1:nH
    g1 = struct('H2', H.H2(k), 'CH4', H.CH4(k), 'C2H6', H.C2H6(k), 'C2H4', H.C2H4(k), 'C2H2', H.C2H2(k), 'record_id', H.record_id(k));
    d1 = struct('rogers', dd.rogers(k), 'iec', dd.iec(k), 'duval', dd.duval(k), 'gate_upper', dd.gate_upper(k));
    m1 = ml_diagnose(g1);  a1 = dga_agreement(d1, m1);
    R1 = struct('gas', g1, 'conventional', d1, 'ml', m1, 'agreement', a1);
    try
        L = dashboard_explain('diagnosis', g1, d1, m1, a1);
        okk = isstring(L) && iscolumn(L) && ~any(contains(L, "NaN")) && ~any(contains(L, "Inf ")) && m1.status == "OK" && explainsAll(L, R1) ...
            && (a1.state ~= "amber" || any(contains(L, "Who differs"))) && (a1.state ~= "green" || any(contains(L, "green lamp")));
        nAmb = nAmb + (a1.state == "amber");
    catch ME
        okk = false;  L = string(ME.message);
    end
    if ~okk, nBad = nBad + 1; bad(end + 1) = H.record_id(k); end %#ok<AGROW>
end
chk = add(chk, 'F the explanation of every held-out record is built without error, has no NaN, names Rogers, IEC, Duval and the ML class, and the agreement text matches the lamp', nBad == 0, ...
    sprintf('%d records, %d bad %s, %d amber', nH, nBad, strjoin(bad(1:min(3, end)), ','), nAmb));
% special inputs: ML not connected, all gases zero
mNo = ml_diagnose(struct('H2', 1, 'CH4', 1, 'C2H6', 1, 'C2H4', 1, 'C2H2', 1), 'http://127.0.0.1:9/diagnose');
d0 = conventional_diagnosis(struct('H2', 1, 'CH4', 1, 'C2H6', 1, 'C2H4', 1, 'C2H2', 1));
L0 = dashboard_explain('diagnosis', struct('H2', 1, 'CH4', 1, 'C2H6', 1, 'C2H4', 1, 'C2H2', 1), d0, mNo, dga_agreement(d0, mNo));
chk = add(chk, 'F2 with the ML service not connected the explanation says so and keeps the classical results', any(contains(L0, "not available (NOT_CONNECTED)")) && any(contains(L0, "grey lamp")), '');

%% H closing the window ----------------------------------------------------------------------------------------------------------------------
stop_ml_service();  pause(2);
app2 = DGADashboard;  drawnow;  startedHere = app2.ServiceStarted;
app2.UIFigure.CloseRequestFcn(app2.UIFigure, []);  pause(2);
chk = add(chk, 'H1 closing the window stops the service that this app started', startedHere && ~isHealthy() && ~isvalid(app2), sprintf('started by app %d', startedHere));
[~, ~] = ensure_ml_service(root, 60);                   % service started "from outside"
app3 = DGADashboard;  drawnow;  startedHere3 = app3.ServiceStarted;
app3.UIFigure.CloseRequestFcn(app3.UIFigure, []);  pause(1);
chk = add(chk, 'H2 closing the window leaves a service that this app did not start', ~startedHere3 && isHealthy() && ~isvalid(app3), sprintf('started by app %d', startedHere3));

%% I buttons after a failure --------------------------------------------------------------------------------------------------------------------
app.DGAFile = fullfile(tempname, 'missing.csv');
try, app.DiagnoseButton.ButtonPushedFcn(app.DiagnoseButton, []); catch, end
chk = add(chk, 'I2 a failed diagnosis (file missing) gives a message and the buttons are enabled again', allEnabled(app) && contains(app.StatusLabel.Text, 'Cannot read'), app.StatusLabel.Text);
delete(app);

%% J older checks ------------------------------------------------------------------------------------------------------------------------------
[~, ~] = ensure_ml_service(root, 60);
T39 = verify_step39();
chk = add(chk, 'J1 the 19 checks of verify_step39 still pass', all(T39.passed) && height(T39) == 19, sprintf('%d of %d', sum(T39.passed), height(T39)));
T40 = verify_step40();
chk = add(chk, 'J2 the 13 checks of verify_step40 still pass', all(T40.passed) && height(T40) == 13, sprintf('%d of %d', sum(T40.passed), height(T40)));

T = struct2table(chk);
fprintf('%d of %d checks passed.\n', sum(T.passed), height(T));
disp(T(~T.passed, :));
writetable(T, fullfile(resDir, 'step43_checks.csv'));
end

%% ---------------------------------------------------------------------------------------------------------------------------------
function tf = isHealthy()
try, r = webread('http://127.0.0.1:8000/health', weboptions('Timeout', 2)); tf = isstruct(r) && strcmp(r.status, 'ok'); catch, tf = false; end
end

function tf = portListening()
[~, out] = system('powershell -NoProfile -NonInteractive -Command "(Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue | Measure-Object).Count"');
tf = str2double(strtrim(out)) > 0;
end

function tf = allEnabled(app)
b = {app.RunSimulationButton, app.LoadDGAFileButton, app.DiagnoseButton, app.RestartServiceButton, app.RecordSpinner};
tf = all(cellfun(@(c) string(c.Enable) == "on", b));
end

function tf = explainsAll(txt, R)
d = R.conventional;  m = R.ml;
tf = any(contains(txt, "- Rogers ratio: ")) && any(contains(txt, "- IEC 60599 ratio: ")) && any(contains(txt, "- Duval Triangle 1: ")) ...
    && any(contains(txt, "Rogers ratio: " + startsWith_label(d.rogers))) && any(contains(txt, "IEC 60599 ratio: " + startsWith_label(d.iec))) ...
    && any(contains(txt, "Duval Triangle 1: " + startsWith_label(d.duval))) ...
    && (m.status ~= "OK" || any(contains(txt, "most probable type " + m.fault_class)));
end

function s = startsWith_label(x)
x = string(x);
if x == "D1/D2", s = "D1 or D2"; elseif any(x == ["Normal" "DT" "ND"]), s = x; else, s = x + ","; end
end

function safeDelete(app)
try, if isvalid(app), delete(app); end, catch, end
end
