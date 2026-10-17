"""Thesis tables generated from result and standards files, plus the abbreviation, symbol and SI-unit lists.

Each function returns {"caption", "rows" (first row = header), "align", "widths" (relative), "note", "font"}.
"""
import json
import re
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
TAB = ROOT / "11_Results" / "tables"
STD = ROOT / "02_Standards"

SETS = [("Internal test", "Internal test (n = 61)"), ("IEC TC 10 (power transformers)", "IEC TC 10 power transformers (n = 58)"),
        ("Li 2019", "Li 2019 (n = 86)")]
METHODS = ["ML (selected model)", "Rogers Ratio", "IEC 60599 ratio", "Duval Triangle 1"]
MNAME = {"ML (selected model)": "ML (Random Forest, F4)", "Rogers Ratio": "Rogers ratio", "IEC 60599 ratio": "IEC 60599 ratio",
         "Duval Triangle 1": "Duval Triangle 1"}
MODEL = {"majority": "Majority-class baseline", "logistic_regression": "Logistic regression", "svm": "SVM (RBF)",
         "random_forest": "Random Forest", "xgboost": "XGBoost", "mlp": "MLP neural network"}


def f3(x):
    return f"{x:.3f}"


def ci(v, lo, hi):
    return f"{v:.3f} [{lo:.3f}, {hi:.3f}]"


def fv(v):
    v = float(v)
    if v == 0:
        return "0"
    if abs(v) >= 100:
        return f"{v:.0f}"
    if abs(v) >= 10:
        return f"{v:.1f}"
    return f"{v:.2g}"


def chem(s):
    return s


# ------------------------------------------------------------------ Chapter 3
def datasets():
    rows = [["Data set (source)", "Records", "Gases", "Label origin", "Role in this study"],
            ["IEC TC 10 database, Annex 1 of Duval and dePablo (2001)", "{{n_raw_iec}}", "H2, CH4, C2H6, C2H4, C2H2 (CO, CO2)",
             "Visual inspection of the failed equipment", "Main benchmark (58 power transformers primary)"],
            ["Dissanayake (2026) DGA dataset, training file", "{{n_raw_distrain}}", "H2, CH4, C2H6, C2H4, C2H2",
             "Codes 0-6; origin not documented", "Development (training, tuning, cross-validation)"],
            ["Dissanayake (2026) DGA dataset, unseen test file", "{{n_raw_distest}}", "H2, CH4, C2H6, C2H4, C2H2",
             "Codes 0-6 (10 per class)", "Internal test"],
            ["Li (2019) DGA dataset", "{{n_raw_li}}", "H2, CH4, C2H6, C2H4, C2H2", "Text labels; origin not documented",
             "External test (sensitivity data set)"]]
    return {"caption": "Data Sets Used and Their Roles", "rows": rows, "widths": [30, 9, 20, 20, 24],
            "align": ["left", "center", "left", "left", "left"], "font": 10}


def iec_table():
    d = pd.read_csv(STD / "iec_ratio_table.csv")
    d = d[d.source_table == "Table 2"]
    rows = [["Fault code", "Fault", "C2H2/C2H4", "CH4/H2", "C2H4/C2H6"]]
    for code, g in d.groupby("fault_code", sort=False):
        val = {r.ratio: r.as_printed for r in g.itertuples()}
        rows.append([code, g.fault_name.iloc[0].replace(" C", " °C"), val["C2H2/C2H4"], val["CH4/H2"], val["C2H4/C2H6"]])
    return {"caption": "IEC 60599 Gas Ratio Limits for Fault Interpretation", "rows": rows, "widths": [10, 34, 16, 16, 16],
            "align": ["left", "left", "center", "center", "center"],
            "note": "NS = not significant whatever the value. Source: IEC 60599:1999+A1:2007, Table 2 (official preview), "
                    "the T1 entry for CH4/H2 (printed \"> 1 but NS\") is applied as CH4/H2 > 1 (see @sec:m-iec)."}


def rogers_table():
    d = pd.read_csv(STD / "rogers_ratio_table.csv")
    rows = [["Case", "Suggested diagnosis", "C2H2/C2H4 (R2)", "CH4/H2 (R1)", "C2H4/C2H6 (R5)", "Project class"]]
    cls = {0: "Normal", 1: "PD", 2: "D2", 3: "T1", 4: "T2", 5: "T3"}
    for case, g in d.groupby("case", sort=True):
        val = {r.ratio.split(" ")[0]: r.as_printed for r in g.itertuples()}
        rows.append([str(case), g.suggested_fault_diagnosis.iloc[0].replace(" C", " °C"), val["C2H2/C2H4"], val["CH4/H2"],
                     val["C2H4/C2H6"], cls[case]])
    return {"caption": "Rogers Ratio Code Table", "rows": rows, "widths": [7, 30, 15, 15, 15, 11],
            "align": ["center", "left", "center", "center", "center", "center"],
            "note": "Source: IEEE Std C57.104-2008, Table 6 (IEEE, 2009); last column: the fault class used in this study for each case."}


