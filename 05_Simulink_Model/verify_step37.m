function [chk, events] = verify_step37()
%VERIFY_STEP37  Roadmap Step 37: tests of the DGA sampling-event subsystem SS8_Sampling_Events (decision D35 and its amendment).
%
%   [chk, events] = verify_step37()
%
%   A  INSPECTION / NO GAS VALUE
%      1  SS8 exists, carries an annotation and a Description, and has no input or output port (no line to SS1-SS7).
%      2  Every block of SS8 is of an allowed kind (clock, constant, comparison, counting, logic, logging); the list is written to
%         results/step37_ss8_blocks.csv.
%      3  No block name, dialog value or logged variable name anywhere in the model refers to a gas or a concentration.
%      4  The logged signals of the model are exactly: K_pu, theta_oil_C, theta_hs_C, ageing_rate_V, record_index, sampling_event.
%      5  params_transformer.m reads no gas column: its code lines name no gas, and the only table it reads is limited to the
%         columns record_id and data_role; the workspace it creates holds the record ids as text and no gas variable.
%   B  BEHAVIOUR (default run, 24 h)
%      6  record_index is 0 before the first sampling time and k from the k-th sampling time (step within 1e-6 s of the set time).
%      7  sampling_event is 1 only inside [t_k, t_k + t_event_s) and 1 for all logged points there; 4 pulses.
%      8  The record_ids found by get_sampling_events are the first n held-out ids, are unique, and exist in dga_master.csv with a
%         role other than "development".
%   C  REGRESSION (D35 amendment)
%      9  The three Step 36 scenarios give the same signals as the saved Step 36 results (results/before_step37) on their common
%         time points: top-oil and hot-spot within 0.01 K, K within 1e-4 pu, ageing rate within 0.12 % (relative).
%     10  The nine checks of verify_step33.m all pass.
%
%   OUTPUT  results/step37_checks.csv, step37_ss8_blocks.csv, step37_sampling_events.csv
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 37.   MATLAB R2025b.

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
mdl  = 'Transformer_Operating_Model';
ss8  = [mdl '/SS8_Sampling_Events'];
warning('off', 'all');
bdclose all;  addpath(here);
evalin('base', 'params_transformer;');
P = struct();
for n = {'t_sample_s', 't_event_s', 'heldout_record_ids', 'n_heldout', 't_stop'}, P.(n{1}) = evalin('base', n{1}); end
chk = table('Size', [0 3], 'VariableTypes', {'string', 'logical', 'string'}, 'VariableNames', {'check', 'passed', 'detail'});
load_system(fullfile(here, [mdl '.slx']));

%% 1-2 inspection --------------------------------------------------------------------------------------------------------
ports = get_param(ss8, 'Ports');
nNotes = numel(find_system(ss8, 'FindAll', 'on', 'SearchDepth', 1, 'Type', 'annotation'));
chk = add(chk, 'SS8 has an annotation and a Description, and no input or output port (no connection to SS1-SS7)', ...
    nNotes >= 1 && ~isempty(get_param(ss8, 'Description')) && all(ports(1:2) == 0), ...
    sprintf('%d annotations; ports in/out = %d/%d', nNotes, ports(1), ports(2)));
b = find_system(ss8, 'SearchDepth', 1, 'Type', 'block');  b = b(~strcmp(b, ss8));
kind = strings(numel(b), 1);
for i = 1:numel(b)
    kind(i) = string(get_param(b{i}, 'BlockType'));
    if kind(i) == "SubSystem", kind(i) = string(get_param(b{i}, 'MaskType')); end
