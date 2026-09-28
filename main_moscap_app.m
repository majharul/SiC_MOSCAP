function [params, sim, measured] = main_moscap_app(parameterFile, measuredFile)
%MAIN_MOSCAP_APP Run MOSCAP plots/GUI from fitted parameters and measurements.
%   main_moscap_app() automatically uses the latest normalized SiC fit and
%   the bundled 100 kHz/1 MHz measured CSV when both files are present.
%
%   main_moscap_app(parameterFile, measuredFile) uses explicit files.

clc;
projectRoot = fileparts(mfilename('fullpath'));

if nargin < 1 || isempty(parameterFile)
    candidate = fullfile(projectRoot, 'optimized_sic_hf_normalized_parameters.mat');
    if isfile(candidate)
        parameterFile = candidate;
    else
        parameterFile = '';
    end
end
if nargin < 2 || isempty(measuredFile)
    candidate = fullfile(projectRoot, 'examples', 'example_sic_cv_realistic.csv');
    if isfile(candidate)
        measuredFile = candidate;
    else
        measuredFile = '';
    end
end

if ~isempty(parameterFile)
    params = moscap.loadParametersFromFile(parameterFile);
else
    params = moscap.defaultParameters();
end

measured = [];
if ~isempty(measuredFile)
    measured = moscap.readMeasuredData(measuredFile);
    if isempty(measured)
        warning('moscap:MeasuredDataNotLoaded', ...
            'Could not load measured data from %s.', measuredFile);
    end
end

% Use the measured bias range and map the two measured frequencies to the
% solver's two finite-frequency branches.
if ~isempty(measured)
    finiteF = measured.frequenciesHz(isfinite(measured.frequenciesHz));
    if numel(finiteF) >= 2
        params.lfFreqHz = min(finiteF);
        params.hfFreqHz = max(finiteF);
    end
    params.Vg = linspace(min(measured.Vg), max(measured.Vg), ...
        max(301, numel(measured.Vg)));
    params.measured = measured;
end

sim = moscap.simulateMosCapCV(params);
moscap.printModelReview(params, sim);
moscap.printValidationReport(params, sim);
moscap.plotSimulationOnly(params, sim);

if usejava('desktop')
    moscap.launchMosCapGui(params, measured);
else
    fprintf('GUI skipped: desktop environment not available.\n');
end
end
