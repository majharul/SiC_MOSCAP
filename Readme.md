# MOSCAP C-V Model

A modular MATLAB framework for simulating MOS capacitor C-V characteristics with surface-potential physics, Si and 4H-SiC material support, and non-ideal effects such as interface traps, border traps, poly depletion, and series resistance.

## What It Does

- Solves the semiconductor surface potential with a damped Newton method
- Uses a Poisson-Boltzmann charge model for accumulation, depletion, and inversion
- Includes SiC-specific non-ideal behavior driven by `Dit`, carrier generation, frequency dispersion, and fixed oxide charge
- Compares simulation against measured C-V data
- Provides both batch execution and an interactive MATLAB GUI

## Core Equations

Gate-voltage relation:

```text
V_G = V_FB + psi_s - Q_s(psi_s) / C_ox'
```

Flat-band voltage:

```text
V_FB = phi_MS - Q_ox / C_ox'
```

Oxide capacitance density:

```text
C_ox' = epsilon_ox / t_ox
C_ox = C_ox' * A
```

Surface charge:

```text
Q_s(psi_s) = -sign(psi_s) * sqrt(2 * epsilon_Si * q * N_A * V_T * F(psi_s))
```

with:

```text
F(psi_s) = exp(-psi_s / V_T) + psi_s / V_T - 1
         + (n_i / N_A)^2 * (exp(psi_s / V_T) - psi_s / V_T - 1)
```

Measured capacitance model:

```text
C_total = (C_ox,eff * (C_s + C_it + C_bt)) / (C_ox,eff + C_s + C_it + C_bt) + C_par
C_meas  = C_total / (1 + (omega * R_s * C_total)^2)
```

## Material Support

Supported materials:

- Silicon (Si)
- 4H-SiC

Material-dependent properties include:

- dielectric constant
- intrinsic carrier concentration
- doping bounds
- generation/recombination defaults
- inversion-response tuning for SiC

## Main Files

- `main_moscap_app.m`: main entry point
- `+moscap/defaultParameters.m`: default parameter set
- `+moscap/simulateMosCapCV.m`: core solver
- `+moscap/launchMosCapGui.m`: interactive GUI
- `+moscap/plotSimulationOnly.m`: static plots
- `+moscap/printModelReview.m`: console summary
- `+moscap/printValidationReport.m`: validation checks

## Usage

Run from MATLAB:

```matlab
main_moscap_app
```

Or use the legacy wrapper:

```matlab
capacitor_model
```

## GUI Features

- Material switching between Si and 4H-SiC
- Real-time parameter updates
- Measured data import
- Model vs measurement overlay
- Low-frequency and high-frequency C-V views

## Validation Focus

The validation report checks:

- Newton convergence
- capacitance bounds
- accumulation behavior
- depletion minimum
- measurement consistency
- material-dependent parameter limits

## Notes on SiC Behavior

For 4H-SiC, inversion is strongly affected by trap dynamics and minority-carrier generation. The model therefore separates low-frequency and high-frequency responses so the U-shaped branch and the depletion-limited branch can both be inspected from the same surface-potential solution.

## Repository Layout

```text
C_V/
+-- capacitor_model.m
+-- main_moscap_app.m
+-- +moscap/
    +-- defaultParameters.m
    +-- simulateMosCapCV.m
    +-- qsurfaceAndDerivative.m
    +-- enforceMaterialConsistency.m
    +-- materialProperties.m
    +-- materialNaBounds.m
    +-- drawCurves.m
    +-- plotSimulationOnly.m
    +-- printModelReview.m
    +-- printValidationReport.m
    +-- launchMosCapGui.m
```

## Requirements

- MATLAB R2021b or newer
- No external toolboxes required

## Author

mi031

Last updated: July 2026
