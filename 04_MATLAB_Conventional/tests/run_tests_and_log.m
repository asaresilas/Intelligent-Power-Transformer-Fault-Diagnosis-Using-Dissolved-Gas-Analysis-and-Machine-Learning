function results = run_tests_and_log()
%RUN_TESTS_AND_LOG  Run TestConventionalMethods and TestReducedGas with runtests and save the log (Roadmap Step 15).
%
%   results = run_tests_and_log()
%
%   Writes 04_MATLAB_Conventional/tests/test_log.txt containing: date, MATLAB version, the full command-
%   window output of runtests, and a table with one line per test (name, passed, duration).
%   Exit condition: an error is raised when any test fails, so the log is never mistaken for a pass.
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 15.

here = fileparts(mfilename('fullpath'));
logFile = fullfile(here, 'test_log.txt');
oldDir = pwd;  cleaner = onCleanup(@() cd(oldDir));
cd(here);
% Step 15: TestConventionalMethods (67 tests). Step 26 added TestReducedGas (gases removed, decision D23 proposed).
out = evalc("results = runtests({'TestConventionalMethods', 'TestReducedGas'});");
T = table(results);
fid = fopen(logFile, 'w');
fprintf(fid, 'TestConventionalMethods + TestReducedGas - roadmap Steps 15 and 26\n');
fprintf(fid, 'Run on: %s\n', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')));
fprintf(fid, 'MATLAB: %s\n', version);
fprintf(fid, 'Data version: 1.0 (checked inside the tests)\n');
fprintf(fid, '%s\n', repmat('=', 1, 78));
fprintf(fid, '%s\n', out);
fprintf(fid, '%s\n', repmat('=', 1, 78));
fprintf(fid, '%-85s %-7s %s\n', 'Test', 'Passed', 'Duration [s]');
for i = 1:height(T)
    fprintf(fid, '%-85s %-7s %.3f\n', T.Name{i}, string(T.Passed(i)), T.Duration(i));
end
fprintf(fid, '%s\n', repmat('=', 1, 78));
fprintf(fid, 'SUMMARY: %d tests, %d passed, %d failed, %d incomplete\n', ...
    numel(results), sum([results.Passed]), sum([results.Failed]), sum([results.Incomplete]));
fclose(fid);
fprintf('%d tests: %d passed, %d failed. Log: %s\n', numel(results), sum([results.Passed]), sum([results.Failed]), logFile);
if any([results.Failed] | [results.Incomplete])
    error('run_tests_and_log:failed', 'At least one test failed; see %s', logFile);
end
end

