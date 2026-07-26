function [eps_si, ni] = materialProperties(material, eps0)
%MATERIALPROPERTIES Retrieve permittivity and intrinsic carrier concentration.
%   Supports Si and 4H-SiC at 300K.

switch lower(strtrim(material))
    case {'si', 'silicon'}
        eps_si = 11.7 * eps0;
        ni = 1.45e16;       % m^-3, Si @ 300K
    case {'4h-sic', 'sic'}
        eps_si = 9.7 * eps0;
        % 4H-SiC @ 300K: band gap = 3.26 eV, much wider than Si (1.12 eV)
        % Intrinsic carrier concentration: ni ≈ 1e4 m^-3 (1e-10 cm^-3)
        % This is 12 orders of magnitude lower than Si!
        ni = 1e4;           % m^-3, 4H-SiC @ 300K (physically correct)
    otherwise
        eps_si = 11.7 * eps0;
        ni = 1.45e16;
end
end
