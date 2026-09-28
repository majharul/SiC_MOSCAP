function [CsLF, CsHF] = surfaceCapacitances(psi, Na, ni, eps_si, Vt, q)
%SURFACECAPACITANCES Semiconductor differential capacitance from surface potential.
%   Returns the per-unit-area surface capacitance split into two limits:
%     CsLF : low-frequency  - minority (inversion) carriers follow the AC signal
%     CsHF : high-frequency - inversion charge is frozen (majority carriers only)
%
%   Both are derived analytically from the same Poisson-Boltzmann function
%   used for the DC surface charge, so no thresholds, triggers, or empirical
%   inversion weights are required. Because the DC solve already pins psi at
%   the onset of strong inversion, CsHF saturates naturally at Cmin.
%
%   p-type convention: psi > 0 depletion/inversion, psi < 0 accumulation.

gamma = real(sqrt(2 * eps_si * q * Na));
if ~isfinite(gamma) || gamma <= 0
    gamma = 1e-30;
end

u = max(min(psi / Vt, 200), -200);
ep = exp(u);        % minority (electron) Boltzmann factor
en = exp(-u);       % majority (hole)     Boltzmann factor

r2 = (ni / Na) ^ 2;
r2 = max(min(r2, 1), 0);

% F = majority(accumulation+depletion) + minority(inversion)
Fmaj = en + u - 1;
Fmin = r2 * (ep - u - 1);
F = max(Fmaj + Fmin, 1e-300);

% dF/du contributions
dFmaj = 1 - en;              % majority carriers - respond at all frequencies
dFmin = r2 * (ep - 1);       % minority carriers - frozen out at high frequency

denom = 2 * sqrt(Vt * F);
if ~isfinite(denom) || denom <= 0
    CsLF = 0;
    CsHF = 0;
    return;
end

CsLF = gamma * abs(dFmaj + dFmin) / denom;   % full quasi-static response

% Conventional high-frequency C-V freezes the incremental minority charge
% and limits the depletion width at strong inversion. Dividing dFmaj by
% the full F (including equilibrium inversion charge) incorrectly drives
% CsHF toward zero. Evaluate the majority-carrier derivative and hold it
% at psi_s = 2*phiF, which gives the physical Cmin plateau.
phiF = Vt * log(max(Na / max(ni, realmin), 1));
psiInv = max(2 * phiF, 10 * eps(Vt));
psiHF = min(psi, psiInv);
uHF = max(min(psiHF / Vt, 200), -200);
FmajHF = max(exp(-uHF) + uHF - 1, 0);
dFmajHF = 1 - exp(-uHF);
if FmajHF < 1e-16
    CsHF = gamma / sqrt(2 * Vt);  % flat-band Debye-capacitance limit
else
    CsHF = gamma * abs(dFmajHF) / (2 * sqrt(Vt * FmajHF));
end

if ~isfinite(CsLF)
    CsLF = 0;
end
if ~isfinite(CsHF)
    CsHF = 0;
end
end
