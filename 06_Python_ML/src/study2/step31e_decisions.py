"""Roadmap Step 31E [Claude Code] - Study 2: apply the pre-registered decision rules (protocol D28, clarification D29).

Input : 08_Statistical_Analysis/study2/contrasts.csv and reject_option.csv (Step 31D).
Rules : (1) pooling helps if B - A > 0 with 95 % CI excluding 0 on >= 2 of the 3 external sources;
        (2) the hybrid helps if C - B > 0 with CI excluding 0 on >= 2 of the 4 held-out sources;
        (3) the reject option (model C) is competitive if, at IEC 60599's coverage, its selective accuracy is at least IEC's
            conditional accuracy ("interval of the difference not below 0") on >= 2 of the 3 external sources.
        Rule 3's wording allows a strict reading (lower CI limit >= 0) and a lenient one (point difference >= 0); both are applied
        and reported, so the result cannot depend on a reading chosen after the results were seen.
Output: 08_Statistical_Analysis/study2/study2_decisions.json; 03_Data/interim/step31e_report.md.  EXPLORATORY.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "data_prep"))

import pandas as pd  # noqa: E402

from common import INTERIM, PROJECT_ROOT  # noqa: E402

D = PROJECT_ROOT / "08_Statistical_Analysis" / "study2"
EXTERNAL = ["DISTEST", "IECTC10", "LI2019"]
ALL = ["DISTRAIN"] + EXTERNAL


def decide(C: pd.DataFrame, R: pd.DataFrame, variant: str) -> dict:
    c = C[C.variant == variant]
    r = R[(R.variant == variant) & (R.model == "C") & (R.method == "IEC60599")].set_index("held_out")
    ba = c[c.contrast == "B - A"].set_index("held_out")
    cb = c[c.contrast == "C - B"].set_index("held_out")
    r1 = {s: bool(ba.loc[s, "diff_lo"] > 0) for s in EXTERNAL}
    r2 = {s: bool(cb.loc[s, "diff_lo"] > 0) for s in ALL}
    r3s = {s: bool(r.loc[s, "diff_lo"] >= 0) for s in EXTERNAL}
    r3l = {s: bool(r.loc[s, "diff"] >= 0) for s in EXTERNAL}
    out = {"rule1_pooling_helps": {"per_source": r1, "count": sum(r1.values()), "needed": 2, "met": sum(r1.values()) >= 2},
           "rule2_hybrid_helps": {"per_source": r2, "count": sum(r2.values()), "needed": 2, "met": sum(r2.values()) >= 2},
           "rule3_reject_option_competitive": {
               "strict_reading_lower_limit_ge_0": {"per_source": r3s, "count": sum(r3s.values()), "met": sum(r3s.values()) >= 2},
               "lenient_reading_point_ge_0": {"per_source": r3l, "count": sum(r3l.values()), "met": sum(r3l.values()) >= 2}}}
    out["rule3_reject_option_competitive"]["readings_agree"] = (
        out["rule3_reject_option_competitive"]["strict_reading_lower_limit_ge_0"]["met"]
        == out["rule3_reject_option_competitive"]["lenient_reading_point_ge_0"]["met"])
    hybrid_worse = {s: bool(cb.loc[s, "diff_hi"] < 0) for s in ALL}
    out["note_hybrid_significantly_worse_on"] = [s for s, v in hybrid_worse.items() if v]
    return out


def main() -> int:
    C = pd.read_csv(D / "contrasts.csv")
    R = pd.read_csv(D / "reject_option.csv")
    res = {"status": "EXPLORATORY - IEC TC 10 and Li 2019 were already seen in Steps 22-31",
           **{v: decide(C, R, v) for v in ("primary", "equal_source_weight", "iec_all")}}
    (D / "study2_decisions.json").write_text(json.dumps(res, indent=1), encoding="utf-8")
    rep = ["# Step 31E report - Study 2 decision rules", "", "```", json.dumps(res, indent=1), "```", ""]
    (INTERIM / "step31e_report.md").write_text("\n".join(rep), encoding="utf-8")
    print("\n".join(rep))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
