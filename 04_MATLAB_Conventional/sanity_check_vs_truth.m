function T = sanity_check_vs_truth()
%SANITY_CHECK_VS_TRUTH  Plausibility check of the three methods against the true class (NOT a result).
%
%   T = sanity_check_vs_truth()
%
%   PURPOSE
%     After Step 16 the question "do the implementations behave plausibly?" is answered by comparing the
%     RAW output of each method (before the normality gate) with the inspection-confirmed class of the
%     IEC TC 10 benchmark records, on the 5 merged classes PD, D1, D2, T12, T3 (the plan's main benchmark).
%     This is an implementation check only. The formal evaluation (macro-F1, confidence intervals, tests,
%     normality gate, ND handling, the primary 58-record subset) is done in later roadmap steps and may
%     differ. Nothing here is a thesis result.
%
%   SCORING USED HERE (simple, for plausibility only)
%     T1 and T2 -> T12 (merged). A dual answer (D1/D2) is correct if the true class is either part.
%     DT and ND are counted as wrong.  Only records with a true class other than Normal are scored.
%
%   OUTPUT  T  table: method, n_scored, n_correct, share_correct, n_ND, n_DT, n_dual
%   Written to 11_Results/conventional/sanity_agreement_benchmark.csv.
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 16 (check).

C = conv_config();
verify_data_version('Quiet', true);
M = readtable(C.masterFile, 'TextType', 'string');
sel = M.data_role == "benchmark";
M = M(sel, :);
g = struct('H2', M.H2, 'CH4', M.CH4, 'C2H6', M.C2H6, 'C2H4', M.C2H4, 'C2H2', M.C2H2, 'equipment_type', M.equipment_type);
d = conventional_diagnosis(g);
truth = M.class_merged;
raw = {d.raw.iec, d.raw.rogers, d.raw.duval};
names = ["IEC60599" "Rogers" "Duval"];
cols = {'method', 'n_scored', 'n_correct', 'share_correct', 'n_ND', 'n_DT', 'n_dual'};
rows = cell(numel(names), 0);
for m = 1:numel(names)
    n = numel(truth);  ok = false(n, 1);
    for i = 1:n
        parts = split(raw{m}(i), "/");
        parts(parts == "T1" | parts == "T2") = "T12";
        ok(i) = any(parts == truth(i));
    end
    rows(m, 1:numel(cols)) = {names(m), n, nnz(ok), nnz(ok) / n, nnz(raw{m} == "ND"), nnz(raw{m} == "DT"), nnz(contains(raw{m}, "/"))};
end
T = cell2table(rows, 'VariableNames', cols);
writetable(T, fullfile(C.outDir, 'sanity_agreement_benchmark.csv'));
disp(T);
end
