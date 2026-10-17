function [x, y] = duval_xy(pct_C2H4, pct_C2H2, scale)
%DUVAL_XY  Cartesian coordinates of a point in the equilateral Duval Triangle 1.
%
%   [x, y] = duval_xy(pct_C2H4, pct_C2H2)          side length 1
%   [x, y] = duval_xy(pct_C2H4, pct_C2H2, 100)     side length 100 ("percentage-point" units)
%
%   INPUT   pct_C2H4, pct_C2H2  [%] scalars or equal-size arrays; %CH4 = 100 - %C2H4 - %C2H2.
%   OUTPUT  x, y  coordinates. Corners: 100 % CH4 at the top (0.5, sqrt(3)/2), 100 % C2H2 at
%           bottom-left (0, 0), 100 % C2H4 at bottom-right (1, 0)  (multiplied by `scale`).
%
%   EQUATION  (Analysis Plan Eq. 4 and the Duval Triangle 1 layout, IEC 60599 Figure B.3)
%     x = (pct_C2H4 + 0.5 * pct_CH4) / 100        y = (sqrt(3)/2) * pct_CH4 / 100
%   where pct_CH4 = 100 - pct_C2H4 - pct_C2H2.
%
%   Why side = 100 matters: in this plane one percentage point along a side is one unit of length,
%   so Euclidean distances are directly "percentage points" (boundary distance, Eq. 10 of the plan).
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 14.

if nargin < 3, scale = 1; end
C = conv_config();
pct_CH4 = C.pctTotal - pct_C2H4 - pct_C2H2;
x = scale * (pct_C2H4 + 0.5 * pct_CH4) / C.pctTotal;
y = scale * (sqrt(3) / 2) * pct_CH4 / C.pctTotal;
end
