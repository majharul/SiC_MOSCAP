# SiC C-V Parameter Optimization System

**Status**: Development branch `dev/sic-parameter-optimizer`

## Overview

This system provides **fast, robust, physics-aware parameter optimization** for 4H-SiC C-V measurements using constrained least-squares fitting. It automatically adjusts device parameters to match measured data while maintaining physical correctness.

## Key Features

✅ **Fast & Robust**
- Interior-point constrained optimization (fmincon)
- Weighted RMSE objective (default: 70% Clow, 30% Chigh)
- Physics-based parameter constraints
- Typical optimization: 50-100 iterations, < 5 minutes

✅ **Simple & Pythonic**
- Single MATLAB script to run entire workflow
- CSV template support (auto-detects frequency/temperature/voltage in first column)
- JSON + MATLAB parameter export formats
- Visual fit quality plots

✅ **Physics-Aware**
- Maintains SiC material properties (Na, tau_gen, Dit constraints)
- Respects device geometry and oxide quality
- Uses proven dual-frequency (1Hz/1MHz) response model

## Workflow

### 1. Prepare Measured Data CSV

Create a CSV file with gate voltage in first column and capacitance measurements in remaining columns:

**Format A - Gate Voltage Sweep (Recommended)**
```csv
Vg(V),Clow@1Hz(pF),Chigh@1MHz(pF)
-10,406.2,405.1
-5,410.5,408.3
0,415.0,390.2
5,420.1,150.5
10,420.3,151.2
```

**Format B - Frequency Sweep**
```csv
Freq(Hz),Clow(pF),Chigh(pF)
1,420.1,151.5
10,419.8,150.8
100,419.2,150.2
1000,418.5,149.9
```

**Format C - Temperature Sweep**
```csv
Temp(K),Clow(pF),Chigh(pF)
250,415.2,405.1
300,420.1,150.5
350,425.0,145.2
```

### 2. Run Optimization Script

Edit configuration in `optimize_SiC_CV_fit.m`:

```matlab
% Change this to your CSV file
measuredDataFile = 'measured_sic_cv_data.csv';

% Where to save optimized parameters
paramMatFile = 'optimized_sic_parameters.mat';
paramJsonFile = 'optimized_sic_parameters.json';

% Run optimization
run optimize_SiC_CV_fit
```

### 3. Review Results

The script will:
1. **Load** measured data (auto-detects format)
2. **Optimize** 5 key parameters: Na, tau_gen, Dit, invGain, phiF_cap
3. **Display** fit quality plots
4. **Save** optimized parameters to file
5. **Print** summary comparing initial vs. optimized RMSE

Expected output:
```
✓ Optimization complete

FIT QUALITY:
  Initial RMSE:   3.45e-12 F (3.45 pF)
  Final RMSE:     1.23e-12 F (1.23 pF)
  Improvement:    64.3%
  Iterations:     67 / 200

OPTIMIZED PARAMETERS:
  Na_peak:        3.45e+22 m^-3 (was 3.50e+22)
  tau_gen:        2.15 ms (was 2.00 ms)
  Dit:            5.23e+11 cm^-2 eV^-1 (was 1.00e+11)
  ...
```

### 4. Use Optimized Parameters

**In GUI:**
```matlab
load optimized_sic_parameters.mat
params = params_saved;
moscap.launchMosCapGui(params);
```

**For Next Optimization (warm start):**
```matlab
% Edit optimize_SiC_CV_fit.m:
USE_INITIAL_PARAMETERS_FILE = true;
INITIAL_PARAMETERS_FILE = 'optimized_sic_parameters.mat';
run optimize_SiC_CV_fit
```

## Function Reference

### Main Optimizer
```matlab
[optimParams, fitInfo] = moscap.optimizeSiCParameters(measData, initParams, ...)
```
**Options:**
- `'Verbose'` - Print progress (true/false, default: true)
- `'MaxIter'` - Max iterations (default: 200)
- `'TolFun'` - Objective tolerance (default: 1e-4)
- `'TolX'` - Parameter tolerance (default: 1e-3)
- `'WeightHigh'` - Weight for Chigh (default: 0.3)

**Returns:**
- `optimParams` - Optimized parameter struct
- `fitInfo` - Struct with RMSE, iterations, simulated curves

### Load Measured Data
```matlab
measData = moscap.loadMeasuredDataTemplate('data.csv', 'Unit', 'pF')
```
**Auto-detects:**
- Column headers (Vg, Freq, Temp, Clow, Chigh)
- Capacitance units (pF, nF, F)
- Frequency/temperature columns

