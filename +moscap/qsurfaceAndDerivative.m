function [Qs, dQs] = qsurfaceAndDerivative(psi, Na, ni, eps_si, Vt, q)
%QSURFACEANDDERIVATIVE Implicit semiconductor surface charge via Poisson-Boltzmann.
%   Computes surface charge density and its derivative w.r.t. surface potential.
%   Ensures all calculations remain real and well-conditioned.

gamma = real(sqrt(2 * eps_si * q * Na));
if ~isfinite(gamma) || gamma <= 0
    gamma = 1e-30;
end

eta = max(min(psi / Vt, 200), -200);
exp_pos = exp(eta);
exp_neg = exp(-eta);

ni_ratio_sq = (ni / Na) ^ 2;
ni_ratio_sq = max(min(ni_ratio_sq, 1), 0);

F = exp_neg + eta - 1 + ni_ratio_sq * (exp_pos - eta - 1);
F = max(F, 1e-300);
if ~isfinite(F)
    F = 1e-300;
end

dF = (-exp_neg + 1 + ni_ratio_sq * (exp_pos - 1)) / Vt;

% Use hard sign function (psi > 0 → Qs negative; psi < 0 → Qs positive)
% Smooth tanh sign was creating nonphysical W-shaped curve artifacts
sgn = sign(psi);
if sgn == 0
    sgn = 1;  % Default to positive for psi=0 (flatband)
end

VtF = Vt * F;
if VtF < 0
    VtF = 1e-30;
end
sqrtVtF = sqrt(VtF);
Qs = real(-sgn * gamma * sqrtVtF);
if ~isfinite(Qs)
    Qs = 0;
end

% Numerical derivative is more stable near psi ~ 0 where sign changes branch.
dpsi = max(1e-7, 1e-5 * Vt);
dQs = (qsurfaceOnly(psi + dpsi, Na, ni, eps_si, Vt, q) - ...
    qsurfaceOnly(psi - dpsi, Na, ni, eps_si, Vt, q)) / (2 * dpsi);
end

function Qs = qsurfaceOnly(psi, Na, ni, eps_si, Vt, q)
gamma = real(sqrt(2 * eps_si * q * Na));
if ~isfinite(gamma) || gamma <= 0
    gamma = 1e-30;
end

eta = max(min(psi / Vt, 200), -200);
exp_pos = exp(eta);
exp_neg = exp(-eta);

ni_ratio_sq = (ni / Na) ^ 2;
ni_ratio_sq = max(min(ni_ratio_sq, 1), 0);

F = exp_neg + eta - 1 + ni_ratio_sq * (exp_pos - eta - 1);
F = max(F, 1e-300);
if ~isfinite(F)
    F = 1e-300;
end

psiScale = max(1e-6, 1 * Vt);
sgn = sign(psi);  % Hard sign function for correct physics
if sgn == 0
    sgn = 1;  % Default to positive for psi=0
end
sgn = real(sgn);
if ~isfinite(sgn)
    sgn = 1;
end

VtF = Vt * F;
if VtF < 0
    VtF = 1e-30;
end
sqrtVtF = sqrt(VtF);
Qs = real(-sgn * gamma * sqrtVtF);
if ~isfinite(Qs)
    Qs = 0;
end
end

