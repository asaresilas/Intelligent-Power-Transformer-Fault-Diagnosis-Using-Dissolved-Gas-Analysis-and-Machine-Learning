"""Every number quoted in the thesis text, computed from the saved result files (never typed by hand).

The thesis sources refer to these values as {{name}}. A missing name stops the build. The table of all
facts with their source file is written to 12_Thesis/build/facts_used.csv by build_thesis.py.
"""
import json
import re
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
R = ROOT / "11_Results"
TAB = R / "tables"
STAT = ROOT / "08_Statistical_Analysis"
SIM = ROOT / "05_Simulink_Model" / "results"

FACTS = {}
SOURCES = {}


def put(name, value, source):
    FACTS[name] = value
    SOURCES[name] = source


def f2(x):
    return f"{x:.2f}"


def f3(x):
    return f"{x:.3f}"


def pc(x, d=1):
    return f"{100 * x:.{d}f} %"


def ci3(lo, hi):
    return f"[{lo:.3f}, {hi:.3f}]"


def pval(p):
    if p < 0.001:
        return "< 0.001"
    return f"{p:.3f}"


def n_int(x):
    return f"{int(round(x)):,}".replace(",", " ")


# ---------------------------------------------------------------- data (Table 4.1, Fig. 3.2)
flow = pd.read_csv(R / "figures" / "F3_2_data_preparation_flow.csv")
fv = {f"{r.stage}:{r.item}": int(r.records) for r in flow.itertuples()}
src = "11_Results/figures/F3_2_data_preparation_flow.csv"
for k, name in [("raw:IECTC10", "n_raw_iec"), ("raw:DISTRAIN", "n_raw_distrain"), ("raw:DISTEST", "n_raw_distest"),
                ("raw:DISIEC", "n_raw_disiec"), ("raw:LI2019", "n_raw_li"), ("step9_removed:leakage", "n_removed_leak"),
                ("step9_removed:exact copy", "n_removed_copy"), ("step9_removed:label conflict", "n_removed_conflict"),
                ("master:all", "n_master"), ("role:development", "n_dev"), ("role:internal_test", "n_int_all"),
                ("role:internal_test independent", "n_int"), ("role:benchmark", "n_iec_all"),
                ("role:benchmark power transformers", "n_iec"), ("role:external_test", "n_li_all"),
                ("role:external_test independent", "n_li"), ("role:development complete cases", "n_dev_complete")]:
    put(name, str(fv[k]), src)
put("n_heldout", str(fv["role:internal_test"] + fv["role:benchmark"] + fv["role:external_test"]), src)
put("n_primary_test", str(fv["role:internal_test independent"] + fv["role:benchmark power transformers"]
                          + fv["role:external_test independent"]), src)
t41 = pd.read_csv(TAB / "T4_1_records_by_role_and_class.csv")
dev = t41.iloc[0]
put("dev_class_counts", ", ".join(f"{c} {int(dev[c])}" for c in ["Normal", "PD", "D1", "D2", "T1", "T2", "T3"]),
    "11_Results/tables/T4_1_records_by_role_and_class.csv")
put("dev_min_class", f"{int(dev[['Normal','PD','D1','D2','T1','T2','T3']].min())}", "T4_1")
put("dev_max_class", f"{int(dev[['Normal','PD','D1','D2','T1','T2','T3']].max())}", "T4_1")

# ---------------------------------------------------------------- gas statistics (Table 4.2)
t42 = pd.read_csv(TAB / "T4_2_gas_by_class_development.csv").set_index("Gas")
for g in t42.index:
    put(f"kw_eps_{g}", f2(t42.loc[g, "epsilon2_R"]), "11_Results/tables/T4_2_gas_by_class_development.csv")
    put(f"kw_H_{g}", f"{t42.loc[g, 'KW H']:.1f}", "T4_2")
corr = pd.read_csv(R / "figures" / "F4_3_gas_correlation.csv")
put("corr_file_cols", ",".join(corr.columns), "F4_3")

