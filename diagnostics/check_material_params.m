%% Check Material-Specific Parameters

params_si = moscap.defaultParameters();
params_si.material = 'Si';
params_si = moscap.enforceMaterialConsistency(params_si, true);

params_sic = moscap.defaultParameters();
params_sic.material = '4H-SiC';
params_sic = moscap.enforceMaterialConsistency(params_sic, true);

fprintf('=== Si PARAMETERS ===\n');
fprintf('material: %s\n', params_si.material);
fprintf('phi_ms: %.4f V\n', params_si.phi_ms);
fprintf('Na_peak: %.2e m^-3\n', params_si.Na_peak);
fprintf('tau_gen: %.4e s\n', params_si.tau_gen);
fprintf('Dit_cm2eV: %.2e cm^-2 eV^-1\n', params_si.Dit_cm2eV);
fprintf('invGain: %.3f\n', params_si.invGain);
fprintf('invWidth: %.3f V\n', params_si.invWidth);
fprintf('phiF_cap: %.3f V\n', params_si.phiF_cap);
fprintf('lfFreqHz: %.2e Hz\n', params_si.lfFreqHz);
fprintf('hfFreqHz: %.2e Hz\n', params_si.hfFreqHz);

fprintf('\n=== 4H-SiC PARAMETERS ===\n');
fprintf('material: %s\n', params_sic.material);
fprintf('phi_ms: %.4f V\n', params_sic.phi_ms);
fprintf('Na_peak: %.2e m^-3\n', params_sic.Na_peak);
fprintf('tau_gen: %.4e s\n', params_sic.tau_gen);
fprintf('Dit_cm2eV: %.2e cm^-2 eV^-1\n', params_sic.Dit_cm2eV);
fprintf('invGain: %.3f\n', params_sic.invGain);
fprintf('invWidth: %.3f V\n', params_sic.invWidth);
fprintf('phiF_cap: %.3f V\n', params_sic.phiF_cap);
fprintf('lfFreqHz: %.2e Hz\n', params_sic.lfFreqHz);
fprintf('hfFreqHz: %.2e Hz\n', params_sic.hfFreqHz);

fprintf('\n=== DIFFERENCES ===\n');
fprintf('phi_ms: Si=%.3f vs SiC=%.3f (delta: %.3f)\n', params_si.phi_ms, params_sic.phi_ms, params_sic.phi_ms - params_si.phi_ms);
fprintf('Na_peak: Si=%.2e vs SiC=%.2e (ratio: %.2f)\n', params_si.Na_peak, params_sic.Na_peak, params_sic.Na_peak/params_si.Na_peak);
fprintf('tau_gen: Si=%.2e vs SiC=%.2e (ratio: %.1f)\n', params_si.tau_gen, params_sic.tau_gen, params_sic.tau_gen/params_si.tau_gen);
fprintf('invGain: Si=%.3f vs SiC=%.3f (delta: %.3f)\n', params_si.invGain, params_sic.invGain, params_sic.invGain - params_si.invGain);

% Check what happens with thermal voltage
fprintf('\n=== THERMAL VOLTAGES ===\n');
q = 1.602e-19;  % C
k = 1.381e-23;  % J/K
T = 300;        % K
Vt = k*T/q;
fprintf('At T=300K: Vt = %.4f V (kT/q)\n', Vt);

% For SiC intrinsic carrier concentration
fprintf('\nSiC material properties:\n');
fprintf('Band gap (4H-SiC): ~3.26 eV @ 300K (vs Si 1.12 eV)\n');
fprintf('intrinsic carrier: SiC much lower than Si\n');
fprintf('Interface trap density (Dit): typically 1e10-1e12 cm^-2 eV^-1\n');
