%% OPTIMIZE_SIC_CV_FIT.M
% Master script for SiC C-V parameter optimization workflow.
%
% WORKFLOW:
%   1. Load measured C-V data from CSV template
%   2. Initialize parameters (use defaults or load previous optimization)
%   3. Run robust least-squares optimizer
%   4. Visualize results (measured vs simulated)
%   5. Save optimized parameters for reuse
%
% USAGE:
%   Edit USER CONFIGURATION section below, then run script
%   Or call with arguments:
%   optimize_SiC_CV_fit('measured_sic_data.csv', 'output_params.mat')
%
% REQUIREMENTS:
%   - +moscap package in MATLAB path
%   - Measured C-V data in CSV format (see example below)
%
% CSV FORMAT EXAMPLE:
%   Vg(V),Clow@1Hz(pF),Chigh@1MHz(pF)
%   -10,406.2,405.1
%   -5,410.5,408.3
%   0,415.0,390.2
%   5,420.1,150.5
%   10,420.3,151.2%
% ⚠️  DATA RANGE CHECK:
%   Measured capacitance should typically be in range: 50-400 pF
%   If your values are < 1e-10 pF or other extreme values, 
%   check data format and units. See DATA_FORMAT_DIAGNOSTIC.md
clear; close all; clc;

% ========== USER CONFIGURATION ==========
% Path to measured data CSV
measuredDataFile = 'example_measured_sic_data.csv';  % Change to your CSV file

% Output parameter files
paramMatFile = 'optimized_sic_parameters.mat';
paramJsonFile = 'optimized_sic_parameters.json';

% Optimization settings
USE_INITIAL_PARAMETERS_FILE = false;  % Set true to start from previous optimization
INITIAL_PARAMETERS_FILE = '';         % Path to previous parameters (if USE_INITIAL_PARAMETERS_FILE=true)

OPTIMIZE_VERBOSE = true;
OPTIMIZE_MAX_ITERATIONS = 200;
OPTIMIZE_TOL_FUN = 1e-4;
OPTIMIZE_TOL_X = 1e-3;
OPTIMIZE_WEIGHT_HIGH = 0.3;  % Weight for Chigh (0.3) vs Clow (0.7)

% Plotting
PLOT_RESULTS = true;
PLOT_INDIVIDUAL_FREQ = false;  % If measured data has multiple frequencies

% ========== END USER CONFIGURATION ==========

fprintf('\n');
fprintf('╔════════════════════════════════════════════════════════════╗\n');
fprintf('║   4H-SiC C-V PARAMETER OPTIMIZATION - ROBUST WORKFLOW    ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n');
fprintf('\n');

% ===== STEP 1: LOAD MEASURED DATA =====
fprintf('STEP 1: Loading measured C-V data...\n');
fprintf('───────────────────────────────────\n');

if ~isfile(measuredDataFile)
    error('Measured data file not found: %s\n', measuredDataFile);
end

measData = moscap.loadMeasuredDataTemplate(measuredDataFile, ...
    'Unit', 'pF', ...
    'Verbose', true);

fprintf('✓ Data loaded successfully\n\n');

% ===== STEP 2: INITIALIZE PARAMETERS =====
fprintf('STEP 2: Initializing parameters...\n');
fprintf('─────────────────────────────────\n');

if USE_INITIAL_PARAMETERS_FILE && isfile(INITIAL_PARAMETERS_FILE)
    fprintf('Loading initial parameters from: %s\n', INITIAL_PARAMETERS_FILE);
    initParams = moscap.loadParametersFromFile(INITIAL_PARAMETERS_FILE);
else
    fprintf('Using default SiC parameters\n');
    initParams = moscap.defaultParameters();
    initParams.material = 'Si';%4H-SiC
    initParams = moscap.enforceMaterialConsistency(initParams, true);
end

fprintf('✓ Parameters initialized\n\n');

% ===== STEP 3: RUN OPTIMIZATION =====
fprintf('STEP 3: Running parameter optimization...\n');
fprintf('───────────────────────────────────────\n');

optimOptions = {
    'Verbose', OPTIMIZE_VERBOSE, ...
    'MaxIter', OPTIMIZE_MAX_ITERATIONS, ...
    'TolFun', OPTIMIZE_TOL_FUN, ...
    'TolX', OPTIMIZE_TOL_X, ...
    'WeightHigh', OPTIMIZE_WEIGHT_HIGH
};

[optimParams, fitInfo] = moscap.optimizeSiCParameters(measData, initParams, optimOptions{:});

fprintf('\n✓ Optimization complete\n\n');

% ===== STEP 4: GENERATE SIMULATION WITH OPTIMIZED PARAMETERS =====
fprintf('STEP 4: Generating optimized simulation...\n');
fprintf('───────────────────────────────────────\n');

simOptim = moscap.simulateMosCapCV(optimParams);

fprintf('✓ Simulation generated\n\n');

% ===== STEP 5: SAVE PARAMETERS =====
fprintf('STEP 5: Saving optimized parameters...\n');
fprintf('─────────────────────────────────────\n');

