"""Roadmap Step 23 [Claude Code] - explain the fitted model (permutation importance and SHAP).

Input : the fitted pipeline of Step 22 (fingerprint checked against final_fit.json); dga_master.csv (data version 1.0).
Do    : (1) permutation importance, Analysis Plan Eq. 38 (Breiman 2001), R = 30 shuffles, on the three primary evaluation sets
        of D19, at GAS level (one raw gas shuffled at the pipeline input) and FEATURE level (one of the 18 F4 features
        shuffled after the feature builder) - decision D20;
        (2) SHAP, Eq. 39: exact TreeSHAP (Lundberg et al. 2020) of the Random Forest, in class-probability units, for the 439
        development records and the 388 test records; additivity check; rank agreement development vs test;
        (3) comparison with the engineering expectation fixed in D20 (key gases per fault type), reported as found.
Output: 11_Results/explain/ (permutation_importance.csv, shap_importance.csv, shap_values_development.csv,
        shap_values_test.csv, engineering_check.csv), Figures 4.14 and 4.15 in 11_Results/figures (PNG, PDF, CSV),
        03_Data/interim/step23_report.md
Note  : the model is not changed; the test sets are used only to explain the fixed model.
"""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "data_prep"))
sys.path.insert(0, str(HERE.parent / "analysis"))

import joblib  # noqa: E402
import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402
from scipy.stats import spearmanr  # noqa: E402
from sklearn.metrics import f1_score  # noqa: E402
from sklearn.pipeline import Pipeline  # noqa: E402

import plotstyle as ps  # noqa: E402
import step20_nested_cv as s20  # noqa: E402
from common import INTERIM, PROCESSED, PROJECT_ROOT, md_table, verify_data_version  # noqa: E402
from features import GASES, RATIOS  # noqa: E402
from step22_final_fit import MERGED5, SEVEN, TO_MERGED  # noqa: E402

FIT_DIR = PROJECT_ROOT / "07_Experiments" / "2026-10-12_final_fit"
OUT = PROJECT_ROOT / "11_Results" / "explain"
SEED, R = 20261010, 30
# D19 primary evaluation sets: (name, role, filter, label column, class list)
SETS = [("Internal test", "internal_test", "independent_of_benchmark", "class_name", SEVEN),
        ("IEC TC 10 (power transformers)", "benchmark", "in_scope_primary", "class_merged", MERGED5),
        ("Li 2019", "external_test", "independent_of_benchmark", "class_name", SEVEN[1:])]
# D20 (3): expected key gases per fault class, fixed before the results
EXPECTED = {"PD": {"H2"}, "D1": {"C2H2"}, "D2": {"C2H2"}, "T1": {"CH4", "C2H6"}, "T2": {"C2H4", "CH4"},
            "T3": {"C2H4"}}
LABEL = {"log": "log", "pct": "%", "duval_pct": "Duval %"}


def gases_of(feature: str) -> set[str]:
    if feature.startswith("log_R"):
        return set(RATIOS[feature[4:]])
    return {feature.split("_")[-1]}


