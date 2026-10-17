% step34_run_model_advisor.m  -  Roadmap Step 34 (Run the model checks), part 1: Model Advisor
%
% PURPOSE   Run Simulink Model Advisor (Simulink Check) on Transformer_Operating_Model.slx and
%           save the report and a one-line-per-check result table.
% INPUT     05_Simulink_Model/Transformer_Operating_Model.slx, params_transformer.m
% OUTPUT    checks/model_advisor_report.html  (the Model Advisor report, ReportFormat html)
%           checks/model_advisor_results.csv  (check id, title, status, number of flagged items)
% CHECK SET All checks of the groups mathworks.design, mathworks.simscape, mathworks.simulink,
%           mathworks.sl, mathworks.maab (modelling and Simscape checks; the code-generation,
%           AUTOSAR, DO-178, MISRA and PLC groups are left out because this model is not meant
%           for code generation). Checks that do not apply to the model (e.g. Stateflow) are
%           reported by the Model Advisor as passed / not run and are kept in the table.
% USAGE     cd 05_Simulink_Model/checks ; step34_run_model_advisor
%
% Written 13 Oct 2026 for MATLAB R2025b.  No value in this file is a model parameter.

thisDir  = fileparts(mfilename('fullpath'));          % .../05_Simulink_Model/checks
modelDir = fileparts(thisDir);                        % .../05_Simulink_Model
modelName = 'Transformer_Operating_Model';
addpath(modelDir);

warning('off', 'all');                                % the Model Advisor cache prints many warnings
params_transformer;                                   % workspace variables used by the model
load_system(fullfile(modelDir, [modelName '.slx']));

ma  = Simulink.ModelAdvisor.getModelAdvisor(modelName);
ids = ma.getCheckAll;  ids = ids(:);
grp = regexp(ids, '^[a-zA-Z]+\.[a-zA-Z]+', 'match', 'once');
sel = ismember(grp, {'mathworks.design','mathworks.simscape','mathworks.simulink', ...
                     'mathworks.sl','mathworks.maab'});
checkIDs = ids(sel)';

% fixed report name so the file can be found again; Force 'On' overwrites an older report
res = ModelAdvisor.run({modelName}, checkIDs, 'Force', 'On', 'DisplayResults', 'None', ...
        'ReportFormat', 'html', 'ReportPath', thisDir, 'ReportName', 'model_advisor_report');

sysRes = res{1};
save(fullfile(thisDir, 'model_advisor_raw.mat'), 'sysRes', 'checkIDs');

% one row per check: id, name, status, first 300 characters of the result text without HTML tags
c = sysRes.CheckResults;  n = numel(c);
id = strings(n, 1);  nm = strings(n, 1);  st = strings(n, 1);  txt = strings(n, 1);
for k = 1:n
    id(k) = c(k).CheckID;  nm(k) = c(k).CheckName;  st(k) = string(c(k).Status);
    t = regexprep(char(strjoin(string(c(k).ResultText), ' ')), '<[^>]+>', ' ');
    t = strtrim(regexprep(t, '\s+', ' '));
    txt(k) = string(t(1:min(end, 300)));
end
T = table(id, nm, st, txt, 'VariableNames', {'check_id', 'check_name', 'status', 'result_text_start'});
writetable(T, fullfile(thisDir, 'model_advisor_results.csv'));
s = sysRes.Summary;
fprintf('Checks run: %d | Passed %d | Warning %d | Failed %d | Incomplete %d | Not run %d | Justified %d\n', ...
    n, s.Passed, s.Warning, s.Failed, s.Incomplete, s.NotRun, s.Justified);
r = dir(fullfile(thisDir, '**', '*.html'));
for k = 1:numel(r), fprintf('report file: %s\n', fullfile(r(k).folder, r(k).name)); end