# ---------------------------------------------------------------- conventional counts on all 827 records
cc = pd.read_csv(R / "conventional" / "conventional_counts.csv")
a = cc[cc.data_role == "all"].set_index("method")
put("iec_nd_all", str(int(a.loc["IEC60599", "ND_final"])), "11_Results/conventional/conventional_counts.csv")
put("rogers_nd_all", str(int(a.loc["Rogers", "ND_final"])), "conventional_counts.csv")
put("duval_nd_all", str(int(a.loc["Duval", "ND_final"])), "conventional_counts.csv")
put("duval_dt_all", str(int(a.loc["Duval", "DT_final"])), "conventional_counts.csv")
put("iec_dual_all", str(int(a.loc["IEC60599", "D1D2_final"])), "conventional_counts.csv")
put("gate_upper_all", str(int(a.loc["IEC60599", "n_gate_upper"])), "conventional_counts.csv")
put("gate_lower_all", str(int(a.loc["IEC60599", "n_gate_lower"])), "conventional_counts.csv")
put("iec_nd_all_pct", pc(a.loc["IEC60599", "ND_final"] / 827), "conventional_counts.csv")
put("rogers_nd_all_pct", pc(a.loc["Rogers", "ND_final"] / 827), "conventional_counts.csv")
put("iec_nd_raw_all", str(int(a.loc["IEC60599", "ND_raw"])), "conventional_counts.csv")
put("rogers_nd_raw_all", str(int(a.loc["Rogers", "ND_raw"])), "conventional_counts.csv")

# ---------------------------------------------------------------- cross-validation (Table 4.4)
cv = pd.read_csv(TAB / "T4_4_cv_results.csv")
cvi = cv.set_index(["feature_set", "model"])
for fs in ["F1", "F2", "F3", "F4"]:
    for m in ["random_forest", "xgboost", "svm", "mlp", "logistic_regression", "majority"]:
        r = cvi.loc[(fs, m)]
        put(f"cv_{fs}_{m}", f3(r.macro_f1_mean), "11_Results/tables/T4_4_cv_results.csv")
        put(f"cv_{fs}_{m}_sd", f3(r.macro_f1_sd), "T4_4")
rf = cvi.loc[("F4", "random_forest")]
put("cv_rf_bacc", f3(rf.balanced_accuracy_mean), "T4_4")
put("cv_rf_f1_D1", f2(rf.f1_D1_mean), "T4_4")
put("cv_rf_f1_T2", f2(rf.f1_T2_mean), "T4_4")
put("cv_rf_f1_T3", f2(rf.f1_T3_mean), "T4_4")
put("cv_rf_f1_Normal", f2(rf.f1_Normal_mean), "T4_4")
put("cv_rf_merged", f3(rf.macro_f1_merged_T12_mean), "T4_4")
ms = (ROOT / "07_Experiments" / "model_selection.md").read_text(encoding="utf-8")
m = re.search(r"Mean difference ([\d.]+); t = ([\d.]+); p = ([\d.]+)", ms)
put("sel_diff", m.group(1), "07_Experiments/model_selection.md")
put("sel_t", m.group(2), "model_selection.md")
put("sel_p", f"{float(m.group(3)):.3f}", "model_selection.md")
put("sel_ratio", re.search(r"ratio used in Eq\. 28: [\d.]+ / [\d.]+ = (0\.\d+)", ms).group(1), "model_selection.md")
put("n_not_worse", re.search(r"significantly worse than the best.*?: (\d+) of 20", ms).group(1), "model_selection.md")
fr = pd.read_csv(STAT / "friedman.csv")
put("friedman_chi2", f"{fr.chi2[0]:.1f}", "08_Statistical_Analysis/friedman.csv")
put("friedman_p", "< 0.001" if fr.p[0] < 0.001 else f3(fr.p[0]), "friedman.csv")
put("nemenyi_cd", f3(fr.critical_difference[0]), "friedman.csv")
put("nemenyi_q", f3(fr.q_alpha[0]), "friedman.csv")
rk = pd.read_csv(R / "figures" / "F4_7_critical_difference.csv").set_index("model")
for mdl in rk.index:
    put(f"rank_{mdl}", f2(rk.loc[mdl, "average_rank"]), "11_Results/figures/F4_7_critical_difference.csv")

# ---------------------------------------------------------------- final model first look
fl = pd.read_csv(R / "ml" / "ml_first_look.csv").set_index("evaluation_set")
put("ml_int_all_f1", f3(fl.loc["Internal test - all", "macro_f1"]), "11_Results/ml/ml_first_look.csv")
put("ml_iec_all_f1", f3(fl.loc["IEC TC 10 - all", "macro_f1"]), "ml_first_look.csv")
put("ml_li_all_f1", f3(fl.loc["Li 2019 - all (merged classes)", "macro_f1"]), "ml_first_look.csv")

