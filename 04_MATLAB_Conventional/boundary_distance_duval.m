function d = boundary_distance_duval(pctC2H4, pctC2H2, S)
%BOUNDARY_DISTANCE_DUVAL  Distance from a sample to the nearest Duval decision edge [percentage points].
%
%   d = boundary_distance_duval(pctC2H4, pctC2H2, S)
%
%   INPUT   pctC2H4, pctC2H2  [%] arrays (NaN when the point is undefined); %CH4 = 100 - %C2H4 - %C2H2
%           S                 output of load_standards()
%   OUTPUT  d                 same size; NaN where the input is NaN
%
%   EQUATION  (Analysis Plan Eq. 10, with the amendment of decision D12)
%     dD = min over e in E of dist(P, e)
%   where:
%     P     sample point in the plane of a triangle of side 100 (duval_xy with scale 100) [percentage points]
%     E     set of DECISION edges: segments with a different zone on each side (duval_decision_edges)
%     dist  shortest (perpendicular or end-point) Euclidean distance from P to the segment e
%   Because the nearest point of all decision edges is always on an edge of the sample's own zone,
%   this is the distance to the nearest zone-limit line that borders the sample's zone.
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 14.

C = conv_config();
E = duval_decision_edges(S);
[px, py] = duval_xy(pctC2H4, pctC2H2, C.pctTotal);
d = inf(size(px));
for e = 1:height(E)
    abx = E.x2(e) - E.x1(e);  aby = E.y2(e) - E.y1(e);
    t = ((px - E.x1(e)) * abx + (py - E.y1(e)) * aby) / (abx^2 + aby^2);
    t = min(max(t, 0), 1);                         % clamp to the segment
    d = min(d, hypot(px - (E.x1(e) + t * abx), py - (E.y1(e) + t * aby)));
end
d(isnan(px) | isnan(py)) = NaN;
end