def duval_table():
    d = pd.read_csv(STD / "duval_triangle_zones.csv")
    rows = [["Rule", "Zone", "Condition (percentages of CH4 + C2H4 + C2H2)"]]
    for r in d.itertuples():
        rows.append([str(r.rule_order), r.zone, r.as_printed.replace(">=", "≥")])
    return {"caption": "Zone Rules of Duval Triangle 1 Used in This Study", "rows": rows, "widths": [8, 10, 60],
            "align": ["center", "center", "left"],
            "note": "Rules are tested in this order; the first rule that holds gives the zone. Sources: Moser (2025), "
                    "citing IEEE Std C57.104-2019, clause 6.2.3, and the zone labels of Manisha et al. (2022)."}


def typical_table():
    d = pd.read_csv(STD / "iec_typical_values.csv")
    rows = [["Gas", "Equipment group", "90 % typical range (ppm)", "Upper end used by the gate (ppm)"]]
    for r in d.itertuples():
        if r.gas in ("CO", "CO2"):
            continue
        rows.append([r.gas, r.group, r.as_printed, f"{r.high:g}"])
    return {"caption": "IEC 60599 Typical Gas Concentrations Used by the Normality Gate", "rows": rows,
            "widths": [10, 28, 25, 25], "align": ["left", "left", "center", "center"],
            "note": "Source: IEC 60599:1999/AMD1:2007, Table A.2. 'Communicating OLTC' applies to IEC TC 10 equipment code U; "
                    "all other records use the 'no OLTC' range."}


def feature_sets():
    rows = [["Set", "Features", "Number", "Purpose"],
            ["F1", "log10(x + 1) of each gas", "5", "Raw measured information"],
            ["F2", "Share of each gas in the five-gas total (%)", "5", "Fault fingerprint independent of the gas level"],
            ["F3", "log10 ratios R1 to R5 with +1 ppm offset, and the three Duval percentages", "8",
             "Engineering knowledge of the conventional methods"],
            ["F4", "F1 + F2 + F3", "18", "All information together"]]
    return {"caption": "Feature Sets Compared", "rows": rows, "widths": [7, 45, 10, 35], "align": ["center", "left", "center", "left"]}


def grids():
    rows = [["Model", "Fixed settings", "Settings tuned (search values)"],
            ["Majority-class baseline", "always predicts the most common class", "none"],
            ["SVM (RBF kernel)", "Platt-calibrated probabilities, 5 internal folds", "C in {0.1, 1, 10, 100}; gamma in {0.001, 0.01, 0.1, 1, scale}"],
            ["Random Forest", "500 trees", "maximum depth in {none, 5, 10}; minimum leaf size in {1, 2, 5}"],
            ["XGBoost", "multi-class soft-probability objective, histogram trees", "learning rate in {0.03, 0.1, 0.3}; depth in {2, 4, 6}; rounds in {100, 300}"],
            ["MLP neural network", "L-BFGS solver, at most 5 000 iterations", "hidden layers in {(16), (32), (32, 16)}; L2 penalty in {0.0001, 0.001, 0.01}"],
            ["Logistic regression", "multinomial, at most 5 000 iterations", "C in {0.1, 1, 10}"]]
    return {"caption": "Classifiers and Hyper-parameter Search Grids", "rows": rows, "widths": [22, 33, 45],
            "align": ["left", "left", "left"], "font": 10,
            "note": "Class weights w~c~ = N/(K n~c~) are recomputed in every training fold for all models except the baseline."}


def sim_params():
    rows = [["Quantity", "Symbol", "Value", "Source"],
            ["Rated power", "S~r~", "40 MVA", "pandapower standard type"],
            ["Rated voltages", "V~HV~ / V~LV~", "110 kV / 20 kV", "pandapower standard type"],
            ["Short-circuit voltage (resistive part)", "u~k~ (u~kr~)", "16.2 % (0.34 %)", "pandapower standard type"],
            ["No-load loss / load loss at rated current", "P~0~ / P~k~", "18 kW / 136 kW", "pandapower standard type"],
            ["Top-oil rise at rated load", "Δθ~or~", "60 K", "Alliander implementation of IEC 60076-7"],
            ["Winding-to-oil gradient; hot-spot factor", "g~r~; H", "17 K; 1.3", "Alliander implementation of IEC 60076-7"],
            ["Oil and winding time constants", "τ~o~; τ~w~", "150 min; 7 min", "Alliander implementation of IEC 60076-7"],
            ["Thermal model constants", "k~11~; k~21~; k~22~", "0.5; 2; 2", "Alliander implementation of IEC 60076-7"],
            ["Oil and winding exponents", "x; y", "0.8; 1.3", "Alliander implementation of IEC 60076-7"],
            ["Ambient temperature", "θ~a~", "20 °C", "reference ambient (chosen)"],
            ["Solver relative tolerance; maximum step", "–", "10^-4^; 60 s", "chosen to meet the 0.1 K tolerance"]]
    return {"caption": "Main Parameters of the Simulink Operating Model", "rows": rows, "widths": [36, 18, 18, 30],
            "align": ["left", "center", "center", "left"],
            "note": "All values are defined as named variables in one parameter script of the model; no number is typed into a block."}


