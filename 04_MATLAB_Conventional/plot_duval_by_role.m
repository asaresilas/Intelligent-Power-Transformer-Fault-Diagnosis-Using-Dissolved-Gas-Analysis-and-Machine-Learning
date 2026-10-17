function out = plot_duval_by_role()
%PLOT_DUVAL_BY_ROLE  Figure 4.4: Duval Triangle 1 for each data role (roadmap Step 17).
%
%   out = plot_duval_by_role()
%
%   For each data role (development, internal_test, benchmark, external_test) of the frozen master table
%   draw Duval Triangle 1 (zones from duval_triangle_zones.csv) and plot every record at its position, coloured
%   and shaped by its TRUE class (11_Results/figures/plot_style.csv). Saves, in 11_Results/figures:
%     duval_<role>.png   300 dpi
%     duval_<role>.pdf   vector
%     duval_<role>.csv   the plotted points: record_id, true_class, pct_CH4, pct_C2H4, pct_C2H2, x, y,
%                        duval_zone (zone by the rules, before any normality gate), data_role
%   The records are plotted exactly where they fall, WITHOUT the normality gate: the figure shows where the true
%   classes lie on the chart, which is independent of the gate. Records with CH4 + C2H4 + C2H2 = 0 ppm have no
%   position and are not plotted; their number is reported.
%
%   TRUE CLASS: class_name (Normal PD D1 D2 T1 T2 T3). 32 records of IEC TC 10 origin whose inspection could not
%   separate T1 from T2 have no class_name; their class_merged "T12" (style item "T1/T2 merged") is used.
%
%   OUTPUT  out  table: data_role, n_records, n_plotted, n_not_plotted
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 17 (Figure 4.4).

C = conv_config();
verify_data_version('Quiet', true);                        % rule 2: only data version 1.0
S = load_standards();
M = readtable(C.masterFile, 'TextType', 'string');
roles = ["development" "internal_test" "benchmark" "external_test"];
title_ = dictionary(roles, ["Development set" "Internal test set" "IEC TC 10 benchmark" "External test set (Li 2019)"]);

trueClass = M.class_name;
miss = ismissing(trueClass);
trueClass(miss) = M.class_merged(miss);                    % "T12" for the inspected T1/T2 records

r = gas_ratios(struct('H2', M.H2, 'CH4', M.CH4, 'C2H6', M.C2H6, 'C2H4', M.C2H4, 'C2H2', M.C2H2));
zone = diagnose_duval(r.pct_CH4, r.pct_C2H4, r.pct_C2H2, S.duval.rules);
[x, y] = duval_xy(r.pct_C2H4, r.pct_C2H2, C.pctTotal);

if ~isfolder(C.figDir), mkdir(C.figDir); end
st = readtable(C.styleFile, 'TextType', 'string');
inkHex = char(st.colour_hex(st.kind == "ink" & st.item == "text"));
ink = sscanf(inkHex(1, 2:7), '%2x').' / 255;                 % text colour from plot_style.csv
res = zeros(numel(roles), 3);
for k = 1:numel(roles)
    sel = (M.data_role == roles(k));
    ok = sel & ~isnan(x);
    rk = struct('pct_C2H4', r.pct_C2H4(ok), 'pct_C2H2', r.pct_C2H2(ok));
    fig = figure('Visible', 'off', 'Color', 'w', 'Units', 'inches', 'Position', [1 1 6.8 6.0]);
    try theme(fig, 'light'); catch, end                     % publication figures are light, whatever the desktop theme
    ax = axes(fig);
    plot_duval_triangle(ax, rk, [], 'Classes', trueClass(ok));
    title(ax, sprintf('Duval Triangle 1 - %s (%d of %d records plotted)', title_(roles(k)), nnz(ok), nnz(sel)), ...
        'FontSize', 10, 'FontWeight', 'normal', 'Color', ink);
    lgd = legend(ax, 'Location', 'southoutside', 'NumColumns', 3, 'Box', 'off', 'FontSize', 8, 'TextColor', ink);
    lgd.ItemTokenSize = [12 8];
    base = fullfile(C.figDir, "duval_" + roles(k));
    exportgraphics(fig, base + ".png", 'Resolution', 300);
    exportgraphics(fig, base + ".pdf", 'ContentType', 'vector');
    close(fig);
    pts = table(M.record_id(ok), trueClass(ok), r.pct_CH4(ok), r.pct_C2H4(ok), r.pct_C2H2(ok), x(ok), y(ok), zone(ok), ...
        repmat(roles(k), nnz(ok), 1), 'VariableNames', ...
        {'record_id', 'true_class', 'pct_CH4', 'pct_C2H4', 'pct_C2H2', 'x', 'y', 'duval_zone', 'data_role'});
    writetable(pts, base + ".csv");
    res(k, :) = [nnz(sel), nnz(ok), nnz(sel) - nnz(ok)];
    fprintf('%-14s %3d records, %3d plotted -> %s\n', roles(k), nnz(sel), nnz(ok), base);
end
out = table(roles.', res(:, 1), res(:, 2), res(:, 3), 'VariableNames', {'data_role', 'n_records', 'n_plotted', 'n_not_plotted'});
end
