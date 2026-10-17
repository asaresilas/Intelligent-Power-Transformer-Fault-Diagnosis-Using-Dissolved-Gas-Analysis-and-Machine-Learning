function E = duval_decision_edges(S)
%DUVAL_DECISION_EDGES  The line segments of Duval Triangle 1 that separate two DIFFERENT zones.
%
%   E = duval_decision_edges(S)        S = load_standards()
%
%   PURPOSE
%     Boundary distance for the Duval Triangle (Analysis Plan Eq. 10, amended by decision D12).
%     Eq. 10 takes "the nearest zone edge". Read literally that would also count (a) the three sides
%     of the triangle and (b) seams between rules of the SAME zone (for example the two D2 rules, the
%     three DT rules). Neither is a decision boundary: crossing them never changes the diagnosis.
%     D12 (researcher, 2026-10-11) therefore keeps only edges with a different zone on each side.
%
%   METHOD
%     1. Every rule is a convex polygon (duval_zone_polygons).
%     2. Each polygon edge is cut at every polygon vertex that lies on it, giving short pieces.
%     3. For the middle of each piece, the zone is looked up a tiny distance (C.probeEps = 1e-6
%        percentage points) on EACH side with the same rule table used for diagnosis.
%        The piece is a decision edge if both sides are inside the triangle and the zones differ.
%     Pieces shared by two polygons appear twice; that does not change any distance.
%
%   OUTPUT  E  table, one row per piece:
%     a1 b1 a2 b2   end points in (%C2H4, %C2H2) coordinates
%     x1 y1 x2 y2   end points in the plane of a triangle with side 100 (1 unit = 1 percentage point)
%     zone1, zone2  zones on the two sides
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 14.

persistent cacheRules cacheE
if ~isempty(cacheE) && isequal(cacheRules, S.duval.rules)
    E = cacheE; return
end
C = conv_config();
Z = duval_zone_polygons(S);
allV = vertcat(Z.poly);
tol = C.probeEps;                                     % length tolerance for "vertex lies on edge"
rows = zeros(0, 4);  z1 = strings(0, 1);  z2 = strings(0, 1);
for i = 1:numel(Z)
    V = Z(i).poly;  m = size(V, 1);
    for e = 1:m
        p = V(e, :);  q = V(mod(e, m) + 1, :);
        len = norm(q - p);
        if len <= tol, continue, end
        u = (q - p) / len;
        d = allV - p;                                  % all polygon vertices relative to p
        along = d * u.';                               % position along the edge [percentage points]
        across = d(:, 1) * u(2) - d(:, 2) * u(1);      % signed distance from the edge line
        onEdge = abs(across) <= tol & along > tol & along < len - tol;
        s = uniquetol([0; along(onEdge); len], tol, 'DataScale', 1);
        for k = 1:numel(s) - 1
            mid = p + u * (s(k) + s(k + 1)) / 2;
            nrm = [-u(2) u(1)];
            la = zone_at(mid + C.probeEps * nrm, S, C);
            lb = zone_at(mid - C.probeEps * nrm, S, C);
            if la ~= "OUT" && lb ~= "OUT" && la ~= lb
                rows(end + 1, :) = [p + u * s(k), p + u * s(k + 1)]; %#ok<AGROW>
                z1(end + 1, 1) = la; z2(end + 1, 1) = lb; %#ok<AGROW>
            end
        end
    end
end
[x1, y1] = duval_xy(rows(:, 1), rows(:, 2), C.pctTotal);
[x2, y2] = duval_xy(rows(:, 3), rows(:, 4), C.pctTotal);
E = table(rows(:, 1), rows(:, 2), rows(:, 3), rows(:, 4), x1, y1, x2, y2, z1, z2, ...
    'VariableNames', {'a1', 'b1', 'a2', 'b2', 'x1', 'y1', 'x2', 'y2', 'zone1', 'zone2'});
cacheRules = S.duval.rules;  cacheE = E;
end

function z = zone_at(ab, S, C)
% Zone of the point (a, b) = (%C2H4, %C2H2); "OUT" when it lies outside the triangle.
a = ab(1);  b = ab(2);
if a < 0 || b < 0 || a + b > C.pctTotal
    z = "OUT"; return
end
z = diagnose_duval(C.pctTotal - a - b, a, b, S.duval.rules);
end
