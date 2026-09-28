function printModelReview(params, sim)
%PRINTMODELREVIEW Display physics model and parameter summary to console.

Vg = sim.Vg;

fprintf('\n================ MOSCAP Physics Review ================\n');
fprintf('Electrostatics: implicit psi_s solved by Newton from Vg = Vfb + psi_s - Qs/Cox_area.\n');
fprintf('Semiconductor charge: exact Poisson-Boltzmann integral form via F(psi_s).\n');
fprintf('Capacitance path: analytic surface capacitance split into low-frequency (minority responds)\n');
fprintf('  and high-frequency (inversion charge frozen -> saturates at Cmin) limits.\n');
fprintf('Doping model: Gaussian Na(x) integrated to an effective Na_eff for 1D compact use.\n');
fprintf('Non-ideal blocks enabled: Dit, border traps, poly depletion, Rs, Cpar.\n');

fprintf('\n---------------- Parameter Summary ----------------\n');
fprintf('Area                = %.3e m^2\n', sim.Area);
fprintf('tox                 = %.2f nm\n', params.tox * 1e9);
fprintf('Na_eff              = %.3e m^-3\n', sim.Na_eff);
fprintf('Material            = %s\n', params.material);
fprintf('ni                  = %.3e m^-3\n', params.ni);
fprintf('Vfb                 = %.3f V\n', sim.Vfb);
fprintf('Cox                 = %.3f pF\n', sim.Cox * 1e12);
fprintf('Cox_eff             = %.3f pF\n', sim.Cox_eff * 1e12);
fprintf('Low-f Cmax          = %.3f pF\n', max(sim.Clow) * 1e12);
fprintf('High-f Cmax         = %.3f pF\n', max(sim.Chigh) * 1e12);
fprintf('Cit                 = %.3f pF\n', sim.Cit * 1e12);
fprintf('Cbt                 = %.3f pF\n', sim.Cbt * 1e12);
fprintf('Cpar               = %.3f pF\n', sim.Cpar * 1e12);
fprintf('tau_gen            = %.3e s\n', params.tau_gen);
fprintf('Rs                  = %.1f ohm\n', params.Rs);
fprintf('Vg range            = [%.2f, %.2f] V\n', min(Vg), max(Vg));
fprintf('=====================================================\n\n');
end
