# SiC C-V Parameter Optimization

**Version tag:** `dev/sic-parameter-optimizer`

This branch provides a compact MATLAB workflow for fitting 4H-SiC MOSCAP C-V data with a surface-potential model. It is intended for process analysis, parameter extraction, and comparison against measured curves.

## What the current model does well

- Solves the MOS surface potential with a damped Newton method
- Separates low-frequency and high-frequency C-V responses
- Includes SiC-relevant non-idealities:
  - interface traps
  - border traps
  - fixed oxide charge
  - generation-limited inversion
  - series resistance
- Supports measured-data overlay in the GUI
- Uses constrained fitting instead of unconstrained curve matching

## Current modeling assumption

The current SiC model is best viewed as a physics-aware compact model, not a full TCAD solver. It is designed to reproduce the main shape of measured C-V curves and to isolate which non-ideality is responsible for a given feature.

## Correctness review

### Physically sound

- Surface-potential-based electrostatics are the right foundation for both Si and SiC MOSCAPs.
- Fixed oxide charge should shift the flat-band voltage.
- Interface traps should cause stretch-out and frequency dispersion.
- Minority-carrier generation should control whether inversion appears in low-frequency response or remains suppressed in high-frequency response.
- Series resistance should distort the measured capacitance at higher frequency.

### Approximation-level items

- The present SiC implementation uses compact effective parameters, not a full energy-resolved defect spectrum.
- The generation term is an effective response model, not a full SRH transient simulator.
- The current Gaussian well profile is a compact proxy for process doping, not a full implant/activation process simulation.

### Items that should not be over-claimed

- Do not describe the SiC inversion branch as universally visible at all frequencies. In real SiC, it can disappear at high frequency because minority carriers respond slowly.
- Do not claim the model extracts unique physical defect chemistry from C-V alone. The fit is not fully identifiable without independent conductance, transient, or temperature data.
- Do not present the current compact trap model as equivalent to a full distributed energy-defect physics model.

## How to use the process context

The `docs/process.md` table is useful for:

- setting the SiC initial doping window
- choosing junction-depth and epi-layer priors
- selecting realistic oxidation and anneal-related starting points
- guiding the `Na_peak`, `Rp`, `sigma`, and `xmax` defaults

It should be used as a prior, not as a direct one-to-one replacement for the electrical model. The process table describes fabrication conditions and nominal layer parameters; the C-V solver still needs electrical fitting to match measurement.

## Recommended documentation wording

Use language like:

- physics-aware compact model
- surface-potential-based C-V framework
- effective trap and generation response
- low- and high-frequency SiC response

Avoid language like:

- exact SiC physics
- fully predictive TCAD replacement
- unique extraction of defect chemistry from C-V alone

## Suggested version note

If you want to tag the current working model in documentation, a good label is:

```text
SiC-CV compact model v0.3
```

Suggested meaning:

- `v0.1` basic surface-potential Si / SiC framework
- `v0.2` non-idealities and GUI integration
- `v0.3` low/high-frequency SiC response with process-aware presets

## Short summary for the README

The current model is physically reasonable as a compact C-V solver if it is described carefully:

- Si: expected quasi-static surface-potential behavior
- SiC: low-frequency inversion can be shown, while high-frequency response may stay depleted
- Trap, generation, and resistance effects should be treated as effective parameters unless independently validated

## Files to cite in the documentation

- `main_moscap_app.m`
- `+moscap/simulateMosCapCV.m`
- `+moscap/enforceMaterialConsistency.m`
- `+moscap/guiHelpers.m`
- `docs/process.md`
- `examples/example_measured_sic_data.csv`

## Documentation status

This note is documentation-only. No model equations or code paths are being changed here.
