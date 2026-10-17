"""Request and response models of the DGA diagnosis service (roadmap Step 38, decision D36).

Gas values are concentrations dissolved in the oil in ppm (ul/l). A gas that was not detected is sent as 0 (decision D8).
Validation: all five gases required, numbers only (text and true/false are refused), finite and >= 0; any other field
is refused so that a misspelt gas name cannot be ignored without notice.
"""
from __future__ import annotations

from typing import Annotated, Optional

from pydantic import BaseModel, ConfigDict, Field

GASES = ["H2", "CH4", "C2H6", "C2H4", "C2H2"]
CLASS_ORDER = ["Normal", "PD", "D1", "D2", "T1", "T2", "T3"]

Ppm = Annotated[float, Field(strict=True, ge=0, allow_inf_nan=False, json_schema_extra={"unit": "ppm (ul/l)"})]


class GasSample(BaseModel):
    """One dissolved gas analysis: the five gases in ppm (ul/l)."""
    model_config = ConfigDict(extra="forbid", json_schema_extra={
        "examples": [{"record_id": "example", "H2": 200.0, "CH4": 300.0, "C2H6": 80.0, "C2H4": 450.0, "C2H2": 2.0}]})

    record_id: Optional[str] = Field(None, max_length=64, description="Optional label; returned unchanged.")
    H2: Ppm = Field(description="Hydrogen [ppm]")
    CH4: Ppm = Field(description="Methane [ppm]")
    C2H6: Ppm = Field(description="Ethane [ppm]")
    C2H4: Ppm = Field(description="Ethylene [ppm]")
    C2H2: Ppm = Field(description="Acetylene [ppm]")


class Probabilities(BaseModel):
    """Probability of each class (sums to 1)."""
    Normal: float
    PD: float
    D1: float
    D2: float
    T1: float
    T2: float
    T3: float


class Diagnosis(BaseModel):
    record_id: Optional[str] = Field(None, description="The record_id sent with the request, if any.")
    fault_class: str = Field(description="Most probable class: Normal, PD, D1, D2, T1, T2 or T3 (IEC 60599 codes).")
    probabilities: Probabilities
    confidence: float = Field(description="The largest class probability.")
    model_name: str
    model_version: str
    model_sha256: str
    data_version: str
    notes: list[str] = Field(description="Remarks about this sample, e.g. features filled with the training median.")


class Health(BaseModel):
    status: str
    model_loaded: bool
    model_sha256: str
    model_version: str
