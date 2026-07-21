function curves = drawCurves(ax, sim, measured)
%DRAWCURVES Initialize plot curves on given axes.

cla(ax);
hold(ax, 'on');
curves = struct();
curves.low = plot(ax, sim.Vg, real(sim.Clow) * 1e12, 'b', 'LineWidth', 2.2);
curves.high = plot(ax, sim.Vg, real(sim.Chigh) * 1e12, 'r', 'LineWidth', 2.0);
curves.ideal = plot(ax, sim.Vg, real(sim.Cideal) * 1e12, 'k:', 'LineWidth', 1.2);

if isempty(measured)
    curves.meas = plot(ax, nan, nan, 'ko', 'MarkerSize', 4, 'LineWidth', 1.0);
else
    curves.meas = plot(ax, measured.Vg, real(moscap.getMeasuredCgg(measured)), 'ko', 'MarkerSize', 4, 'LineWidth', 1.0);
end

legend(ax, {'Low-Frequency (τ_gen-limited)', 'High-Frequency (trap-limited)', 'Ideal: Cox (no defects)', 'Measured'}, 'Location', 'best');
grid(ax, 'on');
end

function curves = redrawCurves(ax, sim, measured, curves)
%REDRAWCURVES Update existing plot curves with new simulation data.

if ~isgraphics(curves.low)
    curves = drawCurves(ax, sim, measured);
    return;
end

set(curves.low, 'XData', sim.Vg, 'YData', real(sim.Clow) * 1e12);
set(curves.high, 'XData', sim.Vg, 'YData', real(sim.Chigh) * 1e12);
set(curves.ideal, 'XData', sim.Vg, 'YData', real(sim.Cideal) * 1e12);

if isempty(measured)
    set(curves.meas, 'XData', nan, 'YData', nan);
else
    set(curves.meas, 'XData', measured.Vg, 'YData', real(moscap.getMeasuredCgg(measured)));
end

title(ax, sprintf('Low- and High-Frequency Simulated vs Measured C-V_g | Vfb = %.3f V', sim.Vfb));
drawnow limitrate;
end