# ---------------------------------------------------------------- main comparison (Table 4.5)
t45 = pd.read_csv(TAB / "T4_5_main_comparison.csv")
SETS = {"Internal test": "int", "IEC TC 10 (power transformers)": "iec", "Li 2019": "li"}
METH = {"ML (selected model)": "ml", "Rogers Ratio": "rog", "IEC 60599 ratio": "iecm", "Duval Triangle 1": "duv"}
for r in t45.itertuples():
    s, mth = SETS[r.evaluation_set], METH[r.method_label]
    k = f"{s}_{mth}"
    put(f"{k}_strict", f3(r.strict_accuracy), "11_Results/tables/T4_5_main_comparison.csv")
    put(f"{k}_strict_pct", pc(r.strict_accuracy), "T4_5")
    put(f"{k}_strict_ci", ci3(r.strict_accuracy_lo, r.strict_accuracy_hi), "T4_5")
    put(f"{k}_cond", f3(r.conditional_accuracy), "T4_5")
    put(f"{k}_cov", f3(r.coverage), "T4_5")
    put(f"{k}_cov_pct", pc(r.coverage), "T4_5")
    put(f"{k}_f1", f3(r.macro_f1), "T4_5")
    put(f"{k}_f1_ci", ci3(r.macro_f1_lo, r.macro_f1_hi), "T4_5")
    put(f"{k}_kappa", f3(r.kappa), "T4_5")
    put(f"{k}_bacc", f3(r.balanced_accuracy), "T4_5")
    put(f"{k}_mcc", f3(r.mcc), "T4_5")

pcf = pd.read_csv(R / "figures" / "F4_10_f1_per_class.csv")
PM = {"ML": "ml", "Rogers": "rog", "IEC60599": "iecm", "Duval": "duv"}
for r in pcf.itertuples():
    put(f"pcf_{SETS[r.evaluation_set]}_{PM[r.method]}_{r._3}", f2(r.f1), "11_Results/figures/F4_10_f1_per_class.csv")

# ---------------------------------------------------------------- McNemar / Cochran (Table 4.6)
t46 = pd.read_csv(TAB / "T4_6_mcnemar.csv")
CMP = {"ML vs Rogers Ratio": "rog", "ML vs IEC 60599 ratio": "iecm", "ML vs Duval Triangle 1": "duv"}
for r in t46.itertuples():
    k = f"mc_{SETS[r.evaluation_set]}_{CMP[r.comparison]}"
    put(f"{k}_b", str(int(r.b)), "11_Results/tables/T4_6_mcnemar.csv")
    put(f"{k}_c", str(int(r.c)), "T4_6")
    put(f"{k}_p", pval(r.p), "T4_6")
    put(f"{k}_pholm", pval(r.p_holm), "T4_6")
    put(f"{k}_or", f2(r.odds_ratio), "T4_6")
    put(f"{k}_orci", f"[{r.or_lo:.2f}, {r.or_hi:.2f}]", "T4_6")
cq = pd.read_csv(STAT / "cochran_q.csv")
for r in cq.itertuples():
    k = f"cq_{SETS[r.evaluation_set]}_{r.variant}"
    put(f"{k}_Q", f"{r.Q:.1f}", "08_Statistical_Analysis/cochran_q.csv")
    put(f"{k}_p", pval(r.p), "cochran_q.csv")
    for mm, col in (("ml", "correct_ML"), ("rog", "correct_Rogers"), ("iecm", "correct_IEC60599"), ("duv", "correct_Duval")):
        put(f"{k}_{mm}", str(int(getattr(r, col))), "cochran_q.csv")

# ---------------------------------------------------------------- kappa (Table 4.7)
kp = pd.read_csv(TAB / "T4_7_kappa.csv")
LAB = {"True label": "true", **METH}
for r in kp.itertuples():
    put(f"k_{SETS[r.evaluation_set]}_{LAB[r.a]}_{LAB[r.b]}", f2(r.kappa), "11_Results/tables/T4_7_kappa.csv")

