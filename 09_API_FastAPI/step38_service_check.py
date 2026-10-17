"""Roadmap Step 38 check: run the real service on the project laptop and send it every held-out record (decision D36 (7)).

    06_Python_ML\\.venv\\Scripts\\python.exe -I 09_API_FastAPI/step38_service_check.py

Starts uvicorn on 127.0.0.1:8000, waits for GET /health, sends 5 warm-up requests (not counted), then the 388 held-out
records one at a time over HTTP and compares each answer with the saved offline prediction (ml_predictions.csv, Step 22).
Only record_id, the gases and the saved predictions are read: true labels are not read and no measure is computed.
The response time (send -> answer received and decoded, client side) is PRELIMINARY: the formal fidelity and response
time (Table 4.11, Figure 4.21) come from the MATLAB test bench in Steps 41-42.

Outputs: 09_API_FastAPI/checks/step38_service_check.json, step38_response_times.csv; a line in 11_Results/ml/test_set_access.log.
"""
from __future__ import annotations

import ctypes
import datetime as dt
import json
import os
import platform
import socket
import subprocess
import sys
import time
import winreg
from pathlib import Path

import httpx
import numpy as np
import pandas as pd

API = Path(__file__).resolve().parent
ROOT = API.parent
OUT = API / "checks"
HOST, PORT = "127.0.0.1", 8000
URL = f"http://{HOST}:{PORT}"
GASES = ["H2", "CH4", "C2H6", "C2H4", "C2H2"]
CLASSES = ["Normal", "PD", "D1", "D2", "T1", "T2", "T3"]
WARMUP = {"H2": 200.0, "CH4": 300.0, "C2H6": 80.0, "C2H4": 450.0, "C2H2": 2.0}


def hardware() -> dict:
    with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"HARDWARE\DESCRIPTION\System\CentralProcessor\0") as k:
        cpu = winreg.QueryValueEx(k, "ProcessorNameString")[0].strip()

    class MEMORYSTATUSEX(ctypes.Structure):
        _fields_ = [("dwLength", ctypes.c_ulong), ("dwMemoryLoad", ctypes.c_ulong),
                    ("ullTotalPhys", ctypes.c_ulonglong), ("ullAvailPhys", ctypes.c_ulonglong),
                    ("ullTotalPageFile", ctypes.c_ulonglong), ("ullAvailPageFile", ctypes.c_ulonglong),
                    ("ullTotalVirtual", ctypes.c_ulonglong), ("ullAvailVirtual", ctypes.c_ulonglong),
                    ("sullAvailExtendedVirtual", ctypes.c_ulonglong)]
    m = MEMORYSTATUSEX()
    m.dwLength = ctypes.sizeof(MEMORYSTATUSEX)
    ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(m))
    return {"cpu": cpu, "logical_processors": os.cpu_count(), "ram_GB": round(m.ullTotalPhys / 2**30, 1),
            "os": f"{platform.system()} {platform.release()} (build {platform.version()})", "python": platform.python_version()}


def port_free() -> bool:
    with socket.socket() as s:
        return s.connect_ex((HOST, PORT)) != 0


