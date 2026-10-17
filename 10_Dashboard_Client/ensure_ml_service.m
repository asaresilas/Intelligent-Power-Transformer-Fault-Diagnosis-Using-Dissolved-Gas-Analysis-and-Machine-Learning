function [ok, msg, started] = ensure_ml_service(projRoot, timeout_s, progressFcn)
%ENSURE_ML_SERVICE  Make sure the FastAPI diagnosis service (09_API_FastAPI) answers; start (or restart) it if it does not.
%
%   [ok, msg, started] = ensure_ml_service(projRoot)
%   [ok, msg, started] = ensure_ml_service(projRoot, timeout_s)               how long to wait for a start (default 60 s)
%   [ok, msg, started] = ensure_ml_service(projRoot, timeout_s, progressFcn)  progressFcn(text) is called while waiting
%
%   projRoot = folder that holds project_setup.m.   ok = the service answered /health.   started = THIS call launched it
%   (the dashboard stops only a service that it started itself).
%
%   Used by the dashboard at start-up and before a diagnosis. Rewritten 15 Oct 2026 after the freeze analysis:
%     1  The old version started the service with system('start /B ...'). The service then shared MATLAB's output pipe; after
%        about 60 requests the pipe was full, the service blocked and MATLAB waited for it (248 s measured). The service is now
%        started by 09_API_FastAPI\launch_service_detached.ps1 (WMI, no inherited handles, output to logs\service.log).
%     2  A service that holds port 8000 but does not answer (hung) is stopped and started again; the old version waited 90 s
%        for a second copy that could never take the port.
%     3  Every wait is short (health check 2 s) and reported through progressFcn, so the app never looks frozen.
%   Never stops the program: the result is returned in ok / msg. Gas values are never created here.
if nargin < 2 || isempty(timeout_s), timeout_s = 60; end
if nargin < 3, progressFcn = []; end
healthURL = 'http://127.0.0.1:8000/health';
ok = false; started = false;
if isHealthy(healthURL)
    ok = true; msg = 'ML service already running.'; return
end
py  = fullfile(projRoot, '06_Python_ML', '.venv', 'Scripts', 'python.exe');
app = fullfile(projRoot, '09_API_FastAPI');
if ~isfile(py)
    msg = 'ML service not started: the Python environment is missing (run 06_Python_ML\Setup_Python_Environment.bat).'; return
end
launcher = fullfile(app, 'launch_service_detached.ps1');
if ~isfile(launcher)
    msg = 'ML service not started: 09_API_FastAPI\launch_service_detached.ps1 not found.'; return
end
if portInUse()                                   % something holds the port but does not answer: a hung service
    say(progressFcn, 'ML service is not answering: restarting it...');
    stop_ml_service();
    pause(1);
end
say(progressFcn, 'Starting the ML service (10-30 s)...');
cmd = sprintf('powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%s"', launcher);
[st, out] = system(cmd);
if st ~= 0
    msg = ['ML service could not be launched: ' strtrim(out)]; return
end
started = true;
t0 = tic;
while toc(t0) < timeout_s
    if isHealthy(healthURL)
        ok = true; msg = sprintf('ML service started (%.0f s).', toc(t0)); return
    end
    say(progressFcn, sprintf('Waiting for the ML service... %.0f s', toc(t0)));
    pause(0.5);
end
msg = sprintf('ML service did not answer within %d s (see 09_API_FastAPI\\logs\\service.log). Start it by hand with 09_API_FastAPI\\Start_ML_Service.bat.', timeout_s);
end

function say(fcn, txt)
if ~isempty(fcn), fcn(txt); end
end

function tf = isHealthy(url)
try
    r = webread(url, weboptions('Timeout', 2));
    tf = isstruct(r) && isfield(r, 'status') && strcmp(r.status, 'ok');
catch
    tf = false;
end
end

function tf = portInUse()
[st, out] = system('powershell -NoProfile -NonInteractive -Command "(Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue | Measure-Object).Count"');
tf = st == 0 && str2double(strtrim(out)) > 0;
end
