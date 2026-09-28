%% Detailed SiC C-V Analysis with Different Smoothing

params_sic = moscap.defaultParameters();
params_sic.material = '4H-SiC';
params_sic = moscap.enforceMaterialConsistency(params_sic, true);
params_sic.Vg = linspace(-10, 15, 501);

% Test with different smoothing windows
smoothings = [1, 3, 5, 11, 21];
results = {};

for i = 1:length(smoothings)
    params = params_sic;
    params.smoothWindow = smoothings(i);
    fprintf('Running with smoothWindow = %d...\n', smoothings(i));
    sim = moscap.simulateMosCapCV(params);
    results{i} = sim;
end

figure('Position', [100 100 1400 700]);

for i = 1:length(smoothings)
    subplot(2,3,i);
    sim = results{i};
    plot(sim.Vg, sim.Clow*1e12, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Clow (1Hz)');
    hold on;
    plot(sim.Vg, sim.Chigh*1e12, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Chigh (1MHz)');
    xlabel('Vg (V)');
    ylabel('C (pF)');
    title(sprintf('4H-SiC with smoothWindow=%d', smoothings(i)));
    grid on;
    legend('show');
    
    % Check for issues
    if any(~isfinite(sim.Clow))
        title(sprintf('4H-SiC with smoothWindow=%d ⚠️ NaN/Inf detected', smoothings(i)));
    end
    
    % Print stats
    fprintf('  smoothWindow=%d: Clow range [%.1f - %.1f] pF\n', ...
        smoothings(i), min(sim.Clow)*1e12, max(sim.Clow)*1e12);
end

% Also test without material enforcement
fprintf('\n\nTesting 4H-SiC WITHOUT enforceMatConsistency:\n');
params_raw_sic = moscap.defaultParameters();
params_raw_sic.material = '4H-SiC';
% Don't call enforceMaterialConsistency - use raw defaults
params_raw_sic.Vg = linspace(-10, 15, 501);
sim_raw = moscap.simulateMosCapCV(params_raw_sic);

subplot(2,3,6);
plot(sim_raw.Vg, sim_raw.Clow*1e12, 'b-', 'LineWidth', 1.5);
hold on;
plot(sim_raw.Vg, sim_raw.Chigh*1e12, 'r-', 'LineWidth', 1.5);
xlabel('Vg (V)');
ylabel('C (pF)');
title('4H-SiC (Raw Defaults)');
grid on;
legend('Clow', 'Chigh');

fprintf('Raw defaults: Clow range [%.1f - %.1f] pF\n', ...
    min(sim_raw.Clow)*1e12, max(sim_raw.Clow)*1e12);

fprintf('\nConclusion:\n');
fprintf('SiC with material enforcement has different doping and tau_gen\n');
fprintf('This affects the C-V behavior significantly\n');
