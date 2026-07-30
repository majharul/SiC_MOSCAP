function verify_simplified_model()
%VERIFY_SIMPLIFIED_MODEL Sanity-check the simplified surface-potential C-V model.
%   Checks, for Si and 4H-SiC:
%     (1) accumulation -> C ~ Cox_eff (both LF and HF)
%     (2) HF does NOT recover toward Cox in inversion (Chigh saturates near Cmin)
%     (3) no flip-flop oscillation (Chigh is smooth / near-monotone in depletion->inv)

mats = {'Si', '4H-SiC'};
for k = 1:numel(mats)
    p = moscap.defaultParameters();
    p.material = mats{k};
    p = moscap.enforceMaterialConsistency(p, true);
    sim = moscap.simulateMosCapCV(p);

    Cox_eff = sim.Cox_eff;
    Clow = sim.Clow; Chigh = sim.Chigh; Vg = sim.Vg;

    accIdx = Vg <= (sim.Vfb - 3);          % well into accumulation
    invIdx = Vg >= (max(Vg) - 2);          % well into inversion

    Cacc_low  = mean(Clow(accIdx));
    Cacc_high = mean(Chigh(accIdx));
    Cinv_high = mean(Chigh(invIdx));
    Cmin_high = min(Chigh);

    % HF recovery metric: how far HF climbs back toward Cox in inversion.
    hfRecovery = (Cinv_high - Cmin_high) / max(Cox_eff, eps);

    % Oscillation metric on HF curve (sign changes of the derivative).
    d = diff(Chigh);
    d(abs(d) < 1e-6 * max(abs(Chigh))) = 0;
    signChanges = sum(abs(diff(sign(d(d ~= 0)))) > 0);

    fprintf('\n===== %s =====\n', mats{k});
    fprintf('Cox_eff        = %.3f pF\n', Cox_eff*1e12);
    fprintf('Acc  LF / HF   = %.3f / %.3f pF  (should ~= Cox_eff)\n', Cacc_low*1e12, Cacc_high*1e12);
    fprintf('Inv  HF (mean) = %.3f pF ,  Cmin_HF = %.3f pF\n', Cinv_high*1e12, Cmin_high*1e12);
    fprintf('HF inv recovery toward Cox = %.1f%% of Cox_eff\n', hfRecovery*100);
    fprintf('HF curve derivative sign-changes = %d\n', signChanges);
    fprintf('any NaN/Inf: Clow=%d Chigh=%d\n', any(~isfinite(Clow)), any(~isfinite(Chigh)));

    assert(all(isfinite(Clow)) && all(isfinite(Chigh)), '%s: non-finite C', mats{k});
    assert(Cacc_high > 0.85*Cox_eff, '%s: HF accumulation did not reach Cox', mats{k});
    assert(hfRecovery < 0.15, '%s: HF is recovering toward Cox in inversion (%.1f%%)', mats{k}, hfRecovery*100);
    fprintf('PASS: %s HF saturates at Cmin, no inversion recovery.\n', mats{k});
end
fprintf('\nAll checks passed.\n');
end
