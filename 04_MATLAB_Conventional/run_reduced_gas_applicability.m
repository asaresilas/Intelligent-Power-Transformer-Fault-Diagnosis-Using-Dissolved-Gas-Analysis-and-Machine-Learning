function [T, chk] = run_reduced_gas_applicability(varargin)
%RUN_REDUCED_GAS_APPLICABILITY  Conventional methods with gases removed: how often do they answer ND? (Roadmap Step 26)
%
%   [T, chk] = run_reduced_gas_applicability()                 compute, write the CSV files, return tables
%   [T, chk] = run_reduced_gas_applicability('Write', false)   compute only (used by the unit tests)
%
%   INPUTS
%     03_Data/processed/dga_master.csv                (data version 1.0, verified first; 827 records, 5 gases in ppm)
%     11_Results/reduced_gas/reduced_gas_subsets.csv  (31 gas combinations, columns has_H2 ... has_C2H2; Step 25)
%
%   WHAT IT DOES (rule of decision D23, proposed; details in reduced_gas_diagnosis.m)
%     For every combination and every method (IEC 60599, Rogers, Duval Triangle 1) the removed gases are set to NaN
%     (not measured, NOT 0 ppm). A method that needs a removed gas returns ND for every record; otherwise the method is
%     run exactly as in Steps 14-17. The numbers of ND results are counted over all 827 records and per data role.
%
%   OUTPUT  T  table, one row per combination x method x data role (31 x 3 x 5 = 465 rows)
%     columns required by the roadmap:
%       subset_id, n_gases, method, applicable (1/0), data_role (all, development, internal_test, benchmark,
%       external_test), n_records, n_nd, share_nd
%     extra columns (kept after the required ones):
%       n_diagnosed       records with any answer other than ND (a class, Normal, DT or the dual answer D1/D2)
%       n_nd_raw          ND before the normality gate (= n_nd unless the gate turned an ND record into Normal)
%       n_nd_gate_measured  SENSITIVITY: n_nd if the gate were evaluated on the measured gases only (see rule 4 of
%                         reduced_gas_diagnosis.m); n_nd is the primary number
%     ND counts are AFTER the upper normality gate (like ND_final in conventional_counts.csv).
%
%           chk  table of the automatic checks (name, passed, detail); also written as CSV. An error is raised when a
%                check fails, so a wrong table is never saved without notice.
%
%   FILES WRITTEN  11_Results/conventional/conventional_applicability.csv
%                  11_Results/conventional/conventional_applicability_checks.csv
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 26.

p = inputParser;
addParameter(p, 'Write', true);
parse(p, varargin{:});
C = conv_config();
verify_data_version('Quiet', true);                       % stop if any frozen file changed

% ---- records ---------------------------------------------------------------------------------------
M = readtable(C.masterFile, 'TextType', 'string');
N = height(M);
g = struct('H2', M.H2, 'CH4', M.CH4, 'C2H6', M.C2H6, 'C2H4', M.C2H4, 'C2H2', M.C2H2, 'equipment_type', M.equipment_type);
roleList = ["all" C.roles];

% ---- gas combinations (Step 25 file), validated before use ------------------------------------------
subsetFile = fullfile(C.root, '11_Results', 'reduced_gas', 'reduced_gas_subsets.csv');
Sb = readtable(subsetFile, 'TextType', 'string');
hasCols = "has_" + C.gas;
H = false(height(Sb), numel(C.gas));
for j = 1:numel(C.gas)
    H(:, j) = as_logical(Sb.(hasCols(j)));
end
nGasStated = Sb.n_gases;
chk = table();
nSub = 2^numel(C.gas) - 1;                                % every non-empty combination of the five gases
chk = add_check(chk, 'subsets: every non-empty combination once (2^5 - 1 = 31), all different', height(Sb) == nSub && size(unique(H, 'rows'), 1) == height(Sb), ...
    sprintf('%d rows', height(Sb)));
chk = add_check(chk, 'subsets: none empty, n_gases = number of gases kept', all(sum(H, 2) >= 1) && all(sum(H, 2) == nGasStated), ...
    'n_gases column equals the row sum of has_*');
idOk = true;
for i = 1:height(Sb)                                      % id = gases joined by "+" in the order of conv_config().gas
    idOk = idOk && (Sb.subset_id(i) == strjoin(C.gas(H(i, :)), "+"));
end
chk = add_check(chk, 'subsets: subset_id matches the gases kept', idOk, 'id = gas names joined by "+", in H2, CH4, C2H6, C2H4, C2H2 order');

% ---- run -------------------------------------------------------------------------------------------
methodName = ["IEC60599" "Rogers" "Duval"];
methodKey  = ["iec" "rogers" "duval"];
rows = {};                                                % one row per combination x method x role
store = struct();                                         % results per subset, kept for the checks
for i = 1:height(Sb)
    present = C.gas(H(i, :));
    d = reduced_gas_diagnosis(g, present);
    store(i).id = Sb.subset_id(i);  store(i).d = d;
    for m = 1:3
        key = methodKey(m);
        fin  = d.(key);  raw = d.raw.(key);  alt = d.final_on_measured.(key);
        for r = 1:numel(roleList)
            if roleList(r) == "all", sel = true(N, 1); else, sel = (M.data_role == roleList(r)); end
            nRec = nnz(sel);
            nNd  = nnz(fin(sel) == "ND");
            rows(end + 1, :) = {Sb.subset_id(i), nGasStated(i), methodName(m), double(d.applicable.(key)), roleList(r), nRec, nNd, ...
                nNd / nRec, nRec - nNd, nnz(raw(sel) == "ND"), nnz(alt(sel) == "ND")}; %#ok<AGROW>
        end
    end
