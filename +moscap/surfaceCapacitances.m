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
CsHF = gamma * abs(dFmaj)          / denom;   % inversion charge frozen -> Cmin

if ~isfinite(CsLF)
    CsLF = 0;
end
if ~isfinite(CsHF)
    CsHF = 0;
end
end
