function [rmsePf, maePf, nPts] = compareMeasured(sim, measured)
%COMPAREMEASURED Compute error metrics between simulation and measured data.

Cgg_pF = getMeasuredCgg(measured);
CsimpF = interp1(sim.Vg, sim.Cmeas * 1e12, measured.Vg, 'linear', 'extrap');
err = CsimpF - Cgg_pF;
rmsePf = sqrt(mean(err .^ 2));
maePf = mean(abs(err));
nPts = numel(err);
end

function Cgg_pF = getMeasuredCgg(measured)
%GETMEASUREDCGG Extract selected capacitance column from measurement struct.

idx = min(max(1, measured.selectedCol), size(measured.Ccols_pF, 1));
Cgg_pF = measured.Ccols_pF(idx, :);
end
