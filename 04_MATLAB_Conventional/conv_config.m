function C = conv_config()
%CONV_CONFIG  Fixed names, paths and bookkeeping constants for the conventional DGA methods.
%
%   C = conv_config()
%
%   PURPOSE
%     One place for everything that is NOT a decision limit: folder paths, gas and ratio names,
%     the Rogers case-to-class mapping (decision D11, rule 5), the tap-changer rule for the
%     C2H2 typical value (D11, rule 2) and two numerical constants.
%     No decision limit (ratio limit, zone limit, typical value) is stored here or anywhere in
%     the .m code: all of them are read from the CSV files in 02_Standards by load_standards.m.
%
%   OUTPUT  C  (struct)
%     C.root, C.stdDir, C.dataDir, C.outDir ... project folders (found from this file's location)
%     C.gas        ... ["H2" "CH4" "C2H6" "C2H4" "C2H2"], the five gases, in this column order
%     C.ratioIds   ... ["R1" "R2" "R5"]  (Rogers naming, IEEE C57.104-2008 Table 6)
%     C.ratioNum / C.ratioDen ... numerator and denominator gas of each ratio
%     C.ratioText  ... the ratio labels as printed in the CSV files, mapped to ratio ids
%     C.rogersCaseLabel ... project class of Rogers cases 0..5 (D11, rule 5)
%     C.oltcCommunicatingType ... IEC TC 10 equipment code "U" (D11, rule 2)
%     C.grpAll, C.grpNoOLTC, C.grpOLTC ... group names used in iec_typical_values.csv
%     C.duvalGas, C.requiredGas ... gases needed by Duval / by each method (Step 26, D23 proposed)
%     C.roles      ... the four data_role values of dga_master.csv
%     C.pctTotal   ... 100: the three Duval percentages add up to 100 (a definition, not a limit)
%     C.probeEps   ... 1e-6 percentage points: numerical offset used only to look "just across"
%                      a zone edge when the decision edges are extracted (see duval_decision_edges.m)
%     C.dataVersion ... "1.0"
%
%   SOURCES
%     Decision D11 (00_Project_Admin/decisions_log.md, closed 2026-10-11);
%     Analysis Plan Section 4.5 (boundary distance); IEEE Std C57.104-2008 Table 6 (Rogers cases).
%
%   Project: MPhil, DGA transformer fault diagnosis - Step 14 (conventional methods in MATLAB).

here = fileparts(mfilename('fullpath'));            % ...\04_MATLAB_Conventional
C.root    = fileparts(here);                        % project root
C.stdDir  = fullfile(C.root, '02_Standards');
C.dataDir = fullfile(C.root, '03_Data');
C.outDir  = fullfile(C.root, '11_Results', 'conventional');
C.figDir  = fullfile(C.root, '11_Results', 'figures');
C.masterFile   = fullfile(C.dataDir, 'processed', 'dga_master.csv');
C.manifestFile = fullfile(C.dataDir, 'data_version_1.0.sha256');
C.styleFile    = fullfile(C.figDir, 'plot_style.csv');
C.dataVersion  = "1.0";

C.gas = ["H2" "CH4" "C2H6" "C2H4" "C2H2"];

% Ratio definitions (names only). R1 = CH4/H2, R2 = C2H2/C2H4, R5 = C2H4/C2H6.
C.ratioIds = ["R1" "R2" "R5"];
C.ratioNum = ["CH4"  "C2H2" "C2H4"];
C.ratioDen = ["H2"   "C2H4" "C2H6"];
% How the ratio is written in the CSV files (Rogers rows add " (R1)" etc., which load_standards removes).
C.ratioText = dictionary(["CH4/H2" "C2H2/C2H4" "C2H4/C2H6"], C.ratioIds);

% Decision D11 rule 5: Rogers case 0..5 -> project class label.
C.rogersCaseLabel = ["Normal" "PD" "D2" "T1" "T2" "T3"];

% Decision D11 rule 2: which C2H2 typical-value row applies.
C.oltcCommunicatingType = "U";                       % IEC TC 10 equipment code U
C.grpAll    = "All transformers";
C.grpNoOLTC = "No OLTC";
C.grpOLTC   = "Communicating OLTC";

% Step 26 (decision D23, proposed): which gases each method NEEDS. The ratio methods (IEC 60599, Rogers) need every
% gas that appears in R1, R2 or R5 (all five); Duval Triangle 1 needs the gases of its three percentages.
% Derived from the definitions above, not typed per method.
C.duvalGas = ["CH4" "C2H4" "C2H2"];
C.requiredGas = struct( ...
    'iec',    C.gas(ismember(C.gas, [C.ratioNum C.ratioDen])), ...
    'rogers', C.gas(ismember(C.gas, [C.ratioNum C.ratioDen])), ...
    'duval',  C.gas(ismember(C.gas, C.duvalGas)));
C.roles = ["development" "internal_test" "benchmark" "external_test"];   % data_role values of dga_master.csv

C.pctTotal = 100;
C.probeEps = 1e-6;
end
