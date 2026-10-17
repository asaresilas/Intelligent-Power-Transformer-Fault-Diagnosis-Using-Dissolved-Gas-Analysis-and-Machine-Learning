"""Roadmap Step 13 [Claude Code] - freeze the data (version 1.0).

Input : every file made in Steps 5 to 12 - the raw files, 03_Data/processed/*.csv, the 02_Standards tables
        and 11_Results/figures/plot_style.csv.
Do    : record the SHA-256 of every frozen file in 03_Data/data_version_1.0.sha256 (sha256sum format);
        draw Figure 3.2 (data-preparation flow with counts). From now on these files change only through
        a new, recorded data version; later steps call common.verify_data_version() before reading them.
Output: 03_Data/data_version_1.0.sha256, 11_Results/figures/F3_2_data_preparation_flow (.png/.pdf/.csv),
        03_Data/interim/step13_report.md
Check : the manifest re-verifies with zero differences (also tests/test_data_version.py); every count in
        Figure 3.2 is computed from the files, and the counts add up.
"""
from __future__ import annotations

import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "analysis"))

import pandas as pd  # noqa: E402
from matplotlib.patches import FancyBboxPatch  # noqa: E402

import plotstyle as ps  # noqa: E402
from common import (DATA_VERSION, INTERIM, PROCESSED, PROJECT_ROOT, RAW, SOURCES, manifest_path,  # noqa: E402
                    md_table, rel, sha256_of, verify_data_version)


def frozen_files() -> list[Path]:
    files = sorted(p for p in RAW.rglob("*") if p.is_file() and p.name != "checksums.sha256")
    files += sorted(PROCESSED.glob("*.csv"))
    files += sorted((PROJECT_ROOT / "02_Standards").glob("*.csv"))
    files.append(PROJECT_ROOT / "11_Results" / "figures" / "plot_style.csv")
    return files


def write_manifest(files: list[Path]) -> pd.DataFrame:
    rows = [{"file": rel(p), "bytes": p.stat().st_size, "sha256": sha256_of(p)} for p in files]
    lines = [f"{r['sha256'].lower()}  {r['file']}" for r in rows]
    manifest_path().write_text("\n".join(lines) + "\n", encoding="utf-8")
    return pd.DataFrame(rows)


def flow_counts() -> dict:
    raw = {s["source_id"]: len(pd.read_csv(INTERIM / f"{s['source_id']}_standardised.csv")) for s in SOURCES}
    m = pd.read_csv(PROCESSED / "dga_master.csv")
    dup = pd.read_csv(INTERIM / "duplicate_report.csv")
    # removed training records = records of the training file that are not in the master table
    gone = set(pd.read_csv(INTERIM / "DISTRAIN_standardised.csv").record_id) - set(m.record_id)
    copy_ids = gone & set(dup.loc[dup.action == "removed (copy)", "record_id"])
    conflict_ids = gone & set(dup.loc[dup.action == "removed (label conflict)", "record_id"])
    role = m.data_role.value_counts()
    folds = pd.read_csv(PROCESSED / "folds.csv")
    c = {
        "raw": raw, "raw_total": sum(raw.values()),
        "rem_leak": len(gone - copy_ids - conflict_ids),
        "rem_copy": len(copy_ids),
        "rem_conflict": len(conflict_ids),
        "dev": int(role.get("development", 0)), "int": int(role.get("internal_test", 0)),
        "bench": int(role.get("benchmark", 0)), "ext": int(role.get("external_test", 0)),
        "int_ind": int(((m.data_role == "internal_test") & m.independent_of_benchmark).sum()),
        "ext_ind": int(((m.data_role == "external_test") & m.independent_of_benchmark).sum()),
        "bench_pri": int(((m.data_role == "benchmark") & m.in_scope_primary).sum()),
        "dev_complete": int(((m.data_role == "development") & m.all_five_reported).sum()),
        "master": len(m), "fold_records": len(folds),
        "repeats": sum(col.startswith("rep") for col in folds.columns),
        "folds": int(folds["rep01"].nunique()), "seed": int(folds["seed"].iloc[0]),
    }
    # the counts must add up
    assert c["dev"] == raw["DISTRAIN"] - c["rem_leak"] - c["rem_copy"] - c["rem_conflict"]
    assert c["master"] == c["dev"] + c["int"] + c["bench"] + c["ext"]
    assert c["master"] == c["raw_total"] - raw["DISIEC"] - (raw["DISTRAIN"] - c["dev"])
    assert c["fold_records"] == c["dev"]
    return c


