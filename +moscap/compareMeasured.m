function [rmseN, maeN, nPts] = compareMeasured(sim, measured)
%COMPAREMEASURED Normalized error metrics between simulation and measured data.
%   For C/max(C) input, both curves use their own maxima. Otherwise the
%   simulation uses Cox_eff. The selected measured frequency is matched to
%   the nearest configured simulated branch.

Cmeas_pF = getMeasuredCgg(measured);

% Compare against the modeled frequency corresponding to the selected
% measured column. The solver exposes the configured 100 kHz and 1 MHz
% branches as Clow and Chigh, respectively.
simCurve = sim.Chigh;
if isfield(measured, 'frequenciesHz') && ...
        numel(measured.frequenciesHz) >= measured.selectedCol
    fMeas = measured.frequenciesHz(measured.selectedCol);
    if isfinite(fMeas) && abs(log(max(fMeas, eps)/sim.params.lfFreqHz)) < ...
            abs(log(max(fMeas, eps)/sim.params.hfFreqHz))
        simCurve = sim.Clow;
    end
end

useMax = isfield(measured, 'normalizationMode') && ...
    strcmpi(measured.normalizationMode, 'max');
measN = moscap.normalizeCV(Cmeas_pF);
if useMax
    simN = moscap.normalizeCV(simCurve);
else
    simN = moscap.normalizeCV(simCurve, sim.Cox_eff);
end
simN_interp = interp1(sim.Vg, simN, measured.Vg, 'linear', 'extrap');

err = simN_interp - measN;
rmseN = sqrt(mean(err .^ 2));
maeN = mean(abs(err));
nPts = numel(err);
end

function Cgg_pF = getMeasuredCgg(measured)
%GETMEASUREDCGG Extract selected capacitance column from measurement struct.

if isfield(measured, 'Ccols')
    values = measured.Ccols;
else
    values = measured.Ccols_pF;
end
idx = min(max(1, measured.selectedCol), size(values, 1));
Cgg_pF = values(idx, :);
end
