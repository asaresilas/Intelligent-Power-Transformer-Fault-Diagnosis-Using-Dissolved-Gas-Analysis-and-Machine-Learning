function d = conventional_diagnosis(g)
%CONVENTIONAL_DIAGNOSIS  IEC 60599 ratio, Rogers ratio and Duval Triangle 1 diagnoses of one or many samples.
%
%   d = conventional_diagnosis(g)
%
%   INPUT   g  struct with fields H2, CH4, C2H6, C2H4, C2H2 [ppm]; each a scalar (one sample) or an
%              N-by-1 array (N samples). Optional field g.equipment_type (N-by-1 string; "U" =
%              communicating OLTC, IEC TC 10 code); when absent every sample is "no OLTC" (D11 rule 2).
%
%   OUTPUT  d  struct (N-by-1 string fields, N-by-1 numeric fields):
%     d.iec, d.rogers, d.duval       FINAL diagnosis (after the upper normality gate): Normal PD D1 D2 T1
%                                    T2 T3, or the dual answer D1/D2 (IEC), DT (Duval), ND. (PD/T1 no longer occurs: D13.)
%                                    These three names are used by the dashboard (DGADashboard_reference.m).
%     d.raw.iec, d.raw.rogers, d.raw.duval   result of the method BEFORE the gate
%     d.gate_upper, d.gate_lower     logical: every gas <= upper / lower end of the IEC Table A.2 range
%     d.boundary.iec, .rogers, .duval  distance to the nearest decision boundary
%                                    (IEC and Rogers: decades, Analysis Plan Eq. 9; Duval: percentage points, Eq. 10 / D12)
%     d.ratios                       gas_ratios(g): R1, R2, R5 and the Duval percentages
%
%   RULES  Decisions D11 (2026-10-11) and D12 (2026-10-11); see the help of the called functions:
%     load_standards (all limits come from 02_Standards), diagnose_ratio_method, diagnose_duval,
%     normality_gate, boundary_distance_ratio, boundary_distance_duval.
%     "result = Normal if the upper gate is passed, otherwise the raw result of the method".
%     The same gate is used for all three methods (D11 rule 6).
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 14.

S = load_standards();

G =[g.H2(:), g.CH4(:), g.C2H6(:), g.C2H4(:), g.C2H2(:)];       % column order = C.gas
N = size(G, 1);
if isfield(g, 'equipment_type')
    eq = string(g.equipment_type(:));
    eq(ismissing(eq)) = "";
else
    eq = strings(N, 1);
end

r = gas_ratios(struct('H2', G(:, 1), 'CH4', G(:, 2), 'C2H6', G(:, 3), 'C2H4', G(:, 4), 'C2H2', G(:, 5)));
R = [r.R1, r.R2, r.R5];

rawIec    = diagnose_ratio_method(R, S.iec.rows);
rawRogers = diagnose_ratio_method(R, S.rogers.rows);
rawDuval  = diagnose_duval(r.pct_CH4, r.pct_C2H4, r.pct_C2H2, S.duval.rules);

gateU = normality_gate(G, eq, S, "high");
gateL = normality_gate(G, eq, S, "low");

d.iec    = apply_gate(rawIec,    gateU);
d.rogers = apply_gate(rawRogers, gateU);
d.duval  = apply_gate(rawDuval,  gateU);
d.raw    = struct('iec', rawIec, 'rogers', rawRogers, 'duval', rawDuval);
d.gate_upper = gateU;
d.gate_lower = gateL;
d.boundary = struct( ...
    'iec',    boundary_distance_ratio(R, S.iec.rows), ...
    'rogers', boundary_distance_ratio(R, S.rogers.rows), ...
    'duval',  boundary_distance_duval(r.pct_C2H4, r.pct_C2H2, S));
d.ratios = r;
end

function out = apply_gate(raw, gate)
% Normality gate: samples with every gas at or below the typical value are "Normal".
out = raw;
out(gate) = "Normal";
end
