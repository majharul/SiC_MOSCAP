function [Cn, Cox_ref] = normalizeCV(C, Cox_ref)
%NORMALIZECV Normalize a capacitance vector to C/Cox.
%   Cn = moscap.normalizeCV(C)          normalizes by the accumulation
%       maximum (max of C), the standard experimental estimate of the oxide
%       capacitance when Cox is not independently known.
%   Cn = moscap.normalizeCV(C, Cox_ref) normalizes by an explicit reference
%       (e.g. the model oxide/effective capacitance sim.Cox_eff).
%
%   Returns the normalized curve and the reference used. Both simulated and
%   measured curves normalized this way plateau at ~1 in accumulation, so a
%   normalized C/Cox overlay compares shape independent of area / tox / Cox.

C = real(C);
if nargin < 2 || isempty(Cox_ref) || ~isfinite(Cox_ref) || Cox_ref <= 0
    finiteC = C(isfinite(C));
    if isempty(finiteC)
        Cox_ref = 1;
    else
        Cox_ref = max(finiteC);
    end
end
if ~isfinite(Cox_ref) || Cox_ref <= 0
    Cox_ref = 1;
end

Cn = C / Cox_ref;
end
