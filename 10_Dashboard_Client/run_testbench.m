function T = run_testbench()
%RUN_TESTBENCH  End-to-end test bench: Simulink model -> sampling events -> records -> conventional methods + ML service (roadmap Step 41, D39).
%
%   T = run_testbench      needs the FastAPI service running on 127.0.0.1:8000 (09_API_FastAPI\run_service.ps1)
%
%   WHAT IT DOES   Simulates Transformer_Operating_Model (unchanged) with one sampling event every 15 min for the 388 held-out
%                  records (the sample times and the stop time are set for this run only, through SimulationInput). For each event,
%                  in time order, it does what the dashboard does with a record (find_dga_row, load_dga_record,
%                  conventional_diagnosis, ml_diagnose, dga_agreement) and logs the answers and the times. No true label is read.
%   OUTPUT         logs/testbench_log.csv       one row per held-out record (columns: see the code below)
%                  logs/testbench_run_info.json run conditions: service health and model hash before and after, schedule, machine, times
%                  logs/testbench_events.mat    the simulation output used for Figure 4.20 (time, temperatures, event times)
%   RESPONSE TIME  response_ms = time between sending the request and receiving the answer (tic/toc around webwrite in ml_diagnose;
%                  Analysis Plan Section 10); conventional_ms = time of conventional_diagnosis; total_ms = whole record.
%                  The first 5 calls are marked warmup = 1; all rows are logged (Step 42 decides what is reported).
%   Written 13 Oct 2026 for MATLAB R2025b.  No value in this file is a model or diagnosis parameter except the bench schedule below.

here = fileparts(mfilename('fullpath'));  root = fileparts(here);
addpath(here);  addpath(fullfile(root, '04_MATLAB_Conventional'));  addpath(fullfile(root, '05_Simulink_Model'));
evalc('params_transformer');                                    % heldout_record_ids etc. into this workspace and, through evalin, the base workspace
evalin('base', 'params_transformer;');                          % get_sampling_events reads heldout_record_ids from the base workspace
logDir = fullfile(here, 'logs');  if ~isfolder(logDir), mkdir(logDir); end
master = fullfile(root, '03_Data', 'processed', 'dga_master.csv');
url = 'http://127.0.0.1:8000/diagnose';  healthUrl = 'http://127.0.0.1:8000/health';
modelFile = fullfile(root, '05_Simulink_Model', 'Transformer_Operating_Model.slx');
warning('off', 'all');

%% bench schedule (decision D39, clause 2) -------------------------------------------------------------------------------------
interval_h = 0.25;                                               % one sampling event every 15 min
n = numel(heldout_record_ids);                                   % 388 held-out records
tSample = (1:n) * interval_h * 3600;                             % [s]
tStop = tSample(end) + 3600;                                     % [s] one hour after the last event

