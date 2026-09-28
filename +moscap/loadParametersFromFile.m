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
    if isfield(jsonStruct.geometry, 'tox')
        params.tox = jsonStruct.geometry.tox;
    elseif isfield(jsonStruct.geometry, 'xox')
        params.tox = jsonStruct.geometry.xox;
    end
    if isfield(jsonStruct.geometry, 'NF')
        params.NF = jsonStruct.geometry.NF;
    end
end

% Material
if isfield(jsonStruct, 'material')
    params.material = jsonStruct.material.name;
    params.Na_peak = jsonStruct.material.Na_peak;
    if isfield(jsonStruct.material, 'Na_eff_override')
        params.Na_eff_override = jsonStruct.material.Na_eff_override;
    end
    params.Npoly = jsonStruct.material.Npoly;
    params.Rp = jsonStruct.material.Rp;
    params.sigma = jsonStruct.material.sigma;
    params.xmax = jsonStruct.material.xmax;
end

% Electrostatics
if isfield(jsonStruct, 'electrostatics')
    if isfield(jsonStruct.electrostatics, 'Qox_m2')
        params.Qox_m2 = jsonStruct.electrostatics.Qox_m2;
    end
    if isfield(jsonStruct.electrostatics, 'phi_ms')
        params.phi_ms = jsonStruct.electrostatics.phi_ms;
    elseif isfield(jsonStruct.electrostatics, 'Vfb')
        CoxArea = params.eps_ox / params.tox;
        params.phi_ms = jsonStruct.electrostatics.Vfb + ...
            params.q * params.Qox_m2 / CoxArea;
    end
    if isfield(jsonStruct.electrostatics, 'Cpar_pF')
        params.Cpar_pF = jsonStruct.electrostatics.Cpar_pF;
    elseif isfield(jsonStruct.electrostatics, 'Cpar')
        params.Cpar_pF = jsonStruct.electrostatics.Cpar;
    end
    params.Rs = jsonStruct.electrostatics.Rs;
    params.stretch = jsonStruct.electrostatics.stretch;
end

% Non-ideal effects
if isfield(jsonStruct, 'nonIdeal')
    params.Dit_cm2eV = jsonStruct.nonIdeal.Dit_cm2eV;
    if isfield(jsonStruct.nonIdeal, 'Cbt_cm2eV')
        params.Cbt_cm2eV = jsonStruct.nonIdeal.Cbt_cm2eV;
    elseif isfield(jsonStruct.nonIdeal, 'Cbt')
        params.Cbt_cm2eV = jsonStruct.nonIdeal.Cbt;
    end
    if isfield(jsonStruct.nonIdeal, 'tau_bt')
        params.tau_bt = jsonStruct.nonIdeal.tau_bt;
    end
    if isfield(jsonStruct.nonIdeal, 'tau_it')
        params.tau_it = jsonStruct.nonIdeal.tau_it;
    end
    params.tau_gen = jsonStruct.nonIdeal.tau_gen;
    params.forceLowFreqInversion = jsonStruct.nonIdeal.forceLowFreqInversion;
end

% Inversion physics
if isfield(jsonStruct, 'inversion')
    params.invGain = jsonStruct.inversion.invGain;
    params.invWidth = jsonStruct.inversion.invWidth;
    params.phiF_cap = jsonStruct.inversion.phiF_cap;
end

params = moscap.enforceMaterialConsistency(params, false);

end