# ------------------------------------------------------------------ Chapter 4
def records():
    d = pd.read_csv(TAB / "T4_1_records_by_role_and_class.csv")
    cols = ["Normal", "PD", "D1", "D2", "T1", "T2", "T12", "T3", "Total"]
    rows = [["Set"] + ["T1/T2" if c == "T12" else c for c in cols]]
    for r in d.itertuples():
        name = r.Set.strip()
        if r.Set.startswith("  "):
            name = " " + name
        rows.append([name] + [str(int(getattr(r, c))) for c in cols])
    return {"caption": "Records by Data Role and Fault Class after Cleaning", "rows": rows,
            "widths": [40] + [8] * 9, "align": ["left"] + ["center"] * 9, "font": 10,
            "note": "T1/T2 = merged thermal class of the IEC TC 10 tables. Removed from the development file: "
                    "{{n_removed_leak}} records that leak test cases, {{n_removed_copy}} exact copies and {{n_removed_conflict}} records with identical gases but conflicting labels."}


def gas_stats(which="development"):
    f = "T4_2_gas_by_class_development.csv" if which == "development" else "A4_2_gas_by_class_benchmark.csv"
    d = pd.read_csv(TAB / f).set_index("Gas")
    classes = [c.replace(" median", "") for c in d.columns if c.endswith(" median")]
    rows = [["Class"] + list(d.index)]
    for c in classes:
        row = [c.replace("T12", "T1/T2")]
        for g in d.index:
            row.append(f"{fv(d.loc[g, c + ' median'])} ({fv(d.loc[g, c + ' Q1'])}–{fv(d.loc[g, c + ' Q3'])})")
        rows.append(row)
    rows.append(["Kruskal–Wallis H"] + [f"{d.loc[g, 'KW H']:.1f}" for g in d.index])
    rows.append(["p"] + [f"{d.loc[g, 'p']:.1e}" for g in d.index])
    rows.append(["ε²~R~"] + [f"{d.loc[g, 'epsilon2_R']:.2f}" for g in d.index])
    n = int(d["n"].iloc[0])
    cap = ("Gas Concentrations by Fault Class, Development Set" if which == "development"
           else "Gas Concentrations by Fault Class, IEC TC 10 Benchmark")
    return {"caption": cap, "rows": rows, "widths": [16, 17, 17, 17, 17, 17], "align": ["left"] + ["center"] * 5,
            "font": 9, "note": f"Median (first quartile–third quartile) in ppm; n = {n}. ε²~R~ = rank epsilon-squared effect size."}


def conventional():
    d = pd.read_csv(TAB / "T4_3_conventional.csv")
    rows = [["Test set", "Method", "Strict accuracy [95 % CI]", "Conditional accuracy [95 % CI]", "Coverage", "ND", "DT", "D1/D2", "Normal"]]
    for r in d.itertuples():
        rows.append([r.evaluation_set.replace(" (power transformers)", " PT"), r.method_label,
                     ci(r.strict_accuracy, r.strict_accuracy_lo, r.strict_accuracy_hi),
                     ci(r.conditional_accuracy, r.conditional_accuracy_lo, r.conditional_accuracy_hi), f3(r.coverage),
                     str(r.n_nd), str(r.n_dt), str(r.n_dual), str(r.n_normal_answers)])
    return {"caption": "Conventional Methods on the Three Primary Test Sets", "rows": rows,
            "widths": [12, 13, 19, 19, 10, 6, 6, 7, 8], "align": ["left", "left"] + ["center"] * 7, "font": 9,
            "note": "Answers after the upper normality gate. ND = no diagnosis; DT = Duval mixed thermal/electrical zone (counted wrong); "
                    "D1/D2 = IEC dual answer (correct for a true D1 or D2); Normal = answers given by the gate. Wilson 95 % intervals."}


def cv_results():
    d = pd.read_csv(TAB / "T4_4_cv_results.csv")
    rk = pd.read_csv(ROOT / "11_Results" / "figures" / "F4_7_critical_difference.csv").set_index("model")
    rows = [["Model", "F1", "F2", "F3", "F4", "Average rank (F4)"]]
    for m in ["random_forest", "xgboost", "logistic_regression", "svm", "mlp", "majority"]:
        row = [MODEL[m]]
        for fs in ["F1", "F2", "F3", "F4"]:
            r = d[(d.feature_set == fs) & (d.model == m)].iloc[0]
            row.append(f"{r.macro_f1_mean:.3f} ± {r.macro_f1_sd:.3f}")
        row.append(f"{rk.loc[m, 'average_rank']:.2f}")
        rows.append(row)
    return {"caption": "Nested Cross-Validation Macro-F1 of the Classifiers (Mean ± SD over 50 Outer Folds)", "rows": rows,
            "widths": [26, 15, 15, 15, 15, 14], "align": ["left"] + ["center"] * 5, "font": 10,
            "note": "Development set, n = {{n_dev}}; 5 folds × 10 repeats. Rank 1 = best (Friedman ranks on F4; critical difference {{nemenyi_cd}})."}


def main_comparison():
    d = pd.read_csv(TAB / "T4_5_main_comparison.csv")
    rows = [["Test set", "Method", "Strict accuracy [95 % CI]", "Conditional accuracy", "Coverage", "Macro-F1 [95 % CI]"]]
    for s, lab in SETS:
        for m in METHODS:
            r = d[(d.evaluation_set == s) & (d.method_label == m)].iloc[0]
            rows.append([lab if m == METHODS[0] else "", MNAME[m], ci(r.strict_accuracy, r.strict_accuracy_lo, r.strict_accuracy_hi),
                         f3(r.conditional_accuracy), f3(r.coverage), ci(r.macro_f1, r.macro_f1_lo, r.macro_f1_hi)])
    return {"caption": "Machine Learning versus the Conventional Methods on the Same Records", "rows": rows,
            "widths": [20, 18, 21, 12, 10, 21], "align": ["left", "left", "center", "center", "center", "center"], "font": 9.5,
            "note": "Strict accuracy counts every no-diagnosis as wrong; conditional accuracy uses only the records that received a diagnosis. "
                    "Wilson intervals for accuracy, stratified bootstrap (B = 2 000) for macro-F1. IEC TC 10 results carry the home-advantage caveat (@sec:threats)."}


