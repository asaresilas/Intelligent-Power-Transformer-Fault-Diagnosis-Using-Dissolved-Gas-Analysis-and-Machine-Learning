# 09 - FastAPI Diagnostic Service

**Purpose.** Objective 3: serve the released machine-learning model (dga_model_v1) through one queryable interface, so the
MATLAB dashboard (Step 39) and the test bench (Steps 40-42) get exactly the offline answers.

**Status.** Built and checked in roadmap Step 38 (13 Oct 2026), design fixed in decision D36. The conventional diagnoses
(Rogers, IEC 60599, Duval) are NOT served here: the dashboard computes them in MATLAB (roadmap Version 3). This replaces the
30 Sep plan in this README (conventional answers, agreement flag in the service).

**Start (on this computer only, 127.0.0.1:8000)**
- `powershell -ExecutionPolicy Bypass -File 09_API_FastAPI\run_service.ps1` - stop with Ctrl+C.
- Check: http://127.0.0.1:8000/health ; interactive page: http://127.0.0.1:8000/docs
- No log-in and no network access from other computers: a local test bench, not a networked product.

**Endpoints**
- `POST /diagnose` - body `{"record_id": "optional", "H2": .., "CH4": .., "C2H6": .., "C2H4": .., "C2H2": ..}` in ppm (ul/l);
  not detected = 0 (D8). All five gases required, numbers only, finite, >= 0; any other field refused (HTTP 422 names the
  field). Answer: `record_id`, `fault_class`, `probabilities` (Normal, PD, D1, D2, T1, T2, T3; not rounded), `confidence`,
  `model_name`, `model_version`, `model_sha256`, `data_version`, `notes` (features filled with the training median).
- `GET /health` - alive, model loaded, verified SHA-256.
- `GET /version` - API version and the model metadata (`06_Python_ML/models/dga_model_v1_meta.json`).

**Files**
- `app/main.py` - the service; loads the model once with `model_io.load_model()` (refuses a changed file: the service does not start).
- `app/schemas.py` - request and response models (validation).
- `openapi.json` - the interface description for the dashboard (written by `export_openapi.py`; a test fails if it is out of date).
- `tests/test_api.py` - 21 pytest tests (validation, answers, identity with the offline predictions, start-up refusal, openapi.json).
- `step38_service_check.py` - runs the real server and sends the 388 held-out records; results in `checks/`.
- `example_request.py` - prints one example request and answer (saved as `checks/step38_example.json`).
- `run_service.ps1` - start script. `code_manifest_step38.sha256` - fingerprints of the Step 38 files.

**Step 38 results (project laptop: AMD Ryzen 5 3500U, 8 logical processors, 21.9 GB RAM, Windows 11)**
- pytest: 21 passed. Real server: 388/388 classes and probabilities identical to `11_Results/ml/ml_predictions.csv`,
  0 failed calls; response time median 55.3 ms, 95th percentile 62.1 ms (preliminary; 5 warm-up calls not counted).
- The formal fidelity and response time (Table 4.11, Figure 4.21) come from the MATLAB test bench (Steps 41-42).

**Run the tests**
`06_Python_ML\.venv\Scripts\python.exe -I -m pytest 09_API_FastAPI\tests -q`

**Feeds thesis.** Chapter 3 (integration architecture), Chapter 4 (framework performance, research question 4).
