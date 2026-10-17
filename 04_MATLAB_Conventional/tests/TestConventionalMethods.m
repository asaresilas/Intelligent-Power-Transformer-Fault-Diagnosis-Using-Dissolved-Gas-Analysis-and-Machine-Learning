classdef TestConventionalMethods < matlab.unittest.TestCase
%TESTCONVENTIONALMETHODS  Unit tests of the conventional DGA methods (Roadmap Step 15).
%
%   Run:  results = runtests('TestConventionalMethods');   or   run_tests_and_log   (writes test_log.txt)
%
%   WHAT IS TESTED
%     (a) every row of 02_Standards/worked_examples.csv: 38 Duval Triangle 1 examples printed in the
%         literature (Aciu et al. 2021; Manisha et al. 2022) + 1 Rogers example (IEEE C57.104-2008
%         Figure 2, Case 2). The METHOD output BEFORE the normality gate is compared with the printed
%         diagnosis; the gate is switched off because the gate (D11) is a project rule, not part of the
%         published examples (examples MAN-22 and MAN-23 have gas values below the gate).
%     (b) zero denominators: undefined ratios give ND; the decision D12 rule (an undefined ratio the
%         table marks "NS" does not stop a class from matching); zero numerator is a valid ratio 0.
%     (c) samples exactly ON a boundary follow decision D11: "<" and ">" strict, printed ranges include
%         both end points, Duval lower limit inclusive / upper limit exclusive.
%     (d) the normality gate: upper end (primary), lower end (sensitivity), tap-changer rule for C2H2.
%     (e) structure: the Duval rule polygons cover the triangle exactly once; Rogers cases never overlap;
%         the dual answer D1/D2 (PD/T1 was removed by decision D13); boundary distances; frozen data version; batch output size;
%         no typed limits in the code.
%
%   Gas values used to build boundary samples are chosen so that the ratio is EXACTLY equal to a limit.
%   Every threshold used for comparison is read from 02_Standards (never typed in a test).
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 15.

    properties (TestParameter)
        example = TestConventionalMethods.exampleParams();
    end

    properties
        S      % standards read from 02_Standards
        C      % configuration
    end

    methods (TestClassSetup)
        function addCodeToPath(testCase)
            here = fileparts(mfilename('fullpath'));
            addpath(fileparts(here));
            testCase.addTeardown(@() rmpath(fileparts(here)));
            testCase.S = load_standards(true);
            testCase.C = conv_config();
        end
    end

    methods (Static)
        function p = exampleParams()
            % One test per row of worked_examples.csv: parameter name = example_id (dashes -> underscores).
            % The parameters are created when the test suite is built, before the class setup runs,
            % so the code folder (parent of tests/) is put on the path here as well.
            addpath(fileparts(fileparts(mfilename('fullpath'))));
            C = conv_config();
            T = readtable(fullfile(C.stdDir, 'worked_examples.csv'), 'TextType', 'string');
            p = struct();
            for i = 1:height(T)
                p.(strrep(T.example_id(i), '-', '_')) = T(i, :);
            end
        end

        function d = diagnose(g)
            % Convenience: diagnose one sample given as a struct of gases (missing gas -> 0 ppm, D8).
            names = ["H2" "CH4" "C2H6" "C2H4" "C2H2"];
            for k = 1:numel(names)
                if ~isfield(g, names(k)) || isnan(g.(names(k))), g.(names(k)) = 0; end
            end
            d = conventional_diagnosis(g);
        end
    end

    % ------------------------------------------------------------------------------------ (a) examples
    methods (Test)
        function workedExample(testCase, example)
            % Reproduce the diagnosis printed in the source of the example.
            g = struct('H2', example.H2, 'CH4', example.CH4, 'C2H6', example.C2H6, ...
                'C2H4', example.C2H4, 'C2H2', example.C2H2);
            d = TestConventionalMethods.diagnose(g);
            if example.method == "Duval Triangle 1"
                testCase.verifyEqual(d.raw.duval, example.diagnosis_printed, ...
                    sprintf('Duval Triangle 1 example %s', example.example_id));
            else
                % IEEE C57.104-2008 Figure 2 step 6: "Case 2 - possible arcing"
                caseNo = str2double(regexp(example.diagnosis_printed, '(?<=Case )\d+', 'match', 'once'));
                testCase.verifyEqual(d.raw.rogers, testCase.C.rogersCaseLabel(caseNo + 1));
                testCase.verifyEqual(d.ratios.R2, 5/17, 'AbsTol', 0.005);     % 0.29 printed
                testCase.verifyEqual(d.ratios.R1, 190/270, 'AbsTol', 0.005);   % 0.70 printed
                testCase.verifyEqual(d.ratios.R5, 17/4, 'AbsTol', 0.005);      % 4.25 printed
            end
        end

        function exampleCountIsComplete(testCase)
            % Instruction for Step 15: 39 Duval Triangle 1 examples and 1 Rogers example.
            T = readtable(fullfile(testCase.C.stdDir, 'worked_examples.csv'), 'TextType', 'string');
            testCase.verifyEqual(nnz(T.method == "Duval Triangle 1"), 39);
            testCase.verifyEqual(nnz(T.method == "Rogers ratios"), 1);
        end
    end

    % ---------------------------------------------------------------------------- (b) zero denominators
    methods (Test)
        function zeroDenominatorGivesUndefinedRatio(testCase)
            r = gas_ratios(struct('H2', 0, 'CH4', 5, 'C2H6', 0, 'C2H4', 0, 'C2H2', 0));
            testCase.verifyTrue(isnan(r.R1));   % CH4/0
            testCase.verifyTrue(isnan(r.R2));   % 0/0
            testCase.verifyTrue(isnan(r.R5));   % 0/0
        end

        function zeroNumeratorIsAValidRatio(testCase)
            r = gas_ratios(struct('H2', 4, 'CH4', 0, 'C2H6', 2, 'C2H4', 0, 'C2H2', 0));
            testCase.verifyEqual(r.R1, 0);      % 0/4 = 0, not undefined
            testCase.verifyEqual(r.R5, 0);
        end

        function rogersNeedsAllThreeRatios(testCase)
            % Every Rogers case uses R1, R2 and R5, so any undefined ratio -> ND.
            d = TestConventionalMethods.diagnose(struct('H2', 0, 'CH4', 5, 'C2H6', 4, 'C2H4', 8, 'C2H2', 2));
            testCase.verifyEqual(d.raw.rogers, "ND");
        end

        function iecUndefinedNeededRatioGivesND(testCase)
            % R5 = C2H4/C2H6 with C2H6 = 0 is undefined and is used by every IEC class -> ND.
            d = TestConventionalMethods.diagnose(struct('H2', 100, 'CH4', 5, 'C2H6', 0, 'C2H4', 10, 'C2H2', 4));
            testCase.verifyEqual(d.raw.iec, "ND");
        end

        function iecUndefinedNSRatioStillDiagnoses(testCase)
            % Decision D12: C2H4 = 0 makes R2 undefined, but R2 is "NS" for PD, so PD can match (with D13, PD alone).
            % (Typical of the IEC TC 10 partial-discharge records.)
            d = TestConventionalMethods.diagnose(struct('H2', 32930, 'CH4', 2397, 'C2H6', 157, 'C2H4', 0, 'C2H2', 0));
            testCase.verifyTrue(isnan(d.ratios.R2));
            testCase.verifyEqual(d.raw.iec, "PD");
        end

        function duvalAllZeroGivesND(testCase)
            d = TestConventionalMethods.diagnose(struct('H2', 50, 'CH4', 0, 'C2H6', 9, 'C2H4', 0, 'C2H2', 0));
            testCase.verifyEqual(d.raw.duval, "ND");
            testCase.verifyTrue(isnan(d.boundary.duval));
        end
    end

    % ------------------------------------------------------------------------ (c) boundary samples (D11)
    methods (Test)
        function iecStrictLessThanAtLimit(testCase)
            % R1 = 0.1 exactly: PD needs CH4/H2 < 0.1 (strict), so PD must NOT match; T1 needs R1 > 1 (D13): ND.
            d = TestConventionalMethods.diagnose(struct('H2', 100, 'CH4', 10, 'C2H6', 100, 'C2H4', 1, 'C2H2', 0));
            testCase.verifyEqual(d.ratios.R1, 0.1);
            testCase.verifyEqual(d.raw.iec, "ND");
            % just below the limit PD matches (and only PD, since T1 needs R1 > 1)
            d = TestConventionalMethods.diagnose(struct('H2', 10000, 'CH4', 999, 'C2H6', 100, 'C2H4', 1, 'C2H2', 0));
            testCase.verifyEqual(d.raw.iec, "PD");
        end

        function iecRangeIncludesBothEndPoints(testCase)
            % D1/D2 CH4/H2 range is printed "0.1 - 0.5" / "0.1 - 1": both end points belong to the range.
            hi = struct('H2', 10, 'CH4', 5, 'C2H6', 2, 'C2H4', 10, 'C2H2', 20);    % R1 = 0.5 exactly
            lo = struct('H2', 100, 'CH4', 10, 'C2H6', 2, 'C2H4', 10, 'C2H2', 20);  % R1 = 0.1 exactly
            testCase.verifyEqual(TestConventionalMethods.diagnose(hi).raw.iec, "D1/D2");
            testCase.verifyEqual(TestConventionalMethods.diagnose(lo).raw.iec, "D1/D2");
            below = struct('H2', 100, 'CH4', 9.99, 'C2H6', 2, 'C2H4', 10, 'C2H2', 20);   % R1 just below 0.1
            testCase.verifyEqual(TestConventionalMethods.diagnose(below).raw.iec, "ND");
        end

        function iecStrictGreaterThanAtLimit(testCase)
            % T2 has C2H4/C2H6 printed "1 - 4" (4 included); T3 has "> 4" (4 excluded). R5 = 4 -> T2 only.
            g = struct('H2', 10, 'CH4', 20, 'C2H6', 10, 'C2H4', 40, 'C2H2', 0);
            testCase.verifyEqual(TestConventionalMethods.diagnose(g).raw.iec, "T2");
            g.C2H4 = 41;                                                            % R5 just above 4
            testCase.verifyEqual(TestConventionalMethods.diagnose(g).raw.iec, "T3");
        end

        function rogersStrictBothSidesAtOne(testCase)
            % R1 = 1 exactly: cases 0 and 3 need R1 < 1, case 4 and 5 need R1 > 1 -> no case: ND.
            g = struct('H2', 10, 'CH4', 10, 'C2H6', 5, 'C2H4', 10, 'C2H2', 0.5);   % R1 = 1, R2 = 0.05, R5 = 2
            testCase.verifyEqual(TestConventionalMethods.diagnose(g).raw.rogers, "ND");
            % the arcing case prints R1 as "0.1 to 1.0" (included): R1 = 1, R2 = 0.5, R5 = 4 -> Case 2
            g = struct('H2', 10, 'CH4', 10, 'C2H6', 5, 'C2H4', 20, 'C2H2', 10);
            testCase.verifyEqual(TestConventionalMethods.diagnose(g).raw.rogers, "D2");
        end

        function duvalLowerLimitIncludedUpperExcluded(testCase)
            % Percentages are exact because CH4 + C2H4 + C2H2 = 100.
            t2 = struct('H2', 0, 'CH4', 79, 'C2H6', 0, 'C2H4', 20, 'C2H2', 1);    % %C2H4 = 20  -> T2 (T1 needs < 20)
            t1 = struct('H2', 0, 'CH4', 79.5, 'C2H6', 0, 'C2H4', 19.5, 'C2H2', 1);% %C2H4 = 19.5 -> T1
            t3 = struct('H2', 0, 'CH4', 49, 'C2H6', 0, 'C2H4', 50, 'C2H2', 1);    % %C2H4 = 50  -> T3 (T2 needs < 50)
            pd = struct('H2', 0, 'CH4', 98, 'C2H6', 0, 'C2H4', 1, 'C2H2', 1);     % %CH4 = 98  -> PD (>= 98)
            dt = struct('H2', 0, 'CH4', 76, 'C2H6', 0, 'C2H4', 20, 'C2H2', 4);    % %C2H2 = 4  -> DT (T zones need < 4)
            testCase.verifyEqual(TestConventionalMethods.diagnose(t2).raw.duval, "T2");
            testCase.verifyEqual(TestConventionalMethods.diagnose(t1).raw.duval, "T1");
            testCase.verifyEqual(TestConventionalMethods.diagnose(t3).raw.duval, "T3");
            testCase.verifyEqual(TestConventionalMethods.diagnose(pd).raw.duval, "PD");
            testCase.verifyEqual(TestConventionalMethods.diagnose(dt).raw.duval, "DT");
        end

        function boundSemanticsOfBoundTest(testCase)
            testCase.verifyEqual(bound_test(1, "lt", NaN, 1), false);
            testCase.verifyEqual(bound_test(1, "gt", 1, NaN), false);
            testCase.verifyEqual(bound_test(1, "gt_lt", 1, 2), false);
            testCase.verifyEqual(bound_test(1, "range_endpoints_not_stated", 1, 2), true);
            testCase.verifyEqual(bound_test(2, "range_endpoints_not_stated", 1, 2), true);
            testCase.verifyEqual(bound_test(NaN, "lt", NaN, 1), false);
            testCase.verifyError(@() bound_test(1, "ns", NaN, NaN), 'bound_test:type');
        end
    end

    % -------------------------------------------------------------------------------- (d) normality gate
    methods (Test)
        function gateUpperAndLowerEnds(testCase)
            S = testCase.S;
            hi = pick_limits(S, "high", false);
            lo = pick_limits(S, "low", false);
            C = testCase.C;
            % all gases exactly at the upper end -> Normal by the upper gate
            testCase.verifyTrue(normality_gate(hi, "", S, "high"));
            % one gas just above -> not Normal
            above = hi; above(2) = above(2) + 1;
            testCase.verifyFalse(normality_gate(above, "", S, "high"));
            % lower-end sensitivity: exactly at the lower end passes, just above fails
            testCase.verifyTrue(normality_gate(lo, "", S, "low"));
            above = lo; above(1) = above(1) + 1;
            testCase.verifyFalse(normality_gate(above, "", S, "low"));
            testCase.verifyEqual(numel(C.gas), 5);
        end

        function gateC2H2DependsOnTapChanger(testCase)
            % D11 rule 2: "communicating OLTC" C2H2 range only for equipment code U, else "no OLTC".
            S = testCase.S;
            g = pick_limits(S, "high", false);                    % all at "no OLTC" upper end
            upperU = pick_limits(S, "high", true);                % C2H2 at the communicating-OLTC upper end
            testCase.verifyGreaterThan(upperU(5), g(5));
            testCase.verifyFalse(normality_gate(upperU, "P", S, "high"));   % too much C2H2 for "no OLTC"
            testCase.verifyTrue(normality_gate(upperU, testCase.C.oltcCommunicatingType, S, "high"));
            testCase.verifyTrue(normality_gate(g, "P", S, "high"));
        end

        function gatedSampleIsNormalInAllThreeMethods(testCase)
            % D11 rule 6: one common gate. A sample below every typical value is Normal for all methods,
            % while the raw method result is kept separately.
            lo = pick_limits(testCase.S, "low", false);
            g = struct('H2', lo(1), 'CH4', lo(2), 'C2H6', lo(3), 'C2H4', lo(4), 'C2H2', lo(5));
            d = conventional_diagnosis(g);
            testCase.verifyEqual([d.iec d.rogers d.duval], ["Normal" "Normal" "Normal"]);
            testCase.verifyTrue(d.gate_upper);
            testCase.verifyTrue(d.gate_lower);
        end
    end

    % ------------------------------------------------------------------------------------ (e) structure
    methods (Test)
        function duvalPolygonsCoverTriangleExactlyOnce(testCase)
            Z = duval_zone_polygons(testCase.S);
            A = arrayfun(@(z) polyarea(z.poly(:, 1), z.poly(:, 2)), Z);
            T = testCase.C.pctTotal;
            testCase.verifyEqual(sum(A), T^2 / 2, 'AbsTol', 1e-9);        % no gap and no overlap
            testCase.verifyEqual(numel(Z), height(testCase.S.duval.rules));
        end

        function duvalEveryPointHasAZone(testCase)
            T = testCase.C.pctTotal;
            [a, b] = meshgrid(0:0.5:T);
            keep = a + b <= T;
            a = a(keep); b = b(keep);
            z = diagnose_duval(T - a - b, a, b, testCase.S.duval.rules);
            testCase.verifyFalse(any(z == "ND"));
        end

        function rogersCasesNeverOverlap(testCase)
            % Dense logarithmic grid of (R1, R2, R5) that also contains every printed limit.
            S = testCase.S;
            lims = unique([S.rogers.rows.lower; S.rogers.rows.upper]);
            lims = lims(~isnan(lims));
            v = unique([logspace(-3, 3, 61), lims.', lims.' * (1 + 1e-9), lims.' * (1 - 1e-9)]);
            [R1, R2, R5] = ndgrid(v, v, v);
            [~, mm] = diagnose_ratio_method([R1(:) R2(:) R5(:)], S.rogers.rows);
            testCase.verifyLessThanOrEqual(max(sum(mm, 2)), 1);
        end

        function iecT1RequiresMethaneHydrogenAboveOne(testCase)
            % Decision D13: the printed "CH4/H2 > 1 but NS" of T1 is used as the condition R1 > 1 (strict).
            g = struct('H2', 10, 'CH4', 20, 'C2H6', 10, 'C2H4', 5, 'C2H2', 0);      % R1 = 2, R5 = 0.5
            testCase.verifyEqual(TestConventionalMethods.diagnose(g).raw.iec, "T1");
            g.CH4 = 10;                                                                    % R1 = 1 exactly: not > 1
            testCase.verifyEqual(TestConventionalMethods.diagnose(g).raw.iec, "ND");
            g.CH4 = 5;                                                                     % R1 = 0.5, R5 < 0.2 would be needed for PD
            testCase.verifyEqual(TestConventionalMethods.diagnose(g).raw.iec, "ND");
        end

        function iecOverlapsAreOnlyTheDeclaredDualAnswer(testCase)
            S = testCase.S;
            lims = unique([S.iec.rows.lower; S.iec.rows.upper]);
            lims = lims(~isnan(lims));
            v = unique([logspace(-3, 3, 41), lims.', lims.' * (1 + 1e-9), lims.' * (1 - 1e-9)]);
            [R1, R2, R5] = ndgrid(v, v, v);
            lab = diagnose_ratio_method([R1(:) R2(:) R5(:)], S.iec.rows);
            multi = unique(lab(contains(lab, "/")));
            testCase.verifyEqual(sort(multi), "D1/D2");       % PD/T1 no longer occurs (D13)
        end

        function boundaryDistanceRatioInDecades(testCase)
            % Only R1 defined (C2H4 = C2H6 = 0 so R2 and R5 are undefined): R1 = 0.2.
            % Nearest IEC R1 limit is 0.1 (0.30103 decades); the others are 0.5 and 1.
            d = TestConventionalMethods.diagnose(struct('H2', 10, 'CH4', 2, 'C2H6', 0, 'C2H4', 0, 'C2H2', 1));
            testCase.verifyEqual(d.boundary.iec, log10(2), 'AbsTol', 1e-12);
            % a ratio of exactly 0 is infinitely far on a log scale
            d = TestConventionalMethods.diagnose(struct('H2', 10, 'CH4', 0, 'C2H6', 0, 'C2H4', 0, 'C2H2', 0));
            testCase.verifyEqual(d.boundary.iec, Inf);
            % all ratios undefined -> no distance
            d = TestConventionalMethods.diagnose(struct('H2', 0, 'CH4', 0, 'C2H6', 0, 'C2H4', 0, 'C2H2', 0));
            testCase.verifyTrue(isnan(d.boundary.iec));
        end

        function boundaryDistanceDuvalIsPerpendicularInPercentagePoints(testCase)
            % Point (%C2H4, %C2H2) = (19.9, 1): the nearest decision edge is the line %C2H4 = 20, which is
            % 0.1 percentage points away measured along the %C2H4 axis, i.e. 0.1*sqrt(3)/2 in the plane.
            d = boundary_distance_duval(19.9, 1, testCase.S);
            testCase.verifyEqual(d, 0.1 * sqrt(3) / 2, 'AbsTol', 1e-9);
            % on the boundary: zero
            testCase.verifyEqual(boundary_distance_duval(20, 1, testCase.S), 0, 'AbsTol', 1e-9);
        end

        function duvalDecisionEdgesIgnoreTriangleSidesAndSeams(testCase)
            % A point on a triangle side is NOT at distance 0 from a decision edge just because it lies on
            % the side. (%C2H4, %C2H2) = (35, 0) is on the base of the triangle; the nearest decision edge
            % is the T2/DT limit %C2H2 = 4 (the T1/T2 edge at %C2H4 = 20 and the T2/T3 edge at 50 are
            % 15 points away along the base), 4 points away along the %C2H2 axis = 4*sqrt(3)/2 in the plane.
            d = boundary_distance_duval(35, 0, testCase.S);
            testCase.verifyEqual(d, 4 * sqrt(3) / 2, 'AbsTol', 1e-9);
            % The seam inside D2 (%C2H2 = 29 between the two D2 rules) is not a decision edge:
            E = duval_decision_edges(testCase.S);
            sameZone = E.zone1 == E.zone2;
            testCase.verifyFalse(any(sameZone));
        end

        function frozenDataVersionVerifies(testCase)
            testCase.verifyTrue(verify_data_version('Quiet', true));
        end

        function batchHasOneRowPerRecordAndMethod(testCase)
            [P, counts] = run_conventional_batch('Write', false);
            C = testCase.C;
            M = readtable(C.masterFile, 'TextType', 'string');
            testCase.verifyEqual(height(P), 3 * height(M));
            testCase.verifyEqual(sort(unique(P.method)), sort(["IEC60599"; "Rogers"; "Duval"]));
            testCase.verifyEqual(unique(P.data_version), "1.0");
            testCase.verifyTrue(any(P.result == "ND"));                         % ND rows are kept
            testCase.verifyEqual(counts.n(counts.data_role == "all" & counts.method == "Rogers"), height(M));
        end

        function noTypedLimitsInCode(testCase)
            [ok, T] = check_no_typed_limits();
            testCase.verifyTrue(ok, sprintf('%d disallowed numeric literal(s) found.', height(T)));
        end
    end
end

function g = pick_limits(S, whichEnd, useOLTC)
% Gas vector [H2 CH4 C2H6 C2H4 C2H2] equal to the upper or lower end of the IEC Table A.2 ranges,
% read from the CSV (C2H2 from the "communicating OLTC" row when useOLTC is true).
C = conv_config();
g = zeros(1, numel(C.gas));
for j = 1:numel(C.gas)
    if C.gas(j) == "C2H2"
        grp = C.grpNoOLTC; if useOLTC, grp = C.grpOLTC; end
        row = S.typical(S.typical.gas == "C2H2" & S.typical.group == grp, :);
    else
        row = S.typical(S.typical.gas == C.gas(j) & S.typical.group == C.grpAll, :);
    end
    g(j) = row.(char(whichEnd));
end
end