def mcnemar():
    d = pd.read_csv(TAB / "T4_6_mcnemar.csv")
    cq = pd.read_csv(ROOT / "08_Statistical_Analysis" / "cochran_q.csv")
    cq = cq[cq.variant == "primary"].set_index("evaluation_set")
    rows = [["Test set (Cochran's Q, p)", "Comparison", "b", "c", "Test", "p", "p (Holm)", "Odds ratio b/c [95 % CI]"]]
    for s, lab in SETS:
        g = d[d.evaluation_set == s]
        q = cq.loc[s]
        for k, r in enumerate(g.itertuples()):
            pv = "< 0.001" if r.p < 0.001 else f"{r.p:.4f}"
            ph = "< 0.001" if r.p_holm < 0.001 else f"{r.p_holm:.4f}"
            first = f"{lab}; Q = {q.Q:.1f}, p {'< 0.001' if q.p < 0.001 else '= ' + format(q.p, '.4f')}" if k == 0 else ""
            rows.append([first, r.comparison.replace("ML vs ", "ML vs "), str(int(r.b)), str(int(r.c)),
                         "exact" if "exact" in r.test else "χ² (cc)", pv, ph, f"{r.odds_ratio:.2f} [{r.or_lo:.2f}, {r.or_hi:.2f}]"])
    return {"caption": "Paired Tests of the ML Model against Each Conventional Method", "rows": rows,
            "widths": [24, 20, 5, 5, 9, 9, 9, 19], "align": ["left", "left"] + ["center"] * 6, "font": 9.5,
            "note": "b = records ML diagnosed correctly and the method did not; c = the reverse (strict scoring, ND wrong). "
                    "cc = continuity-corrected McNemar; exact = binomial test used when b + c < 25. Holm adjustment within each test set (m = 3)."}


def kappa():
    d = pd.read_csv(TAB / "T4_7_kappa.csv")
    name = {"True label": "True label", **MNAME}
    pairs = list(dict.fromkeys(zip(d.a, d.b)))
    rows = [["Pair", "Internal test", "IEC TC 10 PT", "Li 2019"]]
    for a, b in pairs:
        row = [f"{name[a]} – {name[b]}"]
        for s, _ in SETS:
            row.append(f"{d[(d.evaluation_set == s) & (d.a == a) & (d.b == b)].kappa.iloc[0]:.2f}")
        rows.append(row)
    return {"caption": "Cohen's Kappa between the Methods and the True Label", "rows": rows, "widths": [46, 18, 18, 18],
            "align": ["left", "center", "center", "center"], "font": 10}


def boundary():
    d = pd.read_csv(ROOT / "08_Statistical_Analysis" / "boundary_regression.csv")
    d = d[d.analysis == "pooled (main)"]
    rows = [["Method", "Answers", "n (excluded)", "Disagreements", "β~1~", "Odds ratio per SD [95 % CI]", "p"]]
    for v, vl in (("primary", "with gate"), ("no_gate", "raw (no gate)")):
        for _, r in d[d.variant == v].iterrows():
            rows.append([r.method_label, vl, f"{r.n} ({r.n_excluded_no_distance})", str(r.n_disagree), f"{r.beta1:.3f}",
                         f"{r['or']:.2f} [{r.or_lo:.2f}, {r.or_hi:.2f}]", "< 0.001" if r.p < 0.001 else f"{r.p:.3f}"])
    return {"caption": "Logistic Regression of ML–Method Disagreement on Standardised Boundary Distance", "rows": rows,
            "widths": [17, 15, 13, 14, 9, 22, 9], "align": ["left", "left"] + ["center"] * 5, "font": 9.5,
            "note": "The 205 records of the three primary test sets pooled; records without a defined distance are excluded and counted. "
                    "A negative β~1~ means records closer to a boundary are more often disputed (criterion 3)."}


def reduced_gas():
    d = pd.read_csv(TAB / "T4_9_reduced_gas.csv")
    rows = [["Gas subset", "Gases", "Macro-F1 [95 % CI]", "Loss Δ [95 % CI]", "Within δ?", "Conventional methods usable"]]
    for r in d.itertuples():
        within = "reference" if r.n_gases == 5 else ("yes" if r.within_tolerance in (True, "True") else "no")
        rows.append([r.subset_id.replace("+", " + "), str(r.n_gases), ci(r.macro_f1, r.macro_f1_ci_low, r.macro_f1_ci_high),
                     "0 (reference)" if r.n_gases == 5 else ci(r.loss, r.loss_ci_low, r.loss_ci_high), within, r.conventional_usable])
    return {"caption": "Random Forest Macro-F1 for Every Gas Subset and Its Loss against the Full Panel", "rows": rows,
            "widths": [27, 7, 20, 20, 9, 18], "align": ["left", "center", "center", "center", "center", "left"], "font": 9,
            "note": "Development set, nested cross-validation on the same 50 folds; loss intervals by paired stratified bootstrap (B = 2 000). "
                    "δ = {{rg_delta}}. The last column follows from the gases each method needs."}


