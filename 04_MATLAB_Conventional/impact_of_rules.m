function [rules, gate] = impact_of_rules()
%IMPACT_OF_RULES  How much do decision D12 and the normality gate change the results? (evidence for Step 14)
%
%   [rules, gate] = impact_of_rules()
%
%   PURPOSE
%     Decision D12 amended three rules of decision D11 / Analysis Plan Eq. 10 after the written rules were run
%     on the real data. This function recomputes, from the frozen master table, the numbers that justified it,
%     so that the Step 14 report can quote saved output instead of a scratch calculation.
%
%   OUTPUT
%     rules  table of counts (item, value, explanation):
%              n_records                       records in the master table
%              n_any_undefined_ratio           records with at least one zero denominator (R1, R2 or R5)
%              iec_nd_rule_D11_strict          IEC "ND" if ANY ratio is undefined (D11 as first written), final rules (with D13)
%              iec_nd_rule_D12                 IEC "ND" only if a ratio the class uses is undefined (D12), final rules (with D13)
%              iec_recovered_by_D12            records that D11-strict calls ND but D12 diagnoses, final rules (with D13)
%              *_before_D13                    the same three numbers when T1 still ignored CH4/H2: the figures on which the
%                                              researcher decided D12 (1) on 2026-10-11 (D13 came later the same day)
%              iec_match_D1_and_D2             records matching both D1 and D2 (dual answer D1/D2)
%              iec_match_PD_and_T1             records matching both PD and T1 under the final rules (0 since decision D13)
%              iec_PD_T1_overlap_if_T1_ignores_R1  records that WOULD match both if T1 ignored CH4/H2 (the printed "NS" read
%                                              literally): the evidence for decisions D12 (2) and D13
%              iec_match_PD_alone              records whose IEC result is PD alone (0 before D13, see below)
%              rogers_nd                       Rogers ND (unchanged by D12: Rogers uses all three ratios)
%     gate   table: data_role, true_class, n, n_gate_upper, n_gate_lower  (records the normality gate calls Normal)
%
%   NOTE: if T1 ignored CH4/H2 (its printed entry ">1 but NS" read as "not significant"), T1 needs only R5 < 1 and every sample
%   that satisfies PD (R1 < 0.1, R5 < 0.2) also satisfies T1, so IEC "PD" could only appear as "PD/T1" (decision D12 (2)).
%   Decision D13 (researcher, 2026-10-11) uses the printed ">1" as the condition R1 > 1 for T1, which removes the overlap.
%
%   Written to 11_Results/conventional/impact_of_rules.csv and gate_by_class.csv.
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 14 (evidence for decision D12).

C = conv_config();
verify_data_version('Quiet', true);
S = load_standards();
M = readtable(C.masterFile, 'TextType', 'string');
g = struct('H2', M.H2, 'CH4', M.CH4, 'C2H6', M.C2H6, 'C2H4', M.C2H4, 'C2H2', M.C2H2, 'equipment_type', M.equipment_type);
d = conventional_diagnosis(g);
R = [d.ratios.R1, d.ratios.R2, d.ratios.R5];
anyUndef = any(isnan(R), 2);
[~, mm, cls] = diagnose_ratio_method(R, S.iec.rows);
rawI = d.raw.iec;
strictND = (rawI == "ND") | anyUndef;                      % D11 as first written: any undefined ratio -> ND
col = @(name) find(cls == name, 1);

% T1 as it would be if its CH4/H2 entry were ignored: only the C2H4/C2H6 row is used
t1r5 = S.iec.rows(S.iec.rows.cls == "T1" & S.iec.rows.rid == "R5", :);
oldT1 = bound_test(R(:, 3), t1r5.bound_type, t1r5.lower, t1r5.upper);
% the same counts at the time of decision D12, i.e. with the T1 entry for CH4/H2 ignored
rows12 = S.iec.rows;
rows12.ignored(rows12.cls == "T1" & rows12.rid == "R1") = true;
lab12 = diagnose_ratio_method(R, rows12);
strict12 = (lab12 == "ND") | anyUndef;
item = ["n_records"; "n_any_undefined_ratio"; "iec_nd_rule_D11_strict"; "iec_nd_rule_D12"; "iec_recovered_by_D12"; ...
        "iec_nd_rule_D11_strict_before_D13"; "iec_nd_rule_D12_before_D13"; "iec_recovered_by_D12_before_D13"; ...
        "iec_match_D1_and_D2"; "iec_match_PD_and_T1"; "iec_PD_T1_overlap_if_T1_ignores_R1"; "iec_match_PD_alone"; "rogers_nd"];
value = [height(M); nnz(anyUndef); nnz(strictND); nnz(rawI == "ND"); nnz(strictND & rawI ~= "ND"); ...
         nnz(strict12); nnz(lab12 == "ND"); nnz(strict12 & lab12 ~= "ND"); ...
         nnz(mm(:, col("D1")) & mm(:, col("D2"))); nnz(mm(:, col("PD")) & mm(:, col("T1"))); ...
         nnz(mm(:, col("PD")) & oldT1); nnz(rawI == "PD"); nnz(d.raw.rogers == "ND")];
expl = ["records in dga_master.csv"; "records with a zero denominator in R1, R2 or R5"; ...
        "IEC ND if any ratio undefined"; "IEC ND if only a ratio the class uses is undefined"; ...
        "diagnosed under D12 but ND under D11-strict"; ...
        "as above, when T1 still ignored CH4/H2 (figures of decision D12)"; "as above, when T1 still ignored CH4/H2 (figures of decision D12)"; ...
        "as above, when T1 still ignored CH4/H2 (figures of decision D12)"; "IEC dual answer D1/D2"; "records matching PD and T1 under the final rules (D13)"; ...
        "records that would match PD and T1 if T1 ignored CH4/H2 (evidence for D12 (2) and D13)"; "IEC result PD alone"; "Rogers ND before the gate (every case uses all three ratios, so D12 changes nothing)"];
% Duval geometry (Analysis Plan Eq. 10, decision D12)
Z = duval_zone_polygons(S);
E = duval_decision_edges(S);
areaSum = sum(arrayfun(@(z) polyarea(z.poly(:, 1), z.poly(:, 2)), Z));
item  = [item; "duval_rule_polygons"; "duval_polygon_area_sum"; "duval_decision_edge_pieces"];
value = [value; numel(Z); areaSum; height(E)];
expl  = [expl; "convex polygons built from the Duval rules (one per rule)"; ...
         "sum of the polygon areas in (%C2H4, %C2H2) coordinates; the triangle has area 100 x 100 / 2 = 5000"; ...
         "edge pieces that separate two different zones (triangle sides and same-zone seams excluded)"];
rules = table(item, value, expl, 'VariableNames', {'item', 'value', 'explanation'});

trueClass = M.class_name;  miss = ismissing(trueClass);  trueClass(miss) = M.class_merged(miss);
keys = unique(table(M.data_role, trueClass), 'rows', 'stable');
rows = cell(height(keys), 0);
for k = 1:height(keys)
    sel = M.data_role == keys{k, 1} & trueClass == keys{k, 2};
    rows(k, 1:5) = {keys{k, 1}, keys{k, 2}, nnz(sel), nnz(d.gate_upper(sel)), nnz(d.gate_lower(sel))};
end
gate = cell2table(rows, 'VariableNames', {'data_role', 'true_class', 'n', 'n_gate_upper', 'n_gate_lower'});

writetable(rules, fullfile(C.outDir, 'impact_of_rules.csv'));
writetable(gate, fullfile(C.outDir, 'gate_by_class.csv'));
disp(rules(:, 1:2)); disp(gate);
end
