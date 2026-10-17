function r = gas_ratios(g)
%GAS_RATIOS  Diagnostic gas ratios and Duval Triangle 1 percentages (definitions only).
%
%   r = gas_ratios(g)
%
%   INPUT   g  struct with fields H2, CH4, C2H6, C2H4, C2H2 [ppm]. Each field is a scalar or an
%              array; all fields must have the same size (the function is vectorised).
%
%   OUTPUT  r  struct, same size as the input fields:
%     r.R1 = CH4/H2        r.R2 = C2H2/C2H4        r.R5 = C2H4/C2H6      (Rogers naming)
%     r.CH4_H2, r.C2H2_C2H4, r.C2H4_C2H6   same values under the older names (kept for the dashboard)
%     r.C2H2_CH4, r.C2H6_C2H2             Doernenburg ratios (definitions only; not used in this thesis)
%     r.pct_CH4, r.pct_C2H4, r.pct_C2H2   Duval Triangle 1 percentages [%], 100*gas/(CH4+C2H4+C2H2)
%
%   RULES (decision D11, last rule)
%     A ratio whose denominator is 0 ppm is UNDEFINED and returned as NaN. A zero numerator with a
%     non-zero denominator is a valid ratio of 0. When CH4+C2H4+C2H2 = 0 the three percentages are NaN.
%     "Not detected" is stored as 0 ppm (decision D8), so zero denominators do occur in the data.
%     No threshold is applied here.
%
%   EQUATIONS
%     R1 = CH4/H2,  R2 = C2H2/C2H4,  R5 = C2H4/C2H6                       (Analysis Plan Eq. 3)
%     pct_X = 100 * X / (CH4 + C2H4 + C2H2),  X in {CH4, C2H4, C2H2}       (Analysis Plan Eq. 4)
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 14.

C = conv_config();
r.R1 = safe_div(g.CH4,  g.H2);
r.R2 = safe_div(g.C2H2, g.C2H4);
r.R5 = safe_div(g.C2H4, g.C2H6);
r.CH4_H2    = r.R1;
r.C2H2_C2H4 = r.R2;
r.C2H4_C2H6 = r.R5;
r.C2H2_CH4  = safe_div(g.C2H2, g.CH4);
r.C2H6_C2H2 = safe_div(g.C2H6, g.C2H2);
s = g.CH4 + g.C2H4 + g.C2H2;                  % Duval Triangle 1 uses CH4, C2H4 and C2H2 only
r.pct_CH4  = C.pctTotal * safe_div(g.CH4,  s);
r.pct_C2H4 = C.pctTotal * safe_div(g.C2H4, s);
r.pct_C2H2 = C.pctTotal * safe_div(g.C2H2, s);
end

function q = safe_div(a, b)
% a./b with NaN wherever b == 0 (undefined ratio), including 0/0.
q = a ./ b;
q(b == 0) = NaN;
end
