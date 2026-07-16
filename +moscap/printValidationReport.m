function printValidationReport(params, sim)
%PRINTVALIDATIONREPORT Display physics model validation checks.

Vg = sim.Vg;
Cmeas = sim.Cmeas;
Cmos = sim.Cmos;

fprintf('\n================ Validation Checks =================\n');

% 1) Physical bounds.
boundCheck = all(Cmos >= 0) && all(Cmos <= sim.Cox * 1.02);
fprintf('Intrinsic capacitance bounds (0 <= Cmos <= 1.02*Cox): %s\n', passFail(boundCheck));

% 2) Accumulation high-capacitance check (intrinsic model, before Rs attenuation).
accMask = Vg < sim.Vfb - 1.0;
if any(accMask)
    Cacc = median(Cmos(accMask));
    accRatio = Cacc / sim.Cox_eff;
    accCheck = accRatio > 0.85 && accRatio < 1.15;
    fprintf('Accumulation plateau near Cox_eff: %s (ratio = %.3f)\n', passFail(accCheck), accRatio);
else
    fprintf('Accumulation plateau near Cox_eff: SKIP (no strong-accumulation points)\n');
end

% 2b) Rs attenuation plausibility in accumulation.
if any(accMask)
    attenRatio = median(Cmeas(accMask)) / max(median(Cmos(accMask)), eps);
    fprintf('Accumulation attenuation from Rs at f: ratio(Cmeas/Cmos) = %.3e\n', attenRatio);
end

% 3) Depletion minimum existence.
[Cmin, idxMin] = min(Cmos);
depCheck = idxMin > 1 && idxMin < numel(Vg);
fprintf('Depletion minimum exists in sweep: %s (Cmin = %.3f pF @ Vg = %.3f V)\n', ...
    passFail(depCheck), Cmin * 1e12, Vg(idxMin));

% 4) Newton convergence quality.
iter95 = prctile(sim.newtonIters, 95);
convCheck = iter95 < 40;
fprintf('Newton convergence robustness: %s (95th percentile iterations = %.1f)\n', ...
    passFail(convCheck), iter95);

% 5) Material-consistent intrinsic concentration sanity.
if strcmpi(params.material, 'Si')
    niCheck = params.ni > 1e14 && params.ni < 5e16;
else
    niCheck = params.ni > 1e-8 && params.ni < 1e10;
end
fprintf('Intrinsic carrier concentration sanity (%s): %s (ni = %.3e m^-3)\n', ...
    params.material, passFail(niCheck), params.ni);

fprintf('====================================================\n\n');

    function txt = passFail(ok)
        if ok
            txt = 'PASS';
        else
            txt = 'CHECK';
        end
    end
end