def main() -> int:
    if not port_free():
        raise SystemExit(f"port {PORT} is already in use - stop the other service first")
    OUT.mkdir(exist_ok=True)
    saved = pd.read_csv(ROOT / "11_Results" / "ml" / "ml_predictions.csv", float_precision="round_trip",
                        usecols=["record_id", "y_pred", *[f"p_{c}" for c in CLASSES]])
    gases = pd.read_csv(ROOT / "03_Data" / "processed" / "dga_master.csv", usecols=["record_id", *GASES],
                        float_precision="round_trip").set_index("record_id").loc[saved.record_id]
    started = dt.datetime.now().isoformat(timespec="seconds")
    cmd = [sys.executable, "-I", "-m", "uvicorn", "--app-dir", str(API), "app.main:app", "--host", HOST, "--port", str(PORT),
           "--log-level", "warning"]
    server = subprocess.Popen(cmd, cwd=ROOT)
    try:
        t0 = time.perf_counter()
        with httpx.Client(base_url=URL, timeout=10.0) as c:
            while True:                                          # wait for the model to load
                try:
                    health = c.get("/health").json()
                    break
                except httpx.TransportError:
                    if time.perf_counter() - t0 > 120 or server.poll() is not None:
                        raise SystemExit("service did not start")
                    time.sleep(0.25)
            start_up_s = time.perf_counter() - t0
            version = c.get("/version").json()
            for _ in range(5):
                c.post("/diagnose", json=WARMUP).raise_for_status()
            rows = []
            for s, g in zip(saved.itertuples(index=False), gases.itertuples()):
                body = {"record_id": s.record_id, **{k: float(getattr(g, k)) for k in GASES}}
                t = time.perf_counter()
                try:
                    r = c.post("/diagnose", json=body)
                    d = r.json()
                    ms = (time.perf_counter() - t) * 1000
                    ok = r.status_code == 200
                except httpx.HTTPError as e:                     # a failed call is recorded, never skipped
                    ms, ok, d = (time.perf_counter() - t) * 1000, False, {"error": str(e)}
                rows.append({
                    "record_id": s.record_id, "http_ok": ok, "response_ms": ms,
                    "offline_class": s.y_pred, "service_class": d.get("fault_class", ""),
                    "class_match": ok and d["fault_class"] == s.y_pred,
                    "probabilities_identical": ok and [d["probabilities"][k] for k in CLASSES] == [getattr(s, f"p_{k}") for k in CLASSES],
                    "record_id_returned": ok and d["record_id"] == s.record_id,
                })
    finally:
        server.terminate()
        server.wait(timeout=30)
    df = pd.DataFrame(rows)
    df.to_csv(OUT / "step38_response_times.csv", index=False, encoding="utf-8", float_format="%.3f")
    t = df.response_ms.to_numpy()
    res = {
        "step": 38, "run_started": started, "url": URL, "hardware": hardware(),
        "packages": {p: __import__(p).__version__ for p in ("fastapi", "uvicorn", "pydantic", "httpx", "sklearn")},
        "health": health, "api_version": version["api_version"], "start_up_s": round(start_up_s, 2),
        "warm_up_calls_not_counted": 5,
        "n_records": int(len(df)), "failed_calls": int((~df.http_ok).sum()),
        "class_matches": int(df.class_match.sum()), "class_identity_fraction": float(df.class_match.mean()),
        "probabilities_identical": int(df.probabilities_identical.sum()),
        "record_id_returned": int(df.record_id_returned.sum()),
        "response_ms": {"median": round(float(np.median(t)), 2), "p95": round(float(np.percentile(t, 95)), 2),
                        "mean": round(float(t.mean()), 2), "min": round(float(t.min()), 2), "max": round(float(t.max()), 2)},
        "percentile_method": "numpy.percentile, linear interpolation",
        "status": "preliminary - formal fidelity and response time in Steps 41-42 (Table 4.11, Figure 4.21)",
        "labels_read": False,
    }
    res["pass"] = (res["failed_calls"] == 0 and res["class_matches"] == res["n_records"]
                   == res["probabilities_identical"] == res["record_id_returned"] and res["response_ms"]["p95"] < 1000)
    (OUT / "step38_service_check.json").write_text(json.dumps(res, indent=1), encoding="utf-8")
    with open(ROOT / "11_Results" / "ml" / "test_set_access.log", "a", encoding="utf-8") as fh:
        fh.write(f"{dt.datetime.now().isoformat(timespec='seconds')}  Step 38 service check: {len(df)} held-out records sent "
                 f"through the FastAPI service for an identity check against ml_predictions.csv (saved model dga_model_v1, "
                 f"unchanged); true labels not read; no measure computed\n")
    print(json.dumps(res, indent=1))
    return 0 if res["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
