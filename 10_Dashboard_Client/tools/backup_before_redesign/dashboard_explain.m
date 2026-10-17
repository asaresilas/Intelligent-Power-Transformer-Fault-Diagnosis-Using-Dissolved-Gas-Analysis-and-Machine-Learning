function L = dashboard_explain(kind, varargin)
%DASHBOARD_EXPLAIN  Plain-language text that explains a dashboard result to the person who looks at the screen (15 Oct 2026).
%
%   L = dashboard_explain('welcome')                         what the dashboard does and how to use it
%   L = dashboard_explain('simulation', res, P)              what the simulated temperatures and ageing mean
%                                                            res = run_transformer_simulation result;
%                                                            P   = struct theta_ref_age, dT_double_age, theta_amb_C (params_transformer)
%   L = dashboard_explain('diagnosis', g, d, m, a)           what the diagnoses of ONE gas sample mean
%                                                            g = gas struct; d = conventional_diagnosis; m = ml_diagnose; a = dga_agreement
%   L = dashboard_explain('events', ER)                      summary of the sampling events of one simulated run (ER = EventResults)
%   L = dashboard_explain('all', st)                         the text the app shows: st.sim, st.diag, st.events (empty = not available yet)
%
%   OUTPUT  L  string column, one line per element ("" = blank line). Every number in the text is taken from the arguments;
%           the fixed wording comes from IEC 60599 (fault types, typical values) and from decisions D11, D25, D37 of this project.
%   Nothing here creates, changes or estimates a gas value. The text never claims more than the program computed.
%   Project: MPhil, DGA transformer fault diagnosis - dashboard explanation panel.

switch lower(string(kind))
    case "welcome",    L = welcome();
    case "simulation", L = simulation(varargin{:});
    case "diagnosis",  L = diagnosis(varargin{:});
    case "events",     L = events(varargin{:});
    case "all",        L = everything(varargin{1});
    otherwise, error('dashboard_explain:kind', 'Unknown kind "%s".', string(kind));
end
end

%% ------------------------------------------------------------------------------------------------------------------------
function L = everything(st)
% st.focus = "run": the summary of the whole run first (events, simulation), then the record last shown;
% st.focus = "diag" (default): the record on the screen first.
parts = {getfield_or(st, 'diag'), getfield_or(st, 'events'), getfield_or(st, 'sim')};
if isfield(st, 'focus') && string(st.focus) == "run", parts = parts([2 3 1]); end
L = strings(0, 1);
for k = 1:numel(parts)
    if ~isempty(parts{k}), L = [L; parts{k}(:); ""]; end %#ok<AGROW>
end
if isempty(L), L = welcome(); else, L = [L; classGuide()]; end
end

function v = getfield_or(st, name)
v = strings(0, 1);
if isfield(st, name) && ~isempty(st.(name)), v = string(st.(name)); end
end

function L = welcome()
L = [
    "HOW TO READ THIS DASHBOARD"
    ""
    "This tool helps an engineer look at dissolved gas analysis (DGA): the gases that dissolve in the oil of a power transformer when something inside it is wrong."
    ""
    "WHAT TO DO"
    "1. Press 'Run transformer simulation'. The model simulates 24 hours of transformer operation and takes several oil samples (the sampling events, numbered #1, #2, ... on the plot)."
    "2. For every sampling event the dashboard reads the next measured gas record, asks three classical methods (Rogers, IEC 60599, Duval Triangle) and the machine-learning (ML) model for a diagnosis, and shows them side by side."
    "3. Or use 'Load measured DGA file', pick a record number and press 'Diagnose selected record'."
    "4. This panel then explains, in words, what the result on the screen means."
    ""
    "THE TWO KINDS OF INFORMATION"
    "- Temperatures and ageing (top plot) come from the simulated transformer. They describe how hard the transformer is working. They do NOT create gas values and they are NOT the cause of the measured gases."
    "- Gas values come only from the measured records of the data file. The dashboard never makes up, changes or fills in a gas value."
    ""
    classGuide()
    ];
end

function L = classGuide()
L = [
    "FAULT TYPES (IEC 60599)"
    "Normal: no fault is indicated."
    "PD: partial discharges (small electrical sparks inside the insulation). Main gas: hydrogen (H2), a little methane (CH4)."
    "D1: discharges of low energy. Main gases: H2 and acetylene (C2H2)."
    "D2: discharges of high energy (arcing). Main gases: C2H2 and H2, with ethylene (C2H4)."
    "T1: thermal (overheating) fault below 300 degC. Main gases: CH4 and ethane (C2H6)."
    "T2: thermal fault between 300 and 700 degC. Main gases: C2H4 and CH4."
    "T3: thermal fault above 700 degC. Main gas: C2H4, with C2H2 at very high temperature."
    "DT (Duval only): a mixture of thermal and electrical faults. ND: the method gives no diagnosis. D1/D2 (IEC only): the method cannot separate the two."
    ];
