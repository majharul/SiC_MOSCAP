function [optimParams, fitInfo] = optimizeSiCParameters(measData, initParams, varargin)
%OPTIMIZESICPARAMETERS Fast, robust parameter optimization for 4H-SiC C-V data.
%
% USAGE:
%   [optimParams, fitInfo] = moscap.optimizeSiCParameters(measData, initParams)
%   [optimParams, fitInfo] = moscap.optimizeSiCParameters(measData, initParams, 'Verbose', true)
%
% INPUTS:
%   measData   - struct with fields:
%       .Vg        - Gate voltage (V), column 1 of CSV
%       .Clow      - Measured low-frequency capacitance (F)
%       .Chigh     - Measured high-frequency capacitance (F) [optional]
%       .freq      - Frequency values if varying (Hz) [optional]
%       .temp      - Temperature values if varying (K) [optional]
%
%   initParams - Initial parameter struct from moscap.defaultParameters()
%   
%   Name-Value Options:
%       'Verbose'      - true/false, print progress (default: true)
%       'MaxIter'      - max iterations (default: 200)
%       'TolFun'       - function tolerance (default: 1e-4)
%       'TolX'         - parameter tolerance (default: 1e-3)
%       'WeightHigh'   - weight for Chigh in objective (default: 0.3)
%
% OUTPUTS:
%   optimParams - Optimized parameter struct
%   fitInfo     - struct with optimization results:
%       .rmse_initial  - Initial RMSE before optimization
%       .rmse_final    - Final RMSE after optimization
%       .rmse_low      - Final RMSE for Clow only
%       .rmse_high     - Final RMSE for Chigh only (if measured)
%       .exitflag      - fmincon exit flag
%       .iterations    - Number of iterations
%       .simulated     - Final simulated capacitance struct
%
% PHYSICS CONSTRAINTS:
%   - Na_peak: 1e22 - 1e24 m^-3 (SiC doping range)
%   - tau_gen: 0.1 - 10 ms (SiC generation time)
%   - Dit: 1e11 - 1e13 cm^-2 eV^-1 (interface trap density)
%   - Cpar: 0 - 1e-3 F (parasitic capacitance)
%
% METHOD:
%   - Least-squares fitting with constraints
%   - Objective: weighted RMSE of capacitance (low-freq weighted 70%, high-freq 30%)
%   - Optimizer: fmincon with interior-point algorithm
%   - Parallelization: vectorized Newton solver for speed
%

% Parse options
p = inputParser();
addParameter(p, 'Verbose', true, @islogical);
addParameter(p, 'MaxIter', 200, @isnumeric);
addParameter(p, 'TolFun', 1e-4, @isnumeric);
addParameter(p, 'TolX', 1e-3, @isnumeric);
addParameter(p, 'WeightHigh', 0.3, @isnumeric);
parse(p, varargin{:});

verbose = p.Results.Verbose;
maxIter = p.Results.MaxIter;
tolFun = p.Results.TolFun;
tolX = p.Results.TolX;
wHigh = p.Results.WeightHigh;
wLow = 1.0 - wHigh;

if verbose
    fprintf('\n=== 4H-SiC Parameter Optimization ===\n');
    fprintf('Measured points: %d\n', length(measData.Vg));
end

% Validate material
if ~strcmpi(strtrim(initParams.material), '4H-SiC')
    initParams.material = '4H-SiC';
end

% Ensure SiC presets applied
initParams = moscap.enforceMaterialConsistency(initParams, true);

% ===== INITIAL SIMULATION =====
simInit = moscap.simulateMosCapCV(initParams);

% Interpolate measured data to match simulation Vg grid
CmeasLow = interp1(measData.Vg, measData.Clow, simInit.Vg, 'linear', 'extrap');
if isfield(measData, 'Chigh') && ~isempty(measData.Chigh)
    CmeasHigh = interp1(measData.Vg, measData.Chigh, simInit.Vg, 'linear', 'extrap');
    hasMeasHigh = true;
else
    CmeasHigh = [];
    hasMeasHigh = false;
