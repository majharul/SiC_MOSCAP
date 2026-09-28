function [naMin, naMax] = materialNaBounds(material)
%MATERIALNABOUNDS Doping concentration bounds for material.

switch lower(strtrim(material))
    case {'4h-sic', 'sic'}
        % 1e14--1e19 cm^-3 in SI units. The former 5e21 m^-3 upper
        % bound silently clipped ordinary SiC wells and flattened most of
        % the optimizer's advertised search interval.
        naMin = 1e20;
        naMax = 1e25;
    otherwise
        naMin = 5e21;
        naMax = 3e24;
end
end

