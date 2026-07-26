%% DIAGNOSE DEEP DEPLETION AND INVERSION TRANSITION
% Check whether deep depletion width and frequency-dependent generation
% are properly handled for both Si and SiC

clear; clc; close all;

% Setup
q = 1.602e-19;  % Coulomb
eps0 = 8.854e-12;

%% MATERIAL SETUP
materials = {'Si', '4H-SiC'};
figure('Name', 'Deep Depletion Analysis', 'Position', [100 100 1200 900]);

for m = 1:2
    material = materials{m};
    params = moscap.defaultParameters();
    params.material = material;
    params = moscap.enforceMaterialConsistency(params, true);
    
    % Get material properties
    [eps_si, ni] = moscap.materialProperties(material, eps0);
    Na_peak = params.Na_peak;
    
    subplot(2, 3, (m-1)*3 + 1);
    
    % Create voltage sweep focused on inversion
    Vg = linspace(-2, 5, 501);
    Clow_vals = zeros(size(Vg));
    Chigh_vals = zeros(size(Vg));
    
    for i = 1:length(Vg)
        try
            [Clow, Chigh] = moscap.simulateMosCapCV(Vg(i), material);
            Clow_vals(i) = Clow * 1e12;  % pF
            Chigh_vals(i) = Chigh * 1e12;  % pF
        catch
            Clow_vals(i) = NaN;
            Chigh_vals(i) = NaN;
        end
    end
    
    % Plot C-V
    plot(Vg, Clow_vals, 'b-', 'LineWidth', 2, 'DisplayName', 'Low Freq (1 Hz)');
    hold on;
    plot(Vg, Chigh_vals, 'r--', 'LineWidth', 2, 'DisplayName', 'High Freq (1 MHz)');
    grid on;
    title(sprintf('%s - C-V Curves', material));
    xlabel('Gate Voltage (V)');
    ylabel('Capacitance (pF)');
    legend;
    
    %% ANALYZE DEEP DEPLETION TRANSITION
    subplot(2, 3, (m-1)*3 + 2);
    
    % For each voltage, calculate theoretical quantities
    dCdV_low = diff(Clow_vals) ./ diff(Vg);
    dCdV_high = diff(Chigh_vals) ./ diff(Vg);
    
    Vg_mid = Vg(1:end-1);
    plot(Vg_mid, dCdV_low*1e12, 'b-', 'LineWidth', 2);
    hold on;
    plot(Vg_mid, dCdV_high*1e12, 'r--', 'LineWidth', 2);
    grid on;
    title(sprintf('%s - dC/dVg Derivative', material));
    xlabel('Gate Voltage (V)');
    ylabel('dC/dVg (pF/V)');
    legend('Low Freq', 'High Freq');
    
    %% PHYSICAL PARAMETERS AT DIFFERENT REGIONS
    subplot(2, 3, (m-1)*3 + 3);
    
    Vt = 0.0259;  % Thermal voltage
    phiF_raw = Vt * log(Na_peak / max(ni, 1e-30));
    phiF = min(max(phiF_raw, 0.01), params.phiF_cap);
    
    % Flatband voltage
    phi_ms = params.phi_ms;
    Cox = params.eps_ox / params.tox;
    Vfb = phi_ms - 0;  % Approximate (no fixed oxide charge)
    
    % Depletion width formula: W = sqrt(4*eps*phiF / (q*Na))
    W_thermal = sqrt(4 * eps_si * Vt / (q * Na_peak));
    W_deep = sqrt(4 * eps_si * params.phiF_cap / (q * Na_peak));
    
    % Generation time constant effect
    tau_gen = params.tau_gen;
    freq_low = 1;  % Hz
    freq_high = 1e6;  % Hz
    
    % Characteristic frequency where gen/rec starts to matter
    f_gen_low = 1 / (2 * pi * tau_gen);
    
    fmt = ['Material: %s\n' ...
        'Na: %.2e m^-3\n' ...
        'ni: %.2e m^-3\n' ...
        'phiF_raw: %.4f V\n' ...
        'phiF_capped: %.4f V\n' ...
        'Vfb: %.4f V\n' ...
        '2*phiF: %.4f V\n' ...
        '\n' ...
        'Deep Depletion:\n' ...
        'W_thermal: %.2f nm\n' ...
        'W_deep: %.2f nm\n' ...
        'W_ratio: %.1f x\n' ...
        '\n' ...
        'Gen/Rec Frequency:\n' ...
        'tau_gen: %.2e s\n' ...
        'f_gen: %.2e Hz\n' ...
        'f_low: %.0f Hz (τf=%.2f)\n' ...
        'f_high: %.0e Hz (τf=%.2f)\n'];
    
    info_text = sprintf(fmt, ...
        material, Na_peak, ni, phiF_raw, phiF, Vfb, 2*phiF, ...
        W_thermal*1e9, W_deep*1e9, W_deep/W_thermal, ...
        tau_gen, f_gen_low, ...
        freq_low, 2*pi*tau_gen*freq_low, ...
        freq_high, 2*pi*tau_gen*freq_high);
    
    text(0.05, 0.95, info_text, 'Units', 'normalized', ...
        'VerticalAlignment', 'top', 'FontName', 'Courier', ...
        'FontSize', 9, 'BackgroundColor', 'yellow');
    axis off;
