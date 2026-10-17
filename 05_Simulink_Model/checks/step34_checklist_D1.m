function [chk, paramLines, blockNumbers] = step34_checklist_D1()
%STEP34_CHECKLIST_D1  Part D1 checklist of the MATLAB Build Guide, applied to Transformer_Operating_Model.slx.
%
%   [chk, paramLines, blockNumbers] = step34_checklist_D1()
%
%   The guide's seven checklist items and what this function does with each:
%     D1.1  params_transformer.m runs; every variable has a unit and a source code.
%           -> runs the file in an empty workspace and reads every assignment line: needs a unit "[...]" and a source or
%              basis tag in its comment (source codes E1, T1, T2, A1-A4 of the guide, or an explicit basis word).
%     D1.2  No block dialog contains a parameter number.
%           -> reads EVERY dialog parameter of EVERY block of the saved model (not only the ones the builder logged) and lists
%              each value that still holds a digit after variable names and the allowed equation constants are removed.
%     D1.3  Every subsystem and the top level has its annotation.
%     D1.4  Update Diagram gives no errors; a 24 h run reproduces the values of Section B12 within 0.1 K.
%     D1.5  run_transformer_simulation returns non-empty results.
%     D1.6  The app runs ... -> NOT PART OF THIS MODEL (dashboard is a later roadmap step); recorded as "not applicable now".
%     D1.7  A second team member has checked the build -> cannot be done by a program; recorded as OPEN (needs a person).
%
%   OUTPUT  chk (table), written to checks/step34_checklist_D1.csv; paramLines (one row per assignment line of the parameter
%           file) -> checks/step34_param_lines.csv; blockNumbers (flagged dialog values) -> checks/step34_block_numbers.csv.
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 34.   MATLAB R2025b.

here  = fileparts(mfilename('fullpath'));          % .../05_Simulink_Model/checks
root  = fileparts(here);                           % .../05_Simulink_Model
mdl   = 'Transformer_Operating_Model';
tolK  = 0.1;                                       % K, guide D1.4 and approved tolerance
% Values of Build Guide Section B12 (verification run, 20 degC ambient, rated demand) - copied from the guide table.
B12 = struct('K', 0.9839, 'oil', 78.638, 'hs', 100.276, 'rise63_min', 75.0);
chk = table('Size', [0 4], 'VariableTypes', {'string', 'string', 'logical', 'string'}, ...
    'VariableNames', {'item', 'what', 'passed', 'detail'});
w = warning('off', 'all');  restoreWarn = onCleanup(@() warning(w));

%% D1.1 parameter file: runs, unit and source on every variable ------------------------------------------------------
pfile = fullfile(root, 'params_transformer.m');
ok = true; msg = 'runs without error';
try
    evalc('run(pfile);');                          %#ok<EVLC>  the file is a script: it runs in this function's own workspace, which holds no earlier parameter
catch ME
    ok = false; msg = ME.message;
end
txt = splitlines(string(fileread(pfile)));
rows = {};
for i = 1:numel(txt)
    L = strtrim(txt(i));
    if startsWith(L, "%") || L == "", continue; end
    % one or two assignments per line (the file has "Rw1_pu = ..;  Rw2_pu = .." lines)
    names = regexp(char(L), '(?:^|;)\s*([A-Za-z_]\w*)\s*=', 'tokens');
    if isempty(names), continue; end
    names = string([names{:}]);
    cmt = "";
    k = strfind(char(L), '%');
    if ~isempty(k), cmt = string(L{1}(k(1):end)); end
    % a variable also inherits the comment of the line(s) directly above that continue it (not used in this file)
    hasUnit = ~isempty(regexp(char(cmt), '\[[^\]]+\]', 'once'));
    % (MATLAB regular expressions use \< and \> or look-arounds for word limits; \b is the backspace character)
    hasSrc  = ~isempty(regexp(char(cmt), '(?<![A-Za-z0-9_])(E1|T1|T2|A[1-4])(?![A-Za-z0-9_])|by definition|physical constant|IEC|scaling|relation|assumption|R\*C|derived|standard|guide|block default', 'once'));
    for n = names
        rows(end + 1, :) = {i, n, hasUnit, hasSrc, strtrim(extractAfter(string(L), "%") + "")}; %#ok<AGROW>
    end
end
paramLines = cell2table(rows, 'VariableNames', {'line', 'variable', 'has_unit', 'has_source_or_basis', 'comment'});
% A comment that sits only on the section heading counts as the source of every line below it: Sections 1 and 3 name E1 / T1,
% Sections 2 and 4 name "guide Section A3" (derived values), Section 5 states "run settings chosen".
secSrc = strings(numel(txt), 1);  cur = "";
for i = 1:numel(txt)
    L = strtrim(txt(i));
    if startsWith(L, "%%"), cur = L; end
    secSrc(i) = cur;
end
for r = 1:height(paramLines)
    s = secSrc(paramLines.line(r));
    if ~paramLines.has_source_or_basis(r) && ~isempty(regexp(char(s), '(?<![A-Za-z0-9_])(E1|T1|T2)(?![A-Za-z0-9_])|guide Section|run settings chosen', 'once'))
        paramLines.has_source_or_basis(r) = true;
    end
