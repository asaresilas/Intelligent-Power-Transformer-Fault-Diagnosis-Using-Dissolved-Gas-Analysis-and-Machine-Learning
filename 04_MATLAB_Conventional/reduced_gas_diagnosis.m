function d = reduced_gas_diagnosis(g, present)
%REDUCED_GAS_DIAGNOSIS  The three conventional methods when some gases are NOT measured (Roadmap Step 26, D23 proposed).
%
%   d = reduced_gas_diagnosis(g, present)
%
%   INPUT   g        struct with fields H2, CH4, C2H6, C2H4, C2H2 [ppm] (N-by-1) and optional equipment_type, exactly
%                    as for conventional_diagnosis. The values of the removed gases are IGNORED: they are replaced by NaN.
%           present  string array of the gases that are measured, e.g. ["H2" "CH4" "C2H4"].
%
%   WHY NaN AND NOT 0
%     0 ppm means "measured, not detected" (decision D8) and is a valid, informative value. A removed gas is
%     "not measured": it must never look like 0 ppm, otherwise a ratio or a percentage would be computed from
%     data that does not exist. NaN propagates through every ratio, percentage and gate comparison.
%
%   RULE (Analysis Plan Section 8, last paragraph - proposed as decision D23)
%     "The Rogers and IEC 60599 ratios need all five gases, and Duval Triangle 1 needs CH4, C2H4 and C2H2; if any of
%     these is missing the method gives ND."  Implemented as:
%       1. APPLICABLE(method) = every gas of conv_config().requiredGas.(method) is in `present`.
%       2. A method that is not applicable returns ND for EVERY record, as raw result and as final result, decided
%          before any ratio, zone or gate test (no partial use of the IEC table, no "Normal" from the gate).
%       3. An applicable method is run exactly as in Steps 14-17 (conventional_diagnosis), on the NaN-masked data.
%       4. NORMALITY GATE on incomplete data: the gate says "every one of the FIVE gases is at or below its typical
%          value". With a gas not measured this cannot be asserted, so the gate is NOT passed (never "Normal") unless
%          all five gases are present. For the five-gas combination the result is identical to Steps 14-17.
%          Sensitivity: d.gate_on_measured = gate evaluated on the measured gases only; d.final_on_measured.duval
%          is the Duval result if that alternative were used.
%
%   OUTPUT  d  struct
%     d.applicable      struct iec, rogers, duval (logical scalars)
%     d.iec, d.rogers, d.duval        final result per record (N-by-1 string): after the gate
%     d.raw.iec, .rogers, .duval      result before the gate
%     d.gate_upper                    N-by-1 logical, gate as defined in rule 4
%     d.gate_on_measured              N-by-1 logical, sensitivity gate (measured gases only)
%     d.final_on_measured             struct: final results if that sensitivity gate were used
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 26.

C = conv_config();
present = string(present(:)).';
if ~all(ismember(present, C.gas))
    error('reduced_gas_diagnosis:gas', 'Unknown gas name in "present"; allowed: %s.', strjoin(C.gas, ', '));
end

% ---- 1. mask the removed gases (NaN = not measured) -------------------------------------------------
N = numel(g.(C.gas(1)));
gm = g;
G = zeros(N, numel(C.gas));
for j = 1:numel(C.gas)
    v = g.(C.gas(j));
    v = v(:);
    if ~ismember(C.gas(j), present), v = NaN(N, 1); end
    gm.(C.gas(j)) = v;
    G(:, j) = v;
end
allFive = all(ismember(C.gas, present));

% ---- 2. applicability of each method ---------------------------------------------------------------
d.applicable = struct( ...
    'iec',    all(ismember(C.requiredGas.iec,    present)), ...
    'rogers', all(ismember(C.requiredGas.rogers, present)), ...
    'duval',  all(ismember(C.requiredGas.duval,  present)));

% ---- 3. run the methods of Steps 14-17 on the masked data ------------------------------------------
c = conventional_diagnosis(gm);
nd = repmat("ND", N, 1);
meth = ["iec" "rogers" "duval"];
for m = meth
    if d.applicable.(m)
        d.raw.(m) = c.raw.(m);
    else
        d.raw.(m) = nd;                                  % rule 2: ND for every record, before any other test
    end
end

% ---- 4. normality gate on incomplete data ----------------------------------------------------------
if allFive
    d.gate_upper = c.gate_upper;                         % identical to Steps 14-17
else
    d.gate_upper = false(N, 1);                          % rule 4: cannot certify "Normal" with a gas missing
end
eq = strings(N, 1);
if isfield(g, 'equipment_type')
    eq = string(g.equipment_type(:));  eq(ismissing(eq)) = "";
end
Gm = G;  Gm(isnan(Gm)) = 0;                              % measured gases only: a missing gas cannot exceed its limit
S = load_standards();
d.gate_on_measured = normality_gate(Gm, eq, S, "high");

for m = meth
    d.(m) = d.raw.(m);
    d.(m)(d.gate_upper & d.applicable.(m)) = "Normal";   % a method that is not applicable stays ND
    f = d.raw.(m);
    f(d.gate_on_measured & d.applicable.(m)) = "Normal";
    d.final_on_measured.(m) = f;
end
end
