function T = verify_step41()
%VERIFY_STEP41  Checks of roadmap Step 41 (end-to-end test bench), decision D39 clause 5.
%
%   T = verify_step41      reads the saved files of run_testbench (logs/testbench_log.csv, testbench_run_info.json); no service call.
%   OUTPUT  results/step41_checks.csv
%   The comparison with the offline predictions (fidelity) and the response-time statistics are Step 42, not done here.
%   Written 13 Oct 2026 for MATLAB R2025b.

here = fileparts(mfilename('fullpath'));  root = fileparts(here);
resDir = fullfile(here, 'results');  if ~isfolder(resDir), mkdir(resDir); end
chk = struct('check', {}, 'passed', {}, 'detail', {});
add = @(c, name, ok, det) [c, struct('check', name, 'passed', logical(ok), 'detail', char(det))];

L = readtable(fullfile(here, 'logs', 'testbench_log.csv'), 'TextType', 'string');
info = jsondecode(fileread(fullfile(here, 'logs', 'testbench_run_info.json')));
M = readtable(fullfile(root, '03_Data', 'processed', 'dga_master.csv'), 'TextType', 'string');
held = M(M.data_role ~= "development", :);
n = height(held);
classes = ["Normal" "PD" "D1" "D2" "T1" "T2" "T3"];  P = L{:, "p_" + classes};

chk = add(chk, 'one log row per held-out record, in file order, no record twice', height(L) == n && isequal(L.record_id, held.record_id) && numel(unique(L.record_id)) == n, ...
    sprintf('%d rows; %d held-out records in dga_master.csv', height(L), n));
roles = ["benchmark" "internal_test" "external_test"];
chk = add(chk, 'data_role in the log equals the role in dga_master.csv (benchmark 117, internal_test 70, external_test 201)', isequal(L.data_role, held.data_role) && isequal(arrayfun(@(r) sum(L.data_role == r), roles), [117 70 201]), ...
    strjoin(compose("%s %d", roles', arrayfun(@(r) sum(L.data_role == r), roles)'), ', '));
chk = add(chk, 'sampling events at the bench schedule (record k at k x 15 min), in order', all(abs(L.sim_time_h - (1:n)' * info.schedule.interval_h) < 1e-6) && isequal(L.event, (1:n)'), ...
    sprintf('first %.2f h, last %.2f h, stop time %.0f h', L.sim_time_h(1), L.sim_time_h(end), info.schedule.stop_time_h));
errTxt = string(L.error);
okCalls = all(L.ml_status == "OK") && all(ismissing(errTxt) | strlength(errTxt) == 0) && info.n_failed == 0;
chk = add(chk, 'no failed calls: every status OK, no error text', okCalls, sprintf('%d OK of %d; n_failed in run info %d', sum(L.ml_status == "OK"), height(L), info.n_failed));
okVals = ~any(ismissing(L.ml_class)) && all(ismember(L.ml_class, classes)) && ~any(isnan(P), 'all') && all(abs(sum(P, 2) - 1) < 1e-9) && all(abs(L.confidence - max(P, [], 2)) < 1e-12) ...
         && ~any(ismissing(L.rogers)) && ~any(ismissing(L.iec60599)) && ~any(ismissing(L.duval));
chk = add(chk, 'every row has the ML class, seven probabilities that sum to 1, the confidence, and the three conventional answers', okVals, sprintf('%d rows checked', height(L)));
okT = all(isfinite(L.response_ms) & L.response_ms > 0) && all(isfinite(L.conventional_ms) & L.conventional_ms > 0) && all(L.total_ms >= L.response_ms);
chk = add(chk, 'response, conventional and total times are present, positive, and total >= response', okT, sprintf('response %.0f to %.0f ms', min(L.response_ms), max(L.response_ms)));
chk = add(chk, 'the first 5 calls (and only they) are marked as warm-up', isequal(find(L.warmup)', 1:5), sprintf('%d marked', sum(L.warmup)));
g = [held.H2 held.CH4 held.C2H6 held.C2H4 held.C2H2];
chk = add(chk, 'the gas values in the log are those of the file rows (read, never created)', isequal([L.H2 L.CH4 L.C2H6 L.C2H4 L.C2H2], g), sprintf('%d x 5 values', n));
hb = info.health_before;  ha = info.health_after;
acc = fileread(fullfile(root, '11_Results', 'ml', 'test_set_access.log'));  tok = regexp(acc, 'final_pipeline\.joblib SHA-256 ([0-9A-F]{64})', 'tokens', 'once');
okM = hb.status == "ok" && ha.status == "ok" && string(hb.model_sha256) == string(ha.model_sha256) && all(L.model_sha256 == string(hb.model_sha256)) && ~isempty(tok) && string(hb.model_sha256) == string(tok{1}) ...
      && all(L.model_name == "dga_model_v1") && all(str2double(string(L.model_version)) == 1);
chk = add(chk, 'service healthy before and after; the model hash is the same in both, in every row, and equals the saved model of Step 22', okM, extractBefore(string(hb.model_sha256), 13) + "...");
chk = add(chk, 'the model file is unchanged by the bench (checksum before = after)', string(info.model_file_checksum_before) == string(info.model_file_checksum_after), string(info.model_file_checksum_after));
labelCols = ["class_name" "class_code" "class_merged" "original_label" "inspection" "iec_ref" "true_class" "label"];
chk = add(chk, 'the log holds no true label of any record', ~any(ismember(labelCols, string(L.Properties.VariableNames))), 'no label column');
okA = all(L.agreement_count >= 0 & L.agreement_count <= 3) && all((L.agreement_state == "green") == (L.agreement_count == 3)) && all(ismember(L.agreement_state, ["green" "amber"]));
chk = add(chk, 'agreement count 0 to 3 and state consistent (green only when all three agree)', okA, sprintf('green %d, amber %d', sum(L.agreement_state == "green"), sum(L.agreement_state == "amber")));

T = struct2table(chk);
fprintf('%d of %d checks passed.\n', sum(T.passed), height(T));
writetable(T, fullfile(resDir, 'step41_checks.csv'));
end
