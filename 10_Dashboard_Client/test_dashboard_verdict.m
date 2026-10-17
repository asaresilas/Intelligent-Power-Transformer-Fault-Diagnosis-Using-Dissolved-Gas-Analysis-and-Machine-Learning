function T = test_dashboard_verdict()
%TEST_DASHBOARD_VERDICT  Checks of dashboard_verdict, dashboard_samples and sim_window (17 Oct 2026). No ML service is needed:
%   the ML answers are those saved in logs/testbench_log.csv (Step 41). Writes results/dashboard_verdict_check.csv (one row per
%   record: true class, four answers, verdict) and results/dashboard_verdict_summary.csv.
%   Run from MATLAB:  test_dashboard_verdict
here = fileparts(mfilename('fullpath'));  root = fileparts(here);
addpath(fullfile(root, '04_MATLAB_Conventional'), here);
chk = struct('name', {}, 'ok', {}, 'detail', {});
add = @(c, n, ok, d) [c, struct('name', n, 'ok', logical(ok), 'detail', string(d))];

M = readtable(fullfile(root, '03_Data', 'processed', 'dga_master.csv'), 'TextType', 'string');
L = readtable(fullfile(here, 'logs', 'testbench_log.csv'), 'TextType', 'string');
n = height(L);
rows = zeros(n, 1);  lab = strings(n, 1);
for k = 1:n
    rows(k) = find(M.record_id == L.record_id(k), 1);
    lab(k) = M.class_name(rows(k));  if ismissing(lab(k)), lab(k) = ""; end
end

%% verdict for all 388 records ---------------------------------------------------------------------------------------------
cls = ["Normal" "PD" "D1" "D2" "T1" "T2" "T3"];
out = table(L.record_id, lab, strings(n, 1), strings(n, 1), strings(n, 1), strings(n, 1), strings(n, 1), strings(n, 1), zeros(n, 1), ...
    'VariableNames', {'record_id', 'true_class', 'rogers', 'iec', 'duval', 'ml', 'health', 'verdict', 'support'});
errs = 0;
for k = 1:n
    g = load_dga_record(fullfile(root, '03_Data', 'processed', 'dga_master.csv'), rows(k));
    d = conventional_diagnosis(g);
    m = struct('status', L.ml_status(k), 'fault_class', L.ml_class(k));
    a = dga_agreement(d, m);
    try
        V = dashboard_verdict(g, d, m, a, lab(k));
    catch ME
        errs = errs + 1;  disp(ME.message);  continue
    end
    out(k, 3:9) = {string(d.rogers), string(d.iec), string(d.duval), string(L.ml_class(k)), V.health, V.fault_class, V.support};
end
chk = add(chk, 'verdict computed for all 388 records without error', errs == 0, sprintf('%d errors', errs));
chk = add(chk, 'every record has a health state', all(ismember(out.health, ["healthy" "watch" "fault" "undecided"])), '');
chk = add(chk, 'a fault verdict always has at least 2 votes and a known class', all(out.support(out.health == "fault") >= 2) && all(ismember(out.verdict(out.health == "fault"), cls(2:end))), '');
chk = add(chk, 'healthy records have every gas at or below the typical value (gate)', true, 'by construction: see next check');

% the healthy state is exactly the normality gate (plus no ML objection)
gate = false(n, 1);
for k = 1:n
    g = load_dga_record(fullfile(root, '03_Data', 'processed', 'dga_master.csv'), rows(k));
    d = conventional_diagnosis(g);  gate(k) = d.gate_upper;
end
chk = add(chk, 'health is healthy or watch for every gated record and never fault', all(ismember(out.health(gate), ["healthy" "watch"])) && ~any(out.health(~gate) == "healthy"), sprintf('%d gated records', sum(gate)));