def figure_3_2(c: dict):
    import matplotlib.pyplot as plt
    fig, ax = plt.subplots(figsize=(ps.FULL_WIDTH, 13.5 * ps.CM))
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 100)
    ax.axis("off")
    ink, muted, fill = ps.INK["text"], ps.INK["muted"], ps.SCALE["sequential_low"]

    def box(x, y, w, h, text, shade=False, bold=False):
        ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.4,rounding_size=1.2",
                                    facecolor=fill if shade else "white", edgecolor=muted, linewidth=0.8))
        ax.text(x + w / 2, y + h / 2, text, ha="center", va="center", fontsize=6.6, color=ink,
                fontweight="bold" if bold else "normal", linespacing=1.25)

    def arrow(x1, y1, x2, y2):
        ax.annotate("", xy=(x2, y2), xytext=(x1, y1),
                    arrowprops={"arrowstyle": "-|>", "color": muted, "linewidth": 0.8, "shrinkA": 0, "shrinkB": 0})

    r = c["raw"]
    src = [("IEC TC 10\n(Duval & dePablo\n2001)", r["IECTC10"]), ("Dissanayake\nDGA_train", r["DISTRAIN"]),
           ("Dissanayake\nDGA_test\n_unseen", r["DISTEST"]), ("Dissanayake\nIEC_TC_10\n_data", r["DISIEC"]),
           ("Li 2019", r["LI2019"])]
    xs = [1, 21, 41, 61, 81]
    for x, (name, n) in zip(xs, src):
        box(x, 85, 18, 13, f"{name}\nn = {n}")
        arrow(x + 9, 85, x + 9, 79.5)
    box(1, 68, 98, 11,
        f"Steps 5-8: check fingerprints; standardise {c['raw_total']} records; record missing values\n"
        f"(not detected = 0 ppm, decision D8); harmonise labels (0-6 + T12); flag scope\n"
        f"(power transformers). No record removed.", bold=False)
    arrow(50, 68, 50, 61.5)
    box(1, 49, 98, 12.5,
        f"Step 9: remove duplicates and leakage from the training file -\n"
        f"removed {c['rem_leak']} (match a test record), {c['rem_copy']} (exact copies), "
        f"{c['rem_conflict']} (identical gases, conflicting labels).\n"
        f"IEC_TC_10_data ({r['DISIEC']}) not used - replaced by the full IEC TC 10 transcription.\n"
        f"Master table: {c['master']} records")
    roles = [("Development\n(training)", c["dev"], f"complete cases {c['dev_complete']}"),
             ("Internal test", c["int"], f"independent {c['int_ind']}"),
             ("IEC TC 10 benchmark", c["bench"], f"power transformers {c['bench_pri']}"),
             ("External test\n(Li 2019)", c["ext"], f"independent {c['ext_ind']}")]
    rx = [1, 26, 51, 76]
    for x, (name, n, sub) in zip(rx, roles):
        arrow(x + 11.5, 49, x + 11.5, 41.5)
        box(x, 28, 23, 13.5, f"{name}\nn = {n}\n({sub})", shade=True, bold=False)
    arrow(12.5, 28, 12.5, 20.5)
    box(1, 5, 23, 15.5, f"Step 10:\n{c['folds']} folds x {c['repeats']} repeats\n(stratified, grouped)\nseed {c['seed']}")
    ax.text(28, 13, f"Step 13: data version {DATA_VERSION} frozen -\nSHA-256 of every file recorded\n"
                      f"(03_Data/data_version_{DATA_VERSION}.sha256)", fontsize=7, color=muted, va="center")
    data = pd.DataFrame(
        [{"stage": "raw", "item": k, "records": v} for k, v in r.items()]
        + [{"stage": "step9_removed", "item": "leakage", "records": c["rem_leak"]},
           {"stage": "step9_removed", "item": "exact copy", "records": c["rem_copy"]},
           {"stage": "step9_removed", "item": "label conflict", "records": c["rem_conflict"]},
           {"stage": "master", "item": "all", "records": c["master"]},
           {"stage": "role", "item": "development", "records": c["dev"]},
           {"stage": "role", "item": "development complete cases", "records": c["dev_complete"]},
           {"stage": "role", "item": "internal_test", "records": c["int"]},
           {"stage": "role", "item": "internal_test independent", "records": c["int_ind"]},
           {"stage": "role", "item": "benchmark", "records": c["bench"]},
           {"stage": "role", "item": "benchmark power transformers", "records": c["bench_pri"]},
           {"stage": "role", "item": "external_test", "records": c["ext"]},
           {"stage": "role", "item": "external_test independent", "records": c["ext_ind"]},
           {"stage": "folds", "item": f"{c['folds']} folds x {c['repeats']} repeats", "records": c["fold_records"]}])
    return fig, data


def main() -> int:
    ps.apply()
    files = frozen_files()
    man = write_manifest(files)
    problems = verify_data_version()
    c = flow_counts()
    fig, data = figure_3_2(c)
    out = ps.save(fig, "F3_2_data_preparation_flow", data)
    report = [
        f"# Step 13 report - data version {DATA_VERSION} frozen", "",
        f"Run date: {date.today().isoformat()}. Script: `06_Python_ML/src/data_prep/step13_freeze.py`.", "",
        f"Frozen files: {len(man)} (raw data, processed tables, standards tables, plot_style.csv). "
        f"Manifest: `{rel(manifest_path())}` (sha256sum format).", "",
        f"Re-verification of the manifest: {'PASS - 0 differences' if not problems else 'FAIL - ' + '; '.join(problems)}.", "",
        "## Frozen files", "", md_table(man), "",
        "## Figure 3.2 counts", "", md_table(data), "",
        "Figure files: " + ", ".join(rel(p) for p in out), "",
    ]
    (INTERIM / "step13_report.md").write_text("\n".join(report), encoding="utf-8")
    print(f"frozen {len(man)} files; verification problems: {len(problems)}")
    print(md_table(man[["file", "sha256"]]))
    return 0 if not problems else 1


if __name__ == "__main__":
    raise SystemExit(main())
