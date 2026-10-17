# How to Run the Dashboard and the Simulink Model, and How to Set Up the Whole Project on Another Computer

Project: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning
(MPhil, UMaT). Written 15 Oct 2026. Everything below uses paths **relative to the project folder** (called `<PROJECT>`).

---

## 1. Where everything is

| What | Where (inside `<PROJECT>`) |
|---|---|
| **Dashboard (app)** | `10_Dashboard_Client\DGADashboard.mlapp` (a MATLAB App Designer app) |
| Dashboard helper functions | `10_Dashboard_Client\*.m` (`ml_diagnose.m`, `dga_agreement.m`, `load_dga_record.m`, ...) |
| **Simulink model** | `05_Simulink_Model\Transformer_Operating_Model.slx` |
| Model parameters (the only place values are typed) | `05_Simulink_Model\params_transformer.m` |
| Run the model from code | `05_Simulink_Model\run_transformer_simulation.m`, `scenarios.m`, `run_step36.m` |
| **Machine-learning service (FastAPI)** | `09_API_FastAPI\` (start with `run_service.ps1`) |
| Released ML model | `06_Python_ML\models\dga_model_v1.joblib` (+ `model_card.md`) |
| Conventional methods (Rogers, IEC 60599, Duval) in MATLAB | `04_MATLAB_Conventional\` |
| Measured DGA data used by the dashboard | `03_Data\processed\dga_master.csv` |
| Standards tables (Duval triangle zones, etc.) | `02_Standards\` |
| Results, tables, figures | `11_Results\` |
| Thesis | `12_Thesis\Thesis_Draft_v2.docx` |

**How the pieces fit together (one sentence).** The dashboard (MATLAB) computes the three conventional diagnoses itself,
asks the **Python service** for the machine-learning diagnosis, and its *Run Simulation* button runs the **Simulink model**
(load, oil and hot-spot temperature, ageing) and marks the sampling times at which real held-out DGA records are diagnosed.
The Simulink model never creates gas values.

```
 Simulink model  --(sampling events: record_id)-->  Dashboard (MATLAB)  --(HTTP, 5 gas values)-->  FastAPI service (Python, ML model)
                                                         |  also computes Rogers / IEC / Duval in MATLAB
