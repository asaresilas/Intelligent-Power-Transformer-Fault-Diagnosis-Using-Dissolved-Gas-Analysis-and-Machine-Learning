# report_entries_24.ps1 - "Method used" and closing entries for roadmap Step 24 (report standard 2026-10-10/11).
# Result values are NOT typed here: the builder fills $global:S24 from the result files before dot-sourcing.

$s = $global:S24
$global:Methods["24"] = @{
  Approach = @(
    "The pipeline fitted in Step 22 (preprocessing and Random Forest together) was copied byte for byte into the project's model folder as version 1, not fitted again, so every result of Steps 22 and 23 belongs to exactly this file. Its SHA-256 fingerprint is stored beside it.",
    "The file is loaded only through a small loader (model_io.load_model) that refuses any file whose fingerprint differs from the recorded one.",
    "To prove the file is complete, it was reloaded in a fresh Python process and used to predict the 388 test records again; the classes and every class probability had to be identical to the Step 22 predictions. A model card (Mitchell et al., 2019) was generated from the saved result files.")
  Why = @(
    "A versioned, fingerprinted model file lets anyone - the examiners, a utility, or the dashboard of Steps 38 onwards - use exactly the model whose performance is reported.",
    "Copying instead of refitting avoids any chance that a new fit differs slightly from the evaluated one.",
    "A model card states in one place what the model is for, what it is not for, and its known limits - expected in responsible engineering use of machine learning.")
  Settings = @(
    @("Model file", ("06_Python_ML/models/dga_model_v1.joblib; SHA-256 " + $s.hash.Substring(0, 16) + "...")),
    @("Content", "feature builder (F4, 18 features) -> median imputation -> standard scaling -> Random Forest (500 trees, class weights)"),
    @("Software needed", ("Python " + $s.python + ", scikit-learn " + $s.sklearn + ", project modules features.py and pipelines.py")),
    @("Reload check", "fresh Python process; 388 test records; classes and probabilities compared with ml_predictions.csv"),
    @("Model card", "06_Python_ML/models/model_card.md, generated from the result files of Steps 20-23"))
  Eqs = @()
  Tools = @("06_Python_ML/src/ml/step24_save_model.py (copy, fingerprint, reload check, model card)",
            "06_Python_ML/src/ml/model_io.py (load_model with fingerprint check); tests/test_model_v1.py (3 tests)")
  Refs = @("M19")
}

$global:Closings["24"] = @{
  Achieved = @(
    "The released model dga_model_v1 is saved with its fingerprint, metadata and model card.",
    ("Reloading it reproduced all " + $s.records + " test predictions exactly (largest probability difference " + $s.maxdiff + ")."),
    "A changed or damaged model file is refused automatically (tested).",
    "Stage D (machine learning, Steps 19-24) is complete.")
  Record = @(
    @("Step", "24 - Save the versioned model"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "12 October 2026"), @("Status", "Done"),
    @("Main inputs", "07_Experiments/2026-10-12_final_fit/final_pipeline.joblib and final_fit.json; results of Steps 20-23"),
    @("Main outputs", "06_Python_ML/models/: dga_model_v1.joblib, .sha256, _meta.json, model_card.md, reload_check.json"),
    @("Checks", ("reload check " + $s.pass + "; fingerprint equals Step 22; tamper test passes; " + $s.tests)),
    @("Decisions", "D21 (versioning and loading; procedural)"))
  Helps = @(
    "Steps 28-32 use the predictions of this exact model for the formal comparison with the conventional methods.",
    "The dashboard and API (Steps 38 onwards) load this file through model_io.load_model(), so the deployed model is provably the evaluated one.",
    "The model card is ready to be summarised in Chapter 3 and in the journal paper.")
  Open = @(
    "The file can only be loaded with the same library versions and project modules; a future version of scikit-learn may need the model to be re-saved and the reload check repeated.",
    "The model always gives an answer; it does not warn when a sample is unlike the training data. An out-of-range warning could be added in the dashboard stage.",
    "Mitchell et al. (2019): page range taken from secondary records, TO VERIFY (register M19).")
  Exclude = @()
}

$global:StepSources["24"] = @("DF24", "DF25", "DF26", "DF27", "DF22", "SW1")