end
allowed = ["Clock" "Constant" "RelationalOperator" "DataTypeConversion" "Sum" "Product" "MinMax" "Compare To Constant" "Logic" "ToWorkspace"];
blk = table(string(strrep(b, [ss8 '/'], '')), kind, 'VariableNames', {'block', 'kind'});
writetable(blk, fullfile(here, 'results', 'step37_ss8_blocks.csv'));
bad = blk.block(~ismember(blk.kind, allowed));
chk = add(chk, 'every block of SS8 is a clock, constant, comparison, counting, logic or logging block', isempty(bad), ...
    sprintf('%d blocks; kinds: %s; not allowed: %s', numel(b), strjoin(unique(blk.kind).', ', '), joinOrNone(bad)));

%% 3-4 no gas anywhere in the model ---------------------------------------------------------------------------------------
allB = find_system(mdl, 'LookUnderMasks', 'all', 'Type', 'block');
formulas = ["H2" "CH4" "C2H6" "C2H4" "C2H2"];                       % case-sensitive whole words (Q_h2 is a heat input, not hydrogen)
words = ["gas" "ppm" "dga" "concentration" "hydrogen" "methane" "ethane" "ethylene" "acetylene"];
hits = strings(0, 1);
for i = 1:numel(allB)
    txt = string(get_param(allB{i}, 'Name'));
    dp = get_param(allB{i}, 'DialogParameters');
    if isstruct(dp)
        f = fieldnames(dp);
        for j = 1:numel(f)
            try, v = get_param(allB{i}, f{j}); catch, continue; end
            if ischar(v) || isstring(v), txt = txt + " " + string(v); end
        end
    end
    for g = formulas, if ~isempty(regexp(char(txt), ['(^|[^A-Za-z0-9])' char(g) '($|[^A-Za-z0-9])'], 'once')), hits(end + 1) = string(allB{i}) + " (" + g + ")"; end, end %#ok<AGROW>
    for w = words, if contains(lower(txt), w), hits(end + 1) = string(allB{i}) + " (" + w + ")"; end, end %#ok<AGROW>
end
chk = add(chk, 'no block name or dialog value in the model refers to a gas or a concentration', isempty(hits), ...
    sprintf('%d blocks scanned; hits: %s', numel(allB), joinOrNone(hits)));
tw = find_system(mdl, 'LookUnderMasks', 'all', 'BlockType', 'ToWorkspace');
logged = sort(string(get_param(tw, 'VariableName')));
expected = sort(["K_pu"; "theta_oil_C"; "theta_hs_C"; "ageing_rate_V"; "record_index"; "sampling_event"]);
chk = add(chk, 'the logged signals are exactly K_pu, theta_oil_C, theta_hs_C, ageing_rate_V, record_index, sampling_event', isequal(logged(:), expected), ...
    strjoin(logged.', ', '));

%% 5 parameter file reads no gas column -------------------------------------------------------------------------------------
lines = splitlines(string(fileread(fullfile(here, 'params_transformer.m'))));
code = lines(~startsWith(strtrim(lines), "%") & strtrim(lines) ~= "");
code = regexprep(code, '%.*$', '');                                  % strip trailing comments
gasInCode = code(~cellfun(@isempty, regexp(cellstr(code), '(^|[^A-Za-z0-9_])(H2|CH4|C2H6|C2H4|C2H2)($|[^A-Za-z0-9_])', 'once')));
readLines = code(contains(code, "readtable") | contains(code, "SelectedVariableNames"));
colsOK = any(contains(readLines, "{'record_id', 'data_role'}"));
vars = evalin('base', 'who');
gasVars = vars(~cellfun(@isempty, regexpi(vars, '^(H2|CH4|C2H6|C2H4|C2H2|gas|ppm|dga)', 'once')));
chk = add(chk, 'params_transformer.m reads only the columns record_id and data_role and defines no gas variable', ...
    isempty(gasInCode) && colsOK && isempty(gasVars) && isstring(P.heldout_record_ids) && iscolumn(P.heldout_record_ids), ...
    sprintf('gas names in code lines: %d; column limit present: %d; gas-named variables: %d; heldout_record_ids %s %dx1', numel(gasInCode), colsOK, numel(gasVars), class(P.heldout_record_ids), numel(P.heldout_record_ids)));

%% 6-8 behaviour ---------------------------------------------------------------------------------------------------------------
o = sim(mdl);
t  = o.record_index.Time;  ri = squeeze(o.record_index.Data);
ev = squeeze(o.sampling_event.Data);  ev = double(ev);
expIdx = arrayfun(@(x) nnz(x >= P.t_sample_s), t);
nWrong = nnz(ri ~= expIdx);
tk = zeros(numel(P.t_sample_s), 1);
for k = 1:numel(tk), tk(k) = t(find(ri >= k, 1)); end
dt = abs(tk - P.t_sample_s(:));
chk = add(chk, 'record_index is 0 before the first sampling time and k from the k-th (step within 1e-6 s)', nWrong == 0 && all(dt < 1e-6), ...
    sprintf('%d logged points; wrong values %d; largest timing error %.2e s', numel(t), nWrong, max(dt)));
inPulse = false(size(t));
for k = 1:numel(P.t_sample_s), inPulse = inPulse | (t >= P.t_sample_s(k) & t < P.t_sample_s(k) + P.t_event_s); end
nearEdge = false(size(t));                                            % points within 1e-6 s of a pulse edge are not judged
for k = 1:numel(P.t_sample_s), nearEdge = nearEdge | abs(t - P.t_sample_s(k)) < 1e-6 | abs(t - (P.t_sample_s(k) + P.t_event_s)) < 1e-6; end
nBad = nnz((ev ~= 0) ~= inPulse & ~nearEdge);
nPulses = nnz(diff([0; ev]) > 0);
chk = add(chk, 'sampling_event is 1 only inside [t_k, t_k + t_event_s) and one pulse per sampling time', nBad == 0 && nPulses == numel(P.t_sample_s), ...
    sprintf('mismatching points %d; pulses %d (expected %d); points inside pulses %d', nBad, nPulses, numel(P.t_sample_s), nnz(inPulse)));
events = get_sampling_events(o);
master = readtable(fullfile(root, '03_Data', 'processed', 'dga_master.csv'), setvartype(select_cols(fullfile(root, '03_Data', 'processed', 'dga_master.csv')), {'record_id', 'data_role'}, 'string'));
[tf, loc] = ismember(events.record_id, master.record_id);
roleOK = all(tf) && all(master.data_role(loc(tf)) ~= "development");
idsOK = isequal(events.record_id, P.heldout_record_ids(1:height(events))) && numel(unique(events.record_id)) == height(events) && height(events) == numel(P.t_sample_s);
chk = add(chk, 'the record_ids are the first held-out ids, unique, and exist in dga_master.csv with a role other than development', roleOK && idsOK, ...
    sprintf('%s; roles %s', strjoin(events.record_id.', ', '), strjoin(unique(master.data_role(loc(tf))).', ', ')));
writetable(events, fullfile(here, 'results', 'step37_sampling_events.csv'));

%% 9 regression against the saved Step 36 results -----------------------------------------------------------------------------
S = scenarios();
worst = struct('oil', 0, 'hs', 0, 'K', 0, 'V', 0);  lines9 = strings(0, 1);
for q = 1:numel(S)
    in = Simulink.SimulationInput(mdl);
    in = in.setVariable('load_profile', S(q).profile);
    in = in.setModelParameter('StopTime', num2str(S(q).t_stop_s));
    in = in.setModelParameter('RelTol', '1e-3');   % tolerance of the saved results, so that only the effect of SS8 is compared
    r = sim(in);
    L = load(fullfile(here, 'results', 'before_step37', ['sim_' S(q).id '.mat']));  old = L.run;
    [~, ia, ib] = intersect(r.theta_oil_C.Time, old.t_s);
    dO = max(abs(squeeze(r.theta_oil_C.Data(ia)) - old.theta_oil_C(ib)));
    dH = max(abs(squeeze(r.theta_hs_C.Data(ia)) - old.theta_hs_C(ib)));
    dK = max(abs(squeeze(r.K_pu.Data(ia)) - old.K_pu(ib)));
    dV = max(abs(squeeze(r.ageing_rate_V.Data(ia)) ./ old.ageing_V(ib) - 1));
    worst.oil = max(worst.oil, dO);  worst.hs = max(worst.hs, dH);  worst.K = max(worst.K, dK);  worst.V = max(worst.V, dV);
    lines9(end + 1) = sprintf('%s: %d common points of %d; oil %.4f K, hot-spot %.4f K, K %.1e, V %.2e', S(q).id, numel(ia), numel(old.t_s), dO, dH, dK, dV); %#ok<AGROW>
end
chk = add(chk, 'Step 36 scenarios: same signals as the saved results on common time points (0.01 K; K 1e-4; V 0.12 %)', ...
    worst.oil <= 0.01 && worst.hs <= 0.01 && worst.K <= 1e-4 && worst.V <= 2^(0.01 / 6) - 1, strjoin(lines9, ' | '));

%% 10 Step 33 checks again ---------------------------------------------------------------------------------------------------------
bdclose all;
c33 = verify_step33();
chk = add(chk, 'the nine checks of verify_step33.m pass on the model with SS8', all(c33.passed) && height(c33) == 9, sprintf('%d of %d pass', nnz(c33.passed), height(c33)));

writetable(chk, fullfile(here, 'results', 'step37_checks.csv'));
disp(chk(:, 1:2));  disp(events);
fprintf('%d of %d checks passed.\n', nnz(chk.passed), height(chk));
bdclose all;
end

function chk = add(chk, n, p, d)
chk = [chk; table(string(n), logical(p), string(d), 'VariableNames', {'check', 'passed', 'detail'})];
end

function s = joinOrNone(x)
if isempty(x), s = 'none'; else, s = char(strjoin(string(x), ', ')); end
end

function o = select_cols(f)
% Import options that read only record_id and data_role (the test, like the model, does not read any gas column).
o = detectImportOptions(f);  o.SelectedVariableNames = {'record_id', 'data_role'};
end
