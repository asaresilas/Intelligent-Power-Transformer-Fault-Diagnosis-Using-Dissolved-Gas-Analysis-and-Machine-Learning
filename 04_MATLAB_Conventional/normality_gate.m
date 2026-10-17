function isNormal = normality_gate(G, equipmentType, S, whichEnd)
%NORMALITY_GATE  Is every gas at or below the IEC 60599 typical value? (decision D11, rules 1, 2 and 6)
%
%   isNormal = normality_gate(G, equipmentType, S, whichEnd)
%
%   INPUT   G              N-by-5 gas matrix [H2 CH4 C2H6 C2H4 C2H2] in ppm (column order = conv_config().gas)
%           equipmentType  N-by-1 string; IEC TC 10 equipment code ("U" = communicating OLTC, others or "")
%           S              output of load_standards()
%           whichEnd       "high" (primary gate) or "low" (sensitivity)
%   OUTPUT  isNormal       N-by-1 logical: true when ALL five gases are <= the chosen end of their range
%
%   RULES
%     * Primary gate: the UPPER end of the range; sensitivity: the LOWER end (D11 rule 1).
%     * H2, CH4, C2H6, C2H4 use the "All transformers" rows of iec_typical_values.csv.
%     * C2H2 uses the "Communicating OLTC" row only when equipmentType = "U" (IEC TC 10 records);
%       the "No OLTC" row is used for every other record (D11 rule 2).
%     * The same gate is used for all three methods (D11 rule 6).
%
%   CAUTION (IEC 60599 Annex A WARNING, recorded in iec_typical_values.csv): the typical values are
%   90 % observation ranges, NOT fault limits. Using them as a gate is the researcher's approved design;
%   it labels low-gas records "Normal" whatever their true class (the Step 14 report counts them).
%
%   SOURCE  IEC 60599:1999/AMD1:2007 Table A.2 (iec_typical_values.csv).
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 14.

C = conv_config();
N = size(G, 1);
lim = zeros(N, numel(C.gas));
for j = 1:numel(C.gas)
    if C.gas(j) == "C2H2"
        rowU = S.typical(S.typical.gas == "C2H2" & S.typical.group == C.grpOLTC,  :);
        rowN = S.typical(S.typical.gas == "C2H2" & S.typical.group == C.grpNoOLTC, :);
        v = [pick(rowN, whichEnd), pick(rowU, whichEnd)];
        isU = (equipmentType == C.oltcCommunicatingType);
        lim(:, j) = v(1) * ~isU + v(2) * isU;
    else
        row = S.typical(S.typical.gas == C.gas(j) & S.typical.group == C.grpAll, :);
        lim(:, j) = pick(row, whichEnd);
    end
end
isNormal = all(G <= lim, 2);
end

function v = pick(row, whichEnd)
if height(row) ~= 1
    error('normality_gate:row', 'Expected exactly one typical-value row, found %d.', height(row));
end
switch whichEnd
    case "high", v = row.high;
    case "low",  v = row.low;
    otherwise,   error('normality_gate:end', 'whichEnd must be "high" or "low".');
end
end
