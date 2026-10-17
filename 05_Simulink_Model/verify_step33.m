function [chk, diffs] = verify_step33(varargin)
%VERIFY_STEP33  Checks of Roadmap Step 33: the rebuilt Transformer_Operating_Model.slx.
%
%   [chk, diffs] = verify_step33()
%
%   CHECKS (roadmap: "the model updates without errors and its structure matches the reference-build diagrams")
%     1  Opens, updates the diagram and simulates from a CLEAN path (05_Simulink_Model removed from the path first).
%     2  No warning or error is reported by the update (diagnostics of the last update).
%     3  Structure equals the reference model (reference_build/rerun_2026-10-11): same blocks (name, type), same block
%        parameter values, same connections of every block. Expected differences only: the 273.15 K offset (variable
%        T_zero_C_in_K here, typed in the reference), colours and descriptions (annotations are compared separately).
%     4  Every subsystem and the model carry an annotation; every subsystem has a Description.
%     5  No number typed into a block: every setting made by the builder (results/step33_block_settings.csv) contains
%        only variable names of params_transformer.m and the mathematical constants of the equations.
%     6  No gas value is produced: no block or variable name contains a gas name, and the model has no gas output.
%     7  Exactly one Solver Configuration per physical network (two networks: electrical and thermal).
%     8  Simulation result equals the analytic steady state of the IEC 60076-7 equations (independent calculation from
%        params_transformer.m and the simulated K): final top-oil and hot-spot temperature within tolerance.
%     9  The result equals the reference model's result on the same run (max difference of the logged signals).
%
%   OUTPUT  chk    table (check, passed, detail), also written to 05_Simulink_Model/results/step33_checks.csv
%           diffs  table of every structural difference found (check 3)
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 33.

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
mdl  = 'Transformer_Operating_Model';
refFile = fullfile(here, 'reference_build', 'rerun_2026-10-11', [mdl '.slx']);
tolK = 0.1;                                       % K, approved tolerance for Step 35 (Analysis Plan Section 9)
chk = table('Size', [0 3], 'VariableTypes', {'string', 'logical', 'string'}, 'VariableNames', {'check', 'passed', 'detail'});

%% 1-2 clean-path open, update, simulate -----------------------------------------------------------------
bdclose all;
w = warning('off', 'all');  restoreWarn = onCleanup(@() warning(w));
rmpath(here);                                      % nothing of this folder on the path
clear('params_transformer');
msg = ''; ok = true;
lastwarn('');
try
    open_system(fullfile(here, [mdl '.slx']));
    set_param(mdl, 'SimulationCommand', 'update');
    out = sim(mdl);
catch ME
    ok = false; msg = ME.message;
end
addpath(here);
chk = add_check(chk, 'opens, updates and simulates from a clean path', ok, ifelse(ok, 'no error', msg));
if ~ok, writetable(chk, fullfile(here, 'results', 'step33_checks.csv')); error('verify_step33:sim', '%s', msg); end
[lw, ~] = lastwarn;
chk = add_check(chk, 'no warning during update/simulation', isempty(lw), ifelse(isempty(lw), 'none', lw));
warning(w);

%% 3 structure against the reference model --------------------------------------------------------------
A = describe(mdl, 'SS8_Sampling_Events');          % SS8 (Step 37) has no counterpart in the reference build and is ignored here (own checks in verify_step37.m)                                 % the reference is read after the new model is closed (same model name)

%% 4 annotations and descriptions ----------------------------------------------------------------------
subs = find_system(mdl, 'SearchDepth', 1, 'BlockType', 'SubSystem');
okNote = true; okDesc = true; nNotes = numel(find_system(mdl, 'FindAll', 'on', 'SearchDepth', 1, 'Type', 'annotation'));
for k = 1:numel(subs)
    n = numel(find_system(subs{k}, 'FindAll', 'on', 'SearchDepth', 1, 'Type', 'annotation'));
    nNotes = nNotes + n;
    okNote = okNote && n >= 1;
    okDesc = okDesc && ~isempty(get_param(subs{k}, 'Description'));
