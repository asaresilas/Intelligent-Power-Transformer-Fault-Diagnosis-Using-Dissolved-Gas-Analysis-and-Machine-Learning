function [zone, ruleIdx] = diagnose_duval(pctCH4, pctC2H4, pctC2H2, rules)
%DIAGNOSE_DUVAL  Duval Triangle 1 zone of a sample from its three percentages.
%
%   [zone, ruleIdx] = diagnose_duval(pctCH4, pctC2H4, pctC2H2, rules)
%
%   INPUT   pctCH4, pctC2H4, pctC2H2  [%] arrays of equal size (NaN when CH4+C2H4+C2H2 = 0)
%           rules  table S.duval.rules from load_standards (10 rules, sorted by rule_order)
%   OUTPUT  zone     string array: PD T1 T2 T3 DT D1 D2, or "ND"
%           ruleIdx  index of the rule that fired (0 for ND)
%
%   RULES (decision D11, rule 4 of the Steps 14-17 instructions)
%     Rules are tried in rule_order and the first match wins. For every percentage the lower limit is
%     inclusive (>=) and the upper limit exclusive (<); a blank limit means "no limit". DT is a valid
%     zone (thermal and electrical fault) and is returned as "DT".
%     Undefined percentages (all three gases 0 ppm) -> "ND"; so does a point that no rule covers.
%
%   SOURCE  Duval Triangle 1 limits in 02_Standards/duval_triangle_zones.csv (secondary source:
%   Moser 2025 Table 1 citing IEEE C57.104-2019 clause 6.2.3; Manisha et al. 2022 Figure 2).
%   STATUS  TO VERIFY against IEC 60599:2022 Figure B.3 or IEEE C57.104-2019 (see D10 / Step 12).
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 14.

pct = {pctCH4, pctC2H4, pctC2H2};
nm  = {'CH4', 'C2H4', 'C2H2'};
zone = repmat("ND", size(pctCH4));
ruleIdx = zeros(size(pctCH4));
free = ~isnan(pctCH4) & ~isnan(pctC2H4) & ~isnan(pctC2H2);
for k = 1:height(rules)
    hit = free;
    for g = 1:3
        lo = rules.(['pct_' nm{g} '_min'])(k);
        hi = rules.(['pct_' nm{g} '_max'])(k);
        if ~isnan(lo), hit = hit & (pct{g} >= lo); end
        if ~isnan(hi), hit = hit & (pct{g} <  hi); end
    end
    hit = hit & (ruleIdx == 0);
    zone(hit) = rules.zone(k);
    ruleIdx(hit) = k;
end
end
