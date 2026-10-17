"""Write 09_API_FastAPI/openapi.json from the application (roadmap Step 38, decision D36 (6)).

    06_Python_ML\\.venv\\Scripts\\python.exe -I 09_API_FastAPI/export_openapi.py

The test test_openapi_file_is_current fails when the saved file differs from the live schema.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
OPENAPI = HERE / "openapi.json"


def schema_text() -> str:
    if str(HERE) not in sys.path:
        sys.path.insert(0, str(HERE))
    from app.main import app
    return json.dumps(app.openapi(), indent=2, ensure_ascii=False) + "\n"


if __name__ == "__main__":
    OPENAPI.write_text(schema_text(), encoding="utf-8", newline="\n")
    print(f"written {OPENAPI}")
