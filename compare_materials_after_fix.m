%% Compare Si vs SiC Full C-V Behavior After Physics Fixes

% Test 1: Si Material
fprintf('=== SILICON (Si) ===\n');
params_si = moscap.defaultParameters();
params_si.material = 'Si';
params_si = moscap.enforceMaterialConsistency(params_si, true);
params_si.Vg = linspace(-10, 15, 101);

sim_si = moscap.simulateMosCapCV(params_si);

fprintf('Material enforcement applied\n');
fprintf('Na_peak: %.2e m^-3\n', params_si.Na_peak);
fprintf('tau_gen: %.2e s\n', params_si.tau_gen);
fprintf('phiF_cap: %.3f V\n', params_si.phiF_cap);
fprintf('invWidth: %.3f V\n', params_si.invWidth);
fprintf('smoothWindow: %d\n', params_si.smoothWindow);
fprintf('Clow: %.1f - %.1f pF (range: %.1f)\n', min(sim_si.Clow)*1e12, max(sim_si.Clow)*1e12, (max(sim_si.Clow)-min(sim_si.Clow))*1e12);
fprintf('Chigh: %.1f - %.1f pF (range: %.1f)\n\n', min(sim_si.Chigh)*1e12, max(sim_si.Chigh)*1e12, (max(sim_si.Chigh)-min(sim_si.Chigh))*1e12);

% Test 2: SiC Material
fprintf('=== 4H-SiC ===\n');
params_sic = moscap.defaultParameters();
params_sic.material = '4H-SiC';
params_sic = moscap.enforceMaterialConsistency(params_sic, true);
params_sic.Vg = linspace(-10, 15, 101);

sim_sic = moscap.simulateMosCapCV(params_sic);

fprintf('Material enforcement applied\n');
fprintf('Na_peak: %.2e m^-3\n', params_sic.Na_peak);
fprintf('tau_gen: %.2e s\n', params_sic.tau_gen);
fprintf('phiF_cap: %.3f V\n', params_sic.phiF_cap);
fprintf('invWidth: %.3f V\n', params_sic.invWidth);
fprintf('smoothWindow: %d\n', params_sic.smoothWindow);
fprintf('Clow: %.1f - %.1f pF (range: %.1f)\n', min(sim_sic.Clow)*1e12, max(sim_sic.Clow)*1e12, (max(sim_sic.Clow)-min(sim_sic.Clow))*1e12);
fprintf('Chigh: %.1f - %.1f pF (range: %.1f)\n\n', min(sim_sic.Chigh)*1e12, max(sim_sic.Chigh)*1e12, (max(sim_sic.Chigh)-min(sim_sic.Chigh))*1e12);

% Verify no numerical issues
bad_si = ~isfinite(sim_si.Clow) | ~isfinite(sim_si.Chigh);
bad_sic = ~isfinite(sim_sic.Clow) | ~isfinite(sim_sic.Chigh);
fprintf('Numerical issues:\n');
fprintf('Si: %d bad values\n', sum(bad_si));
fprintf('SiC: %d bad values\n\n', sum(bad_sic));

% Plot
figure('Position', [100 100 1200 400]);

subplot(1,2,1);
plot(sim_si.Vg, sim_si.Clow*1e12, 'b-', 'LineWidth', 2, 'DisplayName', 'Clow (1Hz)');
hold on;
plot(sim_si.Vg, sim_si.Chigh*1e12, 'r-', 'LineWidth', 2, 'DisplayName', 'Chigh (1MHz)');
xlabel('Vg (V)');
ylabel('C (pF)');
title('Si - After Pure Physics Fixes');
grid on;
legend;
ylim([0 500]);

subplot(1,2,2);
plot(sim_sic.Vg, sim_sic.Clow*1e12, 'b-', 'LineWidth', 2, 'DisplayName', 'Clow (1Hz)');
hold on;
plot(sim_sic.Vg, sim_sic.Chigh*1e12, 'r-', 'LineWidth', 2, 'DisplayName', 'Chigh (1MHz)');
xlabel('Vg (V)');
ylabel('C (pF)');
title('4H-SiC - After Pure Physics Fixes');
grid on;
legend;
ylim([0 500]);

sgtitle('Si vs SiC C-V Comparison with Material Enforcement');

fprintf('ANALYSIS:\n');
fprintf('Si shows: smooth variation from accumulation to inversion\n');
fprintf('SiC shows: ___?\n');

% Check monotonicity
dClow_si = diff(sim_si.Clow);
dClow_sic = diff(sim_sic.Clow);
fprintf('\nMonotonicity check:\n');
fprintf('Si: %d sign changes in dC/dVg\n', sum(diff(sign(dClow_si))~=0));
fprintf('SiC: %d sign changes in dC/dVg\n', sum(diff(sign(dClow_sic))~=0));
