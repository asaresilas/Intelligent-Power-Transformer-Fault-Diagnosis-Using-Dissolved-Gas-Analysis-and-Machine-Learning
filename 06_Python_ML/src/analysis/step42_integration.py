"""Roadmap Step 42 [Claude Code] - fidelity and response time of the integrated system (Analysis Plan Section 10, decision D40).

    python -I 06_Python_ML/src/analysis/step42_integration.py

Inputs : 10_Dashboard_Client/logs/testbench_log.csv (Step 41); 11_Results/ml/ml_predictions.csv (Step 22);
         11_Results/conventional/conventional_predictions.csv (column result: final answer after the upper gate, D11).
         True labels are not read.
Outputs: Table 4.11 (11_Results/tables/T4_11_integration.csv); Figure 4.21 (11_Results/figures/F4_21_response_times);
         11_Results/integration/integration_comparison.csv, integration_mismatches.csv, integration_checks.json.

  F = n_match / N                                   Eq. 47 (N = all held-out records sent, a failed call is a mismatch)
  response time = time between sending the request and receiving the answer (response_ms of the log)
  median and 95th percentile: numpy.percentile, linear interpolation (as in Step 38)
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402

import plotstyle as ps  # noqa: E402

ROOT = ps.PROJECT_ROOT
LOG = ROOT / "10_Dashboard_Client" / "logs" / "testbench_log.csv"
ML = ROOT / "11_Results" / "ml" / "ml_predictions.csv"
CONV = ROOT / "11_Results" / "conventional" / "conventional_predictions.csv"
OUT = ROOT / "11_Results" / "integration"
CLASSES = ["Normal", "PD", "D1", "D2", "T1", "T2", "T3"]
METHODS = [("rogers", "Rogers", "Rogers Ratio"), ("iec60599", "IEC60599", "IEC 60599 ratio"), ("duval", "Duval", "Duval Triangle 1")]
ROLES = [("benchmark", "IEC TC 10 benchmark"), ("internal_test", "internal test"), ("external_test", "external test (Li 2019)")]
MODEL_SHA = (ROOT / "06_Python_ML" / "models" / "dga_model_v1.sha256").read_text(encoding="utf-8").split()[0].strip().upper()
TARGET_MS = 1000.0
TEXT = {"keep_default_na": False, "na_values": [""]}          # answers such as ND, DT, D1/D2, Normal stay text


def load() -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    log = pd.read_csv(LOG, float_precision="round_trip", dtype={"rogers": str, "iec60599": str, "duval": str,
                      "ml_class": str, "ml_status": str, "error": str, "model_sha256": str}, **TEXT)
    ml = pd.read_csv(ML, float_precision="round_trip", usecols=["record_id", "data_role", "y_pred", *[f"p_{c}" for c in CLASSES]],
                     dtype={"y_pred": str}, **TEXT)
    conv = pd.read_csv(CONV, usecols=["record_id", "method", "result"], dtype={"result": str}, **TEXT)
    conv = conv.pivot(index="record_id", columns="method", values="result").add_prefix("offline_").reset_index()
    return log, ml, conv


def compare(log: pd.DataFrame, ml: pd.DataFrame, conv: pd.DataFrame) -> pd.DataFrame:
    """One row per held-out record of the offline file; a record missing from the log or with a failed call never matches."""
    d = ml.rename(columns={"y_pred": "offline_class", **{f"p_{c}": f"offline_p_{c}" for c in CLASSES}})
    d = d.merge(conv, on="record_id", how="left")
    lg = log.rename(columns={"data_role": "log_role"})
    d = d.merge(lg, on="record_id", how="left", indicator=True)
    d["in_log"] = d.pop("_merge").eq("both")
    d["call_ok"] = d.in_log & d.ml_status.eq("OK") & d.error.isna()
    d["class_match"] = d.call_ok & d.ml_class.eq(d.offline_class)
    d["probabilities_identical"] = d.call_ok & np.all(
        np.stack([d[f"p_{c}"].to_numpy(float) == d[f"offline_p_{c}"].to_numpy(float) for c in CLASSES]), axis=0)
    d["max_probability_difference"] = np.max(
        np.abs(np.stack([d[f"p_{c}"].to_numpy(float) - d[f"offline_p_{c}"].to_numpy(float) for c in CLASSES])), axis=0)
    for col, m, _ in METHODS:
        d[f"{col}_match"] = d.in_log & d[col].eq(d[f"offline_{m}"])
    d["role_match"] = d.in_log & d.log_role.eq(d.data_role)
    d["hash_match"] = d.in_log & d.model_sha256.str.upper().eq(MODEL_SHA)
    return d


def time_stats(x: np.ndarray) -> dict:
    x = np.asarray(x, float)
    return {"n": int(x.size), "median": float(np.median(x)), "p95": float(np.percentile(x, 95)),
            "mean": float(x.mean()), "min": float(x.min()), "max": float(x.max())}


def fidelity(match: pd.Series) -> tuple[int, int, float]:
    n = int(match.size)
    k = int(match.sum())
    return k, n, (k / n if n else float("nan"))


def table_4_11(d: pd.DataFrame, log: pd.DataFrame) -> pd.DataFrame:
    rows = []

    def add(group, measure, records, value, unit, requirement="", passed=""):
        rows.append({"group": group, "measure": measure, "records": records, "value": value, "unit": unit,
                     "requirement": requirement, "passed": passed})

    k, n, f = fidelity(d.class_match)
    add("Fidelity", "ML class identical to the offline prediction (F, Eq. 47)", f"{k}/{n}", f, "fraction", "F = 1", "yes" if f == 1 else "no")
    for role, label in ROLES:
        k, n, f = fidelity(d.class_match[d.data_role == role])
        add("Fidelity", f"ML class identical - {label}", f"{k}/{n}", f, "fraction", "F = 1", "yes" if f == 1 else "no")
    k, n, f = fidelity(d.probabilities_identical)
    add("Fidelity", "All 7 class probabilities identical", f"{k}/{n}", f, "fraction", "", "")
    for col, _, label in METHODS:
        k, n, f = fidelity(d[f"{col}_match"])
        add("Fidelity", f"{label} answer identical to the offline result", f"{k}/{n}", f, "fraction", "", "")
    add("Fidelity", "Failed service calls", f"{int((~d.call_ok).sum())}/{len(d)}", int((~d.call_ok).sum()), "count", "0",
        "yes" if d.call_ok.all() else "no")
    rt = time_stats(log.response_ms)
    rw = time_stats(log.response_ms[log.warmup == 0])
    for key, label in (("median", "median"), ("p95", "95th percentile")):
        add("Response time (service request)", f"{label} - all records", str(rt["n"]), rt[key], "ms",
            "< 1000 ms" if key == "p95" else "", ("yes" if rt[key] < TARGET_MS else "no") if key == "p95" else "")
    for key, label in (("median", "median"), ("p95", "95th percentile")):
        add("Response time (service request)", f"{label} - without the 5 warm-up calls", str(rw["n"]), rw[key], "ms", "", "")
    add("Response time (service request)", "minimum - all records", str(rt["n"]), rt["min"], "ms")
    add("Response time (service request)", "maximum - all records", str(rt["n"]), rt["max"], "ms")
    for col, label in (("conventional_ms", "Conventional diagnoses in MATLAB"), ("total_ms", "Total per record (information)")):
        s = time_stats(log[col])
        add(label, "median - all records", str(s["n"]), s["median"], "ms")
        add(label, "95th percentile - all records", str(s["n"]), s["p95"], "ms")
    t = pd.DataFrame(rows)
    t["value"] = [round(v, 6) if isinstance(v, float) else v for v in t.value]
    return t


def figure_4_21(log: pd.DataFrame) -> None:
    import matplotlib.pyplot as plt
    ps.apply()
    ml_col = ps.METHOD.loc["ML", "colour_hex"]
    x = log.response_ms.to_numpy(float)
    st = time_stats(x)
    fig, (a, b) = plt.subplots(1, 2, figsize=(ps.FULL_WIDTH, 7 * ps.CM), gridspec_kw={"width_ratios": [1.35, 1]})
    warm = log.warmup.to_numpy() == 1
    a.scatter(log.event[~warm], x[~warm], s=7, color=ml_col, lw=0, label="request")
    a.scatter(log.event[warm], x[warm], s=16, facecolor="none", edgecolor=ps.INK["text"], lw=0.8, label="warm-up (first 5)")
    a.axhline(st["median"], color=ps.INK["text"], lw=0.9, ls="--", label=f"median {st['median']:.1f} ms")
    a.axhline(st["p95"], color=ps.INK["muted"], lw=0.9, ls=":", label=f"95th percentile {st['p95']:.1f} ms")
    a.set_xlabel("Request number in the test-bench run [-]")
    a.set_ylabel("Response time [ms]")
    a.set_ylim(0, max(x.max() * 1.45, 1))                  # room for the legend above the slowest request
    a.set_xlim(0, len(x) + 1)
    a.legend(loc="upper right", frameon=False, ncol=2, fontsize=7)
    a.set_title("(a) Every request, in run order", loc="left")
    xs = np.sort(x)
    share = 100 * np.arange(1, xs.size + 1) / xs.size
    b.step(xs, share, where="post", color=ml_col, lw=1.2, label="all 388 requests")
    b.axvline(TARGET_MS, color=ps.SCALE["diverging_negative"], lw=1.0, label="target: 1000 ms")
    b.axvline(st["p95"], color=ps.INK["muted"], lw=0.9, ls=":", label="95th percentile")
    b.set_xscale("log")
    b.set_xlim(10, 2000)
    b.set_ylim(0, 102)
    b.set_xlabel("Response time [ms] (log scale)")
    b.set_ylabel("Requests answered within the time [%]")
    b.legend(loc="lower right", frameon=False, fontsize=7)
    b.set_title("(b) Cumulative distribution", loc="left")
    fig.tight_layout()
    order = np.argsort(x, kind="stable")
    cum = np.empty_like(share)
    cum[order] = share
    data = pd.DataFrame({"event": log.event, "record_id": log.record_id, "data_role": log.data_role, "warmup": log.warmup,
                         "response_ms": x, "cumulative_share_pct": cum}).round(6)
    ps.save(fig, "F4_21_response_times", data)


def main() -> int:
    log, ml, conv = load()
    d = compare(log, ml, conv)
    OUT.mkdir(parents=True, exist_ok=True)
    keep = ["record_id", "data_role", "log_role", "in_log", "call_ok", "offline_class", "ml_class", "class_match",
            "probabilities_identical", "max_probability_difference", *[f"offline_{m}" for _, m, _ in METHODS],
            *[c for c, _, _ in METHODS], *[f"{c}_match" for c, _, _ in METHODS], "hash_match", "response_ms", "warmup"]
    d[keep].to_csv(OUT / "integration_comparison.csv", index=False, encoding="utf-8")
    bad = ~(d.class_match & d.probabilities_identical & d.rogers_match & d.iec60599_match & d.duval_match & d.role_match & d.hash_match)
    d.loc[bad, keep].to_csv(OUT / "integration_mismatches.csv", index=False, encoding="utf-8")
    t = table_4_11(d, log)
    t.to_csv(ps.TAB_DIR / "T4_11_integration.csv", index=False, encoding="utf-8")
    figure_4_21(log)
    k, n, f = fidelity(d.class_match)
    rt = time_stats(log.response_ms)
    checks = {
        "step": 42, "decision": "D40", "records_offline": int(len(d)), "rows_in_log": int(len(log)),
        "log_rows_not_in_offline_file": sorted(set(log.record_id) - set(d.record_id)),
        "duplicate_log_records": int(log.record_id.duplicated().sum()),
        "fidelity_ml_class": {"matches": k, "N": n, "F": f},
        "probabilities_identical": int(d.probabilities_identical.sum()),
        "largest_probability_difference": float(np.nanmax(d.max_probability_difference)),
        "conventional_identical": {m: int(d[f"{c}_match"].sum()) for c, m, _ in METHODS},
        "role_identical": int(d.role_match.sum()), "model_hash_identical": int(d.hash_match.sum()),
        "failed_calls": int((~d.call_ok).sum()), "mismatched_records": int(bad.sum()),
        "response_ms_all": {k2: round(v, 6) for k2, v in rt.items()},
        "response_ms_without_warmup": {k2: round(v, 6) for k2, v in time_stats(log.response_ms[log.warmup == 0]).items()},
        "conventional_ms_all": {k2: round(v, 6) for k2, v in time_stats(log.conventional_ms).items()},
        "total_ms_all": {k2: round(v, 6) for k2, v in time_stats(log.total_ms).items()},
        "requirements": {"fidelity_is_1": f == 1, "p95_below_1000_ms": rt["p95"] < TARGET_MS},
        "labels_read": False,
    }
    checks["pass"] = bool(checks["requirements"]["fidelity_is_1"] and checks["requirements"]["p95_below_1000_ms"]
                          and checks["mismatched_records"] == 0 and not checks["log_rows_not_in_offline_file"]
                          and checks["duplicate_log_records"] == 0)
    (OUT / "integration_checks.json").write_text(json.dumps(checks, indent=1) + "\n", encoding="utf-8")
    print(json.dumps(checks, indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
