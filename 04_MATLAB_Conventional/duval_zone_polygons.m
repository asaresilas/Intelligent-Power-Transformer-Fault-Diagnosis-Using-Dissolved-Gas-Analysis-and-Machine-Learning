function Z = duval_zone_polygons(S)
%DUVAL_ZONE_POLYGONS  Convex polygon of every Duval Triangle 1 rule, built from the CSV limits.
%
%   Z = duval_zone_polygons(S)         S = load_standards()
%
%   PURPOSE
%     duval_triangle_zones.csv stores the zones as RULES (min/max of %CH4, %C2H4, %C2H2). For drawing
%     the triangle (Step 17) and for finding the decision edges (boundary distance, Analysis Plan
%     Eq. 10) the same rules are needed as polygons. Each rule is a set of inequalities that are
%     straight lines in the triangle, so its region is a convex polygon: the triangle clipped, one
%     limit at a time, by the half-planes of the rule (Sutherland-Hodgman clipping).
%
%   COORDINATES
%     Polygons are returned in (a, b) = (%C2H4, %C2H2) percentage coordinates; %CH4 = 100 - a - b.
%     The triangle is (a,b) = (0,0) [100 % CH4], (100,0) [100 % C2H4], (0,100) [100 % C2H2].
%     Use duval_xy(a, b, 100) to obtain plane coordinates with side length 100.
%
%   OUTPUT  Z  struct array with fields
%     zone   zone label of the rule (PD T1 T2 T3 DT D1 D2)
%     rule   rule_order of the rule in the CSV file
%     poly   K-by-2 array [a b] of polygon vertices (counter-clockwise), K >= 3
%
%   Rules with an empty region (area below the numerical tolerance C.probeEps^2) are dropped.
%   Consistency of the polygons with the rules (full coverage, no overlap) is tested in the unit tests.
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 14.

C = conv_config();
T = C.pctTotal;
rules = S.duval.rules;
tri = [0 0; T 0; 0 T];
Z = struct('zone', {}, 'rule', {}, 'poly', {});
for k = 1:height(rules)
    P = tri;
    % %CH4 = T - a - b:  CH4 >= m  <=>  a + b <= T - m ;   CH4 < M  <=>  -(a + b) <= M - T
    P = limit(P, rules.pct_CH4_min(k), [ 1  1], @(m) T - m);
    P = limit(P, rules.pct_CH4_max(k), [-1 -1], @(M) M - T);
    % %C2H4 = a:  a >= m  <=>  -a <= -m ;   a < M  <=>  a <= M
    P = limit(P, rules.pct_C2H4_min(k), [-1 0], @(m) -m);
    P = limit(P, rules.pct_C2H4_max(k), [ 1 0], @(M)  M);
    % %C2H2 = b:  b >= m  <=>  -b <= -m ;   b < M  <=>  b <= M
    P = limit(P, rules.pct_C2H2_min(k), [0 -1], @(m) -m);
    P = limit(P, rules.pct_C2H2_max(k), [0  1], @(M)  M);
    if size(P, 1) >= 3 && abs(polyarea(P(:, 1), P(:, 2))) > C.probeEps^2
        Z(end + 1) = struct('zone', rules.zone(k), 'rule', k, 'poly', P); %#ok<AGROW>
    end
end
end

function P = limit(P, value, n, rhs)
% Clip polygon P by the half-plane n*p <= rhs(value); a blank (NaN) limit means "no limit".
if isnan(value) || isempty(P), return, end
P = clip_halfplane(P, n, rhs(value));
end

function Q = clip_halfplane(P, n, c)
% Sutherland-Hodgman clipping of polygon P (rows = vertices) against n*p <= c.
Q = zeros(0, 2);
m = size(P, 1);
for i = 1:m
    p = P(i, :);  q = P(mod(i, m) + 1, :);
    dp = n * p.' - c;  dq = n * q.' - c;
    if dp <= 0, Q(end + 1, :) = p; end %#ok<AGROW>
    if (dp < 0 && dq > 0) || (dp > 0 && dq < 0)
        t = dp / (dp - dq);
        Q(end + 1, :) = p + t * (q - p); %#ok<AGROW>
    end
end
end
