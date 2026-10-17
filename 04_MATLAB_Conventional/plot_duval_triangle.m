function plot_duval_triangle(ax, r, zoneFile, varargin)
%PLOT_DUVAL_TRIANGLE  Draw Duval Triangle 1 with its zones, decision edges, scales and sample points.
%
%   plot_duval_triangle(ax, r)                          one sample, r = gas_ratios(...) (dashboard use)
%   plot_duval_triangle(ax, r, zoneFile)                same; zoneFile is accepted for compatibility with
%                                                       DGADashboard_reference.m and is NOT needed: the zones
%                                                       are always built from 02_Standards/duval_triangle_zones.csv
%   plot_duval_triangle(ax, r, [], 'Classes', cls)      many samples, coloured and shaped by true class
%
%   INPUT   ax   target axes (e.g. app.UIAxesDuval or axes(figure))
%           r    struct with fields pct_C2H4 and pct_C2H2 [%] (scalars or equal-size arrays)
%   NAME-VALUE
%           'Classes'     string array (same length as the points): class of each point, one of the class
%                         names in 11_Results/figures/plot_style.csv (Normal PD D1 D2 T1 T2 T12 T3).
%                         Without it all points are drawn as one group.
%           'MarkerSize'  marker area in points^2 (default set in the code: 22)
%
%   WHAT IS DRAWN (plane of a triangle with side 100: 1 unit = 1 percentage point)
%     - zones: polygons of the 10 rules in duval_triangle_zones.csv (duval_zone_polygons), light tint of the
%       class colour from plot_style.csv; DT in neutral grey (DT has no class colour);
%     - decision edges: the lines that separate two different zones (duval_decision_edges);
%     - scale: light grid every 20 %, tick labels: %CH4 on the right side, %C2H4 on the base, %C2H2 on the left side;
%     - points: marker colour and shape per class from plot_style.csv (colour_hex, marker_matlab).
%   Colours and markers are never typed here: they are read from 11_Results/figures/plot_style.csv.
%
%   Project: MPhil, DGA transformer fault diagnosis - Steps 14 and 17 (Figure 4.4).

p = inputParser;
addParameter(p, 'Classes', strings(0, 1));
addParameter(p, 'MarkerSize', 22);
parse(p, varargin{:});

C = conv_config();
S = load_standards();
style = read_style(C);
T = C.pctTotal;
step = T / 5;                                               % grid and tick spacing: 20 % (5 divisions)

cla(ax); hold(ax, 'on'); axis(ax, 'equal'); axis(ax, 'off');
ink = style_colour(style, 'ink', 'text');
muted = style_colour(style, 'ink', 'muted');
gridc = style_colour(style, 'ink', 'grid');

% ---- zones (filled), from the rules ------------------------------------------------------------
Z = duval_zone_polygons(S);
for i = 1:numel(Z)
    [zx, zy] = duval_xy(Z(i).poly(:, 1), Z(i).poly(:, 2), T);
    col = zone_colour(style, Z(i).zone, gridc);
    patch(ax, zx, zy, col, 'FaceAlpha', 0.22, 'EdgeColor', 'none', 'HandleVisibility', 'off');
end

% ---- light grid every 20 % ----------------------------------------------------------------------
for v = step:step:T - step
    % constant %CH4 = v:   a + b = T - v        constant %C2H4 = v:  a = v        constant %C2H2 = v:  b = v
    seg = {[0 T - v; T - v 0], [v 0; v T - v], [0 v; T - v v]};
    for s = 1:3
        [gx, gy] = duval_xy(seg{s}(:, 1), seg{s}(:, 2), T);
        plot(ax, gx, gy, '-', 'Color', gridc, 'LineWidth', 0.4, 'HandleVisibility', 'off');
    end
    % tick labels: %CH4 on the right side (b = 0), %C2H4 on the base (CH4 = 0), %C2H2 on the left side (a = 0)
    [tx, ty] = duval_xy(T - v, 0, T);   text(ax, tx + 2, ty + 1, sprintf('%d', T - (T - v)), 'FontSize', 7, 'Color', muted, 'HorizontalAlignment', 'left');
    [tx, ty] = duval_xy(v, T - v, T);   text(ax, tx, ty - 4, sprintf('%d', v), 'FontSize', 7, 'Color', muted, 'HorizontalAlignment', 'center');
    [tx, ty] = duval_xy(0, v, T);       text(ax, tx - 2, ty + 1, sprintf('%d', v), 'FontSize', 7, 'Color', muted, 'HorizontalAlignment', 'right');
end

% ---- decision edges and outline -------------------------------------------------------------------
E = duval_decision_edges(S);
for e = 1:height(E)
    plot(ax, [E.x1(e) E.x2(e)], [E.y1(e) E.y2(e)], '-', 'Color', muted, 'LineWidth', 0.9, 'HandleVisibility', 'off');
