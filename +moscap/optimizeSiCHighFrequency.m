function [optimParams, fitInfo] = optimizeSiCHighFrequency(measData, initParams, varargin)
%OPTIMIZESICHIGHFREQUENCY Fit one conventional high-frequency 4H-SiC C-V curve.
%   Fits only parameters identifiable from a single HF trace: uniform
%   effective doping, flat-band voltage, and (optionally) active-area scale.
%   It deliberately does not extract generation lifetime or interface-trap
%   kinetics; those require sweep-rate/C-t or multifrequency admittance data.

p = inputParser();
addParameter(p, 'Verbose', true, @islogical);
addParameter(p, 'MaxIter', 300, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'FitArea', true, @islogical);
addParameter(p, 'DataMode', 'absolute', ...
    @(x) ischar(x) || (isstring(x) && isscalar(x)));
addParameter(p, 'DisableUnidentifiedTraps', true, @islogical);
addParameter(p, 'NaBounds_cm3', [1e14 1e19], ...
    @(x) isnumeric(x) && numel(x) == 2 && all(x > 0));
addParameter(p, 'VfbBounds', [], ...
    @(x) isempty(x) || (isnumeric(x) && numel(x) == 2));
parse(p, varargin{:});
opt = p.Results;
dataMode = lower(char(opt.DataMode));
isNormalizedMax = any(strcmp(dataMode, ...
    {'normalized', 'normalized-max', 'c/cmax', 'dimensionless'}));
isNormalizedCox = strcmp(dataMode, 'c/cox');
isNormalized = isNormalizedMax || isNormalizedCox;
if ~isNormalized && ~strcmp(dataMode, 'absolute')
    error('moscap:InvalidDataMode', ...
        'DataMode must be absolute, normalized-max, or C/Cox.');
end
fitArea = opt.FitArea && ~isNormalized;
if isNormalized && opt.FitArea
    warning('moscap:AreaNotIdentifiable', ...
        'FitArea is disabled because area cancels from normalized C/Cox data.');
end

if ~isfield(measData, 'Chigh') || isempty(measData.Chigh)
    error('moscap:MissingHighFrequencyData', ...
        'A Chigh column is required for high-frequency-only fitting.');
end

