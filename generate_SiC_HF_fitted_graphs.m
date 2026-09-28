%% GENERATE_SIC_HF_FITTED_GRAPHS.M
% Recreate 100 kHz and 1 MHz SiC MOSCAP model/measurement overlays from
% the saved normalized fit. Both measured and modeled traces use C/max(C).

clear; close all; clc;
projectRoot = fileparts(mfilename('fullpath'));
parameterFile = fullfile(projectRoot, 'optimized_sic_hf_normalized_parameters.mat');
measuredFile = fullfile(projectRoot, 'examples', 'example_sic_cv_realistic.csv');
outputFile = fullfile(projectRoot, 'docs', 'sic_hf_fitted_overlay.png');

params = moscap.loadParametersFromFile(parameterFile);
measured = moscap.readMeasuredData(measuredFile);
if isempty(measured) || size(measured.Ccols, 1) < 2
    error('Expected two normalized measured traces in %s.', measuredFile);
end

freq = measured.frequenciesHz(isfinite(measured.frequenciesHz));
params.lfFreqHz = min(freq);
params.hfFreqHz = max(freq);
params.Vg = linspace(min(measured.Vg), max(measured.Vg), ...
    max(1001, numel(measured.Vg)));
sim = moscap.simulateMosCapCV(params);

model100k = moscap.normalizeCV(sim.Clow);
model1M = moscap.normalizeCV(sim.Chigh);
meas100k = moscap.normalizeCV(measured.Ccols(1, :));
meas1M = moscap.normalizeCV(measured.Ccols(2, :));
fit100k = interp1(sim.Vg, model100k, measured.Vg, 'linear');
fit1M = interp1(sim.Vg, model1M, measured.Vg, 'linear');

fig = figure('Color', 'w', 'Name', 'Fitted SiC high-frequency C-V', ...
    'Position', [100 100 1050 720]);
tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

ax1 = nexttile;
plot(ax1, sim.Vg, model100k, 'b-', 'LineWidth', 3.2, ...
    'DisplayName', 'Model 100 kHz');
hold(ax1, 'on');
plot(ax1, sim.Vg, model1M, 'r-', 'LineWidth', 3.2, ...
    'DisplayName', 'Model 1 MHz');
plot(ax1, measured.Vg, meas100k, 'bo', 'MarkerSize', 3, ...
    'DisplayName', 'Measured 100 kHz');
plot(ax1, measured.Vg, meas1M, 'rs', 'MarkerSize', 3, ...
    'DisplayName', 'Measured 1 MHz');
grid(ax1, 'on');
ylim(ax1, [0 1.05]);
ylabel(ax1, 'C / max(C)');
title(ax1, sprintf(['4H-SiC fitted high-frequency response | ', ...
    'N_{A,eff}=%.3g cm^{-3}, V_{FB}=%.3f V'], ...
    sim.Na_eff/1e6, sim.Vfb));
legend(ax1, 'Location', 'southwest');

ax2 = nexttile;
plot(ax2, measured.Vg, 100*(fit100k-meas100k), 'b-', 'LineWidth', 1.5, ...
    'DisplayName', '100 kHz residual');
hold(ax2, 'on');
plot(ax2, measured.Vg, 100*(fit1M-meas1M), 'r-', 'LineWidth', 1.5, ...
    'DisplayName', '1 MHz residual');
yline(ax2, 0, 'k:', 'HandleVisibility', 'off');
grid(ax2, 'on');
xlabel(ax2, 'Gate Voltage V_g (V)');
ylabel(ax2, 'Model - measured (%)');
legend(ax2, 'Location', 'best');

exportgraphics(fig, outputFile, 'Resolution', 280);
fprintf('Saved fitted overlay: %s\n', outputFile);