# ---------------------------------------------------------------- boundary (Table 4.8)
br = pd.read_csv(STAT / "boundary_regression.csv")
BM = {"Rogers": "rog", "IEC60599": "iecm", "Duval": "duv"}
for _, r in br.iterrows():
    tag = {"pooled (main)": "pool", "pooled + test-set indicators": "poolind", "set: Internal test": "int",
           "set: IEC TC 10 (power transformers)": "iec", "set: Li 2019": "li"}[r.analysis]
    k = f"bd_{BM[r.method]}_{r.variant}_{tag}"
    put(f"{k}_or", f2(r["or"]), "08_Statistical_Analysis/boundary_regression.csv")
    put(f"{k}_b1", f3(r.beta1), "boundary_regression.csv")
    put(f"{k}_ci", f"[{r.or_lo:.2f}, {r.or_hi:.2f}]", "boundary_regression.csv")
    put(f"{k}_p", pval(r.p), "boundary_regression.csv")
    put(f"{k}_n", str(int(r.n)), "boundary_regression.csv")
    put(f"{k}_nd", str(int(r.n_disagree)), "boundary_regression.csv")

# ---------------------------------------------------------------- explainability
pi = pd.read_csv(R / "explain" / "permutation_importance.csv")
for s, tag in SETS.items():
    g = pi[(pi.evaluation_set == s) & (pi.level == "gas")].sort_values("importance_mean", ascending=False)
    put(f"pi_{tag}_order", ", ".join(g.feature), "11_Results/explain/permutation_importance.csv")
    for row in g.itertuples():
        put(f"pi_{tag}_{row.feature}", f3(row.importance_mean), "permutation_importance.csv")
        put(f"pi_{tag}_{row.feature}_ci", ci3(row.ci_low, row.ci_high), "permutation_importance.csv")
s23 = json.loads((R / "explain" / "step23_summary.json").read_text())
put("shap_spearman", f2(s23["spearman_dev_test"]), "11_Results/explain/step23_summary.json")
put("shap_additivity", f"{max(s23['additivity_error'].values()):.0e}", "step23_summary.json")
eng = pd.read_csv(R / "explain" / "engineering_check.csv")
put("eng_consistent", f"{int(eng.consistent.sum())} of {len(eng)}", "11_Results/explain/engineering_check.csv")

# ---------------------------------------------------------------- reduced gas (Table 4.9)
mp = json.loads((R / "reduced_gas" / "minimum_panel.json").read_text())
t49 = pd.read_csv(TAB / "T4_9_reduced_gas.csv").set_index("subset_id")
put("rg_full", f3(mp["full_macro_f1"]), "11_Results/reduced_gas/minimum_panel.json")
put("rg_full_ci", ci3(*mp["full_macro_f1_ci"]), "minimum_panel.json")
pan = mp["minimum_panel"]["subset"]
put("rg_min_panel", pan, "minimum_panel.json")
r = t49.loc[pan]
put("rg_min_f1", f3(r.macro_f1), "11_Results/tables/T4_9_reduced_gas.csv")
put("rg_min_loss", f3(r.loss), "T4_9")
put("rg_min_loss_ci", ci3(r.loss_ci_low, r.loss_ci_high), "T4_9")
for sid, tag in [("H2+CH4+C2H4+C2H2", "noC2H6"), ("C2H6+C2H4+C2H2", "best3"), ("H2+CH4+C2H6+C2H4", "noC2H2"),
                 ("CH4+C2H6+C2H4+C2H2", "noH2"), ("CH4+C2H4+C2H2", "duvgases"), ("C2H6+C2H4", "best2"), ("C2H4", "best1"),
                 ("H2", "h2only"), ("H2+CH4+C2H6+C2H2", "noC2H4")]:
    r = t49.loc[sid]
    put(f"rg_{tag}_f1", f3(r.macro_f1), "T4_9")
    put(f"rg_{tag}_loss", f3(r.loss), "T4_9")
    put(f"rg_{tag}_loss_ci", ci3(r.loss_ci_low, r.loss_ci_high), "T4_9")
put("rg_delta", f2(mp["delta"]), "minimum_panel.json")
put("rg_n_within", str(int((t49.within_tolerance == True).sum())), "T4_9")  # noqa: E712

# ---------------------------------------------------------------- Simulink (Table 4.10, scenarios)
t410 = pd.read_csv(TAB / "T4_10_simulink_verification.csv")


def sv(test, qty, meas):
    return float(t410[(t410.test == test) & (t410.quantity == qty) & (t410.measure == meas)].value.iloc[0])


put("sim_t1_emax_oil", f"{sv('Test 1 rated load', 'top-oil temperature', 'e_max (after 10 min)'):.4f}",
    "11_Results/tables/T4_10_simulink_verification.csv")
