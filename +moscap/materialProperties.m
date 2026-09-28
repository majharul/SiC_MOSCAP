function [eps_si, ni] = materialProperties(material, eps0)
%MATERIALPROPERTIES Retrieve permittivity and intrinsic carrier concentration.
%   Supports Si and 4H-SiC at 300K.

switch lower(strtrim(material))
    case {'si', 'silicon'}
        eps_si = 11.7 * eps0;
        ni = 1.45e16;       % m^-3, Si @ 300K
    case {'4h-sic', 'sic'}
        eps_si = 9.7 * eps0;
        % 4H-SiC @ 300 K: band gap ~= 3.26 eV.
        % Eg ~= 3.26 eV, Nc ~= 1.66e19 cm^-3, and Nv ~= 3.19e19
        % cm^-3 give ni ~= 1e-8 cm^-3. Keep SI units in this model:
        % 1e-8 cm^-3 = 1e-2 m^-3.
        ni = 1e-2;          % m^-3, 4H-SiC @ 300 K
    otherwise
        eps_si = 11.7 * eps0;
        ni = 1.45e16;
end
end