```

---

## 2. What must be installed (any computer)

| Software | Needed for | Version used in this project |
|---|---|---|
| **MATLAB** with **Simulink**, **Simscape**, **Simscape Electrical** | Dashboard, Simulink model, conventional methods | R2025b (25.2) |
| **Python** | ML service | 3.12.10 (3.12.x) |
| Internet (once) | Installing the Python libraries | - |
| Microsoft Word (optional) | Only to rebuild thesis / step reports | - |

Notes
- Statistics and Machine Learning Toolbox is **not** needed.
- Use **R2025b** if you can. An older release may not open the model or app (an .slx/.mlapp saved in R2025b does not open in older releases).
- Windows 11 was used. The service start script is PowerShell (`run_service.ps1`).

---

## 3. Set up the project on a different computer (one time)

### Step 1 - Copy the project
1. Copy the whole project folder to the new computer (USB drive or SSD).
   - **Leave out** `06_Python_ML\.venv` (about 520 MB, it is tied to the old computer and will not work on another one; Step 3 recreates it).
   - You can also leave out the cache folders `slprj\`, `__pycache__\`, `.pytest_cache\` (MATLAB/Python recreate them).
   - Total size without `.venv` is roughly 750 MB.
2. Put it in a **short path**, for example `C:\DGA_Project`. The original folder name is very long and Windows can fail on long paths.
   Do not put it in a OneDrive-synced folder (sync can lock the Simulink cache files).
3. Do not rename the numbered sub-folders (`03_Data`, `05_Simulink_Model`, ...). The code finds files by these names.

### Step 2 - Install Python 3.12
1. Download Python 3.12 from https://www.python.org/downloads/ and install it. Tick **"Add python.exe to PATH"**.
2. Open **PowerShell** and check: `python --version` (should print 3.12.x).

### Step 3 - Create the Python environment (installs the exact library versions of this project)
In PowerShell:
```powershell
cd C:\DGA_Project\06_Python_ML
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```
This takes a few minutes and needs internet. Then check it:
```powershell
cd C:\DGA_Project
.\06_Python_ML\.venv\Scripts\python.exe 06_Python_ML\src\check_environment.py
```
Expected: all libraries listed as OK (it passed 16/16 on the original computer).

### Step 4 - Check the service and the model (no MATLAB needed yet)
```powershell
cd C:\DGA_Project
.\06_Python_ML\.venv\Scripts\python.exe -I -m pytest 09_API_FastAPI\tests -q
```
Expected: `21 passed`. This proves the released model file is intact (the service refuses to start if the model's SHA-256 does not match).

### Step 5 - Prepare MATLAB
1. Install MATLAB R2025b with Simulink, Simscape and Simscape Electrical (MathWorks Add-On Explorer / installer).
2. Open MATLAB, then in the Command Window:
```matlab
cd C:\DGA_Project
project_setup
```
Expected message: `Project paths added. Parameters loaded from params_transformer.m`.
**Run `project_setup` at the start of every MATLAB session**: it puts folders 04, 05 and 10 on the MATLAB path and loads the parameters.
3. Check the toolboxes: `ver` (or `license('test','Simscape_Electrical')` should return `1`).

Setup is finished.

---

## 4. Run the Simulink model

### Option A - open it and press Run (best for showing the lecturer the diagram)
```matlab
cd C:\DGA_Project
project_setup
open_system('Transformer_Operating_Model')
```
- Press **Run** (green triangle) in the Simulink toolbar. The 24-hour simulation takes about 10 seconds.
- What the lecturer will see: eight annotated subsystems
  SS1 110 kV grid -> SS2 40 MVA 110/20 kV transformer -> SS3 current and load factor K -> SS4 variable load -> SS5 losses to heat ->
  SS6 Simscape thermal network (oil and winding R-C circuits, IEC 60076-7 equations) -> SS7 outputs and ageing; SS8 = DGA sampling events.
- Open the **Scope / Simulation Data Inspector** to see the load factor K, top-oil temperature, hot-spot temperature and ageing rate.
- Key reference numbers at rated load from 20 degC ambient: top-oil 78.64 degC, hot-spot 100.28 degC, top-oil time constant 75 min.
- To change values (ambient temperature, ratings, thermal constants, sampling times) edit **only** `05_Simulink_Model\params_transformer.m`, save, and run again.

### Option B - run it from MATLAB code and plot
```matlab
res = run_transformer_simulation();      % returns t_h, K_pu, theta_oil_C, theta_hs_C, ageing_V, loss_of_life_h
figure; plot(res.t_h, res.theta_oil_C, res.t_h, res.theta_hs_C); grid on
xlabel('Time (h)'); ylabel('Temperature (\circC)'); legend('Top-oil','Hot-spot')
```

### Option C - the three demonstration scenarios (rated load, daily load cycle, short overload)
```matlab
cd 05_Simulink_Model
run_step36
```
Produces Figure 4.19 a-c in `11_Results\figures\` and a summary table (peak hot-spot 100.3 / 99.9 / 129.0 degC). The scenario loads are illustrative, not measured.

### Option D - prove the model is correct (verification scripts)
```matlab
cd 05_Simulink_Model
verify_step33      % 9 structure checks (7 expected differences are listed in the output)
verify_step35      % compares the model with an independent IEC 60076-7 solution: 15/15 PASS expected
verify_step37      % sampling-event subsystem: 10/10 PASS expected
```
Verification result to quote: maximum difference after the first 10 min is 0.0014 K (top-oil) and 0.0129 K (hot-spot), against a limit of 0.1 K.
This is verification against the standard's equations, **not** validation against a real transformer.

### If Simulink shows an error
- `Unrecognized function or variable 'params_transformer'` -> you did not run `project_setup`. Run it, then try again.
- Model will not open or "Simscape ... not licensed" -> Simscape / Simscape Electrical is missing. Check with `ver`.
- Delete `05_Simulink_Model\slprj` and the `.slxc` cache files, restart MATLAB, run `project_setup`, try again.

---

## 5. Run the Dashboard (app) - the dashboard is the master control

**Since 15 October 2026 you only start the dashboard.** It starts the Python ML service itself (hidden, output in `09_API_FastAPI\logs\service.log`),
prepares the Simulink model, and stops the service again when you close the window (only if the dashboard started it).

### Step 1 - Start the dashboard (MATLAB)
```matlab
cd C:\DGA_Project
DGADashboard
```
(`project_setup` is no longer needed first: the app finds the project folders itself. Or double-click `10_Dashboard_Client\DGADashboard.mlapp`.)
A small window **"Starting the dashboard"** shows what is happening: checking/starting the ML service (about 10-30 s) and preparing the Simulink
model (the first start in a MATLAB session takes up to about 1 minute). **Wait for it to close** - the window is not frozen. When the status line says
"Ready. ML service connected." everything works.
If the window is cut off on a small screen, the layout was designed for a window 1380 x 740 pixels (a 1366 x 768 screen is fine if the taskbar is hidden or you maximise the window).

### The tab "Explanation in words"
The dashboard explains every result in plain words: what the simulation shows (peak temperatures, ageing), what each method says, how sure the ML model is,
whether the methods agree, what the fault types mean, and how much to trust the answer. The text changes with the result on the screen.
Click a row of the sample table to see the explanation of that sample.

### The button "Restart ML service"
If the ML row ever says NOT_CONNECTED, press this button: it stops the service (also a stuck one) and starts it again. The dashboard also does this by itself before a diagnosis when the service does not answer.

### The screen, from top to bottom (redesign of 17 October 2026)
1. **Banner** - the answer in one line: green HEALTHY, red FAULT with its type, amber WATCH or CHECK; then why, and what to do.
2. **Five cards** - Rogers, IEC 60599, Duval Triangle 1, machine learning, and the known label of the record (if the file has one). Each method card says AGREES, DIFFERS or NO ANSWER.
3. **Sample table** - one row per oil sample: known label, the four answers, how many classical methods agree with ML, and the verdict. Click a row to look at that sample.
4. **Tabs** - *Charts* (gas against typical value, Duval Triangle, ML probabilities), *Step by step* (the IEC 60599 / IEEE C57.104 procedure with the numbers of the sample), *Explanation in words*, *Tables*, *Simulation (operating condition)*.

### Step 2 - What to do in the dashboard
1. **Operating condition** (left, step 1): constant rated load, daily load cycle (3 days simulated, last day shown) or short overload. It changes only the simulated temperatures.
2. **Oil samples to examine** (left, step 2): *Mixed* = a healthy sample plus one of each fault type (a new set each time you press Run); *Healthy records only* = 7 records of the known class Normal (most published DGA records are faults, so a random sample is usually a fault); *Random* = 7 random held-out records; *First 4* = the original test run (records IECTC10_0001 to 0004).
3. Press **Run simulation + diagnose**. The model runs, the sampling events are marked on the temperature plot (tab *Simulation*), and every sample is diagnosed and added to the sample table. A run takes a few seconds; the daily cycle takes longer.
4. **Look at one record instead:** choose a fault type in the drop-down and press **Pick random record**, or type five gas values (ppm) into the gas table and press **Diagnose the values typed above**; or use **Load measured DGA file**, type a record number and press **Diagnose selected record**. (CSV/XLSX with columns H2, CH4, C2H6, C2H4, C2H2 in ppm; optional record_id, equipment_type, class_name.)
5. The **agreement lamp** (right of the banner): green = all three conventional methods agree with ML; amber = at least one disagrees; grey = ML not available. (D1/D2 counts as agreeing with D1 or D2; "DT" and "ND" never count as agreement.)
6. Fault classes: Normal, PD (partial discharge), D1 (low-energy discharge), D2 (high-energy discharge), T1/T2/T3 (thermal faults <300, 300-700, >700 degC).

**How the verdict is made (decision D43):** every method gives one vote (D1/D2 votes for both D1 and D2; DT and ND give no vote); the class with the most votes wins if it has at least two votes; otherwise the banner says CHECK. If all five gases are at or below the IEC 60599 typical values the sample is HEALTHY. The verdict is a display rule for the viewer, not a validated classifier.

Things the app deliberately never does: invent a diagnosis, create or change gas values, or present the simulated temperature as the cause of the measured gases.

### If the dashboard shows a problem
- ML row says `NOT_CONNECTED` -> press **Restart ML service**; if it still fails read `09_API_FastAPI\logs\service.log` (something else may use port 8000, or the Python environment is missing: section 3, Step 3).
- `Undefined function 'DGADashboard'` -> run `project_setup` first from the project root.
- Service does not start -> run the pytest check in section 3, Step 4. The most common cause is that the Python environment was not created on this computer (section 3, Step 3).

---

## 6. Recommended order for presenting to the lecturer (about 15 minutes)

1. **Before the meeting (at home, once):** do section 3 on the presentation computer and test sections 4 and 5. Test again on the day, with the same cable/screen.
2. Open the thesis figures if the computer fails: `11_Results\figures\` contains Figure 4.18 (Simulink verification), 4.19 (scenarios), 4.20-4.22 (dashboard and test bench) as picture files, and `10_Dashboard_Client\reference_app_screenshot.png` is a screenshot of the app.
3. Start the dashboard first (section 5) - it starts the service - and keep the browser tab http://127.0.0.1:8000/docs ready.
4. Show the **Simulink model** (section 4, Option A): the eight subsystems, the annotations, press Run, show the temperatures.
5. Show the **dashboard** (section 5): pick one record where all methods agree (green) and one where they disagree (amber); press **Run simulation + diagnose** (choose *Mixed* to show healthy and every fault type).
6. Show the evidence: `11_Results\tables\T4_10_simulink_verification.csv`, Table 4.11 (integration), the test bench log `10_Dashboard_Client\logs\testbench_log.csv`
   (388 records, 0 failed calls; service response median 78.6 ms, 95th percentile 95.4 ms; ML answers identical to the offline results in 388 of 388 records).

---

## 7. Other things you can re-run (optional)

| Task | Command |
|---|---|
| Whole Python test suite | `06_Python_ML\.venv\Scripts\python.exe -I -m pytest -q` (154 tests passed on 17 Oct 2026, including the API tests) |
| Rebuild all Chapter 4 tables and figures | `06_Python_ML\.venv\Scripts\python.exe -I 06_Python_ML\src\analysis\make_chapter4.py` (add `--check` to compare with saved results) |
| Conventional-method MATLAB tests | in MATLAB: `cd 04_MATLAB_Conventional\tests` then `runtests` |
| Dashboard checks (service must be running) | `cd 10_Dashboard_Client` then `verify_step43` (master control, freeze fix, explanation text; also runs `verify_step39` and `verify_step40`) |
| Full test bench over 388 records (service must be running) | `cd 10_Dashboard_Client` then `T = run_testbench;` (writes `logs\testbench_log.csv`) |
| Rebuild the Simulink model from code | `cd 05_Simulink_Model` then `build_Transformer_Operating_Model` |

**Do not re-run** `step22_final_fit.py` or any step that opens the test sets again: it is blocked on purpose (the test sets were opened once and logged in `11_Results\ml\test_set_access.log`).

---

## 8. Limits to state honestly when presenting

- The Simulink model is **operating context only** (electrical load, oil and hot-spot temperature, ageing). It does not generate or predict gas values; gas values always come from real measured records.
- Thermal constants are default values of an open-source implementation and the electrical data are typical values (pandapower 40 MVA 110/20 kV), not a nameplate of a real transformer. IEC 60076-7:2018 was not obtained, so these are marked TO VERIFY. Scenario loads and sampling times are illustrative.
- The Simulink check is **verification** against the IEC equations, not validation against measurements.
- The dashboard and service are a local test bench (no login, one computer), not a networked product.
- Research result: the hypothesis that ML beats the conventional methods is **not supported** on the main benchmark (IEC TC 10); it is partly supported on the internal and Li 2019 test sets (see thesis Chapter 4).

---

## 9. Quick copy-paste summary

MATLAB:
```matlab
cd C:\DGA_Project
project_setup
DGADashboard                               % the app
open_system('Transformer_Operating_Model') % the Simulink model (press Run)
```
