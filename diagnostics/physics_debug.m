%% Pure Physics Debugging: Inversion Transition Analysis
% Analyze the "down-up-down" W-shaped behavior in detail

params = moscap.defaultParameters();
params.material = 'SiC';

Vg_fine = linspace(-10, 15, 501);  % Fine resolution for smooth curve
params.Vg = Vg_fine;

sim = moscap.simulateMosCapCV(params);

% Plot with full detail
figure('Position', [100 100 1000 600]);

% Top: Full C-V curve
subplot(2,2,1);
plot(sim.Vg, sim.Clow*1e12, 'b-', 'LineWidth', 1.5);
hold on;
plot(sim.Vg, sim.Chigh*1e12, 'r-', 'LineWidth', 1.5);
xlabel('Vg (V)');
ylabel('C (pF)');
title('Complete C-V Curve (Pure Physics - No Stretching/Smoothing)');
grid on;
legend('Clow (1Hz)', 'Chigh (1MHz)');

% Second: Surface potential
subplot(2,2,2);
plot(sim.Vg, sim.psi, 'LineWidth', 1.5);
xlabel('Vg (V)');
ylabel('Surface Potential (V)');
title('Surface Potential vs Gate Voltage');
grid on;

% Third: Derivative dC/dVg (to see kinks)
subplot(2,2,3);
dC_dVg = diff(sim.Clow) ./ diff(sim.Vg);
Vg_deriv = sim.Vg(1:end-1);
plot(Vg_deriv, dC_dVg*1e12, 'b-', 'LineWidth', 1);
hold on;
plot([sim.Vg(1) sim.Vg(end)], [0 0], 'k--', 'LineWidth', 0.5);
xlabel('Vg (V)');
ylabel('dC/dVg (pF/V)');
title('Derivative: Shows Discontinuities/Kinks');
grid on;

% Fourth: Depletion width vs Vg
subplot(2,2,4);
% Estimate depletion width from surface potential
% Wd ≈ sqrt(2*eps_si*abs(psi_s)/(q*Na))
plot(sim.Vg, sqrt(abs(sim.psi)), 'LineWidth', 1.5);
xlabel('Vg (V)');
ylabel('Sqrt(|psi_s|)');
title('Normalized Depletion Width');
grid on;

sgtitle('Pure Physics Analysis: Identifying W-Shape Origin');

% Find the minimum Clow
[Cmin, idx_min] = min(sim.Clow);
fprintf('Detailed Behavior:\n');
fprintf('Minimum Clow: %.2f pF at Vg = %.2f V\n', Cmin*1e12, sim.Vg(idx_min));
fprintf('\nNear minimum region:\n');
for i = max(1, idx_min-3):min(length(sim.Vg), idx_min+3)
    fprintf('Vg=%.2f V: Clow=%.2f pF, psi=%.4f V\n', sim.Vg(i), sim.Clow(i)*1e12, sim.psi(i));
end
