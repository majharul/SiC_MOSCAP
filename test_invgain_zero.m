%% Test: Remove Inversion Gain to See if W-Shape Goes Away

params = moscap.defaultParameters();
params.material = 'SiC';
params.invGain = 0;  % Disable inversion charge contribution

params.Vg = linspace(-10, 15, 501);

sim = moscap.simulateMosCapCV(params);

figure;
plot(sim.Vg, sim.Clow*1e12, 'b-', 'LineWidth', 2);
hold on;
plot(sim.Vg, sim.Chigh*1e12, 'r-', 'LineWidth', 2);
xlabel('Vg (V)');
ylabel('C (pF)');
title('C-V with invGain=0 (No Inversion Effect)');
grid on;
legend('Clow (1Hz, no inversion)', 'Chigh (1MHz)');

% Print values
fprintf('\nC-V values (invGain = 0):\n');
fprintf('Vg (V)    Clow (pF)    Chigh (pF)\n');
for i = [1, 51, 101, 151, 201, 251, 301, 351, 401, 451, 501]
    fprintf('%6.1f      %7.1f       %7.1f\n', sim.Vg(i), sim.Clow(i)*1e12, sim.Chigh(i)*1e12);
end

% Find min/max
[Cmin, idx_min] = min(sim.Clow);
[Cmax, idx_max] = max(sim.Clow);
fprintf('\nStats:\n');
fprintf('Min Clow: %.2f pF at Vg=%.2f V\n', Cmin*1e12, sim.Vg(idx_min));
fprintf('Max Clow: %.2f pF at Vg=%.2f V\n', Cmax*1e12, sim.Vg(idx_max));