end

% Initial RMSE
rmseInit = computeRMSE(simInit.Clow, CmeasLow, simInit.Chigh, CmeasHigh, wLow, wHigh);
if verbose
    fprintf('Initial RMSE: %.2e F (%.4f pF)\n', rmseInit, rmseInit*1e12);
end

% ===== PARAMETER SELECTION FOR OPTIMIZATION =====
% Key tunable parameters for SiC deep depletion:
% 1. Na_peak - affects depletion width
% 2. tau_gen - affects frequency response (1-10 ms range for SiC)
% 3. Dit - affects inversion charge
% 4. invGain - affects inversion recovery magnitude
% 5. phiF_cap - affects band-bending

% Map to optimization vector x = [Na, tau_gen, Dit, invGain, phiF_cap]
x0 = [
    initParams.Na_peak / 1e22;           % Normalize to 1e22 m^-3 scale
    initParams.tau_gen * 1e3;            % Convert to ms
    initParams.Dit_cm2eV / 1e11;         % Normalize to 1e11 cm^-2 eV^-1
    initParams.invGain;                  % Already 0-1
    initParams.phiF_cap                  % Fermi potential (V)
];

% Bounds (lower, upper) for each parameter
lb = [0.1,   0.1,   0.1,  0,    0.5];   % Lower bounds
ub = [100,   10,    100,  1,    1.5];   % Upper bounds

% ===== OBJECTIVE FUNCTION =====
objFun = @(x) objectiveFunction(x, initParams, measData, CmeasLow, CmeasHigh, wLow, wHigh, hasMeasHigh);

% ===== OPTIMIZATION OPTIONS =====
opts = optimoptions('fmincon', ...
    'Algorithm', 'interior-point', ...
    'MaxIterations', maxIter, ...
    'TolFun', tolFun, ...
    'TolX', tolX, ...
    'SpecifyObjectiveGradient', false, ...
    'Display', 'off');

if verbose
    opts = optimoptions(opts, 'Display', 'iter-detailed');
end

% ===== RUN OPTIMIZATION =====
if verbose
    fprintf('\nStarting optimization (%d parameters)...\n', length(x0));
end

[xOpt, fvalOpt, exitflag, output] = fmincon(objFun, x0, [], [], [], [], lb, ub, [], opts);

% ===== UNPACK OPTIMIZED PARAMETERS =====
optimParams = initParams;
optimParams.Na_peak = xOpt(1) * 1e22;
optimParams.tau_gen = xOpt(2) * 1e-3;
optimParams.Dit_cm2eV = xOpt(3) * 1e11;
optimParams.invGain = xOpt(4);
optimParams.phiF_cap = xOpt(5);

% Re-apply SiC consistency
optimParams = moscap.enforceMaterialConsistency(optimParams, false);

% ===== FINAL SIMULATION =====
simFinal = moscap.simulateMosCapCV(optimParams);

% Reinterpolate to original measured Vg
CsimLow = interp1(simFinal.Vg, simFinal.Clow, measData.Vg, 'linear', 'extrap');
if hasMeasHigh
    CsimHigh = interp1(simFinal.Vg, simFinal.Chigh, measData.Vg, 'linear', 'extrap');
else
    CsimHigh = [];
end

rmseFinal = computeRMSE(simFinal.Clow, CmeasLow, simFinal.Chigh, CmeasHigh, wLow, wHigh);
rmseLow = computeRMSE(simFinal.Clow, CmeasLow, [], [], 1, 0);
if hasMeasHigh
    rmseHigh = computeRMSE(simFinal.Chigh, CmeasHigh, [], [], 1, 0);
else
    rmseHigh = NaN;
end