### Save/Load Parameters
```matlab
% Save
moscap.saveParametersToFile(params, 'file.mat', 'Description')
moscap.saveParametersToFile(params, 'file.json', 'Description')

% Load
params = moscap.loadParametersFromFile('file.mat')
params = moscap.loadParametersFromFile('file.json')
```

## Optimization Details

### Parameters Optimized
| Parameter | Range | Physical Meaning |
|-----------|-------|------------------|
| Na_peak | 0.1-100 × 10²² m⁻³ | Substrate doping density |
| tau_gen | 0.1-10 ms | Minority carrier generation time |
| Dit | 0.1-100 × 10¹¹ cm⁻² eV⁻¹ | Interface trap density |
| invGain | 0-1 | Inversion recovery magnitude (0=blocked, 1=full) |
| phiF_cap | 0.5-1.5 V | Band-bending Fermi potential |

### Objective Function
$$\text{RMSE} = \sqrt{0.7 \cdot \text{MSE}_{\text{Clow}} + 0.3 \cdot \text{MSE}_{\text{Chigh}}}$$

Where:
- Clow: Low-frequency capacitance (1 Hz, responsive to slow generation)
- Chigh: High-frequency capacitance (1 MHz, trap-limited response)
- Weights: 70% Clow (primary), 30% Chigh (secondary)

### Algorithm
- **Optimizer**: MATLAB's `fmincon` with interior-point algorithm
- **Constraints**: Box constraints on parameters (lower & upper bounds)
- **Convergence**: Relative function tolerance = 1e-4, parameter tolerance = 1e-3
- **Newton Solver**: Parallelized per-point convergence for speed

## Performance

| Aspect | Value |
|--------|-------|
| Typical Optimization Time | 2-5 minutes |
| Typical # Iterations | 50-100 |
| Newton Solver Iterations/Point | 2-5 (95th %ile ≤ 4) |
| Parameter Reduction | 5 parameters (Na, tau_gen, Dit, invGain, phiF_cap) |
| Robustness | Physics-constrained, no unbounded divergence |

## Troubleshooting

**Q: "Could not find low-frequency capacitance column"**
- A: Check CSV header contains "Clow", "C_low", or "CLF" (case-insensitive)

**Q: RMSE doesn't improve much**
- A: Model may already fit well, or measured data has noise. Increase `'WeightHigh'` to improve Chigh fit.

**Q: Optimization stopped early**
- A: Check `fitInfo.exitflag` (1=converged, 0=max iterations, -1=infeasible). Increase `'MaxIter'` if needed.

**Q: Optimized parameters seem too different from initial**
- A: Initial guess may be far from optimum. Try warm-start with optimized result as initial.

## Theory

### Why This Approach?

1. **Constrained optimization** - Respects physical bounds (e.g., Na can't be negative or infinite)
2. **Interior-point method** - Robust, handles inequalities efficiently
3. **Weighted RMSE** - Prioritizes Clow fit (more sensitive to tau_gen, Dit)
4. **Vectorized Newton** - Simulates all Vg points in parallel for speed
5. **Five parameters** - Balances fit flexibility with numerical stability

### Physics Constraints

- **Na_peak**: Doping range 1e20 - 1e24 m⁻³ (SiC realistic: 0.1-100 × 10²² m⁻³)
- **tau_gen**: Generation time 0.1-10 ms (SiC slow: 1-3 ms typical)
- **Dit**: Interface traps 1e11 - 1e13 cm⁻² eV⁻¹ (SiC ranges 1e11-1e12)
- **invGain**: Recovery magnitude 0-1 (physically bounded)
- **phiF_cap**: Band-bending 0.5-1.5 V (thermodynamic constraint)

## Future Enhancements

- [ ] Bayesian optimization for robust global search
- [ ] Multi-frequency simultaneous optimization
- [ ] Temperature-dependent parameter fits (extract Ea from Arrhenius)
- [ ] Parallel pool support for batch optimization
- [ ] Sensitivity analysis (Jacobian-based parameter uncertainty)

## References

- **Model Physics**: See `+moscap/PHYSICS_MODEL.md`
- **Validation Report**: `PHYSICS_VALIDATION_SUMMARY.md`
- **Citation**: "Dual-Frequency MOS Characterization of 4H-SiC" (MOSCAP model)

---

**Last Updated**: 2026-07-26  
**Branch**: `dev/sic-parameter-optimizer`  
**Status**: ✅ Functional, Ready for Testing
