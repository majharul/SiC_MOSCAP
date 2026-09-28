function Cgg_pF = getMeasuredCgg(measured)
%GETMEASUREDCGG Extract selected capacitance column from measurement struct.

if isfield(measured, 'Ccols')
    values = measured.Ccols;
else
    values = measured.Ccols_pF;
end
idx = min(max(1, measured.selectedCol), size(values, 1));
Cgg_pF = values(idx, :);
end
