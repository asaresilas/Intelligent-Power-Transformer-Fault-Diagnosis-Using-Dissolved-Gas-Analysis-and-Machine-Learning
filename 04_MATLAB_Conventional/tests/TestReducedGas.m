classdef TestReducedGas < matlab.unittest.TestCase
%TESTREDUCEDGAS  Unit tests of the conventional methods with gases removed (Roadmap Step 26, decision D23 proposed).
%
%   Run:  results = runtests('TestReducedGas');     or   run_tests_and_log   (runs this class and TestConventionalMethods)
%
%   WHAT IS TESTED
%     (a) RULE 2 (the test the roadmap asks for): if ONE gas is removed - any of the five - the IEC 60599 and Rogers
%         ratio methods return ND for every record, also for records for which they give a class when all five gases
%         are present and also when the removed gas is not used by the class that would have matched (C2H6).
%     (b) Duval Triangle 1 needs only CH4, C2H4, C2H2: removing H2 and/or C2H6 changes nothing; removing any of
%         its three gases gives ND for every record.
%     (c) The values of removed gases are ignored (huge value, zero and NaN give identical output): the result
%         cannot depend on data that is "not measured".
%     (d) Five gases present: output identical to conventional_diagnosis (Steps 14-17), raw and final.
%     (e) Normality gate on incomplete data: never passed (no "Normal" from missing data); the sensitivity gate on
%         the measured gases is never stricter than the primary gate.
%     (f) Input checks and bookkeeping: unknown gas name raises an error; required gases come from conv_config;
%         the batch (run_reduced_gas_applicability) passes its ten checks and gives 31 x 3 x 5 rows;
%         the audit "no typed limits" still passes with the new files.
%
%   The records used are the 827 records of the frozen master table (data version 1.0); nothing is typed.
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 26.

    properties (TestParameter)
        removedGas = {"H2", "CH4", "C2H6", "C2H4", "C2H2"};        % conv_config().gas, one at a time
        duvalGasRemoved = {"CH4", "C2H4", "C2H2"};
    end

    properties
        C      % configuration
        g      % all 827 records as the gas struct used by conventional_diagnosis
        five   % conventional_diagnosis of the five-gas data (reference)
    end

    methods (TestClassSetup)
        function setup(testCase)
            here = fileparts(mfilename('fullpath'));
            addpath(fileparts(here));
            testCase.addTeardown(@() rmpath(fileparts(here)));
            testCase.C = conv_config();
            verify_data_version('Quiet', true);
            M = readtable(testCase.C.masterFile, 'TextType', 'string');
            testCase.g = struct('H2', M.H2, 'CH4', M.CH4, 'C2H6', M.C2H6, 'C2H4', M.C2H4, 'C2H2', M.C2H2, ...
                'equipment_type', M.equipment_type);
            testCase.five = conventional_diagnosis(testCase.g);
        end
    end

    methods (Test)
        % ---- (a) rule 2: one removed gas -> ND for IEC and Rogers -------------------------------------
        function oneRemovedGasGivesNdForRatioMethods(testCase, removedGas)
            present = setdiff(testCase.C.gas, removedGas, 'stable');
            d = reduced_gas_diagnosis(testCase.g, present);
            testCase.verifyFalse(d.applicable.iec);
            testCase.verifyFalse(d.applicable.rogers);
            testCase.verifyTrue(all(d.iec == "ND") && all(d.raw.iec == "ND"), 'IEC must be ND for every record');
            testCase.verifyTrue(all(d.rogers == "ND") && all(d.raw.rogers == "ND"), 'Rogers must be ND for every record');
        end

        function theTestIsNotVacuous(testCase)
            % With all five gases present the same records DO get a class: ND for every record is caused by the rule.
            testCase.verifyGreaterThan(nnz(testCase.five.raw.iec ~= "ND"), 0);
            testCase.verifyGreaterThan(nnz(testCase.five.raw.rogers ~= "ND"), 0);
        end

        % ---- (b) Duval ------------------------------------------------------------------------------
        function duvalIgnoresH2AndC2H6(testCase)
            d = reduced_gas_diagnosis(testCase.g, testCase.C.duvalGas);
            testCase.verifyTrue(d.applicable.duval);
            testCase.verifyEqual(d.raw.duval, testCase.five.raw.duval);
        end

        function duvalWithOneOfItsGasesRemovedGivesNd(testCase, duvalGasRemoved)
            present = setdiff(testCase.C.gas, duvalGasRemoved, 'stable');
            d = reduced_gas_diagnosis(testCase.g, present);
            testCase.verifyFalse(d.applicable.duval);
            testCase.verifyTrue(all(d.duval == "ND") && all(d.raw.duval == "ND"));
        end

        % ---- (c) removed values are ignored -------------------------------------------------------------
        function removedGasValuesAreIgnored(testCase)
            present = ["CH4" "C2H4" "C2H2"];
            n = numel(testCase.g.H2);
            a = testCase.g;  a.H2 = zeros(n, 1);          a.C2H6 = zeros(n, 1);
            b = testCase.g;  b.H2 = 1e9 * ones(n, 1);     b.C2H6 = 1e9 * ones(n, 1);
            c = testCase.g;  c.H2 = NaN(n, 1);            c.C2H6 = NaN(n, 1);
            da = reduced_gas_diagnosis(a, present);  db = reduced_gas_diagnosis(b, present);  dc = reduced_gas_diagnosis(c, present);
            testCase.verifyEqual(da.duval, db.duval);
            testCase.verifyEqual(da.duval, dc.duval);
            testCase.verifyEqual(da.gate_on_measured, db.gate_on_measured);
        end

        % ---- (d) five gases present = Steps 14-17 -----------------------------------------------------------
        function fiveGasesReproduceConventionalDiagnosis(testCase)
            d = reduced_gas_diagnosis(testCase.g, testCase.C.gas);
            for m = ["iec" "rogers" "duval"]
                testCase.verifyEqual(d.(m), testCase.five.(m), char(m + " final"));
                testCase.verifyEqual(d.raw.(m), testCase.five.raw.(m), char(m + " raw"));
            end
            testCase.verifyEqual(d.gate_upper, testCase.five.gate_upper);
        end

        % ---- (e) gate -------------------------------------------------------------------------------
        function gateNeverPassedWithMissingGas(testCase, removedGas)
            present = setdiff(testCase.C.gas, removedGas, 'stable');
            d = reduced_gas_diagnosis(testCase.g, present);
            testCase.verifyFalse(any(d.gate_upper));
            for m = ["iec" "rogers" "duval"]
                testCase.verifyFalse(any(d.(m) == "Normal"), char(m));
            end
        end

        function sensitivityGateIsNotStricterThanPrimary(testCase, removedGas)
            present = setdiff(testCase.C.gas, removedGas, 'stable');
            d = reduced_gas_diagnosis(testCase.g, present);
            testCase.verifyTrue(all(d.gate_on_measured | ~testCase.five.gate_upper), ...
                'a record that passes the five-gas gate must pass the gate on fewer gases');
        end

        % ---- (f) input checks and bookkeeping ---------------------------------------------------------------
        function unknownGasNameIsRejected(testCase)
            testCase.verifyError(@() reduced_gas_diagnosis(testCase.g, ["H2" "CO"]), 'reduced_gas_diagnosis:gas');
        end

        function requiredGasesComeFromConfiguration(testCase)
            testCase.verifyEqual(testCase.C.requiredGas.iec, testCase.C.gas);
            testCase.verifyEqual(testCase.C.requiredGas.rogers, testCase.C.gas);
            testCase.verifyEqual(testCase.C.requiredGas.duval, ["CH4" "C2H4" "C2H2"]);
        end

        function batchPassesItsChecksAndHasAllRows(testCase)
            [T, chk] = run_reduced_gas_applicability('Write', false);
            testCase.verifyTrue(all(chk.passed));
            testCase.verifyEqual(height(T), (2^numel(testCase.C.gas) - 1) * 3 * (1 + numel(testCase.C.roles)));
            testCase.verifyEqual(T.Properties.VariableNames(1:8), ...
                {'subset_id', 'n_gases', 'method', 'applicable', 'data_role', 'n_records', 'n_nd', 'share_nd'});
        end

        function noTypedLimitsInTheNewCode(testCase)
            ok = check_no_typed_limits();
            testCase.verifyTrue(ok);
        end
    end
end