put("sim_t1_emax_hs", f"{sv('Test 1 rated load', 'hot-spot temperature', 'e_max (after 10 min)'):.4f}", "T4_10")
put("sim_t2_emax_oil", f"{sv('Test 2 load step', 'top-oil temperature', 'e_max (after 10 min)'):.4f}", "T4_10")
put("sim_t2_emax_hs", f"{sv('Test 2 load step', 'hot-spot temperature', 'e_max (after 10 min)'):.4f}", "T4_10")
put("sim_t1_oil", f2(sv('Test 1 rated load', 'top-oil temperature', 'final value, model')), "T4_10")
put("sim_t1_hs", f2(sv('Test 1 rated load', 'hot-spot temperature', 'final value, model')), "T4_10")
put("sim_t2_oil", f2(sv('Test 2 load step', 'top-oil temperature', 'final value, model')), "T4_10")
put("sim_t2_hs", f2(sv('Test 2 load step', 'hot-spot temperature', 'final value, model')), "T4_10")
put("sim_rise_diff", f"{sv('Test 1 rated load', 'top-oil temperature', '63.2 % rise time (difference to k11 x tau_o)'):.4f}", "T4_10")
put("sim_v_diff", pc(sv('Test 1 rated load', 'ageing rate V', 'largest relative difference'), 2), "T4_10")
sc = pd.read_csv(SIM / "step36_scenario_summary.csv").set_index("scenario")
for s in sc.index:
    put(f"sc_{s}_hs", f"{sc.loc[s, 'peak_hot_spot_C']:.1f}", "05_Simulink_Model/results/step36_scenario_summary.csv")
    put(f"sc_{s}_oil", f"{sc.loc[s, 'peak_top_oil_C']:.1f}", "step36_scenario_summary.csv")
    put(f"sc_{s}_L", f"{sc.loc[s, 'loss_of_life_h']:.2f}", "step36_scenario_summary.csv")
    put(f"sc_{s}_K", f3(sc.loc[s, 'K_measured_max_pu']), "step36_scenario_summary.csv")
put("sc_overload_tpeak", f"{sc.loc['overload', 'time_of_peak_h']:.1f}", "step36_scenario_summary.csv")

# ---------------------------------------------------------------- integration (Table 4.11)
ic = json.loads((R / "integration" / "integration_checks.json").read_text())
put("int_F", f"{ic['fidelity_ml_class']['matches']}/{ic['fidelity_ml_class']['N']}", "11_Results/integration/integration_checks.json")
put("int_med", f"{ic['response_ms_all']['median']:.1f}", "integration_checks.json")
put("int_p95", f"{ic['response_ms_all']['p95']:.1f}", "integration_checks.json")
put("int_min", f"{ic['response_ms_all']['min']:.1f}", "integration_checks.json")
put("int_max", f"{ic['response_ms_all']['max']:.1f}", "integration_checks.json")
put("int_med_nw", f"{ic['response_ms_without_warmup']['median']:.1f}", "integration_checks.json")
put("int_p95_nw", f"{ic['response_ms_without_warmup']['p95']:.1f}", "integration_checks.json")
put("int_conv_med", f"{ic['conventional_ms_all']['median']:.1f}", "integration_checks.json")
put("int_conv_p95", f"{ic['conventional_ms_all']['p95']:.1f}", "integration_checks.json")
put("int_tot_med", f"{ic['total_ms_all']['median']:.1f}", "integration_checks.json")
put("int_tot_p95", f"{ic['total_ms_all']['p95']:.1f}", "integration_checks.json")
put("int_tot_max", f"{ic['total_ms_all']['max']:.1f}", "integration_checks.json")
log = pd.read_csv(ROOT / "10_Dashboard_Client" / "logs" / "testbench_log.csv")
tcol = [c for c in log.columns if c.startswith("total")][0]
put("int_tot_over1s", str(int((log[tcol] > 1000).sum())), "10_Dashboard_Client/logs/testbench_log.csv")
ag = log.agreement_count.value_counts()
for k in range(4):
    put(f"tb_agree{k}", str(int(ag.get(k, 0))), "testbench_log.csv")
put("tb_agree3_pct", pc(ag.get(3, 0) / len(log)), "testbench_log.csv")
put("tb_agree0_pct", pc(ag.get(0, 0) / len(log)), "testbench_log.csv")
mlc = log.ml_class.value_counts()
put("tb_ml_classes", ", ".join(f"{c} {int(mlc.get(c, 0))}" for c in ["Normal", "PD", "D1", "D2", "T1", "T2", "T3"]), "testbench_log.csv")