end
T = cell2table(rows, 'VariableNames', {'subset_id', 'n_gases', 'method', 'applicable', 'data_role', 'n_records', 'n_nd', ...
    'share_nd', 'n_diagnosed', 'n_nd_raw', 'n_nd_gate_measured'});

% ---- checks (roadmap) ------------------------------------------------------------------------------
% (1) a method that needs a removed gas gives ND for 100 % of the records, in every role
bad = T(T.applicable == 0 & T.share_nd ~= 1, :);
chk = add_check(chk, 'not applicable -> ND for 100 % of records (all roles)', isempty(bad), sprintf('%d offending rows', height(bad)));
% (2) the applicability flag agrees with the Step 25 file (derived there independently from the same rule)
if all(ismember({'iec_rogers_applicable', 'duval_available'}, Sb.Properties.VariableNames))
    okFlag = true;
    for i = 1:height(Sb)
        a = T.applicable(T.subset_id == Sb.subset_id(i) & T.data_role == "all");
        mm = T.method(T.subset_id == Sb.subset_id(i) & T.data_role == "all");
        okFlag = okFlag && all(a(mm == "IEC60599") == as_logical(Sb.iec_rogers_applicable(i))) ...
                        && all(a(mm == "Rogers") == as_logical(Sb.iec_rogers_applicable(i))) ...
                        && all(a(mm == "Duval") == as_logical(Sb.duval_available(i)));
    end
    chk = add_check(chk, 'applicability agrees with iec_rogers_applicable / duval_available of Step 25', okFlag, 'all 31 combinations');
end
% (3) five-gas combination reproduces conventional_counts.csv (Steps 14-17): ND_final per method and role
K = readtable(fullfile(C.outDir, 'conventional_counts.csv'), 'TextType', 'string');
five = Sb.subset_id(sum(H, 2) == numel(C.gas));
okFive = true;  detail = "";
for m = 1:3
    for r = 1:numel(roleList)
        a = T.n_nd(T.subset_id == five & T.method == methodName(m) & T.data_role == roleList(r));
        b = K.ND_final(K.method == methodName(m) & K.data_role == roleList(r));
        if ~isequal(a, b), okFive = false; detail = detail + sprintf('%s/%s: %d vs %d; ', methodName(m), roleList(r), a, b); end
    end
end
chk = add_check(chk, 'five-gas row reproduces conventional_counts.csv (ND_final, 3 methods x 5 roles)', okFive, char(detail));
% (4) Duval needs only CH4, C2H4, C2H2: every combination that keeps them has the same RAW ND as the five-gas Duval
%     (the gate cannot declare Normal with a gas missing, rule 4, so the final ND equals the raw ND there)
isDuvalSet = all(H(:, ismember(C.gas, C.duvalGas)), 2);
okDuval = true;  detail = "";
for r = 1:numel(roleList)
    ref = K.ND_raw(K.method == "Duval" & K.data_role == roleList(r));
    for i = find(isDuvalSet & sum(H, 2) < numel(C.gas)).'
        a = T.n_nd(T.subset_id == Sb.subset_id(i) & T.method == "Duval" & T.data_role == roleList(r));
        if a ~= ref, okDuval = false; detail = detail + sprintf('%s/%s: %d vs %d; ', Sb.subset_id(i), roleList(r), a, ref); end
    end
end
chk = add_check(chk, 'Duval with CH4, C2H4, C2H2 kept: ND = five-gas Duval ND_raw (all roles)', okDuval, char(detail));
% (5) no combination other than five gases can ever return "Normal" (rule 4)
anyNormal = false;
for i = 1:numel(store)
    if sum(H(i, :)) < numel(C.gas)
        for key = methodKey
            anyNormal = anyNormal || any(store(i).d.(key) == "Normal");
        end
    end
end
chk = add_check(chk, 'no "Normal" result when a gas is missing', ~anyNormal, 'gate needs all five gases (D23 rule 4)');
% (6) bookkeeping
chk = add_check(chk, 'table: combinations x methods x roles rows, shares in [0,1], n_nd + n_diagnosed = n_records', ...
    height(T) == nSub * numel(methodName) * numel(roleList) && all(T.share_nd >= 0 & T.share_nd <= 1) && all(T.n_nd + T.n_diagnosed == T.n_records), sprintf('%d rows', height(T)));
d1 = T(T.subset_id == Sb.subset_id(1) & T.method == "Duval", :);
chk = add_check(chk, 'role sizes add up (the four roles sum to the number of records = all)', ...
    sum(d1.n_records(ismember(d1.data_role, C.roles))) == N && d1.n_records(d1.data_role == "all") == N, sprintf('N = %d', N));

if p.Results.Write
    if ~isfolder(C.outDir), mkdir(C.outDir); end
    writetable(T, fullfile(C.outDir, 'conventional_applicability.csv'));
    writetable(chk, fullfile(C.outDir, 'conventional_applicability_checks.csv'));
    fprintf('Wrote %d rows (combinations x methods x roles) to %s\n', height(T), C.outDir);
end
fprintf('%d of %d checks passed.\n', nnz(chk.passed), height(chk));
if ~all(chk.passed)
    disp(chk(~chk.passed, :));
    error('run_reduced_gas_applicability:check', 'At least one Step 26 check failed; see the table above.');
end
end

function chk = add_check(chk, name, passed, detail)
% Append one line to the table of checks.
row = table(string(name), logical(passed), string(detail), 'VariableNames', {'check', 'passed', 'detail'});
if isempty(chk), chk = row; else, chk = [chk; row]; end
end

function b = as_logical(x)
% CSV columns written by Python hold True/False; readtable may return logical or text.
if islogical(x), b = x; else, b = lower(string(x)) == "true"; end
end