def simulink():
    d = pd.read_csv(TAB / "T4_10_simulink_verification.csv")
    keep = ["e_max (after 10 min)", "RMSE (after 10 min)", "final value, model", "largest relative difference",
            "63.2 % rise time (difference to k11 x tau_o)"]
    rows = [["Test", "Quantity", "Measure", "Value", "Limit", "Passed"]]
    for r in d[d.measure.isin(keep)].itertuples():
        unit = {"degC": "°C", "-": "", "K": "K", "min": "min"}[r.unit]
        val = f"{r.value:.4f} {unit}".strip() if r.value < 10 else f"{r.value:.2f} {unit}"
        lim = "" if pd.isna(r.limit) else (f"{r.limit:.4f}" if r.limit < 0.1 else f"{r.limit:g} {unit}".strip())
        rows.append([r.test.replace("Test 1 rated load", "Rated load").replace("Test 2 load step", "Load step"), r.quantity, r.measure.replace("k11 x tau_o", "k~11~τ~o~").replace("e_max", "e~max~"), val, lim,
                     "" if pd.isna(r.passed) else r.passed])
    return {"caption": "Verification of the Simulink Thermal Model against the IEC 60076-7 Equations", "rows": rows,
            "widths": [12, 18, 34, 14, 12, 10], "align": ["left", "left", "left", "center", "center", "center"], "font": 9.5,
            "note": "Reference: the same differential equations solved independently (ode15s, tolerance 10^-8^), driven by the load factor measured in the model. Time points after the first 10 min."}


def integration():
    d = pd.read_csv(TAB / "T4_11_integration.csv")
    rows = [["Group", "Measure", "Records", "Value", "Requirement"]]
    for r in d.itertuples():
        unit = "ms" if r.unit == "ms" else ""
        val = f"{r.value:.1f} ms" if unit else (f"{r.value:g}")
        rows.append([r.group, r.measure, str(r.records), val, "" if pd.isna(r.requirement) else str(r.requirement)])
    return {"caption": "Fidelity and Response Time of the Integrated Framework", "rows": rows,
            "widths": [19, 39, 10, 14, 18], "align": ["left", "left", "center", "center", "center"], "font": 9.5,
            "note": "All {{n_heldout}} held-out records sent through the test bench; response time = time from sending the request to receiving the answer (client side, project laptop)."}


def study2():
    d = pd.read_csv(TAB / "T4_12_study2_results.csv")
    d = d[d.variant == "primary"]
    src = {"DISTRAIN": "Dissanayake training", "DISTEST": "Dissanayake unseen", "IECTC10": "IEC TC 10 PT", "LI2019": "Li 2019"}
    mod = {"A": "A: released model", "B": "B: pooled retraining", "C": "C: hybrid", "IEC60599": "IEC 60599 ratio",
           "Rogers": "Rogers ratio", "Duval": "Duval Triangle 1"}
    rows = [["Held-out source (n)", "Model / method", "Macro-F1 [95 % CI]", "Strict accuracy", "Coverage"]]
    for ho in ["DISTRAIN", "DISTEST", "IECTC10", "LI2019"]:
        g = d[d.held_out == ho]
        for k, r in enumerate(g.itertuples()):
            rows.append([f"{src[ho]} ({r.n})" if k == 0 else "", mod[r.model], ci(r.macro_f1, r.macro_f1_lo, r.macro_f1_hi),
                         f3(r.strict_accuracy), f3(r.coverage)])
    return {"caption": "Study 2 (Exploratory): Leave-One-Source-Out Results", "rows": rows, "widths": [24, 24, 24, 14, 12],
            "align": ["left", "left", "center", "center", "center"], "font": 9.5,
            "note": "T1 and T2 merged (six classes). Model A is not evaluated on the Dissanayake training source, on which it was trained."}


def study2_reject():
    d = pd.read_csv(TAB / "T4_13_study2_contrasts.csv")
    d = d[(d.variant == "primary") & (d.kind == "reject option")]
    src = {"DISTRAIN": "Dissanayake training", "DISTEST": "Dissanayake unseen", "IECTC10": "IEC TC 10 PT", "LI2019": "Li 2019"}
    rows = [["Held-out source", "Coverage matched to", "Coverage", "Hybrid model C: selective accuracy", "Method: conditional accuracy",
             "Difference [95 % CI]"]]
    for r in d.itertuples():
        rows.append([src[r.held_out], r.method.replace("IEC60599", "IEC 60599"), f3(r.method_coverage), f3(r.selective_accuracy),
                     f3(r.method_conditional_accuracy), f"{r.diff:.3f} [{r.diff_lo:.3f}, {r.diff_hi:.3f}]"])
    return {"caption": "Study 2 (Exploratory): Reject Option at the Coverage of the Ratio Methods", "rows": rows,
            "widths": [18, 15, 11, 18, 18, 20], "align": ["left", "left", "center", "center", "center", "center"], "font": 9.5,
            "note": "The model abstains on its least confident records until its coverage equals that of the ratio method; the threshold uses the model's probabilities only."}


