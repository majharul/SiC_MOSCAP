# 4H-SiC MOSCAP high-frequency C-V review

## Fact-check verdict

A conventional high-frequency MOS-capacitor C-V trace remains at the low
minimum capacitance, `Cmin`, in strong inversion because the small-signal
minority-carrier charge cannot follow the AC excitation. This is not unique
to SiC. The DC sweep must still be slow enough to establish equilibrium;
then the depletion width is limited at strong inversion and the HF curve
forms a plateau. NIST describes this distinction explicitly in its dynamic
MOS C-V guidance: [NBS Special Publication 400-17](https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nbsspecialpublication400-17.pdf).

4H-SiC can show a further decrease below the equilibrium `Cmin` (deep
depletion) because its minority-carrier supply is exceptionally weak. That
behavior depends on DC sweep rate, illumination, temperature, leakage, and
wait time. It is not identifiable from one 1 MHz C-V trace. Appropriate SiC
methods use pulsed C-V or capacitance transients; see
[Marinella et al., IEEE TED 2010](https://doi.org/10.1109/TED.2010.2051196)
and [Cheong et al., IEEE TED 2003](https://doi.org/10.1109/TED.2003.813346).

Also, 1 MHz is not necessarily trap-free at the SiO2/4H-SiC interface.
Very fast interface states can respond at and above this frequency, so a
single lumped `Dit` inferred from only one HF curve is not defensible. See
[Yoshioka et al., Journal of Applied Physics 2012](https://doi.org/10.1063/1.3673572)
and [Yoshioka et al., Journal of Applied Physics 2012](https://doi.org/10.1063/1.4740068).

## Problems found in the previous workflow

1. `surfaceCapacitances.m` removed the minority derivative but retained the
   total inversion term in its denominator. This forced `CsHF` toward zero
   as equilibrium inversion charge increased, despite comments claiming a
   `Cmin` plateau. The implementation now freezes the depletion response at
   `psi_s = 2 phi_F` for the conventional equilibrium HF limit.
2. The SiC doping bounds stopped at `5e15 cm^-3`, while the old optimizer
   searched well above that. Most of its search interval was silently
   clipped and therefore had zero sensitivity. The bounds now cover
   `1e14` through `1e19 cm^-3`.
3. The old intrinsic density was `1e4 m^-3 = 1e-2 cm^-3`, while its comment
   called it `1e-10 cm^-3`. Using `Eg = 3.26 eV`, `Nc = 1.66e19 cm^-3`, and
   `Nv = 3.19e19 cm^-3` gives approximately `1e-8 cm^-3 = 1e-2 m^-3` at
   300 K. The value and units are now consistent.
4. The Gaussian implant was averaged across the arbitrary simulation depth
   `xmax`. That is not a unique electrostatic reduction and can lower the
   apparent concentration by orders of magnitude. The solver now accepts
   `Na_eff_override`, explicitly identifying the uniform effective doping
   used by its Poisson-Boltzmann equation.
5. The prior optimizer fitted `tau_gen`, `Dit`, and `tau_it` to one or two
   normalized curves. Those parameters are not independently observable in
   a single HF trace. With normalized data, active area and absolute oxide
   capacitance are intentionally absent, and `Na,eff` remains coupled to the
   independently supplied oxide thickness.
6. `example_sic_cv_realistic.csv` contains dimensionless `C/max(C)`, not pF
   and not capacitance divided by an independently calculated `Cox`.
   Its headers and loader configuration now state that explicitly, preventing
   an erroneous additional `1e-12` scale factor. The other legacy example
   still mixes raw farad-like values and normalized columns and should not be
   used without first repairing its schema.
7. Material consistency previously forced positive `Qox` and a nonzero
   `Dit` whenever 4H-SiC was selected. Fixed charge is signed, and an ideal
   reference may set both terms to zero, so those artificial floors were
   removed.
8. JSON loading used field names different from JSON saving (`xox/tox`,
   `Vfb/phi_ms`, and `Cpar/Cpar_pF`) and silently lost the fitted effective
   doping. The save/load mapping now round-trips the HF fit parameters.

## Revised fitting workflow

`optimize_SiC_CV_fit.m` now uses a dedicated HF-only extractor. It fits:

- uniform effective doping `Na_eff_override` from depletion shape and `Cmin`;
- flat-band voltage `Vfb` from horizontal position.

For `example_sic_cv_realistic.csv`, both the measured and simulated 1 MHz
traces are divided by their own maximum. This removes all absolute
capacitance information. The doping result remains conditional on the
configured `tox = 50 nm`; normalized C-V alone cannot separate oxide
thickness from substrate doping or determine active area.

The separate `example_sic_hf_measurement_like.csv` remains an explicitly
synthetic absolute-capacitance regression case for testing the pF workflow.

For a complete physical extraction, accompany normalized C-V with:

- de-embedded parallel capacitance and conductance;
- exact AC frequency, amplitude, DC sweep rate/direction, delay, and
  temperature;
- independently measured oxide thickness (and area for absolute C-V); and
- dark/illuminated measurement conditions.

Only add trap parameters after supplying multifrequency `C-V/G-V` data.
Only extract generation dynamics after supplying multiple sweep rates,
`C-t`, or pulsed C-V data.

## Remaining limitations

- The DC electrostatics use a uniform, nondegenerate, fully ionized
  Poisson-Boltzmann model. Incomplete acceptor ionization and compensation
  can matter in 4H-SiC.
- The Gaussian implant is not solved self-consistently as a nonuniform
  Poisson problem; `Na_eff_override` is a compact effective parameter.
- Interface and border traps remain lumped capacitances rather than an
  energy-resolved complex admittance.
- The `tau_gen` frequency blend is a sensitivity model, not an SRH transient
  or sweep-rate model. It must not be reported as measured lifetime.
- Series resistance is represented by a simple capacitance attenuation, not
  a full measured complex-impedance correction.
- Poly depletion is a fixed series capacitance in the current model; its
  gate-bias dependence and the distinction between metal and polysilicon
  gates are not modeled.