%% before the run ----------------------------------------------------------------------------------------------------------------
info = struct();
info.started = char(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss'));
info.matlab = version;  info.processor = getenv('PROCESSOR_IDENTIFIER');  info.logical_processors = getenv('NUMBER_OF_PROCESSORS');
hOpts = weboptions('Timeout', 10);
info.health_before = webread(healthUrl, hOpts);
info.model_file_checksum_before = Simulink.getFileChecksum(modelFile);
info.schedule = struct('interval_h', interval_h, 'n_events', n, 'stop_time_h', tStop / 3600, 'event_pulse_s', t_event_s);

%% simulate the model ------------------------------------------------------------------------------------------------------------
mdl = 'Transformer_Operating_Model';  load_system(mdl);
in = Simulink.SimulationInput(mdl);
in = in.setVariable('t_sample_s', tSample);
in = in.setModelParameter('StopTime', num2str(tStop));
tic;  out = sim(in);  info.simulation_s = toc;
ev = get_sampling_events(out);
if height(ev) ~= n, error('run_testbench:events', 'the model gave %d sampling events, %d expected', height(ev), n); end
tH = out.theta_hs_C.Time / 3600;  hsC = squeeze(out.theta_hs_C.Data);  oilC = squeeze(out.theta_oil_C.Data);
save(fullfile(logDir, 'testbench_events.mat'), 'tH', 'hsC', 'oilC', 'ev', 'tSample');

%% the records, in event order -----------------------------------------------------------------------------------------------------
M = readtable(master, 'TextType', 'string');
classes = ["Normal" "PD" "D1" "D2" "T1" "T2" "T3"];
L = repmat(struct('event', 0, 'sim_time_h', NaN, 'record_id', "", 'data_role', "", 'file_row', NaN, ...
    'H2', NaN, 'CH4', NaN, 'C2H6', NaN, 'C2H4', NaN, 'C2H2', NaN, 'rogers', "", 'iec60599', "", 'duval', "", ...
    'ml_status', "", 'ml_class', "", 'p_Normal', NaN, 'p_PD', NaN, 'p_D1', NaN, 'p_D2', NaN, 'p_T1', NaN, 'p_T2', NaN, 'p_T3', NaN, ...
    'confidence', NaN, 'model_name', "", 'model_version', "", 'model_sha256', "", 'agreement_state', "", 'agreement_count', NaN, ...
    'hot_spot_C', NaN, 'response_ms', NaN, 'conventional_ms', NaN, 'total_ms', NaN, 'warmup', false, 'error', ""), n, 1);
tAll = tic;
for k = 1:n
    L(k).event = k;  L(k).sim_time_h = ev.time_h(k);  L(k).record_id = ev.record_id(k);  L(k).warmup = k <= 5;
    L(k).hot_spot_C = interp1(tH, hsC, ev.time_h(k));
    tRec = tic;
    try
        row = find_dga_row(master, ev.record_id(k));
        if isnan(row), error('record %s is not in the DGA file', ev.record_id(k)); end
        L(k).file_row = row;  L(k).data_role = M.data_role(row);
        g = load_dga_record(master, row);
        L(k).H2 = g.H2;  L(k).CH4 = g.CH4;  L(k).C2H6 = g.C2H6;  L(k).C2H4 = g.C2H4;  L(k).C2H2 = g.C2H2;
        tc = tic;  d = conventional_diagnosis(g);  L(k).conventional_ms = 1000 * toc(tc);
        L(k).rogers = string(d.rogers);  L(k).iec60599 = string(d.iec);  L(k).duval = string(d.duval);
        m = ml_diagnose(g, url);
        L(k).response_ms = 1000 * m.latency_s;  L(k).ml_status = m.status;
        if m.status == "OK"
            L(k).ml_class = m.fault_class;  L(k).confidence = m.confidence;
            for q = 1:7, L(k).("p_" + classes(q)) = m.probabilities(q); end
            L(k).model_name = m.model_name;  L(k).model_version = m.model_version;  L(k).model_sha256 = m.model_sha256;
            a = dga_agreement(d, m);  L(k).agreement_state = a.state;  L(k).agreement_count = a.count;
        end
    catch ME
        L(k).error = string(ME.message);  if L(k).ml_status == "", L(k).ml_status = "ERROR"; end
    end
    L(k).total_ms = 1000 * toc(tRec);
end
info.records_s = toc(tAll);

%% after the run -------------------------------------------------------------------------------------------------------------------
info.health_after = webread(healthUrl, hOpts);
info.model_file_checksum_after = Simulink.getFileChecksum(modelFile);
info.finished = char(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss'));
T = struct2table(L);
writetable(T, fullfile(logDir, 'testbench_log.csv'));
info.n_rows = height(T);  info.n_failed = sum(T.ml_status ~= "OK" | T.error ~= "");
fid = fopen(fullfile(logDir, 'testbench_run_info.json'), 'w', 'n', 'UTF-8');  fwrite(fid, jsonencode(info, 'PrettyPrint', true));  fclose(fid);
fprintf('Test bench: %d records, %d failed, simulation %.1f s, records %.1f s.\n', info.n_rows, info.n_failed, info.simulation_s, info.records_s);
end