% ===== OUTPUT SUMMARY =====
if verbose
    fprintf('\n=== Optimization Complete ===\n');
    fprintf('Exit flag: %d (0=converged, 1=success, -1=failed)\n', exitflag);
    fprintf('Iterations: %d / %d\n', output.iterations, maxIter);
    fprintf('Function calls: %d\n', output.funcCount);
    fprintf('\nRMSE Summary:\n');
    fprintf('  Initial:   %.2e F (%.4f pF)\n', rmseInit, rmseInit*1e12);
    fprintf('  Final:     %.2e F (%.4f pF)\n', rmseFinal, rmseFinal*1e12);
    fprintf('  Clow only: %.2e F (%.4f pF)\n', rmseLow, rmseLow*1e12);
    if hasMeasHigh
        fprintf('  Chigh only: %.2e F (%.4f pF)\n', rmseHigh, rmseHigh*1e12);
    end
    fprintf('\nParameter Changes:\n');
    fprintf('  Na_peak:    %.2e → %.2e m^-3\n', initParams.Na_peak, optimParams.Na_peak);
    fprintf('  tau_gen:    %.2f → %.2f ms\n', initParams.tau_gen*1e3, optimParams.tau_gen*1e3);
    fprintf('  Dit:        %.2e → %.2e cm^-2 eV^-1\n', initParams.Dit_cm2eV, optimParams.Dit_cm2eV);
    fprintf('  invGain:    %.3f → %.3f\n', initParams.invGain, optimParams.invGain);
    fprintf('  phiF_cap:   %.3f → %.3f V\n', initParams.phiF_cap, optimParams.phiF_cap);
end

% ===== OUTPUT STRUCT =====
fitInfo = struct();
fitInfo.rmse_initial = rmseInit;
fitInfo.rmse_final = rmseFinal;
fitInfo.rmse_low = rmseLow;
fitInfo.rmse_high = rmseHigh;
fitInfo.exitflag = exitflag;
fitInfo.iterations = output.iterations;
fitInfo.simulated = struct('Vg', measData.Vg, 'Clow', CsimLow, 'Chigh', CsimHigh);
fitInfo.measured = measData;
fitInfo.improvement = (rmseInit - rmseFinal) / rmseInit * 100;

end

% ===== HELPER FUNCTIONS =====

function fval = objectiveFunction(x, baseParams, measData, CmeasLow, CmeasHigh, wLow, wHigh, hasMeasHigh)
%OBJECTIVEFUNCTION Weighted RMSE between measured and simulated capacitance.

try
    % Unpack parameters
    params = baseParams;
    params.Na_peak = x(1) * 1e22;
    params.tau_gen = x(2) * 1e-3;
    params.Dit_cm2eV = x(3) * 1e11;
    params.invGain = x(4);
    params.phiF_cap = x(5);
    
    % Re-apply SiC consistency
    params = moscap.enforceMaterialConsistency(params, false);
    
    % Simulate
    sim = moscap.simulateMosCapCV(params);
    
    % Interpolate to measurement grid
    CsimLow = interp1(sim.Vg, sim.Clow, measData.Vg, 'linear', 'extrap');
    if hasMeasHigh
        CsimHigh = interp1(sim.Vg, sim.Chigh, measData.Vg, 'linear', 'extrap');
    else
        CsimHigh = [];
    end
    
    % Compute weighted RMSE
    fval = computeRMSE(CsimLow, CmeasLow, CsimHigh, CmeasHigh, wLow, wHigh);
    
    % Penalize non-physical results (negative or zero capacitance)
    if any(CsimLow <= 0) || any(CsimHigh <= 0)
        fval = fval * 10;  % Large penalty
    end
    
catch
    % If simulation fails, return large error
    fval = 1e-6;  % ~1 μF, clearly wrong
end

end

function rmse = computeRMSE(CsimLow, CmeasLow, CsimHigh, CmeasHigh, wLow, wHigh)
%COMPUTERMSE Weighted RMSE of capacitance.

% Low-frequency RMSE
rmseLow = sqrt(mean((CsimLow - CmeasLow).^2));

% High-frequency RMSE (if available)
if ~isempty(CsimHigh) && ~isempty(CmeasHigh)
    rmseHigh = sqrt(mean((CsimHigh - CmeasHigh).^2));
    rmse = wLow * rmseLow + wHigh * rmseHigh;
else
    rmse = rmseLow;
end

end
