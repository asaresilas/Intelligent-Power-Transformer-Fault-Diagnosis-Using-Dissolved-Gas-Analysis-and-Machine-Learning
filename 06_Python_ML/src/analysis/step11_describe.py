"""Roadmap Step 11 [Claude Code] - describe the data.

Input : 03_Data/processed/dga_master.csv, 03_Data/interim/duplicate_report.csv, 03_Data/interim/step08_report inputs.
Output: 11_Results/tables/T4_1_records_by_role_and_class.csv (+ T4_1b removals),
        11_Results/tables/T4_2_gas_by_class_development.csv (+ A4_2 benchmark version),
        11_Results/figures/F4_1_records_per_class, F4_2_gas_by_class, F4_3_gas_correlation (.png/.pdf/.csv),
        03_Data/interim/step11_report.md
Methods (Analysis Plan): Kruskal-Wallis H with tie correction (Eq. 23), rank epsilon-squared (Eq. 24),
Spearman rank correlation (Eq. 25). Gas values are the D8-harmonised values (not detected = 0 ppm).
Check : every number comes from dga_master.csv; class totals in Table 4.1 equal the master table.
"""
from __future__ import annotations

import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "data_prep"))

import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402
from scipy import stats  # noqa: E402

import plotstyle as ps  # noqa: E402
from common import md_table  # noqa: E402  (06_Python_ML/src/data_prep/common.py)

ROOT = ps.PROJECT_ROOT
GASES = ["H2", "CH4", "C2H6", "C2H4", "C2H2"]
GAS_LABEL = {"H2": "H$_2$", "CH4": "CH$_4$", "C2H6": "C$_2$H$_6$", "C2H4": "C$_2$H$_4$", "C2H2": "C$_2$H$_2$"}
ORDER = ["Normal", "PD", "D1", "D2", "T1", "T2", "T12", "T3"]


def load() -> pd.DataFrame:
    m = pd.read_csv(ROOT / "03_Data" / "processed" / "dga_master.csv")
    m["cls"] = m["class_name"].fillna("T12")  # fine class where known, merged T12 otherwise
    return m


def fmt_p(p: float) -> str:
    return f"{p:.3g}" if p >= 1e-4 else f"{p:.2e}"


def table_4_1(m: pd.DataFrame) -> pd.DataFrame:
    sets = [
        ("Development", m.data_role == "development"),
        ("Internal test (all)", m.data_role == "internal_test"),
        ("  of which independent of benchmark", (m.data_role == "internal_test") & m.independent_of_benchmark),
        ("Benchmark IEC TC 10, all equipment", m.data_role == "benchmark"),
        ("  of which power transformers (primary)", (m.data_role == "benchmark") & m.in_scope_primary),
        ("External test Li 2019 (all)", m.data_role == "external_test"),
        ("  of which independent of benchmark", (m.data_role == "external_test") & m.independent_of_benchmark),
    ]
    rows = []
    for name, mask in sets:
        c = m[mask].groupby("cls").size()
        rows.append({"Set": name, **{k: int(c.get(k, 0)) for k in ORDER}, "Total": int(mask.sum())})
    return pd.DataFrame(rows)


def table_4_1b() -> pd.DataFrame:
    """Records removed in Step 9, counted as the records missing from the master table.
    (Correction 2026-10-11: the first version counted the record_id column of duplicate_report.csv, where a leakage
    row can list the matched test record instead of the removed training record - it gave 137 instead of 139 and
    wrongly listed 96 IEC TC 10 benchmark records as removed.)"""
    d = pd.read_csv(ROOT / "03_Data" / "interim" / "duplicate_report.csv")
    master_ids = set(load().record_id)
    rows = []
    for sid in ["IECTC10", "DISTRAIN", "DISTEST", "LI2019"]:  # DISIEC is not used in any role (not 'removed')
        ids = set(pd.read_csv(ROOT / "03_Data" / "interim" / f"{sid}_standardised.csv").record_id) - master_ids
        copy_ids = ids & set(d.loc[d.action == "removed (copy)", "record_id"])
        conflict_ids = ids & set(d.loc[d.action == "removed (label conflict)", "record_id"])
        leak_ids = ids - copy_ids - conflict_ids
        for reason, s in [("exact copy within file", copy_ids), ("identical gases, conflicting labels", conflict_ids),
                          ("leakage: matches a test record", leak_ids)]:
            if s:
                rows.append({"source_id": sid, "reason": reason, "records removed": len(s)})
    return pd.DataFrame(rows)


