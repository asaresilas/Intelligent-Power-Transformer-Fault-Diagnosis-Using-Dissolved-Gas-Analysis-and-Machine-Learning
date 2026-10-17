# Simulink Simulation: Setup and Presentation Guide

Project: Intelligent Power Transformer Fault Diagnosis Using Dissolved Gas Analysis and Machine Learning (MPhil, UMaT).
Purpose of this file: set up and show **only the Simulink simulation** to the lecturer, step by step.
(For the dashboard, the ML service and the full project setup see `README_HOW_TO_RUN_AND_SETUP.md` in this folder.)

`<PROJECT>` below means the project folder, for example `C:\DGA_Project`.

---

## 1. What the simulation is (say this first)

- A Simulink/Simscape model of a **40 MVA, 110/20 kV power transformer** during operation over 24 hours.
- It calculates: load factor K, **top-oil temperature**, **hot-spot temperature** and the **ageing rate / loss of life**,
  using the thermal equations of IEC 60076-7 built as Simscape R-C circuits.
- It is **operating context only**. It never generates or predicts gas values. Gas data always come from real measured records.
- It also contains a block (SS8) that marks four **sampling times** (6, 12, 18, 22 h). At these times the dashboard diagnoses a real held-out DGA record.

File: `05_Simulink_Model\Transformer_Operating_Model.slx`

---

## 2. What you need on the computer

| Item | Requirement |
|---|---|
| MATLAB | **R2025b** (the model was saved in R2025b; older releases cannot open it) |
| Toolboxes | **Simulink, Simscape, Simscape Electrical** (check with `ver` in MATLAB) |
| Python / internet | **Not needed** for the simulation alone |
| Folder | The whole project copied to a short path, e.g. `C:\DGA_Project` (not OneDrive). Keep the numbered folder names unchanged. |

Folders the simulation uses: `05_Simulink_Model`, `04_MATLAB_Conventional`, `10_Dashboard_Client`, `03_Data\processed`.
So copy the whole project, not only the model file.

---

## 3. Setup (one time, about 5 minutes)

1. Copy the project folder to the computer (for example `C:\DGA_Project`).
2. Start MATLAB R2025b.
3. In the MATLAB Command Window type:
```matlab
cd C:\DGA_Project
project_setup
```
4. You must see: `Project paths added. Parameters loaded from params_transformer.m`
5. Check the products:
```matlab
ver                                   % list must include Simulink, Simscape, Simscape Electrical
license('test','Simscape_Electrical') % must return 1
```

Run `project_setup` again every time MATLAB is restarted.

---

## 4. Run the simulation

### Way 1 - open the model and press Run (use this in front of the lecturer)
```matlab
cd C:\DGA_Project
project_setup
open_system('Transformer_Operating_Model')
```
1. The block diagram opens. Press the green **Run** button. The 24-hour run takes about 10 seconds.
2. Open the scopes / **Simulation Data Inspector** (Simulation tab > Data Inspector) to see the signals.

### Way 2 - run from code and plot
```matlab
res = run_transformer_simulation();
figure; plot(res.t_h, res.theta_oil_C, res.t_h, res.theta_hs_C); grid on
xlabel('Time (h)'); ylabel('Temperature (\circC)'); legend('Top-oil','Hot-spot')
```
`res` also contains `K_pu` (load factor), `ageing_V` (ageing rate) and `loss_of_life_h`.

### Way 3 - the three scenarios
```matlab
cd 05_Simulink_Model
run_step36
```
Runs: (1) constant rated load, (2) daily load cycle, (3) short overload of 1.3 per unit for 2 h.
Figures are saved to `11_Results\figures\F4_19a/b/c_*`.
Expected peak hot-spot: about 100.3, 99.9 and 129.0 degC. Scenario loads are illustrative, not measured data.

---

## 5. What to point out on the diagram

| Block | Role |
|---|---|
| SS1 | 110 kV grid source |
| SS2 | 40 MVA 110/20 kV transformer |
| SS3 | Current measurement and load factor K |
| SS4 | Variable load (follows the load profile) |
| SS5 | Losses converted to heat inputs |
| SS6 | Simscape thermal network: oil and winding R-C circuits (IEC 60076-7 equations) |
| SS7 | Hot-spot temperature, ageing rate, logging of outputs |
| SS8 | Sampling events (record index and event signal only, **no gas value**) |

Every subsystem carries an annotation. All numbers come from `05_Simulink_Model\params_transformer.m` (none are typed inside blocks).
To change something (ambient temperature, thermal constants, sampling times) edit that file only, save, and run again.

Reference result at rated load from 20 degC ambient: top-oil **78.64 degC**, hot-spot **100.28 degC**, top-oil time constant **75 min**.

---

## 6. Show that the model is correct

```matlab
cd 05_Simulink_Model
verify_step35        % model vs independent solution of the IEC 60076-7 equations: 15/15 checks should PASS
verify_step37        % sampling-event block: 10/10 checks should PASS
verify_step33        % structure checks: 9 checks (7 listed expected differences)
```
Numbers to quote: after the first 10 minutes the largest difference between the model and the independent solution is
0.0014 K (top-oil) and 0.0129 K (hot-spot), against an accepted limit of 0.1 K; the 63.2 % rise time is 75.002 min (expected 75.000).
Saved results: `11_Results\tables\T4_10_simulink_verification.csv` and `11_Results\figures\F4_18_simulink_verification.png`.

---

## 7. Suggested 5-minute talk

1. (30 s) Purpose: operating context for the DGA diagnosis; no gas values are generated.
2. (1 min) Open the model, walk through SS1 to SS8 using the table in section 5.
3. (1 min) Press Run, show top-oil and hot-spot temperature and the ageing rate.
4. (1 min) Run `run_step36` or show Figure 4.19: the overload scenario reaches about 129 degC hot-spot.
5. (1 min) Verification: Figure 4.18 and the 0.1 K tolerance.
6. (30 s) State the limits (section 8).

If the computer fails, show the pictures instead: `05_Simulink_Model\figures\Figure_3_4_top_level.png` (top level),
`05_Simulink_Model\figures\diag_SS*.png` (one per subsystem) and `11_Results\figures\F4_18` and `F4_19*`.

---

## 8. Limits to state honestly

- Verification against the IEC equations, **not validation** against a real transformer's measurements.
- Thermal constants are defaults of an open-source implementation and the electrical data are typical values (pandapower 40 MVA 110/20 kV), not a real nameplate; IEC 60076-7:2018 was not obtained, so they are marked **TO VERIFY**.
- Scenario loads and the four sampling times are illustrative.
- The electrical part uses the "Frequency and time" formulation, so some arithmetic sits in ordinary Simulink blocks: the model is "Simscape networks plus Simulink arithmetic", not purely Simscape blocks.

---

## 9. Problems and fixes

| Problem | Fix |
|---|---|
| `Unrecognized function or variable 'params_transformer'` | Run `project_setup` from the project folder, then try again. |
| Simscape or Simscape Electrical "not licensed / not found" | Install the product; check with `ver`. |
| Model will not open | MATLAB is older than R2025b. |
| Odd cache errors | Close the model, delete `05_Simulink_Model\slprj` and the `.slxc` files, restart MATLAB, run `project_setup`. |
| Different numbers from the ones above | Someone changed `params_transformer.m`; restore the original from the USB copy. |
| Any other error | Send the exact error text. |

---

## 10. Copy-paste summary
```matlab
cd C:\DGA_Project
project_setup
open_system('Transformer_Operating_Model')   % then press Run
```
