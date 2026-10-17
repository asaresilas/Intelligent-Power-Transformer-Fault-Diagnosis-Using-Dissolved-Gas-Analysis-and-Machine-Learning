# 07 — Experiment Records

**Purpose.** Make every reported number traceable and reproducible.

**Structure.** One folder per run: `YYYY-MM-DD_<short-name>/` containing
- `config.yaml` (copy of the config used), `seed.txt`, `data_hash.txt`, `environment.txt`;
- `fold_predictions.csv` (sample id, fold, true label, predicted label, class probabilities);
- `metrics.json`;
- `notes.md` (what was tested and what was observed).

**Rules**
- Runs are never overwritten or edited; a corrected run gets a new folder and the old one is marked superseded in `index.csv`.
- `index.csv` lists all runs and which thesis table/figure uses each.

**Acceptance criteria.** Every table and figure in `11_Results/` names its run folder; re-running the config reproduces `metrics.json`.

**Feeds thesis.** Chapter 4; reproducibility appendix.