def pretty(feature: str) -> str:
    if feature.startswith("log_R"):
        a, b = RATIOS[feature[4:]]
        return f"log {feature[4:]} ({a}/{b})"
    if feature.startswith("duval_pct_"):
        return f"Duval % {feature[10:]}"
    if feature.startswith("pct_"):
        return f"% {feature[4:]}"
    return f"log {feature[4:]}"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def main() -> int:
    problems = verify_data_version()
    if problems:
        raise SystemExit("data version 1.0 changed: " + "; ".join(problems))
    info = json.loads((FIT_DIR / "final_fit.json").read_text(encoding="utf-8"))
    pkl = FIT_DIR / "final_pipeline.joblib"
    assert sha256(pkl) == info["pipeline_sha256"], "fitted pipeline changed since Step 22"
    pipe = joblib.load(pkl)
    rest = Pipeline(pipe.steps[1:])
    fnames = list(pipe.named_steps["features"].get_feature_names_out())
    classes = [s20.CLASS_NAMES[int(c)] for c in pipe.named_steps["clf"].classes_]
    OUT.mkdir(parents=True, exist_ok=True)
    master = pd.read_csv(PROCESSED / "dga_master.csv")
    rng = np.random.default_rng(SEED)

    # (1) permutation importance
    def macro_f1(yt, pred_codes, labels, merged):
        names = pd.Series([s20.CLASS_NAMES[int(c)] for c in pred_codes])
        yp = names.map(TO_MERGED) if merged else names
        return f1_score(yt, yp, labels=labels, average="macro", zero_division=0)

    rows = []
    for name, role, filt, lab, labels in SETS:
        s = master[(master.data_role == role) & master[filt]].reset_index(drop=True)
        yt, merged, X = s[lab].to_numpy(), lab == "class_merged", s[GASES].reset_index(drop=True)
        base = macro_f1(yt, pipe.predict(X), labels, merged)
        Xf = pipe.named_steps["features"].transform(X)
        for level, cols in (("gas", GASES), ("feature", fnames)):
            for j, col in enumerate(cols):
                drops = []
                for _ in range(R):
                    perm = rng.permutation(len(s))
                    if level == "gas":
                        Xp = X.copy()
                        Xp[col] = X[col].to_numpy()[perm]
                        sc = macro_f1(yt, pipe.predict(Xp), labels, merged)
                    else:
                        Xp = Xf.copy()
                        Xp[:, j] = Xf[perm, j]
                        sc = macro_f1(yt, rest.predict(Xp), labels, merged)
                    drops.append(base - sc)
                d = np.array(drops)
                rows.append({"evaluation_set": name, "n": len(s), "level": level, "feature": col,
                             "baseline_macro_f1": round(base, 4), "importance_mean": d.mean(),
                             "ci_low": np.percentile(d, 2.5), "ci_high": np.percentile(d, 97.5)})
    pi = pd.DataFrame(rows)
    pi["rank"] = pi.groupby(["evaluation_set", "level"]).importance_mean.rank(ascending=False, method="min").astype(int)
    pi.round(5).to_csv(OUT / "permutation_importance.csv", index=False)

    # (2) SHAP (exact TreeSHAP of the forest, class-probability units)
    import shap
    rf = pipe.named_steps["clf"].estimator_
    explainer = shap.TreeExplainer(rf)
    dev = master[master.data_role == "development"].reset_index(drop=True)
    test = master[master.data_role != "development"].reset_index(drop=True)
    shap_out, add_err = {}, {}
    for key, d in (("development", dev), ("test", test)):
        Z = pipe[:-1].transform(d[GASES])
        sv = np.asarray(explainer.shap_values(Z, check_additivity=True))
        if sv.shape[0] == len(classes) and sv.shape[1] == len(d):      # older layout (class, record, feature)
            sv = np.transpose(sv, (1, 2, 0))
        assert sv.shape == (len(d), len(fnames), len(classes))
        recon = np.asarray(explainer.expected_value)[None, :] + sv.sum(axis=1)
        add_err[key] = float(np.abs(recon - pipe.predict_proba(d[GASES])).max())
        shap_out[key] = sv
        long = pd.concat([pd.DataFrame(sv[:, :, k], columns=fnames).assign(record_id=d.record_id.to_numpy(), cls=c)
                          for k, c in enumerate(classes)], ignore_index=True)
        long[["record_id", "cls"] + fnames].rename(columns={"cls": "class"}).round(6).to_csv(
            OUT / f"shap_values_{key}.csv", index=False)
    imp = []
    for key, sv in shap_out.items():
        for k, c in enumerate(classes):
            for j, f in enumerate(fnames):
                imp.append({"records": key, "class": c, "feature": f, "mean_abs_shap": float(np.abs(sv[:, j, k]).mean())})
        for j, f in enumerate(fnames):
            imp.append({"records": key, "class": "all classes", "feature": f,
                        "mean_abs_shap": float(np.abs(sv[:, j, :]).sum(axis=1).mean())})
    si = pd.DataFrame(imp)
    si["rank"] = si.groupby(["records", "class"]).mean_abs_shap.rank(ascending=False, method="min").astype(int)
    si.round(6).to_csv(OUT / "shap_importance.csv", index=False)
    a = si[(si.records == "development") & (si["class"] == "all classes")].set_index("feature").mean_abs_shap
    b = si[(si.records == "test") & (si["class"] == "all classes")].set_index("feature").mean_abs_shap
    rho = float(spearmanr(a, b[a.index]).statistic)

    # (3) engineering expectation (D20), reported as found
    eng = []
    for c, exp_gases in EXPECTED.items():
        top = si[(si.records == "development") & (si["class"] == c)].sort_values("mean_abs_shap", ascending=False).head(3)
        hit = [f for f in top.feature if gases_of(f) & exp_gases]
        eng.append({"class": c, "expected_gases": "/".join(sorted(exp_gases)), "top3_features": "; ".join(top.feature),
                    "matching_features": "; ".join(hit), "consistent": bool(hit)})
    ec = pd.DataFrame(eng)
    ec.to_csv(OUT / "engineering_check.csv", index=False)
    # direction of effect: does a high or a low feature value push towards the class? (development records)
    X18d = pipe.named_steps["features"].transform(dev[GASES])
    drows = []
    for k, c in enumerate(classes):
        sv = shap_out["development"][:, :, k]
        for j in np.argsort(np.abs(sv).mean(axis=0))[::-1][:3]:
            ok = ~np.isnan(X18d[:, j])
            r = float(spearmanr(X18d[ok, j], sv[ok, j]).statistic)
            drows.append({"class": c, "feature": fnames[j], "mean_abs_shap": float(np.abs(sv[:, j]).mean()),
                          "spearman_value_vs_shap": round(r, 3),
                          "direction": "high values push towards the class" if r > 0.3 else
                          ("low values push towards the class" if r < -0.3 else "mixed / non-monotonic")})
    pd.DataFrame(drows).round(6).to_csv(OUT / "shap_direction.csv", index=False)

    # Figures
    ps.apply()
    import matplotlib.pyplot as plt
    pin = pi[pi.evaluation_set == "Internal test"]
    fig, axes = plt.subplots(1, 2, figsize=(ps.FULL_WIDTH, 9 * ps.CM), gridspec_kw={"width_ratios": [1, 1.6]})
    for ax, level, title in zip(axes, ("gas", "feature"), ("(a) Gas level (one gas shuffled)", "(b) Feature level (one feature shuffled)")):
        p = pin[pin.level == level].sort_values("importance_mean")
        lab = p.feature if level == "gas" else p.feature.map(pretty)
        ax.barh(lab, p.importance_mean, color=ps.METHOD.loc["ML", "colour_hex"], height=0.6)
        ax.errorbar(p.importance_mean, lab, xerr=[p.importance_mean - p.ci_low, p.ci_high - p.importance_mean],
                    fmt="none", ecolor=ps.INK["text"], elinewidth=0.8, capsize=2)
        ax.axvline(0, color=ps.INK["muted"], lw=0.8)
        ax.set_xlabel("Drop in macro-F1 [-]")
        ax.set_title(title, loc="left")
    fig.tight_layout()
    ps.save(fig, "F4_14_permutation_importance", pin.round(5))

    sv, X18 = shap_out["development"], pipe.named_steps["features"].transform(dev[GASES])
    ranks = np.apply_along_axis(lambda v: pd.Series(v).rank(pct=True).to_numpy(), 0, X18)
    TOP = 8
    fig, axes = plt.subplots(4, 2, figsize=(ps.FULL_WIDTH, 22 * ps.CM))
    jit = np.random.default_rng(SEED)
    fig_rows = []
    for ax, (k, c) in zip(axes.flat, enumerate(classes)):
        order = np.argsort(np.abs(sv[:, :, k]).mean(axis=0))[::-1][:TOP]
        for pos, j in enumerate(order[::-1]):
            y = pos + jit.uniform(-0.3, 0.3, len(dev))
            ax.scatter(sv[:, j, k], y, c=ranks[:, j], cmap=ps.SEQUENTIAL, vmin=0, vmax=1, s=3, linewidths=0)
            fig_rows.append({"class": c, "feature": fnames[j], "position_from_top": TOP - pos,
                             "mean_abs_shap": float(np.abs(sv[:, j, k]).mean())})
        ax.set_yticks(range(TOP))
        ax.set_yticklabels([pretty(fnames[j]) for j in order[::-1]], fontsize=7)
        ax.axvline(0, color=ps.INK["muted"], lw=0.8)
        ax.set_title(ps.CLASS.loc[c, "label"], loc="left")
        ax.set_xlabel("SHAP value [change in class probability]", fontsize=7)
    cax = axes.flat[-1]
    cax.axis("off")
    sm = plt.cm.ScalarMappable(cmap=ps.SEQUENTIAL, norm=plt.Normalize(0, 1))
    cb = fig.colorbar(sm, ax=cax, orientation="horizontal", fraction=0.5, aspect=12)
    cb.set_label("Feature value (rank within the 439 records) [low to high]")
    cb.set_ticks([0, 1], labels=["low", "high"])
    fig.tight_layout()
    ps.save(fig, "F4_15_shap_summary", pd.DataFrame(fig_rows).round(6))

    # report
    gas = pi[pi.level == "gas"].pivot(index="feature", columns="evaluation_set", values="importance_mean")
    allc = si[si["class"] == "all classes"].pivot(index="feature", columns="records", values="mean_abs_shap")
    rep = ["# Step 23 report - explaining the fitted model", "",
           f"Fitted pipeline verified (SHA-256 {info['pipeline_sha256'][:16]}...). R = {R} shuffles, seed {SEED}.", "",
           "## Permutation importance - gas level (mean drop in macro-F1)", "", md_table(gas.round(4).reset_index()), "",
           "## SHAP - mean absolute value summed over classes", "",
           md_table(allc.sort_values("development", ascending=False).round(4).reset_index()), "",
           f"Rank agreement development vs test (Spearman): {rho:.3f}. Additivity error (max |base + sum SHAP - probability|): "
           f"development {add_err['development']:.2e}, test {add_err['test']:.2e}.", "",
           "## Engineering expectation (D20), reported as found", "", md_table(ec), ""]
    (INTERIM / "step23_report.md").write_text("\n".join(rep), encoding="utf-8")
    (OUT / "step23_summary.json").write_text(json.dumps({"spearman_dev_test": rho, "additivity_error": add_err,
                                                         "R": R, "seed": SEED, "shap": shap.__version__}, indent=1))
    print("\n".join(rep))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
