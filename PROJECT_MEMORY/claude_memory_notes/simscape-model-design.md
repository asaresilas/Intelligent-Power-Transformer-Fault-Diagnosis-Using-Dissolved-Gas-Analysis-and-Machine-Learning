---
name: simscape-model-design
description: "Non-obvious design decisions and pitfalls of the verified Simscape transformer operating model (sources of parameters, solver/network rules)"
metadata:
  node_type: memory
  type: project
  originSessionId: 346338d5-d698-4fb5-b677-85c0c938dfe4
  modified: 2026-10-08T04:18:17.863Z
---

Model (verified 2026-10-03, matches IEC 60076-7 equations within 0.061 K): 7 subsystems SS1 grid → SS2 transformer → SS3 current/K → SS4 variable load; SS5 losses→heat (Simulink) → SS6 thermal R-C network (Simscape Foundation thermal) → SS7 outputs/ageing.

Parameter sources (no standards in hand yet): electrical = pandapower std type "40 MVA 110/20 kV"; thermal constants = Alliander transformer-thermal-model ONAF defaults (IEC 60076-7 implementation); ageing V = 2^((θh−98)/6) from IntechOpen chapter Table 1. To be replaced/checked when IEC 60076-7 arrives. Simulink never generates gas values — operating context only.

Pitfalls found by actually building it:
- Electrical network uses "Frequency and time" formulation (24 h sim in ~10 s); it requires linear equations, so nonlinear math must be Simulink blocks, not PS Math Function.
- Physical-signal lines join networks; each network needs exactly one Solver Configuration.
- Thermal masses must start above 0 K → hot-spot analogue circuits referenced to ambient, sensors in difference mode.
- Connection Port numbers are unique across left and right sides.
- Voltage Source (3-ph) impedance_option '0' = None; Simscape cannot do the 150° vector group, Delta1/Yg used.

**Why:** these took several iterations to discover; re-deriving wastes time.
**How to apply:** follow these when editing the model or guide; reference builder at `05_Simulink_Model/reference_build/build_transformer_model.m`. Related: [[matlab-environment-facts]].
