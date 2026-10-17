---
name: dataset-access-status
description: "Which DGA datasets are wanted, why they are blocked (paywalls), and the free alternatives checked"
metadata:
  node_type: memory
  type: project
  originSessionId: 346338d5-d698-4fb5-b677-85c0c938dfe4
  modified: 2026-10-08T04:18:24.264Z
---

Wanted (all paywalled for the user): IEC TC 10 data in Duval & dePablo 2001, IEEE EIM 17(2):31–41, DOI 10.1109/57.917529 (faults confirmed by visual inspection — primary benchmark); IEEE DataPort "DGA dataset" (Dissanayake 2026, DOI 10.21227/27vy-h479; 584 train / 70 test / 49 IEC TC10, 5 gases, labels 0–6); IEEE DataPort Li 2019 (DOI 10.21227/h8g0-8z59). DataPort "Standard" datasets need a subscription; free only to IEEE Society members (e.g. PES), not plain student membership.

Status 2026-10-08: letter sent (per user) to Prof. Annan / HOD asking for help; messages drafted to both DataPort authors (also asking how labels were established and how the training set was balanced).

Free CC BY 4.0 alternatives checked on Mendeley Data: 10.17632/98f4z3f8tx.2 (Costa Rica, real transformers, CSV — label details unchecked); 10.17632/x22y4s9fks.1 (25 Ukrainian transformers, PDF table). 10.17632/phs5wyfbph.2 uses pseudo-labels from conventional methods → unusable for the ML-vs-conventional benchmark.

**Why:** label provenance decides which data may enter the benchmark (avoid circular validation).
**How to apply:** when data arrives, write data cards and check label origin before use. Related: [[project-overview-and-status]].
