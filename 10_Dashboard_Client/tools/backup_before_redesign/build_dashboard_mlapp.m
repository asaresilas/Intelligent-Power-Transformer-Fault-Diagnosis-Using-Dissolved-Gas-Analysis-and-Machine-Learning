function build_dashboard_mlapp(outFile)
%BUILD_DASHBOARD_MLAPP  Write DGADashboard.mlapp (roadmap Step 39, decision D37, clause 7).
%
%   build_dashboard_mlapp            writes ../DGADashboard.mlapp
%   build_dashboard_mlapp(outFile)   writes another file
%
%   App Designer cannot be driven from code, so the file is written with MathWorks' internal serializer
%   (appdesigner.internal.serialization.MLAPPSerializer, R2025b): the component list below becomes the live
%   figure and the code of createComponents; the hand-written code (callbacks, properties, helper) is read
%   from DGADashboard_code.txt. The result is read back and exported by verify_step39.m.
%   Component names are those of MATLAB_Build_Guide Part C2 (the callbacks use them), plus ControlGrid,
%   RightGrid, ProbabilityTable, ModelLabel and AgreementGrid (D37).
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 39.

here = fileparts(mfilename('fullpath'));
if nargin < 1, outFile = fullfile(fileparts(here), 'DGADashboard.mlapp'); end
appName = 'DGADashboard';
ph = 'ad_CODENAME_ad'; pp = 'ad_PARENTCODENAME_ad';       % placeholders used by App Designer in the stored code

%% 1 components: name, parent, create call, property lines (in the order of createComponents) -----------------------------
C = {};
add = @(name, parent, create, props) {struct('name', name, 'parent', parent, 'create', create, 'props', {props})};
C = [C, add('UIFigure', '', 'uifigure(''Visible'', ''off'')', { ...
    'Position = [8 30 1350 690]', 'Name = ''Transformer DGA Diagnostic Dashboard''', ...
    'CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true)'})];
C = [C, add('GridLayout', 'UIFigure', 'uigridlayout(app.UIFigure)', { ...
    'ColumnWidth = {215, ''1x'', ''1x'', 350}', 'RowHeight = {''0.7x'', ''1.3x'', 150}'})];
C = [C, add('ControlPanel', 'GridLayout', 'uipanel(app.GridLayout)', { ...
    'Title = ''Controls''', 'Layout.Row = [1 3]', 'Layout.Column = 1'})];
C = [C, add('ControlGrid', 'ControlPanel', 'uigridlayout(app.ControlPanel)', { ...
    'ColumnWidth = {''1x''}', 'RowHeight = {40, 40, 22, 30, 40, ''1x'', 34, 88}'})];
C = [C, add('RunSimulationButton', 'ControlGrid', 'uibutton(app.ControlGrid, ''push'')', { ...
    'ButtonPushedFcn = createCallbackFcn(app, @RunSimulationButtonPushed, true)', 'Layout.Row = 1', 'Layout.Column = 1', ...
    'Text = ''Run transformer simulation'''})];
C = [C, add('LoadDGAFileButton', 'ControlGrid', 'uibutton(app.ControlGrid, ''push'')', { ...
    'ButtonPushedFcn = createCallbackFcn(app, @LoadDGAFileButtonPushed, true)', 'Layout.Row = 2', 'Layout.Column = 1', ...
    'Text = ''Load measured DGA file'''})];
C = [C, add('RecordSpinnerLabel', 'ControlGrid', 'uilabel(app.ControlGrid)', { ...
    'Layout.Row = 3', 'Layout.Column = 1', 'Text = ''Record number (row)'''})];
C = [C, add('RecordSpinner', 'ControlGrid', 'uispinner(app.ControlGrid)', { ...
    'Limits = [1 1]', 'RoundFractionalValues = ''on''', 'Layout.Row = 4', 'Layout.Column = 1', 'Value = 1'})];
C = [C, add('DiagnoseButton', 'ControlGrid', 'uibutton(app.ControlGrid, ''push'')', { ...
    'ButtonPushedFcn = createCallbackFcn(app, @DiagnoseButtonPushed, true)', 'Layout.Row = 5', 'Layout.Column = 1', ...
    'Text = ''Diagnose selected record'''})];
C = [C, add('GasTable', 'ControlGrid', 'uitable(app.ControlGrid)', { ...
    'ColumnName = {''Gas''; ''ppm''}', 'RowName = {}', 'Layout.Row = 6', 'Layout.Column = 1'})];