def table_4_2(df: pd.DataFrame, classes: list[str]) -> pd.DataFrame:
    rows = []
    n = len(df)
    for g in GASES:
        groups = [df.loc[df.cls == c, g].to_numpy(float) for c in classes]
        h, p = stats.kruskal(*groups)  # tie-corrected
        eps2 = h * (n + 1) / (n ** 2 - 1)
        row = {"Gas": g}
        for c, v in zip(classes, groups):
            q1, med, q3 = np.percentile(v, [25, 50, 75])
            row[f"{c} median"] = round(float(med), 2)
            row[f"{c} Q1"] = round(float(q1), 2)
            row[f"{c} Q3"] = round(float(q3), 2)
        row.update({"KW H": round(float(h), 2), "df": len(classes) - 1, "p": fmt_p(float(p)),
                    "epsilon2_R": round(float(eps2), 3), "n": n})
        rows.append(row)
    return pd.DataFrame(rows)


def figure_4_1(m: pd.DataFrame):
    import matplotlib.pyplot as plt
    panels = [("Development", m.data_role == "development", "n = {n}"),
              ("Internal test", m.data_role == "internal_test", "n = {n} ({ind} independent of benchmark)"),
              ("IEC TC 10 benchmark", m.data_role == "benchmark", "n = {n} ({pri} power transformers, primary)"),
              ("External test (Li 2019)", m.data_role == "external_test", "n = {n} ({ind} independent of benchmark)")]
    fig, axes = plt.subplots(2, 2, figsize=(ps.FULL_WIDTH, 11 * ps.CM), sharey=False)
    rows = []
    for ax, (title, mask, sub) in zip(axes.flat, panels):
        d = m[mask]
        c = d.groupby("cls").size()
        cls = [k for k in ORDER if c.get(k, 0) > 0]
        vals = [int(c[k]) for k in cls]
        cols = [ps.CLASS.loc[k, "colour_hex"] for k in cls]
        ax.bar(cls, vals, color=cols, width=0.75, edgecolor="white", linewidth=1.0)
        for x, v in zip(cls, vals):
            ax.annotate(str(v), (x, v), xytext=(0, 2), textcoords="offset points", ha="center", va="bottom",
                        fontsize=7, color=ps.INK["text"])
        info = sub.format(n=len(d), ind=int(d.independent_of_benchmark.sum()), pri=int(d.in_scope_primary.sum()))
        ax.set_title(f"{title}\n{info}", loc="left")
        ax.set_ylabel("Number of records [count]")
        ax.set_ylim(0, max(vals) * 1.18)
        ax.grid(axis="x", visible=False)
        rows += [{"panel": title, "class": k, "records": v} for k, v in zip(cls, vals)]
    fig.tight_layout()
    return fig, pd.DataFrame(rows)


def figure_4_2(dev: pd.DataFrame, kw: pd.DataFrame):
    import matplotlib.pyplot as plt
    classes = [k for k in ORDER if (dev.cls == k).any()]
    fig, axes = plt.subplots(2, 3, figsize=(ps.FULL_WIDTH, 15 * ps.CM))
    rows = []
    for idx, (ax, g) in enumerate(zip(axes.flat, GASES)):
        data = [dev.loc[dev.cls == c, g].to_numpy(float) + 1.0 for c in classes]
        bp = ax.boxplot(data, patch_artist=True, widths=0.6, whis=1.5,
                        medianprops={"color": ps.INK["text"], "linewidth": 1.0},
                        whiskerprops={"color": ps.INK["muted"]}, capprops={"color": ps.INK["muted"]},
                        flierprops={"marker": "o", "markersize": 2.5, "markerfacecolor": ps.INK["muted"],
                                    "markeredgecolor": "none", "alpha": 0.7})
        for patch, c in zip(bp["boxes"], classes):
            patch.set_facecolor(ps.CLASS.loc[c, "colour_hex"])
            patch.set_edgecolor("white")
        ax.set_yscale("log")
        ax.set_xticks(range(1, len(classes) + 1), classes, rotation=45, ha="right", rotation_mode="anchor")
        r = kw.set_index("Gas").loc[g]
        ax.set_title(f"{GAS_LABEL[g]}\nH = {r['KW H']:.1f}, p = {r['p']}, $\\varepsilon^2_R$ = {r['epsilon2_R']:.2f}",
                     loc="left", fontsize=8)
        if idx % 3 == 0:
            ax.set_ylabel("Concentration + 1 [ppm], log scale")
        ax.grid(axis="x", visible=False)
        for c, v in zip(classes, data):
            q1, med, q3 = np.percentile(v - 1.0, [25, 50, 75])
            rows.append({"gas": g, "class": c, "n": len(v), "median_ppm": med, "q1_ppm": q1, "q3_ppm": q3})
    axes.flat[-1].axis("off")
    fig.tight_layout()
    return fig, pd.DataFrame(rows)


