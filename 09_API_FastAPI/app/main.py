"""DGA diagnosis service (roadmap Step 38, decision D36).

    POST /diagnose   five gases in ppm  ->  ML class, class probabilities, model version
    GET  /health     the service is alive and the model fingerprint was verified
    GET  /version    the model metadata (06_Python_ML/models/dga_model_v1_meta.json)

Start on the project laptop (listens on this computer only):
    06_Python_ML\\.venv\\Scripts\\python.exe -I -m uvicorn --app-dir 09_API_FastAPI app.main:app --host 127.0.0.1 --port 8000

The model is the released dga_model_v1 (Step 24), loaded once with model_io.load_model(), which refuses a file whose SHA-256
differs from the recorded one; the service then does not start. Nothing is trained or changed here.
"""
from __future__ import annotations

import json
import math
import sys
from contextlib import asynccontextmanager
from pathlib import Path

import pandas as pd
from fastapi import FastAPI, Request
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from .schemas import CLASS_ORDER, GASES, Diagnosis, GasSample, Health, Probabilities

ROOT = Path(__file__).resolve().parents[2]
ML_SRC = ROOT / "06_Python_ML" / "src" / "ml"
if str(ML_SRC) not in sys.path:
    sys.path.insert(0, str(ML_SRC))

from model_io import CLASS_NAMES, MODEL_V1, load_model, recorded_sha256  # noqa: E402

API_VERSION = "1.0.0"


def sample_notes(s: GasSample) -> list[str]:
    """Remarks for features that the model fills with the training median (decision D15)."""
    notes = []
    if s.H2 + s.CH4 + s.C2H6 + s.C2H4 + s.C2H2 == 0:
        notes.append("All five gases are 0 ppm: the gas percentages are undefined and were filled with the training median.")
    elif s.CH4 + s.C2H4 + s.C2H2 == 0:
        notes.append("CH4 + C2H4 + C2H2 = 0 ppm: the Duval percentages are undefined and were filled with the training median.")
    return notes


def json_safe(x):
    """Error details echo the input; NaN and Infinity are not valid JSON, so they are returned as text."""
    if isinstance(x, float) and not math.isfinite(x):
        return str(x)
    if isinstance(x, dict):
        return {k: json_safe(v) for k, v in x.items()}
    if isinstance(x, (list, tuple)):
        return [json_safe(v) for v in x]
    return x


async def invalid_input(request: Request, exc: RequestValidationError) -> JSONResponse:
    detail = [{"loc": list(e["loc"]), "msg": e["msg"], "type": e["type"], "input": json_safe(e.get("input"))}
              for e in exc.errors()]
    return JSONResponse(status_code=422, content=jsonable_encoder({"detail": detail}))


def create_app(model_path: Path = MODEL_V1) -> FastAPI:
    model_path = Path(model_path)

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        app.state.model = load_model(model_path)          # raises ValueError if the fingerprint differs
        app.state.sha256 = recorded_sha256(model_path)
        meta = model_path.with_name(model_path.stem + "_meta.json")
        app.state.meta = json.loads(meta.read_text(encoding="utf-8"))
        app.state.classes = [CLASS_NAMES[int(c)] for c in app.state.model.named_steps["clf"].classes_]
        assert app.state.classes == CLASS_ORDER, app.state.classes
        yield

    app = FastAPI(
        title="DGA transformer fault diagnosis service",
        version=API_VERSION,
        description=("Machine-learning diagnosis of dissolved gas analysis (DGA) samples of mineral-oil power transformers "
                     "(MPhil thesis, UMaT). Model dga_model_v1: Random Forest on feature set F4, trained on 439 "
                     "development records. Decision support only; the conventional methods (Rogers, IEC 60599, Duval) "
                     "are computed by the MATLAB dashboard. Local test bench: no log-in, listens on 127.0.0.1 only."),
        lifespan=lifespan,
    )
    app.add_exception_handler(RequestValidationError, invalid_input)

    @app.get("/health", response_model=Health)
    def health(request: Request) -> Health:
        st = request.app.state
        return Health(status="ok", model_loaded=st.model is not None, model_sha256=st.sha256,
                      model_version=st.meta["version"])

    @app.get("/version")
    def version(request: Request) -> dict:
        return {"api_version": API_VERSION, **request.app.state.meta}

    @app.post("/diagnose", response_model=Diagnosis)
    def diagnose(sample: GasSample, request: Request) -> Diagnosis:
        st = request.app.state
        X = pd.DataFrame([[getattr(sample, g) for g in GASES]], columns=GASES, dtype=float)
        p = st.model.predict_proba(X)[0]
        k = int(p.argmax())                               # same rule as predict(): first class with the largest value
        return Diagnosis(
            record_id=sample.record_id,
            fault_class=st.classes[k],
            probabilities=Probabilities(**{c: float(v) for c, v in zip(st.classes, p)}),
            confidence=float(p[k]),
            model_name=st.meta["name"],
            model_version=st.meta["version"],
            model_sha256=st.sha256,
            data_version=st.meta["data_version"],
            notes=sample_notes(sample),
        )

    return app


app = create_app()
