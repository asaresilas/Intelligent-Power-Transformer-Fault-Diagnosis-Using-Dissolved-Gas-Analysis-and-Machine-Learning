function S = dashboard_samples(kind, file, varargin)
%DASHBOARD_SAMPLES  Choose which measured records the dashboard shows (17 Oct 2026).
%
%   S = dashboard_samples(kind, file)
%   S = dashboard_samples(kind, file, 'N', 7, 'Seed', 1, 'Class', "D2")
%
%   kind   "mixed"   one record of EACH known class Normal, PD, D1, D2, T1, T2, T3 (in this order), picked at random from the
%                    held-out records with a fixed Seed, so the same Seed always gives the same records
%          "random"  N held-out records picked at random (Seed)
%          "first"   the first N held-out records in file order (the Step 40 demonstration)
%          "class"   ONE random held-out record of the given 'Class' ("Normal" = healthy); "" or "All" = any class
%   file   DGA file (default: 03_Data/processed/dga_master.csv). Held-out = data_role is not "development" (as in params_transformer.m).
%          A file without the columns record_id / data_role / class_name is accepted: every row counts, no class is known.
%
%   OUTPUT  S  struct  rows (Nx1 row numbers in the file), record_id (Nx1 string, "" if the file has none),
%                      label (Nx1 string, known class or "" if unknown)
%   Only record numbers and labels are chosen here. The gas values are read later, as they are, from the file.
%   Project: MPhil, DGA transformer fault diagnosis - dashboard redesign.

p = inputParser;
addParameter(p, 'N', 7);  addParameter(p, 'Seed', 1);  addParameter(p, 'Class', "");
parse(p, varargin{:});
n = p.Results.N;  seed = p.Results.Seed;  cls = string(p.Results.Class);
if nargin < 2 || isempty(file), file = conv_config().masterFile; end

T = readtable(file, 'TextType', 'string');
nrow = height(T);
rid = strings(nrow, 1);  if ismember('record_id', T.Properties.VariableNames), rid = string(T.record_id); end
lab = strings(nrow, 1);
if ismember('class_name', T.Properties.VariableNames)
    lab = string(T.class_name);  lab(ismissing(lab)) = "";
end
pool = true(nrow, 1);
if ismember('data_role', T.Properties.VariableNames), pool = string(T.data_role) ~= "development"; end
poolRows = find(pool);
rs = RandStream('mt19937ar', 'Seed', seed);

switch lower(string(kind))
    case "mixed"
        want = ["Normal" "PD" "D1" "D2" "T1" "T2" "T3"];  rows = zeros(0, 1);
        for c = want
            cand = poolRows(lab(poolRows) == c);
            if ~isempty(cand), rows(end + 1, 1) = cand(randi(rs, numel(cand))); end %#ok<AGROW>
        end
    case "random"
        n = min(n, numel(poolRows));
        rows = poolRows(randperm(rs, numel(poolRows), n));
    case "first"
        rows = poolRows(1:min(n, numel(poolRows)));
    case "class"
        cand = poolRows;
        if cls ~= "" && lower(cls) ~= "all", cand = poolRows(lab(poolRows) == cls); end
        if isempty(cand), rows = zeros(0, 1); else, rows = cand(randi(rs, numel(cand))); end
    otherwise
        error('dashboard_samples:kind', 'Unknown kind "%s".', string(kind));
end
rows = rows(:);
S = struct('rows', rows, 'record_id', rid(rows), 'label', lab(rows));
end