def cv_full():
    d = pd.read_csv(TAB / "T4_4_cv_results.csv")
    rows = [["Set", "Model", "Macro-F1", "Bal. acc.", "Acc.", "Kappa", "MCC", "Most chosen setting"]]
    for r in d.itertuples():
        rows.append([r.feature_set, MODEL[r.model], f"{r.macro_f1_mean:.3f} ± {r.macro_f1_sd:.3f}",
                     f"{r.balanced_accuracy_mean:.3f}", f"{r.accuracy_mean:.3f}", f"{r.kappa_mean:.3f}", f"{r.mcc_mean:.3f}",
                     r.most_chosen_setting.replace('"', "").replace("{", "").replace("}", "") or "–"])
    return {"caption": "Full Nested Cross-Validation Results (Means over 50 Outer Folds)", "rows": rows,
            "widths": [6, 17, 15, 9, 8, 8, 8, 32], "align": ["center", "left"] + ["center"] * 5 + ["left"], "font": 8.5,
            "note": "Bal. acc. = balanced accuracy; Acc. = accuracy."}


def per_class_cv():
    d = pd.read_csv(TAB / "T4_4_cv_results.csv")
    d = d[d.feature_set == "F4"]
    cls = ["Normal", "PD", "D1", "D2", "T1", "T2", "T3"]
    rows = [["Model (F4)"] + cls]
    for r in d.itertuples():
        rows.append([MODEL[r.model]] + [f"{getattr(r, 'f1_' + c + '_mean'):.2f}" for c in cls])
    return {"caption": "Per-Class F1-Score in Cross-Validation (Feature Set F4)", "rows": rows,
            "widths": [30] + [10] * 7, "align": ["left"] + ["center"] * 7, "font": 10}


def software():
    rows = [["Component", "Version", "Use"],
            ["Python", "3.12.10", "data preparation, machine learning, statistics, service"],
            ["scikit-learn", "1.9.1", "pipelines, classifiers, cross-validation"],
            ["XGBoost", "pinned in requirements.txt", "gradient-boosted trees"],
            ["SHAP", "0.53.0", "TreeSHAP explanations"],
            ["FastAPI / Uvicorn / Pydantic", "0.143.0 / 0.54.0 / 2.14.0", "diagnosis web service"],
            ["MATLAB", "R2025b (25.2.0.2998904)", "conventional methods, dashboard, test bench"],
            ["Simulink, Simscape, Simscape Electrical", "R2025b", "transformer operating model"],
            ["Microsoft Word", "Microsoft 365", "thesis and reports"]]
    return {"caption": "Software Used", "rows": rows, "widths": [30, 28, 42], "align": ["left", "left", "left"], "font": 10}


def api_fields():
    rows = [["Endpoint", "Input", "Output"],
            ["POST /diagnose", "JSON: H2, CH4, C2H6, C2H4, C2H2 (ppm, numbers ≥ 0); optional record_id",
             "fault_class, probabilities of the 7 classes, confidence, model name, version, SHA-256, data version, notes"],
            ["GET /health", "none", "service status and the verified model fingerprint"],
            ["GET /version", "none", "model metadata (model card summary)"]]
    return {"caption": "Interface of the Diagnosis Service", "rows": rows, "widths": [17, 40, 43], "align": ["left", "left", "left"],
            "font": 10, "note": "Invalid input (text, negative, NaN or infinite values, unknown fields) is refused with HTTP status 422 and the reason."}


def sensitivity():
    d = pd.read_csv(ROOT / "08_Statistical_Analysis" / "performance_measures.csv")
    vname = {"primary": "upper gate (main)", "lower_gate": "lower gate", "no_gate": "no gate", "dual_wrong": "dual answer wrong"}
    sname = {"Internal test": "Internal test", "IEC TC 10 (power transformers)": "IEC TC 10 PT", "Li 2019": "Li 2019"}
    rows = [["Method", "Variant"] + [sname[s] for s in sname]]
    for m in ["Rogers", "IEC60599", "Duval"]:
        for v in ["primary", "lower_gate", "no_gate", "dual_wrong"]:
            if m != "IEC60599" and v == "dual_wrong":
                continue
            row = [{"Rogers": "Rogers ratio", "IEC60599": "IEC 60599 ratio", "Duval": "Duval Triangle 1"}[m] if v == "primary" else "", vname[v]]
            for s in sname:
                r = d[(d.evaluation_set == s) & (d.variant == v) & (d.method == m)]
                row.append(f"{r.strict_accuracy.iloc[0]:.3f} / {r.macro_f1.iloc[0]:.3f}" if len(r) else "–")
            rows.append(row)
    return {"caption": "Sensitivity of the Conventional Methods to the Normality Gate and the Dual-Answer Rule", "rows": rows,
            "widths": [20, 22, 19, 19, 19], "align": ["left", "left", "center", "center", "center"], "font": 9.5,
            "note": "Each cell gives strict accuracy / macro-F1. Upper gate = Normal if every gas is at or below the upper end of its IEC 60599 typical range (main analysis); lower gate = lower end; no gate = raw answer of the method; dual answer wrong = the IEC D1/D2 answer counted as wrong."}


