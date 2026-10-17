classdef DGADashboard_reference < matlab.apps.AppBase
%DGADASHBOARD_REFERENCE Programmatic reference version of the App Designer
%   dashboard described in Part C of the MATLAB Build Guide. Same components,
%   same names and same callback code, so the team can compare their
%   App Designer build with a version that has been run in R2025b.
%   Start with:  app = DGADashboard_reference;

    properties (Access = public)
        UIFigure              matlab.ui.Figure
        Grid                  matlab.ui.container.GridLayout
        ControlPanel          matlab.ui.container.Panel
        RunSimulationButton   matlab.ui.control.Button
        LoadDGAFileButton     matlab.ui.control.Button
        RecordSpinnerLabel    matlab.ui.control.Label
        RecordSpinner         matlab.ui.control.Spinner
        DiagnoseButton        matlab.ui.control.Button
        StatusLabel           matlab.ui.control.Label
        UIAxesTemperature     matlab.ui.control.UIAxes
        UIAxesDuval           matlab.ui.control.UIAxes
        GasTable              matlab.ui.control.Table
        ResultsTable          matlab.ui.control.Table
        AgreementLamp         matlab.ui.control.Lamp
        AgreementLabel        matlab.ui.control.Label
    end

    properties (Access = private)
        SimResult   % struct returned by run_transformer_simulation
        DGAFile     % full path of the measured DGA file
        Gas         % struct with H2, CH4, C2H6, C2H4, C2H2 of the current record
        Info        % table row of the current record (traceability)
    end

    methods (Access = private)

        function startupFcn(app)
            evalin('base', 'params_transformer;');
            app.StatusLabel.Text = 'Ready. Run the simulation or load a DGA file.';
            app.AgreementLamp.Color = [0.6 0.6 0.6];
        end

        function RunSimulationButtonPushed(app, ~)
            app.StatusLabel.Text = 'Simulating transformer operation...'; drawnow;
            app.SimResult = run_transformer_simulation();
            r = app.SimResult;
            plot(app.UIAxesTemperature, r.t_h, r.theta_oil_C, 'b', r.t_h, r.theta_hs_C, 'r', 'LineWidth', 1.3);
            xlabel(app.UIAxesTemperature, 'Time (h)'); ylabel(app.UIAxesTemperature, 'Temperature (\circC)');
            legend(app.UIAxesTemperature, 'Top-oil', 'Hot-spot', 'Location', 'southeast');
            grid(app.UIAxesTemperature, 'on');
            app.StatusLabel.Text = sprintf('Simulation done. Final hot-spot %.1f °C, ageing %.1f h.', ...
                r.theta_hs_C(end), r.loss_of_life_h);
        end

        function LoadDGAFileButtonPushed(app, ~)
            [f, p] = uigetfile({'*.csv;*.xlsx', 'DGA files'}, 'Select measured DGA file');
            if isequal(f, 0), return, end
            app.DGAFile = fullfile(p, f);
            n = height(readtable(app.DGAFile));
            app.RecordSpinner.Limits = [1 n];
            app.RecordSpinner.Value = 1;
            app.StatusLabel.Text = sprintf('Loaded %s (%d records).', f, n);
        end

        function DiagnoseButtonPushed(app, ~)
            if isempty(app.DGAFile)
                app.StatusLabel.Text = 'Load a DGA file first.'; return
            end
            [app.Gas, app.Info] = load_dga_record(app.DGAFile, app.RecordSpinner.Value);
            g = app.Gas;
            d = conventional_diagnosis(g);
            m = ml_diagnose(g);
            app.GasTable.Data = table(["H2"; "CH4"; "C2H6"; "C2H4"; "C2H2"], ...
                [g.H2; g.CH4; g.C2H6; g.C2H4; g.C2H2], 'VariableNames', {'Gas', 'ppm'});
            app.ResultsTable.Data = table(["Rogers Ratio"; "IEC 60599 ratio"; "Duval Triangle 1"; "Machine learning"], ...
                [string(d.rogers); string(d.iec); string(d.duval); m.status + " " + m.fault_class], ...
                'VariableNames', {'Method', 'Diagnosis'});
            root = fileparts(fileparts(which('conventional_diagnosis')));
            plot_duval_triangle(app.UIAxesDuval, d.ratios, fullfile(root, '02_Standards', 'duval_triangle_zones.csv'));
            app.updateAgreement(d, m);
        end

        function updateAgreement(app, d, m)
            conv = [string(d.rogers), string(d.iec), string(d.duval)];
            if m.status ~= "OK" || any(conv == "PENDING_STANDARD")
                app.AgreementLamp.Color = [0.6 0.6 0.6];      % grey: not yet comparable
                app.AgreementLabel.Text = 'Agreement: not available';
            elseif all(conv == m.fault_class)
                app.AgreementLamp.Color = [0 0.7 0];          % green: all agree
                app.AgreementLabel.Text = 'Agreement: all methods agree';
            else
                app.AgreementLamp.Color = [0.9 0.5 0];        % amber: disagreement
                app.AgreementLabel.Text = 'Agreement: methods disagree';
            end
        end
    end

    methods (Access = private)
        function createComponents(app)
            app.UIFigure = uifigure('Visible', 'off', 'Name', 'Transformer DGA Diagnostic Dashboard', ...
                'Position', [100 100 1200 720]);
            app.Grid = uigridlayout(app.UIFigure, [3 3]);
            app.Grid.ColumnWidth = {260, '1x', '1x'};
            app.Grid.RowHeight = {'1x', '1x', 60};

            app.ControlPanel = uipanel(app.Grid, 'Title', 'Controls');
            app.ControlPanel.Layout.Row = [1 3]; app.ControlPanel.Layout.Column = 1;
            cg = uigridlayout(app.ControlPanel, [7 1]);
            cg.RowHeight = {40, 40, 22, 30, 40, '1x', 60};
            app.RunSimulationButton = uibutton(cg, 'Text', 'Run transformer simulation', ...
                'ButtonPushedFcn', createCallbackFcn(app, @RunSimulationButtonPushed, true));
            app.LoadDGAFileButton = uibutton(cg, 'Text', 'Load measured DGA file', ...
                'ButtonPushedFcn', createCallbackFcn(app, @LoadDGAFileButtonPushed, true));
            app.RecordSpinnerLabel = uilabel(cg, 'Text', 'Record number (row)');
            app.RecordSpinner = uispinner(cg, 'Limits', [1 1], 'Value', 1, 'RoundFractionalValues', 'on');
            app.DiagnoseButton = uibutton(cg, 'Text', 'Diagnose selected record', ...
                'ButtonPushedFcn', createCallbackFcn(app, @DiagnoseButtonPushed, true));
            app.GasTable = uitable(cg, 'ColumnName', {'Gas', 'ppm'});
            app.StatusLabel = uilabel(cg, 'Text', '', 'WordWrap', 'on');

            app.UIAxesTemperature = uiaxes(app.Grid);
            app.UIAxesTemperature.Layout.Row = 1; app.UIAxesTemperature.Layout.Column = [2 3];
            title(app.UIAxesTemperature, 'Transformer operating condition (simulated)');
            app.UIAxesDuval = uiaxes(app.Grid);
            app.UIAxesDuval.Layout.Row = 2; app.UIAxesDuval.Layout.Column = 2;
            title(app.UIAxesDuval, 'Duval Triangle 1 (measured sample)');
            app.ResultsTable = uitable(app.Grid, 'ColumnName', {'Method', 'Diagnosis'});
            app.ResultsTable.Layout.Row = 2; app.ResultsTable.Layout.Column = 3;

            ag = uigridlayout(app.Grid, [1 2]); ag.Layout.Row = 3; ag.Layout.Column = [2 3];
            ag.ColumnWidth = {40, '1x'};
            app.AgreementLamp = uilamp(ag);
            app.AgreementLabel = uilabel(ag, 'Text', 'Agreement: not available', 'FontWeight', 'bold');
            app.UIFigure.Visible = 'on';
        end
    end

    methods (Access = public)
        function app = DGADashboard_reference
            createComponents(app);
            registerApp(app, app.UIFigure);
            runStartupFcn(app, @startupFcn);
            if nargout == 0, clear app, end
        end
        function delete(app)
            delete(app.UIFigure);
        end
        % Test hook: diagnose a given file/row without the file dialog
        function testDiagnose(app, file, row)
            app.DGAFile = file;
            app.RecordSpinner.Limits = [1 height(readtable(file))];
            app.RecordSpinner.Value = row;
            DiagnoseButtonPushed(app, []);
        end
        function testRun(app)
            RunSimulationButtonPushed(app, []);
        end
    end
end
