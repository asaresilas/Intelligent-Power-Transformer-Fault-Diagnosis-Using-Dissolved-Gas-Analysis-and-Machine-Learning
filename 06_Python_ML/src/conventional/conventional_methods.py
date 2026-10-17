"""Independent Python implementation of the three conventional DGA methods (roadmap Step 18).

Written from the specification - the frozen 02_Standards tables and decisions D11, D12 and D13 in
00_Project_Admin/decisions_log.md - not translated from the MATLAB code, so that agreement between the two
languages is a real cross-check. No limit is typed here; every limit is read from 02_Standards.

Rules implemented
  Ratios (Analysis Plan Eq. 3): R1 = CH4/H2, R2 = C2H2/C2H4, R5 = C2H4/C2H6; a zero denominator gives an
      undefined ratio (NaN); a zero numerator gives 0.
  IEC 60599 (Table 2 rows only) and Rogers (IEEE C57.104-2008 Table 6): a class matches when every ratio it USES
      is defined and inside its interval (D12 rule 1). bound_type: lt  x < upper; gt / gt_but_ns  x > lower
      (gt_but_ns = IEC T1 'CH4/H2 >1 but NS', used as > by D13); gt_lt  lower < x < upper;
      range_endpoints_not_stated  lower <= x <= upper (D11 rule 3); ns  not used.
      No match -> 'ND'; several matches -> labels joined with '/' in table order (e.g. 'D1/D2', D11 rule 4).
      Rogers case -> class: 0 Normal, 1 PD, 2 D2, 3 T1, 4 T2, 5 T3 (D11 rule 5).
  Duval Triangle 1: percentages 100*gas/(CH4+C2H4+C2H2) (NaN if the sum is 0); rules tried in rule_order, first
      match wins; minimum inclusive, maximum exclusive; no match or NaN -> 'ND'.
  Normality gate (D11 rules 1, 2, 6): Normal if all five gases <= the chosen end (high / low) of the IEC Table A.2
      range; C2H2 uses the 'Communicating OLTC' row only for equipment code U, else 'No OLTC'.
  Boundary distance: ratio methods Eq. 9 - min over defined ratios j and finite limits L of the USED rows of
      |log10 R_j - log10 L| (a ratio of 0 contributes Inf; NaN if no ratio is defined). Duval Eq. 10 with D12 -
      shortest Euclidean distance (triangle of side 100) from the sample point to any point of a DIFFERENT zone.
      Computed here as the distance to the nearest polygon of another zone (polygons built by half-plane
      clipping), which is a different geometric method from the MATLAB edge-splitting method.
"""
from __future__ import annotations

import math
from pathlib import Path

import numpy as np
import pandas as pd

STD = Path(__file__).resolve().parents[3] / "02_Standards"
RATIO_ID = {"CH4/H2": "R1", "C2H2/C2H4": "R2", "C2H4/C2H6": "R5"}
ROGERS_CLASS = {0: "Normal", 1: "PD", 2: "D2", 3: "T1", 4: "T2", 5: "T3"}
GASES = ["H2", "CH4", "C2H6", "C2H4", "C2H2"]


# ------------------------------------------------------------------ tables
def _ratio_key(text: str) -> str:
    return RATIO_ID[text.split("(")[0].strip()]


def load_iec() -> pd.DataFrame:
    t = pd.read_csv(STD / "iec_ratio_table.csv")
    t = t[t.source_table.str.strip() == "Table 2"].copy()
    t["cls"] = t.fault_code
    t["rid"] = t.ratio.map(_ratio_key)
    return t[["cls", "rid", "bound_type", "lower", "upper"]].reset_index(drop=True)


def load_rogers() -> pd.DataFrame:
    t = pd.read_csv(STD / "rogers_ratio_table.csv")
    t["cls"] = t["case"].astype(int).map(ROGERS_CLASS)
    t["rid"] = t.ratio.map(_ratio_key)
    return t[["cls", "rid", "bound_type", "lower", "upper"]].reset_index(drop=True)


def load_duval() -> pd.DataFrame:
    return pd.read_csv(STD / "duval_triangle_zones.csv").sort_values("rule_order").reset_index(drop=True)


def load_typical() -> pd.DataFrame:
    return pd.read_csv(STD / "iec_typical_values.csv")


