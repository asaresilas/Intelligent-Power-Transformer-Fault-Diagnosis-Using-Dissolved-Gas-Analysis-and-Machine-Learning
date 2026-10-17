# report_entries_19.ps1 - "Method used" and closing entries for roadmap Step 19 (report standard 2026-10-10/11).
# Dot-source after helpers.ps1, report_closings.ps1, report_methods.ps1 (and the 14-17 / 18 entry files).

$global:Methods["19"] = @{
  Approach = @(
    "Each machine-learning model is wrapped in a scikit-learn pipeline: a fixed chain of steps that always runs in the same order and is always fitted as one unit. The chain is: (1) build the features of the chosen feature set from the five gases; (2) fill in undefined values with the training-fold median; (3) standardise every feature with the training-fold mean and standard deviation; (4) fit the classifier with class weights computed from the training-fold labels.",
    "Because the whole chain is refitted on every training fold, nothing learned from the data - medians, means, standard deviations or class weights - can come from a held-out record. Step 1 learns nothing at all: each record's features are calculated from its own gases only.",
    "Four feature sets (Analysis Plan Section 5.1) and six models (Section 5.2: majority baseline, SVM, Random Forest, XGBoost, MLP, logistic regression) give 24 pipelines. Each was run once on the training part of one fold to prove it works; no score is computed in this step.")
  Why = @(
    "Fitting preprocessing on all the data before splitting is a common form of leakage that makes cross-validation scores too optimistic; putting every learned step inside the pipeline is the standard remedy, and it is required by the roadmap check for Step 19.",
    "Logarithms tame the very skewed gas concentrations; percentages and ratios give fingerprints that do not depend on the total amount of gas; standardisation puts all features on the same scale, which the SVM, the neural network and logistic regression need.",
    "Class weights make every fault class count equally even though the development classes range from 37 (PD) to 85 (D2) records.")
  Settings = @(
    @("F1 - log gases (5)", "log10(x + 1) for H2, CH4, C2H6, C2H4, C2H2 (Eq. 11)"),
    @("F2 - gas percentages (5)", "100 x_g / sum of the five gases (Eq. 12)"),
    @("F3 - ratios and Duval (8)", "log10((a+1)/(b+1)) for R1-R5 (D15) + the three Duval Triangle 1 percentages (Eq. 4)"),
    @("F4 - all (18)", "F1 + F2 + F3"),
    @("Imputation", "median of the training fold - only the Duval percentages of 2 development records are undefined (D15)"),
    @("Scaling", "z = (x - mean) / sd from the training fold (Eq. 13)"),
    @("Class weights", "w_c = N / (K n_c) from the training-fold labels, passed as sample weights (Eq. 14, D15); baseline not weighted"),
    @("Oversampling", "none - SMOTE was not approved (D15)"),
    @("SVM", "RBF kernel; probabilities by Platt (sigmoid) calibration on 5 internal folds (D16)"),
    @("Neural network (MLP)", "L-BFGS solver, up to 5 000 iterations (D16)"),
    @("Random seed", "20261010 (same as folds.csv)"))
  Eqs = @(
    @{ Eq = 'x{TILDE}_g=log_10 (x_g+1)'; Where = @(
        @('x{TILDE}_g', 'log-transformed concentration of gas g (Analysis Plan Eq. 11)'),
        @('x_g', 'concentration of gas g [ppm]; not detected = 0 ppm (D8)')) },
    @{ Eq = 'r_k=log_10 ((x_a+1)/(x_b+1))'; Where = @(
        @('r_k', 'log-ratio feature k (k = R1 ... R5), decision D15'),
        @('x_a, x_b', 'numerator and denominator gases of ratio k [ppm], e.g. R2 = C2H2/C2H4')) },
    @{ Eq = 'w_c=N/(K⋅n_c )'; Where = @(
        @('w_c', 'weight of every training record of class c (Analysis Plan Eq. 14)'),
        @('N', 'number of records in the training fold'),
        @('K', 'number of classes in the training fold (7)'),
        @('n_c', 'number of training-fold records of class c')) })
  Tools = @("06_Python_ML/src/ml/features.py (FeatureBuilder), pipelines.py (pipelines, class weights, PlattSVC), step19_build_pipelines.py (catalogue); configs/ml_config.yaml",
            "scikit-learn 1.9.1, xgboost 3.4.1, numpy 2.5.3, pandas 3.0.6; tests/test_pipelines.py (pytest 9.1.1, 31 tests)")
  Refs = @("M3", "M10", "M11", "M12")
}

$global:Closings["19"] = @{
  Achieved = @(
    "24 ready-to-train pipelines (4 feature sets x 6 models), all settings read from one configuration file (configs/ml_config.yaml).",
    "Every learned step - imputation, scaling and class weights - is proven by automated tests to use the training rows only, both in a single fold and inside the inner folds of the tuning search.",
    "Two technical problems were found and solved before any training: the SVM probability method that scikit-learn is removing, and the neural network that did not converge (decision D16).",
    "31 new automated tests; the whole suite passes 87 of 87.")
  Record = @(
    @("Step", "19 - Build the preprocessing and feature pipelines"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "11 October 2026"), @("Status", "Done"),
    @("Main inputs", "dga_master.csv and folds.csv (data version 1.0); Analysis Plan Sections 5.1-5.4"),
    @("Main outputs", "06_Python_ML/src/ml (features.py, pipelines.py, step19_build_pipelines.py); configs/ml_config.yaml; configs/pipeline_catalog.csv; step19_report.md"),
    @("Checks", "24 of 24 pipelines run; leakage tests PASS; pytest 87 of 87"), @("Decisions", "D15 (features, imputation, class weights; researcher) and D16 (SVM calibration, MLP solver; procedural)"))
  Helps = @(
    "Step 20 trains and tunes these exact pipelines with nested cross-validation on the 50 fixed folds; nothing about the models has to be decided any more.",
    "Because the pipelines are leakage-proof by construction, the cross-validation scores of Step 20 will be honest estimates.",
    "The same pipeline object is what Step 24 saves and what the diagnosis service (Step 38) loads, so the features are computed identically everywhere.")
  Open = @(
    "No performance has been measured yet (by design); Step 20 does that.",
    "The models assume the gas values are in ppm; the external Li 2019 data state no units (TO VERIFY, see the register).")
  Exclude = @()
}

$global:StepSources["19"] = @("DF2", "DF3", "DF6", "DF18", "DF19", "DF20", "SW1")