# verdict of the redesigned dashboard on the 388 held-out records (descriptive; test_dashboard_verdict.m, 17 Oct 2026)
vd = pd.read_csv(ROOT / "10_Dashboard_Client" / "results" / "dashboard_verdict_summary.csv").set_index("item")["value"]
for key, item in [("vd_known", "with known class"), ("vd_faulty", "known faulty"), ("vd_normal", "known Normal"), ("vd_fault", "verdict = fault"),
                  ("vd_healthy", "verdict = healthy"), ("vd_watch", "verdict = watch"), ("vd_undecided", "verdict = undecided"),
                  ("vd_fault_called", "faulty records called fault"), ("vd_fault_healthy", "faulty records called healthy"),
                  ("vd_normal_healthy", "Normal records called healthy"), ("vd_fault_known", "fault verdict with known class"), ("vd_right", "fault verdict with the right class"),
                  ("vd_family", "fault verdict, family right")]:
    put(key, str(int(vd[item])), "10_Dashboard_Client/results/dashboard_verdict_summary.csv")

# ---------------------------------------------------------------- Study 2 (Tables 4.12-4.13)
s2 = pd.read_csv(TAB / "T4_12_study2_results.csv")
s2 = s2[s2.variant == "primary"].set_index(["held_out", "model"])
for (ho, mdl), r in s2.iterrows():
    put(f"s2_{ho}_{mdl}_f1", f3(r.macro_f1), "11_Results/tables/T4_12_study2_results.csv")
    put(f"s2_{ho}_{mdl}_f1_ci", ci3(r.macro_f1_lo, r.macro_f1_hi), "T4_12")
s3 = pd.read_csv(TAB / "T4_13_study2_contrasts.csv")
s3 = s3[s3.variant == "primary"]
for r in s3[s3.kind == "contrast"].itertuples():
    k = f"s2c_{r.held_out}_{r.contrast.replace(' - ', '_').replace(' ', '')}"
    put(f"{k}_d", f3(r.macro_f1_diff), "11_Results/tables/T4_13_study2_contrasts.csv")
    put(f"{k}_ci", ci3(r.diff_lo, r.diff_hi), "T4_13")
for r in s3[s3.kind == "reject option"].itertuples():
    k = f"s2r_{r.held_out}_{r.method}"
    put(f"{k}_sel", f3(r.selective_accuracy), "T4_13")
    put(f"{k}_cond", f3(r.method_conditional_accuracy), "T4_13")
    put(f"{k}_cov", f3(r.method_coverage), "T4_13")
    put(f"{k}_diff", f3(r.diff), "T4_13")
    put(f"{k}_ci", ci3(float(r.diff_lo), float(r.diff_hi)), "T4_13")


# ---------------------------------------------------------------- sensitivity variants (performance_measures.csv)
pm = pd.read_csv(STAT / "performance_measures.csv")
PSET = {"Internal test": "int", "IEC TC 10 (power transformers)": "iec", "Li 2019": "li", "Internal test - all records": "intall",
        "IEC TC 10 - all records": "iecall", "Li 2019 - all records": "liall"}
PMETH = {"ML": "ml", "Rogers": "rog", "IEC60599": "iecm", "Duval": "duv"}
for r in pm.itertuples():
    k = f"pm_{PSET[r.evaluation_set]}_{r.variant}_{PMETH[r.method]}"
    put(f"{k}_strict", f3(r.strict_accuracy), "08_Statistical_Analysis/performance_measures.csv")
    put(f"{k}_f1", f3(r.macro_f1), "performance_measures.csv")
    put(f"{k}_cov", f3(r.coverage), "performance_measures.csv")

t43 = pd.read_csv(TAB / "T4_3_conventional.csv")
for s, tag in [("Internal test", "int"), ("IEC TC 10 (power transformers)", "iec"), ("Li 2019", "li")]:
    put(f"conv_normal_{tag}", str(int(t43[t43.evaluation_set == s].n_normal_answers.iloc[0])), "11_Results/tables/T4_3_conventional.csv")

def write_sources(path):
    pd.DataFrame({"fact": list(FACTS), "value": [FACTS[k] for k in FACTS], "source": [SOURCES[k] for k in FACTS]}
                 ).to_csv(path, index=False)
