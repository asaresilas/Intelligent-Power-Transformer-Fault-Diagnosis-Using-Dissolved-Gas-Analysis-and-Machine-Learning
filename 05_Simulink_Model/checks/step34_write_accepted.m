function T = step34_write_accepted()
%STEP34_WRITE_ACCEPTED  Table of the Model Advisor results that are not "Passed", with the reason each is accepted.
%
%   T = step34_write_accepted()
%
%   READS   checks/model_advisor_raw.mat  (written by step34_run_model_advisor.m)
%   WRITES  checks/model_advisor_accepted.csv: check id, name, status, number of flagged items (counted from the report text,
%           not typed here) and the reason for accepting it. The reasons are written below by the researcher's assistant after
%           reading each check's text; a check that is not listed here and is not "Passed" stops the function (no silent gaps).
%   The number of flagged items is the count of model paths ("Transformer_Operating_Model/...") in the check's result text;
%   for checks that flag configuration settings or the whole model it is 0.
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 34.   MATLAB R2025b.

here = fileparts(mfilename('fullpath'));
S = load(fullfile(here, 'model_advisor_raw.mat'));
c = S.sysRes.CheckResults;

why = containers.Map();
why('mathworks.design.OptimizationSettings') = "Recommends code-generation optimisations (bitsets for state and Boolean data). The model is used for simulation only; no code is generated from it.";
why('mathworks.design.StowawayDoubles') = "Recommendation for strict single-precision design. The model uses double precision on purpose (temperatures are compared to 0.1 K over 24 h).";
why('mathworks.maab.na_0005') = "The names of the Inport/Outport blocks of subsystems (K_pu, Q_oil, theta_oil_C ...) are hidden on the diagram (Format > Auto Name > Hide Automatic Block Names). Display only; the signals are described in the annotations. Not changed, so that the Step 33 figures stay valid.";
why('mathworks.maab.na_0027') = "MAAB list of allowed blocks for control models. The Simscape and Simscape Electrical blocks are required by the project (physical network) and are not on that list.";
why('mathworks.maab.db_0141') = "Layout rule (signal flow from left to right), flagged for SS1, SS3, SS4, SS6 and the top level. It concerns the arrangement of blocks on the diagram only; no effect on results.";
why('mathworks.maab.hd_0001') = "Rule against sink blocks in discrete hardware-design controllers. The four To Workspace blocks of SS7 log the results of a continuous plant model; they are the model's output.";
why('mathworks.maab.na_0008') = "Style rule asking for a label on some signal lines (those leaving or entering subsystem ports and converter blocks). The blocks are named and annotated; no effect on results.";
why('mathworks.maab.db_0110') = "Tunable parameters used inside expressions (for example log(2)/dT_double_age). This is intended: all values come from params_transformer.m, which is the project rule.";
why('mathworks.maab.db_0140') = "Style rule asking to display block parameters under the blocks. The values are in the block dialogs and are listed in results/step33_block_settings.csv; display only.";
why('mathworks.maab.na_0004') = "Non-standard colours and information overlays. The colour code (blue electrical, green arithmetic, orange thermal) is intentional and explained in the annotations.";
why('mathworks.maab.na_0011') = "All flagged From/Goto blocks are inside blocks of the Simscape library (the EVAL_KEY parts of the converter and Solver Configuration blocks); they were not placed by the model author and cannot be changed.";
why('mathworks.maab.na_0030') = "The Model Advisor check itself stopped with the message 'Dot indexing is not supported for variables of this type' (tool fault, status Incomplete). Replaced by a direct test: the model contains no Bus Creator and no Bus Selector block (test 'no bus signals' in step34_checklist_D1.m), so there is no bus signal name to check.";

n = numel(c);
id = strings(0, 1); nm = strings(0, 1); st = strings(0, 1); cnt = zeros(0, 1); rs = strings(0, 1);
for k = 1:n
    s = string(c(k).Status);
    if s == "Passed", continue; end
    cid = char(c(k).CheckID);
    if ~isKey(why, cid)
        error('step34_write_accepted:unlisted', 'Check %s has status %s and no written reason.', cid, s);
    end
    t = char(strjoin(string(c(k).ResultText), ' '));
    items = regexp(t, 'Transformer_Operating_Model/[^<\s]+', 'match');
    id(end + 1, 1) = string(cid);  nm(end + 1, 1) = string(c(k).CheckName);  st(end + 1, 1) = s; %#ok<AGROW>
    cnt(end + 1, 1) = numel(unique(items));  rs(end + 1, 1) = why(cid); %#ok<AGROW>
end
T = table(id, nm, st, cnt, rs, 'VariableNames', {'check_id', 'check_name', 'status', 'n_flagged_blocks', 'reason_accepted'});
writetable(T, fullfile(here, 'model_advisor_accepted.csv'));
fprintf('%d non-passed checks, all with a written reason.\n', height(T));
disp(T(:, {'check_id', 'status', 'n_flagged_blocks'}));
end