def all_records():
    d = pd.read_csv(ROOT / "08_Statistical_Analysis" / "performance_measures.csv")
    sets = [("Internal test - all records", "Internal test, all 70"), ("IEC TC 10 - all records", "IEC TC 10, all 117"), ("Li 2019 - all records", "Li 2019, all 201")]
    rows = [["Test set", "Method", "Strict accuracy [95 % CI]", "Coverage", "Macro-F1 [95 % CI]"]]
    for s, lab in sets:
        for k, m in enumerate(["ML", "Rogers", "IEC60599", "Duval"]):
            r = d[(d.evaluation_set == s) & (d.method == m) & (d.variant == "primary")].iloc[0]
            rows.append([lab if k == 0 else "", MNAME[r.method_label] if r.method_label in MNAME else r.method_label,
                         ci(r.strict_accuracy, r.strict_accuracy_lo, r.strict_accuracy_hi), f3(r.coverage), ci(r.macro_f1, r.macro_f1_lo, r.macro_f1_hi)])
    return {"caption": "Results on the Full Test Sets, Including Records that Copy Benchmark Cases", "rows": rows,
            "widths": [20, 22, 22, 12, 22], "align": ["left", "left", "center", "center", "center"], "font": 9.5,
            "note": "Sensitivity analysis. The IEC TC 10 set includes all equipment types; the IEC TC 10 and Li sets are scored on merged classes (T1 and T2 as T1/T2)."}


def ml_first_look():
    d = pd.read_csv(ROOT / "11_Results" / "ml" / "ml_first_look.csv")
    name = {"Internal test - independent": "Internal test (independent records)", "Internal test - all": "Internal test (all records)",
            "IEC TC 10 - power transformers": "IEC TC 10 (power transformers)", "IEC TC 10 - all": "IEC TC 10 (all equipment)",
            "Li 2019 - independent": "Li 2019 (independent records)", "Li 2019 - all (merged classes)": "Li 2019 (all, merged classes)"}
    rows = [["Test set", "n", "Classes", "Macro-F1", "Acc.", "Bal. acc.", "Kappa", "MCC"]]
    for r in d.itertuples():
        rows.append([name[r.evaluation_set] + ("" if r.primary else " *"), str(r.n), r.classes.replace("T12", "T1/T2").replace("/", ", ").replace("T1, T2", "T1/T2") if "T12" in r.classes else r.classes.replace("/", ", "),
                     f3(r.macro_f1), f3(r.accuracy), f3(r.balanced_accuracy), f3(r.kappa), f3(r.mcc)])
    return {"caption": "Performance of the Final Model on the Test Sets", "rows": rows, "widths": [26, 6, 24, 10, 8, 9, 8, 8],
            "align": ["left", "center", "left"] + ["center"] * 5, "font": 9,
            "note": "* sensitivity analysis. Acc. = accuracy; Bal. acc. = balanced accuracy. The test records were predicted once, after the model had been chosen."}


def engineering():
    d = pd.read_csv(ROOT / "11_Results" / "explain" / "engineering_check.csv")
    feat = {"log_R1": "log R1 (CH4/H2)", "log_R2": "log R2 (C2H2/C2H4)", "log_R4": "log R4 (C2H6/C2H2)", "log_R5": "log R5 (C2H4/C2H6)",
            "log_H2": "log H2", "pct_H2": "% H2", "duval_pct_C2H2": "Duval % C2H2", "pct_C2H2": "% C2H2", "log_C2H2": "log C2H2",
            "pct_C2H4": "% C2H4", "log_C2H4": "log C2H4"}
    rows = [["Fault class", "Expected key gas", "Three most important features (SHAP)", "Consistent"]]
    for r in d.itertuples():
        rows.append([r._1, r.expected_gases.replace("/", " or "), "; ".join(feat.get(f.strip(), f.strip()) for f in r.top3_features.split(";")),
                     "yes" if r.consistent else "no"])
    return {"caption": "Agreement of the Model's Explanations with the Expected Key Gases", "rows": rows, "widths": [14, 18, 54, 12],
            "align": ["center", "left", "left", "center"], "font": 10,
            "note": "Expected key gases written down before the explanations were computed (@sec:m-explain)."}


TABLES = {k: v for k, v in globals().items() if callable(v) and k in (
    "datasets", "iec_table", "rogers_table", "duval_table", "typical_table", "feature_sets", "grids", "sim_params", "records",
    "gas_stats", "conventional", "cv_results", "main_comparison", "mcnemar", "kappa", "boundary", "reduced_gas", "simulink",
    "integration", "study2", "study2_reject", "cv_full", "per_class_cv", "software", "api_fields", "sensitivity",
    "all_records", "ml_first_look", "engineering")}

