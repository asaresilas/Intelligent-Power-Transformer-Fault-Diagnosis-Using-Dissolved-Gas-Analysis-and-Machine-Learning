function m = ml_diagnose(g, url)
%ML_DIAGNOSE  Ask the FastAPI service (09_API_FastAPI, Step 38) for the machine-learning diagnosis.
%
%   m = ml_diagnose(g)         g = struct with H2, CH4, C2H6, C2H4, C2H2 (ppm), optional record_id (text)
%   m = ml_diagnose(g, url)    other service address (default http://127.0.0.1:8000/diagnose)
%
%   The call never stops the program: every problem is returned in m.status (decision D37, clause 3).
%   OUTPUT  m.status         "OK" | "NOT_CONNECTED" (service not reachable) | "INVALID_INPUT: ..." | "ERROR: ..."
%           m.fault_class    most probable class (Normal PD D1 D2 T1 T2 T3), "" unless status is OK
%           m.probabilities  1x7 double in the order m.classes (as sent by the service, not rounded)
%           m.confidence, m.model_name, m.model_version, m.model_sha256, m.data_version, m.record_id, m.notes
%           m.latency_s      time of the call, s
%   Gas values are never created here: they are sent as given. Field names are those of openapi.json (D36).
if nargin < 2, url = 'http://127.0.0.1:8000/diagnose'; end
gases = {'H2', 'CH4', 'C2H6', 'C2H4', 'C2H2'};
m = struct('status', "NOT_CONNECTED", 'fault_class', "", 'probabilities', nan(1, 7), ...
    'classes', ["Normal" "PD" "D1" "D2" "T1" "T2" "T3"], 'confidence', NaN, 'model_name', "", ...
    'model_version', "", 'model_sha256', "", 'data_version', "", 'record_id', "", 'notes', strings(0, 1), 'latency_s', NaN);
body = struct();
for k = 1:numel(gases)
    if ~isfield(g, gases{k}) || ~isnumeric(g.(gases{k})) || ~isscalar(g.(gases{k})) || ~isfinite(g.(gases{k})) || g.(gases{k}) < 0
        m.status = "INVALID_INPUT: " + string(gases{k}) + " must be one finite number >= 0 (ppm)";
        return
    end
    body.(gases{k}) = double(g.(gases{k}));
end
if isfield(g, 'record_id') && strlength(string(g.record_id)) > 0 && strlength(string(g.record_id)) <= 64
    body.record_id = char(string(g.record_id));
end
opts = weboptions('MediaType', 'application/json', 'RequestMethod', 'post', 'Timeout', 10, 'ContentType', 'json');
tic;
try
    resp = webwrite(url, body, opts);
    m.latency_s = toc;
    p = resp.probabilities;
    m.probabilities = cellfun(@(c) double(p.(c)), cellstr(m.classes));
    m.fault_class   = string(resp.fault_class);
    m.confidence    = double(resp.confidence);
    m.model_name    = string(resp.model_name);
    m.model_version = string(resp.model_version);
    m.model_sha256  = string(resp.model_sha256);
    m.data_version  = string(resp.data_version);
    if isfield(resp, 'record_id') && ~isempty(resp.record_id), m.record_id = string(resp.record_id); end
    if isfield(resp, 'notes') && ~isempty(resp.notes), m.notes = string(resp.notes(:)); end
    m.status = "OK";
catch ME
    m.latency_s = toc;
    msg = string(ME.message);
    if contains(ME.identifier, ["ConnectionRefused", "UnknownHost", "Timeout", "CouldNotConnect", "ConnectFailed"], 'IgnoreCase', true) ...
            || contains(msg, ["refused", "Could not connect", "timed out", "Timeout", "resolve host", "Failed to connect"], 'IgnoreCase', true)
        m.status = "NOT_CONNECTED";
    elseif contains(msg, "422")
        m.status = "INVALID_INPUT: the service refused the values (" + strtrim(extractBefore(msg + newline, newline)) + ")";
    else
        m.status = "ERROR: " + strtrim(extractBefore(msg + newline, newline));
    end
end
end