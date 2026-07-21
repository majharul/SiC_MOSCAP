function params = enforceMaterialConsistency(params, resetDoping)
%ENFORCEMATERIALCONSISTENCY Ensures material-specific consistency of parameters.
%   Resets doping profiles and constraints based on material choice.

[params.eps_si, params.ni] = moscap.materialProperties(params.material, params.eps0);
[naMin, naMax] = moscap.materialNaBounds(params.material);

if resetDoping
    switch lower(strtrim(params.material))
        case {'4h-sic', 'sic'}
            params = applySiCProcessPreset(params);
        otherwise % Si
            params.Na_peak = 5e23;
            params.Npoly = 1e25;
            params.Rp = 0.25e-6;
            params.sigma = 0.08e-6;
            params.tau_gen = 5e-6;
            params.phiF_cap = 1.10;
            params.invGain = 1.0;
            params.invWidth = 0.12;
            params.forceLowFreqInversion = false;
            params.sicProcess = 'none';
    end
end

params.Na_peak = min(max(params.Na_peak, naMin), naMax);
params.smoothWindow = max(1, round(params.smoothWindow));
params.tau_gen = max(params.tau_gen, 1e-9);
params.Rp = max(params.Rp, 0);
params.sigma = max(params.sigma, 1e-9);
params.xmax = max(params.xmax, 5 * params.sigma);
if strcmpi(strtrim(params.material), '4H-SiC')
    params.Qox_m2 = max(params.Qox_m2, 1e15);
    params.Dit_cm2eV = max(params.Dit_cm2eV, 1e11);
end
end

function params = applySiCProcessPreset(params)
%APPLYSICPROCESSPRESET Apply SiC process-aware doping and junction-depth presets.

processName = 'RUN2-2022';
if isfield(params, 'sicProcess') && ~isempty(params.sicProcess)
    processName = lower(strtrim(params.sicProcess));
end

switch processName
    case {'pass0', 'w2-5&8'}
        params.Na_peak = 1e15 * 1e6;
        params.Npoly = 5e24;
        params.Rp = 0.35e-6;
        params.sigma = 0.14e-6;
        params.xmax = 6e-6;
        params.tau_gen = 1e-3;
        params.phiF_cap = 0.75;
        params.invWidth = 0.18;
        params.forceLowFreqInversion = false;
    case {'pass1-run1', 'w1-w6'}
        params.Na_peak = 5e14 * 1e6;
        params.Npoly = 5e24;
        params.Rp = 0.40e-6;
        params.sigma = 0.18e-6;
        params.xmax = 8e-6;
        params.tau_gen = 2e-3;
        params.phiF_cap = 0.80;
        params.invWidth = 0.20;
        params.forceLowFreqInversion = false;
    case {'pass1-run2', 'w7', 'w9', 'w11'}
        params.Na_peak = 5e14 * 1e6;
        params.Npoly = 5e24;
        params.Rp = 0.40e-6;
        params.sigma = 0.18e-6;
        params.xmax = 8e-6;
        params.tau_gen = 2e-3;
        params.phiF_cap = 0.82;
        params.invWidth = 0.22;
        params.forceLowFreqInversion = false;
    case {'run2-2022', 'w1&2'}
        params.Na_peak = 1e15 * 1e6;
        params.Npoly = 5e24;
        params.Rp = 0.55e-6;
        params.sigma = 0.22e-6;
        params.xmax = 12e-6;
        params.tau_gen = 3e-3;
        params.phiF_cap = 0.85;
        params.invWidth = 0.24;
        params.forceLowFreqInversion = false;
    otherwise
        params.Na_peak = 8e22;
        params.Npoly = 5e24;
        params.Rp = 0.20e-6;
        params.sigma = 0.07e-6;
        params.xmax = 6e-6;
        params.tau_gen = 2e-3;
        params.phiF_cap = 0.85;
        params.invGain = 1.0;
        params.invWidth = 0.18;
        params.forceLowFreqInversion = false;
        params.sicProcess = 'custom';
end
end






