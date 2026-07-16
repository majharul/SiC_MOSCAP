function plotSimulationOnly(params, sim)
%PLOTSIMULATIONONLY Display static plot of C-V simulation results.
%   Creates figures showing low- and high-frequency C-V curves and surface potential.

figure('Color', 'w', 'Name', 'MOSCAP C-V (Static)');
plot(sim.Vg, real(sim.Clow) * 1e12, 'b', 'LineWidth', 2.2);
hold on;
plot(sim.Vg, real(sim.Chigh) * 1e12, 'r', 'LineWidth', 2.2);
plot(sim.Vg, real(sim.Cideal) * 1e12, 'k--', 'LineWidth', 1.2);
grid on;
xlabel('Gate Voltage V_g (V)');
ylabel('C_{gg} (pF)');
title('MOSCAP C-V: Low- and High-Frequency Response');
%legend('Low-frequency response', 'High-frequency response', 'Ideal Cox', 'Location', 'best');
legend('Without Rs High-frequency response', 'With Impedence', 'Static Cox', 'Location', 'best');
figure('Color', 'w', 'Name', 'Surface Potential');
plot(sim.Vg, real(sim.psi), 'LineWidth', 2.0);
grid on;
xlabel('Gate Voltage V_g (V)');
ylabel('\psi_s (V)');
title('Surface Potential from Implicit Solver');

if isfield(params, 'measured') && ~isempty(params.measured)
    figure('Color', 'w', 'Name', 'Simulation vs Measured');
    plot(sim.Vg, real(sim.Chigh) * 1e12, 'r', 'LineWidth', 2.2);
    hold on;
    plot(params.measured.Vg, real(moscap.getMeasuredCgg(params.measured)), 'ko', 'MarkerSize', 4, 'LineWidth', 1.1);
    [rmsePf, maePf] = moscap.compareMeasured(sim, params.measured);
    grid on;
    xlabel('Gate Voltage V_g (V)');
    ylabel('C_{gg} (pF)');
    title(sprintf('Measured Comparison (RMSE = %.3f pF, MAE = %.3f pF)', rmsePf, maePf));
    legend('High-frequency simulated', 'Measured data', 'Location', 'best');
end
end