end

%% ------------------------------------------------------------------------------------------------------------------------
function L = simulation(res, P)
hs = res.theta_hs_C(:);  oil = res.theta_oil_C(:);  t = res.t_h(:);
[hsMax, i] = max(hs);
L = [
    "WHAT THE SIMULATION SHOWS"
    sprintf("The transformer was simulated for %.0f hours with an ambient temperature of %.0f degC.", t(end), P.theta_amb_C)
    sprintf("Top-oil temperature (blue): ends at %.1f degC. Hot-spot temperature (red, the hottest point of the winding): peaks at %.1f degC at %.1f h and ends at %.1f degC.", oil(end), hsMax, t(i), hs(end))
    loadText(res.K_pu)
    sprintf("Insulation ageing: the paper insulation ages faster when the hot-spot is hotter. At a hot-spot of %.0f degC the ageing rate is 1 (normal); every %.0f K more doubles it (reference values of params_transformer.m, TO VERIFY against IEC 60076-7). Over this run the insulation aged as much as it would in %.1f hours at the normal rate (loss of life).", P.theta_ref_age, P.dT_double_age, res.loss_of_life_h)
    ageingRemark(res, P)
    "Remember: this is a thermal model of the operating condition. It gives context for the gas results; it does not prove or disprove a fault."
    ];
end

