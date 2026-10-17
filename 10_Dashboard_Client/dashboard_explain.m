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
%   L = dashboard_explain('steps', g, d, m, a, V)            the standard workflow, step by step, with the numbers of ONE sample
%                                                            (V = dashboard_verdict; 17 Oct 2026)
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
    case "steps",      L = steps(varargin{:});
    case "label",      L = methodShort(varargin{1});
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
    "1. Choose the operating condition (constant rated load, daily cycle or short overload) and which oil samples to look at (a mixed set with a healthy sample and every fault type, random samples, or the first samples)."
    "2. Press 'Run simulation + diagnose'. The model simulates the transformer and takes the oil samples (the sampling events, numbered #1, #2, ... on the plot). For every sample the dashboard reads one measured gas record, asks three classical methods (Rogers, IEC 60599, Duval Triangle) and the machine-learning (ML) model for a diagnosis, and shows them side by side."
    "3. The coloured banner at the top is the answer: GREEN = healthy, RED = fault (with the fault type), AMBER = watch or check. Under it, the four method cards show who says what and whether each one AGREES with the verdict."
    "4. Click a row of the sample table to look at another sample. Or pick a record yourself: choose a fault type, press 'Pick random record'; or use 'Load measured DGA file', enter a record number and press 'Diagnose selected record'."
    "5. The tab 'Step by step' shows the standard procedure (IEC 60599 / IEEE C57.104) with the numbers of the sample; this panel explains the result in words."
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

function s = methodShort(x)
% Plain meaning of a method's answer for the method cards (a scalar string).
switch string(x)
    case "",       s = "not available";
    case "Normal", s = "no fault indicated (healthy)";
    case "DT",     s = "mixture of thermal and electrical fault: no single type";
    case "ND",     s = "no diagnosis: the ratios fit no coded fault";
    case "D1/D2",  s = "a discharge, but low or high energy cannot be told apart";
    otherwise,     s = shortName(x);
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
function L = steps(g, d, m, a, V) %#ok<INUSL>
% The procedure of IEC 60599 (interpretation of dissolved gas analysis) and IEEE C57.104-2008, applied to ONE sample.
rid = ""; if isfield(g, 'record_id'), rid = " (record " + string(g.record_id) + ")"; end
r = d.ratios;
L = ["THE STANDARD PROCEDURE, STEP BY STEP" + rid; ""];
L = [L; "STEP 1 - The sample"
    sprintf("Five gases dissolved in the oil were measured (ppm = parts per million): hydrogen H2 %.8g, methane CH4 %.8g, ethane C2H6 %.8g, ethylene C2H4 %.8g, acetylene C2H2 %.8g. They come from the data file; the dashboard never changes them.", g.H2, g.CH4, g.C2H6, g.C2H4, g.C2H2)
    ""];
G = V.gas;
L = [L; "STEP 2 - Is the gas level normal? (IEC 60599 Annex A, typical values)"];
for k = 1:height(G)
    if G.above(k), w = "ABOVE"; else, w = "within"; end
    L(end + 1, 1) = sprintf("  %-5s %10.8g ppm   typical value up to %g ppm   -> %s (%.2g times the typical value)", G.gas(k), G.ppm(k), G.typical_high(k), w, G.times_typical(k)); %#ok<AGROW>
end
if V.health == "healthy"
    L(end + 1, 1) = "Result: all five gases are within the typical values, so the standard's screening says: HEALTHY. The procedure stops here for a healthy transformer; the ratios below are shown for information only.";
elseif d.gate_upper(1)
    L(end + 1, 1) = "Result: all five gases are within the typical values (normal gas level). The ratio methods are shown below for information.";
else
    L(end + 1, 1) = sprintf("Result: %d of 5 gases are above their typical values, so a fault is possible and its type is read from the gas ratios (steps 3 to 6). Typical values are what 90 %% of transformers show; they are not fault limits.", sum(G.above));
