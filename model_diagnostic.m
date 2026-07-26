% Quick diagnostic: Check C-V curve behavior
clear; close all;

params = moscap.defaultParameters();
params.material = '4H-SiC';
params = moscap.enforceMaterialConsistency(params, true);

fprintf('Simulating C-V curve...\n');
tic;
sim = moscap.simulateMosCapCV(params);
toc;

fprintf('\nDiagnostic Output:\n');
fprintf('─────────────────────────────────────────\n');

% Find specific Vg points
Vg_pts = [-10, -8, -5, -3, 0, 5, 10, 15];
fprintf('Vg (V)    Clow (pF)    Chigh (pF)\n');
for Vg_val = Vg_pts
    idx = find(abs(sim.Vg - Vg_val) < 0.01, 1);
    if ~isempty(idx)
        fprintf('%3d       %8.1f      %8.1f\n', Vg_val, sim.Clow(idx)*1e12, sim.Chigh(idx)*1e12);
    end
end

% Check for oscillations or unusual behavior
fprintf('\n───────────────────────────────────────────\n');
fprintf('Clow statistics:\n');
fprintf('  Min: %.1f pF at Vg = %.1f V\n', min(sim.Clow)*1e12, sim.Vg(find(sim.Clow == min(sim.Clow),1)));
fprintf('  Max: %.1f pF at Vg = %.1f V\n', max(sim.Clow)*1e12, sim.Vg(find(sim.Clow == max(sim.Clow),1)));
fprintf('  Std Dev: %.1f pF\n', std(sim.Clow)*1e12);

% Check derivatives to find oscillations
dClow = diff(sim.Clow) ./ diff(sim.Vg);
fprintf('\nDerivative Analysis (dC/dVg):\n');
fprintf('  Min dC/dVg: %.2e F/V\n', min(dClow));
fprintf('  Max dC/dVg: %.2e F/V\n', max(dClow));
fprintf('  Large oscillations detected: %d regions\n', sum(abs(diff(sign(dClow))) > 0));

% Plot
figure('Position', [100 100 1200 400]);

subplot(1,2,1);
plot(sim.Vg, sim.Clow*1e12, 'b-', 'LineWidth', 2);
hold on;
plot(sim.Vg, sim.Chigh*1e12, 'r--', 'LineWidth', 2);
xlabel('Gate Voltage (V)', 'FontSize', 12);
ylabel('Capacitance (pF)', 'FontSize', 12);
title('Default SiC Model - C-V Curve', 'FontSize', 12);
legend('Clow (1 Hz)', 'Chigh (1 MHz)', 'FontSize', 10);
grid on;
xlim([-10 15]);

% Plot derivative to show oscillations
subplot(1,2,2);
Vg_mid = sim.Vg(1:end-1) + diff(sim.Vg)/2;
plot(Vg_mid, dClow*1e12, 'g-', 'LineWidth', 1.5);
xlabel('Gate Voltage (V)', 'FontSize', 12);
ylabel('dC/dVg (pF/V)', 'FontSize', 12);
title('Derivative - Reveals Oscillations', 'FontSize', 12);
grid on;
xlim([-10 15]);

savefig('model_diagnostic.fig');
print('model_diagnostic.png', '-dpng', '-r150');
fprintf('\nPlots saved: model_diagnostic.png\n');