end
missU = paramLines.variable(~paramLines.has_unit);
missS = paramLines.variable(~paramLines.has_source_or_basis);
chk = add(chk, 'D1.1', 'params_transformer.m runs', ok, msg);
chk = add(chk, 'D1.1', 'every variable has a unit [..] in its comment', isempty(missU), ...
    sprintf('%d variables; without unit: %s', height(paramLines), joinOrNone(missU)));
chk = add(chk, 'D1.1', 'every variable has a source or basis in its comment or section heading', isempty(missS), ...
    sprintf('without source/basis: %s', joinOrNone(missS)));

%% D1.2 numbers in block dialogs (every dialog parameter of every block) --------------------------------------------
bdclose all;
addpath(root);
evalin('base', 'params_transformer;');
load_system(fullfile(root, [mdl '.slx']));
blks = find_system(mdl, 'LookUnderMasks', 'all', 'Type', 'block');
blks = blks(~strcmp(blks, mdl));
rows = {};
% Mathematical constants of the equations that may stay in a setting (as in verify_step33, check 5) plus empty / on-off codes.
for b = 1:numel(blks)
    dp = get_param(blks{b}, 'DialogParameters');
    if ~isstruct(dp), continue; end
    f = fieldnames(dp);
    for j = 1:numel(f)
        try, v = get_param(blks{b}, f{j}); catch, continue; end
        if ~(ischar(v) || isstring(v)), continue; end
        v = string(v);
        if v == "" || ismember(lower(v), ["on" "off"]), continue; end
        s = strrep(v, "log(2)", "");  s = strrep(s, "1/3", "");  s = strrep(s, "(k21-1)", "");
        s = regexprep(s, '[A-Za-z_][A-Za-z_0-9]*', '');
        s = regexprep(s, '^1/', '');
        if ~isempty(regexp(char(s), '\d', 'once'))
            % Why is this value not a model parameter? Classify it (rules written down here, applied by program):
            %   interface code   port numbers, inherited sample time (-1), latency, unit selectors (*_unit), normalisation
            %                    values (*_nominal_value) and logging options: they select behaviour, they carry no physical value
            %   hidden field     the mask hides the field in the block dialog (inactive option, library default)
            %   library tuning   numerical tuning defaults of the Solver Configuration and of the Simulink-PS / PS-Simulink
            %                    converters (tolerances, filter order and time constant) - defaults of the MathWorks library
            %   option selector  0 = "None" of an on/off option (e.g. no source impedance, no harmonics)
            %   PARAMETER NUMBER anything else: a typed number that should be a variable of params_transformer.m
            nm = f{j};
            cat = "PARAMETER NUMBER";
            if any(strcmp(nm, {'Port', 'PortDimensions', 'SampleTime', 'SystemSampleTime', 'Latency', 'MessageQueueCapacity', ...
                    'OutputWhenUnconnectedValue', 'Iterations', 'Decimation', 'Save2DSignal', 'CollapseDim', 'Inputs'})) ...
                    || endsWith(nm, '_unit') || endsWith(nm, '_nominal_value')
                cat = "interface code";
            elseif any(strcmp(nm, {'impedance_option', 'harmonic_option'})) && (v == "0")
                cat = "option selector";
            elseif any(strcmp(nm, {'ResidualTolerance', 'ConsistencyAbsTol', 'ConsistencyRelTol', 'ConsistencyTolFactor', ...
                    'FunctionEvalNumThread', 'LocalSolverSampleTime', 'MaxNonlinIter', 'MaxModeIter', 'ImpulseIterations', ...
                    'LinearAlgebraNumThread', 'DelaysMemoryBudget', 'FilteringTimeConstant', 'PartitionMemoryBudget', ...
                    'MultibodyLocalSolverSampleTime', 'SimscapeFilterOrder', 'InputFilterTimeConstant', 'UdotUserProvided'}))
                cat = "library tuning";
            else
                try
                    mn = get_param(blks{b}, 'MaskNames');  mv = get_param(blks{b}, 'MaskVisibilities');
                    q = find(strcmp(mn, nm), 1);
                    if ~isempty(q) && strcmp(mv{q}, 'off'), cat = "hidden field"; end
                catch
                end
            end
            rows(end + 1, :) = {string(strrep(blks{b}, [mdl '/'], '')), string(nm), v, cat}; %#ok<AGROW>
        end
    end
end
if isempty(rows)
    blockNumbers = table(strings(0, 1), strings(0, 1), strings(0, 1), strings(0, 1), 'VariableNames', {'block', 'parameter', 'value', 'category'});
else
    blockNumbers = cell2table(rows, 'VariableNames', {'block', 'parameter', 'value', 'category'});
