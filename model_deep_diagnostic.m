% Deep diagnostic: Check surface potential and internal state
clear; close all;

params = moscap.defaultParameters();
params.material = '4H-SiC';
params = moscap.enforceMaterialConsistency(params, true);

fprintf('Checking parameter defaults:\n');
fprintf('  forceLowFreqInversion: %s\n', mat2str(params.forceLowFreqInversion));
fprintf('  invGain: %.3f\n', params.invGain);
fprintf('  tau_gen: %.3e s\n', params.tau_gen);
fprintf('  Vfb (calc): %.3f V\n', params.phi_ms - params.Qox_m2 / (params.eps_ox / params.tox));

% Manually compute at a few points to understand what's happening
fprintf('\nManual Surface Potential Calculation:\n');

% Extract params
q = params.q;
k = params.k;
T = params.T;
Vt = k * T / q;

% Effective substrate doping
x = linspace(0, params.xmax, 800);
Na_profile = params.Na_peak .* exp(-((x - params.Rp) .^ 2) ./ (2 * params.sigma ^ 2));
Na_eff = trapz(x, Na_profile) / params.xmax;

Cox_area = params.eps_ox / params.tox;
eps_si = params.eps_si;
ni = params.ni;

fprintf('  Na_eff: %.2e m^-3\n', Na_eff);
fprintf('  Cox_area: %.2e F/m^2\n', Cox_area);
fprintf('  Vt (kT/q @ 300K): %.2e V\n', Vt);

phiF_raw = Vt * log(max(Na_eff, 1.01 * ni) / max(ni, 1e-30));
phiF = min(max(phiF_raw, 0.05), params.phiF_cap);
fprintf('  phiF (raw): %.3f V\n', phiF_raw);
fprintf('  phiF (capped): %.3f V\n', phiF);

% Check what happens at different Vg
fprintf('\nSurface Potential at Different Vg:\n');
Vg_test = [-10, -5, 0, 5, 10, 15];

for Vg_val = Vg_test
    % Newton solver for surface potential
    psi_trial = 0;
    Vfb = params.phi_ms - params.Qox_m2 / Cox_area;
    VG_eff = Vfb + (Vg_val - Vfb) / max(params.stretch, 1);
    
    for iter = 1:50
        [Qs, dQs] = moscap.qsurfaceAndDerivative(psi_trial, Na_eff, ni, eps_si, Vt, q);
        f = Vfb + psi_trial - Qs / Cox_area - VG_eff;
        df = 1 - dQs / Cox_area;
        if abs(df) < 1e-15; break; end
        psi_trial = psi_trial - f / df;
        if abs(f) < 1e-12; break; end
    end
    
    fprintf('  Vg = %3d V: psi = %.4f V (2*phiF = %.4f V)\n', Vg_val, psi_trial, 2*phiF);
end

% Now run actual simulation
fprintf('\n\nRunning full simulation...\n');
sim = moscap.simulateMosCapCV(params);

fprintf('\nC-V Output vs Expected Behavior:\n');
fprintf('─────────────────────────────────────────\n');
fprintf('Region        Vg   Clow (pF)  Expected\n');
fprintf('─────────────────────────────────────────\n');

fprintf('Accumulation  -10    %.1f      ~415-420 pF\n', sim.Clow(1)*1e12);
fprintf('Depletion      0    %.1f      ~250-350 pF\n', sim.Clow(find(abs(sim.Vg) < 0.1, 1))*1e12);
fprintf('Inversion     +15    %.1f      ~100-200 pF\n', sim.Clow(end)*1e12);

% Check if the problem is saturation or other issue
fprintf('\n\nInvestigating why Clow doesn''t vary:\n');
fprintf('Checking: Is Cs (semiconductor capacitance) varying?\n');

% We need to manually recompute to see intermediate values
% Use a simplified version
Area = params.W * params.L * params.NF;
for Vg_val = [-10, -5, 0, 5, 15]
    psi_trial = 0;
    Vfb = params.phi_ms - params.Qox_m2 / Cox_area;
    VG_eff = Vfb + (Vg_val - Vfb);
    
    for iter = 1:50
        [Qs, dQs] = moscap.qsurfaceAndDerivative(psi_trial, Na_eff, ni, eps_si, Vt, q);
        f = Vfb + psi_trial - Qs / Cox_area - VG_eff;
        df = 1 - dQs / Cox_area;
        if abs(df) < 1e-15; break; end
        psi_trial = psi_trial - f / df;
    end
    
    [~, dQs] = moscap.qsurfaceAndDerivative(psi_trial, Na_eff, ni, eps_si, Vt, q);
    Cs = abs(dQs) * Area;
    
    fprintf('Vg = %3d V: psi = %.3f V, Cs (semidonductor) = %.2e F (%.1f pF)\n', ...
        Vg_val, psi_trial, Cs, Cs*1e12);
end
