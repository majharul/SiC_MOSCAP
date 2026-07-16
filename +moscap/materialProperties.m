function [eps_si, ni] = materialProperties(material, eps0)
%MATERIALPROPERTIES Retrieve permittivity and intrinsic carrier concentration.
%   Supports Si and 4H-SiC at 300K.

switch lower(strtrim(material))
    case {'si', 'silicon'}
        eps_si = 11.7 * eps0;
        ni = 1.45e16;       % m^-3, Si @ 300K
    case {'4h-sic', 'sic'}
        eps_si = 9.7 * eps0;
        ni = 1e-3;           % m^-3, practical compact value for numerical robustness
    otherwise
        eps_si = 11.7 * eps0;
        ni = 1.45e16;
end
end
