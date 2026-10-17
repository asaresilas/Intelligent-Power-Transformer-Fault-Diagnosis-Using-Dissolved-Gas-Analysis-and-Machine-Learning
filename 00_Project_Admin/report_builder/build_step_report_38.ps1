$ErrorActionPreference = "Stop"
# build_step_report_38.ps1 - Word report of roadmap Step 38 (FastAPI service). Reads the service check, the example and the test results.
$sp   = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning\00_Project_Admin\report_builder"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$work = Join-Path $env:TEMP "dga_scratch"; New-Item -ItemType Directory -Force $work | Out-Null
$outDir = Join-Path $root "00_Project_Admin\Step_Reports"
$prog = Join-Path $work "report38_progress.txt"
"begin " + (Get-Date -Format T) | Out-File $prog -Encoding utf8
$api = Join-Path $root "09_API_FastAPI"
$chk = [IO.File]::ReadAllText((Join-Path $api "checks\step38_service_check.json")) | ConvertFrom-Json
$ex  = [IO.File]::ReadAllText((Join-Path $api "checks\step38_example.json")) | ConvertFrom-Json
if (-not $chk.pass) { throw "service check did not pass" }
if ($chk.n_records -ne 388 -or $chk.class_matches -ne 388 -or $chk.probabilities_identical -ne 388 -or $chk.failed_calls -ne 0) { throw "identity counts differ from the text" }
if ($chk.response_ms.p95 -ge 1000) { throw "p95 not below 1 s" }
$py = Join-Path $root "06_Python_ML\.venv\Scripts\python.exe"
$apiOut = & $py -I -m pytest (Join-Path $api "tests") -q -p no:cacheprovider 2>&1 | Select-Object -Last 1
if ("$apiOut" -notmatch '^(\d+) passed') { throw "API tests failed: $apiOut" }
$nApi = $Matches[1]
$allOut = & $py -I -m pytest (Join-Path $root "06_Python_ML\tests") (Join-Path $api "tests") -q -p no:cacheprovider 2>&1 | Select-Object -Last 1
if ("$allOut" -notmatch '^(\d+) passed') { throw "tests failed: $allOut" }
$nAll = $Matches[1]
if ("$apiOut$allOut" -match 'failed|error') { throw "a test failed" }
$ic = [Globalization.CultureInfo]::InvariantCulture; $med = ([double]$chk.response_ms.median).ToString("F1", $ic); $p95 = ([double]$chk.response_ms.p95).ToString("F1", $ic); $mx = ([double]$chk.response_ms.max).ToString("F1", $ic); $mn = ([double]$chk.response_ms.min).ToString("F1", $ic)
$hw = $chk.hardware
$hwText = $hw.cpu + ", " + $hw.logical_processors + " logical processors, " + $hw.ram_GB + " GB RAM, " + $hw.os + ", Python " + $hw.python
$exA = $ex.answer
if ($exA.fault_class -ne "T3" -or $ex.refused_example.status -ne 422) { throw "example differs from the text" }

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
$doc = $null; $sel = $null
. (Join-Path $sp "helpers.ps1")
. (Join-Path $sp "report_closings.ps1")
. (Join-Path $sp "report_methods.ps1")
$global:Methods["38"] = @{
  Approach = @(
    "The released model dga_model_v1 (Step 24) was put behind a small web service written with FastAPI. A program - later the MATLAB dashboard - sends the five gas values of one sample as a JSON message to the address POST /diagnose and receives the machine-learning diagnosis: the most probable fault class, the probability of every class and the model version. GET /health tells whether the service is running and GET /version returns the model's metadata.",
    "The service loads the model file once at start-up through the project's safe loader, which compares the file's SHA-256 fingerprint with the recorded one; if they differ the service does not start. Every request is checked before the model sees it: all five gases must be present, be numbers, be finite and be zero or more; anything else is refused with a clear message. Nothing is trained or tuned in this step.",
    "The service was then tested in two ways: 21 automated tests (pytest) of the answers and the input checks, and a run of the real server on the project laptop to which the 388 held-out records were sent one by one; each answer was compared with the saved offline prediction, and the time to answer was measured.")
  Why = @(
    "A web service is the standard way to let a MATLAB application use a Python model: MATLAB's webwrite sends the request, and the model stays in the exact Python environment in which it was trained, so the dashboard gets the offline answers and not an approximate copy.",
    "Strict input checks stop silent errors, for example a misspelt gas name or a negative value, before they reach the model; the fingerprint check guarantees that the service answers with the released model and no other.",
    "Comparing the service with the saved offline predictions shows, before the MATLAB work starts, that nothing is lost between the model and the interface (the requirement of the Analysis Plan, Section 10, is 100 % fidelity).")
  Settings = @(
    @("Endpoints", "POST /diagnose, GET /health, GET /version; interface description in openapi.json (OpenAPI 3.1.0)"),
    @("Address", "http://127.0.0.1:8000 (this computer only; no log-in)"),
    @("Input rules", "H2, CH4, C2H6, C2H4, C2H2 in ppm, required, numbers, finite, >= 0; optional record_id (text, at most 64 characters); any other field refused (HTTP 422)"),
    @("Answer", "fault_class, probabilities (7 classes, not rounded), confidence (largest probability), model name, version and SHA-256, data version, notes"),
    @("Model", "dga_model_v1 (Random Forest, feature set F4), SHA-256 1C46D103...7809523, loaded with model_io.load_model()"),
    @("Service check", "real server; 5 warm-up requests not counted; then 388 held-out records one at a time; time from sending to receiving and decoding the answer"),
    @("Software", "Python 3.12.10, FastAPI 0.143.0, Uvicorn 0.54.0, Pydantic 2.14.0, HTTPX 0.28.1, scikit-learn 1.9.1"))
  Eqs = @(
    @{ Eq = 'F=n_"match"/N'; Where = @(@('F', 'fidelity of the service (fraction; required value 1)'), @('n_match', 'number of held-out records for which the service returns exactly the saved offline class'), @('N', 'number of held-out records sent to the service (388)')) },
    @{ Eq = 't_"p95"=Q_(0.95) (t_1,...,t_N)'; Where = @(@('t_p95', '95th percentile of the response times [ms]: 95 % of the requests were answered at least this fast'), @('t_i', 'response time of request i [ms]'), @('Q_0.95', 'the 0.95 quantile, linear interpolation between ordered values (numpy.percentile)')) })
  Tools = @("09_API_FastAPI/app/main.py and app/schemas.py (service); tests/test_api.py (pytest); step38_service_check.py (real-server check); export_openapi.py (openapi.json); example_request.py; run_service.ps1")
  Refs = @("M33", "M34")
}
$global:Closings["38"] = @{
  Achieved = @(
    "The diagnosis service exists and runs on the project laptop: one command starts it, and the dashboard can ask it for a diagnosis over HTTP.",
    ("The service returned exactly the saved offline class and probabilities for all " + $chk.n_records + " held-out records (fidelity 100 %, preliminary), with no failed request."),
    ("It answers in " + $med + " ms (median) and " + $p95 + " ms (95th percentile), far inside the 1 s target."),
    "openapi.json describes the interface for the MATLAB dashboard of Step 39.")
  Record = @(
    @("Step", "38 - Build the FastAPI service"), @("Environment", "Claude Code (this chat)"),
    @("Completed", "13 October 2026"), @("Status", "Done"),
    @("Main inputs", "06_Python_ML/models/dga_model_v1.joblib (DF27); for the checks: ml_predictions.csv (DF25) and the gases of dga_master.csv (DF2)"),
    @("Main outputs", "09_API_FastAPI: app/, tests/, openapi.json, run_service.ps1, checks/step38_service_check.json, step38_response_times.csv, step38_example.json, code_manifest_step38.sha256"),
    @("Checks", ($nApi + " of " + $nApi + " service tests and " + $nAll + " of " + $nAll + " project tests pass; real server " + $chk.class_matches + "/" + $chk.n_records + " identical answers; p95 " + $p95 + " ms")),
    @("Decisions", "D36 (design of the service)"))
  Helps = @(
    "Step 39 (MATLAB Agentic Toolkit) builds the dashboard against openapi.json; in ml_diagnose.m only ML_ENABLED has to be set to true (the address is already http://127.0.0.1:8000/diagnose and the answer fields fault_class and probabilities match).",
    "The optional record_id lets the test bench (Steps 40-41) write each answer next to its record, so Step 42 can compare the log with the offline predictions record by record.",
    "Table 4.11 and Figure 4.21 will be made in Step 42 from the test-bench log; this step shows the Python side already meets both requirements.")
  Open = @(
    "The fidelity and response time here are preliminary: they are measured from Python on the same computer. The formal values (Table 4.11, Figure 4.21) are measured through the MATLAB dashboard in Steps 41-42 and will include MATLAB's own time.",
    "The service has no log-in and listens only on this computer; it is a test bench, not a product for a utility network. Running it on a network would need authentication and encryption (not in the scope of the thesis).",
    "The service returns the model's answer for any valid sample, including samples unlike the training data; it has no check for unusual samples and no reject option (the reject option of Study 2 is exploratory). The model card's limitations apply.",
    "ml_diagnose.m does not yet send a record_id; the test bench of Step 41 should send it so that answers can be matched to records.",
    "pytest shows a deprecation warning of the Starlette test client (the httpx package); it does not affect any result.")
  Exclude = @()
}
$global:StepSources["38"] = @("DF27", "DF25", "DF2", "SW1", "SW6", "DF79", "DF80", "DF81")
function ReportHeader([string]$num, [string]$name, [string]$env, [string]$completed = "13 October 2026") {
  $global:sec = 0; $global:eqn = 0
  Title ("Step " + $num + " Report") 18
  Title $name 13
  Center ("Environment: " + $env + "   |   Completed: " + $completed + "   |   Report version 2 (13 October 2026)")
  Center "Thesis: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT)"
  Ital "Abbreviations (such as PD, D1, T1, ppm) and technical terms are explained in the last section of this report."
}
$global:Blocks = @{ "38" = [IO.File]::ReadAllText($PSCommandPath, [Text.Encoding]::UTF8) }

