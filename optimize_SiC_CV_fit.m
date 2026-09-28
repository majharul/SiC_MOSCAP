%% OPTIMIZE_SIC_CV_FIT.M
% Fit a conventional 1 MHz C-V trace for a p-type 4H-SiC MOS capacitor.
% The input CSV contains C divided by the maximum value of each trace.

clear; close all; clc;

% ---------------- User configuration ----------------
measuredDataFile = 'examples/example_sic_cv_realistic.csv';
dataUnit = 'C/Cmax';
hfFreqHz = 1e6;

% Area cancels from C/Cmax, so W, L, NF, and active-area scale cannot be
% extracted. tox still affects Cmin/Cox and must be supplied independently.
W = 100e-6;
L = 100e-6;
NF = 18;
tox = 50e-9;
fitArea = false;

maxIterations = 300;
plotResults = true;
paramMatFile = 'optimized_sic_hf_normalized_parameters.mat';
paramJsonFile = 'optimized_sic_hf_normalized_parameters.json';
% ----------------------------------------------------

measData = moscap.loadMeasuredDataTemplate(measuredDataFile, ...
    'Unit', dataUnit, 'Verbose', true);

params0 = moscap.defaultParameters();
params0.material = '4H-SiC';
params0 = moscap.enforceMaterialConsistency(params0, true);
params0.W = W;
params0.L = L;
params0.NF = NF;
params0.tox = tox;
params0.hfFreqHz = hfFreqHz;
params0.Vg = measData.Vg(:).';

% One HF trace cannot identify interface-trap kinetics or generation time.
% The dedicated fitter therefore disables those unverified capacitances and
% fits Na,eff, Vfb, and (optionally) an effective area scale only.
[paramsFit, fitInfo] = moscap.optimizeSiCHighFrequency( ...
    measData, params0, ...
    'DataMode', 'normalized-max', ...
    'FitArea', fitArea, ...
    'DisableUnidentifiedTraps', true, ...
    'MaxIter', maxIterations, ...
    'Verbose', true);

description = sprintf([ ...
    'Normalized HF-only 4H-SiC MOSCAP fit to %s | ', ...
    'RMSE %.5f C/Cmax (%.2f percent of maximum)'], ...
    measuredDataFile, fitInfo.rmse, 100*fitInfo.rmse);
moscap.saveParametersToFile(paramsFit, paramMatFile, description);
moscap.saveParametersToFile(paramsFit, paramJsonFile, description);

if plotResults
    figure('Name', '4H-SiC high-frequency C-V fit', ...
        'NumberTitle', 'off', 'Color', 'w');
    plot(fitInfo.measured.Vg, fitInfo.measured.Chigh, ...
        'ko', 'MarkerFaceColor', [0.2 0.2 0.2], ...
        'DisplayName', 'Measured C/C_{max}');
    hold on;
    plot(fitInfo.simulated.Vg, fitInfo.simulated.Chigh, ...
        'r-', 'LineWidth', 2, 'DisplayName', 'Fitted HF model');
    grid on;
    xlabel('Gate voltage, V_G (V)');
    ylabel('C_{HF}/C_{max}');
    ylim([0 1.05]);
    title(sprintf('1 MHz normalized fit: RMSE %.4f (%.2f%% of C_{max})', ...
        fitInfo.rmse, 100*fitInfo.rmse));
    legend('Location', 'best');
end

fprintf('\nInterpretation guardrail:\n');
fprintf(['  The inversion-side HF plateau is Cmin. A continued fall below ', ...
    'Cmin is deep depletion and needs sweep-rate or C-t validation.\n']);
fprintf('  %s\n', fitInfo.note);
fprintf('\nSaved %s and %s\n', paramMatFile, paramJsonFile);
