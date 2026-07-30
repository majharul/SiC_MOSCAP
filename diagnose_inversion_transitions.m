%% DIAGNOSE INVERSION WEIGHT TRANSITIONS FOR Si vs SiC
% Check if the inversion transition is causing discontinuities

clear; clc; close all;

% Setup
q = 1.602e-19;
eps0 = 8.854e-12;

materials = {'Si', '4H-SiC'};
Vg = linspace(-2, 8, 1001);
figure('Name', 'Inversion Transition Analysis', 'Position', [100 100 1400 900]);

for m = 1:2
    material = materials{m};
    params = moscap.defaultParameters();
    params.material = material;
    params = moscap.enforceMaterialConsistency(params, true);
    
    [eps_si, ni] = moscap.materialProperties(material, eps0);
    
    % Pre-compute frequency-dependent responses
    [Clow_vals, Chigh_vals, psi_vals, invWeight_low, invWeight_high] = deal(zeros(size(Vg)));
    
    for i = 1:length(Vg)
        try
            % Use internal physics calculation
            [Clow, Chigh] = moscap.simulateMosCapCV(Vg(i), material);
            Clow_vals(i) = Clow * 1e12;
            Chigh_vals(i) = Chigh * 1e12;
        catch
            Clow_vals(i) = NaN;
            Chigh_vals(i) = NaN;
        end
    end
    
    % Plot 1: C-V curves
    subplot(2, 3, (m-1)*3 + 1);
    plot(Vg, Clow_vals, 'b-', 'LineWidth', 2, 'DisplayName', 'Low Freq');
    hold on;
    plot(Vg, Chigh_vals, 'r--', 'LineWidth', 2, 'DisplayName', 'High Freq');
    grid on;
    xlabel('Vg (V)');
    ylabel('C (pF)');
    title(sprintf('%s - C-V Curves', material));
    legend;
    
    % Plot 2: Frequency Separation
    subplot(2, 3, (m-1)*3 + 2);
    separation = Clow_vals - Chigh_vals;
    plot(Vg, separation, 'g-', 'LineWidth', 2);
    grid on;
    xlabel('Vg (V)');
    ylabel('ΔC = C_low - C_high (pF)');
    title(sprintf('%s - Frequency Separation', material));
    
    % Plot 3: Derivatives
    subplot(2, 3, (m-1)*3 + 3);
    dClow = diff(Clow_vals) ./ diff(Vg);
    dChigh = diff(Chigh_vals) ./ diff(Vg);
    Vg_mid = Vg(1:end-1);
    
    plot(Vg_mid, dClow, 'b-', 'LineWidth', 1.5, 'DisplayName', 'dC_low/dVg');
    hold on;
    plot(Vg_mid, dChigh, 'r--', 'LineWidth', 1.5, 'DisplayName', 'dC_high/dVg');
    grid on;
    axline = gca;
    axline.YAxisLocation = 'origin';
    xlabel('Vg (V)');
    ylabel('dC/dVg (pF/V)');
    title(sprintf('%s - Derivatives', material));
    legend;
    
    %% Print analysis
    fprintf('\n%s ANALYSIS:\n', material);
    fprintf('━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    % Count sign changes in low freq
    signs_low = sign(dClow);
    sign_changes_low = sum(abs(diff(signs_low(~isnan(signs_low)))) > 0);
    
    % Count sign changes in high freq
    signs_high = sign(dChigh);
    sign_changes_high = sum(abs(diff(signs_high(~isnan(signs_high)))) > 0);
    
    fprintf('Low Freq dC/dVg sign changes: %d\n', sign_changes_low);
    fprintf('High Freq dC/dVg sign changes: %d\n', sign_changes_high);
    fprintf('Max frequency separation: %.2f pF\n', max(abs(separation)));
    fprintf('Vg range with ΔC > 10pF: ', '');
    large_sep = Vg(abs(separation) > 10);
    if ~isempty(large_sep)
        fprintf('[%.2f to %.2f]V\n', min(large_sep), max(large_sep));
    else
        fprintf('none\n');
    end
    
    % Find inversion region (where low freq drops)
    fprintf('\nInversion region characterization:\n');
    Vt = 0.0259;
    phiF_raw = Vt * log(max(params.Na_peak, 1.01*ni) / max(ni, 1e-30));
    phiF_capped = min(max(phiF_raw, 0.01), params.phiF_cap);
    fprintf('  phiF: %.4f V → %.4f V (capped)\n', phiF_raw, phiF_capped);
    fprintf('  2*phiF: %.4f V (expected inversion threshold)\n', 2*phiF_capped);
    fprintf('  invWidth: %.2f V\n', params.invWidth);
    fprintf('  tau_gen: %.2e s\n', params.tau_gen);
end

sgtitle('Inversion Transition Analysis: Si vs 4H-SiC');
saveas(gcf, 'diagnose_inversion_transitions.png');
fprintf('\n\nPlots saved to diagnose_inversion_transitions.png\n');