end

sgtitle('Deep Depletion Analysis: Si vs 4H-SiC');

%% PRINT ANALYSIS
fprintf('\n=== DEEP DEPLETION ANALYSIS ===\n\n');

for m = 1:2
    material = materials{m};
    params = moscap.defaultParameters();
    params.material = material;
    params = moscap.enforceMaterialConsistency(params, true);
    [eps_si, ni] = moscap.materialProperties(material, eps0);
    Na_peak = params.Na_peak;
    
    Vt = 0.0259;
    phiF_raw = Vt * log(Na_peak / max(ni, 1e-30));
    phiF = min(max(phiF_raw, 0.01), params.phiF_cap);
    
    % Flatband voltage
    phi_ms = params.phi_ms;
    Cox = params.eps_ox / params.tox;
    Vfb = phi_ms - 0;  % Approximate
    
    W_thermal = sqrt(4 * eps_si * Vt / (q * Na_peak)) * 1e9;  % nm
    W_deep = sqrt(4 * eps_si * params.phiF_cap / (q * Na_peak)) * 1e9;  % nm
    W_2phiF = sqrt(4 * eps_si * (2*phiF) / (q * Na_peak)) * 1e9;  % nm
    
    tau_gen = params.tau_gen;
    tau_gen_low = 1 / (2*pi * 1);  % Time constant at 1 Hz
    tau_gen_high = 1 / (2*pi * 1e6);  % Time constant at 1 MHz
    
    fprintf('%s:\n', material);
    fprintf('  Na: %.2e m^-3\n', Na_peak);
    fprintf('  ni: %.2e m^-3\n', ni);
    fprintf('  phiF_raw: %.4f V\n', phiF_raw);
    fprintf('  phiF (capped): %.4f V\n', phiF);
    fprintf('  2*phiF (inversion): %.4f V\n', 2*phiF);
    fprintf('\n');
    fprintf('  Depletion Widths:\n');
    fprintf('    W(Vt=%.3f V): %.2f nm\n', Vt, W_thermal);
    fprintf('    W(2*phiF=%.3f V): %.2f nm\n', 2*phiF, W_2phiF);
    fprintf('    W(phiF_cap=%.3f V): %.2f nm\n', params.phiF_cap, W_deep);
    fprintf('    Deep/Thermal Ratio: %.1f x\n', W_deep/W_thermal);
    fprintf('\n');
    fprintf('  Gen/Rec Time Constant: %.2e s\n', tau_gen);
    fprintf('    At 1 Hz: τf = %.3f (weak frequency dependence)\n', 2*pi*tau_gen*1);
    fprintf('    At 1 MHz: τf = %.3f (moderate frequency dependence)\n', 2*pi*tau_gen*1e6);
    fprintf('\n');
end

saveas(gcf, 'diagnose_deep_depletion.png');
fprintf('Plots saved to diagnose_deep_depletion.png\n');
