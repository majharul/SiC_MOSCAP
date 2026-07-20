# MOSCAP C-V Model - Modular Architecture
# Poly / SiO₂ / P-Well MOS Capacitor C-V Model

## 1. Device Structure

The capacitor structure is:

\[
\text{Poly Gate} / \text{SiO}_2 / \text{P-Well Silicon}
\]

Device dimensions:

\[
W=100\ \mu m
\]

\[
L=400\ \mu m
\]

Area:

\[
A=W L
\]

\[
A=4\times10^{-8}m^2
\]


Oxide thickness:

\[
t_{ox}=55nm
\]


---

# 2. Material Parameters


Vacuum permittivity:

\[
\epsilon_0=8.854\times10^{-12}F/m
\]


Silicon permittivity:

\[
\epsilon_{Si}=11.7\epsilon_0
\]


Silicon dioxide permittivity:

\[
\epsilon_{ox}=3.9\epsilon_0
\]


Electron charge:

\[
q=1.602\times10^{-19}C
\]


Thermal voltage:

\[
V_T=\frac{kT}{q}
\]


At:

\[
T=300K
\]


\[
V_T=25.85mV
\]


---

# 3. Oxide Capacitance


Oxide capacitance density:

\[
C_{ox}'=\frac{\epsilon_{ox}}{t_{ox}}
\]


Total oxide capacitance:

\[
C_{ox}=C_{ox}'A
\]


For:

\[
t_{ox}=55nm
\]


\[
C_{ox}\approx25pF
\]


---

# 4. MOS Gate Voltage Relation


The gate voltage is related to surface potential by:


