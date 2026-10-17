function [ok, T] = check_no_typed_limits(varargin)
%CHECK_NO_TYPED_LIMITS  Audit: no decision limit is typed in the conventional-method code (Step 14 check).
%
%   [ok, T] = check_no_typed_limits()
%
%   PURPOSE
%     Rule 1 of Steps_14-17_MATLAB.md: "No numeric limit may appear in the .m code". This function
%     reads every .m file of 04_MATLAB_Conventional (not the tests and not this file), removes
%     comments and text strings, and lists every numeric literal that is left.
%
%   ALLOWED LITERALS (bookkeeping, not limits) - anything else makes the check fail:
%     0, 1, 2, 3, 4, 5   array indices, dimensions, "1:3" loops, column numbers of the five gases,
%                  and the geometry constant sqrt(3)/2 of the equilateral triangle (duval_xy.m).
%     duval_xy.m only: 0.5 (the apex of the equilateral triangle lies half-way along the base).
%     conv_config.m only: 100 (the three Duval percentages add up to 100) and 1e-6 (numerical
%                  probe offset, not a limit). Both are documented in that file.
%   NOT AUDITED: plot_*.m (drawing only: axis ranges, font sizes, colours). They take no part in any
%     decision; the zone lines they draw are computed from the CSV limits by duval_zone_polygons.m.
%
%   OUTPUT  ok  true when no other literal is found
%           T   table: file, line, literal, code (comment- and string-free text of the line)
%   The audit is also written to 11_Results/conventional/no_typed_limits_audit.csv.
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 14.

C = conv_config();
here = fileparts(mfilename('fullpath'));
files = dir(fullfile(here, '*.m'));
isPlot = startsWith({files.name}, 'plot_');
files = files(~ismember({files.name}, {'check_no_typed_limits.m'}) & ~isPlot);
allowed = [0 1 2 3 4 5];
allowedConfig = [100 1e-6];
allowedDuvalXy = 0.5;
rows = {};
for f = 1:numel(files)
    txt = readlines(fullfile(here, files(f).name));
    for i = 1:numel(txt)
        s = strip_code(txt(i));
        lits = regexp(s, '(?<![A-Za-z_0-9.])\d+\.?\d*(?:[eE][+-]?\d+)?', 'match');
        for k = 1:numel(lits)
            v = str2double(lits{k});
            ok_ = ismember(v, allowed) ...
                || (files(f).name == "conv_config.m" && ismember(v, allowedConfig)) ...
                || (files(f).name == "duval_xy.m" && ismember(v, allowedDuvalXy));
            if ~ok_
                rows(end + 1, :) = {string(files(f).name), i, string(lits{k}), strtrim(s)}; %#ok<AGROW>
            end
        end
    end
end
if isempty(rows)
    T = table(strings(0, 1), zeros(0, 1), strings(0, 1), strings(0, 1), 'VariableNames', {'file', 'line', 'literal', 'code'});
else
    T = cell2table(rows, 'VariableNames', {'file', 'line', 'literal', 'code'});
end
ok = isempty(rows);
if ~isfolder(C.outDir), mkdir(C.outDir); end
writetable(T, fullfile(C.outDir, 'no_typed_limits_audit.csv'));
fprintf('Audit of %d files: %d disallowed numeric literal(s). %s\n', numel(files), height(T), ternary(ok, 'PASS', 'FAIL'));
if ~ok, disp(T); end
end

function s = strip_code(line)
% Remove text strings and the trailing comment from one line of MATLAB code.
s = char(line);
s = regexprep(s, '"[^"]*"', '""');               % double-quoted strings
s = regexprep(s, '(?<![\w\)\]\}\.''])''[^'']*''', "''");   % single-quoted strings (not the transpose operator)
k = find(s == '%', 1);                           % comment start
if ~isempty(k), s = s(1:k - 1); end
s = string(s);
end

function out = ternary(c, a, b)
if c, out = a; else, out = b; end
end
