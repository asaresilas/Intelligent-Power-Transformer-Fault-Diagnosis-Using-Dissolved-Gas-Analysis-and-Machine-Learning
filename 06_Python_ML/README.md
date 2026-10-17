# 06 — Python Machine-Learning Pipeline

**Purpose.** Objective 2 and the reduced-gas study: train, tune and evaluate classifiers without data leakage, and identify the gases that drive the best model.

**Inputs.** `03_Data/processed/` table and `folds.csv`; threshold files from `02_Standards/` (for the Python copy of the conventional methods).

**Layout**
- `src/preprocess.py` — cleaning rules, log transform, scaling (inside the pipeline).
- `src/features.py` — gas percentages and standard diagnostic ratios.
- `src/conventional.py` — independent Python implementation of Rogers, IEC, Duval (cross-check of folder 04).
- `src/train.py` — nested, repeated stratified k-fold training.
- `src/evaluate.py` — per-class metrics, confusion matrices, bootstrap confidence intervals.
- `src/ablation.py` — reduced-gas experiments on the same folds.
- `src/explain.py` — permutation importance and SHAP.
- `configs/` — one YAML per experiment (models, grids, seed, gas subset).
- `tests/` — leakage test, duplicate-across-folds test, MATLAB/Python agreement test.
- `environment.yml` / `requirements.txt` — pinned versions.

**Method**
- Models: SVM, Random Forest, XGBoost, ANN (MLP), and a fifth per decision D6.
- Scaler, feature selection and any oversampling are fitted on training folds only, via a single `Pipeline`.
- Hyper-parameters chosen in the inner loop; performance estimated in the outer loop.
- Metrics: per-class precision, recall, F1; macro-F1; balanced accuracy; 95 % confidence intervals.
- Ablation: remove gases singly and in field-realistic combinations; only gas availability changes.

**Acceptance criteria.** All tests pass; a run is reproducible from config + seed; every run writes to `07_Experiments/`.

**Feeds thesis.** Chapter 3 (ML pipeline), Chapter 4 (classifier comparison, key gases, reduced-gas results).
