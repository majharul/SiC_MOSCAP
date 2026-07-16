# MOSCAP C-V Model - Modular Architecture

## Overview
The MOSCAP C-V modeling tool has been refactored from a single ~1150-line monolithic script into a well-organized package structure (`+moscap`) for improved maintainability, readability, and code reuse.

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

**`capacitor_model.m`** (Backward-compat wrapper, ~15 lines)
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

**`simulateMosCapCV.m`** (~130 lines)
- **Input**: Parameter struct (W, L, NF, tox, Na_peak, Dit, Cbt, Cpar, stretch, tau_gen, etc.)
- **Algorithm**: Damped Newton iteration for implicit surface potential equation
  - Per gate voltage point: solve Vfb + psi_s - Qs/Cox_area = VG_eff
  - Compute semiconductor capacitance Cs from Qs derivative
  - Apply frequency response (Dit, Cbt) and inversion weighting (tau_gen)
  - Apply Rs measurement roll-off: Cmeas = Cmos / (1 + (ω*Rs*Cmos)²)
  - Smooth output via moving-mean window
- **Output**: Struct with Vg, psi, Cs, Cmos, Cmeas, Cox_eff, Na_eff, etc.

**`qsurfaceAndDerivative.m`** (~50 lines)
- Poisson-Boltzmann implicit form for semiconductor surface charge
- Handles sign change near flat-band via numerically-stable derivative
- Called per gate voltage in Newton loop

### Material Properties

**`materialProperties.m`** (~15 lines)
- Returns (eps_si, ni) for Si or 4H-SiC
- Si: εr=11.7, ni=1.45e16 m⁻³
- 4H-SiC: εr=9.7, ni=1e3 m⁻³

**`materialNaBounds.m`** (~10 lines)
- Returns [naMin, naMax] doping range per material
- Si: [5e21, 3e24] m⁻³
- 4H-SiC: [1e21, 5e23] m⁻³

**`enforceMaterialConsistency.m`** (~30 lines)
- Updates eps_si, ni, doping bounds when material changes
- Optionally resets Na_peak, tau_gen, phiF_cap to material defaults
- Clamps values to bounds and ensures physical reasonableness

### Analysis & Reporting

**`printModelReview.m`** (~30 lines)
- Displays model assumptions and physics methodology
- Shows parameter summary (tox, Na_eff, Cox, Vfb, tau_gen, Rs, etc.)

**`printValidationReport.m`** (~50 lines)
- Validates C-V characteristics:
  - Bounds check (0 ≤ Cmos ≤ 1.02·Cox)
  - Accumulation plateau near Cox_eff
  - Depletion minimum existence
  - Newton convergence quality
  - Material-consistent ni range

### Visualization

**`plotSimulationOnly.m`** (~35 lines)
- Creates 2-3 figures:
  1. C-V curves (ideal, intrinsic, measured)
  2. Surface potential vs Vg
  3. Measured vs simulated comparison (if measured data present)

**`drawCurves.m`** (~40 lines)
- `drawCurves()`: Initialize plot curves on axes
- `redrawCurves()`: Update existing curves with new simulation data

### Data I/O

**`readMeasuredData.m`** (~65 lines)
- Reads CSV/TXT with Vg (col 1) and one or more C columns
- Auto-detects units (Farads→pF if values < 1e-6)
- Interpolates missing values
- Returns struct with Vg, Ccols_pF, colNames, selectedCol

**`compareMeasured.m`** (~20 lines)
- Computes RMSE, MAE between simulated and measured C-Vg
- Interpolates simulation to measured Vg points

**`getMeasuredCgg.m`** (~8 lines)
- Extracts selected capacitance column from measured struct

### GUI

**`launchMosCapGui.m`** (~260 lines)
- Creates interactive uifigure with:
  - Top bar: Load CSV, presets, material dropdown, measured-column selector
  - Left panel: Collapsible sections (Geometry, Electrostatics, Non-Ideal) with sliders
  - Right panel: Real-time C-V plot (simulated + measured overlay)
  - Bottom: Metrics label (RMSE, MAE, material, Cmin/Cmax)
- Callbacks: slider value changes trigger re-simulation and plot update
- Preset buttons for Si and 4H-SiC material switching
- Real-time parameter tuning via slider min/max/step editor

**`private/guiHelpers.m`** (~180 lines, internal use only)
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

| Parameter  | Unit   | Default (Si)  | Default (4H-SiC) | Purpose |
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

## Backward Compatibility

✅ **Preserved**: `matlab -batch "capacitor_model"` continues to work  
✅ **Preserved**: All physics and validation logic  
✅ **Preserved**: GUI functionality and controls  
✅ **Improved**: Code organization, readability, maintainability  

## Dependencies

- MATLAB R2021b or later (uifigure with Scrollable property, uigridlayout)
- No external toolboxes required
- Native functions only: linspace, trapz, interp1, movmean, exp, log, sqrt, etc.

## Validation

After modularization, test with:
```matlab
matlab -batch "capacitor_model"
```

Expected output:
1. Physics Review header
2. Parameter Summary table
3. Validation Checks (all PASS)
4. "GUI skipped: desktop environment not available." message (in headless)

## Future Enhancements

- Separate GUI helpers into dedicated module files (not just private/guiHelpers.m)
- Create separate physics subpackage (+moscap/+physics/) for solvers
- Add unit tests for each module
- Document parameter sensitivity and optimization guidelines
- Export to SPICE compact model format

---

**Last Updated**: Modularization Complete  
**Structure**: +moscap package with 15 public functions + 1 private helper module  
**Test Status**: ✅ Headless batch execution validated
