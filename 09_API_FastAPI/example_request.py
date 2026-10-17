"""Print one example request and the service's answer, without starting a server (in-process test client).

    06_Python_ML\\.venv\\Scripts\\python.exe -I 09_API_FastAPI/example_request.py

The gas values are an illustrative input (the example in openapi.json), not a measured record.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from fastapi.testclient import TestClient  # noqa: E402

from app.main import create_app  # noqa: E402

REQUEST = {"record_id": "example", "H2": 200.0, "CH4": 300.0, "C2H6": 80.0, "C2H4": 450.0, "C2H2": 2.0}

if __name__ == "__main__":
    with TestClient(create_app()) as c:
        answer = c.post("/diagnose", json=REQUEST).json()
        refused = c.post("/diagnose", json={**REQUEST, "H2": -5.0})
    print(json.dumps({"request": REQUEST, "answer": answer,
                      "refused_example": {"request_change": "H2 = -5", "status": refused.status_code,
                                          "detail": refused.json()["detail"]}}, indent=1))
