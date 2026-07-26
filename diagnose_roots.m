%% Diagnostic: Surface Potential Root Analysis
% Check if Newton-Raphson is converging to correct physical root

params = moscap.defaultParameters();
params.material = 'SiC';
params.Vg = linspace(-10, 15, 21);  % Coarse for analysis

sim = moscap.simulateMosCapCV(params);

figure('Position', [100 100 1200 600]);

subplot(1,3,1);
plot(sim.Vg, sim.psi, 'bo-', 'LineWidth', 2, 'MarkerSize', 6);
xlabel('Vg (V)');
ylabel('Surface Potential psi (V)');
title('Surface Potential vs Vg');
grid on;

subplot(1,3,2);
plot(sim.Vg, sim.Cs*1e12, 'go-', 'LineWidth', 2, 'MarkerSize', 6);
xlabel('Vg (V)');
ylabel('Surface Capacitance Cs (pF)');
title('Surface Capacitance vs Vg');
grid on;

subplot(1,3,3);
plot(sim.Vg, sim.Clow*1e12, 'bo-', 'LineWidth', 2, 'MarkerSize', 6);
hold on;
plot(sim.Vg, sim.Chigh*1e12, 'ro-', 'LineWidth', 2, 'MarkerSize', 6);
xlabel('Vg (V)');
ylabel('C (pF)');
title('Complete C-V');
grid on;
legend('Clow (1Hz)', 'Chigh (1MHz)');

fprintf('\nDetailed Analysis:\n');
fprintf('Vg(V)  psi(V)   Cs(pF)   Clow(pF) Chigh(pF)\n');
for i=1:length(sim.Vg)
    fprintf('%6.1f %7.4f %8.2f %8.2f %9.2f\n', sim.Vg(i), sim.psi(i), sim.Cs(i)*1e12, sim.Clow(i)*1e12, sim.Chigh(i)*1e12);
end

% Check Flatband
[~, idx_vfb] = min(abs(sim.psi));
fprintf('\nFlatband: Vg ≈ %.2f V where psi ≈ %.4f V\n', sim.Vg(idx_vfb), sim.psi(idx_vfb));

% Check monotonicity of psi
dpsi = diff(sim.psi) ./ diff(sim.Vg);
fprintf('\ndpsi/dVg values (should be all positive for correct physics):\n');
for i=1:length(dpsi)
    fprintf('Between Vg=%.1f and %.1f: dpsi/dVg = %.6f %s\n', ...
        sim.Vg(i), sim.Vg(i+1), dpsi(i), ...
        ifthenelse(dpsi(i)>0, '✓', '✗ WRONG'));
end

function y = ifthenelse(cond, yes, no)
    if cond
        y = yes;
    else
        y = no;
    end
end