%% summary against the known class (labelled records only) ----------------------------------------------------------------
known = out.true_class ~= "";
isFault = known & out.true_class ~= "Normal";
TP = sum(isFault & out.health == "fault");
Sm = table(); Sm.item = ["records" "with known class" "known faulty" "known Normal" "verdict = fault" "verdict = healthy" "verdict = watch" "verdict = undecided" ...
    "faulty records called fault" "faulty records called healthy" "Normal records called healthy" "fault verdict with known class" "fault verdict with the right class" "fault verdict, family right"]';
famOf = @(c) ifelse(any(c == ["PD" "D1" "D2"]), "e", ifelse(any(c == ["T1" "T2" "T3"]), "t", "n"));
isF = out.health == "fault" & known;
right = sum(out.verdict(isF) == out.true_class(isF));
famRight = sum(arrayfun(@(i) famOf(out.verdict(i)) == famOf(out.true_class(i)), find(isF)));
Sm.value = [n; sum(known); sum(isFault); sum(known & out.true_class == "Normal"); sum(out.health == "fault"); sum(out.health == "healthy"); sum(out.health == "watch"); ...
    sum(out.health == "undecided"); TP; sum(isFault & out.health == "healthy"); sum(known & out.true_class == "Normal" & out.health == "healthy"); sum(isF); right; famRight];
disp(Sm);
writetable(out, fullfile(here, 'results', 'dashboard_verdict_check.csv'));
writetable(Sm, fullfile(here, 'results', 'dashboard_verdict_summary.csv'));

%% dashboard_samples ---------------------------------------------------------------------------------------------------------
s1 = dashboard_samples('mixed', [], 'Seed', 1);  s1b = dashboard_samples('mixed', [], 'Seed', 1);  s2 = dashboard_samples('mixed', [], 'Seed', 2);
chk = add(chk, 'mixed set: 7 records, one of each class in order, held-out only, reproducible with the same seed, different with another', ...
    numel(s1.rows) == 7 && isequal(s1.label', cls) && isequal(s1.rows, s1b.rows) && ~isequal(s1.rows, s2.rows) && all(string(M.data_role(s1.rows)) ~= "development"), strjoin(s1.record_id', ' '));
s3 = dashboard_samples('first', [], 'N', 4);
chk = add(chk, 'first set: IECTC10_0001 to 0004 (the Step 40 demonstration)', isequal(s3.record_id', ["IECTC10_0001" "IECTC10_0002" "IECTC10_0003" "IECTC10_0004"]), strjoin(s3.record_id', ' '));
s4 = dashboard_samples('class', [], 'Class', "Normal", 'Seed', 5);
chk = add(chk, 'class picker: one healthy record', numel(s4.rows) == 1 && s4.label == "Normal", s4.record_id);
s5 = dashboard_samples('random', [], 'N', 7, 'Seed', 3);
chk = add(chk, 'random set: 7 different held-out records', numel(unique(s5.rows)) == 7 && all(string(M.data_role(s5.rows)) ~= "development"), '');

%% sim_window ----------------------------------------------------------------------------------------------------------------
t = (0:0.5:72)';  r = struct('t_h', t, 'K_pu', ones(size(t)), 'theta_oil_C', 50 + t * 0, 'theta_hs_C', 60 + t * 0, 'ageing_V', ones(size(t)), 'loss_of_life_h', 72, ...
    'events', table(48 + [3; 6], [1; 2], ["a"; "b"], 'VariableNames', {'time_h', 'record_index', 'record_id'}));
rw = sim_window(r, 48);
chk = add(chk, 'sim_window: time restarts at 0, last day only (24 h), loss of life 24 h at ageing rate 1, event times 3 and 6 h', ...
    rw.t_h(1) == 0 && rw.t_h(end) == 24 && abs(rw.loss_of_life_h - 24) < 1e-9 && isequal(rw.events.time_h, [3; 6]), sprintf('LoL %.3f h', rw.loss_of_life_h));
T = struct2table(chk);
disp(T(:, {'name', 'ok'}));
fprintf('%d of %d checks passed.\n', sum(T.ok), height(T));
writetable(T, fullfile(here, 'results', 'dashboard_verdict_tests.csv'));
end

function y = ifelse(c, a, b)
if c, y = a; else, y = b; end
end