\[
V_G=V_{FB}+\psi_s-\frac{Q_s(\psi_s)}{C_{ox}'}
\]


where:


\[
V_{FB}=\phi_{MS}-\frac{Q_{ox}}{C_{ox}'}
\]


Parameters:

- \(V_{FB}\): flat band voltage
- \(Q_{ox}\): fixed oxide charge
- \(\phi_{MS}\): metal-semiconductor work function difference


---

# 5. Exact Semiconductor Charge Model


For a p-type substrate:


\[
Q_s=-sign(\psi_s)
\sqrt{2\epsilon_{Si}qN_A V_T F(\psi_s)}
\]


where:


\[
F(\psi_s)=
e^{-\psi_s/V_T}
+\frac{\psi_s}{V_T}-1
+
\left(\frac{n_i}{N_A}\right)^2
\left(
e^{\psi_s/V_T}
-\frac{\psi_s}{V_T}-1
\right)
\]


This equation is valid for:


- Accumulation
- Depletion
- Inversion


without region switching.


---

# 6. Surface Potential Solution


The nonlinear equation:


\[
f(\psi_s)=
V_{FB}
+\psi_s
-\frac{Q_s(\psi_s)}{C_{ox}'}
-V_G
=0
\]


is solved using Newton iteration:


\[
\psi_{n+1}
=
\psi_n
-
\frac{f(\psi_n)}
{df/d\psi}
\]


where:


\[
\frac{df}{d\psi}
=
1-
\frac{1}{C_{ox}'}
\frac{dQ_s}{d\psi_s}
\]


---

# 7. Semiconductor Capacitance


The semiconductor capacitance is:


\[
C_s=
\frac{dQ_s}{d\psi_s}
\]


The derivative:


\[
\frac{dQ_s}{d\psi_s}
=
-\frac{
\sqrt{2\epsilon_{Si}qN_A V_T}
}
{2\sqrt{F}}
\frac{dF}{d\psi_s}
\]


where:


\[
\frac{dF}{d\psi_s}
=
\frac{1}{V_T}
\left[
-e^{-\psi_s/V_T}
+1
+
\left(\frac{n_i}{N_A}\right)^2
(e^{\psi_s/V_T}-1)
\right]
\]


---

# 8. High Frequency MOS Capacitance


The intrinsic MOS capacitance:


\[
C_{MOS}
=
\frac{C_{ox}C_s}
{C_{ox}+C_s}
\]


---

# 9. Interface Trap Capacitance


Interface trap density:


\[
D_{it}
\quad
(cm^{-2}eV^{-1})
\]


Trap capacitance density:


\[
C_{it}'=qD_{it}
\]


Total trap capacitance:


\[
C_{it}=qD_{it}A
\]


Frequency dependence:


\[
C_{it}(f)
=
\frac{C_{it0}}
{1+(\omega\tau_{it})^2}
\]


where:


\[
\omega=2\pi f
\]


---

# 10. Poly Depletion Capacitance


Poly depletion width:


\[
W_{poly}
=
\sqrt{
\frac{2\epsilon_{Si}\psi_{poly}}
{qN_{poly}}
}
\]


Poly capacitance:


\[
C_{poly}
=
\frac{\epsilon_{Si}A}
{W_{poly}}
\]


Effective oxide capacitance:


\[
\frac{1}{C_{ox,eff}}
=
\frac{1}{C_{ox}}
+
\frac{1}{C_{poly}}
\]


---

# 11. Real P-Well Doping Profile


Instead of uniform doping:


\[
N_A(x)=N_0
\]


use Gaussian implant:


\[
N_A(x)
=
N_{peak}
exp
\left(
-\frac{(x-R_p)^2}
{2\sigma^2}
\right)
\]


The depletion charge becomes:


\[
Q_d
=
q
\int_0^{W_d}
N_A(x)dx
\]


---

# 12. Series Resistance Model


Measurement includes parasitic resistance:


\[
Z=R_s+\frac{1}{j\omega C_{MOS}}
\]


Measured capacitance:


\[
C_{meas}
=
\frac{C_{MOS}}
{1+(\omega R_s C_{MOS})^2}
\]


---

# 13. Complete Measured Capacitance Model


Including all non-idealities:


\[
C_{total}
=
\frac{
C_{ox,eff}(C_s+C_{it})
}
{
C_{ox,eff}+C_s+C_{it}
}
\]


The measured value:


\[
\boxed{
C_{gg}(V_G,f)
=
\frac{
C_{total}
}
{
1+(\omega R_s C_{total})^2
}
}
\]


---

# 14. Parameter Extraction


Unknown parameters from measured C-V:


| Parameter | Extracted from |
|---|---|
| \(t_{ox}\) | Accumulation capacitance |
| \(N_A\) | Depletion slope |
| \(V_{FB}\) | Flat-band voltage |
| \(D_{it}\) | C-V stretch |
| \(R_s\) | High-frequency reduction |
| \(N_{poly}\) | Poly depletion loss |


---

# 15. Final Model Flow


```text
VG
 |
 |
Solve surface potential ψs
 |
 |
Calculate Qs(ψs)
 |
 |
Calculate Cs=dQs/dψs
 |
 |
Add Cit
 |
 |
Add Poly depletion
 |
 |
Add Series Resistance
 |
 |
Output Cgg(VG,f)



## Overview
The MOSCAP C-V modeling tool for visualization of non ideal behavior for Si and SiC MOSCAP!

## Directory Structure

```
C_V/
├── capacitor_model.m           ← Backward-compatibility wrapper (calls main_moscap_app)
├── main_moscap_app.m            ← Primary entry point
├── capacitor_model.asv           ← Auto-saved version (ignore)
└── +moscap/                      ← Package directory (public namespace)
    ├── defaultParameters.m       ← Initialize all physics/material parameters
    ├── simulateMosCapCV.m        ← Core physics solver (implicit surface potential, Newton iteration)
    ├── enforceMaterialConsistency.m ← Material-aware parameter validation
    ├── materialProperties.m      ← Si/4H-SiC dielectric/carrier constants
    ├── materialNaBounds.m        ← Doping concentration bounds per material
    ├── printModelReview.m        ← Console output: model description & parameters
    ├── printValidationReport.m   ← Console output: validation checks
    ├── plotSimulationOnly.m      ← Static figure generation (C-V, psi, comparison)
    ├── drawCurves.m              ← Plot helpers (init & update curve objects)
    ├── readMeasuredData.m        ← CSV/TXT file reader with auto unit detection
    ├── compareMeasured.m         ← Error metrics (RMSE, MAE)
    ├── getMeasuredCgg.m          ← Extract selected capacitance column
    ├── qsurfaceAndDerivative.m   ← Poisson-Boltzmann surface charge solver
    ├── launchMosCapGui.m         ← Interactive GUI with collapsible sections & real-time plotting
    └── private/
        └── guiHelpers.m          ← Internal GUI utilities (sliders, specs, ternary, etc.)
```

## Module Descriptions

### Entry Points

**`capacitor_model.m`** (Backward-compat wrapper, )
- Sole purpose: call `main_moscap_app()`
- Enables: `matlab -batch "capacitor_model"` workflow
- No functionality changes; all code moved to package

**`main_moscap_app.m`** (~30 lines)
- Initialize parameters via `moscap.defaultParameters()`
- Run simulation via `moscap.simulateMosCapCV()`
- Display results via `moscap.printModelReview()` and `moscap.printValidationReport()`
- Plot via `moscap.plotSimulationOnly()`
- Launch GUI via `moscap.launchMosCapGui()` (if desktop available)

### Core Physics

**`simulateMosCapCV.m`** 
- **Input**: Parameter struct (W, L, NF, tox, Na_peak, Dit, Cbt, Cpar, stretch, tau_gen, etc.)
- **Algorithm**: Damped Newton iteration for implicit surface potential equation
  - Per gate voltage point: solve Vfb + psi_s - Qs/Cox_area = VG_eff
  - Compute semiconductor capacitance Cs from Qs derivative
  - Apply frequency response (Dit, Cbt) and inversion weighting (tau_gen)
  - Apply Rs measurement roll-off: Cmeas = Cmos / (1 + (ω*Rs*Cmos)²)
  - Smooth output via moving-mean window
- **Output**: Struct with Vg, psi, Cs, Cmos, Cmeas, Cox_eff, Na_eff, etc.

**`qsurfaceAndDerivative.m`** 
- Poisson-Boltzmann implicit form for semiconductor surface charge
- Handles sign change near flat-band via numerically-stable derivative
- Called per gate voltage in Newton loop

### Material Properties

**`materialProperties.m`** 
- Returns (eps_si, ni) for Si or 4H-SiC
- Si: εr=11.7, ni=1.45e16 m⁻³
- 4H-SiC: εr=9.7, ni=1e3 m⁻³

**`materialNaBounds.m`** 
- Returns [naMin, naMax] doping range per material
- Si: [5e21, 3e24] m⁻³
- 4H-SiC: [1e21, 5e23] m⁻³

**`enforceMaterialConsistency.m`** 
- Updates eps_si, ni, doping bounds when material changes
- Optionally resets Na_peak, tau_gen, phiF_cap to material defaults
- Clamps values to bounds and ensures physical reasonableness

### Analysis & Reporting

**`printModelReview.m`** 
- Displays model assumptions and physics methodology
- Shows parameter summary (tox, Na_eff, Cox, Vfb, tau_gen, Rs, etc.)

**`printValidationReport.m`** 
- Validates C-V characteristics:
  - Bounds check (0 ≤ Cmos ≤ 1.02·Cox)
  - Accumulation plateau near Cox_eff
  - Depletion minimum existence
  - Newton convergence quality
  - Material-consistent ni range

### Visualization

**`plotSimulationOnly.m`** 
- Creates 2-3 figures:
  1. C-V curves (ideal, intrinsic, measured)
  2. Surface potential vs Vg
  3. Measured vs simulated comparison (if measured data present)

**`drawCurves.m`** 
- `drawCurves()`: Initialize plot curves on axes
- `redrawCurves()`: Update existing curves with new simulation data

### Data I/O

**`readMeasuredData.m`** 
- Reads CSV/TXT with Vg (col 1) and one or more C columns
- Auto-detects units (Farads→pF if values < 1e-6)
- Interpolates missing values
- Returns struct with Vg, Ccols_pF, colNames, selectedCol

**`compareMeasured.m`** 
- Computes RMSE, MAE between simulated and measured C-Vg
- Interpolates simulation to measured Vg points

**`getMeasuredCgg.m`** 
- Extracts selected capacitance column from measured struct

### GUI

**`launchMosCapGui.m`** 
- Creates interactive uifigure with:
  - Top bar: Load CSV, presets, material dropdown, measured-column selector
  - Left panel: Collapsible sections (Geometry, Electrostatics, Non-Ideal) with sliders
  - Right panel: Real-time C-V plot (simulated + measured overlay)
  - Bottom: Metrics label (RMSE, MAE, material, Cmin/Cmax)
- Callbacks: slider value changes trigger re-simulation and plot update
- Preset buttons for Si and 4H-SiC material switching
- Real-time parameter tuning via slider min/max/step editor

**`private/guiHelpers.m`** 
- `addSlider()`: Create slider + label + value display in grid layout
- `sliderSpecs()`: Generate slider min/max/value/fmt from parameters
- `applySliderStep()`, `estimateSliderStep()`: Tick management
- `makePositiveSpec()`, `makeSignedSpec()`: Auto-range calculation
- `applySpecToControl()`, `applyAllSpecsToControls()`: Batch slider update
- `refreshSliderValueLabels()`: Update value labels from slider states
- `ternary()`: Conditional value selection helper

## Function Call Flow

### Typical Workflow (Batch/Headless)
```
capacitor_model
  → main_moscap_app
      → moscap.defaultParameters()
      → moscap.simulateMosCapCV(params)
      → moscap.printModelReview(params, sim)
      → moscap.printValidationReport(params, sim)
      → moscap.plotSimulationOnly(params, sim)
      → moscap.launchMosCapGui(params)  [skipped if no desktop]
```

### Interactive GUI Workflow
```
GUI slider change
  → onAnySliderChanged() callback
      → Extract slider values to params
      → moscap.enforceMaterialConsistency(params, false)
      → moscap.simulateMosCapCV(params)
      → moscap.drawCurves(ax, sim, measured)
      → updateMetricsLabel()
          → moscap.compareMeasured(sim, measured) [if data present]
```

## Key Physics Parameters

| Parameter  | Unit   | Default (Si)  | Default (4H-SiC)* | Purpose |
|-----------|--------|---------------|------------------|---------|
| W, L, NF  | μm, — | 100, 100, 74  | Same | Geometry |
| tox       | nm     | 50            | Same | Oxide thickness |
| Na_peak   | m⁻³    | 5e23          | 8e22 | Peak doping |
| Dit       | cm⁻²eV⁻¹ | 8e11         | Same | Interface traps |
| Cbt       | cm⁻²eV⁻¹ | 2e11         | Same | Border traps |
| Cpar      | pF     | 0             | Same | Parasitic capacitance |
| stretch   | —      | 1.0           | Same | C-V broadening factor |
| tau_it, tau_bt | s | 100n, 5μ      | Same | Response times |
| tau_gen   | s      | 5μ            | 2m | Inversion generation time |
| Rs        | Ω      | 3000          | Same | Series resistance |
| freq      | Hz     | 1 MHz         | Same | Measurement frequency |
-*The parameters and behaviour is still not fully valdiated!
## Backward Compatibility

 

## Dependencies

- MATLAB R2021b or later (uifigure with Scrollable property, uigridlayout)
- No external toolboxes required
- Native functions only: linspace, trapz, interp1, movmean, exp, log, sqrt, etc.

## Validation

After modularization, test with:
```matlab
matlab -batch "capacitor_model"
```



**Last Updated**: Modularization Complete  
Jul 2026 mi031 