# ------------------------------------------------------------------ ratios and percentages
def _div(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    with np.errstate(divide="ignore", invalid="ignore"):
        q = a / b
    q[b == 0] = np.nan
    return q


def ratios(g: pd.DataFrame) -> pd.DataFrame:
    a = {k: g[k].to_numpy(float) for k in GASES}
    s = a["CH4"] + a["C2H4"] + a["C2H2"]
    return pd.DataFrame({
        "R1": _div(a["CH4"], a["H2"]), "R2": _div(a["C2H2"], a["C2H4"]), "R5": _div(a["C2H4"], a["C2H6"]),
        "pct_CH4": 100 * _div(a["CH4"], s), "pct_C2H4": 100 * _div(a["C2H4"], s), "pct_C2H2": 100 * _div(a["C2H2"], s),
    })


# ------------------------------------------------------------------ ratio methods
def _inside(x: np.ndarray, bt: str, lo: float, hi: float) -> np.ndarray:
    if bt == "lt":
        t = x < hi
    elif bt in ("gt", "gt_but_ns"):
        t = x > lo
    elif bt == "gt_lt":
        t = (x > lo) & (x < hi)
    elif bt == "range_endpoints_not_stated":
        t = (x >= lo) & (x <= hi)
    else:
        raise ValueError(f"not a decision interval: {bt}")
    return t & ~np.isnan(x)


def ratio_method(r: pd.DataFrame, table: pd.DataFrame) -> list[str]:
    classes = list(dict.fromkeys(table.cls))
    match = {}
    for c in classes:
        rows = table[(table.cls == c) & (table.bound_type != "ns")]
        ok = np.ones(len(r), bool)
        for row in rows.itertuples():
            ok &= _inside(r[row.rid].to_numpy(float), row.bound_type, row.lower, row.upper)
        match[c] = ok
    out = []
    for i in range(len(r)):
        hits = [c for c in classes if match[c][i]]
        out.append("/".join(hits) if hits else "ND")
    return out


def ratio_distance(r: pd.DataFrame, table: pd.DataFrame) -> np.ndarray:
    used = table[table.bound_type != "ns"]
    best = np.full(len(r), np.nan)
    for rid in ["R1", "R2", "R5"]:
        sub = used[used.rid == rid]
        lim = pd.concat([sub.lower, sub.upper]).dropna().unique()
        if len(lim) == 0:
            continue
        x = r[rid].to_numpy(float)
        with np.errstate(divide="ignore", invalid="ignore"):
            d = np.min(np.abs(np.log10(x)[:, None] - np.log10(lim)[None, :]), axis=1)
        d[np.isnan(x)] = np.nan
        best = np.fmin(best, d)
    return best


# ------------------------------------------------------------------ Duval Triangle 1
def duval_zone(r: pd.DataFrame, rules: pd.DataFrame) -> list[str]:
    pc = {"CH4": r.pct_CH4.to_numpy(), "C2H4": r.pct_C2H4.to_numpy(), "C2H2": r.pct_C2H2.to_numpy()}
    zone = np.array(["ND"] * len(r), dtype=object)
    done = np.isnan(pc["CH4"]) | np.isnan(pc["C2H4"]) | np.isnan(pc["C2H2"])
    for rule in rules.itertuples():
        hit = ~done
        for g in ["CH4", "C2H4", "C2H2"]:
            lo, hi = getattr(rule, f"pct_{g}_min"), getattr(rule, f"pct_{g}_max")
            if not pd.isna(lo):
                hit &= pc[g] >= lo
            if not pd.isna(hi):
                hit &= pc[g] < hi
        zone[hit] = rule.zone
        done |= hit
    return list(zone)


def _xy(c2h4: float, c2h2: float) -> tuple[float, float]:
    """Point of the triangle with side 100: C2H2 corner (0,0), C2H4 corner (100,0), CH4 corner (50, 86.6)."""
    ch4 = 100.0 - c2h4 - c2h2
    return c2h4 + ch4 / 2.0, ch4 * math.sqrt(3.0) / 2.0


def _clip(poly: list[tuple[float, float]], a: float, b: float, c: float) -> list[tuple[float, float]]:
    """Keep the part of a convex polygon (in (%C2H4, %C2H2) coordinates) where a*u + b*v <= c."""
    out = []
    n = len(poly)
    for i in range(n):
        p, q = poly[i], poly[(i + 1) % n]
        fp, fq = a * p[0] + b * p[1] - c, a * q[0] + b * q[1] - c
        if fp <= 0:
            out.append(p)
        if fp * fq < 0:
            t = fp / (fp - fq)
            out.append((p[0] + t * (q[0] - p[0]), p[1] + t * (q[1] - p[1])))
    return out


def rule_polygons(rules: pd.DataFrame) -> list[tuple[str, list[tuple[float, float]]]]:
    """Each rule as a convex polygon in (x, y) of the side-100 triangle. Coordinates u = %C2H4, v = %C2H2,
    %CH4 = 100 - u - v; every limit is a half-plane."""
    polys = []
    for rule in rules.itertuples():
        poly = [(0.0, 0.0), (100.0, 0.0), (0.0, 100.0)]          # the whole triangle in (u, v)
        cons = []
        if not pd.isna(rule.pct_C2H4_min): cons.append((-1, 0, -rule.pct_C2H4_min))
        if not pd.isna(rule.pct_C2H4_max): cons.append((1, 0, rule.pct_C2H4_max))
        if not pd.isna(rule.pct_C2H2_min): cons.append((0, -1, -rule.pct_C2H2_min))
        if not pd.isna(rule.pct_C2H2_max): cons.append((0, 1, rule.pct_C2H2_max))
        if not pd.isna(rule.pct_CH4_min): cons.append((1, 1, 100 - rule.pct_CH4_min))   # CH4 >= m  <=> u+v <= 100-m
        if not pd.isna(rule.pct_CH4_max): cons.append((-1, -1, -(100 - rule.pct_CH4_max)))
        for a, b, c in cons:
            poly = _clip(poly, a, b, c)
        if len(poly) >= 3:
            polys.append((rule.zone, [_xy(u, v) for u, v in poly]))
    return polys


def _dist_point_polygon(px: float, py: float, poly: list[tuple[float, float]]) -> float:
    """Euclidean distance from a point to a convex polygon (0 if inside or on the boundary).
    Works for either winding direction (the (u, v) -> (x, y) map reverses orientation)."""
    n = len(poly)
    best = math.inf
    signs = set()
    for i in range(n):
        (x1, y1), (x2, y2) = poly[i], poly[(i + 1) % n]
        cross = (x2 - x1) * (py - y1) - (y2 - y1) * (px - x1)
        if cross > 0:
            signs.add(1)
        elif cross < 0:
            signs.add(-1)
        dx, dy = x2 - x1, y2 - y1
        t = max(0.0, min(1.0, ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy)))
        best = min(best, math.hypot(px - (x1 + t * dx), py - (y1 + t * dy)))
    return 0.0 if len(signs) <= 1 else best


