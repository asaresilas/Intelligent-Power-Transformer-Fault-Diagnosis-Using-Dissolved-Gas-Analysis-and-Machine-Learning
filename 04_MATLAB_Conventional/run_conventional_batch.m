function [P, counts] = run_conventional_batch(varargin)
%RUN_CONVENTIONAL_BATCH  Apply the three conventional methods to every record of the frozen master table.
%
%   [P, counts] = run_conventional_batch()                  compute, write the CSV files, return tables
%   [P, counts] = run_conventional_batch('Write', false)    compute only (used by the unit tests)
%
%   STEPS
%     1. verify_data_version()  - recompute the SHA-256 of all 16 frozen files; stop if any differs.
%     2. Read 03_Data/processed/dga_master.csv (five gases in ppm; not detected = 0 ppm, decision D8).
%     3. conventional_diagnosis() on all records at once.
%     4. Build ONE ROW PER RECORD AND METHOD and write
%          11_Results/conventional/conventional_predictions.csv   (Step 16)
%          11_Results/conventional/conventional_counts.csv        (ND, DT, dual answers per method and data role)
%
%   OUTPUT  P  table with columns
%     record_id, method (IEC60599 | Rogers | Duval),
%     gate_upper, gate_lower   "Normal" when the gate is passed, otherwise blank,
%     raw_result               class, dual answer (D1/D2), DT or ND, BEFORE the gate,
%     result                   after the UPPER gate ("Normal" if gate_upper, otherwise raw_result),
%     ratio_R1, ratio_R2, ratio_R5   (NaN = undefined; blank for Duval rows),
%     pct_CH4, pct_C2H4, pct_C2H2    (Duval percentages; blank for the ratio methods),
%     boundary_distance          decades (IEC, Rogers) or percentage points (Duval),
%     data_version               "1.0".
%     The specification lists "ratio_R1, ratio_R2, ratio_R5 (or pct_CH4, pct_C2H4, pct_C2H2 for Duval)";
%     both groups are written so that one file serves all methods; the unused group is blank.
%
%           counts  table: method, data_role (and "all"), n, n_gate_upper, n_gate_lower, and the numbers of
%                   ND, DT, D1/D2 and PD/T1 results after the gate (*_final) and before it (*_raw);
%                   the PD/T1 columns are kept for transparency and are 0 since decision D13
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 16 (function prepared in Step 14).

p = inputParser;
addParameter(p, 'Write', true);
parse(p, varargin{:});
C = conv_config();

verify_data_version();                                     % rule 2: stop if any frozen file changed

M = readtable(C.masterFile, 'TextType', 'string');
N = height(M);
g = struct('H2', M.H2, 'CH4', M.CH4, 'C2H6', M.C2H6, 'C2H4', M.C2H4, 'C2H2', M.C2H2, ...
    'equipment_type', M.equipment_type);
d = conventional_diagnosis(g);

methods_ = ["IEC60599" "Rogers" "Duval"];
raw  = {d.raw.iec, d.raw.rogers, d.raw.duval};
res  = {d.iec, d.rogers, d.duval};
bnd  = {d.boundary.iec, d.boundary.rogers, d.boundary.duval};
nanCol = NaN(N, 1);
P = table();
for m = 1:3
    isDuval = (m == 3);
    gu = repmat("", N, 1);  gu(d.gate_upper) = "Normal";
    gl = repmat("", N, 1);  gl(d.gate_lower) = "Normal";
    Tm = table(M.record_id, repmat(methods_(m), N, 1), gu, gl, raw{m}, res{m}, ...
        pick(~isDuval, d.ratios.R1, nanCol), pick(~isDuval, d.ratios.R2, nanCol), pick(~isDuval, d.ratios.R5, nanCol), ...
        pick(isDuval, d.ratios.pct_CH4, nanCol), pick(isDuval, d.ratios.pct_C2H4, nanCol), pick(isDuval, d.ratios.pct_C2H2, nanCol), ...
        bnd{m}, repmat(C.dataVersion, N, 1), ...
        'VariableNames', {'record_id', 'method', 'gate_upper', 'gate_lower', 'raw_result', 'result', ...
        'ratio_R1', 'ratio_R2', 'ratio_R5', 'pct_CH4', 'pct_C2H4', 'pct_C2H2', 'boundary_distance', 'data_version'});
    Tm.idx = (1:N).';                                      % keeps the master-table order for interleaving
    Tm.m = repmat(m, N, 1);
    P = [P; Tm]; %#ok<AGROW>
end
P = sortrows(P, {'idx', 'm'});                             % record by record: IEC60599, Rogers, Duval
P = removevars(P, {'idx', 'm'});

% ---- counts per method and data role ---------------------------------------------------------------
% "final" = after the upper normality gate (column result); "raw" = before the gate (column raw_result).
% A gated sample becomes "Normal", so the final counts of ND / DT / dual answers are <= the raw counts.
roles = unique(M.data_role, 'stable');
rows = {};
for m = 1:3
    for k = 0:numel(roles)
        if k == 0, sel = true(N, 1); rname = "all"; else, sel = (M.data_role == roles(k)); rname = roles(k); end
        f = res{m}(sel);  w = raw{m}(sel);
        rows(end + 1, :) = {methods_(m), rname, nnz(sel), nnz(d.gate_upper(sel)), nnz(d.gate_lower(sel)), ...
            nnz(f == "ND"), nnz(f == "DT"), nnz(f == "D1/D2"), nnz(f == "PD/T1"), ...
            nnz(w == "ND"), nnz(w == "DT"), nnz(w == "D1/D2"), nnz(w == "PD/T1")}; %#ok<AGROW>
    end
end
counts = cell2table(rows, 'VariableNames', {'method', 'data_role', 'n', 'n_gate_upper', 'n_gate_lower', ...
    'ND_final', 'DT_final', 'D1D2_final', 'PDT1_final', 'ND_raw', 'DT_raw', 'D1D2_raw', 'PDT1_raw'});

if p.Results.Write
    if ~isfolder(C.outDir), mkdir(C.outDir); end
    writetable(P, fullfile(C.outDir, 'conventional_predictions.csv'));
    writetable(counts, fullfile(C.outDir, 'conventional_counts.csv'));
    fprintf('Wrote %d rows (%d records x 3 methods) to %s\n', height(P), N, C.outDir);
end
end

function v = pick(useIt, x, blank)
% Column x when this method uses it, otherwise a blank (NaN) column.
if useIt, v = x; else, v = blank; end
end