# ------------------------------------------------------------------ lists
ABBREV = {
    "AI": "Artificial Intelligence", "ANN": "Artificial Neural Network", "API": "Application Programming Interface",
    "CI": "Confidence Interval", "CIGRE": "International Council on Large Electric Systems (Conseil International des Grands Réseaux Électriques)",
    "CSV": "Comma-Separated Values (file format)", "CV": "Cross-Validation", "D1": "Discharges of low energy",
    "D2": "Discharges of high energy", "DGA": "Dissolved Gas Analysis", "DT": "Mixture of thermal and electrical faults (Duval zone)",
    "ECG": "Electricity Company of Ghana", "GRIDCo": "Ghana Grid Company", "HTTP": "Hypertext Transfer Protocol",
    "IEC": "International Electrotechnical Commission", "IEEE": "Institute of Electrical and Electronics Engineers",
    "IQR": "Interquartile Range", "JSON": "JavaScript Object Notation", "k-NN": "k-Nearest Neighbours",
    "LOSO": "Leave-One-Source-Out", "MCC": "Matthews Correlation Coefficient", "ML": "Machine Learning",
    "MLP": "Multilayer Perceptron", "ND": "No Diagnosis", "OLTC": "On-Load Tap Changer", "PD": "Partial Discharge",
    "PT": "Power Transformer (IEC TC 10 equipment codes P and U)", "PURC": "Public Utilities Regulatory Commission",
    "ppm": "parts per million (µl/l)", "RBF": "Radial Basis Function", "RMSE": "Root-Mean-Square Error",
    "SD": "Standard Deviation", "SDG": "Sustainable Development Goal", "SHA-256": "Secure Hash Algorithm with a 256-bit digest",
    "SHAP": "SHapley Additive exPlanations", "SMOTE": "Synthetic Minority Over-sampling Technique",
    "SS": "Subsystem (of the Simulink model)", "SVM": "Support Vector Machine", "T1": "Thermal fault below 300 °C",
    "T2": "Thermal fault between 300 °C and 700 °C", "T3": "Thermal fault above 700 °C",
    "TC 10": "IEC Technical Committee 10 (fluids for electrotechnical applications)", "UMaT": "University of Mines and Technology",
    "XGBoost": "Extreme Gradient Boosting", "p95": "95th percentile", "ONAF": "Oil Natural Air Forced (cooling)",
    "TDCG": "Total Dissolved Combustible Gas", "PHM": "Prognostics and Health Management", "MLAPP": "MATLAB App Designer file",
    "RQ": "Research Question", "F1": "Feature set 1 (log gases); also the F1-score", "TPE": "Tree-structured Parzen Estimator",
}


def abbreviations_used(text):
    out = []
    for a, m in ABBREV.items():
        if re.search(r"(?<![A-Za-z0-9])" + re.escape(a) + r"(?![A-Za-z0-9])", text):
            out.append((a, m))
    return sorted(out, key=lambda x: x[0].lower())


SYMBOLS = [
    ("A~strict~", "strict accuracy (no-diagnosis counted wrong)", "–"),
    ("A~cond~", "conditional accuracy (records with a diagnosis only)", "–"),
    ("B", "number of bootstrap resamples", "–"),
    ("b, c", "discordant counts of the McNemar test", "–"),
    ("β~0~, β~1~", "intercept and slope of the logistic regression", "–"),
    ("CD", "critical difference of the Nemenyi test", "rank"),
    ("d~R~, d~D~", "distance to the nearest decision boundary (ratio methods; Duval)", "decades; percentage points"),
    ("δ", "largest acceptable loss of macro-F1", "–"),
    ("Δ~S~", "loss of macro-F1 with gas subset S", "–"),
    ("e~max~", "largest absolute model–reference difference", "K"),
    ("F", "fidelity of the integrated system", "–"),
    ("g~r~", "average winding-to-oil temperature gradient at rated current", "K"),
    ("H", "hot-spot factor (thermal model); Kruskal–Wallis statistic (statistics)", "–"),
    ("K", "load factor (Simulink model); number of classes (machine learning)", "pu; –"),
    ("κ", "Cohen's kappa", "–"),
    ("k~11~, k~21~, k~22~", "thermal model constants", "–"),
    ("L", "loss of life over a period", "h"),
    ("N", "number of records", "–"),
    ("P~0~, P~k~", "no-load loss; load loss at rated current", "W"),
    ("Q", "Cochran's Q statistic", "–"),
    ("R", "ratio of load loss to no-load loss", "–"),
    ("R~1~ … R~5~", "gas ratios CH4/H2, C2H2/C2H4, C2H2/CH4, C2H6/C2H2, C2H4/C2H6", "–"),
    ("τ~o~, τ~w~", "oil and winding time constants", "min"),
    ("θ~a~, θ~o~, θ~h~", "ambient, top-oil and hot-spot temperature", "°C"),
    ("Δθ~or~", "top-oil temperature rise at rated load", "K"),
    ("U", "unresolved (no-diagnosis) rate", "–"),
    ("V", "relative ageing rate of the paper insulation", "–"),
    ("w~c~", "class weight of class c", "–"),
    ("x, y", "oil and winding exponents", "–"),
    ("x~g~", "concentration of gas g", "ppm"),
    ("z", "standard normal quantile (1.96 for 95 %)", "–"),
]

SI_UNITS = [
    ("Concentration of a dissolved gas", "parts per million (microlitre per litre)", "ppm (µl/l)"),
    ("Electric current", "ampere", "A"), ("Electric voltage", "volt (kilovolt)", "V (kV)"),
    ("Apparent power", "volt-ampere (megavolt-ampere)", "VA (MVA)"), ("Power, loss", "watt (kilowatt)", "W (kW)"),
    ("Frequency", "hertz", "Hz"), ("Temperature", "degree Celsius", "°C"), ("Temperature difference", "kelvin", "K"),
    ("Time", "second, minute, hour", "s, min, h"), ("Response time", "millisecond", "ms"),
    ("Thermal resistance", "kelvin per watt", "K/W"), ("Thermal capacitance", "joule per kelvin", "J/K"),
]
