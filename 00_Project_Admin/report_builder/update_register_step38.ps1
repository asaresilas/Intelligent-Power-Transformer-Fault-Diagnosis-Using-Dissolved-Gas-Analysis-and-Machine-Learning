# update_register_step38.ps1 (IDs DF79-DF81 since 2026-10-13: DF71-DF73 were taken by Step 39 in a parallel session) - adds the sources and files of roadmap Step 38 (FastAPI service) to the register and glossary. Safe to re-run.
$ErrorActionPreference = "Stop"
$root = "D:\Research WORK\Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning"
$regFile = Join-Path $root "03_Data\provenance\data_and_source_register.csv"
$gloFile = Join-Path $root "00_Project_Admin\abbreviations_glossary.csv"
$utf8 = New-Object Text.UTF8Encoding($false)
function Hsh([string]$rel) { (Get-FileHash (Join-Path $root $rel) -Algorithm SHA256).Hash }
$reg = [System.Collections.ArrayList]@(Import-Csv $regFile -Encoding UTF8)
$cols = $reg[0].PSObject.Properties.Name
function NewRow([hashtable]$h) { $o = [ordered]@{}; foreach ($c in $cols) { $o[$c] = if ($h.ContainsKey($c)) { [string]$h[$c] } else { "" } }; [pscustomobject]$o }
function Put($row) { for ($i = $reg.Count - 1; $i -ge 0; $i--) { if ($reg[$i].id -eq $row.id) { $reg.RemoveAt($i) } }; [void]$reg.Add($row) }
$acc = "2026-10-13"; $A = "09_API_FastAPI/"
Put (NewRow @{ id = "SW6"; category = "Software"; name = "FastAPI web service stack"
  reference = "FastAPI 0.143.0 (web framework), Uvicorn 0.54.0 (server), Pydantic 2.14.0 (input validation), HTTPX 0.28.1 (HTTP client for tests and the service check); Python packages pinned in 06_Python_ML/requirements.txt."
  link = "https://fastapi.tiangolo.com/"; accessed = $acc; how_obtained = "Already installed in the project environment from requirements.txt (Step 1, SW1); versions and licences read from the installed package metadata"
  licence_terms = "MIT (FastAPI, Pydantic); BSD-3-Clause (Uvicorn, HTTPX, Starlette 1.7.0)"; local_file = "06_Python_ML/requirements.txt"; sha256 = (Hsh "06_Python_ML/requirements.txt")
  project_role = "Runs the diagnosis service of Step 38 and its tests"; used_in_steps = "38-42"
  notes = "pytest shows a deprecation warning of Starlette's test client (httpx); it does not affect the results." })
Put (NewRow @{ id = "M33"; category = "Method reference"; name = "OpenAPI Specification 3.1.0"
  reference = "OpenAPI Initiative, OpenAPI Specification v3.1.0, 15 February 2021 (editors D. Miller, J. Whitlock, M. Gardiner, M. Ralphson, R. Ratovsky, U. Sarid)."
  link = "https://spec.openapis.org/oas/v3.1.0"; accessed = $acc; how_obtained = "Read online at the OpenAPI Initiative site; title, version, date and editors confirmed on 2026-10-13"
  licence_terms = "Open specification (licence not recorded here)"; project_role = "Format of 09_API_FastAPI/openapi.json, the interface description used by the MATLAB dashboard"; used_in_steps = "38, 39" })
Put (NewRow @{ id = "M34"; category = "Method reference"; name = "RFC 9110 HTTP Semantics"
  reference = "R. Fielding, M. Nottingham and J. Reschke (Eds.), ""HTTP Semantics,"" RFC 9110, STD 97, RFC Editor, June 2022."
  link = "https://www.rfc-editor.org/rfc/rfc9110"; doi = "10.17487/RFC9110"; accessed = $acc; how_obtained = "Details confirmed in Crossref (DOI record) and on rfc-editor.org on 2026-10-13"
  licence_terms = "Open (IETF document)"; project_role = "Meaning of the HTTP status codes used by the service: 200 OK, 422 Unprocessable Content (Section 15.5.21) for refused input"; used_in_steps = "38" })
Put (NewRow @{ id = "DF79"; category = "Derived file"; name = "Step 38 service code (manifest)"
  reference = "app/__init__.py, app/main.py, app/schemas.py, export_openapi.py, openapi.json, tests/test_api.py, step38_service_check.py, example_request.py, run_service.ps1 (09_API_FastAPI)."
  accessed = $acc; how_obtained = "Written in this project"; licence_terms = "Project file"; local_file = ($A + "code_manifest_step38.sha256"); sha256 = (Hsh ($A + "code_manifest_step38.sha256")); records = "9 files"
  project_role = "Fingerprints of the diagnosis service, its tests and its interface description"; used_in_steps = "38-42" })
