function plotSimulationOnly(params, sim)
%PLOTSIMULATIONONLY Plot modeled frequency branches and optional measurements.

measured = [];
if isfield(params, 'measured')
    measured = params.measured;
end

fig = figure('Color', 'w', 'Name', 'SiC MOSCAP modeled vs measured');
ax = axes(fig);
moscap.drawCurves(ax, sim, measured);

figure('Color', 'w', 'Name', 'Surface Potential');
plot(sim.Vg, real(sim.psi), 'LineWidth', 2.0);
grid on;
xlabel('Gate Voltage V_g (V)');
ylabel('\psi_s (V)');
title('Surface Potential from Implicit Solver');
end