try {
$doc = $word.Documents.Add(); $sel = $word.Selection; Init-Doc
ReportHeader "38" "Build the FastAPI service" "Claude Code (this chat)"
Summary ("The released machine-learning model now runs as a small web service on the project laptop. A program sends the five gas values of a sample and gets back the fault class, the probability of every class and the model version. Wrong input (a missing or negative gas, text instead of a number, a misspelt name) is refused with a clear message. When the 388 held-out records were sent to the running service, every answer was exactly the saved offline answer, and the service answered in about " + $med + " ms (95 % of requests within " + $p95 + " ms), far inside the 1 s target. The MATLAB dashboard (Step 39) can now be connected.")
H1N "Purpose of this step"
Body "Stage H joins the three environments into one test bench. This first step makes the machine-learning model available to MATLAB: it wraps the released model in a web service with a fixed, documented interface, so that the dashboard can ask for a diagnosis and get exactly the result of the offline analysis."
MethodSection "38"
H1N "What was done, step by step"
NumItem "1" "Checked the inputs of the step: the roadmap (Step 38), the Analysis Plan (Section 10), the folder README and the MATLAB function ml_diagnose.m that will call the service (its address and the answer fields it reads). Stage G (Steps 33-37) was already complete."
NumItem "2" "Fixed the design before writing any code (decision D36): ML diagnosis only (the conventional methods are computed in MATLAB), input rules, answer fields, start-up check, local address, tests."
NumItem "3" "Wrote the service (app/main.py, app/schemas.py) and wrote openapi.json from it (export_openapi.py)."
NumItem "4" ("Wrote " + $nApi + " pytest tests; the first run found a fault (see Problems and fixes), which was corrected; all tests then passed, and the whole project suite (" + $nAll + " tests) passed.")
NumItem "5" ("Ran the real server on the project laptop and sent the " + $chk.n_records + " held-out records (step38_service_check.py); started it a second time with run_service.ps1 and checked /health, one diagnosis and one refused input.")
H1N "How the service is used"
AddTable @("Address", "What it does") @(
  , @("POST /diagnose", "Send one sample (five gases in ppm, optional record_id); receive the class, the 7 probabilities, the confidence, model name, version, SHA-256 and data version, and notes")
  , @("GET /health", "Answers status ok, model loaded and the verified model fingerprint")
  , @("GET /version", "API version and the model metadata (inputs, unit, classes, training details)")
) @(110, 340)
Body "Start: powershell -ExecutionPolicy Bypass -File 09_API_FastAPI\run_service.ps1 (stop with Ctrl+C). While it runs, http://127.0.0.1:8000/docs shows an interactive page of the interface."
H2 "Example"
Body ("Request (an illustrative sample, not a measured record): H2 " + $ex.request.H2 + ", CH4 " + $ex.request.CH4 + ", C2H6 " + $ex.request.C2H6 + ", C2H4 " + $ex.request.C2H4 + ", C2H2 " + $ex.request.C2H2 + " ppm.")
$exP = $exA.probabilities
AddTable @("Normal", "PD", "D1", "D2", "T1", "T2", "T3", "Class") @(, @([string]$exP.Normal, [string]$exP.PD, [string]$exP.D1, [string]$exP.D2, [string]$exP.T1, [string]$exP.T2, [string]$exP.T3, [string]$exA.fault_class)) @(55, 50, 50, 50, 50, 50, 50, 95)
Body ("The answer is T3 (thermal fault above 700 degC) with probability " + $exA.confidence + "; the ratios of this sample (C2H2/C2H4 close to 0, CH4/H2 = 1.5, C2H4/C2H6 = 5.6) also point to T3 in the IEC 60599 ratio table. With H2 = -5 the service refuses the sample with HTTP status " + $ex.refused_example.status + " and the message '" + $ex.refused_example.detail[0].msg + "' for the field H2.")
H1N "Results of the service check"
AddTable @("Measure", "Result") @(
  , @("Records sent (held-out: benchmark, internal and external test)", [string]$chk.n_records)
  , @("Failed requests", [string]$chk.failed_calls)
  , @("Same class as the offline prediction", ("" + $chk.class_matches + " of " + $chk.n_records + " (F = " + $chk.class_identity_fraction + ")"))
  , @("Same 7 probabilities, digit for digit", ("" + $chk.probabilities_identical + " of " + $chk.n_records))
  , @("record_id returned unchanged", ("" + $chk.record_id_returned + " of " + $chk.n_records))
  , @("Response time, median", ($med + " ms"))
  , @("Response time, 95th percentile (target below 1000 ms)", ($p95 + " ms"))
  , @("Response time, fastest and slowest", ($mn + " ms and " + $mx + " ms"))
  , @("Start-up time (until /health answers; includes loading the model)", ("" + $chk.start_up_s + " s"))
  , @("Computer", $hwText)
) @(250, 200)
Body "Only the record_id, the five gases and the saved predictions were read; the true fault labels were not read and no accuracy was computed, so this check cannot influence any result. The run is noted in 11_Results/ml/test_set_access.log. The response time includes the model calculation (500 decision trees per sample) as well as sending and decoding the messages."
H1N "Checks"
AddTable @("Check (roadmap: all tests pass and the service runs on the project laptop)", "Result") @(
  , @("Service tests (validation, answers, identity with the offline file, refusal of a changed model file, openapi.json up to date)", ("PASS - " + $nApi + " of " + $nApi))
  , @("Whole project test suite", ("PASS - " + $nAll + " of " + $nAll))
  , @("Real server on the project laptop: 388 held-out records", "PASS - all identical, no failed request")
  , @("Response time, 95th percentile below 1 s (Analysis Plan item 15)", ("PASS - " + $p95 + " ms (preliminary)"))
  , @("Start script run_service.ps1: /health, one diagnosis, one refused input", "PASS")
  , @("Model file with one changed byte", "PASS - the service refuses to start")
) @(330, 120)
H1N "Problems and fixes"
Bullet "The first test run found that a NaN or Infinity value made the service fail with a server error instead of refusing the input: the error message repeats the wrong value, and NaN cannot be written in JSON. The error handler now writes such values as text, and the tests check that the answer is HTTP 422 naming the field."
Bullet "Report version 2: the register IDs of the Step 38 files are DF79-DF81. Version 1 used DF71-DF73, which a parallel session had meanwhile given to the Step 39 files; the Step 39 entries were kept and the Step 38 entries renumbered."
Bullet "The plain 'python' command of this computer does not have the project's packages; the start script and all commands use the project environment (06_Python_ML\.venv)."
H1N "Decisions"
Bullet "D36 (closed, procedural): design of the service, fixed before it was written - ML diagnosis only; input rules; answer fields; start-up fingerprint check; local address; tests and the preliminary service check. It replaces the older plan in the folder README (conventional answers and an agreement flag in the service)."
H1N "Files produced"
Bullet "09_API_FastAPI/app/__init__.py, main.py, schemas.py; tests/test_api.py; export_openapi.py; openapi.json; example_request.py; step38_service_check.py; run_service.ps1; README.md; code_manifest_step38.sha256"
Bullet "09_API_FastAPI/checks/step38_service_check.json, step38_response_times.csv, step38_example.json"
Closing "38" 0 "Step 39 (MATLAB Agentic Toolkit): build the App Designer dashboard DGADashboard.mlapp that shows the three conventional diagnoses computed in MATLAB, calls /diagnose for the ML diagnosis (openapi.json), plots the Duval Triangle and shows the agreement flag and the operating context." $global:Blocks["38"]
while ($doc.Paragraphs.Count -gt 1 -and $doc.Paragraphs.Last.Range.Text.Trim() -eq "") { $r2 = $doc.Content; $r2.SetRange($r2.End - 2, $r2.End - 1); if ($r2.Text -ne [string][char]13) { break }; $r2.Delete() | Out-Null }
$tmp = Join-Path $work "out_Step_38_Report.docx"
[void]$doc.GetType().InvokeMember("SaveAs2", [Reflection.BindingFlags]::InvokeMethod, $null, $doc, @([string]$tmp, 16))
$pg = $doc.ComputeStatistics(2); $doc.Close($false)
Copy-Item $tmp (Join-Path $outDir "Step_38_Report.docx") -Force
("SAVED Step_38_Report.docx (" + $pg + " pages) " + (Get-Date -Format T)) | Out-File $prog -Append -Encoding utf8
} catch {
  ("ERROR " + $_.Exception.Message + " | " + $_.ScriptStackTrace) | Out-File $prog -Append -Encoding utf8
} finally {
  $word.Quit()
}