Put (NewRow @{ id = "DF80"; category = "Derived file"; name = "openapi.json - interface description of the service (Step 38)"
  reference = "Written by export_openapi.py from the application (OpenAPI 3.1.0, M33): endpoints POST /diagnose, GET /health, GET /version and the request and answer schemas."
  accessed = $acc; how_obtained = "Program output"; licence_terms = "Project file"; local_file = ($A + "openapi.json"); sha256 = (Hsh ($A + "openapi.json")); records = "3 endpoints"
  project_role = "Input of Step 39 (the dashboard calls /diagnose as described here)"; used_in_steps = "38, 39" })
Put (NewRow @{ id = "DF81"; category = "Derived file"; name = "Service check on the project laptop (Step 38)"
  reference = "step38_service_check.json (hardware, versions, identity counts, preliminary response times) and step38_response_times.csv (one row per held-out record), written by step38_service_check.py."
  accessed = $acc; how_obtained = "Program output"; licence_terms = "Project file"; local_file = ($A + "checks/step38_service_check.json"); sha256 = (Hsh ($A + "checks/step38_service_check.json")); records = "388 requests"
  project_role = "Evidence that the real service returns exactly the offline answers (388/388) and responds within the 1 s target (preliminary)"; used_in_steps = "38, 42"
  notes = ("step38_response_times.csv SHA-256 " + (Hsh ($A + "checks/step38_response_times.csv")) + ". Inputs: DF2 (record_id and gases only), DF25 (saved predictions), DF27 (model). True labels not read. The run is logged in 11_Results/ml/test_set_access.log.") })
foreach ($x in $reg) {
  if ($x.id -in @("SW1", "DF2", "DF25") -and $x.used_in_steps -notmatch "\b38\b") { $x.used_in_steps = ($x.used_in_steps.TrimEnd() + ", 38") }
}
[IO.File]::WriteAllLines($regFile, ($reg | ConvertTo-Csv -NoTypeInformation), $utf8)
"register rows: " + $reg.Count
$glo = [System.Collections.ArrayList]@(Import-Csv $gloFile -Encoding UTF8)
$gcols = $glo[0].PSObject.Properties.Name
function G($grp, $term, $meaning, $plain, $src, $pattern) { $o = [ordered]@{}; foreach ($c in $gcols) { $o[$c] = "" }; $o.group = $grp; $o.term = $term; $o.meaning = $meaning; $o.plain_explanation = $plain; $o.source = $src; $o.pattern = $pattern; [pscustomobject]$o }
$new = @(
  (G "Software" "API" "application programming interface" "A fixed way for one program to ask another for something; here the dashboard asks the Python service for a diagnosis." "" '\bAPI\b'),
  (G "Software" "HTTP" "Hypertext Transfer Protocol" "The message format of the web; the dashboard sends a request and the service sends back an answer with a status code (200 = OK, 422 = input refused)." "RFC 9110" '\bHTTP\b'),
  (G "Software" "JSON" "JavaScript Object Notation" "A plain-text format for named values, e.g. {""H2"": 200}; requests and answers of the service are written in it." "" '\bJSON\b'),
  (G "Software" "OpenAPI (openapi.json)" "standard description of a web interface" "A file that lists every address of the service, what it must be sent and what it answers, so another program can be built against it." "OpenAPI Specification 3.1.0" 'OpenAPI|openapi\.json'),
  (G "Software" "FastAPI" "Python framework for web services" "The library used to build the diagnosis service; it also checks every input against the declared rules." "" 'FastAPI'),
  (G "Software" "Endpoint" "one address of a web service" "For example POST /diagnose (send a sample, get a diagnosis) or GET /health (is the service alive?)." "" '[Ee]ndpoint|/diagnose|/health|/version'),
  (G "Software" "127.0.0.1 (localhost)" "the address of the computer itself" "A service on 127.0.0.1 can be reached only from the same computer, not from the network." "" '127\.0\.0\.1|localhost'),
  (G "Statistics" "95th percentile (p95)" "the value below which 95 % of the measurements lie" "Used for the response time: 95 of every 100 requests are answered at least this fast." "Analysis Plan Section 10" '95th percentile|\bp95\b'),
  (G "Methods" "Fidelity" "share of records for which the service gives exactly the offline answer" "F = matches / records sent (Analysis Plan Eq. 47); the requirement is 100 %." "Analysis Plan Section 10" '[Ff]idelity'))
foreach ($n in $new) { for ($i = $glo.Count - 1; $i -ge 0; $i--) { if ($glo[$i].term -eq $n.term) { $glo.RemoveAt($i) } }; [void]$glo.Add($n) }
[IO.File]::WriteAllLines($gloFile, ($glo | ConvertTo-Csv -NoTypeInformation), $utf8)
"glossary rows: " + $glo.Count