end
L(end + 1, 1) = "";
L = [L; "STEP 3 - The gas ratios (the fingerprints of the fault types)"
    "  Ratios compare one gas with another. Different faults make different mixtures of gases."
    "  " + ratioLine("CH4 / H2", r.R1) + "   " + ratioLine("C2H2 / C2H4", r.R2) + "   " + ratioLine("C2H4 / C2H6", r.R5)
    "  Duval percentages of CH4, C2H4 and C2H2 together: " + sprintf("%%CH4 = %s, %%C2H4 = %s, %%C2H2 = %s", num(r.pct_CH4), num(r.pct_C2H4), num(r.pct_C2H2))
    ""
    "STEP 4 - IEC 60599 ratio method (Table 2 of IEC 60599:1999+A1:2007)"
    "  Answer: " + methodText(d.iec)
    ""
    "STEP 5 - Rogers ratio method (IEEE Std C57.104-2008, Table 6; table values TO VERIFY against a licensed copy)"
    "  Answer: " + methodText(d.rogers)
    ""
    "STEP 6 - Duval Triangle 1 (a point in a triangle made from %CH4, %C2H4, %C2H2; zones as published by Duval, TO VERIFY)"
    "  Answer: " + methodText(d.duval)
    ""
    "STEP 7 - Machine learning (Random Forest trained on labelled DGA records of this study)"];
if m.status == "OK"
    L(end + 1, 1) = sprintf("  Answer: %s, %s, with probability %.0f %%.", m.fault_class, shortName(m.fault_class), 100 * max(m.probabilities));
else
    L(end + 1, 1) = "  Not available (" + string(m.status) + "). The verdict below uses the three classical methods only.";
end
L(end + 1, 1) = "";
L(end + 1, 1) = "STEP 8 - Compare the methods and give the verdict";
names = V.methods;
for k = 1:4
    ans_k = V.answers(k);  if ans_k == "", ans_k = "not available"; end
    L(end + 1, 1) = sprintf("  %-10s %-14s %s", names(k), ans_k, V.judge(k)); %#ok<AGROW>
end
L(end + 1, 1) = "  (Each method gives one vote. D1/D2 votes for both D1 and D2. DT and ND are not single diagnoses and do not vote. The verdict needs at least two votes.)";
L(end + 1, 1) = "VERDICT: " + V.title;
L(end + 1, 1) = V.detail;
L(end + 1, 1) = "WHAT TO DO: " + V.action;
if V.has_ref
    ok = V.ref_ok;
    L(end + 1, 1) = "";
    L(end + 1, 1) = "CHECK AGAINST THE KNOWN LABEL: the data file says this record is " + V.ref + " (" + shortName(V.ref) + "). Right/wrong per method (compatible with the label): " + ...
        sprintf("Rogers %s, IEC 60599 %s, Duval %s, ML %s.", yn(ok(1)), yn(ok(2)), yn(ok(3)), yn(ok(4)));
    L(end + 1, 1) = "The label comes from the source of the record (inspection or the publication). It is used only for this check; it never changes a diagnosis.";
end
end

function s = ratioLine(name, x)
if isnan(x), s = name + " = undefined (the denominator is 0 ppm)"; else, s = sprintf("%s = %.3g", name, x); end
end

function s = num(x)
if isnan(x), s = "undefined"; else, s = sprintf("%.1f", x); end
end

function s = yn(tf)
if tf, s = "right"; else, s = "wrong"; end
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
if isfield(ER(1).result, 'verdict')
    hl = arrayfun(@(e) string(e.result.verdict.health), ER);
    L(end + 1, 1) = sprintf("Verdicts of this run: %d healthy, %d fault, %d watch or check.", sum(hl == "healthy"), sum(hl == "fault"), sum(hl == "watch" | hl == "undecided"));
end
L(end + 1, 1) = "Click a row of the event table to see the explanation of that record. The event time only places the sample on the operating timeline; the gas values belong to the measured record, not to the simulation.";
end
