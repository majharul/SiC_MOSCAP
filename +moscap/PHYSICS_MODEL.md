% MOSCAP C-V Physics Model - Comprehensive Implementation Guide
% ================================================================
%
% STRUCTURE: n-poly | SiO2 | p-well (all capacitively coupled)
%
% 1. CORE ELECTROSTATICS (Material-Independent)
% =====================================================
%
% Surface Potential Solver:
%   Solve implicit equation: Vfb + ψ_s - Qs(ψ_s)/Cox_area = Vg_eff
%   Using damped Newton-Raphson iteration (80 iterations max per Vg point)
%   
%   where:
%   - Vfb = flat-band voltage = φ_ms - Qox/Cox_area
%   - φ_ms = gate/semiconductor work-function difference (default -1.1 V for Al on p-Si;
%            ~+0.8 V for poly on p-type SiC). Fitted as a flat-band shift knob.
%   - Qox = fixed oxide charge (parameterized as Qox_m2 × area)
%   - ψ_s = surface potential at SiO2/semiconductor interface
%   - Qs(ψ_s) = charge density from Poisson-Boltzmann equation
%
% Surface Charge (Poisson-Boltzmann):
%   Qs = -sign(ψ_s) × √(2·εSi·q·Na) × √(Vt·F(ψ_s))
%   where F(ψ_s) is the Boltzmann integral:
%   F(ψ_s) = exp(-ψ_s/Vt) + (ψ_s/Vt) - 1 + (ni/Na)² × [exp(ψ_s/Vt) - (ψ_s/Vt) - 1]
%   
%   - exp terms: electron and hole concentrations far from surface
%   - (ni/Na)² term: handles weak inversion and intrinsic carrier effects
%   - For Si: ni ≈ 1.45×10^16 m^-3 (small compared to Na) → strong band bending
%   - For 4H-SiC: ni ≈ 10^-2 m^-3 at 300 K → extreme band bending needed for inversion
%
% Semiconductor Capacitance (two-limit split, +moscap/surfaceCapacitances.m):
%   Low-frequency  (minority carriers respond):  Cs_LF ∝ |dF/du|        (u = ψ_s/Vt)
%   High-frequency (inversion charge frozen): majority-carrier response is
%     evaluated up to ψ_s = 2·φ_F and then held at the maximum-depletion value,
%     producing the conventional equilibrium Cmin plateau.
%   Frequency blend: Cs(ω) = Cs_HF + gen(ω)·(Cs_LF - Cs_HF),  gen(ω) = 1/(1+(ω·τ_gen)²)
%
% Total Oxide Capacitance Network:
%   Cox_eff = parallel(Cox, Cpoly)  [poly depletion in series with oxide]
%   
%   Cox = εox/tox × Area  [ideal MOS oxide]
%   Cpoly = εSi/Wpoly    [poly-Si depletion width from psi_poly]
%
% Parallel Combination (Accumulation, Depletion, Inversion):
%   Ceff_parallel = (Cox_eff × (Cs + Cit + Cbt)) / (Cox_eff + Cs + Cit + Cbt) + Cpar
%   
%   - Accumulation: Cs >> Cox → Ceff → Cox (holes fill surface)
%   - Depletion: Cs drops ~ √V → Ceff drops
%   - Inversion: Cs >> Cox again IF minority carriers respond (depends on tau_gen)
%
% 2. NON-IDEAL EFFECTS (Material-Independent)
% =====================================================
%
% Interface Traps (Dit):
%   Frequency response: Cit(ω) = q·Dit / (1 + (ω·τ_it)²)
%   - High frequency (ω → ∞): Traps cannot respond, Cit → 0
%   - Low frequency (ω → 0): Traps fully charged/discharged, Cit → q·Dit
%   - Parameterization: Dit_cm2eV in cm^-2 eV^-1 (standard units)
%
% Border Traps (Cbt):
%   Similar to Dit but with shorter time constant (τ_bt << τ_it)
%   Often represents rapid oxide-semiconductor interface states
%
% Parasitic Capacitance (Cpar):
%   Additive capacitance from metal overlap, fringing, substrate coupling
%   Cpar = constant (frequency-independent)
%
% Series Resistance (Rs):
%   Impedance: Z_Rs(ω) = Rs (resistive, frequency-independent)
%   Measured capacitance (impedance network model):
%   Cmeas = Cintrinsic / (1 + (ω·Rs·Cintrinsic)²)
%   
%   Effect: High-frequency attenuation and phase lag
%
% (The former empirical "stretch-out factor" has been removed: C-V broadening now
%  arises from the physical Dit/border-trap terms and the surface-potential solution.)
%
% 3. MATERIAL-SPECIFIC BEHAVIOR
% =====================================================
%
% SILICON (Si):
% -----------
% - ni = 1.45×10^16 m^-3  (strong intrinsic carrier generation at 300K)
% - εr = 11.7
% - Na_peak = 1-10×10^23 m^-3 (typical commercial substrates)
% - τ_gen ~ 5-10 μs (minority carrier generation/recombination time)
% - τ_it ~ 100 ns (interface traps respond quickly)
%
% C-V BEHAVIOR:
%   Accumulation (Vg << Vfb):
%     ψ_s < 0 (p-type substrate, holes at surface)
%     Cs ~ Cox → Ceff ≈ Cox_eff
%     Ceff recovery to Cox_eff: YES (strong accumulation)
%
%   Depletion (Vfb < Vg < Vg_inv):
%     ψ_s ≈ 0 → ψ_s > 0 (surface depletes, then electron inversion forms)
%     Cs drops from ∞ to minimum
%     Ceff drops (depletion effect dominates)
%
%   Inversion (Vg >> Vfb + 2·φ_F):
%     ψ_s > 2·φ_F (surface becomes n-type)
%     High freq → inversion charge is AC-frozen, so Ceff stays at Cmin
%     Low freq  → inversion charge can respond, so Ceff → Cox_eff
%     Low-Freq C-V: C_LF ≈ Cox in inversion (classic Si behavior)
%     High-Freq C-V: C_HF << Cox at the equilibrium Cmin plateau
%
% PHYSICAL REASONING:
%   At low frequency, thermal generation rate ~1/(τ_gen) generates minority carriers fast enough
%   to screen applied voltage → surface accumulates inversion charge → Cs → ∞ → C_total → Cox
%
% 4H-SiC:
% --------
% - ni ~ 10^-2 m^-3 at 300 K (very small equilibrium carrier density)
% - εr = 9.7
% - Na must be reported in unambiguous units and extracted for the device
% - Generation and trap time constants require transient/multifrequency data
%
% C-V BEHAVIOR:
%   Accumulation: Same as Si (holes abundant, no generation needed)
%     C_LF ≈ C_HF ≈ Cox_eff
%
%   Depletion: Similar to Si (band bending, Cs drops)
%
%   Inversion (Vg >> Vfb + 2·φ_F):
%     Conventional equilibrium HF C-V remains at Cmin. A faster DC sweep
%     than the minority-carrier supply can support may cause nonequilibrium
%     deep depletion below Cmin. Establishing that mechanism requires C-t,
%     pulsed C-V, illumination, temperature, or sweep-rate measurements.
%
% IMPORTANT IDENTIFIABILITY LIMIT:
%   A single HF trace cannot extract generation lifetime. The implemented
%   tau_gen frequency blend is a compact sensitivity model, not a transient
%   SRH solution and not evidence of deep depletion by itself.
%
% 5. PARAMETER EXTRACTION & PDK CALIBRATION
% =====================================================
%
% Measured Quantities:
%   - C_LF(Vg): Measured at low frequency (e.g., 1 Hz)
%   - C_HF(Vg): Measured at high frequency (e.g., 1 MHz)
%   - Vfb_exp: Flat-band voltage extracted from C_HF curve (dC/dVg = 0 in depletion)
%
% Extraction Procedure:
%   1. Set initial Na, tox, φ_ms from process spec
%   2. Simulate C_HF(Vg) at fixed frequency (e.g., 1 MHz)
%   3. Fit Vfb by varying Qox_m2 until simulated Vfb_sim = Vfb_exp
%   4. Fit Na_eff by varying Na_peak until depletion slope matches
%   5. Fit Dit, Cbt by matching LF-HF difference in depletion region
%   6. Fit tau_gen, tau_it by frequency sweep 1 Hz - 10 MHz
%   7. Verify inversion behavior (should match material physics)
%
% Material Presets (Built-in):
%   Si:
%     Na_peak = 5e23 m^-3
%     tau_gen = 5-10 μs
%
%   4H-SiC RUN2-2022 (Cree/Wolfspeed typical):
%     Na_peak = 1e15 m^-3 (≈10 μm depletion width!)
%     tau_gen = 3 ms
%   
%   ...other SiC processes with different depth/doping tradeoffs
%
% 6. NUMERICAL STABILITY & IMPLEMENTATION NOTES
% =====================================================
%
% Complex Number Avoidance:
%   - sqrt(Vt·F) can produce imaginary if F < 0
%     → SOLUTION: Guard F ≥ 1e-30, extract real parts
%   - sign(psi) has a branch at psi = 0
%     → Uses a hard sign() with psi=0 defaulting to +1 (a smooth tanh sign was
%       found to create a non-physical W-shaped artifact and was removed)
%   - exp(psi/Vt) overflow for large band bending
%     → eta = psi/Vt is clamped to ±200 (safe from overflow; large enough that SiC
%       pins on physics, not on the clamp)
%   - Denominator in parallel formula can be zero
%     → SOLUTION: Check and replace with small positive value
%
% Newton Convergence:
%   - Damped line search if ||f_new|| > ||f_old||
%   - Reduce step size until residual decreases
%   - Max 120 iterations (usually 2-5 needed per point)
%
% Frequency Sweep Implementation:
%   Two curves computed per Vg point:
%   - C_LF: Computed at low frequency (e.g., lfFreqHz = 1 Hz)
%     Represents measurement at slow response time scale
%   - C_HF: Computed at high frequency (e.g., hfFreqHz = 1 MHz)
%     Represents measurement at fast response time scale
%   
%   Both share same surface potential ψ_s but have different trap/generation responses
%
% 7. PHYSICAL VALIDATION CHECKLIST
% =====================================================
%
% ✓ Accumulation plateau: C_HF ≈ Cox_eff within ±15%
% ✓ Depletion dip: C_HF drops monotonically, reaches minimum before inversion
% ✓ Minimum capacitance location: Near Vg = Vfb + 2·φ_F (band bending = 2ψ_B)
% ✓ Inversion behavior:
%     Si: C_LF → Cox_eff, C_HF << Cox_eff (distinct high-freq depletion)
%     SiC: C_LF ≈ C_HF << Cox_eff (weak generation, no inversion)
% ✓ Newton convergence: < 5 iterations typical, max 120
% ✓ Series resistance effect: C_meas < C_intrinsic at high freq
% ✓ No NaN/Inf values in output arrays
%
% ================================================================
