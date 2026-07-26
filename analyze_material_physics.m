%% Detailed Physics Analysis: Si vs SiC

% Constants
q = 1.602e-19;  % C
k = 1.381e-23;  % J/K
T = 300;        % K
Vt = k*T/q;

% Material properties
eps0 = 8.854e-12;  % F/m
eps_si_si = 11.68 * eps0;
eps_si_sic = 9.66 * eps0;

% SiC band gap is larger → intrinsic carrier much lower
fprintf('=== MATERIAL PROPERTIES ===\n');
fprintf('Temperature: %.0f K\n', T);
fprintf('Thermal voltage Vt = kT/q: %.4f V\n\n', Vt);

fprintf('Silicon (Si):\n');
Eg_si = 1.12;
ni_si = 1e10 * exp(Eg_si / (2*Vt));  % Approximate
fprintf('  Band gap Eg: %.2f eV\n', Eg_si);
fprintf('  Intrinsic carrier ni ≈ %.2e cm^-3\n', ni_si/1e6);

fprintf('\n4H-SiC:\n');
Eg_sic = 3.26;
ni_sic = 1e10 * exp(Eg_sic / (2*Vt));  % Very approximate
fprintf('  Band gap Eg: %.2f eV\n', Eg_sic);
fprintf('  Intrinsic carrier ni ≈ %.2e cm^-3 (MUCH LOWER!)\n', ni_sic/1e6);

% Fermi potential calculation for each doping
fprintf('\n=== FERMI POTENTIAL CALCULATION ===\n');

Na_si = 5e23;  % m^-3 = 5e17 cm^-3
Na_sic = 5e21; % m^-3 = 5e15 cm^-3

fprintf('\nSi with Na = 5e17 cm^-3:\n');
phiF_si_raw = Vt * log(Na_si/1e6 / ni_si);
fprintf('  phiF = (kT/q) * ln(Na/ni) = %.4f V\n', phiF_si_raw);
phiF_si_capped = min(max(phiF_si_raw, 0.05), 1.10);
fprintf('  Capped at 1.10 V: phiF = %.4f V\n', phiF_si_capped);

fprintf('\nSiC with Na = 5e15 cm^-3:\n');
phiF_sic_raw = Vt * log(Na_sic/1e6 / ni_sic);
fprintf('  phiF = (kT/q) * ln(Na/ni) = %.4f V\n', phiF_sic_raw);
phiF_sic_capped = min(max(phiF_sic_raw, 0.05), 0.85);
fprintf('  Capped at 0.85 V: phiF = %.4f V\n', phiF_sic_capped);

fprintf('\nInversion transition occurs at psi_s ≈ 2*phiF:\n');
fprintf('  Si: psi_s ≈ 2 * %.4f = %.4f V\n', phiF_si_capped, 2*phiF_si_capped);
fprintf('  SiC: psi_s ≈ 2 * %.4f = %.4f V\n', phiF_sic_capped, 2*phiF_sic_capped);

% Depletion width
fprintf('\n=== DEPLETION WIDTH ===\n');
fprintf('Wd = sqrt(2*eps_s*psi_s / (q*Na))\n\n');

psi_test = 0.5;  % Example surface potential
Wd_si = sqrt(2*eps_si_si*psi_test / (q*Na_si));
Wd_sic = sqrt(2*eps_si_sic*psi_test / (q*Na_sic));

fprintf('At psi_s = %.2f V:\n', psi_test);
fprintf('  Si depletion width: %.2e m = %.2f μm\n', Wd_si, Wd_si*1e6);
fprintf('  SiC depletion width: %.2e m = %.2f μm\n', Wd_sic, Wd_sic*1e6);
fprintf('  Ratio (SiC/Si): %.1f x deeper!\n', Wd_sic/Wd_si);

fprintf('\n=== INFERENCE ===\n');
fprintf('SiC with 100x lower doping has:\n');
fprintf('1. Much deeper depletion width (affects C-V slope)\n');
fprintf('2. Similar Fermi potential but different Na → different Cs behavior\n');
fprintf('3. 400x longer tau_gen → more frequency dependence\n');
fprintf('4. Lower phiF_cap → inversion transition at lower psi\n');
fprintf('\nThis combination can create unusual C-V shapes if not handled carefully.\n');