C = [C, add('RestartServiceButton', 'ControlGrid', 'uibutton(app.ControlGrid, ''push'')', { ...
    'ButtonPushedFcn = createCallbackFcn(app, @RestartServiceButtonPushed, true)', 'Layout.Row = 7', 'Layout.Column = 1', ...
    'Text = ''Restart ML service'''})];
C = [C, add('StatusLabel', 'ControlGrid', 'uilabel(app.ControlGrid)', { ...
    'WordWrap = ''on''', 'VerticalAlignment = ''top''', 'Layout.Row = 8', 'Layout.Column = 1', 'Text = '''''})];
C = [C, add('UIAxesTemperature', 'GridLayout', 'uiaxes(app.GridLayout)', { ...
    'title(app.ad_CODENAME_ad, ''Transformer operating condition (simulated, context only)'')', ...
    'xlabel(app.ad_CODENAME_ad, ''Time (h)'')', 'ylabel(app.ad_CODENAME_ad, ''Temperature (\circC)'')', ...
    'Layout.Row = 1', 'Layout.Column = [2 3]'})];
C = [C, add('UIAxesDuval', 'GridLayout', 'uiaxes(app.GridLayout)', { ...
    'title(app.ad_CODENAME_ad, ''Duval Triangle 1 (measured sample)'')', ...
    'Layout.Row = 2', 'Layout.Column = 2'})];
C = [C, add('RightGrid', 'GridLayout', 'uigridlayout(app.GridLayout)', { ...
    'ColumnWidth = {''1x''}', 'RowHeight = {125, ''1x''}', 'Layout.Row = 2', 'Layout.Column = 3'})];
C = [C, add('ResultsTable', 'RightGrid', 'uitable(app.RightGrid)', { ...
    'ColumnName = {''Method''; ''Diagnosis''; ''Agrees with ML''}', 'RowName = {}', 'Layout.Row = 1', 'Layout.Column = 1'})];
C = [C, add('ProbabilityTable', 'RightGrid', 'uitable(app.RightGrid)', { ...
    'ColumnName = {''Class''; ''Probability''}', 'RowName = {}', 'Layout.Row = 2', 'Layout.Column = 1'})];
C = [C, add('EventTable', 'GridLayout', 'uitable(app.GridLayout)', { ...
    'ColumnName = {''#''; ''Time h''; ''Record''; ''ML''; ''Agree''; ''Hot-spot degC''}', 'ColumnWidth = {38, 55, 98, 38, 48, ''auto''}', 'RowName = {}', 'Layout.Row = 3', 'Layout.Column = 2', ...
    'CellSelectionCallback = createCallbackFcn(app, @EventTableCellSelection, true)'})];
C = [C, add('BottomGrid', 'GridLayout', 'uigridlayout(app.GridLayout)', { ...
    'ColumnWidth = {''1x''}', 'RowHeight = {''1x'', 62}', 'Layout.Row = 3', 'Layout.Column = 3'})];
C = [C, add('ModelLabel', 'BottomGrid', 'uilabel(app.BottomGrid)', { ...
    'WordWrap = ''on''', 'VerticalAlignment = ''top''', 'Layout.Row = 1', 'Layout.Column = 1', 'Text = ''ML: not called yet'''})];
C = [C, add('AgreementGrid', 'BottomGrid', 'uigridlayout(app.BottomGrid)', { ...
    'ColumnWidth = {40, ''1x''}', 'RowHeight = {''1x''}', 'Layout.Row = 2', 'Layout.Column = 1'})];
C = [C, add('AgreementLamp', 'AgreementGrid', 'uilamp(app.AgreementGrid)', { ...
    'Layout.Row = 1', 'Layout.Column = 1', 'Color = [0.6 0.6 0.6]'})];
C = [C, add('AgreementLabel', 'AgreementGrid', 'uilabel(app.AgreementGrid)', { ...
    'FontWeight = ''bold''', 'WordWrap = ''on''', 'Layout.Row = 1', 'Layout.Column = 2', 'Text = ''Agreement: not available'''})];
C = [C, add('ExplainPanel', 'GridLayout', 'uipanel(app.GridLayout)', { ...
    'Title = ''How to read this result''', 'Layout.Row = [1 3]', 'Layout.Column = 4'})];