function s = loadText(K)
% Load factor K = load current as a fraction of the rated current (the model's measured value).
K = K(:);
if max(K) - min(K) < 0.005
    s = sprintf("The load factor was constant at %.2f times the rated load.", mean(K));
else
    s = sprintf("The load factor varied between %.2f and %.2f times the rated load.", min(K), max(K));
end
end

function s = ageingRemark(res, P)
if max(res.theta_hs_C) > P.theta_ref_age
    s = sprintf("The hot-spot was above %.0f degC for part of the run, so the insulation aged faster than the normal rate during that time.", P.theta_ref_age);
else
    s = sprintf("The hot-spot stayed at or below %.0f degC, so the insulation aged at or below the normal rate.", P.theta_ref_age);
end
end

%% ------------------------------------------------------------------------------------------------------------------------
function L = diagnosis(g, d, m, a)
rid = ""; if isfield(g, 'record_id'), rid = string(g.record_id); end
L = "WHAT THE DIAGNOSIS MEANS";
if strlength(rid) > 0, L(end + 1, 1) = "Record " + rid; end
L(end + 1, 1) = sprintf("Measured gases (ppm): H2 %.8g, CH4 %.8g, C2H6 %.8g, C2H4 %.8g, C2H2 %.8g. These values come from the data file as they are.", g.H2, g.CH4, g.C2H6, g.C2H4, g.C2H2);
L(end + 1, 1) = "";
% --- gate
if d.gate_upper
    L(end + 1, 1) = "Gas level: every gas is at or below the typical value of IEC 60599 (Annex A). The three classical methods therefore report 'Normal'. Typical values describe what 90 % of healthy units show; they are not fault limits, so a low-gas record can still hide a weak fault.";
else
    L(end + 1, 1) = "Gas level: at least one gas is above the typical value of IEC 60599 (Annex A), so the classical methods look at the gas ratios to name a fault type.";
end
L(end + 1, 1) = "";
% --- the three classical methods
L(end + 1, 1) = "Classical methods:";
L(end + 1, 1) = "- Rogers ratio: " + methodText(d.rogers);
L(end + 1, 1) = "- IEC 60599 ratio: " + methodText(d.iec);
L(end + 1, 1) = "- Duval Triangle 1: " + methodText(d.duval);
L(end + 1, 1) = "";
% --- ML
if m.status == "OK"
    [ps, ord] = sort(m.probabilities, 'descend');  cls = m.classes(ord);
    L(end + 1, 1) = sprintf("Machine learning (Random Forest, model %s): most probable type %s (%s), probability %.0f %%.", m.model_version, m.fault_class, shortName(m.fault_class), 100 * ps(1));
    L(end + 1, 1) = sprintf("The next most probable types are %s (%.0f %%) and %s (%.0f %%).", cls(2), 100 * ps(2), cls(3), 100 * ps(3));
    if ps(1) >= 0.5
        L(end + 1, 1) = "The model has a clear majority for one type (more than half of the probability).";
    else
        L(end + 1, 1) = "No type has more than half of the probability: the model is uncertain, so treat this answer with extra care.";
    end
    if d.gate_upper && m.fault_class ~= "Normal"
        L(end + 1, 1) = "Note: the gases are within typical values, yet the ML model names a fault type. The model has no normality gate; ratios are unreliable at very low gas levels.";
    end
    if ~isempty(m.notes) && any(strlength(m.notes) > 0)
        L(end + 1, 1) = "Service note: " + strjoin(m.notes(strlength(m.notes) > 0), " ");
    end
else
    L(end + 1, 1) = "Machine learning: not available (" + string(m.status) + "). The classical diagnoses above are still valid.";
end
L(end + 1, 1) = "";
% --- agreement
switch a.state
    case "green"
        L(end + 1, 1) = "Agreement (green lamp): Rogers, IEC 60599 and Duval all give the same answer as the ML model. Independent methods pointing the same way make the conclusion more reliable.";
    case "amber"
        L(end + 1, 1) = sprintf("Agreement (amber lamp): %d of the 3 classical methods agree with the ML answer. When methods disagree, the record is close to a boundary between fault types or is unusual: do not rely on one method alone.", a.count);
        L(end + 1, 1) = disagreeText(d, m, a);
    otherwise
        L(end + 1, 1) = "Agreement (grey lamp): cannot be judged because the ML result is missing.";
end
L(end + 1, 1) = "";
L(end + 1, 1) = "HOW MUCH TO TRUST IT";
L(end + 1, 1) = "This is decision support, not a verdict. On the inspection-confirmed IEC TC 10 cases used in this study, the ML model was not shown to be better than the classical methods (thesis, Chapter 4); use it as a second opinion. Confirm any fault indication with a repeat sample, the gas trend over time and, if needed, an inspection.";
end

function s = methodText(x)
x = string(x);
switch x
    case "Normal", s = "Normal (no fault indicated).";
    case "DT",     s = "DT, a mixture of thermal and electrical faults.";
    case "ND",     s = "ND, no diagnosis: the ratios fall in no coded combination.";
    case "D1/D2",  s = "D1 or D2: the method cannot separate low-energy and high-energy discharge.";
    otherwise,     s = x + ", " + shortName(x) + ".";
end
end

function s = shortName(c)
switch string(c)
    case "Normal", s = "no fault";
    case "PD",     s = "partial discharges";
    case "D1",     s = "discharges of low energy";
    case "D2",     s = "discharges of high energy";
    case "T1",     s = "thermal fault below 300 degC";
    case "T2",     s = "thermal fault 300 to 700 degC";
    case "T3",     s = "thermal fault above 700 degC";
    otherwise,     s = string(c);
end
end

function s = disagreeText(d, m, a)
names = ["Rogers", "IEC 60599", "Duval"];  ans3 = [string(d.rogers), string(d.iec), string(d.duval)];
bad = find(~a.agrees);
parts = strings(0, 1);
for k = bad(:)'
    parts(end + 1, 1) = names(k) + " says " + ans3(k); %#ok<AGROW>
end
s = "Who differs from ML (" + m.fault_class + "): " + strjoin(parts, "; ") + ". D1/D2 counts as agreeing with D1 or D2; DT and ND never count as agreeing.";
end

%% ------------------------------------------------------------------------------------------------------------------------
function L = events(ER)
n = numel(ER);
L = ["WHAT HAPPENED AT THE SAMPLING EVENTS"; ""];
if n == 0
    L(end + 1, 1) = "No sampling event was diagnosed in this run.";
    return
end
nOK = 0; nAll = 0;
for k = 1:n
    R = ER(k).result;
    if R.ml.status == "OK"
        nOK = nOK + 1;  nAll = nAll + (R.agreement.count == 3);
    end
end
L(end + 1, 1) = sprintf("%d oil samples were taken at %s h. The dashboard diagnosed the next measured record at each of them (the table below the plots lists them).", n, strjoin(compose("%.0f", [ER.time_h]), ", "));
L(end + 1, 1) = sprintf("The ML model answered for %d of %d records; for %d of them all three classical methods agreed with it.", nOK, n, nAll);
L(end + 1, 1) = "Click a row of the event table to see the explanation of that record. The event time only places the sample on the operating timeline; the gas values belong to the measured record, not to the simulation.";
end
