function V = dashboard_verdict(g, d, m, a, ref)
%DASHBOARD_VERDICT  One clear answer for one gas sample: healthy or fault, which fault, how sure, and what to do (17 Oct 2026).
%
%   V = dashboard_verdict(g, d, m, a)        g = gas struct (H2 CH4 C2H6 C2H4 C2H2 [ppm], optional equipment_type)
%   V = dashboard_verdict(g, d, m, a, ref)   ref = known label of the record from the data file ("" = none), used only to
%                                            show whether each method was right; it never changes a diagnosis.
%
%   INPUT   d  conventional_diagnosis(g)   (Rogers, IEC 60599, Duval Triangle 1 and the IEC 60599 normality gate)
%           m  ml_diagnose(g, url)          (status, fault_class)
%           a  dga_agreement(d, m)
%
%   WORKFLOW (the order of IEC 60599 clause 6 / IEEE C57.104-2008, Section 6):
%     1 compare every gas with its typical value (IEC 60599 AMD1:2007 Table A.2, read through load_standards);
%     2 if all five gases are at or below the typical values the transformer is reported HEALTHY (no fault indicated);
%     3 otherwise the fault type is read from the gas ratios by three classical methods and by the ML model;
%     4 each method casts one vote; "D1/D2" votes for both D1 and D2; "DT" and "ND" are no single diagnosis and do not vote;
%     5 the type with the most votes is the verdict; it needs at least two votes.
%
%   OUTPUT  V  struct
%     V.health      "healthy" | "watch" | "fault" | "undecided"
%     V.title       banner headline;  V.detail  one or two plain sentences;  V.action  what the engineer should do
%     V.color       1x3 RGB of the banner
%     V.fault_class winning type ("" if none);  V.family  "electrical" | "thermal" | "none"
%     V.support     votes for the winner;  V.voters  number of methods that could vote (3 or 4)
%     V.level       "strong" (all voting methods agree) | "majority" | "split" | "none"
%     V.methods     ["Rogers" "IEC 60599" "Duval" "ML"];  V.answers  their answers (string 1x4, "" = ML missing)
%     V.judge       string 1x4: "AGREES" | "DIFFERS" | "NO VERDICT" (nobody has two votes) | "NO ANSWER" (DT, ND, ML missing)
%     V.gas         table: gas, ppm, typical_high, times_typical, above (logical)
%     V.has_ref     true when ref is a class label;  V.ref  the label;  V.ref_ok  logical 1x4 (answer compatible with ref)
%   Nothing here creates, changes or estimates a gas value. Typical values are 90 % observation ranges, NOT fault limits
%   (IEC 60599 Annex A); the "healthy" state therefore means "no fault indicated by the standard's own screening".
%   Project: MPhil, DGA transformer fault diagnosis - dashboard redesign.

if nargin < 5, ref = ""; end
ref = string(ref);
if ismissing(ref) || ~any(ref == ["Normal" "PD" "D1" "D2" "T1" "T2" "T3"]), ref = ""; end

V.methods = ["Rogers" "IEC 60599" "Duval" "ML"];
ans4 = [string(d.rogers), string(d.iec), string(d.duval), ""];
mlOK = isfield(m, 'status') && string(m.status) == "OK";
if mlOK, ans4(4) = string(m.fault_class); end
V.answers = ans4;

%% 1 gases against the typical values --------------------------------------------------------------------------------------
V.gas = gas_table(g);

%% 2 votes ------------------------------------------------------------------------------------------------------------------
classes = ["Normal" "PD" "D1" "D2" "T1" "T2" "T3"];
canVote = [true true true mlOK];                       % DT and ND abstain
canVote(1:3) = ~ismember(ans4(1:3), ["DT" "ND" ""]);
V.voters = 3 + mlOK;
sup = zeros(1, numel(classes));  exact = zeros(1, numel(classes));
for k = 1:4
    if ~canVote(k), continue, end
    for c = 1:numel(classes)
        if compatible(ans4(k), classes(c))
            sup(c) = sup(c) + 1;
            exact(c) = exact(c) + (ans4(k) == classes(c));
        end
    end
end
[best, ic] = max(sup + 0.01 * exact);                  % exact votes break a tie between D1 and D2
winners = find(abs((sup + 0.01 * exact) - best) < 1e-9);
V.fault_class = "";  V.support = 0;
if numel(winners) == 1 && sup(ic) >= 2
    V.fault_class = classes(ic);  V.support = sup(ic);
end
if V.fault_class == "", V.level = "none";
elseif V.support == V.voters, V.level = "strong";
elseif V.support > V.voters / 2, V.level = "majority";
else, V.level = "split";
end
V.family = "none";
if any(V.fault_class == ["PD" "D1" "D2"]), V.family = "electrical"; end
if any(V.fault_class == ["T1" "T2" "T3"]), V.family = "thermal"; end

%% 3 judgement of each method against the verdict --------------------------------------------------------------------------
V.judge = repmat("NO ANSWER", 1, 4);
for k = 1:4
    if canVote(k) && V.fault_class ~= ""
        if compatible(ans4(k), V.fault_class), V.judge(k) = "AGREES"; else, V.judge(k) = "DIFFERS"; end
    elseif canVote(k)
        V.judge(k) = "NO VERDICT";                      % no type has two votes, so nobody can be called right or wrong
    end
end

%% 4 reference label ---------------------------------------------------------------------------------------------------------
V.has_ref = ref ~= "";  V.ref = ref;  V.ref_ok = false(1, 4);
if V.has_ref
    for k = 1:4, V.ref_ok(k) = ans4(k) ~= "" && compatible(ans4(k), ref); end
