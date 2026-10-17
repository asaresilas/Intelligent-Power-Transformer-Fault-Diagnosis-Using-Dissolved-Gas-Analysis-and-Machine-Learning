function [label, matchMat, classes] = diagnose_ratio_method(R, rows)
%DIAGNOSE_RATIO_METHOD  Apply a ratio code table (IEC 60599 Table 2 or Rogers Table 6) to gas ratios.
%
%   [label, matchMat, classes] = diagnose_ratio_method(R, rows)
%
%   INPUT   R     N-by-3 array [R1 R2 R5] (NaN = undefined ratio, i.e. zero denominator)
%           rows  table S.iec.rows or S.rogers.rows from load_standards (one row per class and ratio)
%   OUTPUT  label     N-by-1 string: the class, a dual answer, or "ND"
%           matchMat  N-by-K logical: which of the K classes matched each sample
%           classes   1-by-K string: class labels in table order
%
%   RULES
%     * A class matches when EVERY ratio the table USES for that class (bound_type not ns)
%       is defined and inside its interval. Ratios the standard marks "NS" (not significant) are not
%       used, so an undefined NS ratio does not stop the class from matching.
%       This is decision D12 (researcher, 2026-10-11), an amendment of the last rule of D11 which
%       gave "ND" whenever ANY ratio was undefined (35 of 827 records are affected, see the Step 14 report).
%     * No class matches            -> "ND" (no diagnosis). ND is a result and is never removed.
%     * Several classes match       -> the labels joined with "/" in table order, for example
%       "D1/D2" (IEC dual attribution, D11 rule 4). PD and T1 no longer overlap since decision D13 (T1 requires
%       CH4/H2 > 1, so PD, which needs CH4/H2 < 0.1, is a separate answer). For Rogers no two cases overlap
%       (checked by the unit tests), so the result is always a single case or "ND".
%
%   SOURCES  IEC 60599:1999+A1:2007 Table 2 p.11 and clause 5.3; IEEE Std C57.104-2008 Table 6 p.16.
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 14.

C = conv_config();
N = size(R, 1);
classes = unique(rows.cls, 'stable').';
K = numel(classes);
matchMat = false(N, K);
for k = 1:K
    rk = rows(rows.cls == classes(k), :);
    used = rk(~rk.ignored, :);          % "ns" rows are not used; "gt_but_ns" is used (D13)
    if isempty(used)
        error('diagnose_ratio_method:noRatio', 'Class %s uses no ratio.', classes(k));
    end
    ok = true(N, 1);
    for i = 1:height(used)
        j = find(C.ratioIds == used.rid(i), 1);
        ok = ok & bound_test(R(:, j), used.bound_type(i), used.lower(i), used.upper(i));
    end
    matchMat(:, k) = ok;
end
label = repmat("ND", N, 1);
for n = 1:N
    if any(matchMat(n, :))
        label(n) = strjoin(classes(matchMat(n, :)), "/");
    end
end
end
