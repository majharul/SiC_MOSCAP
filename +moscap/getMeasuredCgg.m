function Cgg_pF = getMeasuredCgg(measured)
%GETMEASUREDCGG Extract selected capacitance column from measurement struct.

idx = min(max(1, measured.selectedCol), size(measured.Ccols_pF, 1));
Cgg_pF = measured.Ccols_pF(idx, :);
end