C = [C, add('ExplainGrid', 'ExplainPanel', 'uigridlayout(app.ExplainPanel)', { ...
    'ColumnWidth = {''1x''}', 'RowHeight = {''1x''}', 'Padding = [4 4 4 4]'})];
C = [C, add('ExplainArea', 'ExplainGrid', 'uitextarea(app.ExplainGrid)', { ...
    'Editable = ''off''', 'FontSize = 12', 'Layout.Row = 1', 'Layout.Column = 1'})];
C = [C{:}];
names = {C.name};
% the code lines of every component, with the placeholders of App Designer
for k = 1:numel(C)
    lines = {};
    if isempty(C(k).parent)
        lines{end + 1} = ['app.' ph ' = ' C(k).create ';']; %#ok<AGROW>
    else
        lines{end + 1} = ['app.' ph ' = ' strrep(C(k).create, ['app.' C(k).parent], ['app.' pp]) ';']; %#ok<AGROW>
    end
    for q = 1:numel(C(k).props)
        p = C(k).props{q};
        if startsWith(p, {'title(', 'xlabel(', 'ylabel('})
            lines{end + 1} = [p ';']; %#ok<AGROW>
        else
            lines{end + 1} = ['app.' ph '.' p ';']; %#ok<AGROW>
        end
    end
    C(k).code = lines(:);
end

