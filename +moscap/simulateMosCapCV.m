function sim = simulateMosCapCV(params)
%SIMULATEMOSCAPCV Core physics solver for MOS capacitor C-V characteristics.
%   Solves implicit surface potential equation using damped Newton method,
%   then computes low-frequency and high-frequency C-V responses.

q = params.q;
k = params.k;
T = params.T;
Vt = k * T / q;

Area = params.W * params.L * params.NF;
eps_si = params.eps_si;
eps_ox = params.eps_ox;
ni = params.ni;

% Effective substrate doping from Gaussian implant profile.
x = linspace(0, params.xmax, 800);
Na_profile = params.Na_peak .* exp(-((x - params.Rp) .^ 2) ./ (2 * params.sigma ^ 2));
Na_eff = trapz(x, Na_profile) / params.xmax;
[NaMin, NaMax] = moscap.materialNaBounds(params.material);
Na_eff = min(max(Na_eff, NaMin), NaMax);

Cox_area = eps_ox / params.tox;
Cox = Cox_area * Area;

Qox = params.Qox_m2 * q;
Vfb = params.phi_ms - Qox / Cox_area;

Dit_m2eV = params.Dit_cm2eV * 1e4;
Cbt_m2eV = params.Cbt_cm2eV * 1e4;
Cit0_area = q * Dit_m2eV;
Cbt0_area = q * Cbt_m2eV;
Cpar = max(params.Cpar_pF, 0) * 1e-12;

psiPoly = max(abs(params.psi_poly), eps);
Wpoly = sqrt(2 * eps_si * psiPoly / (q * params.Npoly));
Cpoly_area = eps_si / max(Wpoly, eps);
Cpoly = Cpoly_area * Area;
Cox_eff = 1 / (1 / Cox + 1 / max(Cpoly, eps));

Vg = params.Vg;
n = numel(Vg);
psi = zeros(1, n);
Cs = zeros(1, n);
Cideal = Cox_eff * ones(1, n);
Clow = zeros(1, n);
Chigh = zeros(1, n);
CmeasLow = zeros(1, n);
CmeasHigh = zeros(1, n);
newtonIters = zeros(1, n);

lfFreqHz = 1;
hfFreqHz = 1e6;
if isfield(params, 'lfFreqHz')
    lfFreqHz = max(params.lfFreqHz, 1e-9);
end
if isfield(params, 'hfFreqHz')
    hfFreqHz = max(params.hfFreqHz, lfFreqHz * 10);
end
omegaLow = 2 * pi * lfFreqHz;
omegaHigh = 2 * pi * hfFreqHz;

