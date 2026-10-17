function d = boundary_distance_ratio(R, rows)
%BOUNDARY_DISTANCE_RATIO  Distance of a sample to the nearest ratio limit, in decades (log10 units).
%
%   d = boundary_distance_ratio(R, rows)
%
%   INPUT   R     N-by-3 array [R1 R2 R5] (NaN = undefined ratio)
%           rows  S.iec.rows or S.rogers.rows from load_standards
%   OUTPUT  d     N-by-1 [decades]; NaN when no ratio is defined; Inf when every defined ratio is 0
%
%   EQUATION  (Analysis Plan Eq. 9)
%     dR = min over j, l of | log10(R_j) - log10(L_j,l) |
%   where:
%     j     index of the ratio (R1, R2 or R5); only ratios that are defined (denominator not 0) count
%     l     index of a limit of ratio j in the code table
%     R_j   value of ratio j for the sample (dimensionless)
%     L_j,l limit l of ratio j read from 02_Standards (dimensionless, > 0)
%
%   RULES
%     * The limits are the finite lower and upper values of the rows the method actually USES
%       (bound_type not ns / gt_but_ns): "not significant" entries are not decision limits.
%     * A defined ratio equal to 0 (zero numerator) lies infinitely far from every limit on a log
%       scale, so it contributes Inf; the minimum is then taken over the other ratios.
%     * The distance is computed for every sample with at least one defined ratio, also when the
%       method gives "ND", because Eq. 9 does not depend on the diagnosis.
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 14.

C = conv_config();
N = size(R, 1);
d = NaN(N, 1);
used = rows(~rows.ignored, :);
for j = 1:numel(C.ratioIds)
    u = used(used.rid == C.ratioIds(j), :);
    L = unique([u.lower; u.upper]);
    L = L(~isnan(L));                              % the finite limits of ratio j
    if isempty(L), continue, end
    x = R(:, j);
    dj = min(abs(log10(x) - log10(L.')), [], 2);   % N-by-numel(L) -> min over limits
    dj(isnan(x)) = NaN;                            % undefined ratio: no contribution
    d = min(d, dj, 'omitnan');                     % min over ratios (NaN ignored)
end
end