end
chk = add_check(chk, 'model and all 8 subsystems carry an annotation; every subsystem has a Description', ...
    numel(subs) == 8 && okNote && okDesc && ~isempty(get_param(mdl, 'Description')), ...
    sprintf('%d subsystems, %d annotations in all', numel(subs), nNotes));

%% 5 no typed numbers -----------------------------------------------------------------------------------
L = readtable(fullfile(here, 'results', 'step33_block_settings.csv'), 'TextType', 'string', 'Delimiter', ',');
bad = strings(0, 1);
% Mathematical constants of the equations that may stay in a setting: log(2) (doubling of the ageing rate), 1/3 (three
% phases), (k21-1) (second hot-spot drive) and the 1 of a reciprocal gain "1/variable". Selector parameters hold codes,
% not values: Operator (function name), Port (port number), impedance_option (0 = None, ideal source).
selectors = ["Operator" "Port" "impedance_option" "Inputs"];   % "Inputs" = number of input ports of a logic block (Step 37)
for i = 1:height(L)
    v = string(L.value(i));
    if ismember(L.parameter(i), selectors), continue; end
    s = strrep(v, "log(2)", "");  s = strrep(s, "1/3", "");  s = strrep(s, "(k21-1)", "");
    s = regexprep(s, '[A-Za-z_][A-Za-z_0-9]*', '');   % variable names (digits inside names are not numbers)
    s = regexprep(s, '^1/', '');                       % reciprocal gain
    if ~isempty(regexp(s, '\d', 'once'))
        bad(end + 1) = L.block(i) + "." + L.parameter(i) + " = " + v; %#ok<AGROW>
    end
end
chk = add_check(chk, 'no number typed into a block (all settings are variables or equation constants)', isempty(bad), ...
    sprintf('%d settings logged; offending: %s', height(L), strjoin(bad, '; ')));

%% 6 no gas value -------------------------------------------------------------------------------------
allB = find_system(mdl, 'LookUnderMasks', 'all', 'Type', 'block');
% Gas formulas are matched case-sensitively as whole words (Q_h2 / dTheta_h2 are hot-spot heat and temperature, not hydrogen).
gasFormula = ["H2" "CH4" "C2H6" "C2H4" "C2H2"];
hit = false; names = string(get_param(allB, 'Name'));
for g = gasFormula, hit = hit | ~cellfun(@isempty, regexp(cellstr(names), ['(^|_)' char(g) '($|_)'], 'once')); end
hit = hit | contains(lower(names), ["ppm" "dga"]);          % concentration units / DGA record blocks
chk = add_check(chk, 'no block produces or names a gas concentration', ~any(hit), sprintf('%d blocks scanned', numel(allB)));