for i = 1:n
    VG = Vg(i);
    if i == 1
        psi_i = 0;
    else
        psi_i = psi(i - 1);
    end
    converged = false;

    for iter = 1:120
        [Qs_i, dQs_i] = moscap.qsurfaceAndDerivative(psi_i, Na_eff, ni, eps_si, Vt, q);

        % Pure Poisson-Boltzmann: psi_s + Qs/Cox = VG - Vfb
        % Rearranged for Newton-Raphson: Vfb + psi_s - Qs/Cox - VG = 0
        f = Vfb + psi_i - Qs_i / Cox_area - VG;
        df = 1 - dQs_i / Cox_area;

        if abs(df) < 1e-18
            break;
        end

        psi_trial = psi_i - f / df;

        alpha = 1.0;
        psi_new = psi_trial;
        for ls = 1:8
            [Qs_new, ~] = moscap.qsurfaceAndDerivative(psi_new, Na_eff, ni, eps_si, Vt, q);
            f_new = Vfb + psi_new - Qs_new / Cox_area - VG;
            if abs(f_new) <= abs(f)
                break;
            end
            alpha = 0.5 * alpha;
            psi_new = psi_i + alpha * (psi_trial - psi_i);
        end

        if abs(psi_new - psi_i) < 1e-9
            psi_i = psi_new;
            converged = true;
            newtonIters(i) = iter;
            break;
        end

        psi_i = psi_new;
    end

    if ~converged
        newtonIters(i) = 120;
    end

    [~, dQs_i] = moscap.qsurfaceAndDerivative(psi_i, Na_eff, ni, eps_si, Vt, q);
    Cs_i = abs(dQs_i) * Area;

    phiF_raw = Vt * log(max(Na_eff, 1.01 * ni) / max(ni, 1e-30));
    phiF = min(max(phiF_raw, 0.05), params.phiF_cap);
    invWidth = 0.12;
    if isfield(params, 'invWidth')
        invWidth = max(params.invWidth, 0.01);
    end
    
    % Smooth inversion weight transition using tanh (gradual S-curve)
    % The tanh naturally creates a smooth step from 0 to 1 around psi_i = 2*phiF
    % Use (psi_i - 2*phiF) / invWidth where larger invWidth = smoother transition
    invWeight = 0.5 * (1 + tanh((psi_i - 2 * phiF) / invWidth));

    tauEff = max(params.tau_gen, 1e-12);
    % FIXED: genLow should ALSO depend on frequency, not always be 1!
    % This allows low-frequency inversion response to be frequency-dependent
    genLow = 1 / (1 + (omegaLow * tauEff)^2);
    genHigh = 1 / (1 + (omegaHigh * tauEff)^2);
    
    trapLow = 1 / (1 + (omegaLow * max(params.tau_it, 1e-12))^2);
    trapHigh = 1 / (1 + (omegaHigh * max(params.tau_it, 1e-12))^2);
    btrapLow = 1 / (1 + (omegaLow * max(params.tau_bt, 1e-12))^2);
    btrapHigh = 1 / (1 + (omegaHigh * max(params.tau_bt, 1e-12))^2);

    CitLow = (Cit0_area * trapLow) * Area;
    CitHigh = (Cit0_area * trapHigh) * Area;
    CbtLow = (Cbt0_area * btrapLow) * Area;
    CbtHigh = (Cbt0_area * btrapHigh) * Area;

    psi(i) = psi_i;
    Cs(i) = Cs_i;

    CbaseLow = (Cox_eff * (Cs_i + CitLow + CbtLow)) / (Cox_eff + Cs_i + CitLow + CbtLow) + Cpar;
    CbaseHigh = (Cox_eff * (Cs_i + CitHigh + CbtHigh)) / (Cox_eff + Cs_i + CitHigh + CbtHigh) + Cpar;

    Cinv_qsLow = max(Cox_eff + Cpar - CbaseLow, 0);
    Cinv_qsHigh = max(Cox_eff + Cpar - CbaseHigh, 0);

    if isfield(params, 'forceLowFreqInversion') && params.forceLowFreqInversion
        genLow = 1;
        genHigh = 1;
    end

    CinvAddLow = invWeight * max(min(params.invGain, 1), 0) * genLow * Cinv_qsLow;
    CinvAddHigh = invWeight * max(min(params.invGain, 1), 0) * genHigh * Cinv_qsHigh;

    Clow(i) = real(min(CbaseLow + CinvAddLow, Cox_eff + Cpar));
    Chigh(i) = real(min(CbaseHigh + CinvAddHigh, Cox_eff + Cpar));
    
    if ~isfinite(Clow(i))
        Clow(i) = max(0, CbaseLow);
    end
    if ~isfinite(Chigh(i))
        Chigh(i) = max(0, CbaseHigh);
    end
    if Clow(i) < 0
        Clow(i) = 0;
    end
    if Chigh(i) < 0
        Chigh(i) = 0;
    end

    Rs_eff = max(params.Rs, 0);
    denom_low = 1 + (omegaLow * Rs_eff * max(Clow(i), 1e-30)) ^ 2;
    denom_high = 1 + (omegaHigh * Rs_eff * max(Chigh(i), 1e-30)) ^ 2;
    
    CmeasLow(i) = real(Clow(i) / max(denom_low, 1e-30));
    CmeasHigh(i) = real(Chigh(i) / max(denom_high, 1e-30));
    
    if ~isfinite(CmeasLow(i))
        CmeasLow(i) = Clow(i);
    end
    if ~isfinite(CmeasHigh(i))
        CmeasHigh(i) = Chigh(i);
    end
end

if params.smoothWindow > 1
    w = max(1, 2 * floor(params.smoothWindow / 2) + 1);
    Clow = movmean(Clow, w, 'Endpoints', 'shrink');
    Chigh = movmean(Chigh, w, 'Endpoints', 'shrink');
    CmeasLow = movmean(CmeasLow, w, 'Endpoints', 'shrink');
    CmeasHigh = movmean(CmeasHigh, w, 'Endpoints', 'shrink');
end

% Note: Removed extra aggressive SiC smoothing pass
% Pure physics model should not require double-smoothing; if oscillations remain,
% they indicate numerical issues in the surface potential solver, not harmonic artifacts.

% Ensure all output is real and finite
Clow = real(Clow);
Chigh = real(Chigh);
CmeasLow = real(CmeasLow);
CmeasHigh = real(CmeasHigh);

Clow(~isfinite(Clow)) = 0;
Chigh(~isfinite(Chigh)) = 0;
CmeasLow(~isfinite(CmeasLow)) = 0;
CmeasHigh(~isfinite(CmeasHigh)) = 0;

Clow(Clow < 0) = 0;
Chigh(Chigh < 0) = 0;
CmeasLow(CmeasLow < 0) = 0;
CmeasHigh(CmeasHigh < 0) = 0;

sim = struct();
sim.Vg = Vg;
sim.psi = psi;
sim.Cs = Cs;
sim.Cideal = Cideal;
sim.Clow = Clow;
sim.Chigh = Chigh;
sim.CmeasLow = CmeasLow;
sim.CmeasHigh = CmeasHigh;
sim.Cmos = Clow;
sim.Cmeas = CmeasHigh;
sim.Cox = Cox;
sim.Cox_eff = Cox_eff;
sim.Cpoly = Cpoly;
sim.Cit = Cit0_area * Area;
sim.Cit_area = Cit0_area;
sim.Cbt = Cbt0_area * Area;
sim.Cbt_area = Cbt0_area;
sim.Cpar = Cpar;
sim.Na_eff = Na_eff;
sim.Na_profile = Na_profile;
sim.x = x;
sim.Vfb = Vfb;
sim.Area = Area;
sim.newtonIters = newtonIters;
sim.omegaLow = omegaLow;
sim.omegaHigh = omegaHigh;
sim.params = params;
end