end

%% 5 health state, banner and advice ----------------------------------------------------------------------------------------
green = [0.10 0.55 0.25];  red = [0.75 0.15 0.15];  amber = [0.85 0.50 0.05];
gateOK = logical(d.gate_upper(1));
nAbove = sum(V.gas.above);
if gateOK
    if mlOK && string(m.fault_class) ~= "Normal"
        V.health = "watch";  V.color = amber;
        V.title = "WATCH - gas levels are normal, but the ML model suggests " + string(m.fault_class);
        V.detail = "All five gases are at or below the typical values of IEC 60599, so the standard's screening reports no fault. " + ...
            "Only the ML model names a fault type (" + shortName(m.fault_class) + "). At very low gas levels ratios are unreliable, so treat this as a hint, not a fault.";
        V.action = "No urgent action. Keep the normal sampling schedule and look at the trend at the next sample.";
    else
        V.health = "healthy";  V.color = green;
        V.title = "HEALTHY - all five gases are within the typical values";
        V.detail = "Every gas is at or below the IEC 60599 typical value, so no fault is indicated. " + ...
            "Typical values show what most healthy transformers have; they are not guarantees, so keep watching the trend.";
        V.action = "No action needed from this sample. Continue the normal oil-sampling schedule.";
    end
elseif V.fault_class == "Normal"
    V.health = "watch";  V.color = amber;
    V.title = "WATCH - " + nAbove + " gas(es) above typical, but the methods see no fault pattern";
    V.detail = "At least one gas is above its typical value, yet the methods agree that the gas ratios look normal (" + ...
        V.support + " of " + V.voters + " methods).";
    V.action = "Take a repeat sample soon and compare it with earlier results to see whether the gases are rising.";
elseif V.fault_class ~= ""
    V.health = "fault";  V.color = red;
    V.title = "FAULT INDICATED - " + V.fault_class + ": " + shortName(V.fault_class);
    V.detail = V.support + " of " + V.voters + " methods name " + V.fault_class + " (" + levelText(V.level) + "). " + ...
        nAbove + " of 5 gases are above their typical values. It is a " + V.family + " fault type (IEC 60599 Table 1).";
    V.action = actionText(V.fault_class);
else
    V.health = "undecided";  V.color = amber;
    V.title = "CHECK - gas levels are raised, but the methods do not agree on a fault type";
    V.detail = nAbove + " of 5 gases are above their typical values, so something may be wrong, but no fault type has two votes. " + ...
        "This happens near the border between two fault types, or when a method gives no diagnosis (ND) or a mixture (DT).";
    V.action = "Do not decide on one method. Take a repeat sample, check the gas trend over time and ask for an expert opinion before any inspection decision.";
end
end

%% ------------------------------------------------------------------------------------------------------------------------
function tf = compatible(answer, cls)
answer = string(answer);  cls = string(cls);
if answer == "D1/D2", tf = any(cls == ["D1" "D2"]); else, tf = (answer == cls); end
end

function T = gas_table(g)
C = conv_config();  S = load_standards();
gas = C.gas(:);  ppm = [g.H2; g.CH4; g.C2H6; g.C2H4; g.C2H2];  ppm = ppm(:);
eq = ""; if isfield(g, 'equipment_type'), eq = string(g.equipment_type); if ismissing(eq), eq = ""; end, end
hi = zeros(5, 1);
for j = 1:5
    if gas(j) == "C2H2"
        grp = C.grpNoOLTC;  if eq == C.oltcCommunicatingType, grp = C.grpOLTC; end
        row = S.typical(S.typical.gas == "C2H2" & S.typical.group == grp, :);
    else
        row = S.typical(S.typical.gas == gas(j) & S.typical.group == C.grpAll, :);
    end
    hi(j) = row.high(1);
end
T = table(gas, ppm, hi, ppm ./ hi, ppm > hi, 'VariableNames', {'gas', 'ppm', 'typical_high', 'times_typical', 'above'});
end

function s = shortName(c)
switch string(c)
    case "Normal", s = "no fault";
    case "PD",     s = "partial discharges";
    case "D1",     s = "discharges of low energy";
    case "D2",     s = "discharges of high energy (arcing)";
    case "T1",     s = "thermal fault below 300 degC";
    case "T2",     s = "thermal fault between 300 and 700 degC";
    case "T3",     s = "thermal fault above 700 degC";
    otherwise,     s = string(c);
end
end

function s = levelText(l)
switch l
    case "strong",   s = "all voting methods agree: strong";
    case "majority", s = "a clear majority";
    otherwise,       s = "only part of the methods agree: weaker";
end
end

function s = actionText(c)
% General engineering practice, not a requirement of IEC 60599 (TO VERIFY against the utility's own procedure).
base = " Confirm with a repeat sample and the gas trend before acting; if the gases rise, plan an inspection.";
switch string(c)
    case "PD", s = "Partial discharges are usually slow-acting but can lead to worse faults." + base;
    case "D1", s = "Discharges of low energy: look at the trend closely." + base;
    case "D2", s = "Discharges of high energy (arcing) can be serious and develop quickly: treat as urgent." + base;
    case "T1", s = "A mild overheating (below 300 degC): check loading and cooling." + base;
    case "T2", s = "Overheating between 300 and 700 degC: check loading, cooling and contacts." + base;
    case "T3", s = "Severe overheating (above 700 degC) can damage the winding or core quickly: treat as urgent." + base;
    otherwise, s = base;
end
end
