function [naMin, naMax] = materialNaBounds(material)
%MATERIALNABOUNDS Doping concentration bounds for material.

switch lower(strtrim(material))
    case {'4h-sic', 'sic'}
        naMin = 1e15;
        naMax = 5e21;
    otherwise
        naMin = 5e21;
        naMax = 3e24;
end
end

