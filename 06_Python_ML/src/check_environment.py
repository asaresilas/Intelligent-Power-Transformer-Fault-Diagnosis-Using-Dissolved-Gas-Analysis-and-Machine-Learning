"""Roadmap Step 1 check: import every library the project needs and print its version.

Run from the project root with the project environment:
    06_Python_ML/.venv/Scripts/python.exe 06_Python_ML/src/check_environment.py
Exit code 0 means every import succeeded.
"""
import importlib
import platform
import sys

# import name -> distribution name shown in the report
PACKAGES = {
    "numpy": "numpy",
    "pandas": "pandas",
    "scipy": "scipy",
    "sklearn": "scikit-learn",
    "xgboost": "xgboost",
    "statsmodels": "statsmodels",
    "shap": "shap",
    "matplotlib": "matplotlib",
    "openpyxl": "openpyxl",
    "yaml": "pyyaml",
    "joblib": "joblib",
    "fastapi": "fastapi",
    "uvicorn": "uvicorn",
    "pydantic": "pydantic",
    "httpx": "httpx",
    "pytest": "pytest",
}


def main() -> int:
    print(f"Python {platform.python_version()} ({sys.executable})")
    failed = []
    for module, dist in PACKAGES.items():
        try:
            mod = importlib.import_module(module)
            print(f"  OK    {dist:<13} {getattr(mod, '__version__', 'unknown')}")
        except Exception as exc:  # report every failure, not just the first
            failed.append(dist)
            print(f"  FAIL  {dist:<13} {exc}")
    if failed:
        print(f"FAILED: {', '.join(failed)}")
        return 1
    print(f"All {len(PACKAGES)} libraries imported successfully.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