def duval_distance(r: pd.DataFrame, zones: list[str], rules: pd.DataFrame) -> np.ndarray:
    polys = rule_polygons(rules)
    d = np.full(len(r), np.nan)
    for i, z in enumerate(zones):
        u, v = r.pct_C2H4.iat[i], r.pct_C2H2.iat[i]
        if np.isnan(u) or np.isnan(v):
            continue
        px, py = _xy(u, v)
        d[i] = min(_dist_point_polygon(px, py, p) for zz, p in polys if zz != z)
    return d


# ------------------------------------------------------------------ normality gate
def normality_gate(g: pd.DataFrame, equipment: pd.Series, which: str) -> np.ndarray:
    t = load_typical()
    col = "high" if which == "high" else "low"
    ok = np.ones(len(g), bool)
    for gas in ["H2", "CH4", "C2H6", "C2H4"]:
        lim = t.loc[(t.group == "All transformers") & (t.gas == gas), col].item()
        ok &= g[gas].to_numpy(float) <= lim
    lim_u = t.loc[(t.group == "Communicating OLTC") & (t.gas == "C2H2"), col].item()
    lim_n = t.loc[(t.group == "No OLTC") & (t.gas == "C2H2"), col].item()
    lim = np.where(equipment.fillna("").astype(str).str.strip().to_numpy() == "U", lim_u, lim_n)
    ok &= g["C2H2"].to_numpy(float) <= lim
    return ok


# ------------------------------------------------------------------ everything for a gas table
def diagnose(g: pd.DataFrame, equipment: pd.Series | None = None) -> pd.DataFrame:
    """One row per record and method, same columns as the MATLAB conventional_predictions.csv."""
    if equipment is None:
        equipment = pd.Series([""] * len(g))
    r = ratios(g)
    gate_hi = normality_gate(g, equipment, "high")
    gate_lo = normality_gate(g, equipment, "low")
    iec, rog, duv = load_iec(), load_rogers(), load_duval()
    zones = duval_zone(r, duv)
    parts = []
    for method, raw, dist in [("IEC60599", ratio_method(r, iec), ratio_distance(r, iec)),
                              ("Rogers", ratio_method(r, rog), ratio_distance(r, rog)),
                              ("Duval", zones, duval_distance(r, zones, duv))]:
        df = pd.DataFrame({"method": method, "gate_upper": np.where(gate_hi, "Normal", ""),
                           "gate_lower": np.where(gate_lo, "Normal", ""), "raw_result": raw})
        df["result"] = np.where(gate_hi, "Normal", df.raw_result)
        ratio_rows = method != "Duval"
        for c in ["R1", "R2", "R5"]:
            df[f"ratio_{c}"] = r[c].to_numpy() if ratio_rows else np.nan
        for c in ["pct_CH4", "pct_C2H4", "pct_C2H2"]:
            df[c] = np.nan if ratio_rows else r[c].to_numpy()
        df["boundary_distance"] = dist
        parts.append(df)
    return pd.concat(parts, ignore_index=True)
