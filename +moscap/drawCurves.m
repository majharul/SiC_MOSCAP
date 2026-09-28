function curves = drawCurves(ax, sim, measured)
%DRAWCURVES Plot modeled frequency branches and all measured C-V columns.

cla(ax);
hold(ax, 'on');

useMax = ~isempty(measured) && isfield(measured, 'normalizationMode') && ...
    strcmpi(measured.normalizationMode, 'max');
if useMax
    lowY = moscap.normalizeCV(sim.Clow);
    highY = moscap.normalizeCV(sim.Chigh);
    idealY = moscap.normalizeCV(sim.Cideal);
    yText = 'C / max(C)';
    titleText = sprintf('SiC high-frequency response | V_{FB}=%.3f V | N_{A,eff}=%.2e cm^{-3}', ...
        sim.Vfb, sim.Na_eff/1e6);
else
    lowY = moscap.normalizeCV(sim.Clow, sim.Cox_eff);
    highY = moscap.normalizeCV(sim.Chigh, sim.Cox_eff);
    idealY = moscap.normalizeCV(sim.Cideal, sim.Cox_eff);
    yText = 'C / C_{ox,eff}';
    titleText = sprintf('MOSCAP response | V_{FB}=%.3f V | C_{ox,eff}=%.1f pF', ...
        sim.Vfb, sim.Cox_eff*1e12);
end

curves = struct();
curves.low = plot(ax, sim.Vg, lowY, 'b-', 'LineWidth', 2.2, ...
    'DisplayName', sprintf('Model %s', formatFrequency(sim.params.lfFreqHz)));
curves.high = plot(ax, sim.Vg, highY, 'r-', 'LineWidth', 2.2, ...
    'DisplayName', sprintf('Model %s', formatFrequency(sim.params.hfFreqHz)));
curves.ideal = plot(ax, sim.Vg, idealY, 'k:', 'LineWidth', 1.0, ...
    'DisplayName', 'Ideal reference');
curves.meas = gobjects(0);

if ~isempty(measured)
    if isfield(measured, 'Ccols')
        values = measured.Ccols;
    else
        values = measured.Ccols_pF;
    end
    palette = lines(max(2, size(values, 1)));
    markers = {'o', 's', '^', 'd', 'v', '>'};
    for k = 1:size(values, 1)
        y = real(values(k, :));
        if useMax
            y = moscap.normalizeCV(y);
        end
        marker = markers{1 + mod(k-1, numel(markers))};
        markerFace = 'none';
        lineWidth = 0.9;
        if k == measured.selectedCol
            markerFace = palette(k, :);
            lineWidth = 1.3;
        end
        curves.meas(k) = plot(ax, measured.Vg, y, ...
            'LineStyle', 'none', 'Marker', marker, 'MarkerSize', 3.5, ...
            'Color', palette(k, :), 'MarkerFaceColor', markerFace, ...
            'LineWidth', lineWidth, 'DisplayName', measured.colNames{k});
    end
end

grid(ax, 'on');
ylim(ax, [0 1.05]);
xlabel(ax, 'Gate Voltage V_g (V)');
ylabel(ax, yText);
title(ax, titleText);
lgd = legend(ax, 'show', 'Location', 'best');
lgd.Interpreter = 'none';
end

function textValue = formatFrequency(frequencyHz)
if frequencyHz >= 1e9
    textValue = sprintf('%.3g GHz', frequencyHz/1e9);
elseif frequencyHz >= 1e6
    textValue = sprintf('%.3g MHz', frequencyHz/1e6);
elseif frequencyHz >= 1e3
    textValue = sprintf('%.3g kHz', frequencyHz/1e3);
else
    textValue = sprintf('%.3g Hz', frequencyHz);
end
end