description = sprintf('SiC C-V optimization from %s\nRMSE: %.2e F (%.4f pF)\nImprovement: %.1f%%', ...
    measuredDataFile, fitInfo.rmse_final, fitInfo.rmse_final*1e12, fitInfo.improvement);

moscap.saveParametersToFile(optimParams, paramMatFile, description);
moscap.saveParametersToFile(optimParams, paramJsonFile, description);

fprintf('✓ Parameters saved\n\n');

% ===== STEP 6: PLOT RESULTS =====
if PLOT_RESULTS
    fprintf('STEP 6: Plotting results...\n');
    fprintf('──────────────────────────\n');
    
    fig = figure('Name', 'SiC C-V Optimization Results', 'NumberTitle', 'off', ...
        'Position', [100 100 1200 500]);
    
    % Plot 1: Clow comparison
    subplot(1, 2, 1);
    plot(measData.Vg, measData.Clow*1e12, 'ko-', 'LineWidth', 2, 'MarkerSize', 6, 'DisplayName', 'Measured');
    hold on;
    plot(simOptim.Vg, simOptim.Clow*1e12, 'b-', 'LineWidth', 2, 'DisplayName', 'Optimized Model');
    grid on; legend('Location', 'best'); 
    xlabel('Gate Voltage (V)', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Clow (pF)', 'FontSize', 11, 'FontWeight', 'bold');
    title('Low-Frequency Capacitance Fit', 'FontSize', 12, 'FontWeight', 'bold');
    
    % Plot 2: Chigh comparison (if available)
    if ~isempty(measData.Chigh)
        subplot(1, 2, 2);
        plot(measData.Vg, measData.Chigh*1e12, 'ko-', 'LineWidth', 2, 'MarkerSize', 6, 'DisplayName', 'Measured');
        hold on;
        plot(simOptim.Vg, simOptim.Chigh*1e12, 'r-', 'LineWidth', 2, 'DisplayName', 'Optimized Model');
        grid on; legend('Location', 'best');
        xlabel('Gate Voltage (V)', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('Chigh (pF)', 'FontSize', 11, 'FontWeight', 'bold');
        title('High-Frequency Capacitance Fit', 'FontSize', 12, 'FontWeight', 'bold');
    else
        subplot(1, 2, 2);
        text(0.5, 0.5, 'Chigh data not available', 'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', 'FontSize', 14);
        axis off;
    end
    
    sgtitle('SiC C-V Parameter Optimization - Fit Quality', 'FontSize', 14, 'FontWeight', 'bold');
    
    fprintf('✓ Plot displayed\n\n');
end

% ===== FINAL SUMMARY =====
fprintf('╔════════════════════════════════════════════════════════════╗\n');
fprintf('║                    OPTIMIZATION SUMMARY                   ║\n');
fprintf('╚════════════════════════════════════════════════════════════╝\n\n');

fprintf('FIT QUALITY:\n');
fprintf('  Initial RMSE:   %.2e F (%.4f pF)\n', fitInfo.rmse_initial, fitInfo.rmse_initial*1e12);
fprintf('  Final RMSE:     %.2e F (%.4f pF)\n', fitInfo.rmse_final, fitInfo.rmse_final*1e12);
fprintf('  Improvement:    %.1f%%\n', fitInfo.improvement);
fprintf('  Iterations:     %d / %d\n', fitInfo.iterations, OPTIMIZE_MAX_ITERATIONS);
fprintf('\n');

fprintf('OPTIMIZED PARAMETERS:\n');
fprintf('  Na_peak:        %.2e m^-3 (was %.2e)\n', optimParams.Na_peak, initParams.Na_peak);
fprintf('  tau_gen:        %.2f ms (was %.2f ms)\n', optimParams.tau_gen*1e3, initParams.tau_gen*1e3);
fprintf('  Dit:            %.2e cm^-2 eV^-1 (was %.2e)\n', optimParams.Dit_cm2eV, initParams.Dit_cm2eV);
fprintf('  invGain:        %.3f (was %.3f)\n', optimParams.invGain, initParams.invGain);
fprintf('  phiF_cap:       %.3f V (was %.3f V)\n', optimParams.phiF_cap, initParams.phiF_cap);
fprintf('\n');

fprintf('OUTPUT FILES:\n');
fprintf('  MATLAB format:  %s\n', paramMatFile);
fprintf('  JSON format:    %s\n', paramJsonFile);
fprintf('\n');

fprintf('NEXT STEPS:\n');
fprintf('  1. Verify plot visually - measured vs optimized curves should align\n');
fprintf('  2. Check parameter changes are physically reasonable\n');
fprintf('  3. Use optimized parameters in GUI: \n');
fprintf('     >> load(%s); params = params_saved; moscap.launchMosCapGui(params);\n', paramMatFile);
fprintf('  4. For next optimization, set:\n');
fprintf('     >> USE_INITIAL_PARAMETERS_FILE = true;\n');
fprintf('     >> INITIAL_PARAMETERS_FILE = ''%s'';\n', paramMatFile);
fprintf('\n✓ OPTIMIZATION WORKFLOW COMPLETE\n\n');
