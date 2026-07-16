function [Qs, dQs] = qsurfaceAndDerivative(psi, Na, ni, eps_si, Vt, q)
%QSURFACEANDDERIVATIVE Implicit semiconductor surface charge via Poisson-Boltzmann.
%   Computes surface charge density and its derivative w.r.t. surface potential.

gamma = sqrt(2 * eps_si * q * Na);

eta = max(min(psi / Vt, 80), -80);
exp_pos = exp(eta);
exp_neg = exp(-eta);

F = exp_neg + eta - 1 + (ni / Na) ^ 2 * (exp_pos - eta - 1);
F = max(F, 1e-30);

dF = (-exp_neg + 1 + (ni / Na) ^ 2 * (exp_pos - 1)) / Vt;

psiScale = max(1e-5, 0.4 * Vt);
sgn = tanh(psi / psiScale);

Qs = -sgn * gamma * sqrt(Vt * F);

% Numerical derivative is more stable near psi ~ 0 where sign changes branch.
dpsi = max(1e-7, 1e-5 * Vt);
dQs = (qsurfaceOnly(psi + dpsi, Na, ni, eps_si, Vt, q) - ...
    qsurfaceOnly(psi - dpsi, Na, ni, eps_si, Vt, q)) / (2 * dpsi);
end

function Qs = qsurfaceOnly(psi, Na, ni, eps_si, Vt, q)
gamma = sqrt(2 * eps_si * q * Na);

eta = max(min(psi / Vt, 80), -80);
exp_pos = exp(eta);
exp_neg = exp(-eta);

F = exp_neg + eta - 1 + (ni / Na) ^ 2 * (exp_pos - eta - 1);
F = max(F, 1e-30);

psiScale = max(1e-6, 0.4 * Vt);
sgn = tanh(psi / psiScale);

Qs = -sgn * gamma * sqrt(Vt * F);
end