%% 2 live figure (what App Designer holds at design time) -------------------------------------------------------------
app = struct();
for k = 1:numel(C)
    for q = 1:numel(C(k).code)
        ln = strrep(strrep(C(k).code{q}, ph, C(k).name), pp, C(k).parent);
        tok = regexp(ln, '^(app\.\w+\.\w+) = createCallbackFcn\(app, @(\w+), true\);$', 'tokens', 'once');
        if ~isempty(tok)
            ln = [tok{1} ' = ''' tok{2} ''';'];            % design time: the callback is stored by name
        end
        eval(ln);
    end
    dt = struct('CodeName', C(k).name, 'GroupId', '', 'ComponentCode', {C(k).code}, 'ImageRelativePath', '', 'DirtyProps', struct());
    addprop(app.(C(k).name), 'DesignTimeProperties');   % as in App Designer (DesignTimeController): saved with the app
    app.(C(k).name).DesignTimeProperties = dt;
end
fig = app.UIFigure;
cleanupFig = onCleanup(@() delete(fig));

%% 3 hand-written code sections ----------------------------------------------------------------------------------------
txt = fileread(fullfile(here, 'DGADashboard_code.txt'), 'Encoding', 'UTF-8');
parts = regexp(txt, '(?m)^%%@ ', 'split'); parts(1) = [];
S = struct('PUBLIC_PROPERTIES', {{}}, 'PRIVATE_PROPERTIES', {{}}, 'PRIVATE_METHODS', {{}}, 'STARTUP', {{}});
cb = struct('Name', {}, 'Code', {}, 'Comment', {}, 'Component', {});
for k = 1:numel(parts)
    nl = find(parts{k} == newline, 1);
    head = strtrim(parts{k}(1:nl - 1));  body = regexprep(parts{k}(nl + 1:end), '\s+$', '');
    lines = strsplit(body, newline, 'CollapseDelimiters', false);
    lines = cellfun(@(s) regexprep(s, '\r$', ''), lines, 'UniformOutput', false);
    if startsWith(head, 'CALLBACK ')
        w = strsplit(head, ' ');  nm = w{2};  cmt = strjoin(w(3:end), ' ');
        comp = regexp(cmt, '\w+$', 'match', 'once');
        cb(end + 1) = struct('Name', nm, 'Code', {lines}, 'Comment', cmt, 'Component', comp); %#ok<AGROW>
    else
        S.(head) = lines;
    end
end
ind = @(lines, n) cellfun(@(s) [repmat(' ', 1, n * ~isempty(s)) s], lines, 'UniformOutput', false);

%% 4 the code text of the app (the layout App Designer writes) ---------------------------------------------------------
cls = {};  w = @(varargin) [cls, varargin];
cls{end + 1} = ['classdef ' appName ' < matlab.apps.AppBase'];
cls{end + 1} = '';
cls{end + 1} = '  % Properties that correspond to app components';
cls{end + 1} = '  properties (Access = public)';
for k = numel(C):-1:1
    cls{end + 1} = sprintf('    %-24s %s', C(k).name, class(app.(C(k).name))); %#ok<AGROW>
end
cls{end + 1} = '  end';
cls{end + 1} = '';
editable = [S.PUBLIC_PROPERTIES(:); {''}; S.PRIVATE_PROPERTIES(:); {''}; S.PRIVATE_METHODS(:)];
cls = [cls, editable(:)'];
cls{end + 1} = '';
cls{end + 1} = '  % Callbacks that handle component events';
cls{end + 1} = '  methods (Access = private)';
cls{end + 1} = '';
cls{end + 1} = '    % Code that executes after component creation';
cls{end + 1} = '    function startupFcn(app)';
cls = [cls, ind(S.STARTUP, 6)];
cls{end + 1} = '    end';
for k = 1:numel(cb)
    cls{end + 1} = '';
    cls{end + 1} = ['    % ' cb(k).Comment];
    cls{end + 1} = ['    function ' cb(k).Name '(app, event)'];
    cls = [cls, ind(cb(k).Code, 6)]; %#ok<AGROW>
    cls{end + 1} = '    end';
end
cls{end + 1} = '  end';
cls{end + 1} = '';
cls{end + 1} = '  % Component initialization';
cls{end + 1} = '  methods (Access = private)';
cls{end + 1} = '';
cls{end + 1} = '    % Create UIFigure and components';
cls{end + 1} = '    function createComponents(app)';
for k = 1:numel(C)
    cls{end + 1} = '';
    if k == 1
        cls{end + 1} = '      % Create UIFigure and hide until all components are created';
    else
        cls{end + 1} = ['      % Create ' C(k).name];
    end
    cls = [cls, ind(cellfun(@(s) strrep(strrep(s, ph, C(k).name), pp, C(k).parent), C(k).code, 'UniformOutput', false), 6)']; %#ok<AGROW>
end
cls{end + 1} = '';
cls{end + 1} = '      % Show the figure after all components are created';
cls{end + 1} = '      app.UIFigure.Visible = ''on'';';
cls{end + 1} = '    end';
cls{end + 1} = '  end';
cls{end + 1} = '';
cls{end + 1} = '  % App creation and deletion';
cls{end + 1} = '  methods (Access = public)';
cls{end + 1} = '';
cls{end + 1} = '    % Construct app';
cls{end + 1} = ['    function app = ' appName];
cls{end + 1} = '';
cls{end + 1} = '      % Create UIFigure and components';
cls{end + 1} = '      createComponents(app)';
cls{end + 1} = '';
cls{end + 1} = '      % Register the app with App Designer';
cls{end + 1} = '      registerApp(app, app.UIFigure)';
cls{end + 1} = '';
cls{end + 1} = '      % Execute the startup function';
cls{end + 1} = '      runStartupFcn(app, @startupFcn)';
cls{end + 1} = '';
cls{end + 1} = '      if nargout == 0';
cls{end + 1} = '        clear app';
cls{end + 1} = '      end';
cls{end + 1} = '    end';
cls{end + 1} = '';
cls{end + 1} = '    % Code that executes before app deletion';
cls{end + 1} = '    function delete(app)';
cls{end + 1} = '';
cls{end + 1} = '      % Delete UIFigure when app is deleted';
cls{end + 1} = '      delete(app.UIFigure)';
cls{end + 1} = '    end';
cls{end + 1} = '  end';
cls{end + 1} = 'end';
codeText = strjoin(cls, newline);

%% 5 serialize ---------------------------------------------------------------------------------------------------------
if isfile(outFile), delete(outFile); end
ser = appdesigner.internal.serialization.MLAPPSerializer(outFile, fig);
ser.OverwriteTargetFile = true;
ser.MatlabCodeText = codeText;
ser.ClassName = appName;
ser.EditableSectionCode = editable(:);
cbs = struct('Name', {}, 'Code', {});
for k = 1:numel(cb), cbs(k) = struct('Name', cb(k).Name, 'Code', {cb(k).Code}); end
ser.Callbacks = cbs;
ser.StartupCallback = struct('Name', 'startupFcn', 'Code', {S.STARTUP});
ser.InputParameters = '';
ser.SingletonMode = 'Multiple';
ser.AppTypeData = struct();
md = appdesigner.internal.model.MetadataModel;
md.Description = 'Transformer DGA diagnostic dashboard: conventional diagnoses in MATLAB, ML diagnosis from the FastAPI service (roadmap Step 39, D37).';
ser.Metadata = md;
ser.save();
fprintf('Wrote %s (%d components)\n', outFile, numel(C));
end
