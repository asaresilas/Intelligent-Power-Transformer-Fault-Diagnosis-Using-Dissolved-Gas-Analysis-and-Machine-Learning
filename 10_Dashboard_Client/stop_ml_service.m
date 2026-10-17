function stop_ml_service()
%STOP_ML_SERVICE  Stop the FastAPI diagnosis service that listens on 127.0.0.1:8000 (started by ensure_ml_service).
%   Runs 09_API_FastAPI\stop_service.ps1: ends the process that holds the port (also a hung one) and its python/cmd parent.
%   Safe to call when nothing runs.
here = fileparts(mfilename('fullpath'));
script = fullfile(fileparts(here), '09_API_FastAPI', 'stop_service.ps1');
if ~isfile(script), return, end
[~, ~] = system(sprintf('powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%s"', script));   % output not printed
end