end
[ox, oy] = duval_xy([0 T 0 0], [0 0 T 0], T);
plot(ax, ox, oy, '-', 'Color', ink, 'LineWidth', 1.2, 'HandleVisibility', 'off');

% ---- zone names -----------------------------------------------------------------------------------------
% Large zones are named at the centroid of their largest polygon. The thin zones (PD, T1, T2: area below
% 3 % of the triangle) lie along the right side where most points fall, so their names are placed outside
% the right side with a short leader line. (Layout only; no decision depends on this.)
names = unique([Z.zone], 'stable');
outward = [sqrt(3) / 2, 1 / 2];                           % outward normal of the right side (C2H2 = 0)
for k = 1:numel(names)
    idx = find([Z.zone] == names(k));
    area = arrayfun(@(i) polyarea(Z(i).poly(:, 1), Z(i).poly(:, 2)), idx);
    [~, big] = max(area);
    P = Z(idx(big)).poly;
    [cx, cy] = duval_xy(mean(P(:, 1)), mean(P(:, 2)), T);
    if sum(area) < 0.03 * T^2 / 2
        lx = cx + 16 * outward(1);  ly = cy + 16 * outward(2);
        plot(ax, [cx lx], [cy ly], '-', 'Color', muted, 'LineWidth', 0.6, 'HandleVisibility', 'off');
        text(ax, lx + 1, ly, names(k), 'HorizontalAlignment', 'left', 'FontSize', 8, 'Color', ink, 'FontWeight', 'bold');
    else
        text(ax, cx, cy, names(k), 'HorizontalAlignment', 'center', 'FontSize', 8, 'Color', ink, 'FontWeight', 'bold', 'Clipping', 'on');
    end
end

% ---- corner and axis labels ---------------------------------------------------------------------------
[tx, ty] = duval_xy(0, 0, T);   text(ax, tx, ty + 6, '100 % CH_4', 'HorizontalAlignment', 'center', 'FontSize', 8, 'Color', ink);
[tx, ty] = duval_xy(T, 0, T);   text(ax, tx + 2, ty - 8, '100 % C_2H_4', 'HorizontalAlignment', 'center', 'FontSize', 8, 'Color', ink);
[tx, ty] = duval_xy(0, T, T);   text(ax, tx - 2, ty - 8, '100 % C_2H_2', 'HorizontalAlignment', 'center', 'FontSize', 8, 'Color', ink);
[tx, ty] = duval_xy(T / 2, T / 2, T); text(ax, tx, ty - 11, '% C_2H_4  \rightarrow', 'HorizontalAlignment', 'center', 'FontSize', 8, 'Color', muted);

% ---- points ---------------------------------------------------------------------------------------------
[px, py] = duval_xy(r.pct_C2H4(:), r.pct_C2H2(:), T);
valid = ~isnan(px);
cls = p.Results.Classes(:);
if isempty(cls)
    plot(ax, px(valid), py(valid), 'o', 'MarkerFaceColor', ink, 'MarkerEdgeColor', 'w', ...
        'MarkerSize', sqrt(p.Results.MarkerSize) + 2, 'DisplayName', 'sample');
else
    order = style(style.kind == "class", :);
    order = sortrows(order, 'order');
    for k = 1:height(order)
        sel = valid & (cls == order.item(k));
        if ~any(sel), continue, end
        mk = char(order.marker_matlab(k));
        col = hex2rgb(order.colour_hex(k));
        lab = sprintf('%s (n = %d)', order.label(k), nnz(sel));
        if any(mk == 'x+*.')                              % line markers cannot be filled: draw them in the class colour
            scatter(ax, px(sel), py(sel), p.Results.MarkerSize, col, mk, 'LineWidth', 1.1, 'DisplayName', lab);
        else
            scatter(ax, px(sel), py(sel), p.Results.MarkerSize, col, mk, 'filled', 'MarkerFaceAlpha', 0.7, ...
                'MarkerEdgeColor', 'w', 'LineWidth', 0.3, 'DisplayName', lab);
        end
    end
end
xlim(ax, [-14 T + 14]); ylim(ax, [-14 sqrt(3) / 2 * T + 10]);
hold(ax, 'off');
end

function style = read_style(C)
opts = detectImportOptions(C.styleFile, 'TextType', 'string');
opts = setvartype(opts, opts.VariableNames, 'string');
opts = setvartype(opts, 'order', 'double');
style = readtable(C.styleFile, opts);
end

function col = style_colour(style, kind, item)
col = hex2rgb(style.colour_hex(style.kind == kind & style.item == item));
end

function col = zone_colour(style, zone, fallback)
% Class colour of a zone from plot_style.csv; DT (thermal and electrical) has no class: neutral grey.
row = style(style.kind == "class" & style.item == zone, :);
if isempty(row), col = fallback; else, col = hex2rgb(row.colour_hex(1)); end
end

function rgb = hex2rgb(h)
% "#2A78D6" -> [0.165 0.471 0.839]
h = char(h);
rgb = sscanf(h(2:7), '%2x').' / 255;
end