end
nReal = nnz(blockNumbers.category == "PARAMETER NUMBER");
cats = ["interface code" "hidden field" "library tuning" "option selector" "PARAMETER NUMBER"];
cnt = arrayfun(@(c) nnz(blockNumbers.category == c), cats);
chk = add(chk, 'D1.2', 'no block dialog holds a typed parameter number (all dialog fields of all blocks read)', nReal == 0, ...
    sprintf('%d blocks; values containing a digit: %d = %s; typed parameter numbers: %d (every value is listed with its category in step34_block_numbers.csv)', ...
    numel(blks), height(blockNumbers), strjoin(cats + " " + string(cnt), ', '), nReal));

%% D1.3 annotations ---------------------------------------------------------------------------------------------------
subs = find_system(mdl, 'SearchDepth', 1, 'BlockType', 'SubSystem');
okNote = numel(find_system(mdl, 'FindAll', 'on', 'SearchDepth', 1, 'Type', 'annotation')) >= 1;
for k = 1:numel(subs)
    okNote = okNote && numel(find_system(subs{k}, 'FindAll', 'on', 'SearchDepth', 1, 'Type', 'annotation')) >= 1;
end
chk = add(chk, 'D1.3', 'top level and every subsystem has an annotation', okNote, sprintf('%d subsystems checked', numel(subs)));
% Extra (not in the guide): the Model Advisor check on bus signal names (mathworks.maab.na_0030) stopped with a tool fault,
% so the model is tested directly for bus blocks; without bus blocks there is no bus signal name to check.
nBus = numel(find_system(mdl, 'LookUnderMasks', 'all', 'BlockType', 'BusCreator')) + ...
       numel(find_system(mdl, 'LookUnderMasks', 'all', 'BlockType', 'BusSelector'));
chk = add(chk, 'extra', 'no bus signals (substitute for the incomplete Model Advisor check na_0030)', nBus == 0, sprintf('%d Bus Creator / Bus Selector blocks', nBus));

%% D1.4 update diagram + 24 h run against Section B12 -------------------------------------------------------------------
ok = true; msg = 'update ok';
lastwarn('');
try
    set_param(mdl, 'SimulationCommand', 'update');
catch ME
    ok = false; msg = ME.message;
end
[lw, ~] = lastwarn;
chk = add(chk, 'D1.4', 'Update Diagram gives no error', ok, msg);
chk = add(chk, 'D1.4', 'Update Diagram gives no warning', isempty(lw), ifelse(isempty(lw), 'none', lw));
out = sim(mdl);
K = out.K_pu.Data(end);  oil = out.theta_oil_C.Data(end);  hs = out.theta_hs_C.Data(end);
chk = add(chk, 'D1.4', '24 h run: load factor K equals B12 (0.9839, 4 decimals)', abs(K - B12.K) < 5e-5, sprintf('K = %.4f', K));
chk = add(chk, 'D1.4', '24 h run: top-oil temperature equals B12 within 0.1 K', abs(oil - B12.oil) <= tolK, ...
    sprintf('%.3f degC vs %.3f degC (diff %.4f K)', oil, B12.oil, abs(oil - B12.oil)));
chk = add(chk, 'D1.4', '24 h run: hot-spot temperature equals B12 within 0.1 K', abs(hs - B12.hs) <= tolK, ...
    sprintf('%.3f degC vs %.3f degC (diff %.4f K)', hs, B12.hs, abs(hs - B12.hs)));
close_system(mdl, 0);

%% D1.5 run_transformer_simulation ---------------------------------------------------------------------------------------
ok = true; msg = '';
try
    res = run_transformer_simulation();
    fn = {'t_h', 'K_pu', 'theta_oil_C', 'theta_hs_C', 'ageing_V', 'loss_of_life_h'};
    ne = cellfun(@(n) isfield(res, n) && ~isempty(res.(n)), fn);
    ok = all(ne);  msg = sprintf('fields non-empty: %d of %d; %d time points', nnz(ne), numel(fn), numel(res.t_h));
catch ME
    ok = false; msg = ME.message;
end
chk = add(chk, 'D1.5', 'run_transformer_simulation returns non-empty results', ok, msg);

%% D1.6 / D1.7 not machine-checkable here ----------------------------------------------------------------------------------
chk = add(chk, 'D1.6', 'the app runs (dashboard)', true, 'NOT APPLICABLE TO STEP 34: dashboard is built in a later roadmap stage (H); recorded, not tested');
chk = add(chk, 'D1.7', 'a second team member checked the build against the reference script', false, ...
    'OPEN: needs a person. Automatic substitute: verify_step33 check 3 compares the model with the reference build (blocks, values, connections)');

writetable(chk, fullfile(here, 'step34_checklist_D1.csv'));
writetable(paramLines, fullfile(here, 'step34_param_lines.csv'));
writetable(blockNumbers, fullfile(here, 'step34_block_numbers.csv'));
disp(chk(:, {'item', 'passed', 'what'}));
end

function chk = add(chk, i, w, p, d)
chk = [chk; table(string(i), string(w), logical(p), string(d), 'VariableNames', {'item', 'what', 'passed', 'detail'})];
end

function v = ifelse(c, a, b)
if c, v = a; else, v = b; end
end

function s = joinOrNone(x)
if isempty(x), s = 'none'; else, s = char(strjoin(x, ', ')); end
end