def figure_4_3(dev: pd.DataFrame):
    import matplotlib.pyplot as plt
    rho = dev[GASES].corr(method="spearman")
    fig, ax = plt.subplots(figsize=(10 * ps.CM, 8.5 * ps.CM))
    im = ax.imshow(rho.to_numpy(), cmap=ps.DIVERGING, vmin=-1, vmax=1)
    labels = [GAS_LABEL[g] for g in GASES]
    ax.set_xticks(range(5), labels)
    ax.set_yticks(range(5), labels)
    ax.grid(False)
    for i in range(5):
        for j in range(5):
            ax.text(j, i, f"{rho.iat[i, j]:.2f}", ha="center", va="center", fontsize=8, color=ps.INK["text"])
    cb = fig.colorbar(im, ax=ax, fraction=0.046, pad=0.04)
    cb.set_label("Spearman rank correlation $\\rho_s$")
    ax.set_title(f"Development set, n = {len(dev)}", loc="left")
    fig.tight_layout()
    out = rho.reset_index().rename(columns={"index": "gas"})
    return fig, out


def main() -> int:
    ps.apply()
    ps.TAB_DIR.mkdir(parents=True, exist_ok=True)
    m = load()
    dev = m[m.data_role == "development"]
    bench = m[m.data_role == "benchmark"]

    t41 = table_4_1(m)
    t41.to_csv(ps.TAB_DIR / "T4_1_records_by_role_and_class.csv", index=False)
    t41b = table_4_1b()
    t41b.to_csv(ps.TAB_DIR / "T4_1b_records_removed.csv", index=False)
    dev_classes = [k for k in ORDER if (dev.cls == k).any()]
    t42 = table_4_2(dev, dev_classes)
    t42.to_csv(ps.TAB_DIR / "T4_2_gas_by_class_development.csv", index=False)
    a42 = table_4_2(bench, [k for k in ORDER if (bench.cls == k).any()])
    a42.to_csv(ps.TAB_DIR / "A4_2_gas_by_class_benchmark.csv", index=False)

    fig1, d1 = figure_4_1(m)
    ps.save(fig1, "F4_1_records_per_class", d1)
    fig2, d2 = figure_4_2(dev, t42)
    ps.save(fig2, "F4_2_gas_by_class", d2)
    fig3, d3 = figure_4_3(dev)
    ps.save(fig3, "F4_3_gas_correlation", d3)

    # check: Table 4.1 totals equal the master table
    ok = all(int(t41.loc[t41.Set == s, "Total"].iloc[0]) == int((m.data_role == r).sum())
             for s, r in [("Development", "development"), ("Internal test (all)", "internal_test"),
                          ("Benchmark IEC TC 10, all equipment", "benchmark"), ("External test Li 2019 (all)", "external_test")])

    L = ["# Step 11 report - describe the data", "",
         f"Run date: {date.today().isoformat()}. Script: `06_Python_ML/src/analysis/step11_describe.py`. "
         "Values: dga_master.csv with decision D8 (not detected = 0 ppm).", "",
         "## Table 4.1 - records by data role and class", "", md_table(t41), "",
         "## Table 4.1b - records removed in Step 9", "", md_table(t41b), "",
         "## Table 4.2 - gas medians [ppm] and Kruskal-Wallis test by class, development set", "",
         md_table(t42[["Gas"] + [f"{c} median" for c in dev_classes] + ["KW H", "df", "p", "epsilon2_R", "n"]]), "",
         "Quartiles (Q1, Q3) for every class are in the CSV file.", "",
         "## Figures", "",
         "- Figure 4.1 records per class (4 panels): `11_Results/figures/F4_1_records_per_class.png/.pdf/.csv`",
         "- Figure 4.2 gas concentrations by class (box plots, log scale of concentration + 1 ppm, because not-detected "
         "values are 0 ppm under D8): `F4_2_gas_by_class.*`",
         "- Figure 4.3 Spearman correlation between gases: `F4_3_gas_correlation.*`", "",
         f"Check: Table 4.1 totals equal the master table - {'PASS' if ok else 'FAIL'}."]
    (ROOT / "03_Data" / "interim" / "step11_report.md").write_text("\n".join(L) + "\n", encoding="utf-8")
    print(t41.to_string(index=False))
    print(t42[["Gas", "KW H", "p", "epsilon2_R"]].to_string(index=False))
    print(f"check={'PASS' if ok else 'FAIL'}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
