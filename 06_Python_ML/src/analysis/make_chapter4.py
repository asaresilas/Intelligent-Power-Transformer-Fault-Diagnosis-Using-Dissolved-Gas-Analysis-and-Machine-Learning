"""Roadmap Step 32 [Claude Code] - rebuild every Chapter 4 table and figure from the saved result files with one command.

    python -I make_chapter4.py            rebuild everything and write 11_Results/chapter4_manifest.sha256 and chapter4_index.csv
    python -I make_chapter4.py --check    move the current tables and figures aside, rebuild, and compare byte for byte

Nothing is retrained and no test set is predicted again: every program below reads saved predictions or fold results
(Steps 11, 20, 22-31D). Protected (never moved or rebuilt here): plot_style.csv (frozen data version 1.0), Figure 3.2 (Step 13),
the MATLAB Duval figures (Figure 4.4, Step 17), and the MATLAB/Simulink outputs Table 4.10 and Figures 4.18-4.20 and 4.22
(Steps 35-41; rebuilt by their MATLAB scripts).
"""
from __future__ import annotations

import argparse
import hashlib
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SRC = HERE.parent
ROOT = SRC.parents[1]
RES = ROOT / "11_Results"
DIRS = [RES / "tables", RES / "figures"]
PROTECTED = {"plot_style.csv"}
PROTECTED_PREFIX = ("F3_2_", "duval_",                      # Step 13 figure; MATLAB Figure 4.4 (Step 17)
                    "T4_10_", "F4_18_", "F4_19", "F4_20_", "F4_22_")  # MATLAB/Simulink outputs of Steps 35, 36, 41, 39-40

# (program, arguments) in dependency order
PIPELINE = [
    ("analysis/step11_describe.py", []),                 # Tables 4.1, 4.1b, 4.2, A4.2; Figures 4.1-4.3
    ("ml/step20_summarize.py", ["--table-only"]),          # Table 4.4
    ("ml/step23_explain.py", []),                          # Figures 4.14-4.15
    ("ml/step27_minimum_panel.py", []),                    # Table 4.9; Figures 4.16-4.17
    ("stats/step29_measures.py", []),                      # Tables 4.3, 4.5; Figures 4.5a-c, 4.8
    ("stats/step30_tests.py", []),                         # Tables 4.6-4.7; Figures 4.7, 4.11
    ("stats/step31_boundary.py", []),                      # Table 4.8; Figure 4.12
    ("study2/step31d_measures.py", []),                    # Tables 4.12-4.13; Figures 4.23-4.24 (exploratory)
    ("study2/step31e_decisions.py", []),
    ("analysis/chapter4_figures.py", []),                  # Figures 4.6, 4.9a-c, 4.10, 4.13
    ("analysis/step42_integration.py", []),                # Table 4.11; Figure 4.21 (Step 42)
]


def sha256(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest().upper()


def outputs() -> list[Path]:
    return sorted(p for d in DIRS for p in d.iterdir()
                  if p.is_file() and p.name not in PROTECTED and not p.name.startswith(PROTECTED_PREFIX))


def build() -> None:
    py = sys.executable
    for prog, args in PIPELINE:
        print(f"running {prog} {' '.join(args)}", flush=True)
        subprocess.run([py, "-I", str(SRC / prog), *args], check=True, stdout=subprocess.DEVNULL)
    files = outputs()
    (RES / "chapter4_manifest.sha256").write_text("".join(f"{sha256(p)}  {p.relative_to(ROOT).as_posix()}\n" for p in files),
                                                 encoding="ascii")
    print(f"built {len(files)} files")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    if not a.check:
        build()
        return 0
    before = {p.relative_to(ROOT).as_posix(): sha256(p) for p in outputs()}
    backup = Path(tempfile.mkdtemp(prefix="chapter4_backup_"))
    for p in outputs():                                      # move aside (reversible), never delete
        dest = backup / p.relative_to(ROOT)
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(p), str(dest))
    assert not outputs(), "outputs not cleared"
    build()
    after = {p.relative_to(ROOT).as_posix(): sha256(p) for p in outputs()}
    missing = sorted(set(before) - set(after))
    new = sorted(set(after) - set(before))
    changed = sorted(k for k in set(before) & set(after) if before[k] != after[k])
    report = [f"files before: {len(before)}; after: {len(after)}", f"missing after rebuild: {missing}", f"new: {new}",
              f"changed: {changed}", f"backup of the previous files: {backup}"]
    (RES / "chapter4_check.txt").write_text("\n".join(report) + "\n", encoding="utf-8")
    print("\n".join(report))
    return 0 if not (missing or changed) else 1


if __name__ == "__main__":
    raise SystemExit(main())
