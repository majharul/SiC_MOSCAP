%% Check Flatband Voltage

params = moscap.defaultParameters();
params.material = 'SiC';

q = params.q;
Cox_area = params.eps_ox / params.tox;
Qox = params.Qox_m2 * q;
Vfb = params.phi_ms - Qox / Cox_area;

fprintf('Flatband Voltage Analysis:\n');
fprintf('phi_ms = %.4f V\n', params.phi_ms);
fprintf('Qox_m2 = %.4e C/m²\n', params.Qox_m2);
fprintf('Qox = %.4e C\n', Qox);
fprintf('Cox_area = %.4e F/m²\n', Cox_area);
fprintf('Qox/Cox_area = %.4f V\n', Qox / Cox_area);
fprintf('Vfb = phi_ms - Qox/Cox = %.4f V\n\n', Vfb);

fprintf('Physical expectation:\n');
fprintf('For Si: Vfb typically -0.5 to +0.5 V\n');
fprintf('For 4H-SiC: Vfb typically -1 to +1 V\n');
fprintf('Your Vfb = %.4f V - %s\n\n', Vfb, ...
    ifthenelse(Vfb > -2 && Vfb < 2, 'REASONABLE', '⚠️ OUT OF RANGE'));

% Now check if this explains the psi behavior
fprintf('At Vg = -10V:\n');
fprintf('  Expected psi: should be far from Vfb in accumulation direction\n');
fprintf('  Got psi = -0.1084V with Vfb = %.4f V\n', Vfb);
fprintf('  This means... psi has OPPOSITE sign from normal!\n\n');

fprintf('The problem:\n');
fprintf('1. At Vg = -10V, we should be in STRONG ACCUMULATION\n');
fprintf('2. Accumulation means psi should have same sign as Vg relative to Vfb\n');
fprintf('3. But psi has a different sign - Newton solver picked wrong root!\n');

function y = ifthenelse(cond, yes, no)
    if cond
        y = yes;
    else
        y = no;
    end
end