Vg = double(measData.Vg(:).');
Cmeas = double(measData.Chigh(:).');
valid = isfinite(Vg) & isfinite(Cmeas) & Cmeas > 0;
Vg = Vg(valid);
Cmeas = Cmeas(valid);
[Vg, order] = sort(Vg);
Cmeas = Cmeas(order);
if isNormalizedMax
    Cmeas = Cmeas / max(Cmeas);
end
if numel(Vg) < 8 || numel(unique(Vg)) ~= numel(Vg)
    error('moscap:InvalidHighFrequencyData', ...
        'Need at least eight finite, positive points at unique gate voltages.');
end

base = initParams;
base.material = '4H-SiC';
base = moscap.enforceMaterialConsistency(base, false);
base.Vg = Vg;
if opt.DisableUnidentifiedTraps
    base.Dit_cm2eV = 0;
    base.Cbt_cm2eV = 0;
    base.Cpar_pF = 0;
end

if isempty(opt.VfbBounds)
    vfbBounds = [min(Vg)-5, max(Vg)+5];
else
    vfbBounds = sort(opt.VfbBounds(:).');
end
naBounds_m3 = sort(opt.NaBounds_cm3(:).') * 1e6;

if isfield(base, 'Na_eff_override') && ~isempty(base.Na_eff_override)
    na0 = base.Na_eff_override;
else
    na0 = base.Na_peak;
end
na0 = min(max(na0, naBounds_m3(1)), naBounds_m3(2));
CoxArea = base.eps_ox / base.tox;
vfb0 = base.phi_ms - base.q * base.Qox_m2 / CoxArea;
vfb0 = min(max(vfb0, vfbBounds(1)), vfbBounds(2));

if fitArea
    x0 = [log10(na0), vfb0, 0];
    lb = [log10(naBounds_m3(1)), vfbBounds(1), log10(0.1)];
    ub = [log10(naBounds_m3(2)), vfbBounds(2), log10(10)];
else
    x0 = [log10(na0), vfb0];
    lb = [log10(naBounds_m3(1)), vfbBounds(1)];
    ub = [log10(naBounds_m3(2)), vfbBounds(2)];
end

if isNormalized
    Cref = 1;
else
    Cref = median(maxk(Cmeas, max(3, ceil(0.1*numel(Cmeas)))));
end
obj = @(x) hfObjective(x, base, Vg, Cmeas, Cref, fitArea, ...
    isNormalizedMax, isNormalizedCox);
options = optimoptions('fmincon', 'Algorithm', 'interior-point', ...
    'MaxIterations', opt.MaxIter, 'MaxFunctionEvaluations', 5000, ...
    'OptimalityTolerance', 1e-9, 'StepTolerance', 1e-9, ...
    'Display', displayMode(opt.Verbose));

initialObjective = obj(x0);
[xBest, finalObjective, exitflag, output] = ...
    fmincon(obj, x0, [], [], [], [], lb, ub, [], options);
[optimParams, Cfit] = unpackAndSimulate(xBest, base, Vg, fitArea, ...
    isNormalizedMax, isNormalizedCox);

residual = Cfit - Cmeas;
fitInfo = struct();
fitInfo.rmse = sqrt(mean(residual.^2));
fitInfo.nrmse = fitInfo.rmse / Cref;
if isNormalized
    fitInfo.rmse_F = NaN;
    fitInfo.rmse_pF = NaN;
else
    fitInfo.rmse_F = fitInfo.rmse;
    fitInfo.rmse_pF = fitInfo.rmse * 1e12;
end
fitInfo.initial_objective = initialObjective;
fitInfo.final_objective = finalObjective;
fitInfo.exitflag = exitflag;
fitInfo.iterations = output.iterations;
fitInfo.Na_eff_m3 = optimParams.Na_eff_override;
fitInfo.Na_eff_cm3 = optimParams.Na_eff_override / 1e6;
fitInfo.Vfb = optimParams.phi_ms - ...
    optimParams.q * optimParams.Qox_m2 / CoxArea;
if fitArea
    fitInfo.areaScale = 10^xBest(3);
else
    fitInfo.areaScale = 1;
end
fitInfo.measured = struct('Vg', Vg, 'Chigh', Cmeas);
fitInfo.simulated = struct('Vg', Vg, 'Chigh', Cfit);
fitInfo.dataMode = dataMode;
if isNormalized
    fitInfo.note = ['Normalized single-frequency HF C-V does not identify ', ...
        'active area, absolute Cox, tau_gen, Dit, tau_it, or deep-depletion ', ...
        'dynamics. Extracted Na is conditional on the supplied tox.'];
else
    fitInfo.note = ['Single-frequency HF C-V does not identify tau_gen, Dit, ', ...
        'tau_it, or deep-depletion dynamics.'];
end

if opt.Verbose && isNormalized
    if isNormalizedMax
        normLabel = 'C/Cmax';
    else
        normLabel = 'C/Cox';
    end
    fprintf('\nNormalized HF fit: RMSE = %.5f %s (%.2f%%)\n', ...
        fitInfo.rmse, normLabel, 100*fitInfo.rmse);
    fprintf('Na,eff = %.3e cm^-3, Vfb = %.3f V\n', ...
        fitInfo.Na_eff_cm3, fitInfo.Vfb);
elseif opt.Verbose
    fprintf('\nHF fit: RMSE = %.3f pF (NRMSE %.2f%%)\n', ...
        fitInfo.rmse_pF, 100*fitInfo.nrmse);
    fprintf('Na,eff = %.3e cm^-3, Vfb = %.3f V, area scale = %.4f\n', ...
        fitInfo.Na_eff_cm3, fitInfo.Vfb, fitInfo.areaScale);
end
end

function value = hfObjective(x, base, Vg, Cmeas, Cref, fitArea, ...
        isNormalizedMax, isNormalizedCox)
try
    [~, Csim] = unpackAndSimulate(x, base, Vg, fitArea, ...
        isNormalizedMax, isNormalizedCox);
    r = (Csim - Cmeas) / Cref;
    % Huber loss reduces leverage from isolated measurement outliers.
    delta = 0.05;
    a = abs(r);
    loss = 0.5*r.^2;
    idx = a > delta;
    loss(idx) = delta*(a(idx) - 0.5*delta);
    value = 2*mean(loss);
    if ~isfinite(value)
        value = 1e6;
    end
catch
    value = 1e6;
end
end

function [params, Csim] = unpackAndSimulate(x, base, Vg, fitArea, ...
        isNormalizedMax, isNormalizedCox)
params = base;
params.Na_eff_override = 10^x(1);
CoxArea = params.eps_ox / params.tox;
params.phi_ms = x(2) + params.q * params.Qox_m2 / CoxArea;
if fitArea
    params.W = base.W * 10^x(3);
end
params.Vg = Vg;
sim = moscap.simulateMosCapCV(params);
if isNormalizedMax
    Csim = sim.Chigh(:).' / max(sim.Chigh);
elseif isNormalizedCox
    Csim = sim.Chigh(:).' / sim.Cox_eff;
else
    Csim = sim.Chigh(:).';
end
end

function value = displayMode(verbose)
if verbose
    value = 'iter';
else
    value = 'off';
end
end
