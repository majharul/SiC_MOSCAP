%% Compare Si vs SiC C-V Behavior

params_si = moscap.defaultParameters();
params_si.material = 'Si';
params_si.Vg = linspace(-10, 15, 101);

params_sic = moscap.defaultParameters();
params_sic.material = '4H-SiC';
params_sic.Vg = linspace(-10, 15, 101);

fprintf('Testing Si...\n');
sim_si = moscap.simulateMosCapCV(params_si);

fprintf('Testing 4H-SiC...\n');
sim_sic = moscap.simulateMosCapCV(params_sic);

figure('Position', [100 100 1200 500]);

subplot(1,2,1);
plot(sim_si.Vg, sim_si.Clow*1e12, 'b-', 'LineWidth', 2);
hold on;
plot(sim_si.Vg, sim_si.Chigh*1e12, 'r-', 'LineWidth', 2);
xlabel('Vg (V)');
ylabel('C (pF)');
title('Si MOS Capacitor');
grid on;
legend('Clow (1Hz)', 'Chigh (1MHz)');

subplot(1,2,2);
plot(sim_sic.Vg, sim_sic.Clow*1e12, 'b-', 'LineWidth', 2);
hold on;
plot(sim_sic.Vg, sim_sic.Chigh*1e12, 'r-', 'LineWidth', 2);
xlabel('Vg (V)');
ylabel('C (pF)');
title('4H-SiC MOS Capacitor');
grid on;
legend('Clow (1Hz)', 'Chigh (1MHz)');

fprintf('\n=== SI ANALYSIS ===\n');
fprintf('Material: %s\n', params_si.material);
fprintf('Vfb: %.3f V\n', params_si.phi_ms);
fprintf('Na_eff (approx): %.2e m^-3\n', params_si.Na_peak);
fprintf('Clow range: %.1f - %.1f pF\n', min(sim_si.Clow)*1e12, max(sim_si.Clow)*1e12);
fprintf('Chigh range: %.1f - %.1f pF\n', min(sim_si.Chigh)*1e12, max(sim_si.Chigh)*1e12);
fprintf('Smooth: %s\n', ifthenelse(std(diff(sim_si.Clow))<1e-12, 'YES', 'NO'));

fprintf('\n=== 4H-SiC ANALYSIS ===\n');
fprintf('Material: %s\n', params_sic.material);
fprintf('Vfb: %.3f V\n', params_sic.phi_ms);
fprintf('Na_eff (approx): %.2e m^-3\n', params_sic.Na_peak);
fprintf('Clow range: %.1f - %.1f pF\n', min(sim_sic.Clow)*1e12, max(sim_sic.Clow)*1e12);
fprintf('Chigh range: %.1f - %.1f pF\n', min(sim_sic.Chigh)*1e12, max(sim_sic.Chigh)*1e12);
fprintf('Smooth: %s\n', ifthenelse(std(diff(sim_sic.Clow))<1e-12, 'YES', 'NO'));

% Check for NaN, Inf
if any(~isfinite(sim_sic.Clow))
    fprintf('\n⚠️  WARNING: SiC Clow contains NaN/Inf!\n');
    idx_bad = find(~isfinite(sim_sic.Clow));
    for i=idx_bad(1:min(5,length(idx_bad)))
        fprintf('  Vg=%.2f: Clow=%s, psi=%.4f\n', sim_sic.Vg(i), string(sim_sic.Clow(i)), sim_sic.psi(i));
    end
end

function y = ifthenelse(cond, yes, no)
    if cond
        y = yes;
    else
        y = no;
    end
end
