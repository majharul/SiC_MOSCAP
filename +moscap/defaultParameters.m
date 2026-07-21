function params = defaultParameters()
%DEFAULTPARAMETERS Initialize MOS capacitor parameters with physical constants.
%   Returns struct with all geometric, material, electrical, and non-ideal parameters.

params.q = 1.602176634e-19;
params.eps0 = 8.8541878128e-12;
params.k = 1.380649e-23;

params.T = 300;
params.eps_ox = 3.9 * params.eps0;
params.material = 'Si';
params.sicProcess = 'none';
[params.eps_si, params.ni] = moscap.materialProperties(params.material, params.eps0);

% Geometry
params.W = 100e-6;                   % m
params.L = 100e-6;                   % m
params.NF = 74;
params.tox = 50e-9;                  % m

% P-well Gaussian profile Na(x)
params.Na_peak = 5e23;               % m^-3
params.Rp = 0.25e-6;                 % m
params.sigma = 0.08e-6;              % m
params.xmax = 3e-6;                  % m

% Work function / fixed oxide charge
params.phi_ms = -3.15;               % V
params.Qox_m2 = 8e3;                   % m^-2 equivalent fixed charge density

% Interface trap dynamics
params.Dit_cm2eV = 9e11;             % cm^-2 eV^-1
params.tau_it = 100e-6;              % s

% Additional non-ideal capacitive behavior
params.Cbt_cm2eV = 2e11;             % border traps (cm^-2 eV^-1)
params.tau_bt = 5e-11;                % border trap response time (s)
params.Cpar_pF = 0;                  % overlap/fringe parasitic capacitance (pF)
params.stretch = 1.0;                % C-V stretch-out factor (>=1)

% Poly depletion
params.Npoly = 1e25;                 % m^-3
params.psi_poly = 3.6;               % V

% Electrical conditions
params.lfFreqHz = 1;                % Hz, quasi-static/low-frequency response
params.hfFreqHz = 1e6;              % Hz, high-frequency response
params.Rs = 500;                    % ohm

% Sweep
params.Vg = linspace(-10, 15, 1001);

% Numerical smoothing for occasional point-to-point artifacts.
params.smoothWindow = 10;

% Inversion response calibration via carrier generation/recombination time.
params.tau_gen = 9e-6;              % s (Si: 5-10 us for fast inversion; SiC: 1-3 ms for slow)
params.invGain = 1.0;               % 0..1 scaling for inversion recovery
params.invWidth = 0.12;             % V, smoothing width for inversion transition
params.forceLowFreqInversion = false; % set true to show low-frequency inversion branch (for teaching)
params.phiF_cap = 3.1;              % V, cap to avoid unrealistically high phiF in compact fitting

params = moscap.enforceMaterialConsistency(params, true);
end






