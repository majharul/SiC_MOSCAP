function saveParametersToFile(params, filePath, description)
%SAVEPARAMETERSTOFILE Save optimized parameters to MAT or JSON file.
%
% USAGE:
%   moscap.saveParametersToFile(params, 'optimized_sic_params.mat')
%   moscap.saveParametersToFile(params, 'optimized_sic_params.json', 'SiC optimized 2026-07-26')
%
% INPUTS:
%   params      - Parameter struct from moscap.defaultParameters()
%   filePath    - Output file path (.mat or .json)
%   description - Optional description/metadata (default: timestamp)
%

if nargin < 3
    description = sprintf('Optimized parameters - %s', datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
end

% Determine file format
[~, ~, ext] = fileparts(filePath);

switch lower(ext)
    case '.mat'
        % MATLAB format
        params_saved = params;
        params_saved.saveDate = datetime('now');
        params_saved.description = description;
        save(filePath, 'params_saved', '-mat');
        fprintf('✓ Saved parameters to: %s\n', filePath);
        
    case '.json'
        % JSON format (human-readable)
        jsonStruct = paramsToJsonStruct(params);
        jsonStruct.metadata.description = description;
        jsonStruct.metadata.saveDate = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss');
        
        jsonText = jsonencode(jsonStruct);
        fid = fopen(filePath, 'w');
        fprintf(fid, jsonText);
        fclose(fid);
        fprintf('✓ Saved parameters to: %s (JSON)\n', filePath);
        
    otherwise
        error('File format must be .mat or .json');
end

end

function jsonStruct = paramsToJsonStruct(params)
%Convert parameter struct to JSON-compatible structure.

jsonStruct = struct();
jsonStruct.metadata = struct();

% Geometry
jsonStruct.geometry = struct();
jsonStruct.geometry.W = params.W;
jsonStruct.geometry.L = params.L;
jsonStruct.geometry.xox = params.xox;

% Material
jsonStruct.material = struct();
jsonStruct.material.name = params.material;
jsonStruct.material.Na_peak = params.Na_peak;
jsonStruct.material.Npoly = params.Npoly;
jsonStruct.material.Rp = params.Rp;
jsonStruct.material.sigma = params.sigma;
jsonStruct.material.xmax = params.xmax;

% Electrostatics
jsonStruct.electrostatics = struct();
jsonStruct.electrostatics.Vfb = params.Vfb;
jsonStruct.electrostatics.Qox_m2 = params.Qox_m2;
jsonStruct.electrostatics.Cpar = params.Cpar;
jsonStruct.electrostatics.Rs = params.Rs;
jsonStruct.electrostatics.stretch = params.stretch;

% Non-ideal effects
jsonStruct.nonIdeal = struct();
jsonStruct.nonIdeal.Dit_cm2eV = params.Dit_cm2eV;
jsonStruct.nonIdeal.Cbt = params.Cbt;
jsonStruct.nonIdeal.tau_gen = params.tau_gen;
jsonStruct.nonIdeal.forceLowFreqInversion = params.forceLowFreqInversion;

% Inversion physics
jsonStruct.inversion = struct();
jsonStruct.inversion.invGain = params.invGain;
jsonStruct.inversion.invWidth = params.invWidth;
jsonStruct.inversion.phiF_cap = params.phiF_cap;

end
