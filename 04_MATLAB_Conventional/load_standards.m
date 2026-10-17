function S = load_standards(forceReload)
%LOAD_STANDARDS  Read every decision limit from the frozen CSV files in 02_Standards.
%
%   S = load_standards()          cached after the first call
%   S = load_standards(true)      re-read the files
%
%   PURPOSE
%     The ONLY place where limits enter the MATLAB code (rule 1 of Steps_14-17_MATLAB.md: "Read, never
%     type, limits"). Nothing numeric is typed in the diagnosis functions.
%
%   FILES READ (all part of data version 1.0)
%     iec_ratio_table.csv       IEC 60599:1999+A1:2007 (Ed. 2.1) Table 2, p.11. Only rows whose
%                               source_table is exactly "Table 2" are used; the "simplified scheme"
%                               rows (Table 3) are NOT used (instruction for Step 14).
%     rogers_ratio_table.csv    IEEE Std C57.104-2008 Table 6, p.16 (TO VERIFY against a licensed copy).
%     duval_triangle_zones.csv  Duval Triangle 1, 10 rules (secondary source, TO VERIFY).
%     iec_typical_values.csv    IEC 60599 AMD1:2007 Table A.2 (typical 90 % values) for the normality gate.
%
%   OUTPUT  S  (struct)
%     S.iec.rows, S.rogers.rows  tables with one row per (class, ratio):
%         cls         class label (IEC: PD D1 D2 T1 T2 T3; Rogers: Normal PD D2 T1 T2 T3 by decision D11)
%         caseNo      Rogers case number 0..5 (NaN for IEC)
%         rid         ratio id "R1" "R2" "R5"
%         bound_type  lt | gt | gt_lt | range_endpoints_not_stated | ns | gt_but_ns
%         lower,upper numeric limits (NaN when not printed)
%         ignored     true for bound_type ns ("not significant": not used to decide). "gt_but_ns" (printed ">1 but NS") is USED as
%                     the condition ">" (decision D13: T1 requires CH4/H2 > 1)
%     S.duval.rules              table sorted by rule_order: zone and the min/max of %CH4, %C2H4, %C2H2
%     S.typical                  table: group, gas, low, high (ppm)
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 14.

persistent cache
if nargin < 1, forceReload = false; end
if ~isempty(cache) && ~forceReload
    S = cache; return
end
C = conv_config();

% ---- IEC 60599 Table 2 (ratio method) --------------------------------------------------------------
T = read_csv(fullfile(C.stdDir, 'iec_ratio_table.csv'), {'lower', 'upper'});
T = T(T.source_table == "Table 2", :);                       % simplified-scheme rows excluded
S.iec.rows = ratio_rows(T, C, false);

% ---- Rogers ratios (IEEE C57.104-2008 Table 6) ----------------------------------------------------
T = read_csv(fullfile(C.stdDir, 'rogers_ratio_table.csv'), {'lower', 'upper'});
S.rogers.rows = ratio_rows(T, C, true);

% ---- Duval Triangle 1 ------------------------------------------------------------------------------
numCols = {'rule_order', 'pct_CH4_min', 'pct_CH4_max', 'pct_C2H4_min', 'pct_C2H4_max', 'pct_C2H2_min', 'pct_C2H2_max'};
T = read_csv(fullfile(C.stdDir, 'duval_triangle_zones.csv'), numCols);
T = sortrows(T, 'rule_order');
S.duval.rules = T(:, [{'zone'} numCols]);

% ---- IEC typical values (normality gate) ----------------------------------------------------------
T = read_csv(fullfile(C.stdDir, 'iec_typical_values.csv'), {'low', 'high'});
S.typical = T(:, {'group', 'gas', 'low', 'high'});

cache = S;
end

function T = read_csv(file, numericCols)
% Read a CSV with every column as text except the named numeric columns (blank -> NaN).
% The Rogers file's first column is called "case", a MATLAB keyword; MATLAB renames it and warns.
% The column is read by position, so the warning is switched off for this read only.
w = warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
restoreWarning = onCleanup(@() warning(w));
opts = detectImportOptions(file, 'TextType', 'string');
opts = setvartype(opts, opts.VariableNames, 'string');
opts = setvartype(opts, numericCols, 'double');
textCols = setdiff(opts.VariableNames, numericCols, 'stable');
opts = setvaropts(opts, textCols, 'WhitespaceRule', 'trim');
opts = setvaropts(opts, numericCols, 'TreatAsMissing', {''});
T = readtable(file, opts);
end

function R = ratio_rows(T, C, isRogers)
% Convert a long-format ratio table into the compact row table described above.
n = height(T);
rid = strings(n, 1);
for i = 1:n
    txt = strtrim(regexprep(T.ratio(i), '\s*\(.*\)', ''));   % "C2H2/C2H4 (R2)" -> "C2H2/C2H4"
    if ~isKey(C.ratioText, txt)
        error('load_standards:ratio', 'Unknown ratio label "%s" in row %d.', T.ratio(i), i);
    end
    rid(i) = C.ratioText(txt);
end
if isRogers
    caseNo = str2double(T.(T.Properties.VariableNames{1}));    % first column holds the case number
    cls = C.rogersCaseLabel(caseNo + 1).';                     % D11 rule 5
else
    caseNo = NaN(n, 1);
    cls = T.fault_code;
end
bt = T.bound_type;
known = ["lt" "gt" "gt_lt" "range_endpoints_not_stated" "ns" "gt_but_ns"];
if ~all(ismember(bt, known))
    error('load_standards:bound', 'Unknown bound_type: %s', strjoin(unique(bt(~ismember(bt, known))), ', '));
end
R = table(cls, caseNo, rid, bt, T.lower, T.upper, bt == "ns", ...
    'VariableNames', {'cls', 'caseNo', 'rid', 'bound_type', 'lower', 'upper', 'ignored'});
end