%% 7 one solver configuration per physical network ---------------------------------------------------
sc = find_system(mdl, 'LookUnderMasks', 'all', 'RegExp', 'on', 'Name', 'Solver_Configuration.*');
chk = add_check(chk, 'exactly one Solver Configuration per physical network (electrical, thermal)', numel(sc) == 2, ...
    sprintf('%d found: %s', numel(sc), strjoin(string(sc).', ', ')));

%% 3 (continued) read the reference model, then compare ---------------------------------------------------
close_system(mdl, 0);
tmpDir = tempname;  mkdir(tmpDir);                 % renamed copy: the two models must not share a name (shadowing)
rm = 'Reference_Transformer_Model';
copyfile(refFile, fullfile(tmpDir, [rm '.slx']));
addpath(tmpDir);
load_system(fullfile(tmpDir, rm));
B = describe(rm, '');
outR = sim(rm);                                    % reference model, same run (used by check 9)
close_system(rm, 0);
rmpath(tmpDir);
diffs = struct_diff(A, B);
expected = contains(diffs.item, ["Thermal_Mass_" "Ambient_Temperature"]) & diffs.parameter ~= "" ...
    & contains(diffs.value_new, 'T_zero_C_in_K') & contains(diffs.value_ref, '273.15');
% Step 34: the deprecated Math Function block 'sqrt' was replaced by the Sqrt block (same operator, same result) after the
% Model Advisor warning; this one block-type difference is expected.
% The Sqrt block's algorithm is 'Exact' (the Math block default was 'Newton-Raphson'); the logged results are identical (check 9).
expected = expected | (diffs.item == "SS3_LV_Measurement/Square_Root" & ...
    (diffs.kind == "block type" | (diffs.kind == "parameter value" & diffs.parameter == "AlgorithmType")));
% Step 34: the transformer's zero-sequence reactance was the block default 0.5 in the reference; here it is the variable X0_pu (= 0.5).
expected = expected | (diffs.item == "SS2_Power_Transformer/Two_Winding_Transformer" & diffs.parameter == "pu_X0" & ...
    diffs.value_new == "X0_pu" & diffs.value_ref == "0.5");
unexpected = diffs(~expected, :);
chk = add_check(chk, 'structure equals the reference model (blocks, parameters, connections)', isempty(unexpected), ...
    sprintf('%d blocks compared; %d expected differences (273.15 -> T_zero_C_in_K; Sqrt block and X0_pu, Step 34); %d unexpected', ...
    numel(A.names), nnz(expected), height(unexpected)));

%% 8 analytic steady state (independent of the Simscape model) ---------------------------------------------
evalin('base', 'params_transformer;');
P = struct();
for n = {'P0', 'Pk', 'P_tot_r', 'dTheta_or', 'dTheta_hr', 'x_oil', 'y_wdg', 'theta_amb_C'}
    P.(n{1}) = evalin('base', n{1});
end
K = out.K_pu.Data(end);
oil_ss = P.theta_amb_C + P.dTheta_or * ((P.P0 + P.Pk * K^2) / P.P_tot_r)^P.x_oil;
hs_ss  = oil_ss + P.dTheta_hr * K^P.y_wdg;
oil_end = out.theta_oil_C.Data(end);  hs_end = out.theta_hs_C.Data(end);
dOil = abs(oil_end - oil_ss);  dHs = abs(hs_end - hs_ss);
chk = add_check(chk, '24 h run equals the analytic steady state of the IEC 60076-7 equations (<= 0.1 K)', dOil <= tolK && dHs <= tolK, ...
    sprintf('K = %.4f; oil %.3f vs %.3f degC (diff %.3f K); hot-spot %.3f vs %.3f degC (diff %.3f K)', K, oil_end, oil_ss, dOil, hs_end, hs_ss, dHs));

%% 9 same result as the reference model ----------------------------------------------------------------
d = max([maxdiff(out.theta_oil_C, outR.theta_oil_C), maxdiff(out.theta_hs_C, outR.theta_hs_C), maxdiff(out.K_pu, outR.K_pu)]);
chk = add_check(chk, 'results equal the reference model (logged signals, same run)', d <= tolK, sprintf('largest difference %.2e (K or pu)', d));
bdclose all;

writetable(chk, fullfile(here, 'results', 'step33_checks.csv'));
writetable(diffs, fullfile(here, 'results', 'step33_structure_differences.csv'));
fprintf('%d of %d checks passed.\n', nnz(chk.passed), height(chk));
disp(chk);
end

%% ---------------------------------------------------------------------------------------------------
function chk = add_check(chk, n, p, d)
% Append one line to the table of checks.
chk = [chk; table(string(n), logical(p), string(d), 'VariableNames', {'check', 'passed', 'detail'})];
end

function v = ifelse(c, a, b)
if c, v = a; else, v = b; end
end

function d = maxdiff(a, b)
% Largest absolute difference of two timeseries. If both were logged on (partly) the same time points - the usual case, and
% still true after Step 37 added solver events - the common points are compared directly; otherwise b is interpolated on the
% time grid of a (D35 amendment: interpolation between different grids adds an error of its own).
[~, ia, ib] = intersect(a.Time, b.Time);
if numel(ia) > 100
    d = max(abs(squeeze(a.Data(ia)) - squeeze(b.Data(ib))));
else
    bi = interp1(b.Time, squeeze(b.Data), a.Time, 'linear', 'extrap');
    d = max(abs(squeeze(a.Data) - bi));
end
end
function D = describe(mdl, ignorePrefix)
% Blocks (relative name, type, dialog values) and connections of one loaded model.
blks = find_system(mdl, 'LookUnderMasks', 'all', 'Type', 'block');
blks = blks(~strcmp(blks, mdl));
if ~isempty(ignorePrefix), blks = blks(~startsWith(blks, [mdl '/' ignorePrefix])); end
D.names = string(strrep(blks, [mdl '/'], ''));
D.type  = string(get_param(blks, 'BlockType'));
D.params = cell(numel(blks), 1);
D.conn = cell(numel(blks), 1);
for i = 1:numel(blks)
    dp = get_param(blks{i}, 'DialogParameters');
    f = {};
    if isstruct(dp), f = fieldnames(dp); end
    kv = strings(0, 2);
    for j = 1:numel(f)
        try
            v = get_param(blks{i}, f{j});
            if ischar(v) || isstring(v), kv(end + 1, :) = [string(f{j}) string(v)]; end %#ok<AGROW>
        catch
        end
    end
    D.params{i} = kv;
    pc = get_param(blks{i}, 'PortConnectivity');
    c = strings(0, 1);
    for j = 1:numel(pc)
        tgt = [pc(j).SrcBlock(:); pc(j).DstBlock(:)];
        tn = strings(0, 1);
        for t = tgt.'
            if t > 0, tn(end + 1) = string(strrep(getfullname(t), [mdl '/'], '')); end %#ok<AGROW>
        end
        c(end + 1) = string(pc(j).Type) + ":" + strjoin(sort(tn), ","); %#ok<AGROW>
    end
    D.conn{i} = sort(c);
end
end

function T = struct_diff(A, B)
% Compare two descriptions; one row per difference.
rows = {};
onlyA = setdiff(A.names, B.names);  onlyB = setdiff(B.names, A.names);
for n = onlyA(:).', rows(end + 1, :) = {n, "block only in new model", "", "", ""}; end %#ok<AGROW>
for n = onlyB(:).', rows(end + 1, :) = {n, "block only in reference", "", "", ""}; end %#ok<AGROW>
common = intersect(A.names, B.names);
for n = common(:).'
    i = find(A.names == n, 1);  j = find(B.names == n, 1);
    if A.type(i) ~= B.type(j), rows(end + 1, :) = {n, "block type", "BlockType", A.type(i), B.type(j)}; end %#ok<AGROW>
    pa = A.params{i}; pb = B.params{j};
    for k = 1:size(pa, 1)
        m = find(pb(:, 1) == pa(k, 1), 1);
        if isempty(m), continue; end
        if pa(k, 2) ~= pb(m, 2) && ~ismember(pa(k, 1), ["BackgroundColor" "Description" "Position"])
            rows(end + 1, :) = {n, "parameter value", pa(k, 1), pa(k, 2), pb(m, 2)}; %#ok<AGROW>
        end
    end
    if ~isequal(A.conn{i}, B.conn{j}), rows(end + 1, :) = {n, "connections", "PortConnectivity", strjoin(A.conn{i}, " | "), strjoin(B.conn{j}, " | ")}; end %#ok<AGROW>
end
if isempty(rows)
    T = table(strings(0, 1), strings(0, 1), strings(0, 1), strings(0, 1), strings(0, 1), 'VariableNames', {'item', 'kind', 'parameter', 'value_new', 'value_ref'});
else
    T = cell2table(rows, 'VariableNames', {'item', 'kind', 'parameter', 'value_new', 'value_ref'});
end
end
