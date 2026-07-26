function params = loadParametersFromFile(filePath)
%LOADPARAMETERSFROMFILE Load parameters from MAT or JSON file.
%
% USAGE:
%   params = moscap.loadParametersFromFile('optimized_sic_params.mat')
%   params = moscap.loadParametersFromFile('optimized_sic_params.json')
%

% Determine file format
[~, ~, ext] = fileparts(filePath);

switch lower(ext)
    case '.mat'
        % MATLAB format
        load(filePath, 'params_saved');
        params = params_saved;
        fprintf('✓ Loaded parameters from: %s\n', filePath);
        if isfield(params, 'description')
            fprintf('  Description: %s\n', params.description);
        end
        if isfield(params, 'saveDate')
            fprintf('  Date: %s\n', params.saveDate);
        end
        
    case '.json'
        % JSON format
        jsonText = fileread(filePath);
        jsonData = jsondecode(jsonText);
        params = jsonStructToParams(jsonData);
        fprintf('✓ Loaded parameters from: %s (JSON)\n', filePath);
        
    otherwise
        error('File format must be .mat or .json');
end

% Validate
if ~isfield(params, 'material')
    error('Invalid parameters file: missing material field');
end

end

function params = jsonStructToParams(jsonStruct)
%Convert JSON structure back to parameter struct.

params = moscap.defaultParameters();

% Geometry
if isfield(jsonStruct, 'geometry')
    params.W = jsonStruct.geometry.W;
    params.L = jsonStruct.geometry.L;
    params.xox = jsonStruct.geometry.xox;
end

% Material
if isfield(jsonStruct, 'material')
    params.material = jsonStruct.material.name;
    params.Na_peak = jsonStruct.material.Na_peak;
    params.Npoly = jsonStruct.material.Npoly;
    params.Rp = jsonStruct.material.Rp;
    params.sigma = jsonStruct.material.sigma;
    params.xmax = jsonStruct.material.xmax;
end

% Electrostatics
if isfield(jsonStruct, 'electrostatics')
    params.Vfb = jsonStruct.electrostatics.Vfb;
    params.Qox_m2 = jsonStruct.electrostatics.Qox_m2;
    params.Cpar = jsonStruct.electrostatics.Cpar;
    params.Rs = jsonStruct.electrostatics.Rs;
    params.stretch = jsonStruct.electrostatics.stretch;
end

% Non-ideal effects
if isfield(jsonStruct, 'nonIdeal')
    params.Dit_cm2eV = jsonStruct.nonIdeal.Dit_cm2eV;
    params.Cbt = jsonStruct.nonIdeal.Cbt;
    params.tau_gen = jsonStruct.nonIdeal.tau_gen;
    params.forceLowFreqInversion = jsonStruct.nonIdeal.forceLowFreqInversion;
end

% Inversion physics
if isfield(jsonStruct, 'inversion')
    params.invGain = jsonStruct.inversion.invGain;
    params.invWidth = jsonStruct.inversion.invWidth;
    params.phiF_cap = jsonStruct.inversion.phiF_cap;
end

end
